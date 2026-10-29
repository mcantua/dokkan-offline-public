#include "overlay_reader.h"
#include "sqlite3.h"
#include <string.h>

#define ODOV_APP_ID 0x4F444F56
#define ODOV_LIMIT INT64_C(9007199254740991)
#define ODOV_JSON_LIMIT (16*1024*1024)

struct odov_reader { sqlite3 *db; char content[81]; char scope[65]; };

static int hex64(const char *s) {
 if(!s||strlen(s)!=64)return 0;
 for(int i=0;i<64;i++)if(!((s[i]>='0'&&s[i]<='9')||(s[i]>='a'&&s[i]<='f')))return 0;
 return 1;
}
static const char *content_hash(const char *s) {
 if(!s)return 0;
 if(!strncmp(s,"eclipse:",8))s+=8;
 else if(!strncmp(s,"sparking:",9))s+=9;
 return !strncmp(s,"sha256:",7)&&hex64(s+7)?s+7:0;
}
static int key(const char *s) {
 if(!s||!*s||strlen(s)>100)return 0;
 for(;*s;s++)if(!((*s>='a'&&*s<='z')||(*s>='A'&&*s<='Z')||(*s>='0'&&*s<='9')||strchr("_.:-",*s)))return 0;
 return 1;
}
static int allowed_table(const char *s) {
 static const char *names[]={"cards","leader_skill_sets","leader_skills","passive_skill_sets","passive_skill_set_relations","passive_skills","card_specials","special_sets","specials","extra_special_options","card_active_skills","active_skill_sets","active_skills","card_standby_skill_set_relations","standby_skill_sets","standby_skills","standby_skill_set_finish_skill_set_relations","card_finish_skill_set_relations","finish_skill_sets","finish_skills","finish_specials","card_card_categories","card_categories","dokkan_fields","dokkan_field_active_skill_set_relations","dokkan_field_passive_skill_relations","link_skills","skill_causalities","sub_target_types","transformation_descriptions"};
 if(!s)return 0;
 for(unsigned i=0;i<sizeof(names)/sizeof(*names);i++)if(!strcmp(names[i],s))return 1;
 return 0;
}
static int prepare(odov_reader *r,const char *sql,sqlite3_stmt **s) {
 return sqlite3_prepare_v2(r->db,sql,-1,s,0)==SQLITE_OK?ODOV_OK:ODOV_DATABASE;
}
static int identity(odov_reader *r,int64_t revision) {
 sqlite3_stmt *s=0;
 const char *sql="SELECT (SELECT value FROM overlay_meta WHERE key='content_id'),(SELECT value FROM overlay_meta WHERE key='save_scope_sha256'),(SELECT value FROM overlay_meta WHERE key='schema'),(SELECT value FROM overlay_meta WHERE key='projection_generation')";
 if(prepare(r,sql,&s)<0)return ODOV_DATABASE;
 int result=ODOV_IDENTITY;
 if(sqlite3_step(s)==SQLITE_ROW){
  const char *content=(const char *)sqlite3_column_text(s,0),*scope=(const char *)sqlite3_column_text(s,1),*schema=(const char *)sqlite3_column_text(s,2),*rev=(const char *)sqlite3_column_text(s,3);
  if(content&&scope&&schema&&rev&&!strcmp(content,r->content)&&!strcmp(scope,r->scope)&&!strcmp(schema,"1")){
   if(revision<0)result=ODOV_OK;
   else { char expected[32];sqlite3_snprintf(sizeof(expected),expected,"%lld",(long long)revision);result=!strcmp(rev,expected)?ODOV_OK:ODOV_REVISION; }
  }
 }
 sqlite3_finalize(s);return result;
}
static int schema(odov_reader *r) {
 sqlite3_stmt *s=0;
 if(prepare(r,"PRAGMA application_id",&s)<0)return ODOV_DATABASE;
 int good=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0)==ODOV_APP_ID;
 sqlite3_finalize(s);if(!good)return ODOV_IDENTITY;
 if(prepare(r,"SELECT count(*),sum(type='table' AND name IN('overlay_meta','overlay_revisions','overlay_heads','overlay_rows','overlay_bindings','overlay_commands')) FROM sqlite_schema WHERE name NOT LIKE 'sqlite_%'",&s)<0)return ODOV_DATABASE;
 good=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0)==6&&sqlite3_column_int(s,1)==6;
 sqlite3_finalize(s);return good?ODOV_OK:ODOV_IDENTITY;
}
int odov_open(const char *path,const char *content,const char *scope,odov_reader **out) {
 if(!out)return ODOV_INVALID;
 *out=0;
 if(!path||!*path||!content_hash(content)||!hex64(scope))return ODOV_INVALID;
 odov_reader *r=sqlite3_malloc64(sizeof(*r));if(!r)return ODOV_MEMORY;
 memset(r,0,sizeof(*r));memcpy(r->content,content,strlen(content)+1);memcpy(r->scope,scope,65);
 int flags=SQLITE_OPEN_READONLY|SQLITE_OPEN_NOMUTEX|SQLITE_OPEN_NOFOLLOW;
 if(sqlite3_open_v2(path,&r->db,flags,0)!=SQLITE_OK){odov_close(r);return ODOV_DATABASE;}
 sqlite3_limit(r->db,SQLITE_LIMIT_LENGTH,ODOV_JSON_LIMIT);
 sqlite3_limit(r->db,SQLITE_LIMIT_SQL_LENGTH,8192);
 if(sqlite3_exec(r->db,"PRAGMA query_only=ON;PRAGMA trusted_schema=OFF",0,0,0)!=SQLITE_OK){odov_close(r);return ODOV_DATABASE;}
 int rc=schema(r);if(rc==ODOV_OK)rc=identity(r,-1);
 if(rc<0){odov_close(r);return rc;}*out=r;return ODOV_OK;
}
void odov_close(odov_reader *r){if(r){if(r->db)sqlite3_close(r->db);sqlite3_free(r);}}
void odov_free(char *json){sqlite3_free(json);}
static int begin(odov_reader *r,int64_t revision) {
 if(!r||revision<1||revision>ODOV_LIMIT)return ODOV_INVALID;
 if(sqlite3_exec(r->db,"BEGIN",0,0,0)!=SQLITE_OK)return ODOV_DATABASE;
 int rc=identity(r,revision);
 if(rc<0)sqlite3_exec(r->db,"ROLLBACK",0,0,0);
 return rc;
}
static int finish(odov_reader *r,int rc) {
 if(sqlite3_exec(r->db,rc<0?"ROLLBACK":"COMMIT",0,0,0)!=SQLITE_OK){sqlite3_exec(r->db,"ROLLBACK",0,0,0);return ODOV_DATABASE;}
 return rc;
}
static int copy_json(sqlite3_stmt *s,int column,char **out) {
 const unsigned char *value=sqlite3_column_text(s,column);int length=sqlite3_column_bytes(s,column);
 if(!value||length<2||length>ODOV_JSON_LIMIT||memchr(value,0,(size_t)length))return ODOV_DATABASE;
 *out=sqlite3_malloc64((sqlite3_uint64)length+1);if(!*out)return ODOV_MEMORY;
 memcpy(*out,value,(size_t)length);(*out)[length]=0;return ODOV_FOUND;
}
int odov_binding(odov_reader *r,const char *instance,int64_t revision,char **out) {
 if(!out)return ODOV_INVALID;
 *out=0;
 if(!key(instance))return ODOV_INVALID;
 int rc=begin(r,revision);if(rc<0)return rc;
 sqlite3_stmt *s=0;
 const char *sql="SELECT json_object('definition_id',b.definition_id,'version',h.version,'document_sha256',d.digest,'projection_generation',?2,'content_id',?3,'save_scope_sha256',?4,'original_client_attached',json('false')) FROM overlay_bindings b JOIN overlay_heads h USING(definition_id) JOIN overlay_revisions d ON d.definition_id=h.definition_id AND d.version=h.version WHERE b.instance_key=?1";
 if(prepare(r,sql,&s)<0)return finish(r,ODOV_DATABASE);
 sqlite3_bind_text(s,1,instance,-1,SQLITE_STATIC);sqlite3_bind_int64(s,2,revision);sqlite3_bind_text(s,3,r->content,-1,SQLITE_STATIC);sqlite3_bind_text(s,4,r->scope,-1,SQLITE_STATIC);
 int step=sqlite3_step(s);rc=step==SQLITE_ROW?copy_json(s,0,out):step==SQLITE_DONE?ODOV_BINDING:ODOV_DATABASE;
 sqlite3_finalize(s);rc=finish(r,rc);if(rc<0){odov_free(*out);*out=0;}return rc;
}
int odov_row(odov_reader *r,const char *instance,const char *table,int64_t source_id,int64_t revision,int64_t version,char **out) {
 if(!out)return ODOV_INVALID;
 *out=0;
 if(!key(instance)||!allowed_table(table)||source_id<1||source_id>ODOV_LIMIT||version<0||version>ODOV_LIMIT)return ODOV_INVALID;
 int rc=begin(r,revision);if(rc<0)return rc;
 sqlite3_stmt *s=0;
 const char *sql="SELECT d.version,o.row_json FROM overlay_bindings b JOIN overlay_heads h USING(definition_id) JOIN overlay_revisions d ON d.definition_id=b.definition_id AND d.version=CASE WHEN ?4=0 THEN h.version ELSE ?4 END LEFT JOIN overlay_rows o ON o.definition_id=d.definition_id AND o.version=d.version AND o.table_name=?2 AND o.source_row_id=?3 WHERE b.instance_key=?1";
 if(prepare(r,sql,&s)<0)return finish(r,ODOV_DATABASE);
 sqlite3_bind_text(s,1,instance,-1,SQLITE_STATIC);sqlite3_bind_text(s,2,table,-1,SQLITE_STATIC);sqlite3_bind_int64(s,3,source_id);sqlite3_bind_int64(s,4,version);
 int step=sqlite3_step(s);
 rc=step==SQLITE_ROW?(sqlite3_column_type(s,1)==SQLITE_NULL?ODOV_MISSING:copy_json(s,1,out)):step==SQLITE_DONE?ODOV_BINDING:ODOV_DATABASE;
 sqlite3_finalize(s);rc=finish(r,rc);if(rc<0){odov_free(*out);*out=0;}return rc;
}
int odov_projection_state(odov_reader *r,int64_t generation,char **out) {
 if(!out)return ODOV_INVALID;
 *out=0;
 int rc=begin(r,generation);if(rc<0)return rc;
 sqlite3_stmt *s=0;
 if(prepare(r,"SELECT value FROM overlay_meta WHERE key='projection_state'",&s)<0)return finish(r,ODOV_DATABASE);
 int step=sqlite3_step(s);rc=step==SQLITE_ROW?copy_json(s,0,out):step==SQLITE_DONE?ODOV_MISSING:ODOV_DATABASE;
 sqlite3_finalize(s);rc=finish(r,rc);if(rc<0){odov_free(*out);*out=0;}return rc;
}
