#define _POSIX_C_SOURCE 200809L
#include "od_core.h"
#include "progression.h"
#include "schedules_store.h"
#include "card_stats.h"
#include "potential.h"
#include "training.h"
#include "kai_training.h"
#include "json_values.h"
#include "original_teams.h"
#include "sqlite3.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <limits.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#if defined(__linux__) && !defined(__ANDROID__)
#include <sys/random.h>
#endif
#if defined(__APPLE__)
#include <Security/SecRandom.h>
#endif

#define OD_LIMIT INT64_C(9007199254740991)
#define OD_MAX_INPUT (1024u * 1024u)
#define OD_MAX_BANNER_INPUT (16u * 1024u * 1024u)
#define OD_FULL_RESULTS 128
struct od_core { sqlite3 *db, *master; char *content; char error[192]; };
static int validate_save(od_core *c,sqlite3 *db);
static int validate_save_version(od_core *c,sqlite3 *db,int version);
static int validate_banners(od_core *c,sqlite3 *db);
static int validate_progress(od_core *c,sqlite3 *db);
static int seed_new_owned_progress(od_core *c);
static int full_bundle_scope(od_core *c,const char *profile,char out[65]);
static int full_bundle_hex(const char *text);
static const char *SCHEMA =
 "CREATE TABLE meta(k TEXT PRIMARY KEY,v TEXT NOT NULL) STRICT;"
 "CREATE TABLE profiles(id TEXT PRIMARY KEY,revision INTEGER NOT NULL DEFAULT 0 CHECK(revision>=0),stamina INTEGER NOT NULL DEFAULT 0 CHECK(stamina BETWEEN 0 AND 9007199254740991)) STRICT;"
 "CREATE TABLE inventory(profile TEXT NOT NULL REFERENCES profiles(id),kind TEXT NOT NULL,item_id INTEGER NOT NULL CHECK(item_id>=0),quantity INTEGER NOT NULL CHECK(quantity BETWEEN 0 AND 9007199254740991),PRIMARY KEY(profile,kind,item_id)) STRICT;"
 "CREATE TABLE owned_cards(id INTEGER PRIMARY KEY,profile TEXT NOT NULL REFERENCES profiles(id),master_id INTEGER NOT NULL CHECK(master_id>0),level INTEGER NOT NULL DEFAULT 1 CHECK(level>=1),sa_level INTEGER NOT NULL DEFAULT 1 CHECK(sa_level>=1),potential TEXT NOT NULL DEFAULT '{}' CHECK(json_valid(potential))) STRICT;"
 "CREATE TABLE teams(profile TEXT NOT NULL REFERENCES profiles(id),slot INTEGER NOT NULL CHECK(slot BETWEEN 0 AND 19),members TEXT NOT NULL CHECK(json_valid(members)),PRIMARY KEY(profile,slot)) STRICT;"
 "CREATE TABLE quest_progress(profile TEXT NOT NULL REFERENCES profiles(id),quest_id INTEGER NOT NULL CHECK(quest_id>0),clears INTEGER NOT NULL CHECK(clears>0),PRIMARY KEY(profile,quest_id)) STRICT;"
 "CREATE TABLE runs(id TEXT PRIMARY KEY,profile TEXT NOT NULL REFERENCES profiles(id),map_id INTEGER NOT NULL CHECK(map_id>0),quest_id INTEGER NOT NULL CHECK(quest_id>0),content TEXT NOT NULL,team_slot INTEGER NOT NULL,team_snapshot TEXT NOT NULL CHECK(json_valid(team_snapshot)),entry_cost INTEGER NOT NULL CHECK(entry_cost>=0),rewards TEXT NOT NULL CHECK(json_valid(rewards)),state TEXT NOT NULL CHECK(state IN('started','finished')),outcome TEXT CHECK(outcome IS NULL OR outcome IN('clear','failed')),result TEXT CHECK(result IS NULL OR json_valid(result))) STRICT;"
 "CREATE TABLE reward_sources(profile TEXT NOT NULL REFERENCES profiles(id),source TEXT NOT NULL,input TEXT NOT NULL CHECK(json_valid(input)),PRIMARY KEY(profile,source)) STRICT;"
 "CREATE TABLE commands(profile TEXT NOT NULL REFERENCES profiles(id),id TEXT NOT NULL,operation TEXT NOT NULL,input TEXT NOT NULL CHECK(json_valid(input)),result TEXT NOT NULL CHECK(json_valid(result)),PRIMARY KEY(profile,id)) STRICT;"
 "PRAGMA user_version=1;";
static const char *SCHEMA_V2 =
 "CREATE TABLE banner_versions(profile TEXT NOT NULL REFERENCES profiles(id),banner_id TEXT NOT NULL,version INTEGER NOT NULL CHECK(version BETWEEN 1 AND 9007199254740991),epoch INTEGER NOT NULL CHECK(epoch BETWEEN 1 AND 9007199254740991),main_id TEXT NOT NULL,multi_count INTEGER NOT NULL CHECK(multi_count BETWEEN 1 AND 100),lr_ppm INTEGER NOT NULL CHECK(lr_ppm BETWEEN 0 AND 1000000),slr_ppm INTEGER NOT NULL CHECK(slr_ppm BETWEEN 0 AND 1000000),gr_ppm INTEGER NOT NULL CHECK(gr_ppm BETWEEN 0 AND 1000000),config TEXT NOT NULL CHECK(json_valid(config)),PRIMARY KEY(profile,banner_id,version)) STRICT;"
 "CREATE TABLE banner_entries(profile TEXT NOT NULL,banner_id TEXT NOT NULL,version INTEGER NOT NULL,ordinal INTEGER NOT NULL CHECK(ordinal>=0),definition_id TEXT NOT NULL,master_id INTEGER NOT NULL CHECK(master_id>0),rarity INTEGER NOT NULL CHECK(rarity BETWEEN 0 AND 7),weight_ppm INTEGER NOT NULL CHECK(weight_ppm BETWEEN 0 AND 1000000),PRIMARY KEY(profile,banner_id,version,ordinal),UNIQUE(profile,banner_id,version,definition_id),FOREIGN KEY(profile,banner_id,version) REFERENCES banner_versions(profile,banner_id,version)) STRICT;"
 "CREATE TABLE banner_active(profile TEXT NOT NULL,banner_id TEXT NOT NULL,version INTEGER NOT NULL,PRIMARY KEY(profile,banner_id),FOREIGN KEY(profile,banner_id,version) REFERENCES banner_versions(profile,banner_id,version)) STRICT;"
 "CREATE TABLE banner_pity(profile TEXT NOT NULL,banner_id TEXT NOT NULL,epoch INTEGER NOT NULL CHECK(epoch BETWEEN 1 AND 9007199254740991),misses INTEGER NOT NULL CHECK(misses BETWEEN 0 AND 4294967295),PRIMARY KEY(profile,banner_id),FOREIGN KEY(profile,banner_id) REFERENCES banner_active(profile,banner_id)) STRICT;"
 "CREATE TABLE card_sources(instance_id INTEGER PRIMARY KEY REFERENCES owned_cards(id),profile TEXT NOT NULL,banner_id TEXT NOT NULL,version INTEGER NOT NULL,definition_id TEXT NOT NULL,FOREIGN KEY(profile,banner_id,version,definition_id) REFERENCES banner_entries(profile,banner_id,version,definition_id)) STRICT;"
 "PRAGMA user_version=2;";

static const char *SCHEMA_V3 =
 "CREATE TABLE created_definitions(profile TEXT NOT NULL REFERENCES profiles(id),definition_id TEXT NOT NULL,version INTEGER NOT NULL CHECK(version BETWEEN 1 AND 9007199254740991),master_id INTEGER NOT NULL CHECK(master_id>0),rarity INTEGER NOT NULL CHECK(rarity BETWEEN 4 AND 7),document TEXT NOT NULL CHECK(json_valid(document)),PRIMARY KEY(profile,definition_id,version)) STRICT;"
 "CREATE TABLE created_active(profile TEXT NOT NULL,definition_id TEXT NOT NULL,version INTEGER NOT NULL,sequence INTEGER NOT NULL CHECK(sequence BETWEEN 1 AND 9007199254740991),PRIMARY KEY(profile,definition_id),UNIQUE(profile,sequence),FOREIGN KEY(profile,definition_id,version) REFERENCES created_definitions(profile,definition_id,version)) STRICT;"
 "CREATE TABLE creator_state(profile TEXT PRIMARY KEY REFERENCES profiles(id),epoch INTEGER NOT NULL CHECK(epoch BETWEEN 1 AND 9007199254740991),main_id TEXT NOT NULL,FOREIGN KEY(profile,main_id) REFERENCES created_active(profile,definition_id)) STRICT;"
 "CREATE TABLE banner_definitions(profile TEXT NOT NULL,banner_id TEXT NOT NULL,banner_version INTEGER NOT NULL,definition_id TEXT NOT NULL,definition_version INTEGER NOT NULL,PRIMARY KEY(profile,banner_id,banner_version,definition_id),FOREIGN KEY(profile,banner_id,banner_version,definition_id) REFERENCES banner_entries(profile,banner_id,version,definition_id),FOREIGN KEY(profile,definition_id,definition_version) REFERENCES created_definitions(profile,definition_id,version)) STRICT;"
 "CREATE TABLE owned_definitions(instance_id INTEGER PRIMARY KEY REFERENCES owned_cards(id),profile TEXT NOT NULL,definition_id TEXT NOT NULL,version INTEGER NOT NULL,origin_version INTEGER NOT NULL,potential_locked INTEGER NOT NULL DEFAULT 1 CHECK(potential_locked IN(0,1)),addons TEXT NOT NULL DEFAULT '[]' CHECK(json_valid(addons) AND json_type(addons)='array'),exclusive_kind INTEGER NOT NULL CHECK(exclusive_kind BETWEEN 0 AND 2),exclusive_always_on INTEGER NOT NULL CHECK(exclusive_always_on IN(0,1)),FOREIGN KEY(profile,definition_id,version) REFERENCES created_definitions(profile,definition_id,version),FOREIGN KEY(profile,definition_id,origin_version) REFERENCES created_definitions(profile,definition_id,version)) STRICT;"
 "PRAGMA user_version=3;";

static const char *SCHEMA_V4 =
 "CREATE TABLE owned_progress(instance_id INTEGER PRIMARY KEY REFERENCES owned_cards(id),experience INTEGER CHECK(experience BETWEEN 0 AND 9007199254740991),locked INTEGER NOT NULL DEFAULT 0 CHECK(locked IN(0,1))) STRICT;"
 "PRAGMA user_version=4;";

static const char *SCHEMA_V5 = "PRAGMA user_version=5;";
static const char *SCHEMA_V6 =
 "CREATE TABLE official_upgrade_policies(profile TEXT NOT NULL REFERENCES profiles(id),policy_id TEXT NOT NULL,policy_version INTEGER NOT NULL CHECK(policy_version BETWEEN 1 AND 9007199254740991),master_id INTEGER NOT NULL CHECK(master_id>0),document TEXT NOT NULL CHECK(json_valid(document)),PRIMARY KEY(profile,policy_id,policy_version,master_id)) STRICT;"
 "CREATE TABLE official_upgrade_versions(profile TEXT NOT NULL REFERENCES profiles(id),master_id INTEGER NOT NULL CHECK(master_id>0),version INTEGER NOT NULL CHECK(version BETWEEN 1 AND 9007199254740991),kind INTEGER NOT NULL CHECK(kind BETWEEN 1 AND 3),custom_eza INTEGER NOT NULL CHECK(custom_eza IN(0,1)),custom_super_eza INTEGER NOT NULL CHECK(custom_super_eza IN(0,1)),enhanced_policy_version INTEGER NOT NULL CHECK(enhanced_policy_version BETWEEN 0 AND 9007199254740991),document TEXT NOT NULL CHECK(json_valid(document)),stone_cost INTEGER NOT NULL CHECK(stone_cost IN(0,300,500,700)),PRIMARY KEY(profile,master_id,version)) STRICT;"
 "CREATE TABLE official_upgrade_active(profile TEXT NOT NULL,master_id INTEGER NOT NULL,version INTEGER NOT NULL,PRIMARY KEY(profile,master_id),FOREIGN KEY(profile,master_id,version) REFERENCES official_upgrade_versions(profile,master_id,version)) STRICT;"
 "PRAGMA user_version=6;";
static const char *SCHEMA_V7="PRAGMA user_version=7;";
/* Direct Creator saves are distinct from banner pulls. Retain their ownership
 * identity forever, including consumed-card tombstones, so retries cannot mint dupes. */
static const char *SCHEMA_V8=
 "CREATE TABLE creator_collection(profile TEXT NOT NULL REFERENCES profiles(id),definition_id TEXT NOT NULL,instance_id INTEGER NOT NULL UNIQUE REFERENCES owned_definitions(instance_id),origin_version INTEGER NOT NULL CHECK(origin_version BETWEEN 1 AND 9007199254740991),PRIMARY KEY(profile,definition_id),FOREIGN KEY(profile,definition_id,origin_version) REFERENCES created_definitions(profile,definition_id,version)) STRICT;"
 "PRAGMA user_version=8;";
/* Own initial ACT policy: capacity is read from rank_statuses(rank=1), while
 * the recovery interval is an explicitly authored offline rule, not wire evidence. */
static const char *SCHEMA_V9=
 "CREATE TABLE player_progress(profile TEXT PRIMARY KEY REFERENCES profiles(id),rank INTEGER NOT NULL CHECK(rank=1),rank_experience INTEGER NOT NULL CHECK(rank_experience=0),act_max INTEGER NOT NULL CHECK(act_max BETWEEN 1 AND 2147483647),recovery_seconds INTEGER NOT NULL CHECK(recovery_seconds=300),recovery_anchor INTEGER CHECK(recovery_anchor BETWEEN 0 AND 253402300799),policy TEXT NOT NULL CHECK(policy='offline-rank1-act-v1')) STRICT;"
 "PRAGMA user_version=9;";
/* A trusted native projection clock, independent of ordinary player revision.
 * Relevant row triggers enqueue an intent in the same transaction as the core
 * mutation. The sidecar is a disposable mirror; it never owns progression. */
static const char *SCHEMA_V10=
 "INSERT INTO meta(k,v) VALUES('projection_identity',lower(hex(randomblob(16))));"
 "CREATE TABLE creator_projection(profile TEXT PRIMARY KEY REFERENCES profiles(id),generation INTEGER NOT NULL CHECK(generation BETWEEN 1 AND 9007199254740991),applied_generation INTEGER NOT NULL DEFAULT 0 CHECK(applied_generation BETWEEN 0 AND generation)) STRICT;"
 "INSERT INTO creator_projection(profile,generation) SELECT id,1 FROM profiles;"
 "CREATE TRIGGER _od_projection_profile AFTER INSERT ON profiles BEGIN INSERT INTO creator_projection(profile,generation) VALUES(NEW.id,1); END;"
 "CREATE TRIGGER _od_projection_active_insert AFTER INSERT ON created_active BEGIN UPDATE creator_projection SET generation=generation+1 WHERE profile=NEW.profile; END;"
 "CREATE TRIGGER _od_projection_active_update AFTER UPDATE OF version ON created_active WHEN OLD.version IS NOT NEW.version BEGIN UPDATE creator_projection SET generation=generation+1 WHERE profile=NEW.profile; END;"
 "CREATE TRIGGER _od_projection_active_delete AFTER DELETE ON created_active BEGIN UPDATE creator_projection SET generation=generation+1 WHERE profile=OLD.profile; END;"
 "CREATE TRIGGER _od_projection_owned_insert AFTER INSERT ON owned_definitions BEGIN UPDATE creator_projection SET generation=generation+1 WHERE profile=NEW.profile; END;"
 "CREATE TRIGGER _od_projection_owned_update AFTER UPDATE ON owned_definitions WHEN OLD.version IS NOT NEW.version OR OLD.definition_id IS NOT NEW.definition_id OR OLD.potential_locked IS NOT NEW.potential_locked OR OLD.addons IS NOT NEW.addons OR OLD.exclusive_kind IS NOT NEW.exclusive_kind OR OLD.exclusive_always_on IS NOT NEW.exclusive_always_on BEGIN UPDATE creator_projection SET generation=generation+1 WHERE profile=NEW.profile; END;"
 "CREATE TRIGGER _od_projection_owned_delete AFTER DELETE ON owned_definitions BEGIN UPDATE creator_projection SET generation=generation+1 WHERE profile=OLD.profile; END;"
 "CREATE TRIGGER _od_projection_consumed_insert AFTER INSERT ON owned_consumptions WHEN EXISTS(SELECT 1 FROM owned_definitions WHERE instance_id=NEW.instance_id) BEGIN UPDATE creator_projection SET generation=generation+1 WHERE profile=NEW.profile; END;"
 "CREATE TRIGGER _od_projection_consumed_delete AFTER DELETE ON owned_consumptions WHEN EXISTS(SELECT 1 FROM owned_definitions WHERE instance_id=OLD.instance_id) BEGIN UPDATE creator_projection SET generation=generation+1 WHERE profile=OLD.profile; END;"
 "CREATE TRIGGER _od_projection_document_update AFTER UPDATE OF document ON created_definitions WHEN OLD.document IS NOT NEW.document AND (EXISTS(SELECT 1 FROM created_active WHERE profile=NEW.profile AND definition_id=NEW.definition_id AND version=NEW.version) OR EXISTS(SELECT 1 FROM owned_definitions WHERE profile=NEW.profile AND definition_id=NEW.definition_id AND version=NEW.version)) BEGIN UPDATE creator_projection SET generation=generation+1 WHERE profile=NEW.profile; END;"
 "PRAGMA user_version=10;";
/* Own local wire identity: generated only by trusted save/profile lifecycle,
 * never copied from an online account or accepted as an editor intent. */
static const char *SCHEMA_V11=
 "CREATE TABLE offline_identity(profile TEXT PRIMARY KEY REFERENCES profiles(id),local_id INTEGER NOT NULL UNIQUE CHECK(local_id BETWEEN 1 AND 2147483647),display_name TEXT NOT NULL CHECK(length(display_name) BETWEEN 1 AND 32 AND instr(display_name,char(0))=0)) STRICT;"
 "INSERT INTO offline_identity SELECT id,row_number() OVER(ORDER BY id),'Offline Player' FROM profiles;"
 "CREATE TRIGGER _od_identity_profile AFTER INSERT ON profiles BEGIN INSERT INTO offline_identity(profile,local_id,display_name) VALUES(NEW.id,(SELECT COALESCE(max(local_id),0)+1 FROM offline_identity),'Offline Player'); END;"
 "PRAGMA user_version=11;";


/* Exact validated native packets are durable with their immutable definition.
 * v11 full descriptors may lack bytes: migration preserves them explicitly;
 * native retrieval reports the missing-payload recovery requirement. */
static const char *SCHEMA_V12=
 "CREATE TABLE created_full_bundles(profile TEXT NOT NULL,definition_id TEXT NOT NULL,version INTEGER NOT NULL CHECK(version BETWEEN 1 AND 9007199254740991),save_scope TEXT NOT NULL CHECK(length(save_scope)=64 AND save_scope NOT GLOB '*[^0-9a-f]*'),sha256 TEXT NOT NULL CHECK(length(sha256)=64 AND sha256 NOT GLOB '*[^0-9a-f]*'),packet BLOB NOT NULL CHECK(length(packet) BETWEEN 1 AND 67108864),PRIMARY KEY(profile,definition_id,version),FOREIGN KEY(profile,definition_id,version) REFERENCES created_definitions(profile,definition_id,version)) STRICT;"
 "PRAGMA user_version=12;";
static int retain_full_bundle(od_core *c,const char *profile,const char *args,const void *bundle,size_t bytes,int allow_insert);
static int validate_full_bundle_rows(od_core *c,sqlite3 *db);

/* Only a genuinely inserted own profile receives the original client's
 * start-tutorial control state. Migration never fabricates this for an old
 * profile. Contents level, capacities and completion remain unimplemented. */
static const char *SCHEMA_V13=
 "CREATE TABLE od_original_tutorial(profile TEXT PRIMARY KEY REFERENCES profiles(id),progress INTEGER NOT NULL CHECK(progress BETWEEN 0 AND 2147483647),is_finished INTEGER NOT NULL CHECK(is_finished=0),policy TEXT NOT NULL CHECK(policy='original-tutorial-entry-v1')) STRICT;"
 "PRAGMA user_version=13;";


void od_free(void *p) { sqlite3_free(p); }
static int fail(od_core *c,const char *message) { snprintf(c->error,sizeof(c->error),"%s",message);return -1; }
const char *od_last_error(od_core *c) { return c ? c->error : "OPEN_FAILED"; }
static int sql(od_core *c,const char *text) { return sqlite3_exec(c->db,text,0,0,0)==SQLITE_OK ? 0 : fail(c,"DATABASE_ERROR"); }
static sqlite3_stmt *prepare(od_core *c,const char *text,const char *p,const char *a,const char *id) {
 sqlite3_stmt *s=NULL;
 /* Reserve named bindings before numbered payload slots, independent of SQL clause order. */
 char *reserved=strncmp(text,"PRAGMA",6)?sqlite3_mprintf("WITH _od_core_bind(_p,_a,_id) AS (VALUES(:p,:a,:id)) %s",text):sqlite3_mprintf("%s",text);
 if(!reserved||sqlite3_prepare_v2(c->db,reserved,-1,&s,NULL)!=SQLITE_OK){sqlite3_free(reserved);fail(c,"DATABASE_ERROR");return NULL;}sqlite3_free(reserved);
 const char *names[]={":p",":a",":id"};const char *values[]={p,a,id};
 for(int i=0;i<3;i++){int n=sqlite3_bind_parameter_index(s,names[i]);if(n)sqlite3_bind_text(s,n,values[i]?values[i]:"",-1,SQLITE_TRANSIENT);}return s;
}
static int scalar(od_core *c,const char *q,const char *p,const char *a,const char *id,int64_t *value) {
 sqlite3_stmt *s=prepare(c,q,p,a,id);if(!s)return -1;int rc=sqlite3_step(s);if(rc==SQLITE_ROW)*value=sqlite3_column_int64(s,0);sqlite3_finalize(s);return rc==SQLITE_ROW?0:fail(c,"DATABASE_ERROR");
}
static int writeq(od_core *c,const char *q,const char *p,const char *a,const char *id) { sqlite3_stmt *s=prepare(c,q,p,a,id);if(!s)return -1;int rc=sqlite3_step(s);sqlite3_finalize(s);return rc==SQLITE_DONE?0:fail(c,"DATABASE_ERROR"); }
static char *query(od_core *c,const char *q,const char *p,const char *a,const char *id) { sqlite3_stmt *s=prepare(c,q,p,a,id);if(!s)return NULL;char *r=NULL;if(sqlite3_step(s)==SQLITE_ROW)r=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);if(!r)fail(c,"DATABASE_ERROR");return r; }
static int identifier(const char *s) { if(!s||!*s||strlen(s)>127)return 0;for(;*s;s++)if(!((*s>='a'&&*s<='z')||(*s>='A'&&*s<='Z')||(*s>='0'&&*s<='9')||*s=='-'||*s=='_'||*s=='.'||*s==':'))return 0;return 1; }
static int master_exists(od_core *c,const char *table,int64_t id) {
 char *q=sqlite3_mprintf("SELECT 1 FROM %w WHERE id=?1",table);sqlite3_stmt *s=NULL;int rc=sqlite3_prepare_v2(c->master,q,-1,&s,NULL);sqlite3_free(q);if(rc!=SQLITE_OK)return 0;sqlite3_bind_int64(s,1,id);rc=sqlite3_step(s);sqlite3_finalize(s);return rc==SQLITE_ROW;
}
static int integer_arg(od_core *c,const char *a,const char *key,int64_t low,int64_t high,int64_t *v) {
 sqlite3_stmt *s=prepare(c,"SELECT json_extract(:a,:id),json_type(:a,:id)",NULL,a,key);if(!s)return -1;int rc=sqlite3_step(s);int good=rc==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_INTEGER&&sqlite3_column_type(s,1)==SQLITE_TEXT&&strcmp((const char *)sqlite3_column_text(s,1),"integer")==0;
 if(good){*v=sqlite3_column_int64(s,0);good=*v>=low&&*v<=high;}sqlite3_finalize(s);return good?0:fail(c,"INVALID_ARGUMENT");
}
static int profile_exists(od_core *c,const char *p) { int64_t n=0;return scalar(c,"SELECT count(*) FROM profiles WHERE id=:p",p,NULL,NULL,&n)==0&&n==1; }
static char *snapshot(od_core *c,const char *p) {
 return query(c,"SELECT json_object('profile_id',id,'wire_identity',json((SELECT json_object('id',local_id,'name',display_name) FROM offline_identity WHERE profile=:p)),'revision',revision,'stamina',stamina,'rank',(SELECT rank FROM player_progress WHERE profile=:p),'rank_experience',(SELECT rank_experience FROM player_progress WHERE profile=:p),'stamina_max',(SELECT act_max FROM player_progress WHERE profile=:p),'stamina_recovery',(SELECT json_object('policy',policy,'seconds_per_point',recovery_seconds,'anchor_utc',recovery_anchor) FROM player_progress WHERE profile=:p),'content_id',(SELECT v FROM meta WHERE k='content'),'inventory',json(COALESCE((SELECT json_group_array(json_object('kind',kind,'id',item_id,'quantity',quantity)) FROM (SELECT * FROM inventory WHERE profile=:p ORDER BY kind,item_id)),'[]')),'cards',json(COALESCE((SELECT json_group_array(json_object('instance_id',id,'master_id',master_id,'level',level,'sa_level',sa_level,'potential',json(potential),'experience',(SELECT experience FROM owned_progress WHERE instance_id=owned_cards.id),'locked',COALESCE((SELECT locked FROM owned_progress WHERE instance_id=owned_cards.id),0),'official_upgrade',(SELECT json_object('version',v.version,'kind',v.kind,'custom_eza',v.custom_eza,'custom_super_eza',v.custom_super_eza,'enhanced_policy_version',v.enhanced_policy_version,'manual_edits_allowed',v.enhanced_policy_version=0,'label',CASE v.kind WHEN 1 THEN 'Custom EZA' WHEN 2 THEN 'Custom Super EZA' ELSE 'Enhanced' END) FROM official_upgrade_active a JOIN official_upgrade_versions v USING(profile,master_id,version) WHERE a.profile=owned_cards.profile AND a.master_id=owned_cards.master_id AND NOT EXISTS(SELECT 1 FROM owned_definitions WHERE instance_id=owned_cards.id) AND NOT EXISTS(SELECT 1 FROM tournament_exclusive_owned WHERE instance_id=owned_cards.id)),'tournament_definition',(SELECT json_object('definition_id',d.definition_id,'version',d.version,'tournament_id',d.tournament_id,'weekend_id',d.weekend_id,'potential_locked',d.potential_locked,'addons',json(d.addons),'exclusive_kind',d.exclusive_kind,'exclusive_always_on',d.exclusive_always_on) FROM tournament_exclusive_owned d WHERE d.instance_id=owned_cards.id),'created_definition',(SELECT json_object('definition_id',d.definition_id,'version',d.version,'origin_version',d.origin_version,'potential_locked',d.potential_locked,'addons',json(d.addons),'exclusive_kind',d.exclusive_kind,'exclusive_always_on',d.exclusive_always_on) FROM owned_definitions d JOIN created_definitions v USING(profile,definition_id,version) WHERE d.instance_id=owned_cards.id))) FROM (SELECT * FROM owned_cards WHERE profile=:p AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=owned_cards.id) ORDER BY id) AS owned_cards),'[]')),'official_upgrades',json(COALESCE((SELECT json_group_array(json_object('master_id',v.master_id,'version',v.version,'document',json(v.document))) FROM official_upgrade_active a JOIN official_upgrade_versions v USING(profile,master_id,version) WHERE a.profile=:p),'[]')),'tournament_definitions',json(COALESCE((SELECT json_group_array(json_object('definition_id',v.definition_id,'version',v.version,'document',json(v.document))) FROM tournament_exclusive_definitions v WHERE v.profile=:p AND EXISTS(SELECT 1 FROM tournament_exclusive_owned d WHERE d.profile=v.profile AND d.definition_id=v.definition_id AND d.version=v.version AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=d.instance_id))),'[]')),'created_definitions',json(COALESCE((SELECT json_group_array(json_object('definition_id',v.definition_id,'version',v.version,'document',json(v.document))) FROM (SELECT * FROM created_definitions v WHERE v.profile=:p AND EXISTS(SELECT 1 FROM owned_definitions d WHERE d.profile=v.profile AND d.definition_id=v.definition_id AND d.version=v.version AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=d.instance_id)) ORDER BY definition_id,version) AS v),'[]')),'teams',json(COALESCE((SELECT json_group_array(json_object('slot',slot,'members',json(members))) FROM (SELECT * FROM teams WHERE profile=:p ORDER BY slot)),'[]')),'runs',json(COALESCE((SELECT json_group_array(json_object('id',id,'map_id',map_id,'state',state)) FROM (SELECT * FROM runs WHERE profile=:p ORDER BY id)),'[]'))) FROM profiles WHERE id=:p",p,NULL,NULL);
}

/* Called only inside the existing canonical read/write transaction. These
 * native properties are never taken from a projection policy or source cache. */
static char *original_player_fields(od_core *c,const char *profile,const char *base) {
 char *teams=NULL,*error=NULL;
 if(od_original_teams_snapshot(c->db,profile,&teams,&error)<0){fail(c,error?error:"ORIGINAL_TEAM_SNAPSHOT_UNAVAILABLE");sqlite3_free(error);sqlite3_free(teams);return NULL;}
 char *tutorial=query(c,"SELECT COALESCE((SELECT json_object('schema',1,'policy',policy,'progress',progress,'is_finished',json('false')) FROM od_original_tutorial WHERE profile=:p),'null')",profile,NULL,NULL);
 sqlite3_stmt *statement=tutorial?prepare(c,"SELECT json_set(:a,'$.original_client_teams',json(?4),'$.original_client_tutorial',json(?5))",profile,base,NULL):NULL;
 char *result=NULL;
 if(statement){sqlite3_bind_text(statement,4,teams,-1,SQLITE_TRANSIENT);sqlite3_bind_text(statement,5,tutorial,-1,SQLITE_TRANSIENT);if(sqlite3_step(statement)==SQLITE_ROW)result=sqlite3_mprintf("%s",sqlite3_column_text(statement,0));}
 sqlite3_finalize(statement);sqlite3_free(teams);sqlite3_free(tutorial);
 if(!result){fail(c,"ORIGINAL_PLAYER_SNAPSHOT_UNAVAILABLE");}return result;
}

int od_open(const char *save,const char *master,const char *content,od_core **out) {
 if(!out){return -1;}
 *out=NULL;if(!save||!master||!identifier(content))return -1;
 struct stat save_stat,master_stat;if(!stat(save,&save_stat)&&!stat(master,&master_stat)&&save_stat.st_dev==master_stat.st_dev&&save_stat.st_ino==master_stat.st_ino)return -1;
 od_core *c=calloc(1,sizeof(*c));if(!c)return -1;c->content=sqlite3_mprintf("%s",content);
 if(!c->content||sqlite3_open_v2(master,&c->master,SQLITE_OPEN_READONLY|SQLITE_OPEN_FULLMUTEX,NULL)!=SQLITE_OK||sqlite3_open_v2(save,&c->db,SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_FULLMUTEX,NULL)!=SQLITE_OK)goto bad;
 sqlite3_busy_timeout(c->db,3000);if(sql(c,"PRAGMA foreign_keys=ON;PRAGMA journal_mode=DELETE;PRAGMA synchronous=FULL;")<0)goto bad;
 int64_t version=0;if(scalar(c,"PRAGMA user_version",NULL,NULL,NULL,&version)<0)goto bad;
 if(version==0){int64_t n=0;if(scalar(c,"SELECT count(*) FROM sqlite_schema WHERE name NOT LIKE 'sqlite_%'",NULL,NULL,NULL,&n)<0||n)goto bad;
  if(sql(c,"BEGIN IMMEDIATE")<0||sql(c,SCHEMA)<0||sql(c,SCHEMA_V2)<0||sql(c,SCHEMA_V3)<0||sql(c,SCHEMA_V4)<0||sql(c,od_schedule_store_schema())<0||sql(c,SCHEMA_V5)<0||sql(c,od_schedule_store_schema_v2())<0||sql(c,SCHEMA_V6)<0||sql(c,od_kai_training_schema())<0||sql(c,SCHEMA_V7)<0||sql(c,SCHEMA_V8)<0||sql(c,SCHEMA_V9)<0||sql(c,SCHEMA_V10)<0||sql(c,SCHEMA_V11)<0||sql(c,SCHEMA_V12)<0||sql(c,od_original_teams_schema_sql())<0||sql(c,SCHEMA_V13)<0||writeq(c,"INSERT INTO meta VALUES('content',:a)",NULL,content,NULL)<0||sql(c,"COMMIT")<0)goto bad;
 }else if(version>=1&&version<=12){
  if(!validate_save_version(c,c->db,(int)version)||sql(c,"BEGIN IMMEDIATE")<0||(version==1&&sql(c,SCHEMA_V2)<0)||(version<=2&&sql(c,SCHEMA_V3)<0)||(version<=3&&sql(c,SCHEMA_V4)<0)||(version<=4&&sql(c,od_schedule_store_schema())<0)||(version<=5&&(sql(c,od_schedule_store_schema_v2())<0||sql(c,SCHEMA_V6)<0))||(version<=6&&(sql(c,od_kai_training_schema())<0||sql(c,SCHEMA_V7)<0))||(version<=7&&sql(c,SCHEMA_V8)<0)||(version<=8&&sql(c,SCHEMA_V9)<0)||(version<=9&&sql(c,SCHEMA_V10)<0)||(version<=10&&sql(c,SCHEMA_V11)<0)||(version<=11&&sql(c,SCHEMA_V12)<0)||sql(c,od_original_teams_schema_sql())<0||sql(c,SCHEMA_V13)<0||sql(c,"COMMIT")<0)goto bad;
 }else if(version!=13)goto bad;
 char *saved=query(c,"SELECT v FROM meta WHERE k='content'",NULL,NULL,NULL);int same=saved&&!strcmp(saved,content);sqlite3_free(saved);if(!same)goto bad;
 sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(c->master,"SELECT id FROM cards LIMIT 1",-1,&s,NULL)!=SQLITE_OK)goto bad;sqlite3_finalize(s);
 if(!validate_save(c,c->db))goto bad;
 /* TEMP instrumentation captures only inserts made by this owner connection.
  * Backup/import never fires it, so unknown legacy EXP is never backfilled. */
 if(sql(c,"CREATE TEMP TABLE _od_new_owned_progress(instance_id INTEGER PRIMARY KEY);CREATE TEMP TRIGGER _od_capture_new_owned AFTER INSERT ON main.owned_cards BEGIN INSERT INTO _od_new_owned_progress VALUES(NEW.id); END;")<0)goto bad;
 *out=c;return 0;
