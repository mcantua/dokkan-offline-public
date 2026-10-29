#include "original_teams.h"
#include <stdint.h>
#include <string.h>
#include <limits.h>

static const char schema_sql[] =
 "CREATE TABLE od_original_team_bindings("
 "profile TEXT NOT NULL,slot INTEGER NOT NULL CHECK(slot BETWEEN 0 AND 19),"
 "native_num INTEGER NOT NULL CHECK(native_num BETWEEN 1 AND 2147483647),"
 "team_name TEXT NOT NULL CHECK(length(CAST(team_name AS BLOB))<=4096 AND instr(team_name,char(0))=0),"
 "bgm_filename TEXT CHECK(bgm_filename IS NULL OR (length(CAST(bgm_filename AS BLOB))<=4096 AND instr(bgm_filename,char(0))=0)),"
 "card_slots TEXT NOT NULL CHECK(json_valid(card_slots) AND json_type(card_slots)='array' AND json_array_length(card_slots)=6),"
 "reference_fields TEXT CHECK(reference_fields IS NULL OR (length(CAST(reference_fields AS BLOB))<=32768 AND json_valid(reference_fields) AND json_type(reference_fields)='object')),"
 "PRIMARY KEY(profile,slot),UNIQUE(profile,native_num),"
 "FOREIGN KEY(profile,slot) REFERENCES teams(profile,slot) ON DELETE CASCADE) STRICT;"
 "CREATE TABLE od_original_team_selection("
 "profile TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,"
 "selected_team_num INTEGER CHECK(selected_team_num IS NULL OR selected_team_num BETWEEN 1 AND 2147483647),"
 "selected_kobetu_team_num INTEGER CHECK(selected_kobetu_team_num IS NULL OR selected_kobetu_team_num BETWEEN 1 AND 2147483647),"
 "advisory_context TEXT NOT NULL DEFAULT '{}' CHECK(length(CAST(advisory_context AS BLOB))<=1024 AND json_valid(advisory_context) AND json_type(advisory_context)='object'),"
 "FOREIGN KEY(profile,selected_team_num) REFERENCES od_original_team_bindings(profile,native_num),"
 "FOREIGN KEY(profile,selected_kobetu_team_num) REFERENCES od_original_team_bindings(profile,native_num)) STRICT;";

const char *od_original_teams_schema_sql(void) { return schema_sql; }
static int fail(char **error,const char *code) {
 if(error)*error=sqlite3_mprintf("%s",code);
 return -1;
}
static int prepare(sqlite3 *db,sqlite3_stmt **s,const char *sql) {
 *s=NULL;
 return sqlite3_prepare_v2(db,sql,-1,s,NULL)==SQLITE_OK;
}
static int text_bind(sqlite3_stmt *s,int index,const char *text) {
 return sqlite3_bind_text(s,index,text,-1,SQLITE_TRANSIENT)==SQLITE_OK;
}
/* SQLite stores text as bytes; reject malformed UTF-8/NUL before retaining an
 * exact native name/resource string. No path or replacement name is invented. */
static int metadata(const unsigned char *s,int n) {
 if(!s||n<0||n>OD_ORIGINAL_TEAM_METADATA_BYTES)return 0;
 for(int i=0;i<n;) {
  uint32_t ch=s[i++];int more=0;uint32_t minimum=0;
  if(ch==0)return 0;
  if(ch<0x80)continue;
  if(ch>=0xc2&&ch<=0xdf){more=1;ch&=31;minimum=0x80;}
  else if(ch>=0xe0&&ch<=0xef){more=2;ch&=15;minimum=0x800;}
  else if(ch>=0xf0&&ch<=0xf4){more=3;ch&=7;minimum=0x10000;}
  else return 0;
  if(i+more>n)return 0;
  while(more--){unsigned char b=s[i++];if((b&0xc0)!=0x80)return 0;ch=(ch<<6)|(b&63);}
  if(ch<minimum||ch>0x10ffff||(ch>=0xd800&&ch<=0xdfff))return 0;
 }
 return 1;
}

