#define _POSIX_C_SOURCE 200809L
#include "od_bridge.h"
#include "../core/od_core.h"
#include "sqlite3.h"
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

struct od_bridge { od_core *core; sqlite3 *validator; pthread_mutex_t lock; };
typedef struct { const char *name, *keys; size_t max; } operation;
/* Client code cannot grant rewards, create owned cards directly, inject draw pools,
 * assert asset readiness, supply master paths, or call an unverified game endpoint. */
static const operation operations[] = {
 {"profile.snapshot", "", 1024},
 {"team.set", "'slot','members'", 4096},
 {"card.lock", "'instance_id','locked'", 4096},
 {"card.stats", "'instance_id'", 4096},
 {"card.potential.preview", "'instance_id','requests','released_node_ids'", 256u*1024u},
 {"card.training.preview", "'instance_id','items','field_id'", 32768},
 {"card.sa.train", "'target_instance_id','material_instance_ids','kai_banner_id','kai_banner_version'", 16384},
 {"banner.snapshot", "'banner_id'", 4096},
 {"summon.draw", "'banner_id','kind'", 4096},
 {"creator.import", "'definition'", 16u*1024u*1024u},
 {"creator.finish", "'definition'", 16u*1024u*1024u},
 {"creator.export", "'definition_id','version'", 4096},
 {"creator.library", "", 1024},
 {"tournament.exclusive.library", "", 1024},
 {"upgrade.status", "'instance_id'", 4096},
 {"upgrade.apply", "'instance_id','kind','definition','policy_id','policy_version'", 16u*1024u*1024u},
 {"upgrade.edit", "'instance_id','kind','definition'", 16u*1024u*1024u}
};
static const operation policy_operations[] = {
 {"inventory.grant", "'source','rewards'", 1024u*1024u},
 {"card.add", "'master_id'", 4096},
 {"card.experience.grant", "'instance_id','source','quantity'", 4096},
 {"upgrade.policy.install", "'definition'", 16u*1024u*1024u},
 {"tournament.exclusive.register", "'definition'", 16u*1024u*1024u},
 {"banner.configure", "'banner_id','version','epoch','main_id','policy','pool','creator_epoch'", 16u*1024u*1024u},
 {"run.start", "'run_id','map_id','team_slot','assets_ready','rewards'", 1024u*1024u},
 {"run.finish", "'run_id','outcome'", 4096},
 {"schedule.catalog.install", "'catalog_id','zone','history'", 1024u*1024u},
 {"schedule.rotate", "'catalog_id','now_utc'", 4096},
 {"tournament.configure", "'tournament_id','version','zone','seed','tie_policy','competitors','maps','reward_tiers'", 1024u*1024u},
 {"tournament.snapshot", "'tournament_id','version','now_utc'", 4096},
 {"tournament.enroll_run", "'tournament_id','version','now_utc','run_id'", 4096},
 {"tournament.record_run", "'tournament_id','version','now_utc','run_id'", 4096},
 {"tournament.claim", "'tournament_id','version','now_utc','weekend_id'", 4096},
 {"elder_kai.configure", "'banner_id','version','zone','multi_count','pool'", 1024u*1024u},
 {"elder_kai.draw", "'banner_id','version','now_utc','kind'", 4096}
};
/* These caller shapes deliberately contain no clock, rewards or score. The core's
 * clocked API pins the first native time transactionally and replays original args. */
