#include "schedules_store.h"
#include "json_values.h"

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define STORE_LIMIT INT64_C(9007199254740991)
typedef struct { sqlite3 *db,*master; const char *profile; const char **error;
    od_schedule_definition_validate_fn validate_definition;
    od_schedule_definition_grant_fn grant_definition;void *definition_context;
} store;
static int error(store *s,const char *text) { if(s->error)*s->error=text; return -1; }
static int id_ok(const char *id) {
    size_t i;if(!id||!id[0]){return 0;}
    for(i=0;i<=127;i++){unsigned char c=(unsigned char)id[i];if(!c){return 1;}
        if(!((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='-'||c=='_'||c=='.'||c==':')){return 0;}}
    return 0;
}
static sqlite3_stmt *statement(store *s,const char *sql,const char *args,const char *id) {
    sqlite3_stmt *q=NULL;const char *names[]={":p",":a",":x"};const char *values[]={s->profile,args,id};int i;
    /* Reserve named slots before numbered extras. An UPDATE may mention ?5 before :p;
     * without this prefix SQLite would assign :p=6, colliding with an explicit ?6. */
    char *bound_sql=sqlite3_mprintf("WITH _od_bind(_p,_a,_x) AS (VALUES(:p,:a,:x)) %s",sql);
    if(!bound_sql){error(s,"SCHEDULE_NO_MEMORY");return NULL;}
    int rc=sqlite3_prepare_v2(s->db,bound_sql,-1,&q,NULL);sqlite3_free(bound_sql);
    if(rc!=SQLITE_OK){error(s,"SCHEDULE_DATABASE_ERROR");return NULL;}
    for(i=0;i<3;i++){int n=sqlite3_bind_parameter_index(q,names[i]);if(n)sqlite3_bind_text(q,n,values[i]?values[i]:"",-1,SQLITE_TRANSIENT);}
    return q;
}
static char *text_query(store *s,const char *sql,const char *args,const char *id) {
    sqlite3_stmt *q=statement(s,sql,args,id);char *result=NULL;if(!q){return NULL;}
    if(sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_type(q,0)!=SQLITE_NULL)result=sqlite3_mprintf("%s",sqlite3_column_text(q,0));
    sqlite3_finalize(q);return result;
}
static int write_statement(store *s,sqlite3_stmt *q) {
    int rc;if(!q){return -1;}rc=sqlite3_step(q);sqlite3_finalize(q);return rc==SQLITE_DONE?0:error(s,"SCHEDULE_DATABASE_ERROR");
}
static char *string_arg(store *s,const char *args,const char *path) {
    return text_query(s,"SELECT CASE WHEN json_type(:a,:x)='text' THEN json_extract(:a,:x) END",args,path);
}
static int integer(store *s,const char *args,const char *path,int64_t low,int64_t high,int64_t *out) {
    sqlite3_stmt *q=statement(s,"SELECT json_extract(:a,:x),json_type(:a,:x)",args,path);int good=0;
    if(q&&sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_type(q,0)==SQLITE_INTEGER&&sqlite3_column_type(q,1)==SQLITE_TEXT&&
        !strcmp((const char *)sqlite3_column_text(q,1),"integer")){*out=sqlite3_column_int64(q,0);good=*out>=low&&*out<=high;}
    sqlite3_finalize(q);return good?0:error(s,"SCHEDULE_INVALID_ARGUMENT");
}
static int boolean(store *s,const char *args,const char *path,int *out) {
    char *type=text_query(s,"SELECT json_type(:a,:x)",args,path);int good=type&&(!strcmp(type,"true")||!strcmp(type,"false"));
    if(good){*out=!strcmp(type,"true");}sqlite3_free(type);return good?0:error(s,"SCHEDULE_INVALID_ARGUMENT");
}
static int array_count(store *s,const char *args,const char *path,int low,int high,int *out) {
    sqlite3_stmt *q=statement(s,"SELECT json_type(:a,:x),json_array_length(:a,:x)",args,path);int good=0;
    if(q&&sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_type(q,0)==SQLITE_TEXT&&!strcmp((const char *)sqlite3_column_text(q,0),"array")){
        *out=sqlite3_column_int(q,1);good=*out>=low&&*out<=high;}
    sqlite3_finalize(q);return good?0:error(s,"SCHEDULE_INVALID_ARGUMENT");
}
static char *json_arg(store *s,const char *args,const char *path) {
    return text_query(s,"SELECT CASE WHEN json_type(:a,:x)='object' THEN json_extract(:a,:x) END",args,path);
}
static int master_has(store *s,const char *table,int64_t id) {
    char sql[160];sqlite3_stmt *q=NULL;int rc;
    snprintf(sql,sizeof(sql),"SELECT 1 FROM %s WHERE id=?1",table);
    if(sqlite3_prepare_v2(s->master,sql,-1,&q,NULL)!=SQLITE_OK){return 0;}
    sqlite3_bind_int64(q,1,id);rc=sqlite3_step(q);sqlite3_finalize(q);return rc==SQLITE_ROW;
}
static int period(store *s,int64_t now,int zone,od_schedule_period *out) {
    if(od_schedule_current_period(now,(od_schedule_zone)zone,out)!=OD_SCHEDULE_OK){return error(s,"SCHEDULE_CLOCK_OUT_OF_RANGE");}return 0;
}
static int seed_value(const char *text,uint64_t *out) {
    size_t i;uint64_t n=0;if(!text||strlen(text)!=16){return 0;}
    for(i=0;i<16;i++){unsigned char c=(unsigned char)text[i];unsigned v;
        if(c>='0'&&c<='9')v=c-'0';else if(c>='a'&&c<='f')v=c-'a'+10;else return 0;
        n=(n<<4)|v;}
    *out=n;return 1;
}

const char *od_schedule_store_schema(void) {
    return
    "CREATE TABLE schedule_catalogs(profile TEXT NOT NULL REFERENCES profiles(id),id TEXT NOT NULL,zone INTEGER NOT NULL CHECK(zone IN(0,1)),document TEXT NOT NULL CHECK(json_valid(document)),PRIMARY KEY(profile,id)) STRICT;"
    "CREATE TABLE weekly_rotations(profile TEXT PRIMARY KEY REFERENCES profiles(id),week_id INTEGER NOT NULL CHECK(week_id>0),catalog_id TEXT NOT NULL,selected_at INTEGER NOT NULL CHECK(selected_at>=0),banner_ids TEXT NOT NULL CHECK(json_valid(banner_ids) AND json_type(banner_ids)='array' AND json_array_length(banner_ids)=2),FOREIGN KEY(profile,catalog_id) REFERENCES schedule_catalogs(profile,id)) STRICT;"
    "CREATE TABLE tournament_configs(profile TEXT NOT NULL REFERENCES profiles(id),id TEXT NOT NULL,version INTEGER NOT NULL CHECK(version BETWEEN 1 AND 9007199254740991),zone INTEGER NOT NULL CHECK(zone IN(0,1)),document TEXT NOT NULL CHECK(json_valid(document)),PRIMARY KEY(profile,id,version)) STRICT;"
    "CREATE TABLE tournament_periods(profile TEXT NOT NULL,tournament_id TEXT NOT NULL,weekend_id INTEGER NOT NULL CHECK(weekend_id>0),config_version INTEGER NOT NULL,start_utc INTEGER NOT NULL CHECK(start_utc>=0),end_utc INTEGER NOT NULL CHECK(end_utc>start_utc),observed_utc INTEGER NOT NULL CHECK(observed_utc>=start_utc AND observed_utc<=end_utc),player_points INTEGER NOT NULL DEFAULT 0 CHECK(player_points BETWEEN 0 AND 9007199254740991),PRIMARY KEY(profile,tournament_id,weekend_id),FOREIGN KEY(profile,tournament_id,config_version) REFERENCES tournament_configs(profile,id,version)) STRICT;"
    "CREATE TABLE tournament_ai(profile TEXT NOT NULL,tournament_id TEXT NOT NULL,weekend_id INTEGER NOT NULL,competitor_id TEXT NOT NULL,state TEXT NOT NULL CHECK(json_valid(state)),PRIMARY KEY(profile,tournament_id,weekend_id,competitor_id),FOREIGN KEY(profile,tournament_id,weekend_id) REFERENCES tournament_periods(profile,tournament_id,weekend_id)) STRICT;"
    "CREATE TABLE tournament_runs(profile TEXT NOT NULL,run_id TEXT NOT NULL REFERENCES runs(id),tournament_id TEXT NOT NULL,weekend_id INTEGER NOT NULL,map_id INTEGER NOT NULL CHECK(map_id>0),points INTEGER NOT NULL CHECK(points BETWEEN 1 AND 9007199254740991),credited INTEGER NOT NULL DEFAULT 0 CHECK(credited IN(0,1)),PRIMARY KEY(profile,run_id),FOREIGN KEY(profile,tournament_id,weekend_id) REFERENCES tournament_periods(profile,tournament_id,weekend_id)) STRICT;"
    "CREATE TABLE tournament_claims(profile TEXT NOT NULL,tournament_id TEXT NOT NULL,weekend_id INTEGER NOT NULL,result TEXT NOT NULL CHECK(json_valid(result)),PRIMARY KEY(profile,tournament_id,weekend_id),FOREIGN KEY(profile,tournament_id,weekend_id) REFERENCES tournament_periods(profile,tournament_id,weekend_id)) STRICT;"
    "CREATE TABLE elder_kai_configs(profile TEXT NOT NULL REFERENCES profiles(id),id TEXT NOT NULL,version INTEGER NOT NULL CHECK(version BETWEEN 1 AND 9007199254740991),zone INTEGER NOT NULL CHECK(zone IN(0,1)),document TEXT NOT NULL CHECK(json_valid(document)),PRIMARY KEY(profile,id,version)) STRICT;";
}

const char *od_schedule_store_schema_v2(void){
    return
    "CREATE TABLE tournament_exclusive_definitions(profile TEXT NOT NULL REFERENCES profiles(id),definition_id TEXT NOT NULL,version INTEGER NOT NULL CHECK(version BETWEEN 1 AND 9007199254740991),document TEXT NOT NULL CHECK(json_valid(document)),PRIMARY KEY(profile,definition_id,version)) STRICT;"
    "CREATE TABLE tournament_exclusive_active(profile TEXT NOT NULL,definition_id TEXT NOT NULL,version INTEGER NOT NULL,PRIMARY KEY(profile,definition_id),FOREIGN KEY(profile,definition_id,version) REFERENCES tournament_exclusive_definitions(profile,definition_id,version)) STRICT;"
    "CREATE TABLE tournament_exclusive_owned(instance_id INTEGER PRIMARY KEY REFERENCES owned_cards(id),profile TEXT NOT NULL,definition_id TEXT NOT NULL,version INTEGER NOT NULL,tournament_id TEXT NOT NULL,weekend_id INTEGER NOT NULL,reward_ordinal INTEGER NOT NULL CHECK(reward_ordinal BETWEEN 0 AND 63),unit_ordinal INTEGER NOT NULL CHECK(unit_ordinal BETWEEN 0 AND 999),potential_locked INTEGER NOT NULL DEFAULT 1 CHECK(potential_locked IN(0,1)),addons TEXT NOT NULL DEFAULT '[]' CHECK(json_valid(addons) AND json_type(addons)='array'),exclusive_kind INTEGER NOT NULL CHECK(exclusive_kind BETWEEN 0 AND 2),exclusive_always_on INTEGER NOT NULL CHECK(exclusive_always_on IN(0,1)),UNIQUE(profile,tournament_id,weekend_id,reward_ordinal,unit_ordinal),FOREIGN KEY(profile,definition_id,version) REFERENCES tournament_exclusive_definitions(profile,definition_id,version),FOREIGN KEY(profile,tournament_id,weekend_id) REFERENCES tournament_claims(profile,tournament_id,weekend_id) DEFERRABLE INITIALLY DEFERRED) STRICT;";
}

int od_schedule_store_is_exclusive_id(sqlite3 *save,const char *profile,const char *id){
    sqlite3_stmt *q=NULL;int rc;if(!save||!id_ok(profile)||!id_ok(id)){return -1;}
    if(sqlite3_prepare_v2(save,"SELECT 1 FROM tournament_exclusive_definitions WHERE profile=?1 AND definition_id=?2 LIMIT 1",-1,&q,NULL)!=SQLITE_OK){return -1;}
    sqlite3_bind_text(q,1,profile,-1,SQLITE_TRANSIENT);sqlite3_bind_text(q,2,id,-1,SQLITE_TRANSIENT);rc=sqlite3_step(q);sqlite3_finalize(q);return rc==SQLITE_ROW?1:rc==SQLITE_DONE?0:-1;
}
static int exclusive_schema(sqlite3 *db){
    sqlite3_stmt *q=NULL;int count=-1;if(sqlite3_prepare_v2(db,"SELECT count(*) FROM sqlite_schema WHERE type='table' AND name IN('tournament_exclusive_definitions','tournament_exclusive_active','tournament_exclusive_owned')",-1,&q,NULL)!=SQLITE_OK){return -1;}
    if(sqlite3_step(q)==SQLITE_ROW){count=sqlite3_column_int(q,0);}sqlite3_finalize(q);return count==3?1:count==0?0:-1;
}

static char *exclusive_document(store *s,const char *id,int64_t version){
    sqlite3_stmt *q=statement(s,"SELECT document FROM tournament_exclusive_definitions WHERE profile=:p AND definition_id=:x AND version=?5",NULL,id);char *doc=NULL;
    if(!q){return NULL;}sqlite3_bind_int64(q,5,version);if(sqlite3_step(q)==SQLITE_ROW){doc=sqlite3_mprintf("%s",sqlite3_column_text(q,0));}sqlite3_finalize(q);return doc;
}
static int exclusive_collision(store *s,const char *id){
    sqlite3_stmt *q=statement(s,"SELECT EXISTS(SELECT 1 FROM created_definitions WHERE profile=:p AND definition_id=:x) OR EXISTS(SELECT 1 FROM banner_entries WHERE profile=:p AND definition_id=:x)",NULL,id);int conflict=1;
    if(q&&sqlite3_step(q)==SQLITE_ROW){conflict=sqlite3_column_int(q,0);}sqlite3_finalize(q);return conflict;
}
static char *exclusive_library(store *s){
    return text_query(s,"SELECT json_object('origin','world_tournament_exclusive','definitions',json(COALESCE((SELECT json_group_array(json(document)) FROM (SELECT d.document FROM tournament_exclusive_definitions d JOIN tournament_exclusive_active a USING(profile,definition_id,version) WHERE d.profile=:p ORDER BY d.definition_id)),'[]')))",NULL,NULL);
}
static int register_exclusive(store *s,const char *args,char **out){
    char *doc=json_arg(s,args,"$.definition"),*id=NULL,*old=NULL,*canonical=NULL,*creator=NULL;int64_t version=0,active=0;sqlite3_stmt *q;int result=-1;
    if(!doc||!s->validate_definition||s->validate_definition(s->definition_context,doc)<0){error(s,"TOURNAMENT_EXCLUSIVE_DEFINITION_INVALID");goto done;}
    id=string_arg(s,doc,"$.definition_id");creator=string_arg(s,doc,"$.creator.id");
    if(!id_ok(id)||strncmp(id,"tournament-exclusive:",21)||!id[21]||!id_ok(creator)||integer(s,doc,"$.version",1,STORE_LIMIT,&version)<0||exclusive_collision(s,id)){error(s,"TOURNAMENT_EXCLUSIVE_ID_CONFLICT");goto done;}
    q=statement(s,"SELECT version FROM tournament_exclusive_active WHERE profile=:p AND definition_id=:x",NULL,id);if(!q){goto done;}
    if(sqlite3_step(q)==SQLITE_ROW){active=sqlite3_column_int64(q,0);}sqlite3_finalize(q);
    if(active){old=exclusive_document(s,id,active);if(!old){error(s,"SCHEDULE_DATABASE_ERROR");goto done;}
        if(version<active){error(s,"TOURNAMENT_EXCLUSIVE_VERSION_STALE");goto done;}
        if(version==active){canonical=text_query(s,"SELECT json(:a)",doc,NULL);if(!canonical||od_json_semantic_equal(s->db,canonical,old)!=1){error(s,"TOURNAMENT_EXCLUSIVE_VERSION_CONFLICT");goto done;}*out=exclusive_library(s);result=*out?1:-1;goto done;}
        char *same=text_query(s,"SELECT json_extract(:a,'$.source.master_id')=json_extract(:x,'$.source.master_id') AND json_extract(:a,'$.source.content_id')=json_extract(:x,'$.source.content_id') AND json_extract(:a,'$.rarity')=json_extract(:x,'$.rarity') AND json_extract(:a,'$.creator.id')=json_extract(:x,'$.creator.id') AND (json_extract(:x,'$.stat_policy') IS NULL OR json_extract(:a,'$.stat_policy') IS json_extract(:x,'$.stat_policy'))",doc,old);
        int equal=same&&!strcmp(same,"1");sqlite3_free(same);if(!equal){error(s,"TOURNAMENT_EXCLUSIVE_IDENTITY_CONFLICT");goto done;}
    }
    q=statement(s,"INSERT INTO tournament_exclusive_definitions VALUES(:p,:x,?5,json(:a))",doc,id);if(!q){goto done;}sqlite3_bind_int64(q,5,version);if(write_statement(s,q)<0){goto done;}
    q=statement(s,"INSERT INTO tournament_exclusive_active VALUES(:p,:x,?5) ON CONFLICT(profile,definition_id) DO UPDATE SET version=excluded.version",NULL,id);if(!q){goto done;}sqlite3_bind_int64(q,5,version);if(write_statement(s,q)<0){goto done;}
    *out=exclusive_library(s);result=*out?0:-1;
done:sqlite3_free(doc);sqlite3_free(id);sqlite3_free(old);sqlite3_free(canonical);sqlite3_free(creator);return result;
}

typedef struct { char *id;int zone;od_historical_banner *rows;size_t count; } catalog;
static void free_catalog(catalog *c) {size_t i;if(c->rows)for(i=0;i<c->count;i++)sqlite3_free((void *)c->rows[i].banner_id);free(c->rows);sqlite3_free(c->id);memset(c,0,sizeof(*c));}
static int load_catalog_document(store *s,const char *doc,catalog *c) {
    int n,i;int64_t zone;memset(c,0,sizeof(*c));c->id=string_arg(s,doc,"$.catalog_id");
    if(!id_ok(c->id)||integer(s,doc,"$.zone",0,1,&zone)<0||array_count(s,doc,"$.history",1,4096,&n)<0){goto bad;}
    c->zone=(int)zone;c->count=(size_t)n;c->rows=calloc(c->count,sizeof(*c->rows));if(!c->rows){goto bad;}
    for(i=0;i<n;i++){
        char path[80],*row;int64_t first,version;int known,usable;sqlite3_stmt *q;int exists;
        snprintf(path,sizeof(path),"$.history[%d]",i);row=json_arg(s,doc,path);if(!row){goto bad;}
        c->rows[i].banner_id=string_arg(s,row,"$.banner_id");
        if(!id_ok(c->rows[i].banner_id)||integer(s,row,"$.version",1,STORE_LIMIT,&version)<0||
            integer(s,row,"$.first_open_utc",0,INT64_C(253402300799),&first)<0||
            boolean(s,row,"$.verified_official",&known)<0||boolean(s,row,"$.usable_local_content",&usable)<0){sqlite3_free(row);goto bad;}
        q=statement(s,"SELECT 1 FROM banner_versions WHERE profile=:p AND banner_id=:x AND version=?5",NULL,c->rows[i].banner_id);
        if(!q){sqlite3_free(row);goto bad;}sqlite3_bind_int64(q,5,version);exists=sqlite3_step(q)==SQLITE_ROW;sqlite3_finalize(q);sqlite3_free(row);
        if(!exists){goto bad;}
        c->rows[i].first_open_utc=first;c->rows[i].verified_official_history=known;c->rows[i].usable_local_content=usable;
        for(int j=0;j<i;j++)if(!strcmp(c->rows[i].banner_id,c->rows[j].banner_id)){goto bad;}
    }
    return 0;
bad:free_catalog(c);return error(s,"SCHEDULE_INVALID_CATALOG");
}

static int install_catalog(store *s,const char *args,char **out) {
    catalog c;char *existing,*canonical;sqlite3_stmt *q;int result=0;
    if(load_catalog_document(s,args,&c)<0){return -1;}
    existing=text_query(s,"SELECT document FROM schedule_catalogs WHERE profile=:p AND id=:x",NULL,c.id);
    canonical=text_query(s,"SELECT json(:a)",args,NULL);
    if(existing){result=canonical&&od_json_semantic_equal(s->db,existing,canonical)==1?1:error(s,"SCHEDULE_CATALOG_CONFLICT");}
    else{q=statement(s,"INSERT INTO schedule_catalogs VALUES(:p,:x,?5,json(:a))",args,c.id);if(q)sqlite3_bind_int(q,5,c.zone);result=write_statement(s,q);}
    if(result>=0)*out=text_query(s,"SELECT json_object('catalog_id',:x,'installed',json('true'))",NULL,c.id);
    sqlite3_free(existing);sqlite3_free(canonical);free_catalog(&c);return result>=0&&!*out?error(s,"SCHEDULE_NO_MEMORY"):result;
}

static int rotate_catalog(store *s,const char *args,od_summon_random rng,void *rng_context,char **out) {
    char *id=string_arg(s,args,"$.catalog_id"),*doc=NULL;int64_t now;catalog c;od_weekly_rotation prior={0},next;sqlite3_stmt *q;int result=-1;
    if(!id_ok(id)||integer(s,args,"$.now_utc",0,INT64_C(253402300799),&now)<0){goto done;}
    doc=text_query(s,"SELECT document FROM schedule_catalogs WHERE profile=:p AND id=:x",NULL,id);if(!doc||load_catalog_document(s,doc,&c)<0){goto done;}
    q=statement(s,"SELECT week_id,catalog_id,selected_at,json_extract(banner_ids,'$[0]'),json_extract(banner_ids,'$[1]') FROM weekly_rotations WHERE profile=:p",NULL,NULL);
    if(!q){free_catalog(&c);goto done;}
    if(sqlite3_step(q)==SQLITE_ROW){prior.week_id=(uint32_t)sqlite3_column_int64(q,0);prior.selected_at_utc=sqlite3_column_int64(q,2);
        snprintf(prior.catalog_version,sizeof(prior.catalog_version),"%s",sqlite3_column_text(q,1));
        snprintf(prior.banner_ids[0],sizeof(prior.banner_ids[0]),"%s",sqlite3_column_text(q,3));snprintf(prior.banner_ids[1],sizeof(prior.banner_ids[1]),"%s",sqlite3_column_text(q,4));}
    sqlite3_finalize(q);
    od_schedule_status status=od_schedule_rotate(c.rows,c.count,id,now,(od_schedule_zone)c.zone,&prior,rng,rng_context,&next);free_catalog(&c);
    if(status!=OD_SCHEDULE_OK){error(s,od_schedule_status_name(status));goto done;}
    result=prior.week_id==next.week_id?1:0;
    if(!result){q=statement(s,"INSERT INTO weekly_rotations(profile,catalog_id,week_id,selected_at,banner_ids) VALUES(:p,:x,?5,?6,json_array(?7,?8)) ON CONFLICT(profile) DO UPDATE SET week_id=excluded.week_id,catalog_id=excluded.catalog_id,selected_at=excluded.selected_at,banner_ids=excluded.banner_ids",NULL,id);
        if(!q){result=-1;goto done;}sqlite3_bind_int64(q,5,next.week_id);sqlite3_bind_int64(q,6,next.selected_at_utc);sqlite3_bind_text(q,7,next.banner_ids[0],-1,SQLITE_TRANSIENT);sqlite3_bind_text(q,8,next.banner_ids[1],-1,SQLITE_TRANSIENT);if(write_statement(s,q)<0){result=-1;goto done;}}
    *out=text_query(s,"SELECT json_object('week_id',week_id,'catalog_id',catalog_id,'selected_at_utc',selected_at,'banner_ids',json(banner_ids)) FROM weekly_rotations WHERE profile=:p",NULL,NULL);
    if(!*out)result=error(s,"SCHEDULE_DATABASE_ERROR");
done:sqlite3_free(id);sqlite3_free(doc);return result;
}

typedef struct {char *definition_id;int64_t version;} exclusive_reward;
typedef struct {char *id;int zone,tie_policy;int64_t version;uint64_t seed;od_tournament_competitor *competitors;size_t competitor_count;od_rank_reward_tier *tiers;exclusive_reward **exclusive;size_t tier_count;int64_t *map_ids,*map_points;size_t map_count;} tournament;
static void free_tournament(tournament *t) {
    size_t i,j;sqlite3_free(t->id);
    if(t->competitors)for(i=0;i<t->competitor_count;i++)sqlite3_free((void *)t->competitors[i].competitor_id);
    if(t->tiers)for(i=0;i<t->tier_count;i++){if(t->tiers[i].rewards)for(j=0;j<t->tiers[i].reward_count;j++)sqlite3_free((void *)t->tiers[i].rewards[j].resource_id);free((void *)t->tiers[i].rewards);
        if(t->exclusive&&t->exclusive[i]){for(j=0;j<t->tiers[i].reward_count;j++)sqlite3_free(t->exclusive[i][j].definition_id);free(t->exclusive[i]);}}
    free(t->competitors);free(t->tiers);free(t->exclusive);free(t->map_ids);free(t->map_points);memset(t,0,sizeof(*t));
}
static const char *reward_table(const char *kind,od_reward_category *category) {
    *category=OD_REWARD_ITEM;
    if(!strcmp(kind,"stone")){*category=OD_REWARD_DRAGON_STONE;return "";}
    if(!strcmp(kind,"medal")){*category=OD_REWARD_MEDAL;return "awakening_items";}
    if(!strcmp(kind,"training"))return "training_items";
    if(!strcmp(kind,"support"))return "support_items";
    if(!strcmp(kind,"equipment"))return "equipment_skill_items";
    if(!strcmp(kind,"act"))return "act_items";
    return NULL;
}
static int load_tournament_document(store *s,const char *doc,tournament *t) {
    int64_t value;int n,i,j;char path[96],*seed=NULL;memset(t,0,sizeof(*t));
    t->id=string_arg(s,doc,"$.tournament_id");seed=string_arg(s,doc,"$.seed");
    if(!id_ok(t->id)||!seed_value(seed,&t->seed)||integer(s,doc,"$.version",1,STORE_LIMIT,&t->version)<0||integer(s,doc,"$.zone",0,1,&value)<0){goto bad;}
    sqlite3_free(seed);seed=NULL;t->zone=(int)value;
    if(integer(s,doc,"$.tie_policy",0,1,&value)<0){goto bad;}t->tie_policy=(int)value;
    if(array_count(s,doc,"$.competitors",1,512,&n)<0){goto bad;}t->competitor_count=(size_t)n;t->competitors=calloc((size_t)n,sizeof(*t->competitors));if(!t->competitors){goto bad;}
    for(i=0;i<n;i++){
        char *row;snprintf(path,sizeof(path),"$.competitors[%d]",i);row=json_arg(s,doc,path);if(!row){goto bad;}
        t->competitors[i].competitor_id=string_arg(s,row,"$.id");
        if(!id_ok(t->competitors[i].competitor_id)||integer(s,row,"$.points_per_hour",1,UINT32_MAX,&value)<0){sqlite3_free(row);goto bad;}t->competitors[i].points_per_hour=(uint32_t)value;
        if(integer(s,row,"$.extra_points_per_hour_max",0,UINT32_MAX,&value)<0){sqlite3_free(row);goto bad;}t->competitors[i].extra_points_per_hour_max=(uint32_t)value;sqlite3_free(row);
        for(j=0;j<i;j++)if(!strcmp(t->competitors[i].competitor_id,t->competitors[j].competitor_id)){goto bad;}
    }
    if(array_count(s,doc,"$.maps",1,1024,&n)<0){goto bad;}t->map_count=(size_t)n;t->map_ids=calloc((size_t)n,sizeof(*t->map_ids));t->map_points=calloc((size_t)n,sizeof(*t->map_points));if(!t->map_ids||!t->map_points){goto bad;}
    for(i=0;i<n;i++){
        char *row;snprintf(path,sizeof(path),"$.maps[%d]",i);row=json_arg(s,doc,path);if(!row){goto bad;}
        if(integer(s,row,"$.map_id",1,STORE_LIMIT,&t->map_ids[i])<0||!master_has(s,"sugoroku_maps",t->map_ids[i])||integer(s,row,"$.points",1,STORE_LIMIT,&t->map_points[i])<0){sqlite3_free(row);goto bad;}sqlite3_free(row);
        for(j=0;j<i;j++)if(t->map_ids[j]==t->map_ids[i]){goto bad;}
    }
    if(array_count(s,doc,"$.reward_tiers",1,128,&n)<0){goto bad;}t->tier_count=(size_t)n;t->tiers=calloc((size_t)n,sizeof(*t->tiers));t->exclusive=calloc((size_t)n,sizeof(*t->exclusive));if(!t->tiers||!t->exclusive){goto bad;}
    for(i=0;i<n;i++){
        char *row;int count;od_rank_reward *rewards;snprintf(path,sizeof(path),"$.reward_tiers[%d]",i);row=json_arg(s,doc,path);if(!row){goto bad;}
        if(integer(s,row,"$.from_rank",1,UINT32_MAX,&value)<0){sqlite3_free(row);goto bad;}t->tiers[i].rank_from=(uint32_t)value;
        if(integer(s,row,"$.to_rank",t->tiers[i].rank_from,UINT32_MAX,&value)<0||array_count(s,row,"$.rewards",1,64,&count)<0){sqlite3_free(row);goto bad;}t->tiers[i].rank_to=(uint32_t)value;
        t->tiers[i].reward_count=(size_t)count;rewards=calloc((size_t)count,sizeof(*rewards));t->tiers[i].rewards=rewards;t->exclusive[i]=calloc((size_t)count,sizeof(**t->exclusive));if(!rewards||!t->exclusive[i]){sqlite3_free(row);goto bad;}
        int64_t exclusive_total=0;
        for(j=0;j<count;j++){
            char *reward,*kind;const char *table;int64_t id;snprintf(path,sizeof(path),"$.rewards[%d]",j);reward=json_arg(s,row,path);if(!reward){sqlite3_free(row);goto bad;}
            kind=string_arg(s,reward,"$.kind");
            if(kind&&!strcmp(kind,"tournament_created")){
                char *category=string_arg(s,reward,"$.multiplier_category"),*definition=NULL;
                exclusive_reward *ref=&t->exclusive[i][j];ref->definition_id=string_arg(s,reward,"$.definition_id");
                int valid=id_ok(ref->definition_id)&&category&&!strcmp(category,"item")&&integer(s,reward,"$.definition_version",1,STORE_LIMIT,&ref->version)==0&&integer(s,reward,"$.quantity",1,333,&rewards[j].base_quantity)==0;
                if(valid){definition=exclusive_document(s,ref->definition_id,ref->version);}valid=valid&&definition&&!exclusive_collision(s,ref->definition_id);sqlite3_free(definition);sqlite3_free(category);
                if(valid){exclusive_total+=rewards[j].base_quantity*3;valid=exclusive_total<=1000;for(int k=0;k<j;k++)if(t->exclusive[i][k].definition_id&&!strcmp(t->exclusive[i][k].definition_id,ref->definition_id)&&t->exclusive[i][k].version==ref->version)valid=0;}
                if(!valid){sqlite3_free(kind);sqlite3_free(reward);sqlite3_free(row);goto bad;}
                rewards[j].category=OD_REWARD_ITEM;rewards[j].resource_id=sqlite3_mprintf("exclusive:%d:%d",i,j);sqlite3_free(kind);sqlite3_free(reward);if(!rewards[j].resource_id){sqlite3_free(row);goto bad;}continue;
            }
            table=kind?reward_table(kind,&rewards[j].category):NULL;
            if(!table||integer(s,reward,"$.id",0,STORE_LIMIT,&id)<0||(!table[0]&&id!=0)||(table[0]&&!master_has(s,table,id))||
                integer(s,reward,"$.quantity",1,STORE_LIMIT,&rewards[j].base_quantity)<0){sqlite3_free(kind);sqlite3_free(reward);sqlite3_free(row);goto bad;}
            rewards[j].resource_id=sqlite3_mprintf("%s:%lld",kind,(long long)id);sqlite3_free(kind);sqlite3_free(reward);if(!rewards[j].resource_id){sqlite3_free(row);goto bad;}
        }
        sqlite3_free(row);
        for(j=0;j<i;j++)if(t->tiers[i].rank_from<=t->tiers[j].rank_to&&t->tiers[i].rank_to>=t->tiers[j].rank_from){goto bad;}
    }
    return 0;
bad:sqlite3_free(seed);free_tournament(t);return error(s,"TOURNAMENT_INVALID_CONFIG");
}

static int install_tournament(store *s,const char *args,char **out) {
    tournament t;char *existing,*canonical;sqlite3_stmt *q;int result=0;if(load_tournament_document(s,args,&t)<0){return -1;}
    q=statement(s,"SELECT document FROM tournament_configs WHERE profile=:p AND id=:x AND version=?5",NULL,t.id);existing=NULL;
    if(!q){free_tournament(&t);return -1;}sqlite3_bind_int64(q,5,t.version);if(sqlite3_step(q)==SQLITE_ROW)existing=sqlite3_mprintf("%s",sqlite3_column_text(q,0));sqlite3_finalize(q);canonical=text_query(s,"SELECT json(:a)",args,NULL);
    if(existing)result=canonical&&od_json_semantic_equal(s->db,existing,canonical)==1?1:error(s,"TOURNAMENT_CONFIG_CONFLICT");
    else{q=statement(s,"INSERT INTO tournament_configs VALUES(:p,:x,?5,?6,json(:a))",args,t.id);if(q){sqlite3_bind_int64(q,5,t.version);sqlite3_bind_int(q,6,t.zone);}result=write_statement(s,q);}
    if(result>=0)*out=text_query(s,"SELECT json_object('tournament_id',:x,'version',json_extract(:a,'$.version'),'configured',json('true'))",args,t.id);
    sqlite3_free(existing);sqlite3_free(canonical);free_tournament(&t);return result>=0&&!*out?error(s,"SCHEDULE_NO_MEMORY"):result;
}

static int read_state(store *s,const char *doc,od_tournament_state *state) {
    char *seed=string_arg(s,doc,"$.seed"),*hash=string_arg(s,doc,"$.competitor_hash");int64_t value;int ok=0;memset(state,0,sizeof(*state));
    if(!seed_value(seed,&state->seed)||!seed_value(hash,&state->competitor_hash)||integer(s,doc,"$.weekend_id",1,UINT32_MAX,&value)<0){goto done;}state->weekend_id=(uint32_t)value;
    if(integer(s,doc,"$.policy_version",1,STORE_LIMIT,&value)<0){goto done;}state->policy_version=(uint64_t)value;
    if(integer(s,doc,"$.last_update_utc",0,INT64_C(253402300799),&state->last_update_utc)<0||integer(s,doc,"$.points",0,STORE_LIMIT,&state->points)<0){goto done;}
    ok=1;
done:sqlite3_free(seed);sqlite3_free(hash);return ok?0:error(s,"TOURNAMENT_INVALID_STATE");
}

static int tournament_period(store *s,const char *args,const tournament *t,int claim,
                             od_schedule_period *p,int64_t *clock,int64_t *player_points) {
    int64_t now,weekend_id;sqlite3_stmt *q;int found=0;
    if(integer(s,args,"$.now_utc",0,INT64_C(253402300799),&now)<0){return -1;}
    if(claim){
        if(integer(s,args,"$.weekend_id",1,UINT32_MAX,&weekend_id)<0){return -1;}
        q=statement(s,"SELECT start_utc,end_utc,observed_utc,player_points,config_version FROM tournament_periods WHERE profile=:p AND tournament_id=:x AND weekend_id=?5",NULL,t->id);
        if(!q){return -1;}sqlite3_bind_int64(q,5,weekend_id);
        if(sqlite3_step(q)==SQLITE_ROW){int64_t start=sqlite3_column_int64(q,0);if(period(s,start,t->zone,p)<0){sqlite3_finalize(q);return -1;}
            if(p->weekend_id!=(uint32_t)weekend_id||p->weekend_end_utc!=sqlite3_column_int64(q,1)||sqlite3_column_int64(q,4)!=t->version){sqlite3_finalize(q);return error(s,"TOURNAMENT_PERIOD_CONFLICT");}
            *clock=now>sqlite3_column_int64(q,2)?now:sqlite3_column_int64(q,2);*player_points=sqlite3_column_int64(q,3);found=1;}
        sqlite3_finalize(q);if(!found)return error(s,"TOURNAMENT_PERIOD_NOT_FOUND");
    }else{
        if(period(s,now,t->zone,p)<0){return -1;}
        if(!p->weekend_active)return error(s,"TOURNAMENT_NOT_ACTIVE");
        q=statement(s,"SELECT observed_utc,player_points,config_version FROM tournament_periods WHERE profile=:p AND tournament_id=:x AND weekend_id=?5",NULL,t->id);
        if(!q){return -1;}sqlite3_bind_int64(q,5,p->weekend_id);
        if(sqlite3_step(q)==SQLITE_ROW){if(sqlite3_column_int64(q,2)!=t->version){sqlite3_finalize(q);return error(s,"TOURNAMENT_PERIOD_CONFLICT");}
            *clock=now>sqlite3_column_int64(q,0)?now:sqlite3_column_int64(q,0);*player_points=sqlite3_column_int64(q,1);found=1;}
        sqlite3_finalize(q);
        if(!found){q=statement(s,"INSERT INTO tournament_periods VALUES(:p,:x,?5,?6,?7,?8,?9,0)",NULL,t->id);if(!q){return -1;}
            sqlite3_bind_int64(q,5,p->weekend_id);sqlite3_bind_int64(q,6,t->version);sqlite3_bind_int64(q,7,p->weekend_start_utc);sqlite3_bind_int64(q,8,p->weekend_end_utc);sqlite3_bind_int64(q,9,now);
            if(write_statement(s,q)<0){return -1;}*clock=now;*player_points=0;}
    }
    if(*clock>p->weekend_end_utc)*clock=p->weekend_end_utc;
    q=statement(s,"UPDATE tournament_periods SET observed_utc=?5 WHERE profile=:p AND tournament_id=:x AND weekend_id=?6",NULL,t->id);if(!q){return -1;}
    sqlite3_bind_int64(q,5,*clock);sqlite3_bind_int64(q,6,p->weekend_id);return write_statement(s,q);
}

static int advance_competitors(store *s,const tournament *t,const od_schedule_period *p,int64_t clock,int64_t **scores) {
    size_t i;*scores=calloc(t->competitor_count,sizeof(**scores));if(!*scores)return error(s,"SCHEDULE_NO_MEMORY");
    for(i=0;i<t->competitor_count;i++){
        sqlite3_stmt *q=statement(s,"SELECT state FROM tournament_ai WHERE profile=:p AND tournament_id=:x AND weekend_id=?5 AND competitor_id=?6",NULL,t->id);
        char *doc=NULL,seed[17],hash[17];od_tournament_state prior={0},next;od_schedule_status status;
        if(!q){goto bad;}sqlite3_bind_int64(q,5,p->weekend_id);sqlite3_bind_text(q,6,t->competitors[i].competitor_id,-1,SQLITE_TRANSIENT);
        if(sqlite3_step(q)==SQLITE_ROW){doc=sqlite3_mprintf("%s",sqlite3_column_text(q,0));}sqlite3_finalize(q);
        if(doc&&read_state(s,doc,&prior)<0){sqlite3_free(doc);goto bad;}sqlite3_free(doc);
        status=od_tournament_advance(p,(uint64_t)t->version,t->seed,&t->competitors[i],clock,&prior,&next);
        if(status!=OD_SCHEDULE_OK||next.points>STORE_LIMIT){error(s,status==OD_SCHEDULE_OK?"TOURNAMENT_POINTS_OVERFLOW":od_schedule_status_name(status));goto bad;}
        snprintf(seed,sizeof(seed),"%016llx",(unsigned long long)next.seed);snprintf(hash,sizeof(hash),"%016llx",(unsigned long long)next.competitor_hash);
        q=statement(s,"INSERT INTO tournament_ai VALUES(:p,:x,?5,?6,json_object('weekend_id',?5,'policy_version',?7,'seed',?8,'competitor_hash',?9,'last_update_utc',?10,'points',?11)) ON CONFLICT(profile,tournament_id,weekend_id,competitor_id) DO UPDATE SET state=excluded.state",NULL,t->id);if(!q){goto bad;}
        sqlite3_bind_int64(q,5,p->weekend_id);sqlite3_bind_text(q,6,t->competitors[i].competitor_id,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(q,7,t->version);sqlite3_bind_text(q,8,seed,-1,SQLITE_TRANSIENT);sqlite3_bind_text(q,9,hash,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(q,10,next.last_update_utc);sqlite3_bind_int64(q,11,next.points);
        if(write_statement(s,q)<0){goto bad;}(*scores)[i]=next.points;
    }
    return 0;
bad:free(*scores);*scores=NULL;return -1;
}

static char *tournament_snapshot(store *s,const tournament *t,const od_schedule_period *p,uint32_t rank) {
    sqlite3_stmt *q=statement(s,"SELECT json_object('tournament_id',:x,'version',?5,'weekend_id',?6,'start_utc',start_utc,'end_utc',end_utc,'observed_utc',observed_utc,'active',json(CASE WHEN observed_utc<end_utc THEN 'true' ELSE 'false' END),'player_points',player_points,'rank',?7,'simulated_competitors',json(COALESCE((SELECT json_group_array(json_object('id',competitor_id,'points',json_extract(state,'$.points'))) FROM (SELECT * FROM tournament_ai WHERE profile=:p AND tournament_id=:x AND weekend_id=?6 ORDER BY competitor_id)),'[]')),'claimed',json(CASE WHEN EXISTS(SELECT 1 FROM tournament_claims WHERE profile=:p AND tournament_id=:x AND weekend_id=?6) THEN 'true' ELSE 'false' END)) FROM tournament_periods WHERE profile=:p AND tournament_id=:x AND weekend_id=?6",NULL,t->id);
    char *out=NULL;if(!q){return NULL;}sqlite3_bind_int64(q,5,t->version);sqlite3_bind_int64(q,6,p->weekend_id);sqlite3_bind_int64(q,7,rank);
    if(sqlite3_step(q)==SQLITE_ROW){out=sqlite3_mprintf("%s",sqlite3_column_text(q,0));}sqlite3_finalize(q);return out;
}

static const exclusive_reward *exclusive_ref(const tournament *t,const char *resource,size_t *ordinal){
    unsigned tier,item;char extra;if(sscanf(resource,"exclusive:%u:%u%c",&tier,&item,&extra)!=2||tier>=t->tier_count||item>=t->tiers[tier].reward_count){return NULL;}
    if(!t->exclusive[tier][item].definition_id){return NULL;}if(ordinal){*ordinal=item;}return &t->exclusive[tier][item];
}

static int grant_exclusive(store *s,const tournament *t,const od_schedule_period *p,const exclusive_reward *ref,size_t ordinal,int64_t quantity){
    char *doc=exclusive_document(s,ref->definition_id,ref->version),*rarity=NULL;od_created_card_defaults defaults;int64_t master=0;int result=-1;
    if(!doc||!s->validate_definition||!s->grant_definition||s->validate_definition(s->definition_context,doc)<0||integer(s,doc,"$.source.master_id",1,STORE_LIMIT,&master)<0){error(s,"TOURNAMENT_EXCLUSIVE_DEFINITION_INVALID");goto done;}
    rarity=string_arg(s,doc,"$.rarity");od_summon_rarity r=rarity&&!strcmp(rarity,"UR")?OD_RARITY_UR:rarity&&!strcmp(rarity,"LR")?OD_RARITY_LR:rarity&&!strcmp(rarity,"SLR")?OD_RARITY_SLR:rarity&&!strcmp(rarity,"GR")?OD_RARITY_GR:(od_summon_rarity)-1;
    if(quantity<1||quantity>1000||od_created_instance_defaults(r,1,&defaults)!=OD_PROGRESSION_OK){error(s,"TOURNAMENT_EXCLUSIVE_DEFINITION_INVALID");goto done;}
    for(int64_t unit=0;unit<quantity;unit++){
        sqlite3_int64 instance=0;sqlite3_stmt *q;
        if(s->grant_definition(s->definition_context,doc,&instance)<0||instance<=0){error(s,"TOURNAMENT_EXCLUSIVE_GRANT_FAILED");goto done;}
        q=statement(s,"SELECT EXISTS(SELECT 1 FROM owned_cards c WHERE c.id=?5 AND c.profile=:p AND c.master_id=?6 AND c.level=1 AND c.sa_level=1 AND json(c.potential)='{}') AND NOT EXISTS(SELECT 1 FROM owned_definitions WHERE instance_id=?5) AND NOT EXISTS(SELECT 1 FROM tournament_exclusive_owned WHERE instance_id=?5)",NULL,NULL);
        if(!q){goto done;}sqlite3_bind_int64(q,5,instance);sqlite3_bind_int64(q,6,master);int valid=sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_int(q,0);sqlite3_finalize(q);
        if(!valid){error(s,"TOURNAMENT_EXCLUSIVE_GRANT_FAILED");goto done;}
        q=statement(s,"INSERT INTO tournament_exclusive_owned(instance_id,profile,definition_id,version,tournament_id,weekend_id,reward_ordinal,unit_ordinal,exclusive_kind,exclusive_always_on) VALUES(?6,:p,:x,?5,?7,?8,?9,?10,?11,?12)",NULL,ref->definition_id);
        if(!q){goto done;}sqlite3_bind_int64(q,5,ref->version);sqlite3_bind_int64(q,6,instance);sqlite3_bind_text(q,7,t->id,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(q,8,p->weekend_id);sqlite3_bind_int64(q,9,(sqlite3_int64)ordinal);sqlite3_bind_int64(q,10,unit);sqlite3_bind_int(q,11,defaults.exclusive_kind);sqlite3_bind_int(q,12,defaults.exclusive_always_on);
        if(write_statement(s,q)<0){goto done;}
    }
    result=0;
done:sqlite3_free(doc);sqlite3_free(rarity);return result;
}

static char *claim_receipt(store *s,const tournament *t,const od_schedule_period *p,uint32_t rank,const od_tournament_reward_plan *plan,int64_t revision,int64_t host_now){
    char *snapshot=tournament_snapshot(s,t,p,rank),*rewards,*result=NULL;sqlite3_stmt *q;sqlite3_str *array;
    if(!snapshot){return NULL;}array=sqlite3_str_new(s->db);sqlite3_str_appendall(array,"[");
    for(size_t i=0;i<plan->reward_count;i++){
        const exclusive_reward *ref=exclusive_ref(t,plan->rewards[i].resource_id,NULL);
        if(ref){sqlite3_str_appendf(array,"%s{\"kind\":\"tournament_created\",\"definition_id\":\"%s\",\"definition_version\":%lld,\"quantity\":%lld}",i?",":"",ref->definition_id,(long long)ref->version,(long long)plan->rewards[i].quantity);continue;}
        const char *colon=strchr(plan->rewards[i].resource_id,':');char kind[32];
        if(!colon||(size_t)(colon-plan->rewards[i].resource_id)>=sizeof(kind)){sqlite3_free(snapshot);char *discard=sqlite3_str_finish(array);sqlite3_free(discard);return NULL;}
        memcpy(kind,plan->rewards[i].resource_id,(size_t)(colon-plan->rewards[i].resource_id));kind[colon-plan->rewards[i].resource_id]=0;
        sqlite3_str_appendf(array,"%s{\"kind\":\"%s\",\"id\":%lld,\"quantity\":%lld}",i?",":"",kind,(long long)strtoll(colon+1,NULL,10),(long long)plan->rewards[i].quantity);
    }
    sqlite3_str_appendall(array,"]");rewards=sqlite3_str_finish(array);if(!rewards){sqlite3_free(snapshot);return NULL;}
    q=statement(s,"SELECT json_set(:a,'$.claimed',json('true'),'$.rewards',json(?5),'$.revision',?6)",snapshot,NULL);
    if(q){sqlite3_bind_text(q,5,rewards,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(q,6,revision);if(sqlite3_step(q)==SQLITE_ROW)result=sqlite3_mprintf("%s",sqlite3_column_text(q,0));sqlite3_finalize(q);}
    sqlite3_free(snapshot);sqlite3_free(rewards);
    if(result&&host_now>=0){q=statement(s,"SELECT json_set(:a,'$.host_now_utc',?5)",result,NULL);char *next=NULL;if(q){sqlite3_bind_int64(q,5,host_now);if(sqlite3_step(q)==SQLITE_ROW)next=sqlite3_mprintf("%s",sqlite3_column_text(q,0));sqlite3_finalize(q);}sqlite3_free(result);result=next;}
    int has_exclusive=exclusive_schema(s->db);
    if(result&&has_exclusive<0){sqlite3_free(result);return NULL;}
    if(result&&has_exclusive){q=statement(s,"SELECT json_group_array(json_object('instance_id',instance_id,'definition_id',definition_id,'definition_version',version,'reward_ordinal',reward_ordinal,'unit_ordinal',unit_ordinal)) FROM (SELECT * FROM tournament_exclusive_owned WHERE profile=:p AND tournament_id=:x AND weekend_id=?5 ORDER BY reward_ordinal,unit_ordinal)",NULL,t->id);
        char *owned=NULL;if(q){sqlite3_bind_int64(q,5,p->weekend_id);if(sqlite3_step(q)==SQLITE_ROW)owned=sqlite3_mprintf("%s",sqlite3_column_text(q,0));sqlite3_finalize(q);}
        if(!owned){sqlite3_free(result);return NULL;}
        if(owned&&strcmp(owned,"[]")){char *next=NULL;q=statement(s,"SELECT json_set(:a,'$.created_cards',json(?5))",result,NULL);if(q){sqlite3_bind_text(q,5,owned,-1,SQLITE_TRANSIENT);if(sqlite3_step(q)==SQLITE_ROW)next=sqlite3_mprintf("%s",sqlite3_column_text(q,0));sqlite3_finalize(q);}sqlite3_free(result);result=next;}
        sqlite3_free(owned);
    }
    return result;
}

static int tournament_operation(store *s,const char *op,const char *args,od_schedule_credit_fn credit,void *credit_ctx,char **out) {
    char *id=string_arg(s,args,"$.tournament_id"),*doc=NULL,*run=NULL;int64_t version,clock,points,*scores=NULL;uint32_t rank;
    tournament t;od_schedule_period p;sqlite3_stmt *q;int result=-1,loaded=0,claim=!strcmp(op,"tournament.claim");
    if(!id_ok(id)||integer(s,args,"$.version",1,STORE_LIMIT,&version)<0){goto done;}
    q=statement(s,"SELECT document FROM tournament_configs WHERE profile=:p AND id=:x AND version=?5",NULL,id);if(!q){goto done;}sqlite3_bind_int64(q,5,version);if(sqlite3_step(q)==SQLITE_ROW){doc=sqlite3_mprintf("%s",sqlite3_column_text(q,0));}sqlite3_finalize(q);
    if(!doc||load_tournament_document(s,doc,&t)<0){goto done;}loaded=1;
    if(claim){
        int64_t weekend;if(integer(s,args,"$.weekend_id",1,UINT32_MAX,&weekend)<0){goto done;}
        q=statement(s,"SELECT result FROM tournament_claims WHERE profile=:p AND tournament_id=:x AND weekend_id=?5",NULL,id);if(!q){goto done;}sqlite3_bind_int64(q,5,weekend);
        if(sqlite3_step(q)==SQLITE_ROW){*out=sqlite3_mprintf("%s",sqlite3_column_text(q,0));}sqlite3_finalize(q);if(*out){result=1;goto done;}
    }
    if(tournament_period(s,args,&t,claim,&p,&clock,&points)<0){goto done;}
    if(!strcmp(op,"tournament.enroll_run")||!strcmp(op,"tournament.record_run")){
        int finished=!strcmp(op,"tournament.record_run"),exists=0,credited=0;int64_t map=0,earned=0;uint32_t enrolled_week=0;char *enrolled_tournament=NULL,*state=NULL,*outcome=NULL;
        run=string_arg(s,args,"$.run_id");if(!id_ok(run)){goto done;}
        q=statement(s,"SELECT map_id,state,outcome FROM runs WHERE profile=:p AND id=:x",NULL,run);if(!q){goto done;}
        if(sqlite3_step(q)==SQLITE_ROW){map=sqlite3_column_int64(q,0);state=sqlite3_mprintf("%s",sqlite3_column_text(q,1));if(sqlite3_column_type(q,2)!=SQLITE_NULL)outcome=sqlite3_mprintf("%s",sqlite3_column_text(q,2));}sqlite3_finalize(q);
        q=statement(s,"SELECT tournament_id,weekend_id,map_id,points,credited FROM tournament_runs WHERE profile=:p AND run_id=:x",NULL,run);if(!q){sqlite3_free(state);sqlite3_free(outcome);goto done;}
        if(sqlite3_step(q)==SQLITE_ROW){enrolled_tournament=sqlite3_mprintf("%s",sqlite3_column_text(q,0));enrolled_week=(uint32_t)sqlite3_column_int64(q,1);if(map!=sqlite3_column_int64(q,2))map=0;earned=sqlite3_column_int64(q,3);credited=sqlite3_column_int(q,4);exists=1;}sqlite3_finalize(q);
        int valid=state&&(!finished?!strcmp(state,"started"):!strcmp(state,"finished")&&outcome&&!strcmp(outcome,"clear"));
        sqlite3_free(state);sqlite3_free(outcome);
        if(exists&&(!enrolled_tournament||strcmp(enrolled_tournament,id)||enrolled_week!=p.weekend_id)){sqlite3_free(enrolled_tournament);error(s,"TOURNAMENT_RUN_CONFLICT");goto done;}sqlite3_free(enrolled_tournament);
        if(!valid||!map||(finished&&!exists)){error(s,"TOURNAMENT_RUN_NOT_ELIGIBLE");goto done;}
        if((finished&&credited)||(!finished&&exists)){result=0;goto snapshot;}
        if(clock>=p.weekend_end_utc){error(s,"TOURNAMENT_CLOSED");goto done;}
        if(!finished){
            size_t i;for(i=0;i<t.map_count;i++)if(t.map_ids[i]==map){earned=t.map_points[i];break;}
            if(i==t.map_count){error(s,"TOURNAMENT_MAP_NOT_ALLOWED");goto done;}
            q=statement(s,"INSERT INTO tournament_runs VALUES(:p,:x,?5,?6,?7,?8,0)",NULL,run);if(!q){goto done;}sqlite3_bind_text(q,5,id,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(q,6,p.weekend_id);sqlite3_bind_int64(q,7,map);sqlite3_bind_int64(q,8,earned);if(write_statement(s,q)<0){goto done;}
        }else{
            q=statement(s,"UPDATE tournament_periods SET player_points=player_points+?5 WHERE profile=:p AND tournament_id=:x AND weekend_id=?6 AND player_points<=9007199254740991-?5",NULL,id);if(!q){goto done;}sqlite3_bind_int64(q,5,earned);sqlite3_bind_int64(q,6,p.weekend_id);
            if(write_statement(s,q)<0||sqlite3_changes(s->db)!=1){error(s,"TOURNAMENT_POINTS_OVERFLOW");goto done;}points+=earned;
            q=statement(s,"UPDATE tournament_runs SET credited=1 WHERE profile=:p AND run_id=:x AND credited=0",NULL,run);if(write_statement(s,q)<0){goto done;}
        }
    }
    result=0;
snapshot:
    if(advance_competitors(s,&t,&p,clock,&scores)<0){result=-1;goto done;}
    if(od_tournament_rank(points,scores,t.competitor_count,(od_rank_tie_policy)t.tie_policy,&rank)!=OD_SCHEDULE_OK){error(s,"TOURNAMENT_INVALID_RANK");result=-1;goto done;}
    if(claim){
        od_tournament_reward_plan plan;od_schedule_status status=od_tournament_rewards(&p,clock,rank,t.tiers,t.tier_count,0,&plan);
        if(status!=OD_SCHEDULE_OK||!credit){error(s,status==OD_SCHEDULE_OK?"SCHEDULE_CREDIT_UNAVAILABLE":od_schedule_status_name(status));result=-1;goto done;}
        for(size_t i=0;i<plan.reward_count;i++){
            size_t ordinal=0;const exclusive_reward *ref=exclusive_ref(&t,plan.rewards[i].resource_id,&ordinal);
            if(ref){if(grant_exclusive(s,&t,&p,ref,ordinal,plan.rewards[i].quantity)<0){result=-1;goto done;}continue;}
            char kind[32];const char *colon=strchr(plan.rewards[i].resource_id,':');if(!colon||(size_t)(colon-plan.rewards[i].resource_id)>=sizeof(kind)){error(s,"TOURNAMENT_INVALID_REWARD");result=-1;goto done;}
            memcpy(kind,plan.rewards[i].resource_id,(size_t)(colon-plan.rewards[i].resource_id));kind[colon-plan.rewards[i].resource_id]=0;
            sqlite3_int64 resource=(sqlite3_int64)strtoll(colon+1,NULL,10);
            if(plan.rewards[i].quantity>STORE_LIMIT||credit(credit_ctx,kind,resource,plan.rewards[i].quantity)<0){error(s,"TOURNAMENT_CREDIT_FAILED");result=-1;goto done;}
        }
        int64_t revision=0;q=statement(s,"SELECT revision FROM profiles WHERE id=:p",NULL,NULL);if(!q){result=-1;goto done;}
        if(sqlite3_step(q)==SQLITE_ROW)revision=sqlite3_column_int64(q,0);else revision=STORE_LIMIT;sqlite3_finalize(q);
        if(revision>=STORE_LIMIT){error(s,"REVISION_OVERFLOW");result=-1;goto done;}
        int64_t host_now=0;if(integer(s,args,"$.now_utc",0,INT64_C(253402300799),&host_now)<0){result=-1;goto done;}
        *out=claim_receipt(s,&t,&p,rank,&plan,revision+1,host_now);if(!*out){result=-1;goto done;}
        q=statement(s,"INSERT INTO tournament_claims VALUES(:p,:x,?5,json(:a))",*out,id);if(!q){result=-1;goto done;}sqlite3_bind_int64(q,5,p.weekend_id);
        if(write_statement(s,q)<0){result=-1;goto done;}
    }else *out=tournament_snapshot(s,&t,&p,rank);
    if(!*out){error(s,"SCHEDULE_NO_MEMORY");result=-1;}
done:if(result<0){sqlite3_free(*out);*out=NULL;}free(scores);if(loaded)free_tournament(&t);sqlite3_free(id);sqlite3_free(doc);sqlite3_free(run);return result;
}

typedef struct {char *id;int64_t version;int zone;unsigned multi_count;od_elder_kai_entry *pool;int64_t *masters;size_t count;} elder_config;
static void free_elder(elder_config *e){size_t i;sqlite3_free(e->id);if(e->pool)for(i=0;i<e->count;i++)sqlite3_free((void *)e->pool[i].definition_id);free(e->pool);free(e->masters);memset(e,0,sizeof(*e));}
static int load_elder_document(store *s,const char *doc,elder_config *e){
    int64_t value;int n,i;char path[64];uint64_t weights=0;memset(e,0,sizeof(*e));e->id=string_arg(s,doc,"$.banner_id");
    if(!id_ok(e->id)||integer(s,doc,"$.version",1,STORE_LIMIT,&e->version)<0||integer(s,doc,"$.zone",0,1,&value)<0){goto bad;}e->zone=(int)value;
    if(integer(s,doc,"$.multi_count",2,OD_SUMMON_MAX_MULTI,&value)<0||array_count(s,doc,"$.pool",1,4096,&n)<0){goto bad;}e->multi_count=(unsigned)value;e->count=(size_t)n;
    e->pool=calloc(e->count,sizeof(*e->pool));e->masters=calloc(e->count,sizeof(*e->masters));if(!e->pool||!e->masters){goto bad;}
    for(i=0;i<n;i++){
        char *row;int verified;snprintf(path,sizeof(path),"$.pool[%d]",i);row=json_arg(s,doc,path);if(!row){goto bad;}
        if(integer(s,row,"$.master_id",1,STORE_LIMIT,&e->masters[i])<0||!master_has(s,"cards",e->masters[i])||boolean(s,row,"$.verified_elder_kai",&verified)<0||!verified||
            integer(s,row,"$.super_attack_levels",1,1,&value)<0){sqlite3_free(row);goto bad;}
        e->pool[i].definition_id=sqlite3_mprintf("master:%lld",(long long)e->masters[i]);e->pool[i].verified_elder_kai=1;e->pool[i].super_attack_levels=1;
        if(integer(s,row,"$.weight_ppm",1,OD_SUMMON_WEIGHT_TOTAL,&value)<0){sqlite3_free(row);goto bad;}e->pool[i].weight_ppm=(uint32_t)value;weights+=(uint64_t)value;sqlite3_free(row);
        if(!e->pool[i].definition_id){goto bad;}for(int j=0;j<i;j++)if(e->masters[i]==e->masters[j]){goto bad;}
    }
    if(weights!=OD_SUMMON_WEIGHT_TOTAL){goto bad;}return 0;
bad:free_elder(e);return error(s,"ELDER_KAI_INVALID_CONFIG");
}
static int install_elder(store *s,const char *args,char **out){
    elder_config e;sqlite3_stmt *q;char *existing=NULL,*canonical;int result=0;if(load_elder_document(s,args,&e)<0){return -1;}
    q=statement(s,"SELECT document FROM elder_kai_configs WHERE profile=:p AND id=:x AND version=?5",NULL,e.id);if(!q){free_elder(&e);return -1;}
    sqlite3_bind_int64(q,5,e.version);if(sqlite3_step(q)==SQLITE_ROW)existing=sqlite3_mprintf("%s",sqlite3_column_text(q,0));sqlite3_finalize(q);canonical=text_query(s,"SELECT json(:a)",args,NULL);
    if(existing)result=canonical&&od_json_semantic_equal(s->db,existing,canonical)==1?1:error(s,"ELDER_KAI_CONFIG_CONFLICT");
    else{q=statement(s,"INSERT INTO elder_kai_configs VALUES(:p,:x,?5,?6,json(:a))",args,e.id);if(q){sqlite3_bind_int64(q,5,e.version);sqlite3_bind_int(q,6,e.zone);}result=write_statement(s,q);}
    if(result>=0)*out=text_query(s,"SELECT json_object('banner_id',:x,'version',json_extract(:a,'$.version'),'configured',json('true'))",args,e.id);
    sqlite3_free(existing);sqlite3_free(canonical);free_elder(&e);return result>=0&&!*out?error(s,"SCHEDULE_NO_MEMORY"):result;
}
static int draw_elder(store *s,const char *args,od_schedule_credit_fn credit,void *credit_ctx,od_summon_random rng,void *rng_ctx,char **out){
    char *id=string_arg(s,args,"$.banner_id"),*doc=NULL,*kind=string_arg(s,args,"$.kind");int64_t version,now,stones=0;elder_config e;int loaded=0,result=-1;sqlite3_stmt *q;od_elder_kai_plan plan;od_schedule_period p;
    if(!id_ok(id)||!kind||(strcmp(kind,"single")&&strcmp(kind,"multi"))||!credit||integer(s,args,"$.version",1,STORE_LIMIT,&version)<0||integer(s,args,"$.now_utc",0,INT64_C(253402300799),&now)<0){goto done;}
    q=statement(s,"SELECT document FROM elder_kai_configs WHERE profile=:p AND id=:x AND version=?5",NULL,id);if(!q){goto done;}sqlite3_bind_int64(q,5,version);if(sqlite3_step(q)==SQLITE_ROW){doc=sqlite3_mprintf("%s",sqlite3_column_text(q,0));}sqlite3_finalize(q);
    if(!doc||load_elder_document(s,doc,&e)<0){goto done;}loaded=1;
    if(period(s,now,e.zone,&p)<0){goto done;}
    q=statement(s,"SELECT quantity FROM inventory WHERE profile=:p AND kind='stone' AND item_id=0",NULL,NULL);if(!q){goto done;}if(sqlite3_step(q)==SQLITE_ROW)stones=sqlite3_column_int64(q,0);sqlite3_finalize(q);
    od_schedule_status status=od_elder_kai_draw(&p,now,e.pool,e.count,e.multi_count,!strcmp(kind,"single")?OD_SUMMON_SINGLE:OD_SUMMON_MULTI,(uint64_t)stones,rng,rng_ctx,&plan);
    if(status!=OD_SCHEDULE_OK){error(s,od_schedule_status_name(status));goto done;}
    q=statement(s,"UPDATE inventory SET quantity=quantity-?5 WHERE profile=:p AND kind='stone' AND item_id=0 AND quantity>=?5",NULL,NULL);if(!q){goto done;}sqlite3_bind_int64(q,5,(sqlite3_int64)plan.stone_cost);
    if(write_statement(s,q)<0||sqlite3_changes(s->db)!=1){error(s,"INSUFFICIENT_STONES");goto done;}
    sqlite3_str *array=sqlite3_str_new(s->db);sqlite3_str_appendall(array,"[");
    for(unsigned i=0;i<plan.count;i++){
        int64_t master=e.masters[plan.pool_indexes[i]];
        if(credit(credit_ctx,"card",master,1)<0){char *discard=sqlite3_str_finish(array);sqlite3_free(discard);error(s,"ELDER_KAI_CREDIT_FAILED");goto done;}
        sqlite3_str_appendf(array,"%s%lld",i?",":"",(long long)master);
    }
    sqlite3_str_appendall(array,"]");char *ids=sqlite3_str_finish(array);if(!ids){error(s,"SCHEDULE_NO_MEMORY");goto done;}
    q=statement(s,"SELECT json_object('banner_id',:x,'version',?5,'spent_stones',?6,'master_ids',json(:a),'super_attack_levels_each',1)",ids,id);sqlite3_free(ids);if(!q){goto done;}sqlite3_bind_int64(q,5,version);sqlite3_bind_int64(q,6,(sqlite3_int64)plan.stone_cost);
    if(sqlite3_step(q)==SQLITE_ROW){*out=sqlite3_mprintf("%s",sqlite3_column_text(q,0));}sqlite3_finalize(q);result=*out?0:error(s,"SCHEDULE_NO_MEMORY");
done:if(result<0){sqlite3_free(*out);*out=NULL;}if(loaded)free_elder(&e);sqlite3_free(id);sqlite3_free(doc);sqlite3_free(kind);return result;
}

int od_schedule_store_handles(const char *op){
    static const char *ops[]={"schedule.catalog.install","schedule.rotate","tournament.configure","tournament.snapshot","tournament.enroll_run","tournament.record_run","tournament.claim","elder_kai.configure","elder_kai.draw","tournament.exclusive.register","tournament.exclusive.library"};
    if(!op){return 0;}for(size_t i=0;i<sizeof(ops)/sizeof(ops[0]);i++)if(!strcmp(op,ops[i])){return 1;}return 0;
}
int od_schedule_store_execute(sqlite3 *save,sqlite3 *master,const char *op,const char *profile,const char *args,
    od_schedule_credit_fn credit,void *credit_context,od_summon_random rng,void *rng_context,
    od_schedule_definition_validate_fn validate_definition,od_schedule_definition_grant_fn grant_definition,void *definition_context,
    char **out,const char **error_out){
    store s={save,master,profile,error_out,validate_definition,grant_definition,definition_context};int result=-1;
    if(error_out){*error_out=NULL;}if(out){*out=NULL;}
    if(!save||!master||!out||!id_ok(profile)||!args||!od_schedule_store_handles(op)||sqlite3_get_autocommit(save))return error(&s,"SCHEDULE_TRANSACTION_REQUIRED");
    sqlite3_stmt *q=statement(&s,"SELECT json_valid(:a) AND json_type(:a)='object'",args,NULL);int valid=q&&sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_int(q,0);sqlite3_finalize(q);if(!valid)return error(&s,"SCHEDULE_INVALID_ARGUMENT");
    if(!strcmp(op,"schedule.catalog.install"))result=install_catalog(&s,args,out);
    else if(!strcmp(op,"schedule.rotate"))result=rotate_catalog(&s,args,rng,rng_context,out);
    else if(!strcmp(op,"tournament.configure"))result=install_tournament(&s,args,out);
    else if(!strcmp(op,"elder_kai.configure"))result=install_elder(&s,args,out);
    else if(!strcmp(op,"elder_kai.draw"))result=draw_elder(&s,args,credit,credit_context,rng,rng_context,out);
    else if(!strcmp(op,"tournament.exclusive.register"))result=register_exclusive(&s,args,out);
    else if(!strcmp(op,"tournament.exclusive.library")){*out=exclusive_library(&s);result=*out?1:-1;}
    else result=tournament_operation(&s,op,args,credit,credit_context,out);
    if(result<0&&error_out&&!*error_out){*error_out="SCHEDULE_INVALID_ARGUMENT";}return result;
}

static int validate_rotations(store *s){
    sqlite3_stmt *q=NULL;int rc;
    if(sqlite3_prepare_v2(s->db,"SELECT r.profile,r.week_id,r.catalog_id,r.selected_at,r.banner_ids,c.document FROM weekly_rotations r JOIN schedule_catalogs c ON c.profile=r.profile AND c.id=r.catalog_id",-1,&q,NULL)!=SQLITE_OK){return 0;}
    while((rc=sqlite3_step(q))==SQLITE_ROW){
        catalog c;od_weekly_rotation prior={0},expected;char *a,*b;s->profile=(const char *)sqlite3_column_text(q,0);
        int64_t week=sqlite3_column_int64(q,1);const char *id=(const char *)sqlite3_column_text(q,2);const char *document=(const char *)sqlite3_column_text(q,5);
        if(!id_ok(s->profile)||!id_ok(id)||week<1||week>UINT32_MAX||load_catalog_document(s,document,&c)<0){sqlite3_finalize(q);return 0;}
        a=string_arg(s,(const char *)sqlite3_column_text(q,4),"$[0]");b=string_arg(s,(const char *)sqlite3_column_text(q,4),"$[1]");
        int good=id_ok(a)&&id_ok(b)&&strcmp(a,b);
        if(good){prior.week_id=(uint32_t)week;prior.selected_at_utc=sqlite3_column_int64(q,3);memcpy(prior.catalog_version,id,strlen(id)+1);memcpy(prior.banner_ids[0],a,strlen(a)+1);memcpy(prior.banner_ids[1],b,strlen(b)+1);
            good=od_schedule_rotate(c.rows,c.count,id,prior.selected_at_utc,(od_schedule_zone)c.zone,&prior,NULL,NULL,&expected)==OD_SCHEDULE_OK;}
        sqlite3_free(a);sqlite3_free(b);free_catalog(&c);if(!good){sqlite3_finalize(q);return 0;}
    }
    sqlite3_finalize(q);return rc==SQLITE_DONE;
}

static int validate_exclusive_claim(store *s,const tournament *t,const od_schedule_period *p,const od_tournament_reward_plan *plan){
    int schema=exclusive_schema(s->db);int64_t expected_total=0;sqlite3_stmt *q=NULL;
    if(schema<0){return 0;}
    for(size_t i=0;i<plan->reward_count;i++){
        const exclusive_reward *ref=exclusive_ref(t,plan->rewards[i].resource_id,NULL);int64_t expected=ref?plan->rewards[i].quantity:0;
        if(!schema){if(ref){return 0;}continue;}
        expected_total+=expected;if(expected_total>1000){return 0;}
        q=statement(s,"SELECT count(*),COALESCE(sum(definition_id=?7 AND version=?8),0),min(unit_ordinal),max(unit_ordinal) FROM tournament_exclusive_owned WHERE profile=:p AND tournament_id=:x AND weekend_id=?5 AND reward_ordinal=?6",NULL,t->id);
        if(!q){return 0;}sqlite3_bind_int64(q,5,p->weekend_id);sqlite3_bind_int64(q,6,(sqlite3_int64)i);sqlite3_bind_text(q,7,ref?ref->definition_id:"",-1,SQLITE_TRANSIENT);sqlite3_bind_int64(q,8,ref?ref->version:0);
        int good=sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_int64(q,0)==expected&&sqlite3_column_int64(q,1)==expected;
        if(good&&expected){good=sqlite3_column_int64(q,2)==0&&sqlite3_column_int64(q,3)==expected-1;}sqlite3_finalize(q);if(!good){return 0;}
    }
    if(!schema){return 1;}
    q=statement(s,"SELECT count(*) FROM tournament_exclusive_owned WHERE profile=:p AND tournament_id=:x AND weekend_id=?5",NULL,t->id);if(!q){return 0;}sqlite3_bind_int64(q,5,p->weekend_id);
    int good=sqlite3_step(q)==SQLITE_ROW&&sqlite3_column_int64(q,0)==expected_total;sqlite3_finalize(q);return good;
}

static int validate_one_period(store *s,const tournament *t,const od_schedule_period *p,int64_t observed,int64_t player_points){
    sqlite3_stmt *q=NULL;int rc;int64_t *scores=calloc(t->competitor_count,sizeof(*scores));uint32_t rank;int good=0;
    if(!scores){return 0;}
    q=statement(s,"SELECT count(*) FROM tournament_ai WHERE profile=:p AND tournament_id=:x AND weekend_id=?5",NULL,t->id);
    if(!q){good=0;goto done;}sqlite3_bind_int64(q,5,p->weekend_id);rc=sqlite3_step(q);good=rc==SQLITE_ROW&&sqlite3_column_int64(q,0)==(sqlite3_int64)t->competitor_count;sqlite3_finalize(q);q=NULL;if(!good){goto done;}
    for(size_t i=0;i<t->competitor_count;i++){
        char *doc=NULL;od_tournament_state saved,empty={0},expected;
        q=statement(s,"SELECT state FROM tournament_ai WHERE profile=:p AND tournament_id=:x AND weekend_id=?5 AND competitor_id=?6",NULL,t->id);
        if(!q){good=0;goto done;}sqlite3_bind_int64(q,5,p->weekend_id);sqlite3_bind_text(q,6,t->competitors[i].competitor_id,-1,SQLITE_TRANSIENT);if(sqlite3_step(q)==SQLITE_ROW){doc=sqlite3_mprintf("%s",sqlite3_column_text(q,0));}sqlite3_finalize(q);q=NULL;
        good=doc&&read_state(s,doc,&saved)==0;sqlite3_free(doc);if(!good){goto done;}
        good=saved.last_update_utc==observed&&od_tournament_advance(p,(uint64_t)t->version,t->seed,&t->competitors[i],observed,&empty,&expected)==OD_SCHEDULE_OK&&
            saved.weekend_id==expected.weekend_id&&saved.policy_version==expected.policy_version&&saved.seed==expected.seed&&saved.competitor_hash==expected.competitor_hash&&saved.points==expected.points;
        if(!good){goto done;}scores[i]=saved.points;
    }
    q=statement(s,"SELECT map_id,points FROM tournament_runs WHERE profile=:p AND tournament_id=:x AND weekend_id=?5",NULL,t->id);
    if(!q){good=0;goto done;}sqlite3_bind_int64(q,5,p->weekend_id);
    while((rc=sqlite3_step(q))==SQLITE_ROW){size_t i;int64_t map=sqlite3_column_int64(q,0),points=sqlite3_column_int64(q,1);
        for(i=0;i<t->map_count;i++)if(t->map_ids[i]==map&&t->map_points[i]==points)break;
        if(i==t->map_count){good=0;goto done;}}
    sqlite3_finalize(q);q=NULL;if(rc!=SQLITE_DONE){good=0;goto done;}
    q=statement(s,"SELECT result FROM tournament_claims WHERE profile=:p AND tournament_id=:x AND weekend_id=?5",NULL,t->id);
    if(!q){good=0;goto done;}sqlite3_bind_int64(q,5,p->weekend_id);rc=sqlite3_step(q);
    if(rc==SQLITE_ROW){
        char *receipt=sqlite3_mprintf("%s",sqlite3_column_text(q,0)),*expected=NULL;int64_t revision,current_revision=0,host_now=-1;od_tournament_reward_plan rewards;
        sqlite3_finalize(q);q=NULL;
        good=observed==p->weekend_end_utc&&integer(s,receipt,"$.revision",1,STORE_LIMIT,&revision)==0&&
            od_tournament_rank(player_points,scores,t->competitor_count,(od_rank_tie_policy)t->tie_policy,&rank)==OD_SCHEDULE_OK&&
            od_tournament_rewards(p,observed,rank,t->tiers,t->tier_count,0,&rewards)==OD_SCHEDULE_OK&&validate_exclusive_claim(s,t,p,&rewards);
        if(good){q=statement(s,"SELECT revision FROM profiles WHERE id=:p",NULL,NULL);if(q&&sqlite3_step(q)==SQLITE_ROW)current_revision=sqlite3_column_int64(q,0);sqlite3_finalize(q);q=NULL;good=revision<=current_revision;}
        if(good){char *host_type=text_query(s,"SELECT json_type(:a,'$.host_now_utc')",receipt,NULL);if(host_type)good=!strcmp(host_type,"integer")&&integer(s,receipt,"$.host_now_utc",p->weekend_end_utc,INT64_C(253402300799),&host_now)==0;sqlite3_free(host_type);}
        if(good){expected=claim_receipt(s,t,p,rank,&rewards,revision,host_now);good=expected&&receipt&&od_json_semantic_equal(s->db,receipt,expected)==1;}
        sqlite3_free(receipt);sqlite3_free(expected);if(!good){goto done;}
    }else{sqlite3_finalize(q);q=NULL;if(rc!=SQLITE_DONE){good=0;goto done;}}
    good=1;
done:sqlite3_finalize(q);free(scores);return good;
}

static int validate_periods(store *s){
    sqlite3_stmt *q=NULL;int rc;
    if(sqlite3_prepare_v2(s->db,"SELECT p.profile,p.tournament_id,p.weekend_id,p.config_version,p.start_utc,p.end_utc,p.observed_utc,p.player_points,c.document FROM tournament_periods p JOIN tournament_configs c ON c.profile=p.profile AND c.id=p.tournament_id AND c.version=p.config_version",-1,&q,NULL)!=SQLITE_OK){return 0;}
    while((rc=sqlite3_step(q))==SQLITE_ROW){
        tournament t;od_schedule_period p;s->profile=(const char *)sqlite3_column_text(q,0);int64_t weekend=sqlite3_column_int64(q,2),start=sqlite3_column_int64(q,4),end=sqlite3_column_int64(q,5),observed=sqlite3_column_int64(q,6),points=sqlite3_column_int64(q,7);
        if(!id_ok(s->profile)||load_tournament_document(s,(const char *)sqlite3_column_text(q,8),&t)<0){sqlite3_finalize(q);return 0;}
        int good=weekend>0&&weekend<=UINT32_MAX&&points>=0&&points<=STORE_LIMIT&&period(s,start,t.zone,&p)==0&&
            p.weekend_id==(uint32_t)weekend&&p.weekend_start_utc==start&&p.weekend_end_utc==end&&observed>=start&&observed<=end&&validate_one_period(s,&t,&p,observed,points);
        free_tournament(&t);if(!good){sqlite3_finalize(q);return 0;}
    }
    sqlite3_finalize(q);return rc==SQLITE_DONE;
}

static int validate_exclusive_registry(store *s){
    int schema=exclusive_schema(s->db),rc;sqlite3_stmt *q=NULL;if(schema==0){return 1;}if(schema<0){return 0;}
    if(sqlite3_prepare_v2(s->db,"SELECT profile,definition_id,version,document FROM tournament_exclusive_definitions",-1,&q,NULL)!=SQLITE_OK){return 0;}
    while((rc=sqlite3_step(q))==SQLITE_ROW){
        s->profile=(const char *)sqlite3_column_text(q,0);const char *id=(const char *)sqlite3_column_text(q,1),*doc=(const char *)sqlite3_column_text(q,3);int64_t version=0;char *document_id=string_arg(s,doc,"$.definition_id"),*creator=string_arg(s,doc,"$.creator.id");
        int good=id_ok(s->profile)&&id_ok(id)&&!strncmp(id,"tournament-exclusive:",21)&&id[21]&&document_id&&!strcmp(id,document_id)&&id_ok(creator)&&s->validate_definition&&s->validate_definition(s->definition_context,doc)==0&&integer(s,doc,"$.version",1,STORE_LIMIT,&version)==0&&version==sqlite3_column_int64(q,2)&&!exclusive_collision(s,id);
        sqlite3_free(document_id);sqlite3_free(creator);if(!good){sqlite3_finalize(q);return 0;}
    }
    sqlite3_finalize(q);if(rc!=SQLITE_DONE){return 0;}
    const char *bad="SELECT 1 FROM tournament_exclusive_active a WHERE version!=(SELECT max(version) FROM tournament_exclusive_definitions d WHERE d.profile=a.profile AND d.definition_id=a.definition_id) UNION ALL SELECT 1 FROM tournament_exclusive_definitions d WHERE NOT EXISTS(SELECT 1 FROM tournament_exclusive_active a WHERE a.profile=d.profile AND a.definition_id=d.definition_id) UNION ALL SELECT 1 FROM tournament_exclusive_definitions d JOIN tournament_exclusive_definitions first ON first.profile=d.profile AND first.definition_id=d.definition_id AND first.version=(SELECT min(version) FROM tournament_exclusive_definitions v WHERE v.profile=d.profile AND v.definition_id=d.definition_id) WHERE json_extract(d.document,'$.source.master_id')!=json_extract(first.document,'$.source.master_id') OR json_extract(d.document,'$.source.content_id')!=json_extract(first.document,'$.source.content_id') OR json_extract(d.document,'$.rarity')!=json_extract(first.document,'$.rarity') OR json_extract(d.document,'$.creator.id')!=json_extract(first.document,'$.creator.id') UNION ALL SELECT 1 FROM tournament_exclusive_definitions newer JOIN tournament_exclusive_definitions older ON older.profile=newer.profile AND older.definition_id=newer.definition_id AND older.version<newer.version WHERE json_extract(older.document,'$.stat_policy') IS NOT NULL AND json_extract(older.document,'$.stat_policy') IS NOT json_extract(newer.document,'$.stat_policy') UNION ALL SELECT 1 FROM tournament_exclusive_owned o JOIN owned_cards c ON c.id=o.instance_id WHERE o.profile!=c.profile OR o.potential_locked!=1 OR o.addons!='[]' OR json(c.potential)!='{}' OR EXISTS(SELECT 1 FROM owned_definitions d WHERE d.instance_id=o.instance_id) LIMIT 1";
    if(sqlite3_prepare_v2(s->db,bad,-1,&q,NULL)!=SQLITE_OK){return 0;}rc=sqlite3_step(q);sqlite3_finalize(q);if(rc!=SQLITE_DONE){return 0;}
    if(sqlite3_prepare_v2(s->db,"SELECT o.profile,o.exclusive_kind,o.exclusive_always_on,c.master_id,c.level,c.sa_level,d.document FROM tournament_exclusive_owned o JOIN owned_cards c ON c.id=o.instance_id JOIN tournament_exclusive_definitions d ON d.profile=o.profile AND d.definition_id=o.definition_id AND d.version=o.version",-1,&q,NULL)!=SQLITE_OK){return 0;}
    while((rc=sqlite3_step(q))==SQLITE_ROW){
        s->profile=(const char *)sqlite3_column_text(q,0);const char *doc=(const char *)sqlite3_column_text(q,6);int64_t master,level_cap,sa_cap;char *rarity=string_arg(s,doc,"$.rarity");
        od_summon_rarity r=rarity&&!strcmp(rarity,"UR")?OD_RARITY_UR:rarity&&!strcmp(rarity,"LR")?OD_RARITY_LR:rarity&&!strcmp(rarity,"SLR")?OD_RARITY_SLR:rarity&&!strcmp(rarity,"GR")?OD_RARITY_GR:(od_summon_rarity)-1;od_created_card_defaults defaults;sqlite3_free(rarity);
        int good=integer(s,doc,"$.source.master_id",1,STORE_LIMIT,&master)==0&&integer(s,doc,"$.card.lv_max",1,STORE_LIMIT,&level_cap)==0&&integer(s,doc,"$.card.skill_lv_max",1,STORE_LIMIT,&sa_cap)==0&&od_created_instance_defaults(r,1,&defaults)==OD_PROGRESSION_OK&&
            master==sqlite3_column_int64(q,3)&&sqlite3_column_int64(q,4)>=1&&sqlite3_column_int64(q,4)<=level_cap&&sqlite3_column_int64(q,5)>=1&&sqlite3_column_int64(q,5)<=sa_cap&&sqlite3_column_int(q,1)==(int)defaults.exclusive_kind&&sqlite3_column_int(q,2)==defaults.exclusive_always_on;
        if(!good){sqlite3_finalize(q);return 0;}
    }
    sqlite3_finalize(q);return rc==SQLITE_DONE;
}

/* Import validation repeats the same config and deterministic-state rules used for execution.
 * Exact table/schema and global FK/integrity validation remain the core's responsibility. */
int od_schedule_store_validate(sqlite3 *save,sqlite3 *master,od_schedule_definition_validate_fn validate_definition,void *definition_context){
    store s={save,master,NULL,NULL,validate_definition,NULL,definition_context};sqlite3_stmt *q=NULL;int rc;
    if(!save||!master){return 0;}
    if(!validate_exclusive_registry(&s)){return 0;}
    if(sqlite3_prepare_v2(save,"SELECT profile,id,zone,document FROM schedule_catalogs",-1,&q,NULL)!=SQLITE_OK){return 0;}
    while((rc=sqlite3_step(q))==SQLITE_ROW){catalog c;s.profile=(const char *)sqlite3_column_text(q,0);
        if(!id_ok(s.profile)||load_catalog_document(&s,(const char *)sqlite3_column_text(q,3),&c)<0){sqlite3_finalize(q);return 0;}
        int valid=!strcmp(c.id,(const char *)sqlite3_column_text(q,1))&&c.zone==sqlite3_column_int(q,2);free_catalog(&c);if(!valid){sqlite3_finalize(q);return 0;}}
    sqlite3_finalize(q);if(rc!=SQLITE_DONE){return 0;}
    if(sqlite3_prepare_v2(save,"SELECT profile,id,version,zone,document FROM tournament_configs",-1,&q,NULL)!=SQLITE_OK){return 0;}
    while((rc=sqlite3_step(q))==SQLITE_ROW){tournament t;s.profile=(const char *)sqlite3_column_text(q,0);
        if(!id_ok(s.profile)||load_tournament_document(&s,(const char *)sqlite3_column_text(q,4),&t)<0){sqlite3_finalize(q);return 0;}
        int valid=!strcmp(t.id,(const char *)sqlite3_column_text(q,1))&&t.version==sqlite3_column_int64(q,2)&&t.zone==sqlite3_column_int(q,3);free_tournament(&t);if(!valid){sqlite3_finalize(q);return 0;}}
    sqlite3_finalize(q);if(rc!=SQLITE_DONE){return 0;}
    if(sqlite3_prepare_v2(save,"SELECT profile,id,version,zone,document FROM elder_kai_configs",-1,&q,NULL)!=SQLITE_OK){return 0;}
    while((rc=sqlite3_step(q))==SQLITE_ROW){elder_config e;s.profile=(const char *)sqlite3_column_text(q,0);
        if(!id_ok(s.profile)||load_elder_document(&s,(const char *)sqlite3_column_text(q,4),&e)<0){sqlite3_finalize(q);return 0;}
        int valid=!strcmp(e.id,(const char *)sqlite3_column_text(q,1))&&e.version==sqlite3_column_int64(q,2)&&e.zone==sqlite3_column_int(q,3);free_elder(&e);if(!valid){sqlite3_finalize(q);return 0;}}
    sqlite3_finalize(q);if(rc!=SQLITE_DONE){return 0;}
    const char *invalid="SELECT 1 FROM tournament_periods p WHERE player_points!=COALESCE((SELECT sum(points) FROM tournament_runs r WHERE r.profile=p.profile AND r.tournament_id=p.tournament_id AND r.weekend_id=p.weekend_id AND r.credited=1),0) UNION ALL SELECT 1 FROM tournament_runs t LEFT JOIN runs r ON r.id=t.run_id AND r.profile=t.profile WHERE r.id IS NULL OR r.map_id!=t.map_id OR t.credited=1 AND (r.state!='finished' OR r.outcome IS NULL OR r.outcome!='clear') LIMIT 1";
    if(sqlite3_prepare_v2(save,invalid,-1,&q,NULL)!=SQLITE_OK){return 0;}rc=sqlite3_step(q);sqlite3_finalize(q);if(rc!=SQLITE_DONE){return 0;}
    return validate_rotations(&s)&&validate_periods(&s);
}
