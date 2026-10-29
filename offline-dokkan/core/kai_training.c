#include "kai_training.h"
#include "json_values.h"
#include <stdint.h>
#include <string.h>
#define SAFE INT64_C(9007199254740991)
#define MAX_MATERIALS 1000

typedef struct {sqlite3 *db;const char *profile;const char **error;} training;
static int failure(training *t,const char *message){if(t->error)*t->error=message;return -1;}
static sqlite3_stmt *statement(training *t,const char *sql,const char *a,const char *id){
 char *reserved=sqlite3_mprintf("WITH _kai_bind(_p,_a,_id) AS (VALUES(:p,:a,:id)) %s",sql);sqlite3_stmt *s=NULL;
 if(!reserved||sqlite3_prepare_v2(t->db,reserved,-1,&s,NULL)!=SQLITE_OK){sqlite3_free(reserved);failure(t,"KAI_DATABASE_ERROR");return NULL;}sqlite3_free(reserved);
 sqlite3_bind_text(s,1,t->profile?t->profile:"",-1,SQLITE_TRANSIENT);sqlite3_bind_text(s,2,a?a:"",-1,SQLITE_TRANSIENT);sqlite3_bind_text(s,3,id?id:"",-1,SQLITE_TRANSIENT);return s;
}
static int integer(training *t,const char *a,const char *path,sqlite3_int64 lo,sqlite3_int64 hi,sqlite3_int64 *out){
 sqlite3_stmt *s=statement(t,"SELECT json_extract(:a,:id),json_type(:a,:id)",a,path);if(!s)return -1;
 int ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_INTEGER&&sqlite3_column_type(s,1)==SQLITE_TEXT&&!strcmp((const char *)sqlite3_column_text(s,1),"integer");
 if(ok){*out=sqlite3_column_int64(s,0);ok=*out>=lo&&*out<=hi;}sqlite3_finalize(s);return ok?0:failure(t,"INVALID_ARGUMENT");
}
static char *query(training *t,const char *sql,const char *a,const char *id){
 sqlite3_stmt *s=statement(t,sql,a,id);if(!s)return NULL;char *r=NULL;if(sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_type(s,0)!=SQLITE_NULL)r=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);return r;
}
static int changed(training *t,sqlite3_stmt *s){if(!s)return -1;int rc=sqlite3_step(s);sqlite3_finalize(s);return rc==SQLITE_DONE?0:failure(t,"KAI_DATABASE_ERROR");}
static int id_ok(const char *id){if(!id||!*id||strlen(id)>127)return 0;for(;*id;id++)if(!((*id>='a'&&*id<='z')||(*id>='A'&&*id<='Z')||(*id>='0'&&*id<='9')||*id=='-'||*id=='_'||*id=='.'||*id==':'))return 0;return 1;}
const char *od_kai_training_schema(void){return
 "CREATE TABLE sa_training_baselines(instance_id INTEGER PRIMARY KEY REFERENCES owned_cards(id),profile TEXT NOT NULL REFERENCES profiles(id),sa_level INTEGER NOT NULL CHECK(sa_level BETWEEN 1 AND 9007199254740991)) STRICT;"
 "CREATE TABLE sa_training_events(id INTEGER PRIMARY KEY,profile TEXT NOT NULL REFERENCES profiles(id),command_id TEXT NOT NULL,target_instance_id INTEGER NOT NULL REFERENCES owned_cards(id),kai_banner_id TEXT NOT NULL,kai_banner_version INTEGER NOT NULL,target_binding TEXT NOT NULL CHECK(json_valid(target_binding) AND json_type(target_binding)='object'),sa_cap INTEGER NOT NULL CHECK(sa_cap BETWEEN 1 AND 9007199254740991),sa_before INTEGER NOT NULL CHECK(sa_before>=1),sa_after INTEGER NOT NULL CHECK(sa_after>sa_before AND sa_after<=sa_cap),materials TEXT NOT NULL CHECK(json_valid(materials) AND json_type(materials)='array' AND json_array_length(materials) BETWEEN 1 AND 1000),UNIQUE(profile,command_id),FOREIGN KEY(profile,command_id) REFERENCES commands(profile,id) DEFERRABLE INITIALLY DEFERRED,FOREIGN KEY(profile,kai_banner_id,kai_banner_version) REFERENCES elder_kai_configs(profile,id,version)) STRICT;"
 "CREATE TABLE owned_consumptions(instance_id INTEGER PRIMARY KEY REFERENCES owned_cards(id),profile TEXT NOT NULL REFERENCES profiles(id),training_event_id INTEGER NOT NULL REFERENCES sa_training_events(id),ordinal INTEGER NOT NULL CHECK(ordinal BETWEEN 0 AND 999),UNIQUE(training_event_id,ordinal)) STRICT;";}
