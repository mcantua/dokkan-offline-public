#include "training.h"
#include <stdlib.h>
#include <string.h>
#define SAFE INT64_C(9007199254740991)
typedef struct {int64_t id,element,exp,zeni;} training_item;
static int fail(const char **error,const char *message){if(error)*error=message;return -1;}
static int positive(int64_t n){return n>0&&n<=SAFE;}
static int multiply(int64_t a,int64_t b,int64_t *out){if(a<0||b<0||a>SAFE||b>SAFE||(a&&b>SAFE/a))return -1;*out=a*b;return 0;}
static sqlite3_stmt *statement(sqlite3 *db,const char *sql,int64_t id){sqlite3_stmt *q=NULL;if(sqlite3_prepare_v2(db,sql,-1,&q,NULL)!=SQLITE_OK)return NULL;sqlite3_bind_int64(q,1,id);return q;}
static int item_index(const training_item *items,size_t count,int64_t id){for(size_t i=0;i<count;i++)if(items[i].id==id)return (int)i;return -1;}
static int read_items(sqlite3 *db,training_item *items,size_t *count){
    sqlite3_stmt *q=statement(db,"SELECT id,element,exp,zeni_to_use FROM training_items ORDER BY id",0);int rc;size_t n=0;
    if(!q)return -1;
    while((rc=sqlite3_step(q))==SQLITE_ROW){
        if(n==OD_TRAINING_MAX_ITEMS){sqlite3_finalize(q);return -1;}
        for(int i=0;i<4;i++)if(sqlite3_column_type(q,i)!=SQLITE_INTEGER){sqlite3_finalize(q);return -1;}
        training_item row={sqlite3_column_int64(q,0),sqlite3_column_int64(q,1),sqlite3_column_int64(q,2),sqlite3_column_int64(q,3)};
        if(!positive(row.id)||row.element<0||row.element>4||!positive(row.exp)||row.zeni<0||row.zeni>SAFE||(n&&row.id<=items[n-1].id)){sqlite3_finalize(q);return -1;}items[n++]=row;
    }
    sqlite3_finalize(q);if(rc!=SQLITE_DONE||!n)return -1;*count=n;return 0;
}
static char *array_query(sqlite3 *db,const char *sql){
    sqlite3_stmt *q=statement(db,sql,0);if(!q)return NULL;int rc;sqlite3_str *json=sqlite3_str_new(NULL);sqlite3_str_appendall(json,"[");int first=1;
    while((rc=sqlite3_step(q))==SQLITE_ROW){if(sqlite3_column_type(q,0)!=SQLITE_TEXT){rc=SQLITE_ERROR;break;}sqlite3_str_appendf(json,"%s%s",first?"":",",sqlite3_column_text(q,0));first=0;}
    sqlite3_finalize(q);sqlite3_str_appendall(json,"]");char *result=sqlite3_str_finish(json);if(rc!=SQLITE_DONE){sqlite3_free(result);return NULL;}return result;
}
static int field_valid(sqlite3 *db,int64_t id){
    sqlite3_stmt *q=statement(db,"SELECT zeni,exp,elements,multiplier,addend,card_training_field_exp_up_prob_id FROM training_fields WHERE id=?1",id);
    if(!q||sqlite3_step(q)!=SQLITE_ROW){sqlite3_finalize(q);return 0;}
    int good=1;for(int i=0;i<5;i++)if(i!=3&&(sqlite3_column_type(q,i)!=SQLITE_INTEGER||sqlite3_column_int64(q,i)<0||sqlite3_column_int64(q,i)>SAFE))good=0;
    double multiplier=sqlite3_column_double(q,3);if((sqlite3_column_type(q,3)!=SQLITE_INTEGER&&sqlite3_column_type(q,3)!=SQLITE_FLOAT)||!(multiplier>0&&multiplier<=1000000))good=0;
    int64_t chance=sqlite3_column_int64(q,5);int has_chance=sqlite3_column_type(q,5)!=SQLITE_NULL;
    if(has_chance&&(sqlite3_column_type(q,5)!=SQLITE_INTEGER||!positive(chance))){good=0;}sqlite3_finalize(q);
    if(good&&has_chance){q=statement(db,"SELECT effect,success_prob_percent FROM card_training_field_exp_up_probs WHERE id=?1",chance);good=q&&sqlite3_step(q)==SQLITE_ROW;
        if(good){double effect=sqlite3_column_double(q,0),probability=sqlite3_column_double(q,1);good=(sqlite3_column_type(q,0)==SQLITE_INTEGER||sqlite3_column_type(q,0)==SQLITE_FLOAT)&&(sqlite3_column_type(q,1)==SQLITE_INTEGER||sqlite3_column_type(q,1)==SQLITE_FLOAT)&&effect>0&&effect<=1000000&&probability>=0&&probability<=100;}sqlite3_finalize(q);}
    return good;
}
int od_training_catalog(sqlite3 *db,char **out,const char **error){
    if(out){*out=NULL;}if(error){*error=NULL;}if(!db||!out)return fail(error,"TRAINING_INVALID_ARGUMENT");
    training_item items[OD_TRAINING_MAX_ITEMS];size_t count=0;if(read_items(db,items,&count)<0)return fail(error,"TRAINING_MASTER_UNSUPPORTED");
    sqlite3_stmt *q=statement(db,"SELECT id FROM training_fields ORDER BY id",0);if(!q)return fail(error,"TRAINING_MASTER_UNSUPPORTED");int rc,fields=0;
    while((rc=sqlite3_step(q))==SQLITE_ROW){if(++fields>OD_TRAINING_MAX_ITEMS||sqlite3_column_type(q,0)!=SQLITE_INTEGER||!positive(sqlite3_column_int64(q,0))||!field_valid(db,sqlite3_column_int64(q,0))){sqlite3_finalize(q);return fail(error,"TRAINING_MASTER_UNSUPPORTED");}}
    sqlite3_finalize(q);if(rc!=SQLITE_DONE)return fail(error,"TRAINING_MASTER_UNSUPPORTED");
    char *item_json=array_query(db,"SELECT json_object('item_id',id,'name',name,'description',description,'element',element,'base_exp',exp,'zeni_to_use',zeni_to_use) FROM training_items ORDER BY id"),*field_json=array_query(db,"SELECT json_object('field_id',f.id,'name',f.name,'description',f.description,'raw_zeni',f.zeni,'raw_exp',f.exp,'raw_elements',f.elements,'raw_multiplier',f.multiplier,'raw_addend',f.addend,'success_reference',f.card_training_field_exp_up_prob_id,'success',CASE WHEN p.id IS NULL THEN NULL ELSE json_object('source_key',p.key,'raw_effect',p.effect,'raw_success_prob_percent',p.success_prob_percent) END) FROM training_fields f LEFT JOIN card_training_field_exp_up_probs p ON p.id=f.card_training_field_exp_up_prob_id ORDER BY f.id");
    if(item_json&&field_json)*out=sqlite3_mprintf("{\"verified_source_facts_only\":true,\"final_training_formula_verified\":false,\"items\":%s,\"fields\":%s}",item_json,field_json);
    sqlite3_free(item_json);sqlite3_free(field_json);return *out?0:fail(error,"TRAINING_MASTER_UNSUPPORTED");
}
static int64_t level_at(const int64_t *curve,size_t count,int64_t exp){size_t low=0,high=count;while(low<high){size_t mid=low+(high-low)/2;if(curve[mid]<=exp)low=mid+1;else high=mid;}return (int64_t)low;}
int od_training_project_exp(const int64_t *curve,size_t count,int64_t level,const int64_t *known,int64_t gain,char **out,const char **error){
    if(out){*out=NULL;}if(error){*error=NULL;}
    if(!curve||!out||count<1||count>OD_TRAINING_MAX_LEVELS||level<1||(uint64_t)level>count||gain<0||gain>SAFE)return fail(error,"TRAINING_INVALID_ARGUMENT");
    for(size_t i=0;i<count;i++)if(curve[i]<0||curve[i]>SAFE||(i?curve[i]<=curve[i-1]:curve[i]!=0))return fail(error,"TRAINING_CURVE_UNAVAILABLE");
    int64_t low=curve[level-1],high=(size_t)level<count?curve[level]-1:low;
    if(known){if(*known<low||*known>high)return fail(error,"TRAINING_EXPERIENCE_MISMATCH");low=high=*known;}
    if(gain>SAFE-high){return fail(error,"TRAINING_AMOUNT_OVERFLOW");}low+=gain;high+=gain;
    int low_over=low>curve[count-1],high_over=high>curve[count-1];
    char *minimum=low_over?sqlite3_mprintf("null"):sqlite3_mprintf("%lld",(long long)level_at(curve,count,low)),*maximum=high_over?sqlite3_mprintf("null"):sqlite3_mprintf("%lld",(long long)level_at(curve,count,high));
    if(minimum&&maximum)*out=sqlite3_mprintf("{\"available\":true,\"base_items_only\":true,\"owned_experience_known\":%s,\"level_cap\":%llu,\"base_gain\":%lld,\"experience_lower\":%lld,\"experience_upper\":%lld,\"level_lower\":%s,\"level_upper\":%s,\"lower_exceeds_cap\":%s,\"upper_exceeds_cap\":%s,\"cap_discard_policy_applied\":false}",known?"true":"false",(unsigned long long)count,(long long)gain,(long long)low,(long long)high,minimum,maximum,low_over?"true":"false",high_over?"true":"false");
    sqlite3_free(minimum);sqlite3_free(maximum);return *out?0:fail(error,"TRAINING_NO_MEMORY");
}
static int target(sqlite3 *db,int64_t id,const char *doc,int64_t *cap,int64_t *type,int64_t *element){
    sqlite3_stmt *q=statement(db,"SELECT lv_max,exp_type,element FROM cards WHERE id=?1",id);if(!q||sqlite3_step(q)!=SQLITE_ROW){sqlite3_finalize(q);return -1;}
    for(int i=0;i<3;i++)if(sqlite3_column_type(q,i)!=SQLITE_INTEGER){sqlite3_finalize(q);return -1;}
    *cap=sqlite3_column_int64(q,0);*type=sqlite3_column_int64(q,1);*element=sqlite3_column_int64(q,2);sqlite3_finalize(q);
    if(doc){const char *paths[]={"$.card.lv_max","$.card.exp_type","$.card.element"};int64_t *values[]={cap,type,element};
        for(int i=0;i<3;i++){
            if(sqlite3_prepare_v2(db,"SELECT json_type(?1,?2),json_extract(?1,?2)",-1,&q,NULL)!=SQLITE_OK)return -1;
            sqlite3_bind_text(q,1,doc,-1,SQLITE_TRANSIENT);sqlite3_bind_text(q,2,paths[i],-1,SQLITE_STATIC);if(sqlite3_step(q)!=SQLITE_ROW){sqlite3_finalize(q);return -1;}
            if(sqlite3_column_type(q,0)!=SQLITE_NULL){if(strcmp((const char *)sqlite3_column_text(q,0),"integer")){sqlite3_finalize(q);return -1;}*values[i]=sqlite3_column_int64(q,1);}sqlite3_finalize(q);
        }
    }
    return *cap>=1&&*cap<=OD_TRAINING_MAX_LEVELS&&*type>=0&&*type<=SAFE&&((*element>=0&&*element<=4)||(*element>=10&&*element<=14)||(*element>=20&&*element<=24))?0:-1;
}
static char *source_projection(sqlite3 *db,int64_t type,int64_t cap,int64_t level,const int64_t *known,int64_t gain,const char **error){
    int64_t *curve=calloc((size_t)cap,sizeof(*curve));if(!curve){fail(error,"TRAINING_NO_MEMORY");return NULL;}
    sqlite3_stmt *q=statement(db,"SELECT lv,exp_total FROM card_exps WHERE exp_type=?1 AND lv BETWEEN 1 AND ?2 ORDER BY lv",type);if(q)sqlite3_bind_int64(q,2,cap);size_t n=0;int rc=SQLITE_ERROR,good=q!=NULL;
    if(q)while((rc=sqlite3_step(q))==SQLITE_ROW){
        if(n==(size_t)cap){good=0;break;}
        if(sqlite3_column_type(q,0)!=SQLITE_INTEGER||sqlite3_column_type(q,1)!=SQLITE_INTEGER||sqlite3_column_int64(q,0)!=(int64_t)n+1){good=0;break;}curve[n++]=sqlite3_column_int64(q,1);
    }
    sqlite3_finalize(q);char *projection=NULL;
    if(!good||n!=(size_t)cap||(rc!=SQLITE_DONE&&rc!=SQLITE_ROW)){projection=sqlite3_mprintf("{\"available\":false,\"reason\":\"TRAINING_CURVE_UNAVAILABLE\"}");}
    else {const char *projection_error=NULL;if(od_training_project_exp(curve,n,level,known,gain,&projection,&projection_error)<0){if(projection_error&&!strcmp(projection_error,"TRAINING_CURVE_UNAVAILABLE"))projection=sqlite3_mprintf("{\"available\":false,\"reason\":\"TRAINING_CURVE_UNAVAILABLE\"}");else fail(error,projection_error?projection_error:"TRAINING_NO_MEMORY");}}
    free(curve);return projection;
}
int od_training_preview(sqlite3 *db,int64_t master,const char *doc,int64_t level,const int64_t *known,const od_training_amount *requests,size_t count,const od_training_amount *inventory,size_t inventory_count,const int64_t *zeni,int64_t field,char **out,const char **error){
    if(out){*out=NULL;}if(error){*error=NULL;}
    if(!db||!out||!positive(master)||!requests||!count||count>OD_TRAINING_MAX_REQUESTS||inventory_count>4096||(inventory_count&&!inventory)||(known&&(*known<0||*known>SAFE))||(zeni&&(*zeni<0||*zeni>SAFE))||field<0||field>SAFE)return fail(error,"TRAINING_INVALID_ARGUMENT");
    training_item items[OD_TRAINING_MAX_ITEMS];size_t item_count=0;int64_t cap,type,element,total_exp=0,total_zeni=0;int enough=1;
    if(read_items(db,items,&item_count)<0)return fail(error,"TRAINING_MASTER_UNSUPPORTED");
    if(target(db,master,doc,&cap,&type,&element)<0||level<1||level>cap)return fail(error,"TRAINING_TARGET_UNAVAILABLE");
    if(field&&!field_valid(db,field))return fail(error,"TRAINING_FIELD_UNAVAILABLE");
    for(size_t i=0;i<inventory_count;i++){if(item_index(items,item_count,inventory[i].item_id)<0||inventory[i].quantity<0||inventory[i].quantity>SAFE)return fail(error,"TRAINING_INVENTORY_INVALID");for(size_t j=0;j<i;j++)if(inventory[j].item_id==inventory[i].item_id)return fail(error,"TRAINING_INVENTORY_INVALID");}
    sqlite3_str *lines=sqlite3_str_new(NULL);sqlite3_str_appendall(lines,"[");
    for(size_t i=0;i<count;i++){
        int index=item_index(items,item_count,requests[i].item_id);if(index<0||!positive(requests[i].quantity)){char *discard=sqlite3_str_finish(lines);sqlite3_free(discard);return fail(error,"TRAINING_ITEM_INVALID");}
        for(size_t j=0;j<i;j++)if(requests[j].item_id==requests[i].item_id){char *discard=sqlite3_str_finish(lines);sqlite3_free(discard);return fail(error,"TRAINING_DUPLICATE_ITEM");}
        int64_t exp,cost,available=0;if(multiply(items[index].exp,requests[i].quantity,&exp)<0||multiply(items[index].zeni,requests[i].quantity,&cost)<0||exp>SAFE-total_exp||cost>SAFE-total_zeni){char *discard=sqlite3_str_finish(lines);sqlite3_free(discard);return fail(error,"TRAINING_AMOUNT_OVERFLOW");}
        total_exp+=exp;total_zeni+=cost;for(size_t j=0;j<inventory_count;j++)if(inventory[j].item_id==requests[i].item_id){available=inventory[j].quantity;break;}int64_t shortfall=available<requests[i].quantity?requests[i].quantity-available:0;if(shortfall)enough=0;
        sqlite3_str_appendf(lines,"%s{\"item_id\":%lld,\"quantity\":%lld,\"available\":%lld,\"shortfall\":%lld,\"source_element\":%lld,\"matches_target_type\":%s,\"source_base_exp_each\":%lld,\"source_zeni_to_use_each\":%lld,\"base_exp_subtotal\":%lld,\"item_zeni_subtotal\":%lld}",i?",":"",(long long)requests[i].item_id,(long long)requests[i].quantity,(long long)available,(long long)shortfall,(long long)items[index].element,items[index].element==element%10?"true":"false",(long long)items[index].exp,(long long)items[index].zeni,(long long)exp,(long long)cost);
    }
    sqlite3_str_appendall(lines,"]");char *item_json=sqlite3_str_finish(lines),*projection=source_projection(db,type,cap,level,known,total_exp,error);
    if(item_json&&projection)*out=sqlite3_mprintf("{\"master_id\":%lld,\"owned_level\":%lld,\"source_exp_type\":%lld,\"target_element\":%lld,\"field_id\":%lld,\"selected_item_kinds\":%llu,\"base_item_exp\":%lld,\"item_zeni_subtotal\":%lld,\"items_available\":%s,\"zeni_known\":%s,\"item_zeni_subtotal_affordable\":%s,\"costs_are_unmultiplied\":true,\"final_exp\":null,\"final_zeni_cost\":null,\"can_commit\":false,\"missing_policy\":[\"target_eligibility\",\"matching_type_bonus\",\"field_success_combination\",\"complete_zeni_formula\",\"cap_overflow_handling\"],\"items\":%s,\"base_experience_projection\":%s}",(long long)master,(long long)level,(long long)type,(long long)element,(long long)field,(unsigned long long)count,(long long)total_exp,(long long)total_zeni,enough?"true":"false",zeni?"true":"false",!zeni?"null":*zeni>=total_zeni?"true":"false",item_json,projection);
    sqlite3_free(item_json);sqlite3_free(projection);if(*out)return 0;return error&&*error?-1:fail(error,"TRAINING_NO_MEMORY");
}
