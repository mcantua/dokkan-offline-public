#include "card_stats.h"
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#define SAFE INT64_C(9007199254740991)
#define MASTER_POLICY "master-coefficient-linear-floor-v1"
#define CREATED_POLICY "creator-cap-normalized-v1"
#define MAX_LEVEL 10000

typedef struct {int64_t initial[3],maximum[3],cap,type;char *rarity,*policy;} card;
static int failed(const char **error,const char *message){if(error)*error=message;return -1;}
int od_stats_muldiv(int64_t a,int64_t b,int64_t divisor,int64_t *out){
    if(!out||a<0||a>SAFE||b<0||b>SAFE||divisor<1||divisor>SAFE)return -1;
    /* Binary multiplication/division keeps remainder < divisor; triple SAFE fits uint64_t.
     * This remains exact even when the full product cannot fit int64_t. */
    uint64_t remainder=0,result=0;unsigned highest=0;uint64_t value=(uint64_t)a;
    while(value>>highest&&highest<63)highest++;
    while(highest){highest--;uint64_t next=remainder*2+(((uint64_t)a>>highest)&1u)*(uint64_t)b;
        uint64_t digit=next/(uint64_t)divisor;remainder=next%(uint64_t)divisor;
        if(digit>(uint64_t)SAFE||result>((uint64_t)SAFE-digit)/2)return -1;
        result=result*2+digit;
    }
    *out=(int64_t)result;return 0;
}
static void release(card *c){sqlite3_free(c->rarity);sqlite3_free(c->policy);}
static int load_card(sqlite3 *master,int64_t id,const char *doc,card *c){
    memset(c,0,sizeof(*c));sqlite3_stmt *q=NULL;
    const char *sql="SELECT hp_init,hp_max,atk_init,atk_max,def_init,def_max,lv_max,grow_type,rarity FROM cards WHERE id=?1";
    if(sqlite3_prepare_v2(master,sql,-1,&q,NULL)!=SQLITE_OK)return -1;
    sqlite3_bind_int64(q,1,id);if(sqlite3_step(q)!=SQLITE_ROW){sqlite3_finalize(q);return -1;}
    for(int i=0;i<8;i++)if(sqlite3_column_type(q,i)!=SQLITE_INTEGER){sqlite3_finalize(q);return -1;}
    for(int i=0;i<3;i++){c->initial[i]=sqlite3_column_int64(q,i*2);c->maximum[i]=sqlite3_column_int64(q,i*2+1);}
    c->cap=sqlite3_column_int64(q,6);c->type=sqlite3_column_int64(q,7);sqlite3_finalize(q);
    if(doc){
        const char *overlay="SELECT json_extract(?1,'$.card.hp_init'),json_extract(?1,'$.card.hp_max'),json_extract(?1,'$.card.atk_init'),json_extract(?1,'$.card.atk_max'),json_extract(?1,'$.card.def_init'),json_extract(?1,'$.card.def_max'),json_extract(?1,'$.card.lv_max'),json_extract(?1,'$.card.grow_type'),json_extract(?1,'$.rarity'),json_extract(?1,'$.stat_policy')";
        if(sqlite3_prepare_v2(master,overlay,-1,&q,NULL)!=SQLITE_OK)return -1;
        sqlite3_bind_text(q,1,doc,-1,SQLITE_TRANSIENT);if(sqlite3_step(q)!=SQLITE_ROW){sqlite3_finalize(q);return -1;}
        for(int i=0;i<8;i++)if(sqlite3_column_type(q,i)!=SQLITE_NULL){
            if(sqlite3_column_type(q,i)!=SQLITE_INTEGER){sqlite3_finalize(q);return -1;}
            int64_t v=sqlite3_column_int64(q,i);if(i<6){if(i%2)c->maximum[i/2]=v;else c->initial[i/2]=v;}else if(i==6)c->cap=v;else c->type=v;
        }
        for(int i=8;i<=9;i++)if(sqlite3_column_type(q,i)!=SQLITE_NULL){
            if(sqlite3_column_type(q,i)!=SQLITE_TEXT){sqlite3_finalize(q);return -1;}
            char **target=i==8?&c->rarity:&c->policy;*target=sqlite3_mprintf("%s",sqlite3_column_text(q,i));if(!*target){sqlite3_finalize(q);return -1;}
        }
        sqlite3_finalize(q);
    }
    if(c->cap<1||c->cap>MAX_LEVEL||c->type<0||c->type>SAFE)return -1;
    for(int i=0;i<3;i++)if(c->initial[i]<0||c->maximum[i]<1||c->initial[i]>c->maximum[i]||c->maximum[i]>INT32_MAX)return -1;
    return 0;
}
static int load_growth(sqlite3 *master,int64_t type,int64_t *values,int *cap){
    sqlite3_stmt *q=NULL;int rc,count=0;
    if(sqlite3_prepare_v2(master,"SELECT lv,coef FROM card_growths WHERE grow_type=?1 ORDER BY lv",-1,&q,NULL)!=SQLITE_OK)return -1;
    sqlite3_bind_int64(q,1,type);
    while((rc=sqlite3_step(q))==SQLITE_ROW){
        int numeric=sqlite3_column_type(q,1)==SQLITE_FLOAT||sqlite3_column_type(q,1)==SQLITE_INTEGER;
        double coef=sqlite3_column_double(q,1),scaled=coef*1000.0;
        if(count>=MAX_LEVEL||sqlite3_column_type(q,0)!=SQLITE_INTEGER||sqlite3_column_int64(q,0)!=(int64_t)count+1||!numeric||!(scaled>=0.0&&scaled<=(double)INT32_MAX)){sqlite3_finalize(q);return -1;}
        int64_t exact=(int64_t)(scaled+0.5);double difference=scaled-(double)exact;
        if(difference>0.000001||difference< -0.000001||(count&&exact<values[count-1])){sqlite3_finalize(q);return -1;}
        values[count++]=exact;
    }
    sqlite3_finalize(q);if(rc!=SQLITE_DONE||!count)return -1;*cap=count;return 0;
}
int od_card_stats(sqlite3 *master,int64_t id,const char *doc,int64_t level,const char *fallback,char **out,const char **error){
    card c;int64_t *curve=NULL,stats[3],numerator,denominator;int source_cap=0,normalized=0,result=-1;
    if(out){*out=NULL;}if(error){*error=NULL;}
    if(!master||!out||id<1||id>SAFE)return failed(error,"STATS_INVALID_ARGUMENT");
    if(load_card(master,id,doc,&c)<0){release(&c);return failed(error,"STATS_CARD_UNAVAILABLE");}
    const char *policy=c.policy?c.policy:fallback;
    if(!policy){failed(error,"STATS_POLICY_REQUIRED");goto done;}
    if(!strcmp(policy,CREATED_POLICY)){if(!doc||!c.policy){failed(error,"STATS_POLICY_REQUIRED");goto done;}normalized=1;}
    else if(strcmp(policy,MASTER_POLICY)){failed(error,"STATS_POLICY_UNSUPPORTED");goto done;}
    if(level<1||level>c.cap){failed(error,"STATS_LEVEL_OUT_OF_RANGE");goto done;}
    curve=calloc(MAX_LEVEL,sizeof(*curve));if(!curve){failed(error,"STATS_NO_MEMORY");goto done;}
    if(load_growth(master,c.type,curve,&source_cap)<0){failed(error,"STATS_CURVE_UNAVAILABLE");goto done;}
    if(normalized){
        if(c.cap<2||source_cap<2||curve[source_cap-1]<=curve[0]){failed(error,"STATS_CURVE_UNAVAILABLE");goto done;}
        int64_t scale=c.cap-1,position=(level-1)*(source_cap-1),low=position/scale,remainder=position%scale;
        numerator=(curve[low]-curve[0])*scale;
        if(remainder){numerator+=(curve[low+1]-curve[low])*remainder;}
        denominator=(curve[source_cap-1]-curve[0])*scale;
    }else{
        if(level>source_cap){failed(error,"STATS_CURVE_UNAVAILABLE");goto done;}
        numerator=curve[level-1];denominator=1000;
    }
    for(int i=0;i<3;i++){
        int64_t growth;if(od_stats_muldiv(c.maximum[i]-c.initial[i],numerator,denominator,&growth)<0||growth>SAFE-c.initial[i]){failed(error,"STATS_OVERFLOW");goto done;}stats[i]=c.initial[i]+growth;
    }
    int boost=c.rarity&&!strcmp(c.rarity,"SLR")?10:c.rarity&&!strcmp(c.rarity,"GR")?20:0;
    *out=sqlite3_mprintf("{\"master_id\":%lld,\"level\":%lld,\"level_cap\":%lld,\"hp\":%lld,\"atk\":%lld,\"def\":%lld,\"policy\":\"%s\",\"source_grow_type\":%lld,\"source_curve_cap\":%d,\"coefficient_numerator\":%lld,\"coefficient_denominator\":%lld,\"internal_policy\":true,\"original_game_rounding_verified\":false,\"base_excludes_bonuses\":true,\"final_exclusive\":{\"atk_percent\":%d,\"def_percent\":%d,\"damage_reduction_percent\":%d,\"always_on\":%s,\"apply_once_after_other_boosts\":true,\"included_in_base\":false}}",(long long)id,(long long)level,(long long)c.cap,(long long)stats[0],(long long)stats[1],(long long)stats[2],policy,(long long)c.type,source_cap,(long long)numerator,(long long)denominator,boost,boost,boost,boost?"true":"false");
    if(!*out){failed(error,"STATS_NO_MEMORY");goto done;}result=0;
done:free(curve);release(&c);return result;
}