bad:od_close(c);return -1;
}
void od_close(od_core *c) { if(!c)return;if(c->db)sqlite3_close(c->db);if(c->master)sqlite3_close(c->master);sqlite3_free(c->content);free(c); }

/* Grant is a trusted server operation: the future wire adapter must never forward client reward amounts.
 * Categories are internal, independent of the game's unverified integer item enums. */
static int grant(od_core *c,const char *p,const char *a,const char *source,int apply) {
 sqlite3_stmt *s=prepare(c,"SELECT json_extract(value,'$.kind'),json_extract(value,'$.id'),json_extract(value,'$.quantity'),json_type(value,'$.id'),json_type(value,'$.quantity') FROM json_each(:a,'$.rewards')",p,a,NULL);if(!s)return -1;
 int count=0,rc;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  if(++count>100||sqlite3_column_type(s,0)!=SQLITE_TEXT||sqlite3_column_type(s,1)!=SQLITE_INTEGER||sqlite3_column_type(s,2)!=SQLITE_INTEGER||!sqlite3_column_text(s,3)||!sqlite3_column_text(s,4)||strcmp((const char *)sqlite3_column_text(s,3),"integer")||strcmp((const char *)sqlite3_column_text(s,4),"integer")){sqlite3_finalize(s);return fail(c,"INVALID_REWARD");}
  const char *kind=(const char *)sqlite3_column_text(s,0);int64_t id=sqlite3_column_int64(s,1),q=sqlite3_column_int64(s,2);int mul=3;const char *table=NULL;
  if(!strcmp(kind,"stone")){mul=10;if(id!=0){sqlite3_finalize(s);return fail(c,"INVALID_REWARD");}}
  else if(!strcmp(kind,"medal")){mul=6;table="awakening_items";}
  else if(!strcmp(kind,"training"))table="training_items";
  else if(!strcmp(kind,"support"))table="support_items";
  else if(!strcmp(kind,"equipment"))table="equipment_skill_items";
  else if(!strcmp(kind,"act"))table="act_items";
  else if(!strcmp(kind,"potential")){if(!source||strncmp(source,"grant:",6)){sqlite3_finalize(s);return fail(c,"POTENTIAL_TRUSTED_GRANT_REQUIRED");}table="potential_items";}
  else{sqlite3_finalize(s);return fail(c,"UNKNOWN_REWARD_KIND");}
  if(id<0||q<1||q>OD_LIMIT/mul||(table&&!master_exists(c,table,id))){sqlite3_finalize(s);return fail(c,"INVALID_REWARD");}
  int64_t amount=0;od_reward_category category=!strcmp(kind,"stone")?OD_REWARD_DRAGON_STONE:!strcmp(kind,"medal")?OD_REWARD_MEDAL:OD_REWARD_ITEM;
  if(od_progression_amount(category,OD_QUANTITY_REWARD,q,&amount)!=OD_PROGRESSION_OK||amount>OD_LIMIT){sqlite3_finalize(s);return fail(c,"QUANTITY_OVERFLOW");}
  if(!apply)continue;
  sqlite3_stmt *u=prepare(c,"INSERT INTO inventory(profile,kind,item_id,quantity) VALUES(:p,:id,?4,?5) ON CONFLICT(profile,kind,item_id) DO UPDATE SET quantity=quantity+excluded.quantity WHERE quantity<=9007199254740991-excluded.quantity",p,NULL,kind);
  if(!u){sqlite3_finalize(s);return -1;}sqlite3_bind_int64(u,4,id);sqlite3_bind_int64(u,5,amount);int urc=sqlite3_step(u);sqlite3_finalize(u);if(urc!=SQLITE_DONE||sqlite3_changes(c->db)!=1){sqlite3_finalize(s);return fail(c,"QUANTITY_OVERFLOW");}
 }
 sqlite3_finalize(s);if(rc!=SQLITE_DONE||count==0)return fail(c,"INVALID_REWARD");
 return apply?writeq(c,"INSERT INTO reward_sources(profile,source,input) VALUES(:p,:id,json(:a))",p,a,source):0;
}

static int validate_rewards(od_core *c,const char *a) {int64_t valid=0;if(scalar(c,"SELECT json_type(:a,'$.rewards')='array' AND json_array_length(:a,'$.rewards') BETWEEN 1 AND 100",NULL,a,NULL,&valid)<0)return -1;return valid?0:fail(c,"INVALID_REWARD");}

/* Trusted encounter plans may explicitly have no rewards. This never weakens
 * ordinary grants: even an empty run writes its unique settlement ledger. */
static int grant_run(od_core *c,const char *p,const char *a,const char *source,int apply) {
 int64_t count=0,valid=0;
 if(scalar(c,"SELECT json_type(:a,'$.rewards')='array' AND json_array_length(:a,'$.rewards') BETWEEN 0 AND 100",p,a,NULL,&valid)<0||!valid)return fail(c,"INVALID_REWARD");
 if(scalar(c,"SELECT json_array_length(:a,'$.rewards')",p,a,NULL,&count)<0)return -1;
 if(count)return grant(c,p,a,source,apply);
 if(!apply)return 0;
 if(!identifier(source))return fail(c,"INVALID_ARGUMENT");
 return writeq(c,"INSERT INTO reward_sources(profile,source,input) VALUES(:p,:id,json(:a))",p,a,source);
}

typedef struct {
 od_summon_entry *entries;
 int64_t *masters;
 size_t count;
 od_summon_policy policy;
 char main_id[128];
 uint64_t version,epoch;
 od_pity_state pity;
} stored_banner;
static void banner_free(stored_banner *b) {
 if(b->entries)for(size_t i=0;i<b->count;i++)sqlite3_free((void *)b->entries[i].definition_id);
 free(b->entries);free(b->masters);memset(b,0,sizeof(*b));
}
static int secure_random(void *unused,void *bytes,size_t length) {
 (void)unused;
#if defined(__APPLE__)
 return SecRandomCopyBytes(kSecRandomDefault,length,bytes)==errSecSuccess;
#else
 unsigned char *p=bytes;
#if defined(__linux__) && !defined(__ANDROID__)
 while(length){ssize_t n=getrandom(p,length,0);if(n<0&&errno==EINTR)continue;if(n<=0)return 0;p+=n;length-=(size_t)n;}return 1;
#else
 int fd=open("/dev/urandom",O_RDONLY);if(fd<0)return 0;
 while(length){ssize_t n=read(fd,p,length);if(n<0&&errno==EINTR)continue;if(n<=0){close(fd);return 0;}p+=n;length-=(size_t)n;}close(fd);return 1;
#endif
#endif
}
static int rarity(const char *name) {
 static const char *names[]={"N","R","SR","SSR","UR","LR","SLR","GR"};
 for(int i=0;i<8;i++){if(name&&!strcmp(name,names[i]))return i;}
 return -1;
}
/* Settings-only definitions are a separate namespace; none of these rows are executed as SQL. */
static int definition_table(const char *name) {
 static const char *allowed[]={"leader_skill_sets","leader_skills","passive_skill_sets","passive_skill_set_relations","passive_skills","card_specials","special_sets","specials","extra_special_options","card_active_skills","active_skill_sets","active_skills","card_standby_skill_set_relations","standby_skill_sets","standby_skills","standby_skill_set_finish_skill_set_relations","card_finish_skill_set_relations","finish_skill_sets","finish_skills","finish_specials","card_card_categories","card_categories","dokkan_fields","dokkan_field_active_skill_set_relations","dokkan_field_passive_skill_relations","link_skills","skill_causalities","sub_target_types","transformation_descriptions"};
 for(size_t i=0;i<sizeof(allowed)/sizeof(*allowed);i++)if(!strcmp(name,allowed[i]))return 1;
 return 0;
}
static const char *reference_table(const char *column) {
 static const char *columns[]={"card_id","passive_skill_set_id","passive_skill_id","target_passive_skill_set_id","additional_passive_skill_set_id","leader_skill_set_id","special_set_id","card_special_id","active_skill_set_id","standby_skill_set_id","finish_skill_set_id","finish_special_id","card_category_id","dokkan_field_id","character_id","card_unique_info_id","potential_board_id","awaked_card_id","card_awakening_set_id"};
 static const char *tables[]={"cards","passive_skill_sets","passive_skills","passive_skill_sets","passive_skill_sets","leader_skill_sets","special_sets","card_specials","active_skill_sets","standby_skill_sets","finish_skill_sets","finish_specials","card_categories","dokkan_fields","characters","card_unique_infos","potential_boards","cards","card_awakening_sets"};
 for(size_t i=0;i<sizeof(columns)/sizeof(*columns);i++)if(!strcmp(column,columns[i]))return tables[i];
 if(strlen(column)==14&&!strncmp(column,"link_skill",10)&&column[10]>='1'&&column[10]<='7'&&!strcmp(column+11,"_id"))return "link_skills";
 return NULL;
}
static int definition_has(od_core *c,const char *document,const char *table,int64_t id) {
 if(id==0)return 1;
 if(!strcmp(table,"cards")){int64_t source=0;return integer_arg(c,document,"$.source.master_id",1,OD_LIMIT,&source)==0&&source==id?1:master_exists(c,table,id);}
 char *path=sqlite3_mprintf("$.tables.%s",table);if(!path)return 0;
 sqlite3_stmt *s=prepare(c,"SELECT EXISTS(SELECT 1 FROM json_each(:a,:id) WHERE json_type(value,'$.id')='integer' AND json_extract(value,'$.id')=?4)",NULL,document,path);sqlite3_free(path);if(!s)return 0;
 sqlite3_bind_int64(s,4,id);int found=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);return found||master_exists(c,table,id);
}
static int definition_row(od_core *c,const char *document,const char *table,const char *row) {
 sqlite3_stmt *s=prepare(c,"SELECT key,value,type FROM json_each(:a)",NULL,row,NULL);if(!s)return -1;int rc,fields=0;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  const char *column=(const char *)sqlite3_column_text(s,0),*type=(const char *)sqlite3_column_text(s,2);sqlite3_stmt *m=NULL;
  if(!column||!identifier(column)||!type||!strcmp(type,"object")||!strcmp(type,"array")||!strcmp(type,"true")||!strcmp(type,"false")){sqlite3_finalize(s);return fail(c,"INVALID_DEFINITION_ROW");}
  if(sqlite3_prepare_v2(c->master,"SELECT type,\"notnull\" FROM pragma_table_info(?1) WHERE name=?2",-1,&m,NULL)!=SQLITE_OK){sqlite3_finalize(s);return fail(c,"MASTER_SCHEMA_UNSUPPORTED");}
  sqlite3_bind_text(m,1,table,-1,SQLITE_STATIC);sqlite3_bind_text(m,2,column,-1,SQLITE_TRANSIENT);int mr=sqlite3_step(m),good=mr==SQLITE_ROW;
  if(good){
   const char *decl=(const char *)sqlite3_column_text(m,0);int nullable=!sqlite3_column_int(m,1);
   if(!strcmp(type,"null"))good=nullable;
   else if(strstr(decl,"int")||strstr(decl,"INT"))good=!strcmp(type,"integer")&&sqlite3_column_int64(s,1)>=-OD_LIMIT&&sqlite3_column_int64(s,1)<=OD_LIMIT;
   else if(strstr(decl,"float")||strstr(decl,"REAL")||strstr(decl,"double"))good=(!strcmp(type,"integer")||!strcmp(type,"real"))&&sqlite3_column_double(s,1)>=-9007199254740991.0&&sqlite3_column_double(s,1)<=9007199254740991.0;
   else good=!strcmp(type,"text")&&sqlite3_column_bytes(s,1)<=65536&&memchr(sqlite3_column_text(s,1),0,(size_t)sqlite3_column_bytes(s,1))==NULL;
  }
  sqlite3_finalize(m);if(!good){sqlite3_finalize(s);return fail(c,"INVALID_DEFINITION_ROW");}
  if(!strcmp(type,"text")&&(!strcmp(column,"efficacy_values")||!strcmp(column,"causality_conditions"))&&sqlite3_column_bytes(s,1)>0){
   int64_t valid=0;if(scalar(c,"SELECT json_valid(:a)",NULL,(const char *)sqlite3_column_text(s,1),NULL,&valid)<0||!valid){sqlite3_finalize(s);return fail(c,"INVALID_DEFINITION_ROW");}
  }

  const char *target=reference_table(column);
  if(target&&!strcmp(type,"integer")&&!definition_has(c,document,target,sqlite3_column_int64(s,1))){sqlite3_finalize(s);return fail(c,"DEFINITION_REFERENCE_MISSING");}
  fields++;
 }
 sqlite3_finalize(s);if(rc!=SQLITE_DONE||!fields)return fail(c,"INVALID_DEFINITION_ROW");
 /* Require the complete non-null source-shaped row; optional fields may be omitted. */
 sqlite3_stmt *m=NULL;if(sqlite3_prepare_v2(c->master,"SELECT name FROM pragma_table_info(?1) WHERE \"notnull\"=1 OR pk>0",-1,&m,NULL)!=SQLITE_OK)return fail(c,"MASTER_SCHEMA_UNSUPPORTED");
 sqlite3_bind_text(m,1,table,-1,SQLITE_STATIC);
 while((rc=sqlite3_step(m))==SQLITE_ROW){char *path=sqlite3_mprintf("$.%s",sqlite3_column_text(m,0));int64_t n=0;int good=path&&scalar(c,"SELECT json_type(:a,:id) IS NOT NULL AND json_type(:a,:id)!='null'",NULL,row,path,&n)==0&&n;sqlite3_free(path);if(!good){sqlite3_finalize(m);return fail(c,"DEFINITION_FIELD_MISSING");}}
 sqlite3_finalize(m);return rc==SQLITE_DONE?0:fail(c,"DATABASE_ERROR");
}
static int definition_validate_ex(od_core *c,const char *document,int official,int full_allowed) {
 int64_t n=0,id=0,version=0;
 const char *shape="SELECT json_type(:a)='object' AND json_extract(:a,'$.format')='offline-dokkan-definition' AND json_type(:a,'$.schema_version')='integer' AND json_extract(:a,'$.schema_version')=1 AND json_type(:a,'$.fully_awakened')='true' AND json_type(:a,'$.source')='object' AND json_type(:a,'$.card')='object' AND json_type(:a,'$.tables')='object' AND NOT EXISTS(SELECT 1 FROM json_tree(:a) WHERE type='text' AND instr(atom,char(0))>0 OR instr(key,char(0))>0) AND NOT EXISTS(SELECT 1 FROM json_tree(:a) WHERE type='object' AND (SELECT count(*) FROM json_each(json_tree.value))!=(SELECT count(DISTINCT key) FROM json_each(json_tree.value))) AND NOT EXISTS(SELECT 1 FROM json_each(:a) WHERE key NOT IN('format','schema_version','definition_id','version','source','rarity','fully_awakened','card','tables','creator','progression_policy','stat_policy','full_bundle')) AND NOT EXISTS(SELECT 1 FROM json_each(:a,'$.source') WHERE key NOT IN('content_id','master_id'))";
 if(scalar(c,shape,NULL,document,NULL,&n)<0||!n)return fail(c,"INVALID_DEFINITION");
 int64_t has_full=0;
 if(scalar(c,"SELECT json_type(:a,'$.full_bundle') IS NOT NULL",NULL,document,NULL,&has_full)<0)return -1;
 if(has_full){
  if(!full_allowed||official)return fail(c,"FULL_BUNDLE_NATIVE_VALIDATION_REQUIRED");
  const char *binding="SELECT json_type(:a,'$.full_bundle')='object' AND json_extract(:a,'$.full_bundle.format')='od-full-creator-binding-v2' AND json_extract(:a,'$.full_bundle.projection')='progression-root-v1' AND json_extract(:a,'$.full_bundle.content_id')=json_extract(:a,'$.source.content_id') AND json_extract(:a,'$.full_bundle.definition_id')=json_extract(:a,'$.definition_id') AND json_type(:a,'$.full_bundle.version')='integer' AND json_extract(:a,'$.full_bundle.version')=json_extract(:a,'$.version') AND json_type(:a,'$.full_bundle.profile_id')='text' AND length(json_extract(:a,'$.full_bundle.profile_id')) BETWEEN 1 AND 127 AND json_type(:a,'$.full_bundle.member_count')='integer' AND json_extract(:a,'$.full_bundle.member_count') BETWEEN 1 AND 5 AND (SELECT count(*) FROM json_each(:a,'$.full_bundle'))=10 AND NOT EXISTS(SELECT 1 FROM json_each(:a,'$.full_bundle') WHERE key NOT IN('format','projection','content_id','profile_id','save_scope','definition_id','version','project_sha256','full_bundle_sha256','member_count')) AND NOT EXISTS(SELECT 1 FROM json_each(:a,'$.full_bundle') WHERE key IN('save_scope','project_sha256','full_bundle_sha256') AND (type!='text' OR length(value)!=64 OR value GLOB '*[^0-9a-f]*'))";
  if(scalar(c,binding,NULL,document,NULL,&n)<0||!n)return fail(c,"FULL_BUNDLE_BINDING_INVALID");
 }
 if(scalar(c,"SELECT json_type(:a,'$.creator') IS NOT NULL",NULL,document,NULL,&n)<0)return -1;
 if(n){
  char *credit=query(c,"SELECT CASE WHEN json_type(:a,'$.creator.id')='text' THEN json_extract(:a,'$.creator.id') END",NULL,document,NULL);
  int64_t valid=0;int good=identifier(credit)&&scalar(c,"SELECT json_type(:a,'$.creator')='object' AND json_type(:a,'$.creator.name')='text' AND length(trim(json_extract(:a,'$.creator.name'))) BETWEEN 1 AND 80 AND instr(json_extract(:a,'$.creator.name'),char(0))=0 AND NOT EXISTS(SELECT 1 FROM json_each(:a,'$.creator') WHERE key NOT IN('id','name'))",NULL,document,NULL,&valid)==0&&valid;sqlite3_free(credit);if(!good)return fail(c,"INVALID_CREATOR_CREDIT");
 }

 char *key=query(c,"SELECT json_extract(:a,'$.definition_id')",NULL,document,NULL),*content=query(c,"SELECT json_extract(:a,'$.source.content_id')",NULL,document,NULL),*name=query(c,"SELECT CASE WHEN json_type(:a,'$.card.name')='text' THEN trim(json_extract(:a,'$.card.name')) END",NULL,document,NULL),*r=query(c,"SELECT json_extract(:a,'$.rarity')",NULL,document,NULL);
 int category=rarity(r),good=identifier(key)&&content&&!strcmp(content,c->content)&&name&&strcmp(name,"(NULL)")&&*name&&strlen(name)<=1024&&category>=OD_RARITY_UR;sqlite3_free(key);sqlite3_free(content);sqlite3_free(name);sqlite3_free(r);if(!good)return fail(c,"INVALID_DEFINITION");
 if(integer_arg(c,document,"$.version",1,OD_LIMIT,&version)<0||integer_arg(c,document,"$.source.master_id",1,OD_LIMIT,&id)<0||!master_exists(c,"cards",id))return fail(c,"CARD_NOT_FOUND");
 int64_t actual=0;if(integer_arg(c,document,"$.card.id",1,OD_LIMIT,&actual)<0||actual!=id)return fail(c,"DEFINITION_SOURCE_MISMATCH");
 /* Only normal Z/Dokkan outgoing routes disqualify a source. Optimal self-routes are EZA. */
 sqlite3_stmt *m=NULL;if(sqlite3_prepare_v2(c->master,"SELECT 1 FROM card_awakening_routes WHERE card_id=?1 AND awaked_card_id!=card_id AND type IN('CardAwakeningRoute::Dokkan','CardAwakeningRoute::Zet') LIMIT 1",-1,&m,NULL)!=SQLITE_OK)return fail(c,"MASTER_SCHEMA_UNSUPPORTED");
 sqlite3_bind_int64(m,1,id);int mr=sqlite3_step(m);sqlite3_finalize(m);if(mr!=SQLITE_DONE)return fail(c,"SOURCE_NOT_FULLY_AWAKENED");
 const char *caps[]={"$.card.lv_max","$.card.skill_lv_max","$.card.hp_max","$.card.atk_max","$.card.def_max"};
 for(size_t i=0;i<5;i++)if(integer_arg(c,document,caps[i],1,INT32_MAX,&n)<0)return fail(c,"INVALID_DEFINITION_STATS");
 const char *initial[]={"hp","atk","def"};for(size_t i=0;i<3;i++){char *q=sqlite3_mprintf("SELECT json_type(:a,'$.card.%s_init')='integer' AND json_extract(:a,'$.card.%s_init') BETWEEN 0 AND json_extract(:a,'$.card.%s_max')",initial[i],initial[i],initial[i]);int valid=q&&scalar(c,q,NULL,document,NULL,&n)==0&&n;sqlite3_free(q);if(!valid)return fail(c,"INVALID_DEFINITION_STATS");}
 if(integer_arg(c,document,"$.card.rarity",4,5,&n)<0||(category==OD_RARITY_UR?n!=4:n!=5))return fail(c,"INVALID_DEFINITION_RARITY");
 if(category==OD_RARITY_SLR||category==OD_RARITY_GR){int64_t cap=0;if(integer_arg(c,document,"$.card.lv_max",1,INT32_MAX,&cap)<0||cap!=(category==OD_RARITY_SLR?180:200))return fail(c,"INVALID_DEFINITION_RARITY");}
 if(scalar(c,"SELECT json_type(:a,'$.progression_policy') IS NULL OR json_type(:a,'$.progression_policy')='text' AND json_extract(:a,'$.progression_policy')='creator-lr-extended-v1'",NULL,document,NULL,&n)<0||!n)return fail(c,"UNSUPPORTED_PROGRESSION_POLICY");
 if(scalar(c,"SELECT json_type(:a,'$.stat_policy') IS NULL OR json_type(:a,'$.stat_policy')='text' AND json_extract(:a,'$.stat_policy') IN('master-coefficient-linear-floor-v1','creator-cap-normalized-v1')",NULL,document,NULL,&n)<0||!n)return fail(c,"UNSUPPORTED_STAT_POLICY");
 if(scalar(c,"SELECT json_type(:a,'$.card.element')='integer' AND json_extract(:a,'$.card.element') IN(0,1,2,3,4,10,11,12,13,14,20,21,22,23,24)",NULL,document,NULL,&n)<0||!n)return fail(c,"INVALID_DEFINITION_ELEMENT");
 if(integer_arg(c,document,"$.card.leader_skill_set_id",-OD_LIMIT,OD_LIMIT,&n)<0||n==0||integer_arg(c,document,"$.card.passive_skill_set_id",-OD_LIMIT,OD_LIMIT,&n)<0||n==0)return fail(c,"DEFINITION_SKILLS_MISSING");
 if(scalar(c,"SELECT count(*)=count(DISTINCT value) FROM json_each(:a,'$.card') WHERE key GLOB 'link_skill[1-7]_id' AND type!='null' AND value!=0",NULL,document,NULL,&n)<0||!n)return fail(c,"DUPLICATE_LINK_SKILL");

 if(scalar(c,"SELECT json_type(:a,'$.card.cost') IS NULL OR json_type(:a,'$.card.cost')='integer' AND json_extract(:a,'$.card.cost') BETWEEN 0 AND 2147483647",NULL,document,NULL,&n)<0||!n)return fail(c,"INVALID_DEFINITION_STATS");
 char *card=query(c,"SELECT json_extract(:a,'$.card')",NULL,document,NULL);if(!card)return -1;int result=definition_row(c,document,"cards",card);sqlite3_free(card);if(result<0)return -1;
 sqlite3_stmt *s=prepare(c,"SELECT key,value,type FROM json_each(:a,'$.tables')",NULL,document,NULL);if(!s)return -1;int rc,rows=0;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  const char *table=(const char *)sqlite3_column_text(s,0),*type=(const char *)sqlite3_column_text(s,2);if((!definition_table(table)&&!(official&&(!strcmp(table,"optimal_awakening_growths")||!strcmp(table,"card_awakening_routes"))))||strcmp(type,"array")){sqlite3_finalize(s);return fail(c,"UNSUPPORTED_DEFINITION_TABLE");}
  const char *array=(const char *)sqlite3_column_text(s,1);sqlite3_stmt *rstmt=prepare(c,"SELECT value,type FROM json_each(:a)",NULL,array,NULL);if(!rstmt){sqlite3_finalize(s);return -1;}int rr;
  while((rr=sqlite3_step(rstmt))==SQLITE_ROW){const char *row=(const char *)sqlite3_column_text(rstmt,0);int64_t rid=0;if(++rows>10000||strcmp((const char *)sqlite3_column_text(rstmt,1),"object")||integer_arg(c,row,"$.id",-OD_LIMIT,OD_LIMIT,&rid)<0||rid==0||definition_row(c,document,table,row)<0){sqlite3_finalize(rstmt);sqlite3_finalize(s);return fail(c,"INVALID_DEFINITION_ROW");}}
  sqlite3_finalize(rstmt);if(rr!=SQLITE_DONE){sqlite3_finalize(s);return fail(c,"INVALID_DEFINITION_ROW");}
  char *path=sqlite3_mprintf("$.tables.%s",table);int64_t distinct=0;int valid=path&&scalar(c,"SELECT count(*)=count(DISTINCT json_extract(value,'$.id')) FROM json_each(:a,:id)",NULL,document,path,&distinct)==0&&distinct;sqlite3_free(path);if(!valid){sqlite3_finalize(s);return fail(c,"DUPLICATE_DEFINITION_ROW");}
 }
 sqlite3_finalize(s);return rc==SQLITE_DONE?0:fail(c,"INVALID_DEFINITION");
}
static int definition_validate(od_core *c,const char *document){return definition_validate_ex(c,document,0,0);}

static char *creator_library(od_core *c,const char *p) {
 return query(c,"SELECT json_object('revision',(SELECT revision FROM profiles WHERE id=:p),'epoch',COALESCE((SELECT epoch FROM creator_state WHERE profile=:p),0),'main_id',(SELECT main_id FROM creator_state WHERE profile=:p),'featured',json(COALESCE((SELECT json_group_array(definition_id) FROM (SELECT definition_id FROM created_active WHERE profile=:p ORDER BY sequence DESC LIMIT 5)),'[]')),'definitions',json(COALESCE((SELECT json_group_array(json_object('definition_id',definition_id,'version',version,'sequence',sequence,'name',json_extract(document,'$.card.name'),'rarity',json_extract(document,'$.rarity'),'creator',json_extract(document,'$.creator'))) FROM (SELECT a.*,d.document FROM created_active a JOIN created_definitions d USING(profile,definition_id,version) WHERE a.profile=:p ORDER BY sequence DESC)),'[]'))) ",p,NULL,NULL);
}
static int creator_import(od_core *c,const char *p,const char *a,char **out,int full_allowed) {
 int64_t unknown=0;if(scalar(c,"SELECT count(*) FROM json_each(:a) WHERE key!='definition'",p,a,NULL,&unknown)<0||unknown)return fail(c,"INVALID_ARGUMENT");
 char *d=query(c,"SELECT CASE WHEN json_type(:a,'$.definition')='object' THEN json_extract(:a,'$.definition') END",p,a,NULL);if(!d)return -1;if(definition_validate_ex(c,d,0,full_allowed)<0){sqlite3_free(d);return -1;}
 if(full_allowed){int64_t same_profile=0;if(scalar(c,"SELECT json_extract(:a,'$.full_bundle.profile_id')=:p",p,d,NULL,&same_profile)<0||!same_profile){sqlite3_free(d);return fail(c,"FULL_BUNDLE_PROFILE_MISMATCH");}}
 char *id=query(c,"SELECT json_extract(:a,'$.definition_id')",p,d,NULL);if(!id){sqlite3_free(d);return -1;}int64_t active=0,version=0;
 if(!strncmp(id,"tournament-exclusive:",21)||od_schedule_store_is_exclusive_id(c->db,p,id)!=0){sqlite3_free(id);sqlite3_free(d);return fail(c,"TOURNAMENT_EXCLUSIVE_NOT_SHAREABLE");}integer_arg(c,d,"$.version",1,OD_LIMIT,&version);
 sqlite3_stmt *s=prepare(c,"SELECT version FROM created_active WHERE profile=:p AND definition_id=:id",p,d,id);if(!s)goto bad;int rc=sqlite3_step(s);if(rc==SQLITE_ROW)active=sqlite3_column_int64(s,0);sqlite3_finalize(s);
 if(active&&version<=active){
  if(version<active){fail(c,"DEFINITION_VERSION_STALE");goto bad;}
  int64_t same=0;if(scalar(c,"SELECT od_json_equal(document,:a) FROM created_definitions WHERE profile=:p AND definition_id=:id AND version=json_extract(:a,'$.version')",p,d,id,&same)<0||!same){fail(c,"DEFINITION_VERSION_CONFLICT");goto bad;}
  *out=creator_library(c,p);sqlite3_free(id);sqlite3_free(d);return *out?1:-1;
 }
 int64_t conflict=0;
 if(active&&scalar(c,"SELECT EXISTS(SELECT 1 FROM created_definitions WHERE profile=:p AND definition_id=:id AND json_type(document,'$.creator') IS NOT NULL AND COALESCE(json_extract(document,'$.creator.id')!=json_extract(:a,'$.creator.id') OR json_extract(document,'$.creator.name')!=json_extract(:a,'$.creator.name'),1))",p,d,id,&conflict)<0)goto bad;
 if(conflict){fail(c,"CREATOR_CREDIT_CONFLICT");goto bad;}
 if(active&&scalar(c,"SELECT EXISTS(SELECT 1 FROM created_definitions WHERE profile=:p AND definition_id=:id AND json_type(document,'$.stat_policy') IS NOT NULL AND json_extract(document,'$.stat_policy') IS NOT json_extract(:a,'$.stat_policy'))",p,d,id,&conflict)<0)goto bad;
 if(conflict){fail(c,"STAT_POLICY_CONFLICT");goto bad;}

 if(scalar(c,"SELECT EXISTS(SELECT 1 FROM created_definitions WHERE profile=:p AND definition_id=:id AND (master_id!=json_extract(:a,'$.source.master_id') OR rarity!=CASE json_extract(:a,'$.rarity') WHEN 'UR' THEN 4 WHEN 'LR' THEN 5 WHEN 'SLR' THEN 6 ELSE 7 END)) OR EXISTS(SELECT 1 FROM banner_entries WHERE profile=:p AND definition_id=:id AND (master_id!=json_extract(:a,'$.source.master_id') OR rarity!=CASE json_extract(:a,'$.rarity') WHEN 'UR' THEN 4 WHEN 'LR' THEN 5 WHEN 'SLR' THEN 6 ELSE 7 END))",p,d,id,&conflict)<0||conflict){fail(c,"DEFINITION_CONFLICT");goto bad;}
 if(scalar(c,"SELECT EXISTS(SELECT 1 FROM owned_definitions d JOIN owned_cards c ON c.id=d.instance_id WHERE d.profile=:p AND d.definition_id=:id AND (c.level>json_extract(:a,'$.card.lv_max') OR c.sa_level>json_extract(:a,'$.card.skill_lv_max')))",p,d,id,&conflict)<0||conflict){fail(c,"DEFINITION_PROGRESS_CONFLICT");goto bad;}
 if(active){
  if(scalar(c,"SELECT EXISTS(SELECT 1 FROM runs r,json_each(r.team_snapshot) j JOIN owned_definitions d ON d.instance_id=j.value WHERE r.profile=:p AND r.state='started' AND d.profile=:p AND d.definition_id=:id)",p,d,id,&conflict)<0||conflict){fail(c,"DEFINITION_IN_USE");goto bad;}
 }
 if(writeq(c,"INSERT INTO created_definitions VALUES(:p,:id,json_extract(:a,'$.version'),json_extract(:a,'$.source.master_id'),CASE json_extract(:a,'$.rarity') WHEN 'UR' THEN 4 WHEN 'LR' THEN 5 WHEN 'SLR' THEN 6 ELSE 7 END,json(:a))",p,d,id)<0)goto bad;
 if(writeq(c,"INSERT INTO created_active VALUES(:p,:id,json_extract(:a,'$.version'),(SELECT COALESCE(max(sequence),0)+1 FROM created_active WHERE profile=:p)) ON CONFLICT(profile,definition_id) DO UPDATE SET version=excluded.version",p,d,id)<0)goto bad;
 if(writeq(c,"UPDATE owned_definitions SET version=json_extract(:a,'$.version') WHERE profile=:p AND definition_id=:id",p,d,id)<0)goto bad;
 if(!validate_progress(c,c->db)){fail(c,"DEFINITION_PROGRESS_CONFLICT");goto bad;}
 if(!active&&writeq(c,"INSERT INTO creator_state VALUES(:p,1,:id) ON CONFLICT(profile) DO UPDATE SET epoch=epoch+1,main_id=excluded.main_id",p,d,id)<0)goto bad;
 *out=creator_library(c,p);sqlite3_free(id);sqlite3_free(d);return *out?0:-1;
 bad:sqlite3_free(id);sqlite3_free(d);return -1;
}

static int banner_check(od_core *c,stored_banner *b) {
 if(od_summon_validate_pool(b->entries,b->count,&b->policy)!=OD_SUMMON_OK)return fail(c,"INVALID_BANNER_POOL");
 unsigned limit=0;for(size_t i=0;i<b->count;i++){
  if(!master_exists(c,"cards",b->masters[i]))return fail(c,"CARD_NOT_FOUND");
  if(!strcmp(b->entries[i].definition_id,b->main_id))limit=od_summon_pity_limit(b->entries[i].rarity);
 }
 return limit?0:fail(c,"MAIN_FEATURE_POLICY_REQUIRED");
}
static int banner_parse(od_core *c,const char *a,stored_banner *b) {
 int64_t x=0;memset(b,0,sizeof(*b));
 const char *keys[]={"$.version","$.epoch","$.policy.multi_count","$.policy.lr_ppm","$.policy.slr_ppm","$.policy.gr_ppm"};
 for(int i=0;i<6;i++){
  if(integer_arg(c,a,keys[i],i<3?1:0,i<2?OD_LIMIT:i==2?OD_SUMMON_MAX_MULTI:1000000,&x)<0)goto bad;
  if(i==0)b->version=(uint64_t)x;else if(i==1)b->epoch=(uint64_t)x;else if(i==2)b->policy.multi_count=(unsigned)x;else if(i==3)b->policy.lr_ppm=(uint32_t)x;else if(i==4)b->policy.slr_ppm=(uint32_t)x;else b->policy.gr_ppm=(uint32_t)x;
 }
 char *main=query(c,"SELECT CASE WHEN json_type(:a,'$.main_id')='text' THEN json_extract(:a,'$.main_id') END",NULL,a,NULL);
 if(!identifier(main)){sqlite3_free(main);fail(c,"INVALID_ARGUMENT");goto bad;}snprintf(b->main_id,sizeof(b->main_id),"%s",main);sqlite3_free(main);
 if(scalar(c,"SELECT CASE WHEN json_type(:a,'$.pool')='array' THEN json_array_length(:a,'$.pool') ELSE 0 END",NULL,a,NULL,&x)<0||x<1||x>OD_SUMMON_MAX_POOL){fail(c,"INVALID_BANNER_POOL");goto bad;}
 b->count=(size_t)x;b->entries=calloc(b->count,sizeof(*b->entries));b->masters=calloc(b->count,sizeof(*b->masters));if(!b->entries||!b->masters){fail(c,"NO_MEMORY");goto bad;}
 sqlite3_stmt *s=prepare(c,"SELECT json_extract(value,'$.definition_id'),json_extract(value,'$.master_id'),json_extract(value,'$.rarity'),json_extract(value,'$.weight_ppm'),json_type(value,'$.master_id'),json_type(value,'$.weight_ppm') FROM json_each(:a,'$.pool')",NULL,a,NULL);if(!s)goto bad;
 size_t n=0;int rc;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  const char *id=(const char *)sqlite3_column_text(s,0);int r=rarity((const char *)sqlite3_column_text(s,2));
  if(n>=b->count||sqlite3_column_type(s,0)!=SQLITE_TEXT||!identifier(id)||r<0||sqlite3_column_type(s,1)!=SQLITE_INTEGER||sqlite3_column_type(s,3)!=SQLITE_INTEGER||!sqlite3_column_text(s,4)||!sqlite3_column_text(s,5)||strcmp((const char *)sqlite3_column_text(s,4),"integer")||strcmp((const char *)sqlite3_column_text(s,5),"integer")||sqlite3_column_int64(s,1)<1||sqlite3_column_int64(s,1)>OD_LIMIT||sqlite3_column_int64(s,3)<0||sqlite3_column_int64(s,3)>1000000){sqlite3_finalize(s);fail(c,"INVALID_BANNER_POOL");goto bad;}
  b->entries[n].definition_id=sqlite3_mprintf("%s",id);b->entries[n].rarity=(od_summon_rarity)r;b->entries[n].weight_ppm=(uint32_t)sqlite3_column_int64(s,3);b->masters[n]=sqlite3_column_int64(s,1);if(!b->entries[n].definition_id){sqlite3_finalize(s);fail(c,"NO_MEMORY");goto bad;}n++;
 }
 sqlite3_finalize(s);if(rc!=SQLITE_DONE||n!=b->count){fail(c,"INVALID_BANNER_POOL");goto bad;}
 if(banner_check(c,b)<0){goto bad;}
 return 0;