static int valid_args(training *t,const char *a,sqlite3_int64 *target,sqlite3_int64 *version,int *count,char **banner){
 sqlite3_stmt *s=statement(t,"SELECT CASE WHEN json_valid(:a) THEN json_type(:a)='object' AND (SELECT count(*)=count(DISTINCT fullkey) FROM json_tree(:a)) AND NOT EXISTS(SELECT 1 FROM json_tree(:a) WHERE type='text' AND instr(atom,char(0))>0 OR instr(key,char(0))>0) AND NOT EXISTS(SELECT 1 FROM json_each(:a) WHERE key NOT IN('target_instance_id','material_instance_ids','kai_banner_id','kai_banner_version')) AND json_type(:a,'$.material_instance_ids')='array' AND json_array_length(:a,'$.material_instance_ids') BETWEEN 1 AND 1000 AND NOT EXISTS(SELECT 1 FROM json_each(:a,'$.material_instance_ids') WHERE type!='integer' OR value<1 OR value>9007199254740991) AND json_array_length(:a,'$.material_instance_ids')=(SELECT count(DISTINCT value) FROM json_each(:a,'$.material_instance_ids')) ELSE 0 END",a,NULL);if(!s)return -1;int ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);if(!ok)return failure(t,"INVALID_KAI_MATERIALS");
 if(integer(t,a,"$.target_instance_id",1,SAFE,target)<0||integer(t,a,"$.kai_banner_version",1,SAFE,version)<0)return -1;
 *banner=query(t,"SELECT CASE WHEN json_type(:a,'$.kai_banner_id')='text' THEN json_extract(:a,'$.kai_banner_id') END",a,NULL);if(!id_ok(*banner))return failure(t,"INVALID_ARGUMENT");
 s=statement(t,"SELECT json_array_length(:a,'$.material_instance_ids')",a,NULL);if(!s)return -1;ok=sqlite3_step(s)==SQLITE_ROW;*count=ok?sqlite3_column_int(s,0):0;sqlite3_finalize(s);return ok?0:failure(t,"INVALID_KAI_MATERIALS");
}
static char *policy_document(training *t,const char *banner,sqlite3_int64 version){
 sqlite3_stmt *s=statement(t,"SELECT document FROM elder_kai_configs WHERE profile=:p AND id=:id AND version=?4",NULL,banner);if(!s)return NULL;sqlite3_bind_int64(s,4,version);char *d=sqlite3_step(s)==SQLITE_ROW?sqlite3_mprintf("%s",sqlite3_column_text(s,0)):NULL;sqlite3_finalize(s);return d;
}
static int verified_material(training *t,const char *policy,sqlite3_int64 master){
 sqlite3_stmt *s=statement(t,"SELECT EXISTS(SELECT 1 FROM json_each(:a,'$.pool') WHERE json_type(value,'$.master_id')='integer' AND json_extract(value,'$.master_id')=?4 AND json_type(value,'$.verified_elder_kai')='true' AND json_type(value,'$.super_attack_levels')='integer' AND json_extract(value,'$.super_attack_levels')=1)",policy,NULL);if(!s)return 0;sqlite3_bind_int64(s,4,master);int ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);return ok;
}
int od_kai_training_apply(sqlite3 *save,const char *profile,const char *command,const char *a,od_kai_target_binding_fn resolve,void *context,char **out,const char **error){
 if(out){*out=NULL;}if(error){*error=NULL;}training t={save,profile,error};if(!save||!out||!resolve||sqlite3_get_autocommit(save)||!id_ok(profile)||!id_ok(command))return failure(&t,"KAI_TRANSACTION_REQUIRED");
 sqlite3_int64 target=0,version=0,cap=0,before=0;int count=0,result=-1;char *banner=NULL,*policy=NULL,*binding=NULL,*materials=NULL;sqlite3_stmt *s=NULL;
 if(valid_args(&t,a,&target,&version,&count,&banner)<0)goto done;
 policy=policy_document(&t,banner,version);if(!policy){failure(&t,"KAI_POLICY_NOT_FOUND");goto done;}
 s=statement(&t,"SELECT c.sa_level,EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=c.id),EXISTS(SELECT 1 FROM runs r,json_each(r.team_snapshot) j WHERE r.profile=:p AND r.state='started' AND j.value=c.id) FROM owned_cards c WHERE c.profile=:p AND c.id=?4",a,NULL);if(!s){goto done;}sqlite3_bind_int64(s,4,target);
 if(sqlite3_step(s)!=SQLITE_ROW){sqlite3_finalize(s);failure(&t,"CARD_NOT_OWNED");goto done;}before=sqlite3_column_int64(s,0);int consumed=sqlite3_column_int(s,1),in_run=sqlite3_column_int(s,2);sqlite3_finalize(s);if(consumed){failure(&t,"CARD_CONSUMED");goto done;}if(in_run){failure(&t,"CARD_IN_USE");goto done;}
 if(resolve(context,save,profile,target,NULL,&binding,&cap)<0||!binding||cap<before||cap>SAFE){failure(&t,"KAI_TARGET_CAP_UNAVAILABLE");goto done;}
 if(count>cap-before){failure(&t,"SUPER_ATTACK_CAP_EXCEEDED");goto done;}
 materials=query(&t,"SELECT json_extract(:a,'$.material_instance_ids')",a,NULL);if(!materials)goto done;
 s=statement(&t,"SELECT j.value,c.master_id,COALESCE(p.locked,0),x.instance_id,EXISTS(SELECT 1 FROM teams z,json_each(z.members) k WHERE z.profile=:p AND k.value=j.value),EXISTS(SELECT 1 FROM runs r,json_each(r.team_snapshot) k WHERE r.profile=:p AND r.state='started' AND k.value=j.value),EXISTS(SELECT 1 FROM owned_definitions d WHERE d.instance_id=j.value) OR EXISTS(SELECT 1 FROM tournament_exclusive_owned d WHERE d.instance_id=j.value) OR EXISTS(SELECT 1 FROM official_upgrade_active d WHERE d.profile=:p AND d.master_id=c.master_id) FROM json_each(:a,'$.material_instance_ids') j LEFT JOIN owned_cards c ON c.id=j.value AND c.profile=:p LEFT JOIN owned_progress p ON p.instance_id=c.id LEFT JOIN owned_consumptions x ON x.instance_id=c.id",a,NULL);if(!s){goto done;}int rc;
 while((rc=sqlite3_step(s))==SQLITE_ROW){const char *why=NULL;sqlite3_int64 id=sqlite3_column_int64(s,0),master=sqlite3_column_int64(s,1);
  if(id==target)why="KAI_SELF_FEED_FORBIDDEN";else if(sqlite3_column_type(s,1)==SQLITE_NULL)why="KAI_MATERIAL_NOT_OWNED";else if(sqlite3_column_type(s,3)!=SQLITE_NULL)why="KAI_MATERIAL_CONSUMED";else if(sqlite3_column_int(s,2))why="KAI_MATERIAL_LOCKED";else if(sqlite3_column_int(s,4))why="KAI_MATERIAL_IN_TEAM";else if(sqlite3_column_int(s,5))why="KAI_MATERIAL_IN_RUN";else if(sqlite3_column_int(s,6))why="KAI_MATERIAL_MODIFIED";else if(!verified_material(&t,policy,master))why="KAI_MATERIAL_NOT_VERIFIED";
  if(why){sqlite3_finalize(s);failure(&t,why);goto done;}
 }
 sqlite3_finalize(s);if(rc!=SQLITE_DONE){failure(&t,"KAI_DATABASE_ERROR");goto done;}
 s=statement(&t,"INSERT INTO sa_training_baselines(instance_id,profile,sa_level) VALUES(?4,:p,?5) ON CONFLICT(instance_id) DO NOTHING",a,NULL);if(!s){goto done;}sqlite3_bind_int64(s,4,target);sqlite3_bind_int64(s,5,before);if(changed(&t,s)<0)goto done;
 s=statement(&t,"INSERT INTO sa_training_events(profile,command_id,target_instance_id,kai_banner_id,kai_banner_version,target_binding,sa_cap,sa_before,sa_after,materials) VALUES(:p,:id,?4,?5,?6,json(?7),?8,?9,?10,json(?11))",a,command);if(!s){goto done;}sqlite3_bind_int64(s,4,target);sqlite3_bind_text(s,5,banner,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,6,version);sqlite3_bind_text(s,7,binding,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,8,cap);sqlite3_bind_int64(s,9,before);sqlite3_bind_int64(s,10,before+count);sqlite3_bind_text(s,11,materials,-1,SQLITE_TRANSIENT);if(changed(&t,s)<0)goto done;sqlite3_int64 event=sqlite3_last_insert_rowid(save);
 s=statement(&t,"INSERT INTO owned_consumptions(instance_id,profile,training_event_id,ordinal) SELECT value,:p,?4,key FROM json_each(:a,'$.material_instance_ids')",a,NULL);if(!s){goto done;}sqlite3_bind_int64(s,4,event);if(changed(&t,s)<0)goto done;
 s=statement(&t,"UPDATE owned_cards SET sa_level=?4 WHERE profile=:p AND id=?5 AND sa_level=?6",a,NULL);if(!s){goto done;}sqlite3_bind_int64(s,4,before+count);sqlite3_bind_int64(s,5,target);sqlite3_bind_int64(s,6,before);if(changed(&t,s)<0||sqlite3_changes(save)!=1){failure(&t,"KAI_TARGET_CONFLICT");goto done;}
 s=statement(&t,"SELECT json_object('event_id',?4,'target_instance_id',?5,'sa_before',?6,'sa_after',?7,'sa_cap',?8,'super_attack_levels_added',?9,'material_instance_ids',json(:a),'target_binding',json(:id),'guaranteed_kai_only',json('true'))",materials,binding);if(!s){goto done;}sqlite3_bind_int64(s,4,event);sqlite3_bind_int64(s,5,target);sqlite3_bind_int64(s,6,before);sqlite3_bind_int64(s,7,before+count);sqlite3_bind_int64(s,8,cap);sqlite3_bind_int(s,9,count);if(sqlite3_step(s)==SQLITE_ROW)*out=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);if(!*out){failure(&t,"KAI_NO_MEMORY");goto done;}result=0;
 done:sqlite3_free(banner);sqlite3_free(policy);sqlite3_free(binding);sqlite3_free(materials);return result;
}
int od_kai_training_validate(sqlite3 *save,od_kai_target_binding_fn resolve,void *context){
 if(!save||!resolve)return 0;
 training t={save,NULL,NULL};sqlite3_stmt *s=NULL;int rc,ok=1;
 const char *invalid="SELECT 1 FROM sa_training_baselines b JOIN owned_cards c ON c.id=b.instance_id WHERE c.profile!=b.profile OR NOT EXISTS(SELECT 1 FROM sa_training_events e WHERE e.target_instance_id=b.instance_id AND e.profile=b.profile) UNION ALL SELECT 1 FROM sa_training_events e WHERE NOT EXISTS(SELECT 1 FROM sa_training_baselines b WHERE b.instance_id=e.target_instance_id AND b.profile=e.profile) UNION ALL SELECT 1 FROM sa_training_events e JOIN owned_consumptions x ON x.instance_id=e.target_instance_id WHERE x.training_event_id<=e.id UNION ALL SELECT 1 FROM owned_consumptions x JOIN owned_cards c ON c.id=x.instance_id JOIN sa_training_events e ON e.id=x.training_event_id LEFT JOIN owned_progress p ON p.instance_id=c.id WHERE c.profile!=x.profile OR e.profile!=x.profile OR c.id=e.target_instance_id OR COALESCE(p.locked,0)!=0 OR EXISTS(SELECT 1 FROM owned_definitions d WHERE d.instance_id=c.id) OR EXISTS(SELECT 1 FROM tournament_exclusive_owned d WHERE d.instance_id=c.id) OR EXISTS(SELECT 1 FROM teams z,json_each(z.members) j WHERE z.profile=x.profile AND j.value=x.instance_id) OR EXISTS(SELECT 1 FROM runs r,json_each(r.team_snapshot) j WHERE r.profile=x.profile AND r.state='started' AND j.value=x.instance_id) LIMIT 1";
 if(sqlite3_prepare_v2(save,invalid,-1,&s,NULL)!=SQLITE_OK)return 0;
 ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 if(sqlite3_prepare_v2(save,"SELECT b.instance_id,b.profile,b.sa_level,c.sa_level FROM sa_training_baselines b JOIN owned_cards c ON c.id=b.instance_id ORDER BY b.instance_id",-1,&s,NULL)!=SQLITE_OK)return 0;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  sqlite3_int64 target=sqlite3_column_int64(s,0),expected=sqlite3_column_int64(s,2),current=sqlite3_column_int64(s,3);t.profile=(const char *)sqlite3_column_text(s,1);if(!id_ok(t.profile)){ok=0;break;}
  sqlite3_stmt *events=statement(&t,"SELECT e.id,e.command_id,e.kai_banner_id,e.kai_banner_version,e.target_binding,e.sa_cap,e.sa_before,e.sa_after,e.materials,c.operation,c.input,c.result FROM sa_training_events e LEFT JOIN commands c ON c.profile=e.profile AND c.id=e.command_id WHERE e.profile=:p AND e.target_instance_id=?4 ORDER BY e.id",NULL,NULL);if(!events){ok=0;break;}sqlite3_bind_int64(events,4,target);int er;
  while((er=sqlite3_step(events))==SQLITE_ROW){
   sqlite3_int64 event=sqlite3_column_int64(events,0),version=sqlite3_column_int64(events,3),cap=sqlite3_column_int64(events,5),before=sqlite3_column_int64(events,6),after=sqlite3_column_int64(events,7);const char *command=(const char *)sqlite3_column_text(events,1),*banner=(const char *)sqlite3_column_text(events,2),*binding=(const char *)sqlite3_column_text(events,4),*materials=(const char *)sqlite3_column_text(events,8),*op=(const char *)sqlite3_column_text(events,9),*input=(const char *)sqlite3_column_text(events,10),*result=(const char *)sqlite3_column_text(events,11);
   sqlite3_int64 arg_target=0,arg_version=0,resolved_cap=0;int count=0;char *arg_banner=NULL,*verified_binding=NULL,*policy=NULL,*arg_materials=NULL;
   if(!id_ok(command)||!id_ok(banner)||!op||strcmp(op,"card.sa.train")||!input||valid_args(&t,input,&arg_target,&arg_version,&count,&arg_banner)<0||arg_target!=target||arg_version!=version||strcmp(arg_banner,banner)||before!=expected||after-before!=count||after>cap||resolve(context,save,t.profile,target,binding,&verified_binding,&resolved_cap)<0||!verified_binding||resolved_cap!=cap){ok=0;}
   if(ok){arg_materials=query(&t,"SELECT json_extract(:a,'$.material_instance_ids')",input,NULL);policy=policy_document(&t,banner,version);if(!arg_materials||od_json_semantic_equal(save,arg_materials,materials)!=1||!policy)ok=0;}
   if(ok){
    sqlite3_stmt *teachers=statement(&t,"SELECT j.key,j.value,c.master_id,x.training_event_id,x.ordinal FROM json_each(:a) j LEFT JOIN owned_cards c ON c.id=j.value AND c.profile=:p LEFT JOIN owned_consumptions x ON x.instance_id=c.id",materials,NULL);if(!teachers)ok=0;
    if(teachers){int tr;while((tr=sqlite3_step(teachers))==SQLITE_ROW){if(sqlite3_column_type(teachers,2)==SQLITE_NULL||sqlite3_column_type(teachers,3)==SQLITE_NULL||sqlite3_column_int64(teachers,3)!=event||sqlite3_column_int64(teachers,4)!=sqlite3_column_int64(teachers,0)||!verified_material(&t,policy,sqlite3_column_int64(teachers,2))){ok=0;break;}}sqlite3_finalize(teachers);if(tr!=SQLITE_DONE)ok=0;}
   }
   if(ok){sqlite3_stmt *n=statement(&t,"SELECT count(*)=?4 FROM owned_consumptions WHERE training_event_id=?5",NULL,NULL);if(!n)ok=0;else{sqlite3_bind_int(n,4,count);sqlite3_bind_int64(n,5,event);ok=sqlite3_step(n)==SQLITE_ROW&&sqlite3_column_int(n,0);sqlite3_finalize(n);}}
   if(ok&&result&&strcmp(result,"null")){
    sqlite3_stmt *r=statement(&t,"SELECT od_json_equal(json_extract(:a,'$.sa_training'),json_object('event_id',?4,'target_instance_id',?5,'sa_before',?6,'sa_after',?7,'sa_cap',?8,'super_attack_levels_added',?9,'material_instance_ids',json(:id),'target_binding',json(?10),'guaranteed_kai_only',json('true')))",result,materials);if(!r)ok=0;else{sqlite3_bind_int64(r,4,event);sqlite3_bind_int64(r,5,target);sqlite3_bind_int64(r,6,before);sqlite3_bind_int64(r,7,after);sqlite3_bind_int64(r,8,cap);sqlite3_bind_int(r,9,count);sqlite3_bind_text(r,10,binding,-1,SQLITE_TRANSIENT);ok=sqlite3_step(r)==SQLITE_ROW&&sqlite3_column_int(r,0);sqlite3_finalize(r);}
   }
   sqlite3_free(arg_banner);sqlite3_free(verified_binding);sqlite3_free(policy);sqlite3_free(arg_materials);if(!ok)break;expected=after;
  }
  sqlite3_finalize(events);if(!ok||er!=SQLITE_DONE||current!=expected){ok=0;break;}
  char *binding=NULL;sqlite3_int64 cap=0;if(resolve(context,save,t.profile,target,NULL,&binding,&cap)<0||!binding||current>cap){sqlite3_free(binding);ok=0;break;}sqlite3_free(binding);
 }
 sqlite3_finalize(s);return ok&&rc==SQLITE_DONE;
}