static const char reference_validation_sql[]=
 "SELECT length(CAST(?1 AS BLOB))<=32768 AND json_type(?1)='object' "
 "AND (SELECT count(*)=3 AND count(*)=count(DISTINCT key) FROM json_each(?1)) "
 "AND NOT EXISTS(SELECT 1 FROM json_each(?1) WHERE key NOT IN('referenced_sugoroku_map_id','referenced_z_battle_stage_id','referenced_card_ids')) "
 "AND json_type(?1,'$.referenced_sugoroku_map_id')='integer' AND typeof(json_extract(?1,'$.referenced_sugoroku_map_id'))='integer' "
 "AND json_extract(?1,'$.referenced_sugoroku_map_id') BETWEEN -2147483648 AND 2147483647 "
 "AND json_type(?1,'$.referenced_z_battle_stage_id')='integer' AND typeof(json_extract(?1,'$.referenced_z_battle_stage_id'))='integer' "
 "AND json_extract(?1,'$.referenced_z_battle_stage_id') BETWEEN -2147483648 AND 2147483647 "
 "AND json_type(?1,'$.referenced_card_ids')='array' AND json_array_length(?1,'$.referenced_card_ids')<=1024 "
 "AND NOT EXISTS(SELECT 1 FROM json_each(?1,'$.referenced_card_ids') WHERE type!='integer' OR typeof(value)!='integer' OR value NOT BETWEEN -2147483648 AND 2147483647)";
static const char context_validation_sql[]=
 "SELECT length(CAST(?1 AS BLOB))<=1024 AND json_type(?1)='object' "
 "AND (SELECT count(*)=count(DISTINCT key) FROM json_each(?1)) "
 "AND NOT EXISTS(SELECT 1 FROM json_each(?1) WHERE key NOT IN('sugoroku_map_id','z_battle_stage_id','origin_battle_id') OR type!='integer' OR typeof(value)!='integer' OR value NOT BETWEEN 0 AND 4294967295)";
const char *od_original_teams_reference_validation_sql(void) { return reference_validation_sql; }
const char *od_original_teams_context_validation_sql(void) { return context_validation_sql; }
static int valid_metadata_json(sqlite3 *db,const char *json,const char *sql) {
 sqlite3_stmt *s=NULL;
 if(!json||!prepare(db,&s,"SELECT json_valid(?1)")||!text_bind(s,1,json)){sqlite3_finalize(s);return 0;}
 int rc=sqlite3_step(s),ok=rc==SQLITE_ROW&&sqlite3_column_int(s,0)==1;sqlite3_finalize(s);s=NULL;
 if(!ok||!prepare(db,&s,sql)||!text_bind(s,1,json)){sqlite3_finalize(s);return 0;}
 rc=sqlite3_step(s);ok=rc==SQLITE_ROW&&sqlite3_column_int(s,0)==1;sqlite3_finalize(s);return ok;
}
static const char validation_sql[]=
 "SELECT 1 FROM od_original_team_bindings b LEFT JOIN teams t ON t.profile=b.profile AND t.slot=b.slot "
 "WHERE t.profile IS NULL OR b.slot NOT BETWEEN 0 AND 19 OR b.native_num NOT BETWEEN 1 AND 2147483647 OR json_type(b.card_slots)!='array' OR json_array_length(b.card_slots)!=6 "
 "OR EXISTS(SELECT 1 FROM json_each(b.card_slots) j WHERE j.type!='integer' OR typeof(j.value)!='integer' OR j.value<0 "
 "OR j.value>9223372036854775807 OR j.value!=0 AND NOT EXISTS(SELECT 1 FROM owned_cards o "
 "WHERE o.profile=b.profile AND o.id=j.value AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=o.id))) "
 "OR (SELECT count(*)-count(DISTINCT value) FROM json_each(b.card_slots) WHERE value!=0)!=0 "
 "OR json(t.members)!=json((SELECT json_group_array(value) FROM json_each(b.card_slots) WHERE value!=0)) "
 "UNION ALL SELECT 1 FROM od_original_team_selection s WHERE "
 "s.selected_team_num IS NOT NULL AND NOT EXISTS(SELECT 1 FROM od_original_team_bindings b WHERE b.profile=s.profile AND b.native_num=s.selected_team_num) "
 "OR s.selected_kobetu_team_num IS NOT NULL AND NOT EXISTS(SELECT 1 FROM od_original_team_bindings b WHERE b.profile=s.profile AND b.native_num=s.selected_kobetu_team_num) "
 "UNION ALL SELECT 1 FROM od_original_team_bindings GROUP BY profile,native_num HAVING count(*)!=1 "
 "UNION ALL SELECT 1 FROM od_original_team_bindings GROUP BY profile,slot HAVING count(*)!=1 LIMIT 1";
