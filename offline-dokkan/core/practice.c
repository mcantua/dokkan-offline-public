#include "practice.h"
#include <stdint.h>
#include <string.h>

#define OD_PRACTICE_LIMIT INT64_C(9007199254740991)
static const char schema_sql[]=
 "CREATE TABLE offline_practice_sessions("
 "profile TEXT NOT NULL REFERENCES profiles(id),session_id TEXT NOT NULL CHECK(length(CAST(session_id AS BLOB)) BETWEEN 1 AND 127 AND instr(session_id,char(0))=0 AND session_id NOT GLOB '*[^A-Za-z0-9_.:-]*'),"
 "content_id TEXT NOT NULL,phase_number INTEGER NOT NULL CHECK(phase_number=3),"
 "parameters_sha256 TEXT NOT NULL CHECK(length(CAST(parameters_sha256 AS BLOB))=64 AND instr(parameters_sha256,char(0))=0 AND parameters_sha256 NOT GLOB '*[^0-9a-f]*'),"
 "state TEXT NOT NULL CHECK(state IN('prepared','native-finish-observed')),"
 "prepared_revision INTEGER NOT NULL CHECK(prepared_revision BETWEEN 1 AND 9007199254740991),"
 "finish_revision INTEGER CHECK(finish_revision BETWEEN 1 AND 9007199254740991),"
 "PRIMARY KEY(profile,session_id),CHECK((state='prepared' AND finish_revision IS NULL) OR (state='native-finish-observed' AND finish_revision>prepared_revision))) STRICT;"
 "PRAGMA user_version=15;";
