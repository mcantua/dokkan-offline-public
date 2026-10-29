#include "potential.h"
#include <stdlib.h>
#include <string.h>

#define SAFE INT64_C(9007199254740991)
static int fail(const char **error,const char *message){if(error)*error=message;return -1;}
static int valid(int64_t v){return v>0&&v<=SAFE;}
static sqlite3_stmt *query(sqlite3 *db,const char *sql,int64_t id){
    sqlite3_stmt *q=NULL;if(sqlite3_prepare_v2(db,sql,-1,&q,NULL)!=SQLITE_OK)return NULL;
    sqlite3_bind_int64(q,1,id);return q;
}
static int exists(sqlite3 *db,const char *table,int64_t id){
    char *sql=sqlite3_mprintf("SELECT 1 FROM %s WHERE id=?1",table);if(!sql)return 0;
    sqlite3_stmt *q=query(db,sql,id);sqlite3_free(sql);int found=q&&sqlite3_step(q)==SQLITE_ROW;sqlite3_finalize(q);return found;
}
static int node_index(const od_potential_board *b,int64_t id){
    size_t low=0,high=b->node_count;while(low<high){size_t mid=low+(high-low)/2;if(b->nodes[mid].id<id)low=mid+1;else high=mid;}
    return low<b->node_count&&b->nodes[low].id==id?(int)low:-1;
}
static int bounded_board(const od_potential_board *b){
    if(!b||!b->nodes||!valid(b->master_id)||!valid(b->board_id)||!b->node_count||b->node_count>OD_POTENTIAL_MAX_NODES)return 0;
    for(size_t i=0;i<b->node_count;i++){
        const od_potential_node *n=&b->nodes[i];
        if(!valid(n->id)||(i&&n->id<=b->nodes[i-1].id)||n->link_count>OD_POTENTIAL_MAX_LINKS||n->cost_count>OD_POTENTIAL_MAX_COSTS||n->choice_count>OD_POTENTIAL_MAX_CHOICES||n->minimum_sa<0||n->minimum_sa>SAFE||n->event.kind<OD_POTENTIAL_HP||n->event.kind>OD_POTENTIAL_SELECT)return 0;
        for(size_t j=0;j<n->cost_count;j++)if(!valid(n->costs[j].item_id)||!valid(n->costs[j].quantity))return 0;
    }
    return 1;
}
static int read_event(sqlite3 *db,int64_t id,od_potential_event *event){
    sqlite3_stmt *q=query(db,"SELECT type,currency_id,additional_value FROM potential_events WHERE id=?1",id);
    if(!q||sqlite3_step(q)!=SQLITE_ROW||sqlite3_column_type(q,0)!=SQLITE_TEXT||sqlite3_column_type(q,2)!=SQLITE_INTEGER){sqlite3_finalize(q);return -1;}
    const char *type=(const char *)sqlite3_column_text(q,0);const char *types[]={"PotentialEvent::Hp","PotentialEvent::Atk","PotentialEvent::Defense","PotentialEvent::Skill","PotentialEvent::Select"};int k;
    for(k=0;k<5;k++)if(!strcmp(type,types[k]))break;
    int nullable=sqlite3_column_type(q,1)==SQLITE_NULL;int64_t resource=sqlite3_column_int64(q,1),amount=sqlite3_column_int64(q,2);
    int good=k<5&&amount>=0&&amount<=SAFE&&(k<3?nullable&&amount>0:!nullable&&sqlite3_column_type(q,1)==SQLITE_INTEGER&&valid(resource));
    if(good&&k==4)good=amount==0;
    if(good&&k==3)good=amount>0;
    sqlite3_finalize(q);if(!good)return -1;
    if(k==3&&!exists(db,"potential_skills",resource))return -1;
    if(k==4&&!exists(db,"potential_event_selection_tables",resource))return -1;
    *event=(od_potential_event){id,resource,amount,(od_potential_event_kind)k};return 0;
}
static int read_choices(sqlite3 *db,od_potential_node *node){
    if(node->event.kind!=OD_POTENTIAL_SELECT)return 0;
    sqlite3_stmt *q=query(db,"SELECT required_stone_for_unrelease FROM potential_event_selection_tables WHERE id=?1",node->event.resource_id);
    if(!q||sqlite3_step(q)!=SQLITE_ROW||sqlite3_column_type(q,0)!=SQLITE_INTEGER||sqlite3_column_int64(q,0)<0||sqlite3_column_int64(q,0)>SAFE){sqlite3_finalize(q);return -1;}
    node->source_reset_stones=sqlite3_column_int64(q,0);sqlite3_finalize(q);
    q=query(db,"SELECT event_id FROM potential_event_selections WHERE selection_table_id=?1 ORDER BY id",node->event.resource_id);int rc;
    if(!q)return -1;
    while((rc=sqlite3_step(q))==SQLITE_ROW){
        if(node->choice_count==OD_POTENTIAL_MAX_CHOICES||sqlite3_column_type(q,0)!=SQLITE_INTEGER){sqlite3_finalize(q);return -1;}
        int64_t id=sqlite3_column_int64(q,0);for(size_t i=0;i<node->choice_count;i++)if(node->choices[i].id==id){sqlite3_finalize(q);return -1;}
        if(read_event(db,id,&node->choices[node->choice_count])<0||node->choices[node->choice_count].kind!=OD_POTENTIAL_SKILL){sqlite3_finalize(q);return -1;}node->choice_count++;
    }
    sqlite3_finalize(q);return rc==SQLITE_DONE&&node->choice_count?0:-1;
}
static int read_conditions(sqlite3 *db,int64_t set,od_potential_node *node){
    sqlite3_stmt *q=query(db,"SELECT c.type,c.conditions,c.id FROM potential_square_condition_set_relations r LEFT JOIN potential_square_conditions c ON c.id=r.condition_id WHERE r.condition_set_id=?1 ORDER BY r.id",set);int rc,count=0;int64_t seen[64];
    if(!q)return -1;
    while((rc=sqlite3_step(q))==SQLITE_ROW){
        if(count>=64||sqlite3_column_type(q,0)!=SQLITE_TEXT||sqlite3_column_type(q,1)!=SQLITE_TEXT){sqlite3_finalize(q);return -1;}
        int64_t condition_id=sqlite3_column_int64(q,2);for(int i=0;i<count;i++)if(seen[i]==condition_id){sqlite3_finalize(q);return -1;}seen[count++]=condition_id;
        const char *type=(const char *)sqlite3_column_text(q,0),*json=(const char *)sqlite3_column_text(q,1);int item=!strcmp(type,"PotentialSquareCondition::PotentialItem"),sa=!strcmp(type,"PotentialSquareCondition::SkillLv");
        if(!item&&!sa){sqlite3_finalize(q);return -1;}
        sqlite3_stmt *v=NULL;const char *sql=item?"SELECT json_type(?1)='object' AND json_type(?1,'$.item_id')='integer' AND json_type(?1,'$.quantity')='integer' AND (SELECT count(*) FROM json_each(?1))=2,json_extract(?1,'$.item_id'),json_extract(?1,'$.quantity')":"SELECT json_type(?1)='object' AND json_type(?1,'$.skill_lv')='integer' AND (SELECT count(*) FROM json_each(?1))=1,json_extract(?1,'$.skill_lv')";
        if(sqlite3_prepare_v2(db,sql,-1,&v,NULL)!=SQLITE_OK){sqlite3_finalize(q);return -1;}sqlite3_bind_text(v,1,json,-1,SQLITE_TRANSIENT);
        if(sqlite3_step(v)!=SQLITE_ROW||!sqlite3_column_int(v,0)){sqlite3_finalize(v);sqlite3_finalize(q);return -1;}
        int64_t first=sqlite3_column_int64(v,1),amount=item?sqlite3_column_int64(v,2):0;sqlite3_finalize(v);
        if(!valid(first)||(item&&(!valid(amount)||!exists(db,"potential_items",first)))){sqlite3_finalize(q);return -1;}
        if(sa){if(first>node->minimum_sa)node->minimum_sa=first;continue;}
        size_t i;for(i=0;i<node->cost_count;i++)if(node->costs[i].item_id==first)break;
        if(i==node->cost_count){if(i==OD_POTENTIAL_MAX_COSTS){sqlite3_finalize(q);return -1;}node->costs[node->cost_count++]=(od_potential_orbs){first,0};}
        if(amount>SAFE-node->costs[i].quantity){sqlite3_finalize(q);return -1;}node->costs[i].quantity+=amount;
    }
    sqlite3_finalize(q);return rc==SQLITE_DONE&&count?0:-1;
}
int od_potential_load(sqlite3 *db,int64_t master,const char *doc,od_potential_board **out,const char **error){
    if(out){*out=NULL;}if(error){*error=NULL;}
    if(!db||!out||!valid(master))return fail(error,"POTENTIAL_INVALID_ARGUMENT");
    sqlite3_stmt *q=query(db,"SELECT potential_board_id FROM cards WHERE id=?1",master);int64_t board=0;
    if(!q||sqlite3_step(q)!=SQLITE_ROW){sqlite3_finalize(q);return fail(error,"POTENTIAL_CARD_NOT_FOUND");}
    if(sqlite3_column_type(q,0)==SQLITE_INTEGER){board=sqlite3_column_int64(q,0);}sqlite3_finalize(q);
    if(doc){
        if(sqlite3_prepare_v2(db,"SELECT json_type(?1,'$.card.potential_board_id'),json_extract(?1,'$.card.potential_board_id')",-1,&q,NULL)!=SQLITE_OK)return fail(error,"POTENTIAL_DEFINITION_INVALID");
        sqlite3_bind_text(q,1,doc,-1,SQLITE_TRANSIENT);if(sqlite3_step(q)!=SQLITE_ROW){sqlite3_finalize(q);return fail(error,"POTENTIAL_DEFINITION_INVALID");}
        if(sqlite3_column_type(q,0)!=SQLITE_NULL){if(sqlite3_column_type(q,1)!=SQLITE_INTEGER||strcmp((const char *)sqlite3_column_text(q,0),"integer")){sqlite3_finalize(q);return fail(error,"POTENTIAL_DEFINITION_INVALID");}board=sqlite3_column_int64(q,1);}sqlite3_finalize(q);
    }
    if(!valid(board)||!exists(db,"potential_boards",board))return fail(error,"POTENTIAL_BOARD_UNAVAILABLE");
    od_potential_board *b=calloc(1,sizeof(*b));if(!b)return fail(error,"POTENTIAL_NO_MEMORY");b->master_id=master;b->board_id=board;
    b->nodes=calloc(OD_POTENTIAL_MAX_NODES,sizeof(*b->nodes));if(!b->nodes){od_potential_free(b);return fail(error,"POTENTIAL_NO_MEMORY");}
    q=query(db,"SELECT id,event_id,condition_set_id,is_locked,route FROM potential_squares WHERE potential_board_id=?1 ORDER BY id",board);int rc;
    if(!q)goto invalid;
    while((rc=sqlite3_step(q))==SQLITE_ROW){
        if(b->node_count==OD_POTENTIAL_MAX_NODES)goto invalid;
        for(int column=0;column<4;column++)if(sqlite3_column_type(q,column)!=SQLITE_INTEGER)goto invalid;
        if(sqlite3_column_type(q,4)!=SQLITE_NULL&&sqlite3_column_type(q,4)!=SQLITE_INTEGER)goto invalid;
        od_potential_node *node=&b->nodes[b->node_count++];node->id=sqlite3_column_int64(q,0);
        int64_t event=sqlite3_column_int64(q,1),set=sqlite3_column_int64(q,2);node->condition_set_id=set;node->locked=sqlite3_column_int(q,3);node->route=sqlite3_column_type(q,4)==SQLITE_NULL?-1:sqlite3_column_int(q,4);
        if(!valid(node->id)||!valid(event)||!valid(set)||(node->locked!=0&&node->locked!=1)||(node->locked?(node->route<0||node->route>3):node->route!=-1)||read_event(db,event,&node->event)<0||read_choices(db,node)<0||!exists(db,"potential_square_condition_sets",set)||read_conditions(db,set,node)<0)goto invalid;
    }
    sqlite3_finalize(q);q=NULL;if(rc!=SQLITE_DONE||!b->node_count)goto invalid;
    for(size_t i=0;i<b->node_count;i++){
        od_potential_node *node=&b->nodes[i];q=query(db,"SELECT prev_potential_square_id FROM potential_square_relations WHERE potential_square_id=?1 ORDER BY id",node->id);int relations=0;
        if(!q)goto invalid;
        while((rc=sqlite3_step(q))==SQLITE_ROW){
            if(++relations>OD_POTENTIAL_MAX_LINKS+1)goto invalid;
            if(sqlite3_column_type(q,0)==SQLITE_NULL){if(node->has_start_link)goto invalid;node->has_start_link=1;continue;}
            int64_t previous=sqlite3_column_int64(q,0);if(sqlite3_column_type(q,0)!=SQLITE_INTEGER||previous==node->id||node_index(b,previous)<0||node->link_count==OD_POTENTIAL_MAX_LINKS)goto invalid;
            for(size_t j=0;j<node->link_count;j++)if(node->linked_nodes[j]==previous)goto invalid;
            node->linked_nodes[node->link_count++]=previous;
        }
        sqlite3_finalize(q);q=NULL;if(rc!=SQLITE_DONE||!relations)goto invalid;
    }
    *out=b;return 0;
invalid:sqlite3_finalize(q);od_potential_free(b);return fail(error,"POTENTIAL_MASTER_UNSUPPORTED");
}
void od_potential_free(od_potential_board *b){if(b){free(b->nodes);free(b);}}
static const char *kind_name(od_potential_event_kind kind){const char *names[]={"hp","atk","def","skill","selection"};return kind>=OD_POTENTIAL_HP&&kind<=OD_POTENTIAL_SELECT?names[kind]:"unsupported";}
static void event_json(sqlite3_str *json,const od_potential_event *e){sqlite3_str_appendf(json,"{\"event_id\":%lld,\"kind\":\"%s\",\"resource_id\":%lld,\"amount\":%lld}",(long long)e->id,kind_name(e->kind),(long long)e->resource_id,(long long)e->amount);}
int od_potential_view(const od_potential_board *b,char **out,const char **error){
    if(out){*out=NULL;}if(!bounded_board(b)||!out)return fail(error,"POTENTIAL_INVALID_ARGUMENT");
    sqlite3_str *json=sqlite3_str_new(NULL);sqlite3_str_appendf(json,"{\"master_id\":%lld,\"board_id\":%lld,\"links_are_source_adjacency\":true,\"activation_policy_verified\":false,\"nodes\":[",(long long)b->master_id,(long long)b->board_id);
    for(size_t i=0;i<b->node_count;i++){
        const od_potential_node *n=&b->nodes[i];sqlite3_str_appendf(json,"%s{\"node_id\":%lld,\"condition_set_id\":%lld,\"locked\":%s,\"route\":%d,\"has_start_link\":%s,\"linked_nodes\":[",i?",":"",(long long)n->id,(long long)n->condition_set_id,n->locked?"true":"false",n->route,n->has_start_link?"true":"false");
        for(size_t j=0;j<n->link_count;j++)sqlite3_str_appendf(json,"%s%lld",j?",":"",(long long)n->linked_nodes[j]);
        sqlite3_str_appendf(json,"],\"minimum_sa_level\":%lld,\"orb_costs\":[",(long long)n->minimum_sa);
        for(size_t j=0;j<n->cost_count;j++)sqlite3_str_appendf(json,"%s{\"item_id\":%lld,\"quantity\":%lld}",j?",":"",(long long)n->costs[j].item_id,(long long)n->costs[j].quantity);
        sqlite3_str_appendall(json,"],\"event\":");event_json(json,&n->event);sqlite3_str_appendall(json,",\"choices\":[");
        for(size_t j=0;j<n->choice_count;j++){if(j)sqlite3_str_appendall(json,",");event_json(json,&n->choices[j]);}
        sqlite3_str_appendf(json,"],\"source_reset_stones\":%lld}",(long long)n->source_reset_stones);
    }
    sqlite3_str_appendall(json,"]}");*out=sqlite3_str_finish(json);return *out?0:fail(error,"POTENTIAL_NO_MEMORY");
}
int od_potential_cost_plan(const od_potential_board *b,const int64_t *released,size_t released_count,const od_potential_request *requests,size_t request_count,int64_t sa,const od_potential_orbs *inventory,size_t inventory_count,od_potential_plan *out,const char **error){
    if(!bounded_board(b)||!out||!requests||request_count<1||request_count>OD_POTENTIAL_MAX_REQUESTS||request_count>b->node_count||released_count>b->node_count||(released_count&&!released)||inventory_count>4096||(inventory_count&&!inventory)||!valid(sa))return fail(error,"POTENTIAL_INVALID_ARGUMENT");
    for(size_t i=0;i<released_count;i++){if(node_index(b,released[i])<0)return fail(error,"POTENTIAL_STATE_INVALID");for(size_t j=0;j<i;j++)if(released[i]==released[j])return fail(error,"POTENTIAL_STATE_INVALID");}
    for(size_t i=0;i<inventory_count;i++){if(!valid(inventory[i].item_id)||inventory[i].quantity<0||inventory[i].quantity>SAFE)return fail(error,"POTENTIAL_INVENTORY_INVALID");for(size_t j=0;j<i;j++)if(inventory[i].item_id==inventory[j].item_id)return fail(error,"POTENTIAL_INVENTORY_INVALID");}
    od_potential_plan plan={0};plan.master_id=b->master_id;plan.board_id=b->board_id;plan.materials_satisfied=1;
    for(size_t i=0;i<request_count;i++){
        int index=node_index(b,requests[i].node_id);if(index<0)return fail(error,"POTENTIAL_NODE_NOT_FOUND");const od_potential_node *node=&b->nodes[index];
        for(size_t j=0;j<i;j++)if(requests[j].node_id==requests[i].node_id)return fail(error,"POTENTIAL_DUPLICATE_TARGET");
        for(size_t j=0;j<released_count;j++)if(released[j]==node->id)return fail(error,"POTENTIAL_ALREADY_RELEASED");
        od_potential_event event=node->event;
        if(event.kind==OD_POTENTIAL_SELECT){size_t j;for(j=0;j<node->choice_count;j++)if(node->choices[j].id==requests[i].selected_event_id){event=node->choices[j];break;}if(j==node->choice_count)return fail(error,"POTENTIAL_SELECTION_REQUIRED");}
        else if(requests[i].selected_event_id)return fail(error,"POTENTIAL_SELECTION_INVALID");
        plan.effects[plan.effect_count++]=(od_potential_effect){node->id,event};if(node->locked)plan.has_locked_nodes=1;if(node->minimum_sa>plan.minimum_sa)plan.minimum_sa=node->minimum_sa;
        for(size_t j=0;j<node->cost_count;j++){
            size_t k;for(k=0;k<plan.cost_count;k++)if(plan.costs[k].item_id==node->costs[j].item_id)break;
            if(k==plan.cost_count){if(k==OD_POTENTIAL_MAX_RESOURCES)return fail(error,"POTENTIAL_BUDGET_EXCEEDED");plan.costs[plan.cost_count++].item_id=node->costs[j].item_id;}
            if(node->costs[j].quantity>SAFE-plan.costs[k].quantity){return fail(error,"POTENTIAL_COST_OVERFLOW");}plan.costs[k].quantity+=node->costs[j].quantity;
        }
    }
    plan.sa_satisfied=sa>=plan.minimum_sa;
    for(size_t i=0;i<plan.cost_count;i++){
        for(size_t j=0;j<inventory_count;j++)if(plan.costs[i].item_id==inventory[j].item_id){plan.costs[i].available=inventory[j].quantity;break;}
        if(plan.costs[i].available<plan.costs[i].quantity){plan.costs[i].shortfall=plan.costs[i].quantity-plan.costs[i].available;plan.materials_satisfied=0;}
    }
    *out=plan;return 0;
}
int od_potential_plan_view(const od_potential_plan *p,char **out,const char **error){
    if(out){*out=NULL;}if(!p||!out||p->cost_count>OD_POTENTIAL_MAX_RESOURCES||p->effect_count>OD_POTENTIAL_MAX_REQUESTS)return fail(error,"POTENTIAL_INVALID_ARGUMENT");
    sqlite3_str *json=sqlite3_str_new(NULL);sqlite3_str_appendf(json,"{\"master_id\":%lld,\"board_id\":%lld,\"minimum_sa_level\":%lld,\"sa_satisfied\":%s,\"materials_satisfied\":%s,\"has_locked_route_nodes\":%s,\"costs_are_unmultiplied\":true,\"can_commit\":false,\"missing_policy\":[\"owned_card_eligibility\",\"graph_activation\",\"duplicate_route_unlock\"],\"orb_costs\":[",(long long)p->master_id,(long long)p->board_id,(long long)p->minimum_sa,p->sa_satisfied?"true":"false",p->materials_satisfied?"true":"false",p->has_locked_nodes?"true":"false");
    for(size_t i=0;i<p->cost_count;i++)sqlite3_str_appendf(json,"%s{\"item_id\":%lld,\"quantity\":%lld,\"available\":%lld,\"shortfall\":%lld}",i?",":"",(long long)p->costs[i].item_id,(long long)p->costs[i].quantity,(long long)p->costs[i].available,(long long)p->costs[i].shortfall);
    sqlite3_str_appendall(json,"],\"effects\":[");for(size_t i=0;i<p->effect_count;i++){if(i)sqlite3_str_appendall(json,",");sqlite3_str_appendf(json,"{\"node_id\":%lld,\"event\":",(long long)p->effects[i].node_id);event_json(json,&p->effects[i].event);sqlite3_str_appendall(json,"}");}
    sqlite3_str_appendall(json,"]}");*out=sqlite3_str_finish(json);return *out?0:fail(error,"POTENTIAL_NO_MEMORY");
}
