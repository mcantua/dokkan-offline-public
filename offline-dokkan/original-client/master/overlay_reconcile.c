#if defined(__APPLE__) && !defined(_DARWIN_C_SOURCE)
#define _DARWIN_C_SOURCE 1
#endif
#define _POSIX_C_SOURCE 200809L
#include "overlay_reconcile.h"
#include "../../core/json_values.h"
#include "sqlite3.h"
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define LIMIT INT64_C(9007199254740991)
#define MAX_JSON (16*1024*1024)
#define MAX_TOTAL (64*1024*1024)
#define APP_ID 0x4F444F56
typedef struct {char *id,*document;int64_t version;char digest[65];} document;
static const char *ddl[]={
 "CREATE TABLE overlay_meta(key TEXT PRIMARY KEY,value TEXT NOT NULL) STRICT",
 "CREATE TABLE overlay_revisions(definition_id TEXT NOT NULL,version INTEGER NOT NULL CHECK(version>0),document TEXT NOT NULL CHECK(json_valid(document)),digest TEXT NOT NULL,projection_generation INTEGER NOT NULL CHECK(projection_generation>0),PRIMARY KEY(definition_id,version)) STRICT",
 "CREATE TABLE overlay_heads(definition_id TEXT PRIMARY KEY,version INTEGER NOT NULL,FOREIGN KEY(definition_id,version) REFERENCES overlay_revisions(definition_id,version)) STRICT",
 "CREATE TABLE overlay_rows(definition_id TEXT NOT NULL,version INTEGER NOT NULL,table_name TEXT NOT NULL,source_row_id INTEGER NOT NULL,row_json TEXT NOT NULL CHECK(json_valid(row_json)),PRIMARY KEY(definition_id,version,table_name,source_row_id),FOREIGN KEY(definition_id,version) REFERENCES overlay_revisions(definition_id,version)) STRICT",
 "CREATE TABLE overlay_bindings(instance_key TEXT PRIMARY KEY,definition_id TEXT NOT NULL REFERENCES overlay_heads(definition_id)) STRICT",
 "CREATE TABLE overlay_commands(command_id TEXT PRIMARY KEY,request_digest TEXT NOT NULL,receipt TEXT NOT NULL CHECK(json_valid(receipt))) STRICT"};