bad:banner_free(b);return -1;
}
static int banner_load(od_core *c,sqlite3 *db,const char *profile,const char *id,uint64_t version,stored_banner *b) {
 memset(b,0,sizeof(*b));sqlite3_stmt *s=NULL;
 const char *q="SELECT v.version,v.epoch,v.main_id,v.multi_count,v.lr_ppm,v.slr_ppm,v.gr_ppm,COALESCE(p.epoch,v.epoch),COALESCE(p.misses,0) FROM banner_versions v LEFT JOIN banner_pity p ON p.profile=v.profile AND p.banner_id=v.banner_id WHERE v.profile=?1 AND v.banner_id=?2 AND v.version=COALESCE(NULLIF(?3,0),(SELECT version FROM banner_active WHERE profile=?1 AND banner_id=?2))";
 if(sqlite3_prepare_v2(db,q,-1,&s,NULL)!=SQLITE_OK){return fail(c,"DATABASE_ERROR");}
 sqlite3_bind_text(s,1,profile,-1,SQLITE_TRANSIENT);sqlite3_bind_text(s,2,id,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,3,(sqlite3_int64)version);
 if(sqlite3_step(s)!=SQLITE_ROW){sqlite3_finalize(s);return fail(c,"BANNER_NOT_FOUND");}
 b->version=(uint64_t)sqlite3_column_int64(s,0);b->epoch=(uint64_t)sqlite3_column_int64(s,1);const char *main=(const char *)sqlite3_column_text(s,2);if(!identifier(main)){sqlite3_finalize(s);return fail(c,"INVALID_BANNER_POOL");}snprintf(b->main_id,sizeof(b->main_id),"%s",main);
 b->policy.multi_count=(unsigned)sqlite3_column_int(s,3);b->policy.lr_ppm=(uint32_t)sqlite3_column_int64(s,4);b->policy.slr_ppm=(uint32_t)sqlite3_column_int64(s,5);b->policy.gr_ppm=(uint32_t)sqlite3_column_int64(s,6);b->pity.epoch=(uint64_t)sqlite3_column_int64(s,7);b->pity.misses=(uint32_t)sqlite3_column_int64(s,8);sqlite3_finalize(s);
 q="SELECT definition_id,master_id,rarity,weight_ppm,ordinal FROM banner_entries WHERE profile=?1 AND banner_id=?2 AND version=?3 ORDER BY ordinal";
 if(sqlite3_prepare_v2(db,q,-1,&s,NULL)!=SQLITE_OK){return fail(c,"DATABASE_ERROR");}
 sqlite3_bind_text(s,1,profile,-1,SQLITE_TRANSIENT);sqlite3_bind_text(s,2,id,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,3,(sqlite3_int64)b->version);
 size_t cap=0;int rc;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  if(b->count>=OD_SUMMON_MAX_POOL||sqlite3_column_int64(s,4)!=(sqlite3_int64)b->count){sqlite3_finalize(s);fail(c,"INVALID_BANNER_POOL");goto bad;}
  if(b->count==cap){cap=cap?cap*2:8;void *e=realloc(b->entries,cap*sizeof(*b->entries));if(!e){sqlite3_finalize(s);fail(c,"NO_MEMORY");goto bad;}b->entries=e;void *m=realloc(b->masters,cap*sizeof(*b->masters));if(!m){sqlite3_finalize(s);fail(c,"NO_MEMORY");goto bad;}b->masters=m;}
  const char *definition=(const char *)sqlite3_column_text(s,0);if(!identifier(definition)){sqlite3_finalize(s);fail(c,"INVALID_BANNER_POOL");goto bad;}
  b->entries[b->count].definition_id=sqlite3_mprintf("%s",definition);if(!b->entries[b->count].definition_id){sqlite3_finalize(s);fail(c,"NO_MEMORY");goto bad;}b->masters[b->count]=sqlite3_column_int64(s,1);b->entries[b->count].rarity=(od_summon_rarity)sqlite3_column_int(s,2);b->entries[b->count].weight_ppm=(uint32_t)sqlite3_column_int64(s,3);b->count++;
 }
 sqlite3_finalize(s);if(rc!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto bad;}if(banner_check(c,b)<0){goto bad;}
 return 0;
bad:banner_free(b);return -1;
}
static char *banner_snapshot(od_core *c,const char *p,const char *a) {
 return query(c,"SELECT json_object('banner_id',v.banner_id,'version',v.version,'main_id',v.main_id,'epoch',v.epoch,'multi_count',v.multi_count,'policy',json_object('lr_ppm',v.lr_ppm,'slr_ppm',v.slr_ppm,'gr_ppm',v.gr_ppm),'pity_misses',p.misses,'pool',json(v.config)->'$.pool') FROM banner_active a JOIN banner_versions v USING(profile,banner_id,version) JOIN banner_pity p USING(profile,banner_id) WHERE a.profile=:p AND a.banner_id=json_extract(:a,'$.banner_id')",p,a,NULL);
}
static int banner_bind_created(od_core *c,const char *p,const char *id,const char *a) {
 int64_t bad=0;
 /* A known created identity can never silently fall back to its original master definition. */
 const char *q="SELECT EXISTS(SELECT 1 FROM json_each(:a,'$.pool') j WHERE (json_type(j.value,'$.definition_version') IS NOT NULL OR EXISTS(SELECT 1 FROM created_active d WHERE d.profile=:p AND d.definition_id=json_extract(j.value,'$.definition_id'))) AND (json_type(j.value,'$.definition_version') IS NOT 'integer' OR NOT EXISTS(SELECT 1 FROM created_definitions d JOIN created_active a USING(profile,definition_id,version) WHERE d.profile=:p AND d.definition_id=json_extract(j.value,'$.definition_id') AND d.version=json_extract(j.value,'$.definition_version') AND d.master_id=json_extract(j.value,'$.master_id') AND d.rarity=CASE json_extract(j.value,'$.rarity') WHEN 'UR' THEN 4 WHEN 'LR' THEN 5 WHEN 'SLR' THEN 6 WHEN 'GR' THEN 7 ELSE -1 END)))";
 if(scalar(c,q,p,a,id,&bad)<0||bad)return fail(c,"CREATED_DEFINITION_BINDING_REQUIRED");
 if(scalar(c,"SELECT EXISTS(SELECT 1 FROM json_each(:a,'$.pool') WHERE json_type(value,'$.definition_version')='integer')",p,a,id,&bad)<0)return -1;
 if(bad){int64_t match=0;if(scalar(c,"SELECT json_type(:a,'$.creator_epoch')='integer' AND EXISTS(SELECT 1 FROM creator_state WHERE profile=:p AND epoch=json_extract(:a,'$.creator_epoch') AND epoch=json_extract(:a,'$.epoch') AND main_id=json_extract(:a,'$.main_id'))",p,a,id,&match)<0||!match)return fail(c,"CREATOR_MAIN_EPOCH_REQUIRED");}

 return writeq(c,"INSERT INTO banner_definitions SELECT :p,:id,json_extract(:a,'$.version'),json_extract(j.value,'$.definition_id'),json_extract(j.value,'$.definition_version') FROM json_each(:a,'$.pool') j WHERE json_type(j.value,'$.definition_version')='integer'",p,a,id);
}
static int bind_owned_created(od_core *c,const char *p,const char *definition,sqlite3_int64 version,od_summon_rarity category,sqlite3_int64 instance) {
 sqlite3_stmt *s=NULL;int rc;
 od_created_card_defaults defaults;if(od_created_instance_defaults(category,1,&defaults)!=OD_PROGRESSION_OK)return fail(c,"INVALID_CREATED_DEFAULTS");
 s=prepare(c,"INSERT INTO owned_definitions(profile,definition_id,instance_id,version,origin_version,exclusive_kind,exclusive_always_on) VALUES(:p,:id,?4,?5,?5,?6,?7)",p,NULL,definition);if(!s)return -1;
 sqlite3_bind_int64(s,4,instance);sqlite3_bind_int64(s,5,version);sqlite3_bind_int(s,6,defaults.exclusive_kind);sqlite3_bind_int(s,7,defaults.exclusive_always_on);rc=sqlite3_step(s);sqlite3_finalize(s);return rc==SQLITE_DONE?0:fail(c,"DATABASE_ERROR");
}
static int grant_created(od_core *c,const char *p,const char *banner,uint64_t banner_version,const od_summon_entry *entry,sqlite3_int64 instance) {
 sqlite3_stmt *s=prepare(c,"SELECT definition_version FROM banner_definitions WHERE profile=:p AND banner_id=:id AND banner_version=?4 AND definition_id=?5",p,NULL,banner);if(!s)return -1;
 sqlite3_bind_int64(s,4,(sqlite3_int64)banner_version);sqlite3_bind_text(s,5,entry->definition_id,-1,SQLITE_TRANSIENT);int rc=sqlite3_step(s);sqlite3_int64 version=rc==SQLITE_ROW?sqlite3_column_int64(s,0):0;sqlite3_finalize(s);if(rc==SQLITE_DONE)return 0;if(rc!=SQLITE_ROW)return fail(c,"DATABASE_ERROR");
 return bind_owned_created(c,p,entry->definition_id,version,entry->rarity,instance);
}

/* Native Creator coordinators call this only after checking the complete saved
 * project projection. Imported/shared settings keep creator.import semantics. */
static int creator_finish(od_core *c,const char *p,const char *a,char **out,int full_allowed) {
 char *library=NULL;int imported=creator_import(c,p,a,&library,full_allowed);if(imported<0)return -1;
 sqlite3_free(library);library=NULL;
 char *definition=query(c,"SELECT json_extract(:a,'$.definition.definition_id')",p,a,NULL);
 if(!definition)return -1;
 int64_t instance=0,exists=0,version=0,category=0;
 if(scalar(c,"SELECT count(*) FROM creator_collection WHERE profile=:p AND definition_id=:id",p,NULL,definition,&exists)<0)goto bad;
 if(scalar(c,"SELECT version FROM created_active WHERE profile=:p AND definition_id=:id",p,NULL,definition,&version)<0)goto bad;
 if(exists){
  if(scalar(c,"SELECT instance_id FROM creator_collection WHERE profile=:p AND definition_id=:id",p,NULL,definition,&instance)<0)goto bad;
 }else{
  if(writeq(c,"INSERT INTO owned_cards(profile,master_id) SELECT :p,master_id FROM created_definitions WHERE profile=:p AND definition_id=:id AND version=json_extract(:a,'$.definition.version')",p,a,definition)<0||sqlite3_changes(c->db)!=1)goto bad;
  instance=sqlite3_last_insert_rowid(c->db);
  if(scalar(c,"SELECT rarity FROM created_definitions WHERE profile=:p AND definition_id=:id AND version=json_extract(:a,'$.definition.version')",p,a,definition,&category)<0)goto bad;
  if(bind_owned_created(c,p,definition,version,(od_summon_rarity)category,instance)<0)goto bad;
  sqlite3_stmt *q=prepare(c,"INSERT INTO creator_collection VALUES(:p,:id,?4,?5)",p,NULL,definition);if(!q)goto bad;
  sqlite3_bind_int64(q,4,instance);sqlite3_bind_int64(q,5,version);int rc=sqlite3_step(q);sqlite3_finalize(q);if(rc!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto bad;}
 }
 library=creator_library(c,p);if(!library)goto bad;
 sqlite3_stmt *q=prepare(c,"SELECT json_object('instance_id',?4,'definition_id',:id,'version',?5,'newly_owned',json(CASE WHEN ?6 THEN 'true' ELSE 'false' END),'available',json(CASE WHEN NOT EXISTS(SELECT 1 FROM owned_consumptions WHERE instance_id=?4) THEN 'true' ELSE 'false' END),'library',json(:a))",p,library,definition);
 if(!q)goto bad;
 sqlite3_bind_int64(q,4,instance);sqlite3_bind_int64(q,5,version);sqlite3_bind_int(q,6,!exists);
 if(sqlite3_step(q)==SQLITE_ROW){*out=sqlite3_mprintf("%s",sqlite3_column_text(q,0));}
 sqlite3_finalize(q);
 if(!*out){fail(c,"NO_MEMORY");goto bad;}
 sqlite3_free(definition);sqlite3_free(library);return imported&&exists?1:0;
 bad:sqlite3_free(definition);sqlite3_free(library);return -1;
}

static int banner_configure(od_core *c,const char *p,const char *a) {
 char *id=query(c,"SELECT CASE WHEN json_type(:a,'$.banner_id')='text' THEN json_extract(:a,'$.banner_id') END",p,a,NULL);if(!identifier(id)){sqlite3_free(id);return fail(c,"INVALID_ARGUMENT");}
 stored_banner next,old;if(banner_parse(c,a,&next)<0){sqlite3_free(id);return -1;}memset(&old,0,sizeof(old));
 int64_t exists=0;if(scalar(c,"SELECT count(*) FROM banner_active WHERE profile=:p AND banner_id=:id",p,NULL,id,&exists)<0)goto bad;
 if(exists){
  if(banner_load(c,c->db,p,id,0,&old)<0)goto bad;
  if(next.version<=old.version){
   if(next.version<old.version){fail(c,"BANNER_VERSION_STALE");goto bad;}
   sqlite3_stmt *s=prepare(c,"SELECT od_json_equal(config,:a) FROM banner_versions WHERE profile=:p AND banner_id=:id AND version=?4",p,a,id);if(!s)goto bad;sqlite3_bind_int64(s,4,(sqlite3_int64)next.version);int same=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);if(!same){fail(c,"BANNER_VERSION_CONFLICT");goto bad;}banner_free(&next);banner_free(&old);sqlite3_free(id);return 1;
  }
  int main_changed=strcmp(next.main_id,old.main_id)!=0;
  if((main_changed&&next.epoch<=old.epoch)||(!main_changed&&next.epoch!=old.epoch)){fail(c,"BANNER_EPOCH_CONFLICT");goto bad;}
 }
 for(size_t i=0;i<next.count;i++){
  if(!strncmp(next.entries[i].definition_id,"tournament-exclusive:",21)||od_schedule_store_is_exclusive_id(c->db,p,next.entries[i].definition_id)!=0){fail(c,"TOURNAMENT_EXCLUSIVE_NOT_SUMMONABLE");goto bad;}
  sqlite3_stmt *s=prepare(c,"SELECT 1 FROM banner_entries WHERE profile=:p AND definition_id=:id AND (master_id!=?4 OR rarity!=?5) LIMIT 1",p,NULL,next.entries[i].definition_id);if(!s)goto bad;sqlite3_bind_int64(s,4,next.masters[i]);sqlite3_bind_int(s,5,next.entries[i].rarity);int conflict=sqlite3_step(s)==SQLITE_ROW;sqlite3_finalize(s);if(conflict){fail(c,"DEFINITION_CONFLICT");goto bad;}
 }
 sqlite3_stmt *s=prepare(c,"INSERT INTO banner_versions VALUES(:p,:id,json_extract(:a,'$.version'),json_extract(:a,'$.epoch'),json_extract(:a,'$.main_id'),json_extract(:a,'$.policy.multi_count'),json_extract(:a,'$.policy.lr_ppm'),json_extract(:a,'$.policy.slr_ppm'),json_extract(:a,'$.policy.gr_ppm'),json(:a))",p,a,id);if(!s)goto bad;int rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto bad;}
 for(size_t i=0;i<next.count;i++){
  s=prepare(c,"INSERT INTO banner_entries VALUES(:p,:id,?4,?5,?6,?7,?8,?9)",p,NULL,id);if(!s)goto bad;sqlite3_bind_int64(s,4,(sqlite3_int64)next.version);sqlite3_bind_int64(s,5,(sqlite3_int64)i);sqlite3_bind_text(s,6,next.entries[i].definition_id,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,7,next.masters[i]);sqlite3_bind_int(s,8,next.entries[i].rarity);sqlite3_bind_int64(s,9,next.entries[i].weight_ppm);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto bad;}
 }
 if(banner_bind_created(c,p,id,a)<0)goto bad;
 if(writeq(c,"INSERT INTO banner_active VALUES(:p,:id,json_extract(:a,'$.version')) ON CONFLICT(profile,banner_id) DO UPDATE SET version=excluded.version",p,a,id)<0||writeq(c,"INSERT INTO banner_pity VALUES(:p,:id,json_extract(:a,'$.epoch'),0) ON CONFLICT(profile,banner_id) DO UPDATE SET epoch=excluded.epoch,misses=CASE WHEN banner_pity.epoch=excluded.epoch THEN banner_pity.misses ELSE 0 END",p,a,id)<0)goto bad;
 banner_free(&next);banner_free(&old);sqlite3_free(id);return 0;
bad:banner_free(&next);banner_free(&old);sqlite3_free(id);return -1;
}
static int summon_draw(od_core *c,const char *p,const char *a,char **out) {
 char *id=query(c,"SELECT CASE WHEN json_type(:a,'$.banner_id')='text' THEN json_extract(:a,'$.banner_id') END",p,a,NULL);char *kind=query(c,"SELECT CASE WHEN json_type(:a,'$.kind')='text' THEN json_extract(:a,'$.kind') END",p,a,NULL);
 if(!identifier(id)||!kind||(strcmp(kind,"single")&&strcmp(kind,"multi"))){sqlite3_free(id);sqlite3_free(kind);return fail(c,"INVALID_ARGUMENT");}
 int64_t count=0;if(scalar(c,"SELECT count(*) FROM json_each(:a) WHERE key NOT IN('banner_id','kind')",p,a,NULL,&count)<0||count){sqlite3_free(id);sqlite3_free(kind);return fail(c,"INVALID_ARGUMENT");}
 stored_banner b;if(banner_load(c,c->db,p,id,0,&b)<0){sqlite3_free(id);sqlite3_free(kind);return -1;}
 int64_t stale=0;
 if(scalar(c,"SELECT EXISTS(SELECT 1 FROM banner_definitions b JOIN banner_active v ON v.profile=b.profile AND v.banner_id=b.banner_id AND v.version=b.banner_version JOIN created_active a USING(profile,definition_id) WHERE b.profile=:p AND b.banner_id=:id AND b.definition_version!=a.version) OR EXISTS(SELECT 1 FROM banner_entries e JOIN banner_active v USING(profile,banner_id,version) JOIN created_active a USING(profile,definition_id) WHERE e.profile=:p AND e.banner_id=:id AND NOT EXISTS(SELECT 1 FROM banner_definitions b WHERE b.profile=e.profile AND b.banner_id=e.banner_id AND b.banner_version=e.version AND b.definition_id=e.definition_id))",p,NULL,id,&stale)<0)goto bad;
 if(!stale&&scalar(c,"SELECT EXISTS(SELECT 1 FROM banner_active a JOIN banner_versions v USING(profile,banner_id,version) WHERE a.profile=:p AND a.banner_id=:id AND EXISTS(SELECT 1 FROM banner_definitions b WHERE b.profile=a.profile AND b.banner_id=a.banner_id AND b.banner_version=a.version) AND NOT EXISTS(SELECT 1 FROM creator_state s WHERE s.profile=a.profile AND s.epoch=json_extract(v.config,'$.creator_epoch') AND s.main_id=v.main_id))",p,NULL,id,&stale)<0)goto bad;
 if(stale){fail(c,"CREATED_BANNER_STALE");goto bad;}
 int64_t stones=0;if(scalar(c,"SELECT COALESCE((SELECT quantity FROM inventory WHERE profile=:p AND kind='stone' AND item_id=0),0)",p,NULL,NULL,&stones)<0)goto bad;
 od_summon_plan plan;od_summon_status status=od_summon_make_plan(b.entries,b.count,&b.policy,b.main_id,b.epoch,b.pity,!strcmp(kind,"single")?OD_SUMMON_SINGLE:OD_SUMMON_MULTI,(uint64_t)stones,secure_random,NULL,&plan);
 if(status!=OD_SUMMON_OK){fail(c,status==OD_SUMMON_INSUFFICIENT_STONES?"INSUFFICIENT_STONES":od_summon_status_name(status));goto bad;}
 sqlite3_stmt *s=prepare(c,"UPDATE inventory SET quantity=quantity-?2 WHERE profile=:p AND kind='stone' AND item_id=0 AND quantity>=?2",p,NULL,NULL);if(!s)goto bad;sqlite3_bind_int64(s,2,(sqlite3_int64)plan.stone_cost);int rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE||sqlite3_changes(c->db)!=1){fail(c,"INSUFFICIENT_STONES");goto bad;}
 char *draws=sqlite3_mprintf("[]");if(!draws){fail(c,"NO_MEMORY");goto bad;}
 for(unsigned i=0;i<plan.count;i++){
  size_t index=plan.pool_indexes[i];s=prepare(c,"INSERT INTO owned_cards(profile,master_id) VALUES(:p,?2)",p,NULL,NULL);if(!s){sqlite3_free(draws);goto bad;}sqlite3_bind_int64(s,2,b.masters[index]);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE){sqlite3_free(draws);fail(c,"DATABASE_ERROR");goto bad;}sqlite3_int64 instance=sqlite3_last_insert_rowid(c->db);
  if(grant_created(c,p,id,b.version,&b.entries[index],instance)<0){sqlite3_free(draws);goto bad;}
  s=prepare(c,"INSERT INTO card_sources(profile,banner_id,instance_id,version,definition_id) VALUES(:p,:id,?4,?5,?6)",p,NULL,id);if(!s){sqlite3_free(draws);goto bad;}sqlite3_bind_int64(s,4,instance);sqlite3_bind_int64(s,5,(sqlite3_int64)b.version);sqlite3_bind_text(s,6,b.entries[index].definition_id,-1,SQLITE_TRANSIENT);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE){sqlite3_free(draws);fail(c,"DATABASE_ERROR");goto bad;}
  s=prepare(c,"SELECT json_insert(:a,'$[#]',json_object('definition_id',:id,'instance_id',?4,'master_id',?5))",p,draws,b.entries[index].definition_id);if(!s){sqlite3_free(draws);goto bad;}sqlite3_bind_int64(s,4,instance);sqlite3_bind_int64(s,5,b.masters[index]);char *next=sqlite3_step(s)==SQLITE_ROW?sqlite3_mprintf("%s",sqlite3_column_text(s,0)):NULL;sqlite3_finalize(s);sqlite3_free(draws);draws=next;if(!draws){fail(c,"NO_MEMORY");goto bad;}
 }
 s=prepare(c,"UPDATE banner_pity SET epoch=?4,misses=?5 WHERE profile=:p AND banner_id=:id",p,NULL,id);if(!s){sqlite3_free(draws);goto bad;}sqlite3_bind_int64(s,4,(sqlite3_int64)plan.next_pity.epoch);sqlite3_bind_int64(s,5,plan.next_pity.misses);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE){sqlite3_free(draws);fail(c,"DATABASE_ERROR");goto bad;}
 char *state=snapshot(c,p);if(!state){sqlite3_free(draws);goto bad;}
 s=prepare(c,"SELECT json_set(json(:a),'$.summon',json_object('banner_id',:id,'version',?4,'epoch',?5,'kind',?6,'stone_cost',?7,'draws',json(?8),'pity_misses',?9,'guaranteed',?10,'main_feature_pulled',?11))",p,state,id);sqlite3_free(state);if(!s){sqlite3_free(draws);goto bad;}
 sqlite3_bind_int64(s,4,(sqlite3_int64)b.version);sqlite3_bind_int64(s,5,(sqlite3_int64)b.epoch);sqlite3_bind_text(s,6,kind,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,7,(sqlite3_int64)plan.stone_cost);sqlite3_bind_text(s,8,draws,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,9,plan.next_pity.misses);sqlite3_bind_int(s,10,plan.guaranteed);sqlite3_bind_int(s,11,plan.main_feature_pulled);*out=sqlite3_step(s)==SQLITE_ROW?sqlite3_mprintf("%s",sqlite3_column_text(s,0)):NULL;sqlite3_finalize(s);sqlite3_free(draws);
 banner_free(&b);sqlite3_free(id);sqlite3_free(kind);return *out?0:fail(c,"NO_MEMORY");
bad:banner_free(&b);sqlite3_free(id);sqlite3_free(kind);return -1;
}