const char *od_original_teams_validation_sql(void) { return validation_sql; }

int od_original_teams_validate(sqlite3 *db) {
 if(!db)return 0;
 sqlite3_stmt *s=NULL;
 if(!prepare(db,&s,validation_sql))return 0;
 int rc=sqlite3_step(s);sqlite3_finalize(s);
 if(rc!=SQLITE_DONE)return 0;
 if(!prepare(db,&s,"SELECT team_name,bgm_filename,reference_fields FROM od_original_team_bindings"))return 0;
 while((rc=sqlite3_step(s))==SQLITE_ROW) {
  if(!metadata(sqlite3_column_text(s,0),sqlite3_column_bytes(s,0))||
     (sqlite3_column_type(s,1)!=SQLITE_NULL&&!metadata(sqlite3_column_text(s,1),sqlite3_column_bytes(s,1)))||
     (sqlite3_column_type(s,2)!=SQLITE_NULL&&!valid_metadata_json(db,(const char *)sqlite3_column_text(s,2),reference_validation_sql))) {
   sqlite3_finalize(s);return 0;
  }
 }
 sqlite3_finalize(s);s=NULL;
 if(rc!=SQLITE_DONE||!prepare(db,&s,"SELECT advisory_context FROM od_original_team_selection"))return 0;
 while((rc=sqlite3_step(s))==SQLITE_ROW) {
  if(!valid_metadata_json(db,(const char *)sqlite3_column_text(s,0),context_validation_sql)){sqlite3_finalize(s);return 0;}
 }
 sqlite3_finalize(s);return rc==SQLITE_DONE;
}

int od_original_teams_snapshot(sqlite3 *db,const char *profile,char **json,char **error) {
 if(json)*json=NULL;if(error)*error=NULL;
 if(!db||!profile||!json)return fail(error,"INVALID_ORIGINAL_TEAM_ARGUMENT");
 const char *sql=
 "SELECT json_object('schema',1,'bindings',json(COALESCE((SELECT json_group_array(json_object("
 "'slot',slot,'native_num',native_num,'name',team_name,'team_bgm_filename',bgm_filename,'card_slots',json(card_slots),'references',json(reference_fields))) "
 "FROM (SELECT * FROM od_original_team_bindings WHERE profile=?1 ORDER BY slot)),'[]')),"
 "'selection',json(COALESCE((SELECT json_patch("
 "CASE WHEN selected_team_num IS NULL THEN '{}' ELSE json_object('selected_team_num',selected_team_num) END,"
 "CASE WHEN selected_kobetu_team_num IS NULL THEN '{}' ELSE json_object('selected_kobetu_team_num',selected_kobetu_team_num) END) "
 "FROM od_original_team_selection WHERE profile=?1),'{}')),'advisory_context',json(COALESCE((SELECT advisory_context FROM od_original_team_selection WHERE profile=?1),'{}'))) FROM profiles WHERE id=?1";
 sqlite3_stmt *s=NULL;
 if(!prepare(db,&s,sql)||!text_bind(s,1,profile)){sqlite3_finalize(s);return fail(error,"ORIGINAL_TEAM_STORAGE_FAILURE");}
 int rc=sqlite3_step(s);
 if(rc==SQLITE_ROW){*json=sqlite3_mprintf("%s",sqlite3_column_text(s,0));rc=sqlite3_step(s);}
 sqlite3_finalize(s);
 if(rc!=SQLITE_DONE||!*json){sqlite3_free(*json);*json=NULL;return fail(error,"ORIGINAL_TEAM_SNAPSHOT_UNAVAILABLE");}
 return 0;
}

static int step_done(sqlite3 *db,const char *sql,const char *profile,const char *json) {
 sqlite3_stmt *s=NULL;
 if(!prepare(db,&s,sql))return 0;
 int ok=text_bind(s,1,profile)&&(!json||text_bind(s,2,json))&&sqlite3_step(s)==SQLITE_DONE;
 sqlite3_finalize(s);return ok;
}