static const char *table_names[]={"cards","leader_skill_sets","leader_skills","passive_skill_sets","passive_skill_set_relations","passive_skills","card_specials","special_sets","specials","extra_special_options","card_active_skills","active_skill_sets","active_skills","card_standby_skill_set_relations","standby_skill_sets","standby_skills","standby_skill_set_finish_skill_set_relations","finish_skill_sets","card_finish_skill_set_relations","finish_skills","finish_specials","card_card_categories","card_categories","dokkan_fields","dokkan_field_active_skill_set_relations","dokkan_field_passive_skill_relations","link_skills","skill_causalities","sub_target_types","transformation_descriptions"};
static int hex(const char *s,size_t n){if(!s||strlen(s)!=n)return 0;for(size_t i=0;i<n;i++)if(!((s[i]>='0'&&s[i]<='9')||(s[i]>='a'&&s[i]<='f')))return 0;return 1;}
static const char *content_hash(const char *s){if(!s)return 0;if(!strncmp(s,"eclipse:",8))s+=8;else if(!strncmp(s,"sparking:",9))s+=9;return !strncmp(s,"sha256:",7)&&hex(s+7,64)?s+7:0;}
static int key(const char *s,size_t max){if(!s||!*s||strlen(s)>max)return 0;for(;*s;s++)if(!((*s>='a'&&*s<='z')||(*s>='A'&&*s<='Z')||(*s>='0'&&*s<='9')||strchr("_.:-",*s)))return 0;return 1;}
static int allowed_table(const char *name){if(!name)return 0;for(unsigned i=0;i<sizeof(table_names)/sizeof(*table_names);i++)if(!strcmp(name,table_names[i]))return 1;return 0;}
static int known_reference(const char *name){
 static const char *names[]={"card_id","passive_skill_set_id","passive_skill_id","target_passive_skill_set_id","additional_passive_skill_set_id","leader_skill_set_id","special_set_id","card_special_id","active_skill_set_id","standby_skill_set_id","finish_skill_set_id","finish_special_id","card_category_id","dokkan_field_id","character_id","card_unique_info_id","potential_board_id","awaked_card_id","card_awakening_set_id"};
 for(unsigned i=0;i<sizeof(names)/sizeof(*names);i++)if(!strcmp(name,names[i]))return 1;
 return strlen(name)==14&&!strncmp(name,"link_skill",10)&&name[10]>='1'&&name[10]<='7'&&!strcmp(name+11,"_id");
}
static int prep(sqlite3 *db,const char *sql,sqlite3_stmt **out){return sqlite3_prepare_v2(db,sql,-1,out,0)==SQLITE_OK?0:ODOV_DATABASE;}
static int exec(sqlite3 *db,const char *sql){return sqlite3_exec(db,sql,0,0,0)==SQLITE_OK?0:ODOV_DATABASE;}
static int truth(sqlite3 *db,const char *sql,const char *json){sqlite3_stmt *s=0;if(prep(db,sql,&s)<0)return 0;sqlite3_bind_text(s,1,json,-1,SQLITE_STATIC);int ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);return ok;}
static char *copy_column(sqlite3_stmt *s,int col){const unsigned char *v=sqlite3_column_text(s,col);int n=sqlite3_column_bytes(s,col);return v&&n<=MAX_JSON&&!memchr(v,0,(size_t)n)?sqlite3_mprintf("%s",v):0;}
static char *text(sqlite3 *db,const char *json,const char *path){sqlite3_stmt *s=0;if(prep(db,"SELECT json_extract(?1,?2) WHERE json_type(?1,?2) IN('text','object','array')",&s)<0)return 0;sqlite3_bind_text(s,1,json,-1,SQLITE_STATIC);sqlite3_bind_text(s,2,path,-1,SQLITE_STATIC);char *out=sqlite3_step(s)==SQLITE_ROW?copy_column(s,0):0;sqlite3_finalize(s);return out;}
static int number(sqlite3 *db,const char *json,const char *path,int64_t *out){sqlite3_stmt *s=0;if(prep(db,"SELECT json_extract(?1,?2) WHERE json_type(?1,?2)='integer'",&s)<0)return 0;sqlite3_bind_text(s,1,json,-1,SQLITE_STATIC);sqlite3_bind_text(s,2,path,-1,SQLITE_STATIC);int ok=sqlite3_step(s)==SQLITE_ROW;if(ok)*out=sqlite3_column_int64(s,0);sqlite3_finalize(s);return ok;}
static int valid_json(sqlite3 *db,const char *json){return json&&strlen(json)<=MAX_JSON&&truth(db,"SELECT CASE WHEN json_valid(?1) THEN NOT EXISTS(SELECT 1 FROM json_tree(?1) WHERE type='text' AND instr(atom,char(0))>0) AND (SELECT count(*)=count(DISTINCT fullkey) FROM json_tree(?1)) ELSE 0 END",json);}
static int source_row(sqlite3 *master,const char *table,const char *row){
 int64_t id=0;if(!allowed_table(table)||!number(master,row,"$.id",&id)||id<1||id>LIMIT)return ODOV_UNSUPPORTED;
 char *sql=sqlite3_mprintf("SELECT 1 FROM \"%w\" WHERE id=?1",table);sqlite3_stmt *s=0;
 int rc=sql?prep(master,sql,&s):ODOV_MEMORY;sqlite3_free(sql);if(rc<0)return rc;
 sqlite3_bind_int64(s,1,id);int exists=sqlite3_step(s)==SQLITE_ROW;sqlite3_finalize(s);if(!exists)return ODOV_UNSUPPORTED;
 if(prep(master,"SELECT key,value FROM json_each(?1)",&s)<0)return ODOV_DATABASE;
 sqlite3_bind_text(s,1,row,-1,SQLITE_STATIC);int step;
 while((step=sqlite3_step(s))==SQLITE_ROW){
  const char *column=(const char *)sqlite3_column_text(s,0);size_t n=column?strlen(column):0;
  if(n>3&&!strcmp(column+n-3,"_id")&&!known_reference(column)){
   char *q=sqlite3_mprintf("SELECT \"%w\" IS ?2 FROM \"%w\" WHERE id=?1",column,table);sqlite3_stmt *base=0;
   rc=q?prep(master,q,&base):ODOV_MEMORY;sqlite3_free(q);if(rc<0){sqlite3_finalize(s);return rc;}
   sqlite3_bind_int64(base,1,id);sqlite3_bind_value(base,2,sqlite3_column_value(s,1));int same=sqlite3_step(base)==SQLITE_ROW&&sqlite3_column_int(base,0);sqlite3_finalize(base);
   if(!same){sqlite3_finalize(s);return ODOV_UNSUPPORTED;}
  }
 }
 sqlite3_finalize(s);return step==SQLITE_DONE?0:ODOV_DATABASE;
}
static int each_row(sqlite3 *master,sqlite3 *sidecar,const document *d){
 sqlite3_stmt *s=0,*insert=0;
 const char *sql="SELECT 'cards',json_extract(?1,'$.card') UNION ALL SELECT t.key,r.value FROM json_each(?1,'$.tables') t,json_each(t.value) r";
 if(prep(master,sql,&s)<0)return ODOV_DATABASE;
 sqlite3_bind_text(s,1,d->document,-1,SQLITE_STATIC);
 if(sidecar&&prep(sidecar,"INSERT INTO overlay_rows VALUES(?1,?2,?3,?4,json(?5))",&insert)<0){sqlite3_finalize(s);return ODOV_DATABASE;}
 int step,count=0,rc=0;
 while((step=sqlite3_step(s))==SQLITE_ROW){
  const char *table=(const char *)sqlite3_column_text(s,0),*row=(const char *)sqlite3_column_text(s,1);int64_t id=0;
  if(++count>10001||!row||(rc=source_row(master,table,row))<0)break;
  if(insert){
   if(!number(master,row,"$.id",&id)){rc=ODOV_UNSUPPORTED;break;}
   sqlite3_reset(insert);sqlite3_clear_bindings(insert);sqlite3_bind_text(insert,1,d->id,-1,SQLITE_STATIC);sqlite3_bind_int64(insert,2,d->version);sqlite3_bind_text(insert,3,table,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(insert,4,id);sqlite3_bind_text(insert,5,row,-1,SQLITE_TRANSIENT);
   if(sqlite3_step(insert)!=SQLITE_DONE){rc=ODOV_DATABASE;break;}
  }
 }
 if(rc==0&&step!=SQLITE_DONE)rc=ODOV_UNSUPPORTED;
 sqlite3_finalize(s);sqlite3_finalize(insert);return rc;
}
static int open_store(const char *path,const char *master_path,const char *content,const char *scope,sqlite3 **out){
 *out=0;struct stat ms,ss;if(stat(master_path,&ms))return ODOV_INVALID;
 int created=0,fd=open(path,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0600);
 if(fd>=0){close(fd);created=1;}else{
  if(lstat(path,&ss)||!S_ISREG(ss.st_mode)||(ss.st_mode&0077)||(ms.st_dev==ss.st_dev&&ms.st_ino==ss.st_ino))return ODOV_IDENTITY;
  odov_reader *check=0;int rc=odov_open(path,content,scope,&check);odov_close(check);if(rc<0)return rc;
 }
 sqlite3 *db=0;if(sqlite3_open_v2(path,&db,SQLITE_OPEN_READWRITE|SQLITE_OPEN_NOMUTEX|SQLITE_OPEN_NOFOLLOW,0)!=SQLITE_OK){if(db)sqlite3_close(db);return ODOV_DATABASE;}
 sqlite3_busy_timeout(db,3000);sqlite3_limit(db,SQLITE_LIMIT_LENGTH,MAX_JSON);
 if(exec(db,"PRAGMA trusted_schema=OFF;PRAGMA foreign_keys=ON;PRAGMA journal_mode=DELETE;PRAGMA synchronous=FULL")<0)goto bad;
 if(created){
  if(exec(db,"BEGIN IMMEDIATE;PRAGMA application_id=1329876822")<0)goto bad;
  for(unsigned i=0;i<sizeof(ddl)/sizeof(*ddl);i++)if(exec(db,ddl[i])<0)goto bad;
  sqlite3_stmt *s=0;if(prep(db,"INSERT INTO overlay_meta VALUES('schema','1'),('content_id',?1),('save_scope_sha256',?2),('projection_generation','0')",&s)<0)goto bad;
  sqlite3_bind_text(s,1,content,-1,SQLITE_STATIC);sqlite3_bind_text(s,2,scope,-1,SQLITE_STATIC);int step=sqlite3_step(s);sqlite3_finalize(s);if(step!=SQLITE_DONE||exec(db,"COMMIT")<0)goto bad;
 }
 *out=db;return 0;
bad:
 sqlite3_exec(db,"ROLLBACK",0,0,0);sqlite3_close(db);return ODOV_DATABASE;
}
int odov_reconcile(const char *path,const char *master_path,const char *content,const char *scope,const odov_projection_host *host,char **receipt){
 if(!receipt)return ODOV_INVALID;
 *receipt=0;
 if(!path||!*path||!master_path||!*master_path||!content_hash(content)||!hex(scope,64)||!host||!host->snapshot||!host->definition||!host->ack||!host->release_json||!host->sha256)return ODOV_INVALID;
 sqlite3 *master=0,*db=0;sqlite3_stmt *s=0;char *snapshot=0,*state=0,*save_id=0,*profile=0,*actual_content=0,*scope_json=0,*persisted=0,*ack=0;document *docs=0;int count=0,rc=ODOV_DATABASE;int64_t generation=0,applied=0;
 if(sqlite3_open_v2(master_path,&master,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOMUTEX|SQLITE_OPEN_NOFOLLOW,0)!=SQLITE_OK)goto done;
 sqlite3_limit(master,SQLITE_LIMIT_LENGTH,MAX_JSON);
 if(exec(master,"PRAGMA query_only=ON;PRAGMA trusted_schema=OFF")<0)goto done;
 if(host->snapshot(host->context,&snapshot)<0||!valid_json(master,snapshot)){rc=ODOV_HOST;goto done;}
 if(!truth(master,"SELECT (SELECT count(*)=3 FROM json_each(?1)) AND json_type(?1,'$.state')='object'",snapshot)||!number(master,snapshot,"$.generation",&generation)||!number(master,snapshot,"$.applied_generation",&applied)||generation<1||generation>LIMIT||applied<0||applied>generation){rc=ODOV_INVALID;goto done;}
 state=text(master,snapshot,"$.state");save_id=text(master,state,"$.save_identity");profile=text(master,state,"$.profile_id");actual_content=text(master,state,"$.content_id");
 if(!state||!hex(save_id,32)||!key(profile,127)||!actual_content||strcmp(actual_content,content)||!truth(master,"SELECT (SELECT count(*)=7 FROM json_each(?1)) AND json_extract(?1,'$.format')='od-native-creator-projection' AND json_type(?1,'$.schema_version')='integer' AND json_extract(?1,'$.schema_version')=1 AND json_type(?1,'$.definitions')='array' AND json_type(?1,'$.bindings')='array' AND json_array_length(?1,'$.definitions')<=10000 AND json_array_length(?1,'$.bindings')<=100000",state)){rc=ODOV_IDENTITY;goto done;}
 if(prep(master,"SELECT json_array(?1,?2,?3)",&s)<0)goto done;
 sqlite3_bind_text(s,1,save_id,-1,SQLITE_STATIC);sqlite3_bind_text(s,2,profile,-1,SQLITE_STATIC);sqlite3_bind_text(s,3,content,-1,SQLITE_STATIC);scope_json=sqlite3_step(s)==SQLITE_ROW?copy_column(s,0):0;sqlite3_finalize(s);s=0;
 char scope_hash[65]={0};if(!scope_json||host->sha256(host->context,scope_json,strlen(scope_json),scope_hash)<0||!hex(scope_hash,64)||strcmp(scope_hash,scope)){rc=ODOV_IDENTITY;goto done;}
 if(prep(master,"SELECT count(*) FROM json_each(?1,'$.definitions')",&s)<0)goto done;
 sqlite3_bind_text(s,1,state,-1,SQLITE_STATIC);if(sqlite3_step(s)!=SQLITE_ROW)goto done;count=sqlite3_column_int(s,0);sqlite3_finalize(s);s=0;
 docs=sqlite3_malloc64((sqlite3_uint64)(count?count:1)*sizeof(*docs));if(!docs){rc=ODOV_MEMORY;goto done;}memset(docs,0,(size_t)(count?count:1)*sizeof(*docs));
 if(prep(master,"SELECT json_extract(refs.value,'$.definition_id'),json_extract(refs.value,'$.version'),json_type(refs.value,'$.definition_id'),json_type(refs.value,'$.version'),(SELECT count(*) FROM json_each(refs.value)) FROM json_each(?1,'$.definitions') AS refs",&s)<0)goto done;
 sqlite3_bind_text(s,1,state,-1,SQLITE_STATIC);size_t total=0;int index=0,step;
 while((step=sqlite3_step(s))==SQLITE_ROW){
  document *d=&docs[index++];d->id=copy_column(s,0);d->version=sqlite3_column_int64(s,1);
  const char *id_type=(const char *)sqlite3_column_text(s,2),*version_type=(const char *)sqlite3_column_text(s,3);
  if(!key(d->id,100)||!id_type||strcmp(id_type,"text")||!version_type||strcmp(version_type,"integer")||sqlite3_column_int(s,4)!=2||d->version<1||d->version>LIMIT){rc=ODOV_INVALID;goto done;}
  char *raw=0;if(host->definition(host->context,generation,d->id,d->version,&raw)<0||!valid_json(master,raw)){if(raw)host->release_json(host->context,raw);rc=ODOV_HOST;goto done;}
  d->document=sqlite3_mprintf("%s",raw);host->release_json(host->context,raw);if(!d->document){rc=ODOV_MEMORY;goto done;}total+=strlen(d->document);if(total>MAX_TOTAL){rc=ODOV_UNSUPPORTED;goto done;}
  char *id=text(master,d->document,"$.definition_id"),*source=text(master,d->document,"$.source.content_id");int64_t version=0;
  int shape=truth(master,"SELECT json_extract(?1,'$.format')='offline-dokkan-definition' AND json_extract(?1,'$.schema_version')=1 AND json_type(?1,'$.fully_awakened')='true' AND json_type(?1,'$.card')='object' AND json_type(?1,'$.tables')='object' AND NOT EXISTS(SELECT 1 FROM json_each(?1) WHERE key NOT IN('format','schema_version','definition_id','version','source','rarity','fully_awakened','card','tables','creator')) AND NOT EXISTS(SELECT 1 FROM json_each(?1,'$.tables') WHERE key='cards' OR type!='array')",d->document);
  int match=id&&source&&!strcmp(id,d->id)&&!strcmp(source,content)&&number(master,d->document,"$.version",&version)&&version==d->version;sqlite3_free(id);sqlite3_free(source);
  if(!shape||!match){rc=ODOV_UNSUPPORTED;goto done;}
  if((rc=each_row(master,0,d))<0)goto done;
  if(host->sha256(host->context,d->document,strlen(d->document),d->digest)<0||!hex(d->digest,64)){rc=ODOV_HOST;goto done;}
 }
 sqlite3_finalize(s);s=0;if(step!=SQLITE_DONE){rc=ODOV_DATABASE;goto done;}
 rc=open_store(path,master_path,content,scope,&db);if(rc<0)goto done;
 if(exec(db,"BEGIN IMMEDIATE")<0){rc=ODOV_DATABASE;goto done;}
 if(prep(db,"SELECT CAST(value AS INTEGER) FROM overlay_meta WHERE key='projection_generation'",&s)<0)goto done;
 int64_t previous=sqlite3_step(s)==SQLITE_ROW?sqlite3_column_int64(s,0):-1;sqlite3_finalize(s);s=0;if(previous<0||generation<previous){rc=ODOV_REVISION;goto done;}
 if(previous==generation){
  if(prep(db,"SELECT value FROM overlay_meta WHERE key='projection_state'",&s)<0)goto done;
  int saved=sqlite3_step(s);
  if(saved==SQLITE_ROW&&od_json_semantic_equal(db,(const char *)sqlite3_column_text(s,0),state)!=1){rc=ODOV_CONFLICT;goto done;}
  if(saved!=SQLITE_ROW&&saved!=SQLITE_DONE){rc=ODOV_DATABASE;goto done;}
  sqlite3_finalize(s);s=0;
 }
 for(int i=0;i<count;i++){
  document *d=&docs[i];if(prep(db,"SELECT document,digest FROM overlay_revisions WHERE definition_id=?1 AND version=?2",&s)<0)goto done;
  sqlite3_bind_text(s,1,d->id,-1,SQLITE_STATIC);sqlite3_bind_int64(s,2,d->version);step=sqlite3_step(s);
  if(step==SQLITE_ROW){
   const char *stored=(const char *)sqlite3_column_text(s,0),*digest=(const char *)sqlite3_column_text(s,1);char verified[65]={0};
   if(!stored||!digest||host->sha256(host->context,stored,strlen(stored),verified)<0||!hex(verified,64)||strcmp(verified,digest)){rc=ODOV_IDENTITY;goto done;}
   if(od_json_semantic_equal(db,stored,d->document)!=1){rc=ODOV_CONFLICT;goto done;}
  }
  if(step!=SQLITE_ROW&&step!=SQLITE_DONE){rc=ODOV_DATABASE;goto done;}sqlite3_finalize(s);s=0;
  if(prep(db,"INSERT OR IGNORE INTO overlay_revisions VALUES(?1,?2,?3,?4,?5)",&s)<0)goto done;
  sqlite3_bind_text(s,1,d->id,-1,SQLITE_STATIC);sqlite3_bind_int64(s,2,d->version);sqlite3_bind_text(s,3,d->document,-1,SQLITE_STATIC);sqlite3_bind_text(s,4,d->digest,-1,SQLITE_STATIC);sqlite3_bind_int64(s,5,generation);step=sqlite3_step(s);sqlite3_finalize(s);s=0;if(step!=SQLITE_DONE){rc=ODOV_DATABASE;goto done;}
 }
 if(exec(db,"DELETE FROM overlay_bindings;DELETE FROM overlay_heads")<0)goto done;
 for(int i=0;i<count;i++){
  document *d=&docs[i];if(prep(db,"INSERT INTO overlay_heads VALUES(?1,?2) ON CONFLICT(definition_id) DO UPDATE SET version=max(version,excluded.version)",&s)<0)goto done;
  sqlite3_bind_text(s,1,d->id,-1,SQLITE_STATIC);sqlite3_bind_int64(s,2,d->version);step=sqlite3_step(s);sqlite3_finalize(s);s=0;if(step!=SQLITE_DONE)goto done;
  if(prep(db,"DELETE FROM overlay_rows WHERE definition_id=?1 AND version=?2",&s)<0)goto done;
  sqlite3_bind_text(s,1,d->id,-1,SQLITE_STATIC);sqlite3_bind_int64(s,2,d->version);step=sqlite3_step(s);sqlite3_finalize(s);s=0;if(step!=SQLITE_DONE)goto done;
  if((rc=each_row(master,db,d))<0)goto done;
 }
 if(prep(master,"SELECT json_extract(value,'$.instance_id'),json_extract(value,'$.definition_id'),json_extract(value,'$.version'),json_type(value,'$.instance_id'),json_type(value,'$.version') FROM json_each(?1,'$.bindings')",&s)<0)goto done;
 sqlite3_bind_text(s,1,state,-1,SQLITE_STATIC);
 while((step=sqlite3_step(s))==SQLITE_ROW){
  int64_t instance=sqlite3_column_int64(s,0),version=sqlite3_column_int64(s,2);const char *id=(const char *)sqlite3_column_text(s,1),*itype=(const char *)sqlite3_column_text(s,3),*vtype=(const char *)sqlite3_column_text(s,4);sqlite3_stmt *b=0;
  if(instance<1||instance>LIMIT||!key(id,100)||!itype||strcmp(itype,"integer")||!vtype||strcmp(vtype,"integer")){rc=ODOV_INVALID;goto done;}
  if(prep(db,"INSERT INTO overlay_bindings SELECT 'instance:'||?1,definition_id FROM overlay_heads WHERE definition_id=?2 AND version=?3",&b)<0)goto done;
  sqlite3_bind_int64(b,1,instance);sqlite3_bind_text(b,2,id,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(b,3,version);int inserted=sqlite3_step(b);sqlite3_finalize(b);if(inserted!=SQLITE_DONE||sqlite3_changes(db)!=1){rc=ODOV_UNSUPPORTED;goto done;}
 }
 sqlite3_finalize(s);s=0;if(step!=SQLITE_DONE){rc=ODOV_DATABASE;goto done;}
 if(prep(db,"UPDATE overlay_meta SET value=CAST(?1 AS TEXT) WHERE key='projection_generation'",&s)<0)goto done;
 sqlite3_bind_int64(s,1,generation);step=sqlite3_step(s);sqlite3_finalize(s);s=0;if(step!=SQLITE_DONE)goto done;
 if(prep(db,"INSERT INTO overlay_meta VALUES('projection_state',?1) ON CONFLICT(key) DO UPDATE SET value=excluded.value",&s)<0)goto done;
 sqlite3_bind_text(s,1,state,-1,SQLITE_STATIC);step=sqlite3_step(s);sqlite3_finalize(s);s=0;if(step!=SQLITE_DONE||exec(db,"COMMIT")<0)goto done;
 sqlite3_close(db);db=0;
 odov_reader *readback=0;rc=odov_open(path,content,scope,&readback);if(rc<0)goto done;rc=odov_projection_state(readback,generation,&persisted);odov_close(readback);if(rc!=ODOV_FOUND){if(rc>=0)rc=ODOV_DATABASE;goto done;}
 if(od_json_semantic_equal(master,state,persisted)!=1){rc=ODOV_IDENTITY;goto done;}
 if(host->ack(host->context,generation,persisted,&ack)<0||!valid_json(master,ack)){rc=ODOV_HOST;goto done;}
 char *ack_content=text(master,ack,"$.content_id"),*ack_save=text(master,ack,"$.save_identity"),*ack_profile=text(master,ack,"$.profile_id");int64_t ack_generation=0,ack_applied=0;
 int ack_ok=ack_content&&ack_save&&ack_profile&&!strcmp(ack_content,content)&&!strcmp(ack_save,save_id)&&!strcmp(ack_profile,profile)&&number(master,ack,"$.generation",&ack_generation)&&number(master,ack,"$.applied_generation",&ack_applied)&&ack_generation==generation&&ack_applied==generation;
 sqlite3_free(ack_content);sqlite3_free(ack_save);sqlite3_free(ack_profile);if(!ack_ok){rc=ODOV_HOST;goto done;}
 *receipt=sqlite3_mprintf("%s",ack);rc=*receipt?ODOV_OK:ODOV_MEMORY;
done:
 sqlite3_finalize(s);if(db){sqlite3_exec(db,"ROLLBACK",0,0,0);sqlite3_close(db);}if(master)sqlite3_close(master);
 if(snapshot)host->release_json(host->context,snapshot);
 if(ack)host->release_json(host->context,ack);
 sqlite3_free(state);sqlite3_free(save_id);sqlite3_free(profile);sqlite3_free(actual_content);sqlite3_free(scope_json);odov_free(persisted);
 if(docs){for(int i=0;i<count;i++){sqlite3_free(docs[i].id);sqlite3_free(docs[i].document);}sqlite3_free(docs);}
 if(!*receipt&&rc>=0)rc=ODOV_DATABASE;
 if(rc<0){odov_free(*receipt);*receipt=0;}return rc;
}