const char *od_practice_schema_sql(void){return schema_sql;}
static int fail(char **error,const char *reason){if(error)*error=sqlite3_mprintf("%s",reason);return -1;}
static int prepare(sqlite3 *db,sqlite3_stmt **s,const char *sql){*s=NULL;return sqlite3_prepare_v2(db,sql,-1,s,NULL)==SQLITE_OK;}
static int bind(sqlite3_stmt *s,int index,const char *text){return sqlite3_bind_text(s,index,text,-1,SQLITE_TRANSIENT)==SQLITE_OK;}
static int phase_hash(sqlite3 *master,od_practice_digest digest,char hash[65]){
 sqlite3_stmt *s=NULL;
 if(!master||!digest||!prepare(master,&s,"SELECT parameters FROM tutorial_phases WHERE number=3 AND tutorial_scene_url='internal:Tutorial::BattleSetupScene' AND json_valid(parameters) AND json_type(parameters)='object'"))return 0;
 int rc=sqlite3_step(s),ok=rc==SQLITE_ROW;
 if(ok){int bytes=sqlite3_column_bytes(s,0);const void *parameters=sqlite3_column_text(s,0);
  ok=parameters&&bytes>0&&bytes<=65536;if(ok)digest(parameters,(size_t)bytes,hash);
  if(sqlite3_step(s)!=SQLITE_DONE)ok=0;}
 sqlite3_finalize(s);return ok;
}
int od_practice_snapshot(sqlite3 *db,const char *profile,char **json,char **error){
 if(error){*error=NULL;}
 if(!json)return fail(error,"INVALID_PRACTICE_SNAPSHOT");
 *json=NULL;
 sqlite3_stmt *s=NULL;
 const char *sql="SELECT json_object('policy','offline-original-practice-v1','prepared_count',(SELECT count(*) FROM offline_practice_sessions WHERE profile=?1 AND state='prepared'),'native_finish_count',(SELECT count(*) FROM offline_practice_sessions WHERE profile=?1 AND state='native-finish-observed'),'latest',json(COALESCE((SELECT json_object('session_id',session_id,'phase_number',phase_number,'parameters_sha256',parameters_sha256,'state',state,'prepared_revision',prepared_revision,'finish_revision',finish_revision) FROM offline_practice_sessions WHERE profile=?1 ORDER BY prepared_revision DESC,session_id DESC LIMIT 1),'null')))";
 if(!prepare(db,&s,sql)||!bind(s,1,profile)){sqlite3_finalize(s);return fail(error,"PRACTICE_STORAGE_FAILURE");}
 int rc=sqlite3_step(s);if(rc==SQLITE_ROW){*json=sqlite3_mprintf("%s",sqlite3_column_text(s,0));rc=sqlite3_step(s);}
 sqlite3_finalize(s);return rc==SQLITE_DONE&&*json?0:fail(error,"PRACTICE_SNAPSHOT_UNAVAILABLE");
}
int od_practice_validate(sqlite3 *db,sqlite3 *master,od_practice_digest digest){
 sqlite3_stmt *s=NULL;const char *invalid="SELECT 1 FROM offline_practice_sessions x LEFT JOIN profiles p ON p.id=x.profile WHERE p.id IS NULL OR x.content_id!=(SELECT v FROM meta WHERE k='content') OR x.phase_number!=3 OR length(CAST(x.parameters_sha256 AS BLOB))!=64 OR instr(x.parameters_sha256,char(0))>0 OR x.parameters_sha256 GLOB '*[^0-9a-f]*' OR x.session_id GLOB '*[^A-Za-z0-9_.:-]*' OR length(CAST(x.session_id AS BLOB)) NOT BETWEEN 1 AND 127 OR instr(x.session_id,char(0))>0 OR x.prepared_revision NOT BETWEEN 1 AND p.revision OR x.state NOT IN('prepared','native-finish-observed') OR (x.state='prepared' AND x.finish_revision IS NOT NULL) OR (x.state='native-finish-observed' AND (x.finish_revision IS NULL OR x.finish_revision<=x.prepared_revision OR x.finish_revision>p.revision)) LIMIT 1";
 if(!prepare(db,&s,invalid))return 0;
 int ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 if(!prepare(db,&s,"SELECT DISTINCT parameters_sha256 FROM offline_practice_sessions"))return 0;
 int rc=sqlite3_step(s);if(rc==SQLITE_DONE){sqlite3_finalize(s);return 1;}
 char expected[65];if(rc!=SQLITE_ROW||!phase_hash(master,digest,expected)){sqlite3_finalize(s);return 0;}
 do{const char *actual=(const char*)sqlite3_column_text(s,0);if(!actual||strcmp(actual,expected)){ok=0;break;}rc=sqlite3_step(s);}while(rc==SQLITE_ROW);
 sqlite3_finalize(s);return ok&&rc==SQLITE_DONE;
}
int od_practice_apply(sqlite3 *db,sqlite3 *master,const char *profile,sqlite3_int64 revision,
 const char *operation,const char *payload,od_practice_digest digest,char **json,char **error){
 if(error){*error=NULL;}
 if(!json)return fail(error,"INVALID_PRACTICE_TRANSACTION");
 *json=NULL;
 int begin=operation&&!strcmp(operation,"practice.begin");
 if(!db||!profile||!payload||revision<0||revision>=OD_PRACTICE_LIMIT||sqlite3_get_autocommit(db)||
    (!begin&&(!operation||strcmp(operation,"practice.finish"))))return fail(error,"INVALID_PRACTICE_TRANSACTION");
 sqlite3_stmt *s=NULL;
 const char *check="SELECT CASE WHEN json_valid(?1) THEN json_type(?1)='object' AND (SELECT count(*)=3 AND count(DISTINCT key)=3 FROM json_each(?1)) AND NOT EXISTS(SELECT 1 FROM json_each(?1) WHERE key NOT IN('session_id','parameters_sha256','phase_number')) AND json_type(?1,'$.session_id')='text' AND length(json_extract(?1,'$.session_id')) BETWEEN 1 AND 127 AND json_extract(?1,'$.session_id') NOT GLOB '*[^A-Za-z0-9_.:-]*' AND json_type(?1,'$.parameters_sha256')='text' AND length(json_extract(?1,'$.parameters_sha256'))=64 AND json_extract(?1,'$.parameters_sha256') NOT GLOB '*[^0-9a-f]*' AND json_type(?1,'$.phase_number')='integer' AND json_extract(?1,'$.phase_number')=3 ELSE 0 END";
 if(!prepare(db,&s,check)||!bind(s,1,payload)){sqlite3_finalize(s);return fail(error,"PRACTICE_STORAGE_FAILURE");}
 int valid=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);s=NULL;
 if(!valid)return fail(error,"INVALID_PRACTICE_PAYLOAD");
 char expected[65];if(!phase_hash(master,digest,expected))return fail(error,"PRACTICE_SOURCE_PHASE_UNAVAILABLE");
 if(!prepare(db,&s,"SELECT json_extract(?1,'$.parameters_sha256')=?2")||!bind(s,1,payload)||!bind(s,2,expected)){sqlite3_finalize(s);return fail(error,"PRACTICE_STORAGE_FAILURE");}
 valid=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);s=NULL;
 if(!valid)return fail(error,"PRACTICE_SOURCE_HASH_MISMATCH");
 if(!prepare(db,&s,"SELECT revision=?2 FROM profiles WHERE id=?1")||!bind(s,1,profile)||sqlite3_bind_int64(s,2,revision)!=SQLITE_OK){sqlite3_finalize(s);return fail(error,"PRACTICE_STORAGE_FAILURE");}
 valid=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);s=NULL;
 if(!valid)return fail(error,"ORIGINAL_PLAYER_REVISION_CHANGED");
 if(!prepare(db,&s,"SELECT state,parameters_sha256 FROM offline_practice_sessions WHERE profile=?1 AND session_id=json_extract(?2,'$.session_id')")||!bind(s,1,profile)||!bind(s,2,payload)){sqlite3_finalize(s);return fail(error,"PRACTICE_STORAGE_FAILURE");}
 int rc=sqlite3_step(s),found=rc==SQLITE_ROW,finished=found&&!strcmp((const char*)sqlite3_column_text(s,0),"native-finish-observed");
 valid=!found||(sqlite3_column_text(s,1)&&!strcmp((const char*)sqlite3_column_text(s,1),expected));sqlite3_finalize(s);s=NULL;
 if((rc!=SQLITE_ROW&&rc!=SQLITE_DONE)||!valid)return fail(error,"PRACTICE_SESSION_CONFLICT");
 if(begin&&finished)return fail(error,"PRACTICE_SESSION_ALREADY_FINISHED");
 if(!begin&&!found)return fail(error,"PRACTICE_SESSION_NOT_FOUND");
 int replay=(begin&&found)||(!begin&&finished);
 if(!replay){
  const char *sql=begin?"INSERT INTO offline_practice_sessions(profile,session_id,content_id,phase_number,parameters_sha256,state,prepared_revision,finish_revision) VALUES(?1,json_extract(?2,'$.session_id'),(SELECT v FROM meta WHERE k='content'),3,json_extract(?2,'$.parameters_sha256'),'prepared',?3,NULL)":
      "UPDATE offline_practice_sessions SET state='native-finish-observed',finish_revision=?3 WHERE profile=?1 AND session_id=json_extract(?2,'$.session_id') AND state='prepared'";
  if(!prepare(db,&s,sql)||!bind(s,1,profile)||!bind(s,2,payload)||sqlite3_bind_int64(s,3,revision+1)!=SQLITE_OK||sqlite3_step(s)!=SQLITE_DONE||sqlite3_changes(db)!=1){sqlite3_finalize(s);return fail(error,"PRACTICE_STORAGE_FAILURE");}
  sqlite3_finalize(s);s=NULL;
 }
 const char *receipt="SELECT json_object('kind','offline-original-practice-session','profile_id',profile,'session_id',session_id,'content_id',content_id,'phase_number',phase_number,'parameters_sha256',parameters_sha256,'state',state,'prepared_revision',prepared_revision,'finish_revision',finish_revision) FROM offline_practice_sessions WHERE profile=?1 AND session_id=json_extract(?2,'$.session_id')";
 if(!prepare(db,&s,receipt)||!bind(s,1,profile)||!bind(s,2,payload)){sqlite3_finalize(s);return fail(error,"PRACTICE_STORAGE_FAILURE");}
 rc=sqlite3_step(s);if(rc==SQLITE_ROW)*json=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);
 return *json?replay:fail(error,"PRACTICE_RECEIPT_UNAVAILABLE");
}