static const operation clocked_operations[] = {
 {"profile.create", "", 1024},
 {"profile.refresh", "", 1024},
 {"schedule.rotate", "'catalog_id'", 4096},
 {"tournament.snapshot", "'tournament_id','version'", 4096},
 {"tournament.enroll_run", "'tournament_id','version','run_id'", 4096},
 {"tournament.record_run", "'tournament_id','version','run_id'", 4096},
 {"tournament.claim", "'tournament_id','version','weekend_id'", 4096},
 {"elder_kai.draw", "'banner_id','version','kind'", 4096}
};
static int fail(char **error,const char *code) { if(error)*error=sqlite3_mprintf("%s",code);return -1; }
void od_bridge_free(void *p) { od_free(p); }
int od_bridge_open(const char *save,const char *master,const char *content,od_bridge **out,char **error) {
 if(error)*error=NULL;
 if(out)*out=NULL;
 if(!out||!save||!master||!content)return fail(error,"INVALID_HOST_CONFIGURATION");
 od_bridge *b=calloc(1,sizeof(*b));if(!b)return fail(error,"NO_MEMORY");
 if(pthread_mutex_init(&b->lock,NULL)){free(b);return fail(error,"LOCK_FAILED");}
 if(sqlite3_open(":memory:",&b->validator)!=SQLITE_OK||od_open(save,master,content,&b->core)<0){
  if(b->validator)sqlite3_close(b->validator);
  pthread_mutex_destroy(&b->lock);free(b);return fail(error,"OPEN_FAILED");
 }
#ifndef SQLITE_OMIT_LOAD_EXTENSION
 sqlite3_enable_load_extension(b->validator,0);
#endif
 *out=b;return 0;
}
void od_bridge_close(od_bridge *b) {
 if(!b)return;
 pthread_mutex_lock(&b->lock);od_close(b->core);sqlite3_close(b->validator);
 pthread_mutex_unlock(&b->lock);pthread_mutex_destroy(&b->lock);free(b);
}
static int args_valid(od_bridge *b,const operation *op,const char *args) {
 if(!args||strnlen(args,op->max+1)>op->max)return 0;
 sqlite3_stmt *s=NULL;
 if(sqlite3_prepare_v2(b->validator,"SELECT json_valid(?1)",-1,&s,NULL)!=SQLITE_OK)return 0;
 sqlite3_bind_text(s,1,args,-1,SQLITE_TRANSIENT);int ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0)==1;sqlite3_finalize(s);if(!ok)return 0;
 char *sql=*op->keys?sqlite3_mprintf("SELECT json_type(?1)='object' AND NOT EXISTS(SELECT 1 FROM json_each(?1) WHERE key NOT IN(%s)) AND (SELECT count(*)=count(DISTINCT key) FROM json_each(?1))",op->keys):sqlite3_mprintf("SELECT json_type(?1)='object' AND NOT EXISTS(SELECT 1 FROM json_each(?1))");
 if(!sql)return 0;
 if(sqlite3_prepare_v2(b->validator,sql,-1,&s,NULL)!=SQLITE_OK){sqlite3_free(sql);return 0;}
 sqlite3_free(sql);sqlite3_bind_text(s,1,args,-1,SQLITE_TRANSIENT);
 ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0)==1;sqlite3_finalize(s);return ok;
}
static int execute_table(od_bridge *b,const operation *table,size_t count,int clocked,const char *name,const char *profile,const char *command,const char *args,char **result,char **error) {
 if(error)*error=NULL;
 if(result)*result=NULL;
 if(!b||!name||!result)return fail(error,"INVALID_ARGUMENT");
 const operation *op=NULL;
 for(size_t i=0;i<count;i++)if(!strcmp(name,table[i].name)){op=&table[i];break;}
 if(!op)return fail(error,name[0]=='/'?"GAME_WIRE_UNVERIFIED":"UNSUPPORTED_OPERATION");
 pthread_mutex_lock(&b->lock);
 int rc;
 if(!args_valid(b,op,args))rc=fail(error,"INVALID_ARGUMENT");
 else {
  if(clocked){
   time_t now=time(NULL);
   rc=now==(time_t)-1||now<0?fail(error,"CLOCK_UNAVAILABLE"):od_execute_clocked(b->core,name,profile,command,args,(int64_t)now,result);
  }else rc=od_execute(b->core,name,profile,command,args,result);
  if(rc<0){if(!error||!*error)fail(error,od_last_error(b->core));}
  else if(!*result)rc=fail(error,"INVALID_CORE_REPLY");
 }
 pthread_mutex_unlock(&b->lock);return rc;
}
int od_bridge_execute(od_bridge *b,const char *name,const char *profile,const char *command,const char *args,char **result,char **error) {
 if(name)for(size_t i=0;i<sizeof(clocked_operations)/sizeof(clocked_operations[0]);i++)if(!strcmp(name,clocked_operations[i].name))
  return execute_table(b,clocked_operations,sizeof(clocked_operations)/sizeof(clocked_operations[0]),1,name,profile,command,args,result,error);
 return execute_table(b,operations,sizeof(operations)/sizeof(operations[0]),0,name,profile,command,args,result,error);
}
int od_bridge_execute_policy(od_bridge *b,const char *name,const char *profile,const char *command,const char *args,char **result,char **error) {
 return execute_table(b,policy_operations,sizeof(policy_operations)/sizeof(policy_operations[0]),name&&!strcmp(name,"run.start"),name,profile,command,args,result,error);
}
static int projection_reply(od_bridge *b,int rc,char **result,char **error) {
 if(rc<0)return fail(error,od_last_error(b->core));
 return *result?rc:fail(error,"INVALID_CORE_REPLY");
}
int od_bridge_projection_snapshot(od_bridge *b,const char *profile,char **result,char **error) {
 if(error)*error=NULL;
 if(result)*result=NULL;
 if(!b||!profile||!*profile||!result)return fail(error,"INVALID_ARGUMENT");
 pthread_mutex_lock(&b->lock);
 int rc=od_projection_snapshot(b->core,profile,result);
 rc=projection_reply(b,rc,result,error);pthread_mutex_unlock(&b->lock);return rc;
}
int od_bridge_projection_definition(od_bridge *b,const char *profile,int64_t generation,
 const char *definition,int64_t version,char **result,char **error) {
 if(error)*error=NULL;
 if(result)*result=NULL;
 if(!b||!profile||!*profile||!definition||!*definition||!result)return fail(error,"INVALID_ARGUMENT");
 pthread_mutex_lock(&b->lock);
 int rc=od_projection_definition(b->core,profile,generation,definition,version,result);
 rc=projection_reply(b,rc,result,error);pthread_mutex_unlock(&b->lock);return rc;
}
int od_bridge_projection_ack(od_bridge *b,const char *profile,int64_t generation,
 const char *state,char **result,char **error) {
 if(error)*error=NULL;
 if(result)*result=NULL;
 if(!b||!profile||!*profile||!state||!result)return fail(error,"INVALID_ARGUMENT");
 pthread_mutex_lock(&b->lock);
 int rc=od_projection_ack(b->core,profile,generation,state,result);
 rc=projection_reply(b,rc,result,error);pthread_mutex_unlock(&b->lock);return rc;
}
int od_bridge_offline_player_snapshot(od_bridge *b,const char *profile,char **result,char **error) {
 if(error)*error=NULL;
 if(result)*result=NULL;
 if(!b||!profile||!*profile||!result)return fail(error,"INVALID_ARGUMENT");
 pthread_mutex_lock(&b->lock);
 int rc=od_offline_player_snapshot(b->core,profile,result);
 rc=projection_reply(b,rc,result,error);pthread_mutex_unlock(&b->lock);return rc;
}
int od_bridge_creator_finish_receipt(od_bridge *b,const char *profile,const char *command,
 const char *expected,char **result,char **error) {
 if(error)*error=NULL;
 if(result)*result=NULL;
 if(!b||!profile||!*profile||!command||!*command||!expected||!result)return fail(error,"INVALID_ARGUMENT");
 pthread_mutex_lock(&b->lock);
 int rc=od_creator_finish_receipt(b->core,profile,command,expected,result);
 rc=projection_reply(b,rc,result,error);pthread_mutex_unlock(&b->lock);return rc;
}
int od_bridge_creator_finish_bundle(od_bridge *b,const char *profile,const char *command,
 const char *definition,const void *bundle,size_t bundle_len,char **result,char **error) {
 if(error)*error=NULL;
 if(result)*result=NULL;
 if(!b||!profile||!*profile||!command||!*command||!definition||!bundle||!bundle_len||!result)return fail(error,"INVALID_ARGUMENT");
 pthread_mutex_lock(&b->lock);
 int rc=od_creator_finish_bundle(b->core,profile,command,definition,bundle,bundle_len,result);
 rc=projection_reply(b,rc,result,error);pthread_mutex_unlock(&b->lock);return rc;
}
static int save_io(od_bridge *b,const char *path,char **error,int importing) {
 if(error)*error=NULL;
 if(!b||!path)return fail(error,"INVALID_HOST_CONFIGURATION");
 pthread_mutex_lock(&b->lock);int rc=importing?od_import_save(b->core,path):od_export_save(b->core,path);
 if(rc<0)fail(error,od_last_error(b->core));
 pthread_mutex_unlock(&b->lock);return rc;
}
int od_bridge_export(od_bridge *b,const char *path,char **error){return save_io(b,path,error,0);}
int od_bridge_import(od_bridge *b,const char *path,char **error){return save_io(b,path,error,1);}