/* Official modifications never enter Creator sharing/catalog tables. */
static int table_present(sqlite3 *db,const char *name) {
 sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,"SELECT 1 FROM sqlite_schema WHERE type='table' AND name=?1",-1,&s,NULL)!=SQLITE_OK)return 0;sqlite3_bind_text(s,1,name,-1,SQLITE_STATIC);int yes=sqlite3_step(s)==SQLITE_ROW;sqlite3_finalize(s);return yes;
}
static int official_status(od_core *c,int64_t master,od_upgrade_target *target) {
 memset(target,0,sizeof(*target));target->official_definition=1;sqlite3_stmt *s=NULL;
 const char *q="SELECT COALESCE(c.optimal_awakening_grow_type,0),EXISTS(SELECT 1 FROM card_awakening_routes r WHERE (r.card_id=c.id OR r.card_id=(c.id/10)*10+1) AND r.type='CardAwakeningRoute::Optimal' AND (r.optimal_awakening_step=1 OR r.optimal_awakening_step=8 OR r.optimal_awakening_type=2)),EXISTS(SELECT 1 FROM card_awakening_routes r WHERE (r.card_id=c.id OR r.card_id=(c.id/10)*10+1) AND r.type='CardAwakeningRoute::Optimal' AND (r.optimal_awakening_step=8 OR r.optimal_awakening_type=2)),EXISTS(SELECT 1 FROM optimal_awakening_growths g WHERE g.optimal_awakening_grow_type=c.optimal_awakening_grow_type AND g.step=8) FROM cards c WHERE c.id=?1";
 if(sqlite3_prepare_v2(c->master,q,-1,&s,NULL)!=SQLITE_OK)return fail(c,"MASTER_AWAKENING_SCHEMA_UNSUPPORTED");
  sqlite3_bind_int64(s,1,master);
 int rc=sqlite3_step(s);if(rc==SQLITE_ROW){target->official_eza=sqlite3_column_int64(s,0)>0||sqlite3_column_int(s,1);target->official_super_eza=sqlite3_column_int(s,2)||sqlite3_column_int(s,3);if(target->official_super_eza)target->official_eza=1;}sqlite3_finalize(s);return rc==SQLITE_ROW?0:fail(c,"CARD_NOT_FOUND");
}
static int upgrade_kind(const char *text){return text&&!strcmp(text,"custom_eza")?OD_UPGRADE_CUSTOM_EZA:text&&!strcmp(text,"custom_super_eza")?OD_UPGRADE_CUSTOM_SUPER_EZA:text&&!strcmp(text,"enhanced")?OD_UPGRADE_ENHANCE:0;}
static char *official_proxy(od_core *c,const char *d) {
 char *r=query(c,"SELECT json_object('format','offline-dokkan-definition','schema_version',1,'definition_id','official:'||json_extract(:a,'$.source.master_id'),'version',json_extract(:a,'$.version'),'source',json_extract(:a,'$.source'),'rarity',CASE json_extract(:a,'$.card.rarity') WHEN 4 THEN 'UR' ELSE 'LR' END,'fully_awakened',json('true'),'card',json_extract(:a,'$.card'),'tables',json_extract(:a,'$.tables'),'progression_policy',json_extract(:a,'$.progression_policy'),'stat_policy',json_extract(:a,'$.stat_policy'))",NULL,d,NULL);if(!r)return NULL;
 char *clean=query(c,"SELECT CASE WHEN json_type(:a,'$.progression_policy')='null' THEN json_remove(:a,'$.progression_policy') ELSE :a END",NULL,r,NULL);sqlite3_free(r);if(!clean)return NULL;r=query(c,"SELECT CASE WHEN json_type(:a,'$.stat_policy')='null' THEN json_remove(:a,'$.stat_policy') ELSE :a END",NULL,clean,NULL);sqlite3_free(clean);return r;
}
static int official_validate(od_core *c,const char *d) {
 int64_t valid=0,version=0,master=0;
 if(scalar(c,"SELECT CASE WHEN json_valid(:a) THEN json_type(:a)='object' AND json_extract(:a,'$.format')='offline-dokkan-official-upgrade' AND json_type(:a,'$.schema_version')='integer' AND json_extract(:a,'$.schema_version')=1 AND NOT EXISTS(SELECT 1 FROM json_tree(:a) WHERE type='text' AND instr(atom,char(0))>0 OR instr(key,char(0))>0) AND NOT EXISTS(SELECT 1 FROM json_tree(:a) WHERE type='object' AND (SELECT count(*) FROM json_each(json_tree.value))!=(SELECT count(DISTINCT key) FROM json_each(json_tree.value))) AND NOT EXISTS(SELECT 1 FROM json_each(:a) WHERE key NOT IN('format','schema_version','version','source','kind','policy_id','policy_version','card','tables','progression_policy','stat_policy')) ELSE 0 END",NULL,d,NULL,&valid)<0||!valid)return fail(c,"INVALID_OFFICIAL_UPGRADE");
 char *kind=query(c,"SELECT json_extract(:a,'$.kind')",NULL,d,NULL);int k=upgrade_kind(kind);sqlite3_free(kind);if(!k||integer_arg(c,d,"$.version",1,OD_LIMIT,&version)<0||integer_arg(c,d,"$.source.master_id",1,OD_LIMIT,&master)<0)return fail(c,"INVALID_OFFICIAL_UPGRADE");
 if(k==OD_UPGRADE_ENHANCE){char *id=query(c,"SELECT CASE WHEN json_type(:a,'$.policy_id')='text' THEN json_extract(:a,'$.policy_id') END",NULL,d,NULL);int good=identifier(id)&&integer_arg(c,d,"$.policy_version",1,OD_LIMIT,&version)==0;sqlite3_free(id);if(!good)return fail(c,"GENERATED_POLICY_REQUIRED");}
 else if(scalar(c,"SELECT json_type(:a,'$.policy_id') IS NOT NULL OR json_type(:a,'$.policy_version') IS NOT NULL",NULL,d,NULL,&valid)<0||valid)return fail(c,"INVALID_OFFICIAL_UPGRADE");
 char *proxy=official_proxy(c,d);if(!proxy)return -1;int rc=definition_validate_ex(c,proxy,1,0);sqlite3_free(proxy);if(rc<0)return -1;
 /* Card identity/art/resource fields stay bound to the official source. */
 sqlite3_stmt *s=prepare(c,"SELECT key,value,type FROM json_each(:a,'$.card')",NULL,d,NULL);if(!s)return -1;int step;
 while((step=sqlite3_step(s))==SQLITE_ROW){
  const char *key=(const char *)sqlite3_column_text(s,0);int mutable=!strcmp(key,"lv_max")||!strcmp(key,"skill_lv_max")||!strcmp(key,"leader_skill_set_id")||!strcmp(key,"passive_skill_set_id")||!strcmp(key,"optimal_awakening_grow_type")||!strcmp(key,"exp_type");
  if(k==OD_UPGRADE_ENHANCE&&(!strcmp(key,"hp_init")||!strcmp(key,"hp_max")||!strcmp(key,"atk_init")||!strcmp(key,"atk_max")||!strcmp(key,"def_init")||!strcmp(key,"def_max")))mutable=1;
  if(mutable)continue;
  char *q=sqlite3_mprintf("SELECT \"%w\" FROM cards WHERE id=?1",key);sqlite3_stmt *m=NULL;int good=q&&sqlite3_prepare_v2(c->master,q,-1,&m,NULL)==SQLITE_OK;sqlite3_free(q);
  if(good){sqlite3_bind_int64(m,1,master);int mr=sqlite3_step(m),type=sqlite3_column_type(m,0),input=sqlite3_column_type(s,1);int numeric=(type==SQLITE_INTEGER||type==SQLITE_FLOAT)&&(input==SQLITE_INTEGER||input==SQLITE_FLOAT);good=mr==SQLITE_ROW&&(type==input||numeric);if(good){if(type==SQLITE_INTEGER&&input==SQLITE_INTEGER)good=sqlite3_column_int64(m,0)==sqlite3_column_int64(s,1);else if(numeric)good=sqlite3_column_double(m,0)==sqlite3_column_double(s,1);else if(type==SQLITE_TEXT)good=sqlite3_column_bytes(m,0)==sqlite3_column_bytes(s,1)&&!memcmp(sqlite3_column_text(m,0),sqlite3_column_text(s,1),(size_t)sqlite3_column_bytes(m,0));}}
  sqlite3_finalize(m);if(!good){sqlite3_finalize(s);return fail(c,"OFFICIAL_SOURCE_CONFLICT");}
 }
 sqlite3_finalize(s);if(step!=SQLITE_DONE)return fail(c,"INVALID_OFFICIAL_UPGRADE");
 if(k!=OD_UPGRADE_ENHANCE){
  int terminal=k==OD_UPGRADE_CUSTOM_EZA?7:8;
  sqlite3_stmt *q=prepare(c,"SELECT json_type(:a,'$.tables.optimal_awakening_growths')='array' AND json_array_length(:a,'$.tables.optimal_awakening_growths')=?4 AND (SELECT count(DISTINCT json_extract(value,'$.step')) FROM json_each(:a,'$.tables.optimal_awakening_growths'))=?4 AND NOT EXISTS(SELECT 1 FROM json_each(:a,'$.tables.optimal_awakening_growths') g WHERE json_type(g.value,'$.step')!='integer' OR json_extract(g.value,'$.step') NOT BETWEEN 1 AND ?4 OR json_extract(g.value,'$.optimal_awakening_grow_type')!=json_extract(:a,'$.card.optimal_awakening_grow_type') OR json_type(g.value,'$.lv_max')!='integer' OR json_extract(g.value,'$.lv_max')<1 OR json_type(g.value,'$.skill_lv_max')!='integer' OR json_extract(g.value,'$.skill_lv_max')<1 OR NOT EXISTS(SELECT 1 FROM json_each(:a,'$.tables.card_awakening_routes') r WHERE json_extract(r.value,'$.type')='CardAwakeningRoute::Optimal' AND json_extract(r.value,'$.card_id')=json_extract(:a,'$.source.master_id') AND json_extract(r.value,'$.awaked_card_id')=json_extract(:a,'$.source.master_id') AND json_extract(r.value,'$.optimal_awakening_step')=json_extract(g.value,'$.step') AND json_extract(r.value,'$.optimal_awakening_type')=CASE WHEN json_extract(g.value,'$.step')=8 THEN 2 ELSE 1 END)) AND EXISTS(SELECT 1 FROM json_each(:a,'$.tables.optimal_awakening_growths') g WHERE json_extract(g.value,'$.step')=?4 AND json_extract(g.value,'$.lv_max')=json_extract(:a,'$.card.lv_max') AND json_extract(g.value,'$.skill_lv_max')=json_extract(:a,'$.card.skill_lv_max') AND json_extract(g.value,'$.leader_skill_set_id')=json_extract(:a,'$.card.leader_skill_set_id') AND json_extract(g.value,'$.passive_skill_set_id')=json_extract(:a,'$.card.passive_skill_set_id'))",NULL,d,NULL);if(!q)return -1;sqlite3_bind_int(q,4,terminal);valid=sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_int(q,0);sqlite3_finalize(q);if(!valid)return fail(c,"INCOMPLETE_AWAKENING_GRAPH");
 }
 return 0;
}
static int mechanic_metadata(const char *key){return !strcmp(key,"id")||!strcmp(key,"name")||!strcmp(key,"description")||!strcmp(key,"itemized_description")||!strcmp(key,"created_at")||!strcmp(key,"updated_at")||!strcmp(key,"leader_skill_set_id");}
static char *mechanic_rows(od_core *c,const char *d,const char *table,int64_t fallback_set) {
 int passive=!strcmp(table,"passive_skills");int64_t set=fallback_set;sqlite3_stmt *s=NULL;char *rows=NULL;
 if(d){
  if(integer_arg(c,d,passive?"$.card.passive_skill_set_id":"$.card.leader_skill_set_id",-OD_LIMIT,OD_LIMIT,&set)<0)return NULL;
  const char *q=passive?"SELECT json_group_array(json(json_remove(p.value,'$.id','$.name','$.description','$.itemized_description','$.created_at','$.updated_at'))) FROM json_each(:a,'$.tables.passive_skills') p WHERE json_extract(p.value,'$.id') IN(SELECT json_extract(r.value,'$.passive_skill_id') FROM json_each(:a,'$.tables.passive_skill_set_relations') r WHERE json_extract(r.value,'$.passive_skill_set_id')=json_extract(:a,'$.card.passive_skill_set_id'))":"SELECT json_group_array(json(json_remove(p.value,'$.id','$.name','$.description','$.itemized_description','$.created_at','$.updated_at','$.leader_skill_set_id'))) FROM json_each(:a,'$.tables.leader_skills') p WHERE json_extract(p.value,'$.leader_skill_set_id')=json_extract(:a,'$.card.leader_skill_set_id')";
  rows=query(c,q,NULL,d,NULL);if(!rows)return NULL;if(strcmp(rows,"[]")||set<0)return rows;sqlite3_free(rows);rows=NULL;
 }
 sqlite3_str *builder=sqlite3_str_new(c->master);if(!builder)return NULL;sqlite3_str_appendall(builder,"SELECT json_object(");int count=0;
 if(sqlite3_prepare_v2(c->master,"SELECT name FROM pragma_table_info(?1) ORDER BY cid",-1,&s,NULL)!=SQLITE_OK){sqlite3_free(sqlite3_str_finish(builder));return NULL;}sqlite3_bind_text(s,1,table,-1,SQLITE_STATIC);int rc;
 while((rc=sqlite3_step(s))==SQLITE_ROW){const char *key=(const char *)sqlite3_column_text(s,0);if(mechanic_metadata(key))continue;sqlite3_str_appendf(builder,"%s%Q,p.\"%w\"",count++?",":"",key,key);}sqlite3_finalize(s);
 if(rc!=SQLITE_DONE||!count){sqlite3_free(sqlite3_str_finish(builder));return NULL;}
 sqlite3_str_appendall(builder,passive?") FROM passive_skills p JOIN passive_skill_set_relations r ON r.passive_skill_id=p.id WHERE r.passive_skill_set_id=?1":") FROM leader_skills p WHERE p.leader_skill_set_id=?1");char *q=sqlite3_str_finish(builder);if(!q)return NULL;
 if(sqlite3_prepare_v2(c->master,q,-1,&s,NULL)!=SQLITE_OK){sqlite3_free(q);return NULL;}sqlite3_free(q);sqlite3_bind_int64(s,1,set);rows=sqlite3_mprintf("[]");
 while((rc=sqlite3_step(s))==SQLITE_ROW){sqlite3_stmt *add=prepare(c,"SELECT json_insert(:a,'$[#]',json(:id))",NULL,rows,(const char *)sqlite3_column_text(s,0));if(!add){sqlite3_free(rows);rows=NULL;break;}char *next=sqlite3_step(add)==SQLITE_ROW?sqlite3_mprintf("%s",sqlite3_column_text(add,0)):NULL;sqlite3_finalize(add);sqlite3_free(rows);rows=next;if(!rows)break;}
 sqlite3_finalize(s);if(rc!=SQLITE_DONE){sqlite3_free(rows);rows=NULL;}return rows;
}
static int official_mechanics_changed(od_core *c,const char *p,int64_t master,const char *d) {
 sqlite3_stmt *s=prepare(c,"SELECT document FROM official_upgrade_active a JOIN official_upgrade_versions v USING(profile,master_id,version) WHERE a.profile=:p AND a.master_id=?4",p,NULL,NULL);if(!s)return -1;sqlite3_bind_int64(s,4,master);char *prior=sqlite3_step(s)==SQLITE_ROW?sqlite3_mprintf("%s",sqlite3_column_text(s,0)):NULL;sqlite3_finalize(s);
 int64_t baseline[5]={0},new_values[5]={0},sets[2]={0};const char *keys[]={"$.card.lv_max","$.card.skill_lv_max","$.card.hp_max","$.card.atk_max","$.card.def_max"};
 if(prior){for(int i=0;i<5;i++)if(integer_arg(c,prior,keys[i],1,INT32_MAX,&baseline[i])<0){sqlite3_free(prior);return -1;}}
 else{
  const char *q="SELECT COALESCE((SELECT lv_max FROM optimal_awakening_growths g WHERE g.optimal_awakening_grow_type=c.optimal_awakening_grow_type ORDER BY step DESC LIMIT 1),c.lv_max),COALESCE((SELECT skill_lv_max FROM optimal_awakening_growths g WHERE g.optimal_awakening_grow_type=c.optimal_awakening_grow_type ORDER BY step DESC LIMIT 1),c.skill_lv_max),c.hp_max,c.atk_max,c.def_max,COALESCE((SELECT passive_skill_set_id FROM optimal_awakening_growths g WHERE g.optimal_awakening_grow_type=c.optimal_awakening_grow_type ORDER BY step DESC LIMIT 1),c.passive_skill_set_id),COALESCE((SELECT leader_skill_set_id FROM optimal_awakening_growths g WHERE g.optimal_awakening_grow_type=c.optimal_awakening_grow_type ORDER BY step DESC LIMIT 1),c.leader_skill_set_id) FROM cards c WHERE id=?1";
  if(sqlite3_prepare_v2(c->master,q,-1,&s,NULL)!=SQLITE_OK)return fail(c,"MASTER_AWAKENING_SCHEMA_UNSUPPORTED");
  sqlite3_bind_int64(s,1,master);int rc=sqlite3_step(s);if(rc==SQLITE_ROW){for(int i=0;i<5;i++)baseline[i]=sqlite3_column_int64(s,i);sets[0]=sqlite3_column_int64(s,5);sets[1]=sqlite3_column_int64(s,6);}sqlite3_finalize(s);if(rc!=SQLITE_ROW)return fail(c,"CARD_NOT_FOUND");
 }
 int changed=0;for(int i=0;i<5;i++){if(integer_arg(c,d,keys[i],1,INT32_MAX,&new_values[i])<0){sqlite3_free(prior);return -1;}if(new_values[i]>baseline[i])changed=1;}
 const char *tables[]={"passive_skills","leader_skills"};
 for(int i=0;i<2&&!changed;i++){
  char *next=mechanic_rows(c,d,tables[i],0),*old=mechanic_rows(c,prior,tables[i],sets[i]);if(!next||!old){sqlite3_free(next);sqlite3_free(old);sqlite3_free(prior);return fail(c,"UPGRADE_MECHANICS_UNAVAILABLE");}
  int64_t different=0;const char *q="SELECT json_array_length(:a)!=json_array_length(:id) OR EXISTS(SELECT 1 FROM json_each(:a) n WHERE NOT EXISTS(SELECT 1 FROM json_each(:id) b WHERE NOT EXISTS(SELECT key,type,value FROM json_each(n.value) EXCEPT SELECT key,type,value FROM json_each(b.value)) AND NOT EXISTS(SELECT key,type,value FROM json_each(b.value) EXCEPT SELECT key,type,value FROM json_each(n.value)))) OR EXISTS(SELECT 1 FROM json_each(:id) b WHERE NOT EXISTS(SELECT 1 FROM json_each(:a) n WHERE NOT EXISTS(SELECT key,type,value FROM json_each(n.value) EXCEPT SELECT key,type,value FROM json_each(b.value)) AND NOT EXISTS(SELECT key,type,value FROM json_each(b.value) EXCEPT SELECT key,type,value FROM json_each(n.value))))";
  int rc=scalar(c,q,NULL,next,old,&different);sqlite3_free(next);sqlite3_free(old);if(rc<0){sqlite3_free(prior);return -1;}changed=different!=0;
 }
 sqlite3_free(prior);return changed?0:fail(c,"UPGRADE_HAS_NO_MECHANICAL_CHANGE");
}

static int official_target(od_core *c,const char *p,const char *a,int64_t *master,od_upgrade_target *target) {
 int64_t instance=0;if(integer_arg(c,a,"$.instance_id",1,OD_LIMIT,&instance)<0)return -1;
 sqlite3_stmt *s=prepare(c,"SELECT master_id,NOT EXISTS(SELECT 1 FROM owned_definitions WHERE instance_id=c.id) AND NOT EXISTS(SELECT 1 FROM tournament_exclusive_owned WHERE instance_id=c.id) FROM owned_cards c WHERE profile=:p AND id=json_extract(:a,'$.instance_id') AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=c.id)",p,a,NULL);if(!s)return -1;int rc=sqlite3_step(s),official=rc==SQLITE_ROW&&sqlite3_column_int(s,1);*master=rc==SQLITE_ROW?sqlite3_column_int64(s,0):0;sqlite3_finalize(s);if(!official)return fail(c,"OFFICIAL_OWNED_CARD_REQUIRED");
 if(official_status(c,*master,target)<0)return -1;
 s=prepare(c,"SELECT custom_eza,custom_super_eza,enhanced_policy_version FROM official_upgrade_active a JOIN official_upgrade_versions v USING(profile,master_id,version) WHERE a.profile=:p AND a.master_id=?4",p,NULL,NULL);if(!s)return -1;sqlite3_bind_int64(s,4,*master);if(sqlite3_step(s)==SQLITE_ROW){target->custom_eza=sqlite3_column_int(s,0);target->custom_super_eza=sqlite3_column_int(s,1);target->enhanced_policy_version=(uint64_t)sqlite3_column_int64(s,2);}sqlite3_finalize(s);return 0;
}
static int official_mutation(od_core *c,const char *op,const char *p,const char *a,char **out) {
 if(!strcmp(op,"upgrade.policy.install")){
  int64_t extras=0;if(scalar(c,"SELECT count(*) FROM json_each(:a) WHERE key!='definition'",p,a,NULL,&extras)<0||extras)return fail(c,"INVALID_ARGUMENT");
  char *d=query(c,"SELECT json_extract(:a,'$.definition')",p,a,NULL);if(!d)return -1;if(official_validate(c,d)<0){sqlite3_free(d);return -1;}
  int64_t enhanced=0;if(scalar(c,"SELECT json_extract(:a,'$.kind')='enhanced'",p,d,NULL,&enhanced)<0||!enhanced){sqlite3_free(d);return fail(c,"GENERATED_POLICY_REQUIRED");}
  int64_t exists=0;if(scalar(c,"SELECT count(*) FROM official_upgrade_policies WHERE profile=:p AND policy_id=json_extract(:a,'$.policy_id') AND policy_version=json_extract(:a,'$.policy_version') AND master_id=json_extract(:a,'$.source.master_id')",p,d,NULL,&exists)<0){sqlite3_free(d);return -1;}
  if(exists){int64_t same=0;if(scalar(c,"SELECT od_json_equal(document,:a) FROM official_upgrade_policies WHERE profile=:p AND policy_id=json_extract(:a,'$.policy_id') AND policy_version=json_extract(:a,'$.policy_version') AND master_id=json_extract(:a,'$.source.master_id')",p,d,NULL,&same)<0||!same){sqlite3_free(d);return fail(c,"GENERATED_POLICY_CONFLICT");}}
  else if(writeq(c,"INSERT INTO official_upgrade_policies VALUES(:p,json_extract(:a,'$.policy_id'),json_extract(:a,'$.policy_version'),json_extract(:a,'$.source.master_id'),json(:a))",p,d,NULL)<0){sqlite3_free(d);return -1;}
  sqlite3_free(d);*out=snapshot(c,p);return *out?(exists?1:0):-1;
 }
 int64_t master=0;od_upgrade_target target;if(official_target(c,p,a,&master,&target)<0)return -1;
 char *kind=query(c,"SELECT json_extract(:a,'$.kind')",p,a,NULL);int k=upgrade_kind(kind);sqlite3_free(kind);int editing=!strcmp(op,"upgrade.edit");
 int64_t unknown=0;if(scalar(c,editing?"SELECT count(*) FROM json_each(:a) WHERE key NOT IN('instance_id','kind','definition')":"SELECT count(*) FROM json_each(:a) WHERE key NOT IN('instance_id','kind','definition','policy_id','policy_version')",p,a,NULL,&unknown)<0||unknown||!k)return fail(c,"INVALID_ARGUMENT");
 if((editing&&k==OD_UPGRADE_ENHANCE)||(target.enhanced_policy_version&&(editing||k!=OD_UPGRADE_ENHANCE)))return fail(c,"MANUAL_EDIT_FORBIDDEN");
 int64_t in_use=0;
 sqlite3_stmt *s=prepare(c,"SELECT EXISTS(SELECT 1 FROM runs r,json_each(r.team_snapshot) j JOIN owned_cards o ON o.id=j.value WHERE r.profile=:p AND r.state='started' AND o.master_id=?4)",p,a,NULL);if(!s)return -1;sqlite3_bind_int64(s,4,master);in_use=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);if(in_use)return fail(c,"CARD_IN_USE");
 char *d=NULL;uint64_t policy=0;
 if(k==OD_UPGRADE_ENHANCE){
  int64_t pv=0,has_document=0;if(integer_arg(c,a,"$.policy_version",1,OD_LIMIT,&pv)<0||scalar(c,"SELECT json_type(:a,'$.definition') IS NOT NULL",p,a,NULL,&has_document)<0||has_document)return fail(c,"GENERATED_POLICY_REQUIRED");policy=(uint64_t)pv;
  s=prepare(c,"SELECT document FROM official_upgrade_policies WHERE profile=:p AND policy_id=json_extract(:a,'$.policy_id') AND policy_version=json_extract(:a,'$.policy_version') AND master_id=?4",p,a,NULL);if(!s)return -1;sqlite3_bind_int64(s,4,master);if(sqlite3_step(s)==SQLITE_ROW)d=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);if(!d)return fail(c,"GENERATED_POLICY_NOT_FOUND");
 }else d=query(c,"SELECT json_extract(:a,'$.definition')",p,a,NULL);
 if(!d)return fail(c,"INVALID_OFFICIAL_UPGRADE");
 if(official_validate(c,d)<0){sqlite3_free(d);return -1;}
 int64_t matches=0;s=prepare(c,"SELECT json_extract(:a,'$.source.master_id')=?4 AND CASE json_extract(:a,'$.kind') WHEN 'custom_eza' THEN 1 WHEN 'custom_super_eza' THEN 2 ELSE 3 END=?5",p,d,NULL);if(!s){sqlite3_free(d);return -1;}sqlite3_bind_int64(s,4,master);sqlite3_bind_int(s,5,k);matches=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);if(!matches){sqlite3_free(d);return fail(c,"OFFICIAL_SOURCE_CONFLICT");}
 sqlite3_stmt *caps=prepare(c,"SELECT EXISTS(SELECT 1 FROM owned_cards o WHERE o.profile=:p AND o.master_id=?4 AND NOT EXISTS(SELECT 1 FROM owned_definitions n WHERE n.instance_id=o.id) AND NOT EXISTS(SELECT 1 FROM tournament_exclusive_owned n WHERE n.instance_id=o.id) AND (o.level>json_extract(:a,'$.card.lv_max') OR o.sa_level>json_extract(:a,'$.card.skill_lv_max')))",p,d,NULL);if(!caps){sqlite3_free(d);return -1;}sqlite3_bind_int64(caps,4,master);int conflict=sqlite3_step(caps)==SQLITE_ROW&&sqlite3_column_int(caps,0);sqlite3_finalize(caps);if(conflict){sqlite3_free(d);return fail(c,"UPGRADE_PROGRESS_CONFLICT");}
 od_upgrade_plan plan;memset(&plan,0,sizeof(plan));int64_t stones=0;if(scalar(c,"SELECT COALESCE((SELECT quantity FROM inventory WHERE profile=:p AND kind='stone' AND item_id=0),0)",p,a,NULL,&stones)<0){sqlite3_free(d);return -1;}
 if(!editing&&k==OD_UPGRADE_CUSTOM_EZA&&target.custom_super_eza){sqlite3_free(d);return fail(c,"ALREADY_APPLIED");}
 if(!editing){od_progression_status status=od_upgrade_make_plan(&target,(od_upgrade_kind)k,policy,0,(uint64_t)stones,&plan);if(status!=OD_PROGRESSION_OK){sqlite3_free(d);return fail(c,od_progression_status_name(status));}}
 else {if((k==OD_UPGRADE_CUSTOM_EZA&&!target.custom_eza)||(k==OD_UPGRADE_CUSTOM_SUPER_EZA&&!target.custom_super_eza)){sqlite3_free(d);return fail(c,"UPGRADE_NOT_APPLIED");}plan.kind=(od_upgrade_kind)k;plan.custom_eza=target.custom_eza;plan.custom_super_eza=target.custom_super_eza;plan.enhanced_policy_version=target.enhanced_policy_version;}
 if(!editing&&official_mechanics_changed(c,p,master,d)<0){sqlite3_free(d);return -1;}
 if(k==OD_UPGRADE_CUSTOM_SUPER_EZA&&!target.official_eza)plan.custom_eza=1;
 int64_t stat_conflict=0;s=prepare(c,"SELECT EXISTS(SELECT 1 FROM official_upgrade_active a JOIN official_upgrade_versions v USING(profile,master_id,version) WHERE a.profile=:p AND a.master_id=?4 AND json_type(v.document,'$.stat_policy') IS NOT NULL AND json_extract(v.document,'$.stat_policy') IS NOT json_extract(:a,'$.stat_policy'))",p,d,NULL);if(!s){sqlite3_free(d);return -1;}sqlite3_bind_int64(s,4,master);stat_conflict=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);if(stat_conflict){sqlite3_free(d);return fail(c,"STAT_POLICY_CONFLICT");}
 int64_t prior=0,revision=0;s=prepare(c,"SELECT COALESCE(max(version),0) FROM official_upgrade_versions WHERE profile=:p AND master_id=?4",p,a,NULL);if(!s){sqlite3_free(d);return -1;}sqlite3_bind_int64(s,4,master);if(sqlite3_step(s)==SQLITE_ROW)prior=sqlite3_column_int64(s,0);sqlite3_finalize(s);if(prior>=OD_LIMIT){sqlite3_free(d);return fail(c,"REVISION_OVERFLOW");}revision=prior+1;
 if(editing){s=prepare(c,"SELECT kind,json_extract(document,'$.version'),od_json_equal(document,:a) FROM official_upgrade_versions WHERE profile=:p AND master_id=?4 AND version=?5",p,d,NULL);if(!s){sqlite3_free(d);return -1;}sqlite3_bind_int64(s,4,master);sqlite3_bind_int64(s,5,prior);int64_t dv=0;integer_arg(c,d,"$.version",1,OD_LIMIT,&dv);int ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0)==k&&dv>sqlite3_column_int64(s,1);sqlite3_finalize(s);if(!ok){sqlite3_free(d);return fail(c,"UPGRADE_VERSION_CONFLICT");}}
 if(plan.stone_cost){s=prepare(c,"UPDATE inventory SET quantity=quantity-?4 WHERE profile=:p AND kind='stone' AND item_id=0 AND quantity>=?4",p,a,NULL);if(!s){sqlite3_free(d);return -1;}sqlite3_bind_int64(s,4,(sqlite3_int64)plan.stone_cost);int rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE||sqlite3_changes(c->db)!=1){sqlite3_free(d);return fail(c,"INSUFFICIENT_STONES");}}
 s=prepare(c,"INSERT INTO official_upgrade_versions VALUES(:p,?4,?5,?6,?7,?8,?9,json(:a),?10)",p,d,NULL);if(!s){sqlite3_free(d);return -1;}sqlite3_bind_int64(s,4,master);sqlite3_bind_int64(s,5,revision);sqlite3_bind_int(s,6,k);sqlite3_bind_int(s,7,plan.custom_eza);sqlite3_bind_int(s,8,plan.custom_super_eza);sqlite3_bind_int64(s,9,(sqlite3_int64)plan.enhanced_policy_version);sqlite3_bind_int64(s,10,(sqlite3_int64)plan.stone_cost);int rc=sqlite3_step(s);sqlite3_finalize(s);
 if(rc!=SQLITE_DONE){sqlite3_free(d);return fail(c,"DATABASE_ERROR");}
 s=prepare(c,"INSERT INTO official_upgrade_active VALUES(:p,?4,?5) ON CONFLICT(profile,master_id) DO UPDATE SET version=excluded.version",p,a,NULL);if(!s){sqlite3_free(d);return -1;}sqlite3_bind_int64(s,4,master);sqlite3_bind_int64(s,5,revision);rc=sqlite3_step(s);sqlite3_finalize(s);sqlite3_free(d);if(rc!=SQLITE_DONE)return fail(c,"DATABASE_ERROR");
 if(!validate_progress(c,c->db))return fail(c,"UPGRADE_PROGRESS_CONFLICT");
 *out=snapshot(c,p);return *out?0:-1;
}

static char *effective_document(od_core *c,sqlite3 *db,int64_t instance) {
 const char *queries[]={
 "SELECT v.document FROM owned_definitions o JOIN created_definitions v USING(profile,definition_id,version) WHERE o.instance_id=?1",
 "SELECT v.document FROM tournament_exclusive_owned o JOIN tournament_exclusive_definitions v USING(profile,definition_id,version) WHERE o.instance_id=?1",
 "SELECT v.document FROM owned_cards c JOIN official_upgrade_active a ON a.profile=c.profile AND a.master_id=c.master_id JOIN official_upgrade_versions v USING(profile,master_id,version) WHERE c.id=?1 AND NOT EXISTS(SELECT 1 FROM owned_definitions o WHERE o.instance_id=c.id) AND NOT EXISTS(SELECT 1 FROM tournament_exclusive_owned o WHERE o.instance_id=c.id)"};
 const char *tables[]={"owned_definitions","tournament_exclusive_owned","official_upgrade_active"};
 for(int i=0;i<3;i++){
  if(!table_present(db,tables[i]))continue;
  sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,queries[i],-1,&s,NULL)!=SQLITE_OK){fail(c,"DATABASE_ERROR");return NULL;}sqlite3_bind_int64(s,1,instance);char *d=NULL;if(sqlite3_step(s)==SQLITE_ROW)d=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);if(d)return d;
 }
 return NULL;
}