int od_original_teams_apply(sqlite3 *db,const char *profile,sqlite3_int64 expected_revision,const char *json,char **error) {
 if(error)*error=NULL;
 if(!db||!profile||!json||expected_revision<0||sqlite3_get_autocommit(db))return fail(error,"INVALID_ORIGINAL_TEAM_TRANSACTION");
 size_t bytes=0;while(bytes<=OD_ORIGINAL_TEAM_APPLY_BYTES&&json[bytes])++bytes;
 if(!bytes||bytes>OD_ORIGINAL_TEAM_APPLY_BYTES)return fail(error,"ORIGINAL_TEAM_UPDATE_TOO_LARGE");
 sqlite3_stmt *s=NULL,*rows=NULL;const char *reason="ORIGINAL_TEAM_STORAGE_FAILURE";
 if(!prepare(db,&s,"SELECT revision FROM profiles WHERE id=?1")||!text_bind(s,1,profile)){sqlite3_finalize(s);return fail(error,reason);}
 int rc=sqlite3_step(s);int same=rc==SQLITE_ROW&&sqlite3_column_int64(s,0)==expected_revision;
 sqlite3_finalize(s);s=NULL;
 if(!same)return fail(error,"ORIGINAL_TEAM_REVISION_CHANGED");
 if(sqlite3_exec(db,"SAVEPOINT od_original_teams_apply",NULL,NULL,NULL)!=SQLITE_OK)return fail(error,reason);
 if(!prepare(db,&s,"SELECT json_valid(?1)")||!text_bind(s,1,json))goto bad;
 rc=sqlite3_step(s);int json_ok=rc==SQLITE_ROW&&sqlite3_column_int(s,0)==1;
 sqlite3_finalize(s);s=NULL;
 if(!json_ok){reason="INVALID_ORIGINAL_TEAM_UPDATE";goto bad;}
 const char *valid=
 "SELECT json_valid(?1) AND json_type(?1)='object' "
 "AND NOT EXISTS(SELECT 1 FROM json_each(?1) WHERE key NOT IN('teams','selected_team_num','selected_kobetu_team_num','advisory_context')) "
 "AND (SELECT count(*)=count(DISTINCT key) FROM json_each(?1)) "
 "AND (json_type(?1,'$.teams') IS NULL OR json_type(?1,'$.teams')='array') "
 "AND COALESCE(json_array_length(?1,'$.teams'),0)<=20 "
 "AND NOT EXISTS(SELECT 1 FROM json_each(?1) WHERE key IN('selected_team_num','selected_kobetu_team_num') AND (type!='integer' OR value NOT BETWEEN 1 AND 2147483647)) "
 "AND NOT EXISTS(SELECT 1 FROM json_each(?1,'$.teams') r WHERE r.type!='object' "
 "OR (SELECT count(*)!=count(DISTINCT key) FROM json_each(r.value)) "
 "OR EXISTS(SELECT 1 FROM json_each(r.value) WHERE key NOT IN('native_num','name','team_bgm_filename','card_slots','references')) "
 "OR COALESCE(json_type(r.value,'$.native_num')!='integer',1) OR json_extract(r.value,'$.native_num') NOT BETWEEN 1 AND 2147483647 "
 "OR COALESCE(json_type(r.value,'$.name')!='text',1) "
 "OR COALESCE(json_type(r.value,'$.team_bgm_filename') NOT IN('text','null'),1) "
 "OR COALESCE(json_type(r.value,'$.card_slots')!='array',1) OR json_array_length(r.value,'$.card_slots')!=6 "
 "OR (json_type(r.value,'$.references') IS NOT NULL AND json_type(r.value,'$.references') NOT IN('object','null')) "
 "OR EXISTS(SELECT 1 FROM json_each(r.value,'$.card_slots') j WHERE j.type!='integer' OR typeof(j.value)!='integer' OR j.value<0 "
 "OR j.value!=0 AND NOT EXISTS(SELECT 1 FROM owned_cards o WHERE o.profile=?2 AND o.id=j.value AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=o.id))) "
 "OR (SELECT count(*)-count(DISTINCT value) FROM json_each(r.value,'$.card_slots') WHERE value!=0)!=0) "
 "AND (SELECT count(*)=count(DISTINCT json_extract(value,'$.native_num')) FROM json_each(?1,'$.teams'))";
 if(!prepare(db,&s,valid)||!text_bind(s,1,json)||!text_bind(s,2,profile))goto bad;
 rc=sqlite3_step(s);int accepted=rc==SQLITE_ROW&&sqlite3_column_int(s,0)==1;
 sqlite3_finalize(s);s=NULL;
 if(!accepted){reason="INVALID_ORIGINAL_TEAM_UPDATE";goto bad;}
 if(!prepare(db,&rows,"SELECT json_extract(value,'$.native_num'),json_extract(value,'$.name'),json_extract(value,'$.team_bgm_filename'),json_extract(value,'$.card_slots'),json_extract(value,'$.references') FROM json_each(?1,'$.teams') ORDER BY CAST(key AS INTEGER)")||!text_bind(rows,1,json))goto bad;
 if(!prepare(db,&s,"SELECT json_type(?1,'$.advisory_context'),json_extract(?1,'$.advisory_context')")||!text_bind(s,1,json))goto bad;
 rc=sqlite3_step(s);
 if(rc!=SQLITE_ROW)goto bad;
 if(sqlite3_column_type(s,0)!=SQLITE_NULL) {
  const unsigned char *type=sqlite3_column_text(s,0);
  if(!type||strcmp((const char *)type,"object")||!valid_metadata_json(db,(const char *)sqlite3_column_text(s,1),context_validation_sql)){reason="INVALID_ORIGINAL_TEAM_CONTEXT";goto bad;}
 }
 sqlite3_finalize(s);s=NULL;
 /* Validate metadata for the whole batch before the first canonical write. */
 while((rc=sqlite3_step(rows))==SQLITE_ROW) {
  if(!metadata(sqlite3_column_text(rows,1),sqlite3_column_bytes(rows,1))||
     (sqlite3_column_type(rows,2)!=SQLITE_NULL&&!metadata(sqlite3_column_text(rows,2),sqlite3_column_bytes(rows,2)))||
     (sqlite3_column_type(rows,4)!=SQLITE_NULL&&!valid_metadata_json(db,(const char *)sqlite3_column_text(rows,4),reference_validation_sql))) {
   reason="INVALID_ORIGINAL_TEAM_METADATA";goto bad;
  }
 }
 if(rc!=SQLITE_DONE||sqlite3_reset(rows)!=SQLITE_OK)goto bad;
 while((rc=sqlite3_step(rows))==SQLITE_ROW) {
  sqlite3_int64 num=sqlite3_column_int64(rows,0);const char *name=(const char *)sqlite3_column_text(rows,1),*bgm=(const char *)sqlite3_column_text(rows,2),*slots=(const char *)sqlite3_column_text(rows,3),*references=(const char *)sqlite3_column_text(rows,4);
  if(!metadata((const unsigned char *)name,sqlite3_column_bytes(rows,1))||(bgm&&!metadata((const unsigned char *)bgm,sqlite3_column_bytes(rows,2)))){reason="INVALID_ORIGINAL_TEAM_METADATA";goto bad;}
  const char *slot_sql="SELECT slot,0 AS priority FROM od_original_team_bindings WHERE profile=?1 AND native_num=?2 UNION ALL SELECT n,1 FROM (WITH RECURSIVE n(n) AS (VALUES(0) UNION ALL SELECT n+1 FROM n WHERE n<19) SELECT n FROM n) WHERE NOT EXISTS(SELECT 1 FROM od_original_team_bindings WHERE profile=?1 AND native_num=?2) AND NOT EXISTS(SELECT 1 FROM teams WHERE profile=?1 AND slot=n) ORDER BY 2,1 LIMIT 1";
  if(!prepare(db,&s,slot_sql)||!text_bind(s,1,profile)||sqlite3_bind_int64(s,2,num)!=SQLITE_OK)goto bad;
  int sr=sqlite3_step(s);int slot=sr==SQLITE_ROW?sqlite3_column_int(s,0):-1;sqlite3_finalize(s);s=NULL;
  if(slot<0){reason="ORIGINAL_TEAM_SLOT_CAPACITY_EXHAUSTED";goto bad;}
  if(!prepare(db,&s,"INSERT INTO teams(profile,slot,members) VALUES(?1,?2,(SELECT json_group_array(value) FROM json_each(?3) WHERE value!=0)) ON CONFLICT(profile,slot) DO UPDATE SET members=excluded.members")||!text_bind(s,1,profile)||sqlite3_bind_int(s,2,slot)!=SQLITE_OK||!text_bind(s,3,slots)||sqlite3_step(s)!=SQLITE_DONE)goto bad;
  sqlite3_finalize(s);s=NULL;
  if(!prepare(db,&s,"INSERT INTO od_original_team_bindings(profile,slot,native_num,team_name,bgm_filename,card_slots,reference_fields) VALUES(?1,?2,?3,?4,?5,json(?6),json(?7)) ON CONFLICT(profile,slot) DO UPDATE SET team_name=excluded.team_name,bgm_filename=excluded.bgm_filename,card_slots=excluded.card_slots,reference_fields=COALESCE(excluded.reference_fields,od_original_team_bindings.reference_fields)")||!text_bind(s,1,profile)||sqlite3_bind_int(s,2,slot)!=SQLITE_OK||sqlite3_bind_int64(s,3,num)!=SQLITE_OK||!text_bind(s,4,name)||(bgm?sqlite3_bind_text(s,5,bgm,-1,SQLITE_TRANSIENT):sqlite3_bind_null(s,5))!=SQLITE_OK||!text_bind(s,6,slots)||(references?sqlite3_bind_text(s,7,references,-1,SQLITE_TRANSIENT):sqlite3_bind_null(s,7))!=SQLITE_OK||sqlite3_step(s)!=SQLITE_DONE)goto bad;
  sqlite3_finalize(s);s=NULL;
 }
 sqlite3_finalize(rows);rows=NULL;
 if(rc!=SQLITE_DONE)goto bad;
 const char *selection_sql="INSERT INTO od_original_team_selection(profile,selected_team_num,selected_kobetu_team_num,advisory_context) VALUES(?1,json_extract(?2,'$.selected_team_num'),json_extract(?2,'$.selected_kobetu_team_num'),COALESCE(json_extract(?2,'$.advisory_context'),'{}')) ON CONFLICT(profile) DO UPDATE SET selected_team_num=CASE WHEN json_type(?2,'$.selected_team_num') IS NULL THEN selected_team_num ELSE excluded.selected_team_num END,selected_kobetu_team_num=CASE WHEN json_type(?2,'$.selected_kobetu_team_num') IS NULL THEN selected_kobetu_team_num ELSE excluded.selected_kobetu_team_num END,advisory_context=CASE WHEN json_type(?2,'$.advisory_context') IS NULL THEN advisory_context ELSE excluded.advisory_context END";
 if(!prepare(db,&s,"SELECT NOT EXISTS(SELECT 1 FROM json_each(?1) j WHERE j.key IN('selected_team_num','selected_kobetu_team_num') AND NOT EXISTS(SELECT 1 FROM od_original_team_bindings b WHERE b.profile=?2 AND b.native_num=j.value))")||!text_bind(s,1,json)||!text_bind(s,2,profile))goto bad;
 rc=sqlite3_step(s);int selected_owned=rc==SQLITE_ROW&&sqlite3_column_int(s,0)==1;
 sqlite3_finalize(s);s=NULL;
 if(!selected_owned){reason="ORIGINAL_TEAM_SELECTION_NOT_OWNED";goto bad;}
 if(!step_done(db,selection_sql,profile,json))goto bad;
 if(!od_original_teams_validate(db)){reason="ORIGINAL_TEAM_LAYOUT_OR_OWNERSHIP_MISMATCH";goto bad;}
 if(sqlite3_exec(db,"RELEASE od_original_teams_apply",NULL,NULL,NULL)!=SQLITE_OK)goto bad;
 return 0;
 bad:
 sqlite3_finalize(s);sqlite3_finalize(rows);
 sqlite3_exec(db,"ROLLBACK TO od_original_teams_apply;RELEASE od_original_teams_apply",NULL,NULL,NULL);
 return fail(error,reason);
}