typedef struct {int64_t *threshold;unsigned cap;int64_t current_level;int64_t instance;} experience_curve;
static void curve_free(experience_curve *v){free(v->threshold);memset(v,0,sizeof(*v));}
static int curve_load(od_core *c,sqlite3 *db,int64_t instance,experience_curve *v) {
 memset(v,0,sizeof(*v));v->instance=instance;sqlite3_stmt *s=NULL;
 const char *q="SELECT master_id,level FROM owned_cards WHERE id=?1";
 if(sqlite3_prepare_v2(db,q,-1,&s,NULL)!=SQLITE_OK)return fail(c,"DATABASE_ERROR");
 sqlite3_bind_int64(s,1,instance);if(sqlite3_step(s)!=SQLITE_ROW){sqlite3_finalize(s);return fail(c,"CARD_NOT_OWNED");}
 int64_t master=sqlite3_column_int64(s,0);v->current_level=sqlite3_column_int64(s,1);sqlite3_finalize(s);
 char *effective=effective_document(c,db,instance);int custom=effective!=NULL,inherit_type=1,extended=0;int64_t type=0,cap=0;
 if(custom){
  s=prepare(c,"SELECT json_extract(:a,'$.card.exp_type'),json_extract(:a,'$.card.lv_max'),COALESCE(json_extract(:a,'$.progression_policy')='creator-lr-extended-v1',0)",NULL,effective,NULL);sqlite3_free(effective);if(!s)return -1;
  if(sqlite3_step(s)!=SQLITE_ROW){sqlite3_finalize(s);return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");}inherit_type=sqlite3_column_type(s,0)==SQLITE_NULL;type=sqlite3_column_int64(s,0);cap=sqlite3_column_int64(s,1);extended=cap>150&&sqlite3_column_int(s,2);sqlite3_finalize(s);
 }
 if(custom&&inherit_type){
  /* Legacy settings-only documents may inherit their verified source EXP curve. */
  if(sqlite3_prepare_v2(c->master,"SELECT exp_type FROM cards WHERE id=?1",-1,&s,NULL)!=SQLITE_OK)return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");
  sqlite3_bind_int64(s,1,master);int rc=sqlite3_step(s);if(rc!=SQLITE_ROW||sqlite3_column_type(s,0)!=SQLITE_INTEGER){sqlite3_finalize(s);return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");}type=sqlite3_column_int64(s,0);sqlite3_finalize(s);
 }
 if(!custom){
  if(sqlite3_prepare_v2(c->master,"SELECT exp_type,lv_max FROM cards WHERE id=?1",-1,&s,NULL)!=SQLITE_OK)return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");
  sqlite3_bind_int64(s,1,master);
  int rc=sqlite3_step(s);if(rc!=SQLITE_ROW||sqlite3_column_type(s,0)!=SQLITE_INTEGER||sqlite3_column_type(s,1)!=SQLITE_INTEGER){sqlite3_finalize(s);return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");}type=sqlite3_column_int64(s,0);cap=sqlite3_column_int64(s,1);sqlite3_finalize(s);
 }
 if(custom&&cap>150&&!extended)return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");
 if(extended){if(cap>200)return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");type=25;}
 /* 10,000 is a bounded import budget, not a claim about an official level maximum. */
 if(type<0||cap<1||cap>10000||v->current_level<1||v->current_level>cap)return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");
 v->cap=(unsigned)cap;v->threshold=calloc((size_t)cap,sizeof(*v->threshold));if(!v->threshold)return fail(c,"NO_MEMORY");
 if(sqlite3_prepare_v2(c->master,"SELECT lv,exp_total FROM card_exps WHERE exp_type=?1 AND lv BETWEEN 1 AND ?2 ORDER BY lv",-1,&s,NULL)!=SQLITE_OK){curve_free(v);return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");}
 unsigned stored_cap=extended?150u:(unsigned)cap;
 sqlite3_bind_int64(s,1,type);sqlite3_bind_int64(s,2,stored_cap);unsigned n=0;int rc;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  int64_t level=sqlite3_column_int64(s,0),xp=sqlite3_column_int64(s,1);
  if(n>=v->cap||sqlite3_column_type(s,0)!=SQLITE_INTEGER||sqlite3_column_type(s,1)!=SQLITE_INTEGER||level!=(int64_t)n+1||xp<0||xp>OD_LIMIT||(n==0?xp!=0:xp<=v->threshold[n-1])){sqlite3_finalize(s);curve_free(v);return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");}v->threshold[n++]=xp;
 }
 sqlite3_finalize(s);if(rc!=SQLITE_DONE||n!=stored_cap){curve_free(v);return fail(c,"EXPERIENCE_CURVE_UNAVAILABLE");}
 if(extended){
  /* Existing Creator extendLevels policy: LR curve to150, rounded +3.5% steps to200. */
  int64_t step=v->threshold[149]-v->threshold[148];
  for(unsigned i=150;i<v->cap;i++){
   if(step>(OD_LIMIT-500)/1035){curve_free(v);return fail(c,"QUANTITY_OVERFLOW");}step=(step*1035+500)/1000;
   if(v->threshold[i-1]>OD_LIMIT-step){curve_free(v);return fail(c,"QUANTITY_OVERFLOW");}v->threshold[i]=v->threshold[i-1]+step;
  }
 }
 return 0;
}
static int card_progress_mutation(od_core *c,const char *op,const char *p,const char *a,char **out) {
 int64_t instance=0,owned=0;if(integer_arg(c,a,"$.instance_id",1,OD_LIMIT,&instance)<0)return -1;
 if(scalar(c,"SELECT EXISTS(SELECT 1 FROM owned_cards WHERE id=json_extract(:a,'$.instance_id') AND profile=:p AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=owned_cards.id))",p,a,NULL,&owned)<0||!owned)return fail(c,"CARD_NOT_OWNED");
 if(!strcmp(op,"card.lock")){
  int64_t valid=0;if(scalar(c,"SELECT json_type(:a,'$.locked') IN('true','false') AND NOT EXISTS(SELECT 1 FROM json_each(:a) WHERE key NOT IN('instance_id','locked'))",p,a,NULL,&valid)<0||!valid)return fail(c,"INVALID_ARGUMENT");
  if(writeq(c,"INSERT INTO owned_progress(instance_id,locked) VALUES(json_extract(:a,'$.instance_id'),json_extract(:a,'$.locked')) ON CONFLICT(instance_id) DO UPDATE SET locked=excluded.locked",p,a,NULL)<0)return -1;
  *out=snapshot(c,p);return *out?0:-1;
 }
 int64_t unknown=0;if(scalar(c,"SELECT count(*) FROM json_each(:a) WHERE key NOT IN('instance_id','source','quantity')",p,a,NULL,&unknown)<0||unknown)return fail(c,"INVALID_ARGUMENT");
 char *source=query(c,"SELECT CASE WHEN json_type(:a,'$.source')='text' THEN json_extract(:a,'$.source') END",p,a,NULL);int64_t amount=0;
 if(!identifier(source)||integer_arg(c,a,"$.quantity",1,OD_LIMIT,&amount)<0){sqlite3_free(source);return fail(c,"INVALID_ARGUMENT");}
 char *key=sqlite3_mprintf("xp:%s",source);sqlite3_free(source);if(!key)return fail(c,"NO_MEMORY");
 sqlite3_stmt *s=prepare(c,"SELECT od_json_equal(input,:a) FROM reward_sources WHERE profile=:p AND source=:id",p,a,key);if(!s){sqlite3_free(key);return -1;}int rc=sqlite3_step(s),same=rc==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);
 if(rc==SQLITE_ROW){sqlite3_free(key);if(!same)return fail(c,"REWARD_SOURCE_CONFLICT");*out=snapshot(c,p);return *out?1:-1;}
 int64_t in_use=0;if(scalar(c,"SELECT EXISTS(SELECT 1 FROM runs r,json_each(r.team_snapshot) j WHERE r.profile=:p AND r.state='started' AND j.value=json_extract(:a,'$.instance_id'))",p,a,NULL,&in_use)<0||in_use){sqlite3_free(key);return fail(c,"CARD_IN_USE");}
 experience_curve v;if(curve_load(c,c->db,instance,&v)<0){sqlite3_free(key);return -1;}
 int64_t old=v.threshold[v.current_level-1],value=0;
 s=prepare(c,"SELECT experience FROM owned_progress WHERE instance_id=json_extract(:a,'$.instance_id')",p,a,NULL);if(!s){curve_free(&v);sqlite3_free(key);return -1;}rc=sqlite3_step(s);if(rc==SQLITE_ROW&&sqlite3_column_type(s,0)!=SQLITE_NULL)old=sqlite3_column_int64(s,0);sqlite3_finalize(s);
 if(old>OD_LIMIT-amount){curve_free(&v);sqlite3_free(key);return fail(c,"QUANTITY_OVERFLOW");}value=old+amount;
 /* Trusted evaluator must resolve capped earnings before calling; never silently discard XP. */
 if(value>v.threshold[v.cap-1]){curve_free(&v);sqlite3_free(key);return fail(c,"EXPERIENCE_CAP_EXCEEDED");}
 unsigned level=1;while(level<v.cap&&value>=v.threshold[level])level++;
 s=prepare(c,"INSERT INTO owned_progress(instance_id,experience) VALUES(json_extract(:a,'$.instance_id'),?4) ON CONFLICT(instance_id) DO UPDATE SET experience=excluded.experience",p,a,NULL);if(!s){curve_free(&v);sqlite3_free(key);return -1;}sqlite3_bind_int64(s,4,value);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE){curve_free(&v);sqlite3_free(key);return fail(c,"DATABASE_ERROR");}
 s=prepare(c,"UPDATE owned_cards SET level=?4 WHERE profile=:p AND id=json_extract(:a,'$.instance_id')",p,a,NULL);if(!s){curve_free(&v);sqlite3_free(key);return -1;}sqlite3_bind_int64(s,4,level);rc=sqlite3_step(s);sqlite3_finalize(s);curve_free(&v);if(rc!=SQLITE_DONE){sqlite3_free(key);return fail(c,"DATABASE_ERROR");}
 int result=writeq(c,"INSERT INTO reward_sources VALUES(:p,:id,json(:a))",p,a,key);sqlite3_free(key);if(result<0)return -1;*out=snapshot(c,p);return *out?0:-1;
}
static int validate_progress(od_core *c,sqlite3 *db) {
 sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,"SELECT p.instance_id,p.experience,c.level FROM owned_progress p JOIN owned_cards c ON c.id=p.instance_id WHERE p.experience IS NOT NULL",-1,&s,NULL)!=SQLITE_OK)return 0;int rc,ok=1;
 while((rc=sqlite3_step(s))==SQLITE_ROW){experience_curve v;if(curve_load(c,db,sqlite3_column_int64(s,0),&v)<0){ok=0;break;}int64_t xp=sqlite3_column_int64(s,1),level=sqlite3_column_int64(s,2);ok=xp>=v.threshold[level-1]&&(level==(int64_t)v.cap?xp==v.threshold[v.cap-1]:xp<v.threshold[level]);curve_free(&v);if(!ok)break;}
 sqlite3_finalize(s);return ok&&rc==SQLITE_DONE;
}
static int seed_new_owned_progress(od_core *c) {
 sqlite3_stmt *s=NULL;
 /* Missing curves remain explicitly unknown for legacy/synthetic masters.
  * A declared but malformed curve rejects a new grant instead of guessing. */
 int has_curves=table_present(c->master,"card_exps");
 if(!has_curves)return sql(c,"DELETE FROM temp._od_new_owned_progress");
 if(sqlite3_prepare_v2(c->db,"SELECT instance_id FROM temp._od_new_owned_progress ORDER BY instance_id",-1,&s,NULL)!=SQLITE_OK)return fail(c,"DATABASE_ERROR");
 int step,written=0;
 while((step=sqlite3_step(s))==SQLITE_ROW){
  sqlite3_int64 instance=sqlite3_column_int64(s,0);experience_curve curve;
  if(curve_load(c,c->db,instance,&curve)<0){sqlite3_finalize(s);return -1;}
  if(curve.current_level!=1){curve_free(&curve);sqlite3_finalize(s);return fail(c,"NEW_CARD_LEVEL_INVALID");}
  sqlite3_stmt *insert=NULL;
  if(sqlite3_prepare_v2(c->db,"INSERT INTO owned_progress(instance_id,experience) VALUES(?1,?2)",-1,&insert,NULL)!=SQLITE_OK){curve_free(&curve);sqlite3_finalize(s);return fail(c,"DATABASE_ERROR");}
  sqlite3_bind_int64(insert,1,instance);sqlite3_bind_int64(insert,2,curve.threshold[0]);
  int rc=sqlite3_step(insert);sqlite3_finalize(insert);curve_free(&curve);
  if(rc!=SQLITE_DONE){sqlite3_finalize(s);return fail(c,"DATABASE_ERROR");}
  written++;
 }
 sqlite3_finalize(s);
 if(step!=SQLITE_DONE||sql(c,"DELETE FROM temp._od_new_owned_progress")<0)return fail(c,"DATABASE_ERROR");
 return written?1:0;
}

static int kai_target_binding(void *opaque,sqlite3 *save,const char *profile,sqlite3_int64 instance,const char *historical,char **out,sqlite3_int64 *cap){
 od_core *c=opaque;*out=NULL;*cap=0;sqlite3_stmt *s=NULL;
 if(sqlite3_prepare_v2(save,"SELECT master_id FROM owned_cards WHERE profile=?1 AND id=?2",-1,&s,NULL)!=SQLITE_OK)return fail(c,"DATABASE_ERROR");
  sqlite3_bind_text(s,1,profile,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,2,instance);sqlite3_int64 master=sqlite3_step(s)==SQLITE_ROW?sqlite3_column_int64(s,0):0;sqlite3_finalize(s);if(!master)return fail(c,"CARD_NOT_OWNED");
 char *binding=NULL;
 if(historical)binding=sqlite3_mprintf("%s",historical);
 else{
  const char *q="SELECT json_object('binding_version',1,'channel','created','master_id',?3,'definition_id',definition_id,'version',version) FROM owned_definitions WHERE instance_id=?2 AND profile=?1 UNION ALL SELECT json_object('binding_version',1,'channel','tournament','master_id',?3,'definition_id',definition_id,'version',version) FROM tournament_exclusive_owned WHERE instance_id=?2 AND profile=?1 UNION ALL SELECT json_object('binding_version',1,'channel','official','master_id',?3,'definition_id',NULL,'version',version) FROM official_upgrade_active WHERE profile=?1 AND master_id=?3 UNION ALL SELECT json_object('binding_version',1,'channel','master','master_id',?3,'definition_id',NULL,'version',0) LIMIT 1";
  if(sqlite3_prepare_v2(save,q,-1,&s,NULL)!=SQLITE_OK)return fail(c,"DATABASE_ERROR");
  sqlite3_bind_text(s,1,profile,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,2,instance);sqlite3_bind_int64(s,3,master);if(sqlite3_step(s)==SQLITE_ROW)binding=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);
 }
 if(!binding)return fail(c,"NO_MEMORY");
 int64_t valid=0;
 if(scalar(c,"SELECT CASE WHEN json_valid(:a) THEN json_type(:a)='object' AND json_type(:a,'$.binding_version')='integer' AND json_extract(:a,'$.binding_version')=1 AND (SELECT count(*)=count(DISTINCT fullkey) FROM json_tree(:a)) AND NOT EXISTS(SELECT 1 FROM json_tree(:a) WHERE type='text' AND instr(atom,char(0))>0 OR instr(key,char(0))>0) AND NOT EXISTS(SELECT 1 FROM json_each(:a) WHERE key NOT IN('binding_version','channel','master_id','definition_id','version')) ELSE 0 END",NULL,binding,NULL,&valid)<0||!valid){sqlite3_free(binding);return fail(c,"KAI_TARGET_BINDING_INVALID");}
 char *channel=query(c,"SELECT CASE WHEN json_type(:a,'$.channel')='text' THEN json_extract(:a,'$.channel') END",NULL,binding,NULL),*id=query(c,"SELECT CASE WHEN json_type(:a,'$.definition_id')='text' THEN json_extract(:a,'$.definition_id') END",NULL,binding,NULL);int64_t source=0,version=0;
 if(!channel||integer_arg(c,binding,"$.master_id",1,OD_LIMIT,&source)<0||source!=master||integer_arg(c,binding,"$.version",0,OD_LIMIT,&version)<0){sqlite3_free(channel);sqlite3_free(id);sqlite3_free(binding);return fail(c,"KAI_TARGET_BINDING_INVALID");}
 int kind=!strcmp(channel,"master")?0:!strcmp(channel,"created")?1:!strcmp(channel,"tournament")?2:!strcmp(channel,"official")?3:-1;sqlite3_free(channel);
 const char *q=NULL;
 if(kind==0){
  if(version!=0||scalar(c,"SELECT json_type(:a,'$.definition_id')='null'",NULL,binding,NULL,&valid)<0||!valid)kind=-1;
  q="SELECT 1 FROM owned_cards c WHERE c.id=?1 AND c.profile=?2 AND NOT EXISTS(SELECT 1 FROM owned_definitions d WHERE d.instance_id=c.id) AND NOT EXISTS(SELECT 1 FROM tournament_exclusive_owned d WHERE d.instance_id=c.id)";
 }else if(kind==1)q="SELECT v.document FROM owned_definitions o JOIN created_definitions v ON v.profile=o.profile AND v.definition_id=o.definition_id WHERE o.instance_id=?1 AND o.profile=?2 AND o.definition_id=?4 AND v.version=?3 AND o.origin_version<=v.version AND o.version>=v.version";
 else if(kind==2)q="SELECT v.document FROM tournament_exclusive_owned o JOIN tournament_exclusive_definitions v USING(profile,definition_id,version) WHERE o.instance_id=?1 AND o.profile=?2 AND o.definition_id=?4 AND o.version=?3";
 else if(kind==3){
  if(version<1||scalar(c,"SELECT json_type(:a,'$.definition_id')='null'",NULL,binding,NULL,&valid)<0||!valid)kind=-1;
  q="SELECT v.document FROM owned_cards c JOIN official_upgrade_active a ON a.profile=c.profile AND a.master_id=c.master_id JOIN official_upgrade_versions v ON v.profile=a.profile AND v.master_id=a.master_id WHERE c.id=?1 AND c.profile=?2 AND v.version=?3 AND v.version<=a.version AND NOT EXISTS(SELECT 1 FROM owned_definitions d WHERE d.instance_id=c.id) AND NOT EXISTS(SELECT 1 FROM tournament_exclusive_owned d WHERE d.instance_id=c.id)";
 }
 if(kind<0||((kind==1||kind==2)&&(!identifier(id)||version<1))){sqlite3_free(id);sqlite3_free(binding);return fail(c,"KAI_TARGET_BINDING_INVALID");}
 if(sqlite3_prepare_v2(save,q,-1,&s,NULL)!=SQLITE_OK){sqlite3_free(id);sqlite3_free(binding);return fail(c,"DATABASE_ERROR");}sqlite3_bind_int64(s,1,instance);sqlite3_bind_text(s,2,profile,-1,SQLITE_TRANSIENT);if(kind){sqlite3_bind_int64(s,3,version);if(kind==1||kind==2)sqlite3_bind_text(s,4,id,-1,SQLITE_TRANSIENT);}sqlite3_free(id);
 int rc=sqlite3_step(s);char *document=rc==SQLITE_ROW&&kind?sqlite3_mprintf("%s",sqlite3_column_text(s,0)):NULL;sqlite3_finalize(s);if(rc!=SQLITE_ROW){sqlite3_free(binding);return fail(c,"KAI_TARGET_BINDING_INVALID");}
 if(kind){int64_t value=0;int ok=document&&integer_arg(c,document,"$.card.skill_lv_max",1,OD_LIMIT,&value)==0;sqlite3_free(document);if(!ok){sqlite3_free(binding);return fail(c,"KAI_TARGET_CAP_UNAVAILABLE");}*cap=value;}
 else{
  if(sqlite3_prepare_v2(c->master,"SELECT skill_lv_max FROM cards WHERE id=?1",-1,&s,NULL)!=SQLITE_OK){sqlite3_free(binding);return fail(c,"MASTER_SCHEMA_UNSUPPORTED");}sqlite3_bind_int64(s,1,master);int ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_INTEGER;sqlite3_int64 value=ok?sqlite3_column_int64(s,0):0;sqlite3_finalize(s);if(value<1||value>OD_LIMIT){sqlite3_free(binding);return fail(c,"KAI_TARGET_CAP_UNAVAILABLE");}*cap=value;
 }
 *out=binding;return 0;
}

typedef struct {od_core *core;const char *profile;} schedule_credit_context;
static int schedule_credit(void *opaque,const char *kind,sqlite3_int64 id,sqlite3_int64 quantity) {
 schedule_credit_context *context=opaque;od_core *c=context->core;const char *p=context->profile,*table=NULL;
 if(!kind||quantity<1||quantity>OD_LIMIT)return fail(c,"INVALID_REWARD");
 if(!strcmp(kind,"card")){
  /* One summon can grant at most the policy multi budget; this is not a reward multiplier. */
  if(quantity>OD_SUMMON_MAX_MULTI||!master_exists(c,"cards",id))return fail(c,"INVALID_REWARD");
  for(sqlite3_int64 i=0;i<quantity;i++){sqlite3_stmt *s=prepare(c,"INSERT INTO owned_cards(profile,master_id) VALUES(:p,?2)",p,NULL,NULL);if(!s)return -1;sqlite3_bind_int64(s,2,id);int rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE)return fail(c,"DATABASE_ERROR");}return 0;
 }
 if(!strcmp(kind,"stone")){if(id!=0)return fail(c,"INVALID_REWARD");}
 else if(!strcmp(kind,"medal"))table="awakening_items";
 else if(!strcmp(kind,"training"))table="training_items";
 else if(!strcmp(kind,"support"))table="support_items";
 else if(!strcmp(kind,"equipment"))table="equipment_skill_items";
 else if(!strcmp(kind,"act"))table="act_items";
 else return fail(c,"UNKNOWN_REWARD_KIND");
 if(id<0||(table&&!master_exists(c,table,id)))return fail(c,"INVALID_REWARD");
 sqlite3_stmt *s=prepare(c,"INSERT INTO inventory(profile,kind,item_id,quantity) VALUES(:p,:id,?4,?5) ON CONFLICT(profile,kind,item_id) DO UPDATE SET quantity=quantity+excluded.quantity WHERE quantity<=9007199254740991-excluded.quantity",p,NULL,kind);if(!s)return -1;sqlite3_bind_int64(s,4,id);sqlite3_bind_int64(s,5,quantity);int rc=sqlite3_step(s);sqlite3_finalize(s);return rc==SQLITE_DONE&&sqlite3_changes(c->db)==1?0:fail(c,"QUANTITY_OVERFLOW");
}

static int schedule_definition_validate(void *opaque,const char *d){schedule_credit_context *ctx=opaque;return definition_validate(ctx->core,d);}
static int schedule_definition_grant(void *opaque,const char *d,sqlite3_int64 *instance){
 schedule_credit_context *ctx=opaque;od_core *c=ctx->core;int64_t master=0;
 if(!instance||definition_validate(c,d)<0||integer_arg(c,d,"$.source.master_id",1,OD_LIMIT,&master)<0)return -1;
 sqlite3_stmt *s=prepare(c,"INSERT INTO owned_cards(profile,master_id) VALUES(:p,?2)",ctx->profile,NULL,NULL);if(!s)return -1;sqlite3_bind_int64(s,2,master);int rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE)return fail(c,"DATABASE_ERROR");*instance=sqlite3_last_insert_rowid(c->db);return 0;
}

/* 0: no source rank policy available (legacy synthetic/trusted masters);
 * 1: validated source capacity; -1: malformed declared source data. */
static int rank_one_capacity(od_core *c,int64_t *capacity) {
 sqlite3_stmt *s=NULL;
 if(sqlite3_prepare_v2(c->master,"SELECT 1 FROM sqlite_schema WHERE type='table' AND name='rank_statuses'",-1,&s,NULL)!=SQLITE_OK)return fail(c,"RANK_SOURCE_UNAVAILABLE");
 int rc=sqlite3_step(s);sqlite3_finalize(s);if(rc==SQLITE_DONE)return 0;if(rc!=SQLITE_ROW)return fail(c,"RANK_SOURCE_UNAVAILABLE");
 if(sqlite3_prepare_v2(c->master,"SELECT act_max,exp_total FROM rank_statuses WHERE rank=1",-1,&s,NULL)!=SQLITE_OK)return fail(c,"RANK_SOURCE_INVALID");
 rc=sqlite3_step(s);int valid=rc==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_INTEGER&&sqlite3_column_type(s,1)==SQLITE_INTEGER&&sqlite3_column_int64(s,0)>0&&sqlite3_column_int64(s,0)<=INT32_MAX&&sqlite3_column_int64(s,1)==0;
 if(valid)*capacity=sqlite3_column_int64(s,0);
 if(valid)valid=sqlite3_step(s)==SQLITE_DONE;
 sqlite3_finalize(s);return valid?1:fail(c,"RANK_SOURCE_INVALID");
}
static int player_progress_attach(od_core *c,const char *p,int64_t capacity,const int64_t *now) {
 sqlite3_stmt *s=prepare(c,"INSERT INTO player_progress VALUES(:p,1,0,?4,300,?5,'offline-rank1-act-v1')",p,NULL,NULL);if(!s)return -1;
 sqlite3_bind_int64(s,4,capacity);if(now)sqlite3_bind_int64(s,5,*now);else sqlite3_bind_null(s,5);
 int rc=sqlite3_step(s);sqlite3_finalize(s);return rc==SQLITE_DONE?0:fail(c,"DATABASE_ERROR");
}
static int profile_create(od_core *c,const char *p,const char *a,char **out) {
 int64_t explicit_stamina=0,stamina=0,capacity=0,clock_present=0,now=0;
 if(scalar(c,"SELECT json_type(:a,'$.initial_stamina') IS NOT NULL",p,a,NULL,&explicit_stamina)<0||scalar(c,"SELECT json_type(:a,'$.now_utc') IS NOT NULL",p,a,NULL,&clock_present)<0)return -1;
 if(explicit_stamina&&integer_arg(c,a,"$.initial_stamina",0,OD_LIMIT,&stamina)<0)return -1;
 if(clock_present&&integer_arg(c,a,"$.now_utc",0,INT64_C(253402300799),&now)<0)return -1;
 int supported=rank_one_capacity(c,&capacity);if(supported<0)return -1;
 if(!explicit_stamina&&supported)stamina=capacity;
 sqlite3_stmt *s=prepare(c,"INSERT INTO profiles(id,stamina) VALUES(:p,?4) ON CONFLICT DO NOTHING",p,NULL,NULL);if(!s)return -1;
 sqlite3_bind_int64(s,4,stamina);int rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE)return fail(c,"DATABASE_ERROR");
 int replay=sqlite3_changes(c->db)==0;
 if(!replay&&supported&&player_progress_attach(c,p,capacity,clock_present?&now:NULL)<0)return -1;
 if(!replay&&writeq(c,"INSERT INTO od_original_tutorial VALUES(:p,0,0,'original-tutorial-entry-v1')",p,NULL,NULL)<0)return -1;
 *out=snapshot(c,p);return *out?replay:-1;
}
/* Called inside the same mutation transaction as a clocked refresh/run entry.
 * Over-capacity legacy balances are retained. Backward clocks never grant ACT. */
static int profile_recover_act(od_core *c,const char *p,int64_t now) {
 sqlite3_stmt *s=prepare(c,"SELECT p.stamina,r.act_max,r.recovery_anchor FROM profiles p LEFT JOIN player_progress r ON r.profile=p.id WHERE p.id=:p",p,NULL,NULL);if(!s)return -1;
 int rc=sqlite3_step(s);if(rc!=SQLITE_ROW){sqlite3_finalize(s);return fail(c,"PROFILE_NOT_FOUND");}
 int64_t stamina=sqlite3_column_int64(s,0),capacity=sqlite3_column_int64(s,1),anchor=sqlite3_column_int64(s,2);
 int absent=sqlite3_column_type(s,1)==SQLITE_NULL,unanchored=sqlite3_column_type(s,2)==SQLITE_NULL;sqlite3_finalize(s);
 if(absent){int supported=rank_one_capacity(c,&capacity);if(supported<=0)return supported<0?-1:fail(c,"STAMINA_POLICY_UNAVAILABLE");return player_progress_attach(c,p,capacity,&now);}
 if(!unanchored&&now<=anchor)return 1;
 int64_t recovered=0,new_anchor=now;
 if(!unanchored&&stamina<capacity){
  int64_t points=(now-anchor)/300;if(!points)return 1;
  int64_t missing=capacity-stamina;recovered=points<missing?points:missing;
  if(recovered<missing)new_anchor=anchor+recovered*300;
 }
 s=prepare(c,"UPDATE player_progress SET recovery_anchor=?4 WHERE profile=:p",p,NULL,NULL);if(!s)return -1;
 sqlite3_bind_int64(s,4,new_anchor);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE)return fail(c,"DATABASE_ERROR");
 if(recovered){s=prepare(c,"UPDATE profiles SET stamina=stamina+?4 WHERE id=:p",p,NULL,NULL);if(!s)return -1;sqlite3_bind_int64(s,4,recovered);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE)return fail(c,"DATABASE_ERROR");}
 return 0;
}
static int profile_refresh(od_core *c,const char *p,const char *a,char **out) {
 int64_t now=0;if(integer_arg(c,a,"$.now_utc",0,INT64_C(253402300799),&now)<0)return -1;
 int replay=profile_recover_act(c,p,now);if(replay<0)return -1;
 *out=snapshot(c,p);return *out?replay:-1;
}
static int validate_player_progress(od_core *c,sqlite3 *db) {
 sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,"SELECT rank,rank_experience,act_max,recovery_seconds,recovery_anchor,policy FROM player_progress",-1,&s,NULL)!=SQLITE_OK)return 0;
 int rc,valid=1;int64_t capacity=0;int supported=-2;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  if(supported==-2)supported=rank_one_capacity(c,&capacity);
  valid=supported==1&&sqlite3_column_int64(s,0)==1&&sqlite3_column_int64(s,1)==0&&sqlite3_column_int64(s,2)==capacity&&sqlite3_column_int64(s,3)==300&&(!strcmp((const char *)sqlite3_column_text(s,5),"offline-rank1-act-v1"))&&(sqlite3_column_type(s,4)==SQLITE_NULL||(sqlite3_column_int64(s,4)>=0&&sqlite3_column_int64(s,4)<=INT64_C(253402300799)));
  if(!valid)break;
 }
 sqlite3_finalize(s);return valid&&rc==SQLITE_DONE;
}

static int mutation(od_core *c,const char *op,const char *p,const char *command,const char *a,char **out) {
 int64_t id=0,n=0;
 if(!strcmp(op,"card.sa.train")){
  char *receipt=NULL;const char *error=NULL;int rc=od_kai_training_apply(c->db,p,command,a,kai_target_binding,c,&receipt,&error);
  if(rc<0){sqlite3_free(receipt);if(c->error[0])return -1;return fail(c,error?error:"KAI_TRAINING_FAILED");}
  char *state=snapshot(c,p);if(!state){sqlite3_free(receipt);return -1;}*out=query(c,"SELECT json_set(:a,'$.sa_training',json(:id))",p,state,receipt);sqlite3_free(state);sqlite3_free(receipt);return *out?0:-1;
 }
 if(!strcmp(op,"upgrade.apply")||!strcmp(op,"upgrade.edit")||!strcmp(op,"upgrade.policy.install"))return official_mutation(c,op,p,a,out);
 if(od_schedule_store_handles(op)){
  const char *error=NULL;schedule_credit_context context={c,p};int rc=od_schedule_store_execute(c->db,c->master,op,p,a,schedule_credit,&context,secure_random,NULL,schedule_definition_validate,schedule_definition_grant,&context,out,&error);
  if(rc<0){if(c->error[0])return -1;return fail(c,error?error:"SCHEDULE_ERROR");}return rc;
 }
 if(!strcmp(op,"card.lock")||!strcmp(op,"card.experience.grant"))return card_progress_mutation(c,op,p,a,out);
 if(!strcmp(op,"creator.import"))return creator_import(c,p,a,out,0);
 if(!strcmp(op,"creator.finish"))return creator_finish(c,p,a,out,0);
 if(!strcmp(op,"banner.configure")){int r=banner_configure(c,p,a);if(r<0)return -1;*out=snapshot(c,p);return *out?r:-1;}
 if(!strcmp(op,"summon.draw"))return summon_draw(c,p,a,out);
 if(!strcmp(op,"profile.create"))return profile_create(c,p,a,out);
 if(!strcmp(op,"profile.refresh"))return profile_refresh(c,p,a,out);
 if(!strcmp(op,"inventory.grant")){
  char *source=query(c,"SELECT CASE WHEN json_type(:a,'$.source')='text' THEN json_extract(:a,'$.source') END",p,a,NULL);if(!identifier(source)||validate_rewards(c,a)<0){sqlite3_free(source);return fail(c,"INVALID_ARGUMENT");}
  char *key=sqlite3_mprintf("grant:%s",source);sqlite3_free(source);source=key;if(!source)return fail(c,"NO_MEMORY");
  sqlite3_stmt *s=prepare(c,"SELECT od_json_equal(input,:a) FROM reward_sources WHERE profile=:p AND source=:id",p,a,source);if(!s){sqlite3_free(source);return -1;}int rc=sqlite3_step(s),same=rc==SQLITE_ROW?sqlite3_column_int(s,0):0;sqlite3_finalize(s);
  if(rc==SQLITE_ROW){sqlite3_free(source);if(!same)return fail(c,"REWARD_SOURCE_CONFLICT");*out=snapshot(c,p);return *out?1:-1;}
  else{int r=grant(c,p,a,source,1);sqlite3_free(source);if(r<0)return -1;}
 }
 else if(!strcmp(op,"card.add")){
  if(integer_arg(c,a,"$.master_id",1,OD_LIMIT,&id)<0||!master_exists(c,"cards",id))return fail(c,"CARD_NOT_FOUND");
  if(writeq(c,"INSERT INTO owned_cards(profile,master_id) VALUES(:p,json_extract(:a,'$.master_id'))",p,a,NULL)<0)return -1;
 }
 else if(!strcmp(op,"team.set")){
  if(integer_arg(c,a,"$.slot",0,19,&id)<0)return -1;
  if(scalar(c,"SELECT json_type(:a,'$.members')='array' AND json_array_length(:a,'$.members') BETWEEN 0 AND 6",p,a,NULL,&n)<0||!n)return fail(c,"INVALID_TEAM");
  if(scalar(c,"SELECT count(*) FROM json_each(:a,'$.members') j WHERE j.type!='integer' OR NOT EXISTS(SELECT 1 FROM owned_cards c WHERE c.profile=:p AND c.id=j.value AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=c.id))",p,a,NULL,&n)<0||n)return fail(c,"CARD_NOT_OWNED");
  if(scalar(c,"SELECT count(*)-count(DISTINCT value) FROM json_each(:a,'$.members')",p,a,NULL,&n)<0||n)return fail(c,"DUPLICATE_TEAM_MEMBER");
  if(writeq(c,"INSERT INTO teams VALUES(:p,json_extract(:a,'$.slot'),json_extract(:a,'$.members')) ON CONFLICT(profile,slot) DO UPDATE SET members=excluded.members",p,a,NULL)<0)return -1;
 }
 else if(!strcmp(op,"run.start")){
  if(integer_arg(c,a,"$.map_id",1,OD_LIMIT,&id)<0)return -1;
  int64_t slot=0;if(integer_arg(c,a,"$.team_slot",0,19,&slot)<0)return -1;
  if(scalar(c,"SELECT json_type(:a,'$.assets_ready')='true'",p,a,NULL,&n)<0||!n)return fail(c,"CONTENT_MISSING");
  char *run=query(c,"SELECT CASE WHEN json_type(:a,'$.run_id')='text' THEN json_extract(:a,'$.run_id') END",p,a,NULL);if(!identifier(run)){sqlite3_free(run);return fail(c,"INVALID_ARGUMENT");}
  if(grant_run(c,p,a,NULL,0)<0){sqlite3_free(run);return -1;}
  sqlite3_stmt *m=NULL;
  if(sqlite3_prepare_v2(c->master,"SELECT m.act,m.quest_id,COALESCE(q.prev_quest_id,0) FROM sugoroku_maps m JOIN quests q ON q.id=m.quest_id WHERE m.id=?1",-1,&m,NULL)!=SQLITE_OK){sqlite3_free(run);return fail(c,"MASTER_SCHEMA_UNSUPPORTED");}
  sqlite3_bind_int64(m,1,id);int rc=sqlite3_step(m);
  if(rc!=SQLITE_ROW){sqlite3_finalize(m);sqlite3_free(run);return fail(c,"MAP_NOT_FOUND");}
  int64_t cost=sqlite3_column_int64(m,0),quest=sqlite3_column_int64(m,1),prev=sqlite3_column_int64(m,2);sqlite3_finalize(m);
  if(cost<0||cost>OD_LIMIT||quest<1){sqlite3_free(run);return fail(c,"MASTER_DATA_INVALID");}
  if(prev>0){sqlite3_stmt *u=prepare(c,"SELECT 1 FROM quest_progress WHERE profile=:p AND quest_id=?2",p,NULL,NULL);if(!u){sqlite3_free(run);return -1;}sqlite3_bind_int64(u,2,prev);int unlocked=sqlite3_step(u)==SQLITE_ROW;sqlite3_finalize(u);if(!unlocked){sqlite3_free(run);return fail(c,"NOT_UNLOCKED");}}
  if(scalar(c,"SELECT count(*) FROM teams WHERE profile=:p AND slot=json_extract(:a,'$.team_slot') AND json_array_length(members)>0",p,a,NULL,&n)<0||!n){sqlite3_free(run);return fail(c,"TEAM_REQUIRED");}
  int64_t has_clock=0,now=0;
  if(scalar(c,"SELECT json_type(:a,'$.now_utc') IS NOT NULL",p,a,NULL,&has_clock)<0||(has_clock&&(integer_arg(c,a,"$.now_utc",0,INT64_C(253402300799),&now)<0||profile_recover_act(c,p,now)<0))){sqlite3_free(run);return -1;}
  sqlite3_stmt *u=prepare(c,"UPDATE profiles SET stamina=stamina-?2 WHERE id=:p AND stamina>=?2",p,NULL,NULL);if(!u){sqlite3_free(run);return -1;}sqlite3_bind_int64(u,2,cost);rc=sqlite3_step(u);sqlite3_finalize(u);if(rc!=SQLITE_DONE||sqlite3_changes(c->db)!=1){sqlite3_free(run);return fail(c,"INSUFFICIENT_STAMINA");}
  u=prepare(c,"INSERT INTO runs(id,profile,map_id,quest_id,content,team_slot,team_snapshot,entry_cost,rewards,state) VALUES(:id,:p,json_extract(:a,'$.map_id'),?4,(SELECT v FROM meta WHERE k='content'),json_extract(:a,'$.team_slot'),(SELECT members FROM teams WHERE profile=:p AND slot=json_extract(:a,'$.team_slot')),?5,json(:a),'started')",p,a,run);
  if(!u){sqlite3_free(run);return -1;}sqlite3_bind_int64(u,4,quest);sqlite3_bind_int64(u,5,cost);rc=sqlite3_step(u);sqlite3_finalize(u);sqlite3_free(run);if(rc!=SQLITE_DONE)return fail(c,"DATABASE_ERROR");
 }
 else if(!strcmp(op,"run.finish")){
  char *run=query(c,"SELECT CASE WHEN json_type(:a,'$.run_id')='text' THEN json_extract(:a,'$.run_id') END",p,a,NULL);char *outcome=query(c,"SELECT CASE WHEN json_type(:a,'$.outcome')='text' THEN json_extract(:a,'$.outcome') END",p,a,NULL);
  if(!identifier(run)||!outcome||(strcmp(outcome,"clear")&&strcmp(outcome,"failed"))){sqlite3_free(run);sqlite3_free(outcome);return fail(c,"INVALID_ARGUMENT");}
  sqlite3_stmt *s=prepare(c,"SELECT state,rewards,result,outcome FROM runs WHERE id=:id AND profile=:p",p,a,run);if(!s){sqlite3_free(run);sqlite3_free(outcome);return -1;}int rc=sqlite3_step(s);
  if(rc!=SQLITE_ROW){sqlite3_finalize(s);sqlite3_free(run);sqlite3_free(outcome);return fail(c,"RUN_NOT_FOUND");}
  int done=!strcmp((const char *)sqlite3_column_text(s,0),"finished");char *rewards=sqlite3_mprintf("%s",sqlite3_column_text(s,1));char *result=done?sqlite3_mprintf("%s",sqlite3_column_text(s,2)):NULL;
  int same=!done||!strcmp((const char *)sqlite3_column_text(s,3),outcome);sqlite3_finalize(s);
  if(done){sqlite3_free(rewards);sqlite3_free(run);sqlite3_free(outcome);if(!same){sqlite3_free(result);return fail(c,"RUN_OUTCOME_CONFLICT");}if(result&&!strcmp(result,"null")){sqlite3_free(result);return fail(c,"RUN_RESULT_EXPIRED");}*out=result;return *out?1:fail(c,"NO_MEMORY");}
  if(!strcmp(outcome,"clear")){
   char *key=sqlite3_mprintf("run:%s",run);int r=key?grant_run(c,p,rewards,key,1):fail(c,"NO_MEMORY");sqlite3_free(key);if(r<0){sqlite3_free(rewards);sqlite3_free(run);sqlite3_free(outcome);return -1;}
   if(writeq(c,"INSERT INTO quest_progress SELECT profile,quest_id,1 FROM runs WHERE id=:id AND profile=:p ON CONFLICT(profile,quest_id) DO UPDATE SET clears=clears+1",p,a,run)<0){sqlite3_free(rewards);sqlite3_free(run);sqlite3_free(outcome);return -1;}
  }
  sqlite3_free(rewards);
  int r=writeq(c,"UPDATE runs SET state='finished',outcome=json_extract(:a,'$.outcome') WHERE id=:id AND profile=:p",p,a,run);sqlite3_free(run);sqlite3_free(outcome);if(r<0)return -1;
 }
 else return fail(c,"UNSUPPORTED_OPERATION");
 *out=snapshot(c,p);return *out?0:-1;
}

/* Advisory planner: callers may describe hypothetical released nodes/choices, but never
 * supply an owned identity, board, SA level or authoritative orb balance. */
static int potential_preview(od_core *c,const char *p,const char *a,char **out){
 int64_t instance=0,valid=0;
 if(integer_arg(c,a,"$.instance_id",1,OD_LIMIT,&instance)<0)return -1;
 const char *shape="SELECT NOT EXISTS(SELECT 1 FROM json_each(:a) WHERE key NOT IN('instance_id','requests','released_node_ids')) AND (json_type(:a,'$.requests') IS NULL OR json_type(:a,'$.requests')='array' AND json_array_length(:a,'$.requests')<=512) AND (json_type(:a,'$.released_node_ids') IS NULL OR json_type(:a,'$.released_node_ids')='array' AND json_array_length(:a,'$.released_node_ids')<=4096) AND NOT EXISTS(SELECT 1 FROM json_each(:a,'$.released_node_ids') WHERE type!='integer' OR value<1 OR value>9007199254740991) AND (SELECT count(*)=count(DISTINCT value) FROM json_each(:a,'$.released_node_ids')) AND NOT EXISTS(SELECT 1 FROM json_each(:a,'$.requests') j WHERE CASE WHEN j.type!='object' THEN 1 ELSE (SELECT count(*) FROM json_each(j.value))!=2 OR EXISTS(SELECT 1 FROM json_each(j.value) WHERE key NOT IN('node_id','selected_event_id')) OR json_type(j.value,'$.node_id') IS NOT 'integer' OR json_extract(j.value,'$.node_id') NOT BETWEEN 1 AND 9007199254740991 OR json_type(j.value,'$.selected_event_id') IS NOT 'integer' OR json_extract(j.value,'$.selected_event_id') NOT BETWEEN 0 AND 9007199254740991 END)";
 if(scalar(c,shape,p,a,NULL,&valid)<0||!valid)return fail(c,"POTENTIAL_INVALID_ARGUMENT");
 sqlite3_stmt *s=prepare(c,"SELECT master_id,level,sa_level,COALESCE((SELECT potential_locked FROM owned_definitions WHERE instance_id=c.id),(SELECT potential_locked FROM tournament_exclusive_owned WHERE instance_id=c.id),-1) FROM owned_cards c WHERE profile=:p AND id=json_extract(:a,'$.instance_id') AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=c.id)",p,a,NULL);if(!s)return -1;
 int rc=sqlite3_step(s);int64_t master=rc==SQLITE_ROW?sqlite3_column_int64(s,0):0,level=rc==SQLITE_ROW?sqlite3_column_int64(s,1):0,sa=rc==SQLITE_ROW?sqlite3_column_int64(s,2):0;int locked=rc==SQLITE_ROW?sqlite3_column_int(s,3):0;sqlite3_finalize(s);if(!master)return fail(c,"CARD_NOT_OWNED");
 const char *error=NULL;od_potential_board *board=NULL;char *doc=effective_document(c,c->db,instance),*graph=NULL,*plan_json=NULL;od_potential_plan *plan=NULL;int result=-1;int64_t *released=calloc(OD_POTENTIAL_MAX_NODES,sizeof(*released));od_potential_request *requests=calloc(OD_POTENTIAL_MAX_REQUESTS,sizeof(*requests));size_t rn=0,qn=0,in=0;od_potential_orbs *inventory=calloc(4096,sizeof(*inventory));
 if(!released||!requests||!inventory){error="NO_MEMORY";goto done;}
 if(od_potential_load(c->master,master,doc,&board,&error)<0)goto done;
 s=prepare(c,"SELECT value FROM json_each(:a,'$.released_node_ids') ORDER BY key",p,a,NULL);if(!s)goto done;
 while((rc=sqlite3_step(s))==SQLITE_ROW){int64_t id=sqlite3_column_int64(s,0);size_t i;for(i=0;i<board->node_count;i++)if(board->nodes[i].id==id)break;if(i==board->node_count){sqlite3_finalize(s);error="POTENTIAL_STATE_INVALID";goto done;}released[rn++]=id;}sqlite3_finalize(s);if(rc!=SQLITE_DONE)goto done;
 s=prepare(c,"SELECT json_extract(value,'$.node_id'),json_extract(value,'$.selected_event_id') FROM json_each(:a,'$.requests') ORDER BY key",p,a,NULL);if(!s)goto done;
 while((rc=sqlite3_step(s))==SQLITE_ROW){requests[qn++]=(od_potential_request){sqlite3_column_int64(s,0),sqlite3_column_int64(s,1)};}sqlite3_finalize(s);if(rc!=SQLITE_DONE)goto done;
 s=prepare(c,"SELECT item_id,quantity FROM inventory WHERE profile=:p AND kind='potential' ORDER BY item_id",p,NULL,NULL);if(!s)goto done;
 while((rc=sqlite3_step(s))==SQLITE_ROW){if(in==4096){sqlite3_finalize(s);error="POTENTIAL_INVENTORY_LIMIT";goto done;}inventory[in++]=(od_potential_orbs){sqlite3_column_int64(s,0),sqlite3_column_int64(s,1)};}sqlite3_finalize(s);if(rc!=SQLITE_DONE)goto done;
 if(qn){plan=calloc(1,sizeof(*plan));if(!plan){error="NO_MEMORY";goto done;}if(od_potential_cost_plan(board,released,rn,requests,qn,sa,inventory,in,plan,&error)<0||od_potential_plan_view(plan,&plan_json,&error)<0)goto done;}
 if(od_potential_view(board,&graph,&error)<0)goto done;
 s=prepare(c,"SELECT json_object('instance_id',?4,'master_id',?5,'level',?6,'sa_level',?7,'potential_locked',CASE WHEN ?8<0 THEN NULL ELSE json(CASE ?8 WHEN 1 THEN 'true' ELSE 'false' END) END,'owned_potential_state_verified',json('false'),'can_commit',json('false'),'released_state_is_hypothetical',json('true'),'orb_balance_verified',json('true'),'missing_policy',json('[\"owned_card_eligibility\",\"graph_activation\",\"duplicate_route_unlock\",\"owned_potential_state\"]'),'graph',json(:a),'plan',CASE WHEN :id='' THEN NULL ELSE json_set(json(:id),'$.orb_balance_verified',json('true')) END)",p,graph,plan_json);if(!s)goto done;
 sqlite3_bind_int64(s,4,instance);sqlite3_bind_int64(s,5,master);sqlite3_bind_int64(s,6,level);sqlite3_bind_int64(s,7,sa);sqlite3_bind_int(s,8,locked);if(sqlite3_step(s)==SQLITE_ROW)*out=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);if(!*out){error="NO_MEMORY";goto done;}result=0;
 done:sqlite3_free(doc);sqlite3_free(graph);sqlite3_free(plan_json);od_potential_free(board);free(plan);free(released);free(requests);free(inventory);return result<0?fail(c,error?error:"POTENTIAL_PREVIEW_FAILED"):0;
}
static int training_preview(od_core *c,const char *p,const char *a,char **out){
 int64_t instance=0,valid=0,field=0,present=0;
 if(integer_arg(c,a,"$.instance_id",1,OD_LIMIT,&instance)<0)return -1;
 const char *shape="SELECT NOT EXISTS(SELECT 1 FROM json_each(:a) WHERE key NOT IN('instance_id','items','field_id')) AND json_type(:a,'$.items')='array' AND json_array_length(:a,'$.items') BETWEEN 1 AND 128 AND NOT EXISTS(SELECT 1 FROM json_each(:a,'$.items') j WHERE CASE WHEN j.type!='object' THEN 1 ELSE (SELECT count(*) FROM json_each(j.value))!=2 OR EXISTS(SELECT 1 FROM json_each(j.value) WHERE key NOT IN('item_id','quantity')) OR json_type(j.value,'$.item_id') IS NOT 'integer' OR json_extract(j.value,'$.item_id') NOT BETWEEN 1 AND 9007199254740991 OR json_type(j.value,'$.quantity') IS NOT 'integer' OR json_extract(j.value,'$.quantity') NOT BETWEEN 1 AND 9007199254740991 END)";
 if(scalar(c,shape,p,a,NULL,&valid)<0||!valid||scalar(c,"SELECT json_type(:a,'$.field_id') IS NOT NULL",p,a,NULL,&present)<0)return fail(c,"TRAINING_INVALID_ARGUMENT");
 if(present&&integer_arg(c,a,"$.field_id",0,OD_LIMIT,&field)<0)return fail(c,"TRAINING_INVALID_ARGUMENT");
 sqlite3_stmt *s=prepare(c,"SELECT master_id,level,sa_level,(SELECT experience FROM owned_progress WHERE instance_id=c.id) FROM owned_cards c WHERE profile=:p AND id=json_extract(:a,'$.instance_id') AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=c.id)",p,a,NULL);if(!s)return -1;
 int rc=sqlite3_step(s),known=rc==SQLITE_ROW&&sqlite3_column_type(s,3)!=SQLITE_NULL;int64_t master=rc==SQLITE_ROW?sqlite3_column_int64(s,0):0,level=rc==SQLITE_ROW?sqlite3_column_int64(s,1):0,sa=rc==SQLITE_ROW?sqlite3_column_int64(s,2):0,xp=known?sqlite3_column_int64(s,3):0;sqlite3_finalize(s);if(!master)return fail(c,"CARD_NOT_OWNED");
 od_training_amount *requests=calloc(OD_TRAINING_MAX_REQUESTS,sizeof(*requests)),*inventory=calloc(4096,sizeof(*inventory));size_t rn=0,in=0;const char *error=NULL;char *doc=effective_document(c,c->db,instance),*preview=NULL,*catalog=NULL;int result=-1;
 if(!requests||!inventory){error="NO_MEMORY";goto done;}
 int64_t cap=0;if(sqlite3_prepare_v2(c->master,"SELECT COALESCE(json_extract(?2,'$.card.lv_max'),lv_max) FROM cards WHERE id=?1",-1,&s,NULL)!=SQLITE_OK){error="TRAINING_TARGET_UNAVAILABLE";goto done;}
 sqlite3_bind_int64(s,1,master);sqlite3_bind_text(s,2,doc,-1,SQLITE_TRANSIENT);if(sqlite3_step(s)==SQLITE_ROW)cap=sqlite3_column_int64(s,0);sqlite3_finalize(s);if(cap<1){error="TRAINING_TARGET_UNAVAILABLE";goto done;}
 s=prepare(c,"SELECT json_extract(value,'$.item_id'),json_extract(value,'$.quantity') FROM json_each(:a,'$.items') ORDER BY key",p,a,NULL);if(!s)goto done;
 while((rc=sqlite3_step(s))==SQLITE_ROW){requests[rn++]=(od_training_amount){sqlite3_column_int64(s,0),sqlite3_column_int64(s,1)};}sqlite3_finalize(s);if(rc!=SQLITE_DONE)goto done;
 s=prepare(c,"SELECT item_id,quantity FROM inventory WHERE profile=:p AND kind='training' ORDER BY item_id",p,NULL,NULL);if(!s)goto done;
 while((rc=sqlite3_step(s))==SQLITE_ROW){if(in==4096){sqlite3_finalize(s);error="TRAINING_INVENTORY_LIMIT";goto done;}inventory[in++]=(od_training_amount){sqlite3_column_int64(s,0),sqlite3_column_int64(s,1)};}sqlite3_finalize(s);if(rc!=SQLITE_DONE)goto done;
 if(od_training_preview(c->master,master,doc,level,known?&xp:NULL,requests,rn,inventory,in,NULL,field,&preview,&error)<0)goto done;
 if(field&&od_training_catalog(c->master,&catalog,&error)<0)goto done;
 s=prepare(c,"SELECT json_set(json(:a),'$.instance_id',?4,'$.sa_level',?5,'$.inventory_verified',json('true'),'$.effective_level_cap',?7,'$.selected_field',CASE WHEN ?6=0 THEN NULL ELSE json((SELECT value FROM json_each(:id,'$.fields') WHERE json_extract(value,'$.field_id')=?6)) END)",p,preview,catalog);if(!s)goto done;
 sqlite3_bind_int64(s,4,instance);sqlite3_bind_int64(s,5,sa);sqlite3_bind_int64(s,6,field);sqlite3_bind_int64(s,7,cap);if(sqlite3_step(s)==SQLITE_ROW)*out=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);if(!*out){error="NO_MEMORY";goto done;}result=0;
 done:free(requests);free(inventory);sqlite3_free(doc);sqlite3_free(preview);sqlite3_free(catalog);return result<0?fail(c,error?error:"TRAINING_PREVIEW_FAILED"):0;
}
static int original_scope_current(od_core *c,const char *profile,const char *args) {
 char actual[65];char *expected=query(c,"SELECT json_extract(:a,'$.expected_scope')",profile,args,NULL);
 int good=full_bundle_hex(expected)&&full_bundle_scope(c,profile,actual)==0&&!strcmp(expected,actual);
 sqlite3_free(expected);return good?0:fail(c,"ORIGINAL_PLAYER_SCOPE_CHANGED");
}
static int original_client_mutation(od_core *c,const char *operation,const char *profile,const char *args,char **out) {
 int64_t revision=0,current=0,valid=0;
 if(integer_arg(c,args,"$.expected_revision",0,OD_LIMIT,&revision)<0||
    scalar(c,"SELECT revision FROM profiles WHERE id=:p",profile,NULL,NULL,&current)<0)return -1;
 if(revision!=current)return fail(c,"ORIGINAL_PLAYER_REVISION_CHANGED");
 if(scalar(c,"SELECT json_type(:a,'$.payload')='object'",profile,args,NULL,&valid)<0||!valid)return fail(c,"INVALID_ORIGINAL_PLAYER_PAYLOAD");
 char *payload=query(c,"SELECT json_extract(:a,'$.payload')",profile,args,NULL);if(!payload)return -1;
 int replay=0;
 if(!strcmp(operation,"native.tutorial.progress")){
  int64_t progress=0,prior=0;
  if(integer_arg(c,payload,"$.progress",1,INT32_MAX,&progress)<0||
     scalar(c,"SELECT count(*)=1 AND NOT EXISTS(SELECT 1 FROM json_each(:a) WHERE key!='progress') FROM json_each(:a)",profile,payload,NULL,&valid)<0||!valid){sqlite3_free(payload);return fail(c,"INVALID_TUTORIAL_CHECKPOINT");}
  if(scalar(c,"SELECT count(*) FROM od_original_tutorial WHERE profile=:p",profile,NULL,NULL,&valid)<0||valid!=1){sqlite3_free(payload);return fail(c,"TUTORIAL_STATE_RECOVERY_REQUIRED");}
  if(scalar(c,"SELECT progress FROM od_original_tutorial WHERE profile=:p AND is_finished=0 AND policy='original-tutorial-entry-v1'",profile,NULL,NULL,&prior)<0){sqlite3_free(payload);return -1;}
  replay=prior==progress;
  if(!replay&&writeq(c,"UPDATE od_original_tutorial SET progress=json_extract(:a,'$.progress') WHERE profile=:p AND is_finished=0",profile,payload,NULL)<0){sqlite3_free(payload);return -1;}
 }else{
  char *error=NULL;int rc=od_original_teams_apply(c->db,profile,revision,payload,&error);
  if(rc<0){fail(c,error?error:"ORIGINAL_TEAM_UPDATE_FAILED");sqlite3_free(error);sqlite3_free(payload);return -1;}
  sqlite3_free(error);
 }
 sqlite3_free(payload);
 char *base=snapshot(c,profile);if(!base)return -1;
 *out=original_player_fields(c,profile,base);sqlite3_free(base);return *out?replay:-1;
}
static int execute_internal(od_core *c,const char *op,const char *p,const char *command,const char *a,int clocked,int64_t host_now,int native_mode,const void *full_bundle,size_t full_bundle_len,char **out) {
 if(!c||!out){return -1;}
 *out=NULL;c->error[0]=0;
 if(!op||!identifier(p)||!a)return fail(c,"INVALID_ARGUMENT");
 int native_full=native_mode==1,native_original=native_mode==2;
 int original_operation=!strcmp(op,"native.tutorial.progress")||!strcmp(op,"native.teams.apply");
 if(native_mode<0||native_mode>2||native_original!=original_operation)return fail(c,"ORIGINAL_PLAYER_NATIVE_AUTHORITY_REQUIRED");
 size_t limit=(!strcmp(op,"banner.configure")||!strcmp(op,"creator.import")||!strcmp(op,"creator.finish")||!strcmp(op,"upgrade.apply")||!strcmp(op,"upgrade.edit")||!strcmp(op,"upgrade.policy.install"))?OD_MAX_BANNER_INPUT:OD_MAX_INPUT;
 if(strlen(a)>limit)return fail(c,"INPUT_TOO_LARGE");
 int64_t valid=0;if(scalar(c,"SELECT CASE WHEN json_valid(:a) THEN json_type(:a)='object' ELSE 0 END",p,a,NULL,&valid)<0||!valid)return fail(c,"INVALID_JSON");
 if(scalar(c,"SELECT (SELECT count(*)=count(DISTINCT fullkey) FROM json_tree(:a)) AND NOT EXISTS(SELECT 1 FROM json_tree(:a) WHERE type='text' AND instr(atom,char(0))>0 OR instr(key,char(0))>0)",p,a,NULL,&valid)<0||!valid)return fail(c,"INVALID_JSON");

 int64_t full=0;
 if(scalar(c,"SELECT json_type(:a,'$.definition.full_bundle') IS NOT NULL",p,a,NULL,&full)<0)return -1;
 if(native_full){if(strcmp(op,"creator.finish")||!full)return fail(c,"FULL_BUNDLE_BINDING_REQUIRED");}
 else if(full)return fail(c,"FULL_BUNDLE_NATIVE_VALIDATION_REQUIRED");

 if(clocked){
  const char *keys=NULL;
  if(!strcmp(op,"profile.create")||!strcmp(op,"profile.refresh"))keys="";
  else if(!strcmp(op,"run.start"))keys="'run_id','map_id','team_slot','assets_ready','rewards'";
  else if(!strcmp(op,"schedule.rotate"))keys="'catalog_id'";
  else if(!strcmp(op,"tournament.snapshot"))keys="'tournament_id','version'";
  else if(!strcmp(op,"tournament.enroll_run")||!strcmp(op,"tournament.record_run"))keys="'tournament_id','version','run_id'";
  else if(!strcmp(op,"tournament.claim"))keys="'tournament_id','version','weekend_id'";
  else if(!strcmp(op,"elder_kai.draw"))keys="'banner_id','version','kind'";
  if(!keys)return fail(c,"UNSUPPORTED_CLOCKED_OPERATION");
  if(host_now<0||host_now>INT64_C(253402300799))return fail(c,"INVALID_HOST_CLOCK");
  char *q=sqlite3_mprintf("SELECT NOT EXISTS(SELECT 1 FROM json_each(:a) WHERE key NOT IN(%s))",keys);int allowed=q&&scalar(c,q,p,a,NULL,&valid)==0&&valid;sqlite3_free(q);if(!allowed)return fail(c,"CLOCKED_ARGUMENT_FORBIDDEN");
 }
 if(!strcmp(op,"card.training.preview")){
  if(!profile_exists(c,p))return fail(c,"PROFILE_NOT_FOUND");
  if(sql(c,"BEGIN")<0)return -1;
  if(training_preview(c,p,a,out)<0){sql(c,"ROLLBACK");return -1;}
  if(sql(c,"COMMIT")<0){od_free(*out);*out=NULL;return -1;}return 0;
 }
 if(!strcmp(op,"card.potential.preview")){
  if(!profile_exists(c,p))return fail(c,"PROFILE_NOT_FOUND");
  if(sql(c,"BEGIN")<0)return -1;
  if(potential_preview(c,p,a,out)<0){sql(c,"ROLLBACK");return -1;}
  if(sql(c,"COMMIT")<0){od_free(*out);*out=NULL;return -1;}return 0;
 }
 if(!strcmp(op,"card.stats")){
  if(!profile_exists(c,p))return fail(c,"PROFILE_NOT_FOUND");
  int64_t instance=0,unknown=0;
  if(integer_arg(c,a,"$.instance_id",1,OD_LIMIT,&instance)<0||scalar(c,"SELECT count(*) FROM json_each(:a) WHERE key!='instance_id'",p,a,NULL,&unknown)<0||unknown)return fail(c,"INVALID_ARGUMENT");
  if(sql(c,"BEGIN")<0)return -1;
  sqlite3_stmt *s=prepare(c,"SELECT master_id,level FROM owned_cards WHERE profile=:p AND id=json_extract(:a,'$.instance_id') AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=owned_cards.id)",p,a,NULL);if(!s){sql(c,"ROLLBACK");return -1;}
  int rc=sqlite3_step(s);int64_t master=rc==SQLITE_ROW?sqlite3_column_int64(s,0):0,level=rc==SQLITE_ROW?sqlite3_column_int64(s,1):0;sqlite3_finalize(s);if(!master){sql(c,"ROLLBACK");return fail(c,"CARD_NOT_OWNED");}
  char *d=effective_document(c,c->db,instance);const char *error=NULL;rc=od_card_stats(c->master,master,d,level,"master-coefficient-linear-floor-v1",out,&error);sqlite3_free(d);
  if(rc<0){sql(c,"ROLLBACK");return fail(c,error?error:"STATS_UNAVAILABLE");}if(sql(c,"COMMIT")<0){od_free(*out);*out=NULL;return -1;}return 0;
 }
 if(!strcmp(op,"upgrade.status")){
  if(!profile_exists(c,p)){return fail(c,"PROFILE_NOT_FOUND");}if(sql(c,"BEGIN")<0)return -1;
  int64_t master=0;od_upgrade_target target;if(official_target(c,p,a,&master,&target)<0){sql(c,"ROLLBACK");return -1;}
  sqlite3_stmt *s=prepare(c,"SELECT json_object('master_id',?4,'official_eza',?5,'official_super_eza',?6,'custom_eza',?7,'custom_super_eza',?8,'enhanced_policy_version',?9,'manual_edits_allowed',?9=0,'custom_eza_cost',500,'custom_super_eza_cost',700,'enhance_cost',300)",p,a,NULL);if(!s){sql(c,"ROLLBACK");return -1;}
  sqlite3_bind_int64(s,4,master);sqlite3_bind_int(s,5,target.official_eza);sqlite3_bind_int(s,6,target.official_super_eza);sqlite3_bind_int(s,7,target.custom_eza);sqlite3_bind_int(s,8,target.custom_super_eza);sqlite3_bind_int64(s,9,(sqlite3_int64)target.enhanced_policy_version);if(sqlite3_step(s)==SQLITE_ROW)*out=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);if(!*out){sql(c,"ROLLBACK");return fail(c,"NO_MEMORY");}if(sql(c,"COMMIT")<0){od_free(*out);*out=NULL;return -1;}return 0;
 }
 if(!strcmp(op,"creator.library")||!strcmp(op,"creator.export")){
  if(!profile_exists(c,p))return fail(c,"PROFILE_NOT_FOUND");
  if(sql(c,"BEGIN")<0)return -1;
  if(!strcmp(op,"creator.library"))*out=creator_library(c,p);
  else {
   char *id=query(c,"SELECT CASE WHEN json_type(:a,'$.definition_id')='text' THEN json_extract(:a,'$.definition_id') END",p,a,NULL);int64_t present=0,v=0;
   if(!identifier(id)||scalar(c,"SELECT json_type(:a,'$.version') IS NOT NULL",p,a,NULL,&present)<0||(present&&integer_arg(c,a,"$.version",1,OD_LIMIT,&v)<0)){sqlite3_free(id);sql(c,"ROLLBACK");return fail(c,"INVALID_ARGUMENT");}
   *out=query(c,"SELECT document FROM created_definitions WHERE profile=:p AND definition_id=:id AND version=COALESCE(json_extract(:a,'$.version'),(SELECT version FROM created_active WHERE profile=:p AND definition_id=:id))",p,a,id);sqlite3_free(id);
  }
  if(!*out){sql(c,"ROLLBACK");return fail(c,"DEFINITION_NOT_FOUND");}
  if(sql(c,"COMMIT")<0){od_free(*out);*out=NULL;return -1;}return 0;
 }
 if(!strcmp(op,"banner.snapshot")){
  if(!profile_exists(c,p))return fail(c,"PROFILE_NOT_FOUND");
  char *id=query(c,"SELECT CASE WHEN json_type(:a,'$.banner_id')='text' THEN json_extract(:a,'$.banner_id') END",p,a,NULL);if(!identifier(id)){sqlite3_free(id);return fail(c,"INVALID_ARGUMENT");}sqlite3_free(id);
  if(sql(c,"BEGIN")<0){return -1;}
  *out=banner_snapshot(c,p,a);if(!*out||!strcmp(*out,"(NULL)")){od_free(*out);*out=NULL;sql(c,"ROLLBACK");return fail(c,"BANNER_NOT_FOUND");}if(sql(c,"COMMIT")<0){od_free(*out);*out=NULL;return -1;}return 0;
 }
 if(!strcmp(op,"profile.snapshot")){if(!profile_exists(c,p)){return fail(c,"PROFILE_NOT_FOUND");}if(sql(c,"BEGIN")<0)return -1;*out=snapshot(c,p);if(!*out){sql(c,"ROLLBACK");return -1;}if(sql(c,"COMMIT")<0){od_free(*out);*out=NULL;return -1;}return 0;}
 if(!identifier(command))return fail(c,"COMMAND_ID_REQUIRED");
 if(sql(c,"BEGIN IMMEDIATE")<0)return -1;
 if(strcmp(op,"profile.create")&&!profile_exists(c,p)){fail(c,"PROFILE_NOT_FOUND");goto bad;}
 /* A changed save scope rejects before cached replay. Restoring the same
  * original save retains its stable scope and may replay its retained command. */
 if(native_original&&original_scope_current(c,p,a)<0)goto bad;
 sqlite3_stmt *s=prepare(c,"SELECT operation=:a,od_json_equal(input,?4),result FROM commands WHERE profile=:p AND id=:id",p,op,command);if(!s)goto bad;sqlite3_bind_text(s,4,a,-1,SQLITE_TRANSIENT);int rc=sqlite3_step(s);
 if(rc==SQLITE_ROW){int same=sqlite3_column_int(s,0)&&sqlite3_column_int(s,1);if(same)*out=sqlite3_mprintf("%s",sqlite3_column_text(s,2));sqlite3_finalize(s);if(!same){fail(c,"COMMAND_CONFLICT");goto bad;}if(*out&&!strcmp(*out,"null")){fail(c,"COMMAND_RESULT_EXPIRED");goto bad;}if(!*out){fail(c,"NO_MEMORY");goto bad;}if(native_full&&retain_full_bundle(c,p,a,full_bundle,full_bundle_len,0)<0)goto bad;if(sql(c,"COMMIT")<0){goto bad;}
 return 0;}sqlite3_finalize(s);
 if(rc!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto bad;}
 char *execution=NULL;
 if(clocked){
  s=prepare(c,"SELECT json_set(:a,'$.now_utc',?4)",p,a,NULL);if(!s)goto bad;sqlite3_bind_int64(s,4,host_now);if(sqlite3_step(s)==SQLITE_ROW)execution=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);if(!execution){fail(c,"NO_MEMORY");goto bad;}
 }
 int64_t full_definition_existed=0;
 if(native_full&&scalar(c,"SELECT EXISTS(SELECT 1 FROM created_definitions WHERE profile=:p AND definition_id=json_extract(:a,'$.definition.definition_id') AND version=json_extract(:a,'$.definition.version'))",p,a,NULL,&full_definition_existed)<0){sqlite3_free(execution);goto bad;}
 if(native_full&&full_definition_existed&&retain_full_bundle(c,p,a,full_bundle,full_bundle_len,0)<0){sqlite3_free(execution);goto bad;}
 int replay=native_full?creator_finish(c,p,a,out,1):native_original?original_client_mutation(c,op,p,a,out):mutation(c,op,p,command,execution?execution:a,out);sqlite3_free(execution);if(replay<0)goto bad;
 if(native_full&&!full_definition_existed&&retain_full_bundle(c,p,a,full_bundle,full_bundle_len,1)<0)goto bad;
 int seeded=seed_new_owned_progress(c);if(seeded<0)goto bad;
 /* Generic compact team edits must not leave a retained six-position native
  * layout invalid or turn an otherwise openable save into an invalid save. */
 if(!od_original_teams_validate(c->db)){fail(c,"ORIGINAL_TEAM_LAYOUT_CONFLICT");goto bad;}
 /* A mutation may have built its response before the fresh-row EXP seed. Keep
  * its cached cards snapshot coherent with the same committed transaction. */
 int64_t has_cards=0;if(seeded&&scalar(c,"SELECT json_type(:a,'$.cards')='array'",p,*out,NULL,&has_cards)<0)goto bad;
 if(seeded&&has_cards){
  char *current=snapshot(c,p);if(!current)goto bad;
  sqlite3_stmt *fresh=prepare(c,"SELECT json_set(:a,'$.cards',json_extract(?4,'$.cards'))",p,*out,NULL);if(!fresh){sqlite3_free(current);goto bad;}
  sqlite3_bind_text(fresh,4,current,-1,SQLITE_TRANSIENT);char *updated=sqlite3_step(fresh)==SQLITE_ROW?sqlite3_mprintf("%s",sqlite3_column_text(fresh,0)):NULL;sqlite3_finalize(fresh);sqlite3_free(current);if(!updated){fail(c,"NO_MEMORY");goto bad;}od_free(*out);*out=updated;
 }
 if(clocked&&!replay){
  s=prepare(c,"SELECT json_set(:a,'$.host_now_utc',?4)",p,*out,NULL);if(!s)goto bad;sqlite3_bind_int64(s,4,host_now);char *timed=sqlite3_step(s)==SQLITE_ROW?sqlite3_mprintf("%s",sqlite3_column_text(s,0)):NULL;sqlite3_finalize(s);if(!timed){fail(c,"NO_MEMORY");goto bad;}od_free(*out);*out=timed;
 }

 if(!replay&&(writeq(c,"UPDATE profiles SET revision=revision+1 WHERE id=:p AND revision<9007199254740991",p,a,NULL)<0||sqlite3_changes(c->db)!=1)){fail(c,"REVISION_OVERFLOW");goto bad;}
 /* Result revision is committed alongside its state. Run-finish replay retains the first settlement snapshot. */
 char *result=replay?query(c,"SELECT CASE WHEN json_type(:a,'$.revision') IS NOT NULL THEN :a ELSE json_set(:a,'$.revision',(SELECT revision FROM profiles WHERE id=:p)) END",p,*out,NULL):query(c,"SELECT json_set(:a,'$.revision',(SELECT revision FROM profiles WHERE id=:p))",p,*out,NULL);if(!result)goto bad;od_free(*out);*out=result;
 if(!strcmp(op,"creator.finish")){
  result=query(c,"SELECT json_set(:a,'$.library.revision',(SELECT revision FROM profiles WHERE id=:p))",p,*out,NULL);if(!result)goto bad;od_free(*out);*out=result;
 }
 if(!replay&&!strcmp(op,"run.finish")){
  char *run=query(c,"SELECT CASE WHEN json_type(:a,'$.run_id')='text' THEN json_extract(:a,'$.run_id') END",p,a,NULL);if(!run)goto bad;
  int stored=writeq(c,"UPDATE runs SET result=:a WHERE id=:id AND profile=:p",p,*out,run);sqlite3_free(run);if(stored<0)goto bad;
 }
 s=prepare(c,"INSERT INTO commands VALUES(:p,:id,:a,json(?4),?5)",p,op,command);if(!s)goto bad;sqlite3_bind_text(s,4,a,-1,SQLITE_TRANSIENT);sqlite3_bind_text(s,5,*out,-1,SQLITE_TRANSIENT);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto bad;}
 /* Keep bounded full snapshots, but never remove command IDs or settled-run tombstones.
  * Expired retries fail explicitly instead of re-executing a debit, draw or reward. */
 s=prepare(c,"UPDATE commands SET result='null' WHERE profile=:p AND result!='null' AND rowid NOT IN(SELECT rowid FROM commands WHERE profile=:p ORDER BY rowid DESC LIMIT ?2)",p,NULL,NULL);if(!s)goto bad;sqlite3_bind_int(s,2,OD_FULL_RESULTS);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto bad;}
 s=prepare(c,"UPDATE runs SET result='null' WHERE profile=:p AND state='finished' AND result!='null' AND rowid NOT IN(SELECT rowid FROM runs WHERE profile=:p AND state='finished' AND result!='null' ORDER BY CAST(json_extract(result,'$.revision') AS INTEGER) DESC,rowid DESC LIMIT ?2)",p,NULL,NULL);if(!s)goto bad;sqlite3_bind_int(s,2,OD_FULL_RESULTS);rc=sqlite3_step(s);sqlite3_finalize(s);if(rc!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto bad;}
 if(sql(c,"COMMIT")<0){goto bad;}
 return 0;
bad:{char saved[192];memcpy(saved,c->error,sizeof(saved));sqlite3_exec(c->db,"ROLLBACK",0,0,0);memcpy(c->error,saved,sizeof(saved));od_free(*out);*out=NULL;return -1;}
}

int od_execute(od_core *c,const char *op,const char *p,const char *command,const char *a,char **out){return execute_internal(c,op,p,command,a,0,0,0,NULL,0,out);}
int od_execute_clocked(od_core *c,const char *op,const char *p,const char *command,const char *a,int64_t host_now,char **out){return execute_internal(c,op,p,command,a,1,host_now,0,NULL,0,out);}

int od_original_client_apply(od_core *c,const char *operation,const char *profile,const char *command,
 const char *expected_scope,int64_t expected_revision,const char *payload,char **out) {
 if(!c||!out)return -1;
 *out=NULL;
 if(!operation||(strcmp(operation,"tutorial.progress")&&strcmp(operation,"teams.apply"))||
    !identifier(profile)||!identifier(command)||!full_bundle_hex(expected_scope)||
    expected_revision<0||expected_revision>OD_LIMIT||!payload||strlen(payload)>OD_MAX_INPUT)return fail(c,"INVALID_ORIGINAL_PLAYER_ARGUMENT");
 int64_t valid=0;
 if(scalar(c,"SELECT CASE WHEN json_valid(:a) THEN json_type(:a)='object' ELSE 0 END",profile,payload,NULL,&valid)<0||!valid)return fail(c,"INVALID_JSON");
 sqlite3_stmt *s=prepare(c,"SELECT json_object('expected_scope',:id,'expected_revision',?4,'payload',json(:a))",profile,payload,expected_scope);
 if(!s)return -1;
 sqlite3_bind_int64(s,4,expected_revision);char *args=sqlite3_step(s)==SQLITE_ROW?sqlite3_mprintf("%s",sqlite3_column_text(s,0)):NULL;sqlite3_finalize(s);
 if(!args)return fail(c,"NO_MEMORY");
 const char *internal=!strcmp(operation,"tutorial.progress")?"native.tutorial.progress":"native.teams.apply";
 int rc=execute_internal(c,internal,profile,command,args,0,0,2,NULL,0,out);sqlite3_free(args);return rc;
}

typedef struct { uint32_t h[8]; uint64_t bits; unsigned char block[64]; unsigned n; } od_sha256_state;
static uint32_t od_rotr(uint32_t x,unsigned n){return (x>>n)|(x<<(32-n));}
static void od_sha256_block(od_sha256_state *s,const unsigned char p[64]){
 static const uint32_t k[64]={
  0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
  0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
  0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
  0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
  0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
  0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
  0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
  0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
 uint32_t w[64],a=s->h[0],b=s->h[1],c=s->h[2],d=s->h[3],e=s->h[4],f=s->h[5],g=s->h[6],hh=s->h[7];
 for(int i=0;i<16;i++)w[i]=((uint32_t)p[i*4]<<24)|((uint32_t)p[i*4+1]<<16)|((uint32_t)p[i*4+2]<<8)|p[i*4+3];
 for(int i=16;i<64;i++){uint32_t s0=od_rotr(w[i-15],7)^od_rotr(w[i-15],18)^(w[i-15]>>3),s1=od_rotr(w[i-2],17)^od_rotr(w[i-2],19)^(w[i-2]>>10);w[i]=w[i-16]+s0+w[i-7]+s1;}
 for(int i=0;i<64;i++){uint32_t s1=od_rotr(e,6)^od_rotr(e,11)^od_rotr(e,25),ch=(e&f)^(~e&g),t1=hh+s1+ch+k[i]+w[i],s0=od_rotr(a,2)^od_rotr(a,13)^od_rotr(a,22),maj=(a&b)^(a&c)^(b&c),t2=s0+maj;hh=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;}
 s->h[0]+=a;s->h[1]+=b;s->h[2]+=c;s->h[3]+=d;s->h[4]+=e;s->h[5]+=f;s->h[6]+=g;s->h[7]+=hh;
}
static void od_sha256_hex(const void *data,size_t len,char out[65]){
 od_sha256_state s; memset(&s,0,sizeof s);
 s.h[0]=0x6a09e667;s.h[1]=0xbb67ae85;s.h[2]=0x3c6ef372;s.h[3]=0xa54ff53a;s.h[4]=0x510e527f;s.h[5]=0x9b05688c;s.h[6]=0x1f83d9ab;s.h[7]=0x5be0cd19;
 const unsigned char *p=data; s.bits=(uint64_t)len*8u;
 while(len){size_t space=64u-s.n,take=len<space?len:space;memcpy(s.block+s.n,p,take);s.n+=(unsigned)take;p+=take;len-=take;if(s.n==64){od_sha256_block(&s,s.block);s.n=0;}}
 unsigned char block[64]={0};memcpy(block,s.block,s.n);block[s.n]=0x80;if(s.n>=56){od_sha256_block(&s,block);memset(block,0,sizeof block);}
 for(int i=0;i<8;i++)block[63-i]=(unsigned char)(s.bits>>(8*i));od_sha256_block(&s,block);
 unsigned char raw[32];for(int i=0;i<8;i++){raw[i*4]=(unsigned char)(s.h[i]>>24);raw[i*4+1]=(unsigned char)(s.h[i]>>16);raw[i*4+2]=(unsigned char)(s.h[i]>>8);raw[i*4+3]=(unsigned char)s.h[i];}
 for(int i=0;i<32;i++)sprintf(out+i*2,"%02x",raw[i]);out[64]=0;
}
static int bundle_packet_matches(od_core *c,const char *profile,const char *definition,const void *bundle,size_t bundle_len){
 const char *text="SELECT json_valid(:a)=1 AND json_type(:a,'$.materialization_utc')='integer' AND json_extract(:a,'$.materialization_utc') BETWEEN 0 AND 253402300799000 AND json_extract(:a,'$.format')='od-native-creator-full-bundle-v2' AND json_extract(:a,'$.engine_admission')='pending-master-cipher-resource-and-form-progression-binding' AND json_type(:a,'$.original_client_attached') IS NULL AND json_type(:a,'$.source_sha256')='text' AND length(json_extract(:a,'$.source_sha256'))=64 AND json_extract(:a,'$.source_sha256') NOT GLOB '*[^0-9a-f]*' AND ('sha256:'||json_extract(:a,'$.source_sha256'))=CASE WHEN json_extract(:id,'$.source.content_id') LIKE 'sparking:%' THEN substr(json_extract(:id,'$.source.content_id'),10) WHEN json_extract(:id,'$.source.content_id') LIKE 'eclipse:%' THEN substr(json_extract(:id,'$.source.content_id'),9) ELSE json_extract(:id,'$.source.content_id') END AND json_extract(:a,'$.content_id')=json_extract(:id,'$.source.content_id') AND json_extract(:a,'$.content_id')=(SELECT v FROM meta WHERE k='content') AND json_extract(:a,'$.profile_id')=:p AND json_extract(:a,'$.profile_id')=json_extract(:id,'$.full_bundle.profile_id') AND json_extract(:a,'$.save_scope')=json_extract(:id,'$.full_bundle.save_scope') AND json_extract(:a,'$.definition_id')=json_extract(:id,'$.definition_id') AND json_type(:a,'$.version')='integer' AND json_extract(:a,'$.version')=json_extract(:id,'$.version') AND json_extract(:a,'$.project_sha256')=json_extract(:id,'$.full_bundle.project_sha256') AND json_type(:a,'$.member_count')='integer' AND json_extract(:a,'$.member_count')=json_extract(:id,'$.full_bundle.member_count') AND json_type(:a,'$.members')='array' AND json_array_length(:a,'$.members')=json_extract(:id,'$.full_bundle.member_count') AND json_type(:a,'$.tables')='object' AND json_type(:a,'$.resources')='array' AND json_type(:a,'$.transform_links')='array' AND json_type(:a,'$.source_dependencies')='array' AND json_type(:a,'$.shared_actions')='array'";
 sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(c->db,text,-1,&s,NULL)!=SQLITE_OK)return fail(c,"DATABASE_ERROR");
 int ip=sqlite3_bind_parameter_index(s,":p"),ia=sqlite3_bind_parameter_index(s,":a"),iid=sqlite3_bind_parameter_index(s,":id"),step,ok;
 if(!ip||!ia||!iid||sqlite3_bind_text(s,ip,profile,-1,SQLITE_TRANSIENT)!=SQLITE_OK||sqlite3_bind_text(s,iid,definition,-1,SQLITE_TRANSIENT)!=SQLITE_OK||sqlite3_bind_text(s,ia,bundle,(int)bundle_len,SQLITE_STATIC)!=SQLITE_OK){sqlite3_finalize(s);return fail(c,"DATABASE_ERROR");}
 step=sqlite3_step(s);ok=step==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);
 if(step!=SQLITE_ROW)return fail(c,"DATABASE_ERROR");
 return ok?0:fail(c,"FULL_BUNDLE_BINDING_INVALID");
}
static int full_bundle_hex(const char *text){
 if(!text||strlen(text)!=64)return 0;
 for(int i=0;i<64;i++)if(!((text[i]>='0'&&text[i]<='9')||(text[i]>='a'&&text[i]<='f')))return 0;
 return 1;
}
static int full_bundle_scope(od_core *c,const char *profile,char out[65]){
 char *identity=query(c,"SELECT v FROM meta WHERE k='projection_identity'",NULL,NULL,NULL);
 int good=identity&&strlen(identity)==32;
 for(int i=0;good&&i<32;i++)good=(identity[i]>='0'&&identity[i]<='9')||(identity[i]>='a'&&identity[i]<='f');
 char *text=good?sqlite3_mprintf("[\"%s\",\"%s\",\"%s\"]",identity,profile,c->content):NULL;
 sqlite3_free(identity);
 if(!text)return fail(c,good?"NO_MEMORY":"FULL_BUNDLE_SAVE_SCOPE_MISMATCH");
 od_sha256_hex(text,strlen(text),out);sqlite3_free(text);return 0;
}
/* Called only inside execute_internal's existing acceptance transaction.
 * Existing versions, including command retries, must already retain identical
 * bytes. Missing historical payload is explicit; descriptors never rehydrate it. */
static int retain_full_bundle(od_core *c,const char *profile,const char *args,const void *bundle,size_t bytes,int allow_insert){
 if(!bundle||!bytes||bytes>64u*1024u*1024u||memchr(bundle,0,bytes))return fail(c,"FULL_BUNDLE_BINDING_INVALID");
 char *definition=query(c,"SELECT json_extract(:a,'$.definition')",profile,args,NULL);
 char *id=definition?query(c,"SELECT json_extract(:a,'$.definition_id')",profile,definition,NULL):NULL;
 char *expected=definition?query(c,"SELECT json_extract(:a,'$.full_bundle.full_bundle_sha256')",profile,definition,NULL):NULL;
 char *bound_scope=definition?query(c,"SELECT json_extract(:a,'$.full_bundle.save_scope')",profile,definition,NULL):NULL;
 int64_t version=0;int result=-1;sqlite3_stmt *statement=NULL;char actual[65],scope[65];
 od_sha256_hex(bundle,bytes,actual);
 if(!identifier(id)||!full_bundle_hex(expected)||!full_bundle_hex(bound_scope)||strcmp(expected,actual)||
    integer_arg(c,definition,"$.version",1,OD_LIMIT,&version)<0){fail(c,"FULL_BUNDLE_HASH_MISMATCH");goto done;}
 if(full_bundle_scope(c,profile,scope)<0)goto done;
 if(strcmp(bound_scope,scope)){fail(c,"FULL_BUNDLE_SAVE_SCOPE_MISMATCH");goto done;}
 if(bundle_packet_matches(c,profile,definition,bundle,bytes)<0)goto done;
 statement=prepare(c,"SELECT save_scope,sha256,packet FROM created_full_bundles WHERE profile=:p AND definition_id=:id AND version=?4",profile,NULL,id);
 if(!statement)goto done;sqlite3_bind_int64(statement,4,version);
 int step=sqlite3_step(statement);
 if(step==SQLITE_ROW){
  const char *stored_scope=(const char *)sqlite3_column_text(statement,0),*stored_hash=(const char *)sqlite3_column_text(statement,1);
  const void *stored=sqlite3_column_blob(statement,2);int count=sqlite3_column_bytes(statement,2);
  int same=stored_scope&&stored_hash&&sqlite3_column_bytes(statement,0)==64&&sqlite3_column_bytes(statement,1)==64&&
      !strcmp(stored_scope,scope)&&!strcmp(stored_hash,actual)&&count>=0&&(size_t)count==bytes&&stored&&!memcmp(stored,bundle,bytes);
  result=same?0:fail(c,"FULL_BUNDLE_STORED_PAYLOAD_CONFLICT");goto done;
 }
 if(step!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto done;}
 sqlite3_finalize(statement);statement=NULL;
 if(!allow_insert){fail(c,"FULL_BUNDLE_PAYLOAD_MISSING_RECOVERY_REQUIRED");goto done;}
 int64_t accepted=0;
 if(scalar(c,"SELECT od_json_equal(document,:a) FROM created_definitions WHERE profile=:p AND definition_id=:id AND version=json_extract(:a,'$.version')",profile,definition,id,&accepted)<0||!accepted){fail(c,"FULL_BUNDLE_BINDING_INVALID");goto done;}
 statement=prepare(c,"INSERT INTO created_full_bundles(profile,definition_id,version,save_scope,sha256,packet) VALUES(:p,:id,?4,?5,?6,?7)",profile,NULL,id);
 if(!statement)goto done;
 sqlite3_bind_int64(statement,4,version);sqlite3_bind_text(statement,5,scope,-1,SQLITE_TRANSIENT);sqlite3_bind_text(statement,6,actual,-1,SQLITE_TRANSIENT);
 if(sqlite3_bind_blob64(statement,7,bundle,(sqlite3_uint64)bytes,SQLITE_STATIC)!=SQLITE_OK||sqlite3_step(statement)!=SQLITE_DONE){fail(c,"FULL_BUNDLE_STORAGE_FAILED");goto done;}
 result=0;
 done:sqlite3_finalize(statement);sqlite3_free(definition);sqlite3_free(id);sqlite3_free(expected);sqlite3_free(bound_scope);return result;
}
static int validate_full_bundle_rows(od_core *c,sqlite3 *db){
 od_core view=*c;view.db=db;sqlite3_stmt *statement=NULL;
 const char *sql_text="SELECT b.profile,b.save_scope,b.sha256,b.packet,d.document FROM created_full_bundles b JOIN created_definitions d USING(profile,definition_id,version)";
 if(sqlite3_prepare_v2(db,sql_text,-1,&statement,NULL)!=SQLITE_OK)return 0;
 int ok=1,step;
 while((step=sqlite3_step(statement))==SQLITE_ROW){
  const char *profile=(const char *)sqlite3_column_text(statement,0),*scope=(const char *)sqlite3_column_text(statement,1),*hash=(const char *)sqlite3_column_text(statement,2),*definition=(const char *)sqlite3_column_text(statement,4);
  const void *packet=sqlite3_column_blob(statement,3);int bytes=sqlite3_column_bytes(statement,3);char actual[65],current_scope[65];
  if(!identifier(profile)||!full_bundle_hex(scope)||!full_bundle_hex(hash)||sqlite3_column_bytes(statement,1)!=64||sqlite3_column_bytes(statement,2)!=64||!definition||sqlite3_column_bytes(statement,4)<1||sqlite3_column_bytes(statement,4)>(int)OD_MAX_BANNER_INPUT||memchr(definition,0,(size_t)sqlite3_column_bytes(statement,4))||sqlite3_column_type(statement,3)!=SQLITE_BLOB||!packet||bytes<1||bytes>64*1024*1024||memchr(packet,0,(size_t)bytes)){ok=0;break;}
  od_sha256_hex(packet,(size_t)bytes,actual);
  char *expected=query(&view,"SELECT json_extract(:a,'$.full_bundle.full_bundle_sha256')",profile,definition,NULL);
  char *bound_scope=query(&view,"SELECT json_extract(:a,'$.full_bundle.save_scope')",profile,definition,NULL);
  ok=expected&&bound_scope&&!strcmp(hash,actual)&&!strcmp(expected,actual)&&!strcmp(scope,bound_scope)&&
      full_bundle_scope(&view,profile,current_scope)==0&&!strcmp(scope,current_scope)&&bundle_packet_matches(&view,profile,definition,packet,(size_t)bytes)==0;
  sqlite3_free(expected);sqlite3_free(bound_scope);if(!ok)break;
 }
 sqlite3_finalize(statement);return ok&&step==SQLITE_DONE;
}
int od_creator_accepted_bundle(od_core *c,const char *profile,const char *definition_id,int64_t version,int64_t instance_id,const char *expected_scope,void **packet_out,size_t *packet_length,char **definition_out,char **receipt_out){
 if(!c||!packet_out||!packet_length||!definition_out||!receipt_out)return -1;
 *packet_out=NULL;*packet_length=0;*definition_out=NULL;*receipt_out=NULL;c->error[0]=0;
 if(!identifier(profile)||!identifier(definition_id)||!full_bundle_hex(expected_scope)||version<1||version>OD_LIMIT||instance_id<1||instance_id>OD_LIMIT)return fail(c,"INVALID_ACCEPTED_FULL_BUNDLE_REQUEST");
 if(sql(c,"BEGIN")<0)return -1;
 sqlite3_stmt *statement=NULL;int result=-1;char scope[65];
 if(full_bundle_scope(c,profile,scope)<0)goto done;
 if(strcmp(scope,expected_scope)){fail(c,"FULL_BUNDLE_SAVE_SCOPE_MISMATCH");goto done;}
 const char *read="SELECT d.document,b.packet,b.sha256,b.save_scope,p.revision,x.generation,json_extract(d.document,'$.full_bundle.member_count'),json_extract(d.document,'$.full_bundle.project_sha256') FROM created_definitions d JOIN profiles p ON p.id=d.profile JOIN creator_projection x ON x.profile=d.profile JOIN created_active a ON a.profile=d.profile AND a.definition_id=d.definition_id AND a.version=d.version JOIN owned_definitions o ON o.profile=d.profile AND o.definition_id=d.definition_id AND o.version=d.version JOIN owned_cards card ON card.id=o.instance_id AND card.profile=o.profile AND card.master_id=d.master_id LEFT JOIN created_full_bundles b ON b.profile=d.profile AND b.definition_id=d.definition_id AND b.version=d.version WHERE d.profile=:p AND d.definition_id=:id AND d.version=?4 AND o.instance_id=?5 AND NOT EXISTS(SELECT 1 FROM owned_consumptions consumed WHERE consumed.instance_id=o.instance_id)";
 statement=prepare(c,read,profile,NULL,definition_id);if(!statement)goto done;
 sqlite3_bind_int64(statement,4,version);sqlite3_bind_int64(statement,5,instance_id);
 int step=sqlite3_step(statement);
 if(step!=SQLITE_ROW){fail(c,step==SQLITE_DONE?"FULL_BUNDLE_ACCEPTED_OWNERSHIP_UNAVAILABLE":"DATABASE_ERROR");goto done;}
 if(sqlite3_column_type(statement,1)==SQLITE_NULL){fail(c,"FULL_BUNDLE_PAYLOAD_MISSING_RECOVERY_REQUIRED");goto done;}
 const char *definition=(const char *)sqlite3_column_text(statement,0),*hash=(const char *)sqlite3_column_text(statement,2),*stored_scope=(const char *)sqlite3_column_text(statement,3),*project_hash=(const char *)sqlite3_column_text(statement,7);
 const void *packet=sqlite3_column_blob(statement,1);int bytes=sqlite3_column_bytes(statement,1),definition_bytes=sqlite3_column_bytes(statement,0);
 int64_t revision=sqlite3_column_int64(statement,4),generation=sqlite3_column_int64(statement,5),members=sqlite3_column_int64(statement,6);
 if(!definition||definition_bytes<1||definition_bytes>(int)OD_MAX_BANNER_INPUT||memchr(definition,0,(size_t)definition_bytes)||!packet||bytes<1||bytes>64*1024*1024||sqlite3_column_type(statement,1)!=SQLITE_BLOB||memchr(packet,0,(size_t)bytes)||!full_bundle_hex(hash)||!full_bundle_hex(stored_scope)||!full_bundle_hex(project_hash)||sqlite3_column_bytes(statement,2)!=64||sqlite3_column_bytes(statement,3)!=64||sqlite3_column_bytes(statement,7)!=64||strcmp(scope,stored_scope)||revision<0||revision>OD_LIMIT||generation<1||generation>OD_LIMIT||members<1||members>5){fail(c,"FULL_BUNDLE_STORED_PAYLOAD_CONFLICT");goto done;}
 if(definition_validate_ex(c,definition,0,1)<0)goto done;
 char actual[65],definition_hash[65];od_sha256_hex(packet,(size_t)bytes,actual);od_sha256_hex(definition,(size_t)definition_bytes,definition_hash);
 char *expected=query(c,"SELECT json_extract(:a,'$.full_bundle.full_bundle_sha256')",profile,definition,NULL);
 int hashed=expected&&!strcmp(expected,actual)&&!strcmp(hash,actual);sqlite3_free(expected);
 if(!hashed||bundle_packet_matches(c,profile,definition,packet,(size_t)bytes)<0){fail(c,"FULL_BUNDLE_STORED_PAYLOAD_CONFLICT");goto done;}
 *packet_out=sqlite3_malloc64((sqlite3_uint64)bytes);*definition_out=sqlite3_mprintf("%s",definition);
 *receipt_out=sqlite3_mprintf("{\"format\":\"od-accepted-full-bundle-receipt-v1\",\"content_id\":\"%s\",\"save_scope\":\"%s\",\"profile_id\":\"%s\",\"definition_id\":\"%s\",\"version\":%lld,\"instance_id\":%lld,\"profile_revision\":%lld,\"projection_generation\":%lld,\"full_bundle_sha256\":\"%s\",\"project_sha256\":\"%s\",\"definition_sha256\":\"%s\",\"member_count\":%lld}",c->content,scope,profile,definition_id,(long long)version,(long long)instance_id,(long long)revision,(long long)generation,actual,project_hash,definition_hash,(long long)members);
 if(!*packet_out||!*definition_out||!*receipt_out){fail(c,"NO_MEMORY");goto done;}
 memcpy(*packet_out,packet,(size_t)bytes);*packet_length=(size_t)bytes;
 sqlite3_finalize(statement);statement=NULL;
 if(sql(c,"COMMIT")==0)result=0;
 done:sqlite3_finalize(statement);
 if(result<0){sqlite3_exec(c->db,"ROLLBACK",0,0,0);od_free(*packet_out);od_free(*definition_out);od_free(*receipt_out);*packet_out=NULL;*packet_length=0;*definition_out=NULL;*receipt_out=NULL;}
 return result;
}
int od_creator_finish_bundle(od_core *c,const char *p,const char *command,const char *definition,const void *bundle,size_t bundle_len,char **out) {
 if(!c||!out)return -1;
 *out=NULL;
 if(!identifier(p)||!identifier(command)||!definition||!bundle)return fail(c,"INVALID_ARGUMENT");
 if(strlen(definition)>OD_MAX_BANNER_INPUT-32||bundle_len>64u*1024u*1024u)return fail(c,"INPUT_TOO_LARGE");
 if(!bundle_len||memchr(bundle,0,bundle_len))return fail(c,"FULL_BUNDLE_BINDING_INVALID");
 int64_t valid=0;
 if(scalar(c,"SELECT CASE WHEN json_valid(:a) THEN json_type(:a)='object' AND od_json_equal(:a,:a) ELSE 0 END",p,definition,NULL,&valid)<0||!valid)return fail(c,"INVALID_JSON");
 if(scalar(c,"SELECT json_type(:a,'$.full_bundle.full_bundle_sha256')='text' AND length(json_extract(:a,'$.full_bundle.full_bundle_sha256'))=64 AND json_extract(:a,'$.full_bundle.full_bundle_sha256') NOT GLOB '*[^0-9a-f]*'",p,definition,NULL,&valid)<0)return -1;
 if(!valid)return fail(c,"FULL_BUNDLE_BINDING_REQUIRED");
 char actual[65];od_sha256_hex(bundle,bundle_len,actual);
 char *expected=query(c,"SELECT json_extract(:a,'$.full_bundle.full_bundle_sha256')",p,definition,NULL);
 int hashed=expected&&!strcmp(expected,actual);sqlite3_free(expected);
 if(!hashed)return fail(c,"FULL_BUNDLE_HASH_MISMATCH");
 if(bundle_packet_matches(c,p,definition,bundle,bundle_len)<0)return -1;
 char *args=query(c,"SELECT json_object('definition',json(:a))",p,definition,NULL);
 if(!args)return -1;
 int rc=execute_internal(c,"creator.finish",p,command,args,0,0,1,bundle,bundle_len,out);
 sqlite3_free(args);return rc;
}

/* Build the current logical projection from authoritative rows, never caller
 * document/version claims. Immutable definition versions are fetched separately
 * so the durable outbox does not duplicate every complete Creator document. */
static char *projection_state(od_core *c,const char *p) {
 return query(c,"SELECT json_object('format','od-native-creator-projection','schema_version',1,'content_id',(SELECT v FROM meta WHERE k='content'),'save_identity',(SELECT v FROM meta WHERE k='projection_identity'),'profile_id',:p,'definitions',json(COALESCE((SELECT json_group_array(json_object('definition_id',definition_id,'version',version)) FROM (SELECT definition_id,version FROM created_active WHERE profile=:p UNION SELECT d.definition_id,d.version FROM owned_definitions d WHERE d.profile=:p AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=d.instance_id) ORDER BY definition_id,version)),'[]')),'bindings',json(COALESCE((SELECT json_group_array(json_object('instance_id',instance_id,'definition_id',definition_id,'version',version,'master_id',master_id,'potential_locked',potential_locked,'addons',json(addons),'exclusive_kind',exclusive_kind,'exclusive_always_on',exclusive_always_on)) FROM (SELECT d.*,c.master_id FROM owned_definitions d JOIN owned_cards c ON c.id=d.instance_id AND c.profile=d.profile WHERE d.profile=:p AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=d.instance_id) ORDER BY instance_id)),'[]')))",p,NULL,NULL);
}
static int projection_generation(od_core *c,const char *p,int64_t expected) {
 int64_t current=0;
 if(scalar(c,"SELECT COALESCE((SELECT generation FROM creator_projection WHERE profile=:p),0)",p,NULL,NULL,&current)<0)return -1;
 if(!current)return fail(c,"PROFILE_NOT_FOUND");
 return expected&&expected!=current?fail(c,"PROJECTION_STALE"):0;
}
int od_projection_snapshot(od_core *c,const char *p,char **out) {
 if(!c||!out)return -1;
 *out=NULL;
 if(!identifier(p))return fail(c,"INVALID_ARGUMENT");
 if(sql(c,"BEGIN")<0)return -1;
 char *state=NULL;int rc=-1;
 if(projection_generation(c,p,0)<0)goto done;
 state=projection_state(c,p);if(!state)goto done;
 if(strlen(state)>OD_MAX_BANNER_INPUT){fail(c,"PROJECTION_TOO_LARGE");goto done;}
 *out=query(c,"SELECT json_object('generation',generation,'applied_generation',applied_generation,'state',json(:a)) FROM creator_projection WHERE profile=:p",p,state,NULL);
 if(*out&&sql(c,"COMMIT")==0)rc=0;
done:
 sqlite3_free(state);
 if(rc<0){sqlite3_exec(c->db,"ROLLBACK",0,0,0);od_free(*out);*out=NULL;}
 return rc;
}
int od_projection_definition(od_core *c,const char *p,int64_t generation,const char *id,int64_t version,char **out) {
 if(!c||!out)return -1;
 *out=NULL;
 if(!identifier(p)||!identifier(id)||generation<1||generation>OD_LIMIT||version<1||version>OD_LIMIT)return fail(c,"INVALID_ARGUMENT");
 if(sql(c,"BEGIN")<0)return -1;
 int rc=-1;sqlite3_stmt *s=NULL;
 if(projection_generation(c,p,generation)<0)goto done;
 s=prepare(c,"SELECT document FROM created_definitions v WHERE v.profile=:p AND v.definition_id=:id AND v.version=?4 AND (EXISTS(SELECT 1 FROM created_active a WHERE a.profile=v.profile AND a.definition_id=v.definition_id AND a.version=v.version) OR EXISTS(SELECT 1 FROM owned_definitions d WHERE d.profile=v.profile AND d.definition_id=v.definition_id AND d.version=v.version AND NOT EXISTS(SELECT 1 FROM owned_consumptions x WHERE x.instance_id=d.instance_id)))",p,NULL,id);
 if(!s)goto done;
 sqlite3_bind_int64(s,4,version);
 int step=sqlite3_step(s);
 if(step==SQLITE_ROW){
  if(sqlite3_column_bytes(s,0)>(int)OD_MAX_BANNER_INPUT)fail(c,"PROJECTION_TOO_LARGE");
  else *out=sqlite3_mprintf("%s",sqlite3_column_text(s,0));
 }else fail(c,step==SQLITE_DONE?"PROJECTION_DEFINITION_MISSING":"DATABASE_ERROR");
 sqlite3_finalize(s);s=NULL;
 if(*out&&sql(c,"COMMIT")==0)rc=0;
done:
 sqlite3_finalize(s);
 if(rc<0){sqlite3_exec(c->db,"ROLLBACK",0,0,0);od_free(*out);*out=NULL;}
 return rc;
}
int od_projection_ack(od_core *c,const char *p,int64_t generation,const char *state,char **out) {
 if(!c||!out)return -1;
 *out=NULL;
 if(!identifier(p)||!state||strlen(state)>OD_MAX_BANNER_INPUT||generation<1||generation>OD_LIMIT)return fail(c,"INVALID_ARGUMENT");
 if(sql(c,"BEGIN IMMEDIATE")<0)return -1;
 char *current=NULL;int rc=-1;sqlite3_stmt *s=NULL;
 if(projection_generation(c,p,generation)<0)goto done;
 current=projection_state(c,p);if(!current)goto done;
 if(od_json_semantic_equal(c->db,current,state)!=1){fail(c,"PROJECTION_STATE_MISMATCH");goto done;}
 s=prepare(c,"UPDATE creator_projection SET applied_generation=generation WHERE profile=:p AND generation=?4",p,NULL,NULL);if(!s)goto done;
 sqlite3_bind_int64(s,4,generation);
 int step=sqlite3_step(s);sqlite3_finalize(s);s=NULL;
 if(step!=SQLITE_DONE||sqlite3_changes(c->db)!=1){fail(c,"PROJECTION_STALE");goto done;}
 *out=query(c,"SELECT json_object('generation',generation,'applied_generation',applied_generation,'content_id',(SELECT v FROM meta WHERE k='content'),'save_identity',(SELECT v FROM meta WHERE k='projection_identity'),'profile_id',:p) FROM creator_projection WHERE profile=:p",p,NULL,NULL);
 if(*out&&sql(c,"COMMIT")==0)rc=0;
done:
 sqlite3_finalize(s);sqlite3_free(current);
 if(rc<0){sqlite3_exec(c->db,"ROLLBACK",0,0,0);od_free(*out);*out=NULL;}
 return rc;
}
static int offline_player_read(od_core *c,const char *p,int identity_only,char **out) {
 if(!c||!out)return -1;
 *out=NULL;
 if(!identifier(p))return fail(c,"INVALID_ARGUMENT");
 if(sql(c,"BEGIN")<0)return -1;
 int64_t present=0;
 if(scalar(c,"SELECT count(*) FROM offline_identity WHERE profile=:p",p,NULL,NULL,&present)<0||present!=1){
  sqlite3_exec(c->db,"ROLLBACK",0,0,0);return fail(c,"OFFLINE_IDENTITY_UNAVAILABLE");
 }
 *out=identity_only?query(c,"SELECT json_object('id',local_id,'name',display_name) FROM offline_identity WHERE profile=:p",p,NULL,NULL):snapshot(c,p);
 if(*out&&!identity_only){
  char *native=query(c,"SELECT json_set(:a,'$.creator_projection_generation',(SELECT generation FROM creator_projection WHERE profile=:p),'$.creator_projection_applied_generation',(SELECT applied_generation FROM creator_projection WHERE profile=:p))",p,*out,NULL);
  od_free(*out);*out=native;
  int64_t rank=0;char *source_rank=NULL;
  if(*out&&scalar(c,"SELECT COALESCE((SELECT rank FROM player_progress WHERE profile=:p),0)",p,NULL,NULL,&rank)<0){od_free(*out);*out=NULL;}
  if(*out&&rank>0&&table_present(c->master,"rank_statuses")){
   sqlite3_stmt *source=NULL;
   const char *q="SELECT json_object('rank',rank,'exp_total',exp_total,'act_max',act_max,'friends_capacity',friends_capacity) FROM rank_statuses WHERE rank=?1 AND typeof(rank)='integer' AND typeof(exp_total)='integer' AND typeof(act_max)='integer' AND typeof(friends_capacity)='integer' AND exp_total>=0 AND act_max>0 AND friends_capacity>=0";
   if(sqlite3_prepare_v2(c->master,q,-1,&source,NULL)==SQLITE_OK){
    sqlite3_bind_int64(source,1,rank);
    if(sqlite3_step(source)==SQLITE_ROW){source_rank=sqlite3_mprintf("%s",sqlite3_column_text(source,0));if(sqlite3_step(source)!=SQLITE_DONE){sqlite3_free(source_rank);source_rank=NULL;}}
   }
   sqlite3_finalize(source);
  }
  if(*out){
   sqlite3_stmt *source=prepare(c,"SELECT json_set(:a,'$.source_rank',json(?4))",p,*out,NULL);
   char *combined=NULL;
   if(source){if(source_rank)sqlite3_bind_text(source,4,source_rank,-1,SQLITE_TRANSIENT);else sqlite3_bind_null(source,4);if(sqlite3_step(source)==SQLITE_ROW)combined=sqlite3_mprintf("%s",sqlite3_column_text(source,0));sqlite3_finalize(source);}
   od_free(*out);*out=combined;
  }
  sqlite3_free(source_rank);
  if(*out){char *native=original_player_fields(c,p,*out);od_free(*out);*out=native;}
 }
 if(!*out||sql(c,"COMMIT")<0){sqlite3_exec(c->db,"ROLLBACK",0,0,0);od_free(*out);*out=NULL;return -1;}
 return 0;
}
int od_offline_identity(od_core *c,const char *p,char **out){return offline_player_read(c,p,1,out);}
int od_offline_player_snapshot(od_core *c,const char *p,char **out){return offline_player_read(c,p,0,out);}

int od_creator_finish_receipt(od_core *c,const char *p,const char *command,const char *definition,char **out) {
 if(!c||!out)return -1;
 *out=NULL;c->error[0]=0;
 if(!identifier(p)||!identifier(command)||!definition)return fail(c,"INVALID_ARGUMENT");
 if(strlen(definition)>OD_MAX_BANNER_INPUT)return fail(c,"INPUT_TOO_LARGE");
 int64_t valid=0;
 if(scalar(c,"SELECT CASE WHEN json_valid(:a) THEN json_type(:a)='object' AND od_json_equal(:a,:a) ELSE 0 END",p,definition,NULL,&valid)<0||!valid)return fail(c,"INVALID_JSON");
 if(sql(c,"BEGIN")<0)return -1;
 sqlite3_stmt *s=prepare(c,"SELECT operation='creator.finish',od_json_equal(input,json_object('definition',json(:a))),CASE WHEN json_type(result)='object' THEN result END FROM commands WHERE profile=:p AND id=:id",p,definition,command);
 int result=-1;
 if(!s)goto done;
 int step=sqlite3_step(s);
 if(step==SQLITE_DONE){fail(c,"CREATOR_FINISH_RECEIPT_UNAVAILABLE");goto done;}
 if(step!=SQLITE_ROW){fail(c,"DATABASE_ERROR");goto done;}
 if(!sqlite3_column_int(s,0)||!sqlite3_column_int(s,1)){fail(c,"CREATOR_FINISH_RECEIPT_MISMATCH");goto done;}
 if(sqlite3_column_type(s,2)!=SQLITE_TEXT){fail(c,"CREATOR_FINISH_RECEIPT_UNAVAILABLE");goto done;}
 *out=sqlite3_mprintf("%s",sqlite3_column_text(s,2));
 if(!*out){fail(c,"NO_MEMORY");goto done;}
 if(sqlite3_step(s)!=SQLITE_DONE){fail(c,"DATABASE_ERROR");goto done;}
 sqlite3_finalize(s);s=NULL;
 if(sql(c,"COMMIT")==0)result=0;
 done:
 sqlite3_finalize(s);
 if(result<0){sqlite3_exec(c->db,"ROLLBACK",0,0,0);od_free(*out);*out=NULL;}
 return result;
}

static int backup(sqlite3 *to,sqlite3 *from) { sqlite3_backup *b=sqlite3_backup_init(to,"main",from,"main");if(!b)return -1;int rc=sqlite3_backup_step(b,-1),end=sqlite3_backup_finish(b);return rc==SQLITE_DONE&&end==SQLITE_OK?0:-1; }
static char *schema(sqlite3 *db) {sqlite3_stmt *s=NULL;char *r=NULL;if(sqlite3_prepare_v2(db,"SELECT group_concat(name||':'||type||':'||sql,'\n') FROM (SELECT name,type,sql FROM sqlite_schema WHERE sql IS NOT NULL ORDER BY name)",-1,&s,NULL)==SQLITE_OK&&sqlite3_step(s)==SQLITE_ROW)r=sqlite3_mprintf("%s",sqlite3_column_text(s,0));sqlite3_finalize(s);return r;}
static int validate_banners(od_core *c,sqlite3 *db) {
 sqlite3_stmt *s=NULL;
 const char *invalid="SELECT 1 FROM banner_entries WHERE definition_id LIKE 'tournament-exclusive:%' UNION ALL SELECT 1 FROM banner_active a LEFT JOIN banner_pity p USING(profile,banner_id) JOIN banner_versions v USING(profile,banner_id,version) WHERE p.profile IS NULL OR p.epoch!=v.epoch UNION ALL SELECT 1 FROM card_sources s JOIN owned_cards c ON c.id=s.instance_id JOIN banner_entries e USING(profile,banner_id,version,definition_id) WHERE c.profile!=s.profile OR c.master_id!=e.master_id UNION ALL SELECT 1 FROM banner_entries a JOIN banner_entries b ON a.profile=b.profile AND a.definition_id=b.definition_id WHERE a.master_id!=b.master_id OR a.rarity!=b.rarity LIMIT 1";
 if(sqlite3_prepare_v2(db,invalid,-1,&s,NULL)!=SQLITE_OK)return 0;
 int ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 if(sqlite3_prepare_v2(db,"SELECT profile,banner_id,version,config,json_extract(config,'$.banner_id') FROM banner_versions",-1,&s,NULL)!=SQLITE_OK)return 0;
 int rc;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  if(!sqlite3_column_text(s,4)||strcmp((const char *)sqlite3_column_text(s,1),(const char *)sqlite3_column_text(s,4))){ok=0;break;}
  stored_banner b;if(banner_load(c,db,(const char *)sqlite3_column_text(s,0),(const char *)sqlite3_column_text(s,1),(uint64_t)sqlite3_column_int64(s,2),&b)<0){ok=0;break;}
  stored_banner from_json;if(banner_parse(c,(const char *)sqlite3_column_text(s,3),&from_json)<0){banner_free(&b);ok=0;break;}
  ok=b.version==from_json.version&&b.epoch==from_json.epoch&&!strcmp(b.main_id,from_json.main_id)&&b.policy.multi_count==from_json.policy.multi_count&&b.policy.lr_ppm==from_json.policy.lr_ppm&&b.policy.slr_ppm==from_json.policy.slr_ppm&&b.policy.gr_ppm==from_json.policy.gr_ppm&&b.count==from_json.count;
  for(size_t i=0;ok&&i<b.count;i++)ok=!strcmp(b.entries[i].definition_id,from_json.entries[i].definition_id)&&b.entries[i].rarity==from_json.entries[i].rarity&&b.entries[i].weight_ppm==from_json.entries[i].weight_ppm&&b.masters[i]==from_json.masters[i];
  banner_free(&b);banner_free(&from_json);if(!ok)break;
 }
 if(rc!=SQLITE_DONE){ok=0;}
 sqlite3_finalize(s);if(!ok)return 0;
 if(sqlite3_prepare_v2(db,"SELECT profile,banner_id FROM banner_active",-1,&s,NULL)!=SQLITE_OK)return 0;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  stored_banner b;if(banner_load(c,db,(const char *)sqlite3_column_text(s,0),(const char *)sqlite3_column_text(s,1),0,&b)<0){ok=0;break;}
  unsigned limit=0;for(size_t i=0;i<b.count;i++)if(!strcmp(b.entries[i].definition_id,b.main_id))limit=od_summon_pity_limit(b.entries[i].rarity);
  ok=limit&&b.pity.epoch==b.epoch&&b.pity.misses<limit;banner_free(&b);if(!ok)break;
 }
 if(rc!=SQLITE_DONE){ok=0;}
 sqlite3_finalize(s);return ok;
}
static int validate_created(od_core *c,sqlite3 *db,int version) {
 sqlite3_stmt *s=NULL;
 const char *invalid="SELECT 1 FROM created_definitions WHERE json_type(document,'$.full_bundle') IS NOT NULL AND json_extract(document,'$.full_bundle.profile_id') IS NOT profile UNION ALL SELECT 1 FROM created_definitions WHERE definition_id LIKE 'tournament-exclusive:%' UNION ALL SELECT 1 FROM created_active a WHERE a.version!=(SELECT max(version) FROM created_definitions d WHERE d.profile=a.profile AND d.definition_id=a.definition_id) UNION ALL SELECT 1 FROM created_definitions a JOIN created_definitions b USING(profile,definition_id) WHERE a.master_id!=b.master_id OR a.rarity!=b.rarity OR a.version<b.version AND json_type(a.document,'$.stat_policy') IS NOT NULL AND json_extract(a.document,'$.stat_policy') IS NOT json_extract(b.document,'$.stat_policy') OR a.version<b.version AND json_type(a.document,'$.creator') IS NOT NULL AND (json_extract(a.document,'$.creator.id') IS NOT json_extract(b.document,'$.creator.id') OR json_extract(a.document,'$.creator.name') IS NOT json_extract(b.document,'$.creator.name')) UNION ALL SELECT 1 FROM created_definitions d WHERE NOT EXISTS(SELECT 1 FROM created_active a WHERE a.profile=d.profile AND a.definition_id=d.definition_id) UNION ALL SELECT 1 FROM created_active a WHERE NOT EXISTS(SELECT 1 FROM creator_state s WHERE s.profile=a.profile) UNION ALL SELECT 1 FROM creator_state s WHERE s.main_id!=(SELECT definition_id FROM created_active a WHERE a.profile=s.profile ORDER BY sequence DESC LIMIT 1) OR s.epoch!=(SELECT count(*) FROM created_active a WHERE a.profile=s.profile) UNION ALL SELECT 1 FROM owned_definitions d JOIN owned_cards c ON c.id=d.instance_id JOIN created_definitions v USING(profile,definition_id,version) JOIN created_active a USING(profile,definition_id) WHERE c.profile!=d.profile OR c.master_id!=v.master_id OR d.version!=a.version OR d.origin_version>d.version OR d.potential_locked!=1 OR d.addons!='[]' OR json(c.potential)!='{}' OR d.exclusive_kind!=CASE v.rarity WHEN 6 THEN 1 WHEN 7 THEN 2 ELSE 0 END OR d.exclusive_always_on!=CASE WHEN v.rarity>=6 THEN 1 ELSE 0 END UNION ALL SELECT 1 FROM banner_definitions b JOIN banner_entries e ON e.profile=b.profile AND e.banner_id=b.banner_id AND e.version=b.banner_version AND e.definition_id=b.definition_id JOIN created_definitions d ON d.profile=b.profile AND d.definition_id=b.definition_id AND d.version=b.definition_version WHERE e.master_id!=d.master_id OR e.rarity!=d.rarity UNION ALL SELECT 1 FROM card_sources s JOIN banner_definitions b ON b.profile=s.profile AND b.banner_id=s.banner_id AND b.banner_version=s.version AND b.definition_id=s.definition_id LEFT JOIN owned_definitions d ON d.instance_id=s.instance_id WHERE d.instance_id IS NULL OR d.definition_id!=b.definition_id OR d.origin_version!=b.definition_version LIMIT 1";
 if(sqlite3_prepare_v2(db,invalid,-1,&s,NULL)!=SQLITE_OK)return 0;
 int ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 /* Every created copy has exactly one provable origin: an actual banner pull
  * or its permanent local Creator collection entry. Legacy saves permit pulls only. */
 const char *sourceCheck="SELECT 1 FROM owned_definitions d WHERE NOT EXISTS(SELECT 1 FROM card_sources s JOIN banner_definitions b ON b.profile=s.profile AND b.banner_id=s.banner_id AND b.banner_version=s.version AND b.definition_id=s.definition_id WHERE s.instance_id=d.instance_id AND b.definition_id=d.definition_id AND b.definition_version=d.origin_version)";
 char *origin=sqlite3_mprintf("%s%s LIMIT 1",sourceCheck,version>=8?" AND NOT EXISTS(SELECT 1 FROM creator_collection x WHERE x.instance_id=d.instance_id AND x.profile=d.profile AND x.definition_id=d.definition_id AND x.origin_version=d.origin_version)":"");
 if(!origin||sqlite3_prepare_v2(db,origin,-1,&s,NULL)!=SQLITE_OK){sqlite3_free(origin);return 0;}sqlite3_free(origin);
 ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 if(version>=8){
  const char *invalidCollection="SELECT 1 FROM creator_collection x LEFT JOIN owned_definitions d ON d.instance_id=x.instance_id WHERE d.instance_id IS NULL OR x.profile!=d.profile OR x.definition_id!=d.definition_id OR x.origin_version!=d.origin_version OR EXISTS(SELECT 1 FROM card_sources p WHERE p.instance_id=x.instance_id) LIMIT 1";
  if(sqlite3_prepare_v2(db,invalidCollection,-1,&s,NULL)!=SQLITE_OK)return 0;
  ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 }
 if(sqlite3_prepare_v2(db,"SELECT definition_id,version,master_id,rarity,document FROM created_definitions",-1,&s,NULL)!=SQLITE_OK)return 0;
 int rc;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  const char *d=(const char *)sqlite3_column_text(s,4);if(definition_validate_ex(c,d,0,1)<0){ok=0;break;}
  sqlite3_stmt *q=prepare(c,"SELECT json_extract(:a,'$.definition_id')=?4 AND json_extract(:a,'$.version')=?5 AND json_extract(:a,'$.source.master_id')=?6 AND CASE json_extract(:a,'$.rarity') WHEN 'UR' THEN 4 WHEN 'LR' THEN 5 WHEN 'SLR' THEN 6 ELSE 7 END=?7",NULL,d,NULL);if(!q){ok=0;break;}
  sqlite3_bind_text(q,4,(const char *)sqlite3_column_text(s,0),-1,SQLITE_TRANSIENT);sqlite3_bind_int64(q,5,sqlite3_column_int64(s,1));sqlite3_bind_int64(q,6,sqlite3_column_int64(s,2));sqlite3_bind_int(q,7,sqlite3_column_int(s,3));ok=sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_int(q,0);sqlite3_finalize(q);if(!ok)break;
 }
 sqlite3_finalize(s);if(!ok||rc!=SQLITE_DONE)return 0;
 /* Check pinned versions against the immutable JSON, including missing/extra binding rows. */
 const char *bindings="SELECT 1 FROM banner_versions v,json_each(v.config,'$.pool') j WHERE (json_type(j.value,'$.definition_version') IS NOT NULL) != EXISTS(SELECT 1 FROM banner_definitions b WHERE b.profile=v.profile AND b.banner_id=v.banner_id AND b.banner_version=v.version AND b.definition_id=json_extract(j.value,'$.definition_id')) OR json_type(j.value,'$.definition_version') IS NOT NULL AND (json_type(j.value,'$.definition_version')!='integer' OR NOT EXISTS(SELECT 1 FROM banner_definitions b WHERE b.profile=v.profile AND b.banner_id=v.banner_id AND b.banner_version=v.version AND b.definition_id=json_extract(j.value,'$.definition_id') AND b.definition_version=json_extract(j.value,'$.definition_version'))) UNION ALL SELECT 1 FROM banner_versions v WHERE EXISTS(SELECT 1 FROM banner_definitions b WHERE b.profile=v.profile AND b.banner_id=v.banner_id AND b.banner_version=v.version) AND (json_type(v.config,'$.creator_epoch') IS NOT 'integer' OR json_extract(v.config,'$.creator_epoch')!=v.epoch OR NOT EXISTS(SELECT 1 FROM created_active a WHERE a.profile=v.profile AND a.definition_id=v.main_id AND a.sequence=v.epoch)) LIMIT 1";
 if(sqlite3_prepare_v2(db,bindings,-1,&s,NULL)!=SQLITE_OK)return 0;
 ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);return ok;
}

static int validate_official(od_core *c,sqlite3 *db) {
 sqlite3_stmt *s=NULL;
 if(sqlite3_prepare_v2(db,"SELECT profile,policy_id,policy_version,master_id,document FROM official_upgrade_policies",-1,&s,NULL)!=SQLITE_OK)return 0;
 int rc,ok=1;
 while((rc=sqlite3_step(s))==SQLITE_ROW){const char *d=(const char *)sqlite3_column_text(s,4);if(official_validate(c,d)<0){ok=0;break;}sqlite3_stmt *q=prepare(c,"SELECT json_extract(:a,'$.kind')='enhanced' AND json_extract(:a,'$.policy_id')=?4 AND json_extract(:a,'$.policy_version')=?5 AND json_extract(:a,'$.source.master_id')=?6",NULL,d,NULL);if(!q){ok=0;break;}sqlite3_bind_text(q,4,(const char *)sqlite3_column_text(s,1),-1,SQLITE_TRANSIENT);sqlite3_bind_int64(q,5,sqlite3_column_int64(s,2));sqlite3_bind_int64(q,6,sqlite3_column_int64(s,3));ok=sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_int(q,0);sqlite3_finalize(q);if(!ok)break;}
 sqlite3_finalize(s);if(!ok||rc!=SQLITE_DONE)return 0;
 const char *bad="SELECT 1 FROM official_upgrade_active a WHERE a.version!=(SELECT max(version) FROM official_upgrade_versions v WHERE v.profile=a.profile AND v.master_id=a.master_id) UNION ALL SELECT 1 FROM official_upgrade_versions v WHERE NOT EXISTS(SELECT 1 FROM official_upgrade_active a WHERE a.profile=v.profile AND a.master_id=v.master_id) LIMIT 1";
 if(sqlite3_prepare_v2(db,bad,-1,&s,NULL)!=SQLITE_OK)return 0;
 ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 if(sqlite3_prepare_v2(db,"SELECT profile,master_id,version,kind,custom_eza,custom_super_eza,enhanced_policy_version,document,stone_cost FROM official_upgrade_versions ORDER BY profile,master_id,version",-1,&s,NULL)!=SQLITE_OK)return 0;
 char *profile=NULL,*prior_doc=NULL;int64_t master=0,last=0;int prior_kind=0;od_upgrade_target target;memset(&target,0,sizeof(target));
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  const char *p=(const char *)sqlite3_column_text(s,0),*d=(const char *)sqlite3_column_text(s,7);int64_t m=sqlite3_column_int64(s,1),version=sqlite3_column_int64(s,2),cost=sqlite3_column_int64(s,8);int kind=sqlite3_column_int(s,3);
  if(!profile||strcmp(profile,p)||m!=master){sqlite3_free(profile);profile=sqlite3_mprintf("%s",p);master=m;last=0;prior_kind=0;sqlite3_free(prior_doc);prior_doc=NULL;if(!profile||official_status(c,m,&target)<0){ok=0;break;}}
  if(version!=last+1||official_validate(c,d)<0){ok=0;break;}
  if(prior_doc){int64_t compatible=0;if(scalar(c,"SELECT json_type(:a,'$.stat_policy') IS NULL OR json_extract(:a,'$.stat_policy') IS json_extract(:id,'$.stat_policy')",NULL,prior_doc,d,&compatible)<0||!compatible){ok=0;break;}}

  int64_t source=0;char *name=query(c,"SELECT json_extract(:a,'$.kind')",NULL,d,NULL);int doc_kind=upgrade_kind(name);sqlite3_free(name);if(integer_arg(c,d,"$.source.master_id",1,OD_LIMIT,&source)<0||source!=master||doc_kind!=kind){ok=0;break;}
  od_upgrade_plan plan;memset(&plan,0,sizeof(plan));uint64_t policy=0;int64_t pv=0;
  if(kind==OD_UPGRADE_ENHANCE){
   if(integer_arg(c,d,"$.policy_version",1,OD_LIMIT,&pv)<0){ok=0;break;}policy=(uint64_t)pv;
   sqlite3_stmt *q=NULL;const char *lookup="SELECT od_json_equal(document,?1) FROM official_upgrade_policies WHERE profile=?2 AND policy_id=json_extract(?1,'$.policy_id') AND policy_version=json_extract(?1,'$.policy_version') AND master_id=?3";
   if(sqlite3_prepare_v2(db,lookup,-1,&q,NULL)!=SQLITE_OK){ok=0;break;}sqlite3_bind_text(q,1,d,-1,SQLITE_TRANSIENT);sqlite3_bind_text(q,2,p,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(q,3,m);ok=sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_int(q,0);sqlite3_finalize(q);if(!ok)break;
  }
  if(cost){if(od_upgrade_make_plan(&target,(od_upgrade_kind)kind,policy,0,OD_LIMIT,&plan)!=OD_PROGRESSION_OK||cost!=(int64_t)plan.stone_cost){ok=0;break;}if(kind==OD_UPGRADE_CUSTOM_SUPER_EZA&&!target.official_eza)plan.custom_eza=1;}
  else{
   int64_t old_revision=0,new_revision=0;if(!prior_doc||prior_kind!=kind||kind==OD_UPGRADE_ENHANCE||target.enhanced_policy_version||integer_arg(c,prior_doc,"$.version",1,OD_LIMIT,&old_revision)<0||integer_arg(c,d,"$.version",1,OD_LIMIT,&new_revision)<0||new_revision<=old_revision){ok=0;break;}
   plan.custom_eza=target.custom_eza;plan.custom_super_eza=target.custom_super_eza;plan.enhanced_policy_version=target.enhanced_policy_version;
  }
  if(sqlite3_column_int(s,4)!=plan.custom_eza||sqlite3_column_int(s,5)!=plan.custom_super_eza||(uint64_t)sqlite3_column_int64(s,6)!=plan.enhanced_policy_version){ok=0;break;}
  target.custom_eza=plan.custom_eza;target.custom_super_eza=plan.custom_super_eza;target.enhanced_policy_version=plan.enhanced_policy_version;last=version;prior_kind=kind;sqlite3_free(prior_doc);prior_doc=sqlite3_mprintf("%s",d);if(!prior_doc){ok=0;break;}
 }
 sqlite3_free(profile);sqlite3_free(prior_doc);sqlite3_finalize(s);return ok&&rc==SQLITE_DONE;
}

static int validate_inventory(od_core *c,sqlite3 *db) {
 sqlite3_stmt *s=NULL;if(sqlite3_prepare_v2(db,"SELECT kind,item_id FROM inventory",-1,&s,NULL)!=SQLITE_OK)return 0;int rc,ok=1;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  const char *kind=(const char *)sqlite3_column_text(s,0),*table=NULL;int64_t id=sqlite3_column_int64(s,1);
  if(!strcmp(kind,"stone")){if(id!=0){ok=0;break;}continue;}
  if(!strcmp(kind,"medal"))table="awakening_items";else if(!strcmp(kind,"training"))table="training_items";else if(!strcmp(kind,"support"))table="support_items";else if(!strcmp(kind,"equipment"))table="equipment_skill_items";else if(!strcmp(kind,"act"))table="act_items";else if(!strcmp(kind,"potential"))table="potential_items";
  if(!table||!master_exists(c,table,id)){ok=0;break;}
 }
 sqlite3_finalize(s);return ok&&rc==SQLITE_DONE;
}

static int validate_save_version(od_core *c,sqlite3 *db,int version) {
 if(od_register_json_equal(db)!=SQLITE_OK)return 0;
 sqlite3_stmt *s=NULL;int ok=0,rc;
 if(sqlite3_prepare_v2(db,"PRAGMA quick_check",-1,&s,NULL)!=SQLITE_OK)return 0;
 if(sqlite3_step(s)==SQLITE_ROW)ok=!strcmp((const char *)sqlite3_column_text(s,0),"ok");
 sqlite3_finalize(s);if(!ok)return 0;
 sqlite3 *expected=NULL;
 if(sqlite3_open(":memory:",&expected)!=SQLITE_OK){if(expected)sqlite3_close(expected);return 0;}
 if(sqlite3_exec(expected,SCHEMA,0,0,0)!=SQLITE_OK||(version>=2&&sqlite3_exec(expected,SCHEMA_V2,0,0,0)!=SQLITE_OK)||(version>=3&&sqlite3_exec(expected,SCHEMA_V3,0,0,0)!=SQLITE_OK)||(version>=4&&sqlite3_exec(expected,SCHEMA_V4,0,0,0)!=SQLITE_OK)||(version>=5&&(sqlite3_exec(expected,od_schedule_store_schema(),0,0,0)!=SQLITE_OK||sqlite3_exec(expected,SCHEMA_V5,0,0,0)!=SQLITE_OK))||(version>=6&&(sqlite3_exec(expected,od_schedule_store_schema_v2(),0,0,0)!=SQLITE_OK||sqlite3_exec(expected,SCHEMA_V6,0,0,0)!=SQLITE_OK))||(version>=7&&(sqlite3_exec(expected,od_kai_training_schema(),0,0,0)!=SQLITE_OK||sqlite3_exec(expected,SCHEMA_V7,0,0,0)!=SQLITE_OK))||(version>=8&&sqlite3_exec(expected,SCHEMA_V8,0,0,0)!=SQLITE_OK)||(version>=9&&sqlite3_exec(expected,SCHEMA_V9,0,0,0)!=SQLITE_OK)||(version>=10&&sqlite3_exec(expected,SCHEMA_V10,0,0,0)!=SQLITE_OK)||(version>=11&&sqlite3_exec(expected,SCHEMA_V11,0,0,0)!=SQLITE_OK)||(version>=12&&sqlite3_exec(expected,SCHEMA_V12,0,0,0)!=SQLITE_OK)||(version>=13&&(sqlite3_exec(expected,od_original_teams_schema_sql(),0,0,0)!=SQLITE_OK||sqlite3_exec(expected,SCHEMA_V13,0,0,0)!=SQLITE_OK))){sqlite3_close(expected);return 0;}
 char *a=schema(expected),*b=schema(db);ok=a&&b&&!strcmp(a,b);sqlite3_free(a);sqlite3_free(b);sqlite3_close(expected);if(!ok)return 0;
 if(sqlite3_prepare_v2(db,"SELECT count(*)=1 AND max(v)=?1 FROM meta WHERE k='content'",-1,&s,NULL)!=SQLITE_OK)return 0;
 sqlite3_bind_text(s,1,c->content,-1,SQLITE_TRANSIENT);ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0);sqlite3_finalize(s);if(!ok)return 0;
 if(sqlite3_prepare_v2(db,"PRAGMA user_version",-1,&s,NULL)!=SQLITE_OK)return 0;
 ok=sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_int(s,0)==version;sqlite3_finalize(s);if(!ok)return 0;
 if(sqlite3_prepare_v2(db,"PRAGMA foreign_key_check",-1,&s,NULL)!=SQLITE_OK)return 0;
 ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 const char *invalid="SELECT 1 FROM inventory WHERE quantity<0 OR quantity>9007199254740991 OR item_id<0 UNION ALL SELECT 1 FROM profiles WHERE revision<0 OR revision>9007199254740991 OR stamina<0 OR stamina>9007199254740991 UNION ALL SELECT 1 FROM owned_cards WHERE level<1 OR sa_level<1 OR NOT json_valid(potential) OR json_type(potential)!='object' UNION ALL SELECT 1 FROM teams WHERE slot<0 OR slot>19 OR json_type(members)!='array' OR json_array_length(members)>6 UNION ALL SELECT 1 FROM runs WHERE json_type(team_snapshot)!='array' OR json_array_length(team_snapshot) NOT BETWEEN 1 AND 6 OR state='finished' AND (result IS NULL OR outcome IS NULL) OR state='started' AND (result IS NOT NULL OR outcome IS NOT NULL) LIMIT 1";
 if(sqlite3_prepare_v2(db,invalid,-1,&s,NULL)!=SQLITE_OK)return 0;
 ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 const char *bad_teams="SELECT 1 FROM teams t,json_each(t.members) j WHERE j.type!='integer' OR NOT EXISTS(SELECT 1 FROM owned_cards c WHERE c.profile=t.profile AND c.id=j.value) UNION ALL SELECT 1 FROM teams t WHERE json_array_length(t.members)!=(SELECT count(DISTINCT value) FROM json_each(t.members)) UNION ALL SELECT 1 FROM runs r,json_each(r.team_snapshot) j WHERE j.type!='integer' OR NOT EXISTS(SELECT 1 FROM owned_cards c WHERE c.profile=r.profile AND c.id=j.value) UNION ALL SELECT 1 FROM runs r WHERE json_array_length(r.team_snapshot)!=(SELECT count(DISTINCT value) FROM json_each(r.team_snapshot)) UNION ALL SELECT 1 FROM runs WHERE content!=(SELECT v FROM meta WHERE k='content') LIMIT 1";
 if(sqlite3_prepare_v2(db,bad_teams,-1,&s,NULL)!=SQLITE_OK)return 0;
 ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 if(!validate_inventory(c,db))return 0;
 if(version>=3&&!validate_created(c,db,version))return 0;
 if(version>=9&&!validate_player_progress(c,db))return 0;
 if(version>=10){
  const char *projection_invalid="SELECT 1 WHERE (SELECT count(*) FROM meta WHERE k='projection_identity' AND length(v)=32 AND v NOT GLOB '*[^0-9a-f]*')!=1 UNION ALL SELECT 1 FROM profiles p LEFT JOIN creator_projection x ON x.profile=p.id WHERE x.profile IS NULL UNION ALL SELECT 1 FROM creator_projection WHERE generation NOT BETWEEN 1 AND 9007199254740991 OR applied_generation NOT BETWEEN 0 AND generation LIMIT 1";
  if(sqlite3_prepare_v2(db,projection_invalid,-1,&s,NULL)!=SQLITE_OK)return 0;
  ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 }
 if(version>=11){
  const char *identity_invalid="SELECT 1 FROM profiles p LEFT JOIN offline_identity i ON i.profile=p.id WHERE i.profile IS NULL UNION ALL SELECT 1 FROM offline_identity WHERE local_id NOT BETWEEN 1 AND 2147483647 OR length(display_name) NOT BETWEEN 1 AND 32 OR instr(display_name,char(0))>0 LIMIT 1";
  if(sqlite3_prepare_v2(db,identity_invalid,-1,&s,NULL)!=SQLITE_OK)return 0;
  ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok)return 0;
 }
 if(version>=12&&!validate_full_bundle_rows(c,db))return 0;
 if(version>=13){
  const char *tutorial_invalid="SELECT 1 FROM od_original_tutorial WHERE progress NOT BETWEEN 0 AND 2147483647 OR is_finished!=0 OR policy!='original-tutorial-entry-v1' LIMIT 1";
  if(sqlite3_prepare_v2(db,tutorial_invalid,-1,&s,NULL)!=SQLITE_OK)return 0;
  ok=sqlite3_step(s)==SQLITE_DONE;sqlite3_finalize(s);if(!ok||!od_original_teams_validate(db))return 0;
 }
 if(version>=6&&!validate_official(c,db))return 0;
 if(version>=7&&!od_kai_training_validate(db,kai_target_binding,c))return 0;
 if(version>=4&&!validate_progress(c,db))return 0;
 if(version>=5){schedule_credit_context ctx={c,NULL};if(!od_schedule_store_validate(db,c->master,schedule_definition_validate,&ctx))return 0;}
 if(sqlite3_prepare_v2(db,"SELECT master_id,level,sa_level,id FROM owned_cards",-1,&s,NULL)!=SQLITE_OK)return 0;
 while((rc=sqlite3_step(s))==SQLITE_ROW){
  sqlite3_stmt *m=NULL;
  if(sqlite3_prepare_v2(c->master,"SELECT lv_max,skill_lv_max FROM cards WHERE id=?1",-1,&m,NULL)!=SQLITE_OK){ok=0;break;}
  sqlite3_bind_int64(m,1,sqlite3_column_int64(s,0));int mr=sqlite3_step(m);
  int within=mr==SQLITE_ROW&&sqlite3_column_int64(s,1)<=sqlite3_column_int64(m,0)&&sqlite3_column_int64(s,2)<=sqlite3_column_int64(m,1);
  sqlite3_finalize(m);
  if(version>=3){
   char *effective=effective_document(c,db,sqlite3_column_int64(s,3));
   if(effective){sqlite3_stmt *d=prepare(c,"SELECT json_extract(:a,'$.card.lv_max'),json_extract(:a,'$.card.skill_lv_max')",NULL,effective,NULL);sqlite3_free(effective);if(!d){ok=0;break;}within=sqlite3_step(d)==SQLITE_ROW&&sqlite3_column_int64(s,1)<=sqlite3_column_int64(d,0)&&sqlite3_column_int64(s,2)<=sqlite3_column_int64(d,1);sqlite3_finalize(d);}
  }
  if(!within){ok=0;break;}
 }
 if(rc!=SQLITE_DONE){ok=0;}
 sqlite3_finalize(s);if(!ok)return 0;
 if(sqlite3_prepare_v2(db,"SELECT DISTINCT map_id FROM runs",-1,&s,NULL)!=SQLITE_OK)return 0;
 while((rc=sqlite3_step(s))==SQLITE_ROW)if(!master_exists(c,"sugoroku_maps",sqlite3_column_int64(s,0))){ok=0;break;}
 if(rc!=SQLITE_DONE){ok=0;}
 sqlite3_finalize(s);return ok&&(version==1||validate_banners(c,db));
}
static int validate_save(od_core *c,sqlite3 *db){return validate_save_version(c,db,13);}
int od_export_save(od_core *c,const char *dest) {
 if(!c||!dest||!*dest)return -1;
 struct stat st;if(lstat(dest,&st)==0)return fail(c,"DESTINATION_EXISTS");
 char *part=sqlite3_mprintf("%s.part",dest);if(!part)return fail(c,"NO_MEMORY");
 int fd=open(part,O_CREAT|O_EXCL|O_RDWR|O_NOFOLLOW,0600);if(fd<0){sqlite3_free(part);return fail(c,"DESTINATION_EXISTS");}
 /* Match the existing import budget without limiting live-save mutations.
  * Inspect the completed SQLite snapshot, not a racing source file size. */
 const sqlite3_int64 budget_bytes=256LL*1024LL*1024LL;
 struct stat owned={0},live={0};int pinned=fstat(fd,&owned)==0&&S_ISREG(owned.st_mode);
 sqlite3 *db=NULL;sqlite3_stmt *budget=NULL;int too_large=0,published=0;
 int ok=pinned&&sqlite3_open_v2(part,&db,SQLITE_OPEN_READWRITE|SQLITE_OPEN_NOFOLLOW,NULL)==SQLITE_OK&&backup(db,c->db)==0;
 if(ok){
  ok=sqlite3_prepare_v2(db,"SELECT page_count,page_size FROM pragma_page_count(),pragma_page_size()",-1,&budget,NULL)==SQLITE_OK&&sqlite3_step(budget)==SQLITE_ROW;
  if(ok){sqlite3_int64 pages=sqlite3_column_int64(budget,0),page_bytes=sqlite3_column_int64(budget,1);
   if(pages<1||page_bytes<1)ok=0;
   else if(pages>budget_bytes/page_bytes){too_large=1;ok=0;}
  }
 }
 sqlite3_finalize(budget);if(db&&sqlite3_close(db)!=SQLITE_OK)ok=0;
 /* Verify the final file too: logical page size alone does not bound trailing
  * bytes. Keep the original descriptor until no-replace publication completes. */
 if(ok){
  ok=fstat(fd,&live)==0&&S_ISREG(live.st_mode)&&live.st_dev==owned.st_dev&&live.st_ino==owned.st_ino&&live.st_size>0;
  if(ok&&live.st_size>budget_bytes){too_large=1;ok=0;}
  if(ok)ok=fsync(fd)==0&&lstat(part,&live)==0&&S_ISREG(live.st_mode)&&live.st_dev==owned.st_dev&&live.st_ino==owned.st_ino;
  if(ok&&live.st_size>budget_bytes){too_large=1;ok=0;}
 }
 /* link is an atomic no-replace publish: unlike rename, it cannot overwrite an unrelated destination. */
 if(ok){published=link(part,dest)==0;ok=published;}
 if(ok){
  ok=lstat(dest,&live)==0&&S_ISREG(live.st_mode)&&live.st_dev==owned.st_dev&&live.st_ino==owned.st_ino&&live.st_size>0;
  if(ok&&live.st_size>budget_bytes){too_large=1;ok=0;}
 }
 /* A refusal must preserve the canonical save, an existing backup, and any
  * pre-existing/replaced .part. Remove only paths still naming our new inode. */
 if(published&&!ok&&lstat(dest,&live)==0&&live.st_dev==owned.st_dev&&live.st_ino==owned.st_ino)unlink(dest);
 if(pinned&&lstat(part,&live)==0&&live.st_dev==owned.st_dev&&live.st_ino==owned.st_ino)unlink(part);
 close(fd);sqlite3_free(part);return ok?0:fail(c,too_large?"SAVE_EXPORT_TOO_LARGE":"EXPORT_FAILED");
}
static int projection_import_epoch(od_core *c,sqlite3 *candidate) {
 /* Restoring an older backup must not reuse a generation already materialized
  * by this device's sidecar. Requeue above both source and current epochs. */
 sqlite3_stmt *old=NULL,*update=NULL;
 if(sqlite3_prepare_v2(c->db,"SELECT profile,generation FROM creator_projection",-1,&old,NULL)!=SQLITE_OK)return 0;
 if(sqlite3_prepare_v2(candidate,"UPDATE creator_projection SET generation=max(generation,?2),applied_generation=0 WHERE profile=?1",-1,&update,NULL)!=SQLITE_OK){sqlite3_finalize(old);return 0;}
 int rc,ok=1;
 while((rc=sqlite3_step(old))==SQLITE_ROW){
  sqlite3_int64 epoch=sqlite3_column_int64(old,1);
  if(epoch>=OD_LIMIT){ok=0;break;}
  sqlite3_reset(update);sqlite3_clear_bindings(update);
  sqlite3_bind_text(update,1,(const char *)sqlite3_column_text(old,0),-1,SQLITE_TRANSIENT);
  sqlite3_bind_int64(update,2,epoch+1);
  if(sqlite3_step(update)!=SQLITE_DONE){ok=0;break;}
 }
 if(rc!=SQLITE_DONE)ok=0;
 sqlite3_finalize(old);sqlite3_finalize(update);return ok;
}
int od_import_save(od_core *c,const char *source) {
 if(!c||!source)return -1;
 struct stat st;if(lstat(source,&st)||!S_ISREG(st.st_mode)||st.st_size>256*1024*1024)return fail(c,"SAVE_INVALID");sqlite3 *db=NULL,*candidate=NULL;
 if(sqlite3_open_v2(source,&db,SQLITE_OPEN_READONLY,NULL)!=SQLITE_OK){if(db)sqlite3_close(db);return fail(c,"SAVE_INVALID");}
 if(sqlite3_exec(db,"BEGIN",0,0,0)!=SQLITE_OK){sqlite3_close(db);return fail(c,"IMPORT_FAILED");}
 sqlite3_stmt *s=NULL;int version=0;
 if(sqlite3_prepare_v2(db,"PRAGMA user_version",-1,&s,NULL)==SQLITE_OK&&sqlite3_step(s)==SQLITE_ROW)version=sqlite3_column_int(s,0);
 sqlite3_finalize(s);
 int valid=0;
 /* Always stage imports privately. Requeue projection before replacing the active
  * save: a restored backup may carry an ack for a sidecar absent on this device. */
 if(version>=1&&version<=13&&validate_save_version(c,db,version)){
  if(sqlite3_open(":memory:",&candidate)==SQLITE_OK&&backup(candidate,db)==0&&
     (version>=2||sqlite3_exec(candidate,SCHEMA_V2,0,0,0)==SQLITE_OK)&&
     (version>=3||sqlite3_exec(candidate,SCHEMA_V3,0,0,0)==SQLITE_OK)&&
     (version>=4||sqlite3_exec(candidate,SCHEMA_V4,0,0,0)==SQLITE_OK)&&
     (version>=5||sqlite3_exec(candidate,od_schedule_store_schema(),0,0,0)==SQLITE_OK)&&
     (version>=6||(sqlite3_exec(candidate,od_schedule_store_schema_v2(),0,0,0)==SQLITE_OK&&sqlite3_exec(candidate,SCHEMA_V6,0,0,0)==SQLITE_OK))&&
     (version>=7||(sqlite3_exec(candidate,od_kai_training_schema(),0,0,0)==SQLITE_OK&&sqlite3_exec(candidate,SCHEMA_V7,0,0,0)==SQLITE_OK))&&
     (version>=8||sqlite3_exec(candidate,SCHEMA_V8,0,0,0)==SQLITE_OK)&&
     (version>=9||sqlite3_exec(candidate,SCHEMA_V9,0,0,0)==SQLITE_OK)&&
     (version>=10||sqlite3_exec(candidate,SCHEMA_V10,0,0,0)==SQLITE_OK)&&
     (version>=11||sqlite3_exec(candidate,SCHEMA_V11,0,0,0)==SQLITE_OK)&&
     (version>=12||sqlite3_exec(candidate,SCHEMA_V12,0,0,0)==SQLITE_OK)&&
     (version>=13||(sqlite3_exec(candidate,od_original_teams_schema_sql(),0,0,0)==SQLITE_OK&&sqlite3_exec(candidate,SCHEMA_V13,0,0,0)==SQLITE_OK))&&
     sqlite3_exec(candidate,"UPDATE creator_projection SET generation=generation+1,applied_generation=0",0,0,0)==SQLITE_OK&&projection_import_epoch(c,candidate))
   valid=validate_save(c,candidate);
 }
 int ok=valid&&backup(c->db,candidate?candidate:db)==0;
 if(candidate){sqlite3_close(candidate);}
 sqlite3_exec(db,"ROLLBACK",0,0,0);sqlite3_close(db);return ok?0:fail(c,valid?"IMPORT_FAILED":"SAVE_INVALID");
}
