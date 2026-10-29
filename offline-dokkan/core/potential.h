#ifndef OD_POTENTIAL_H
#define OD_POTENTIAL_H
#include <stddef.h>
#include <stdint.h>
#include "sqlite3.h"
#ifdef __cplusplus
extern "C" {
#endif
#define OD_POTENTIAL_MAX_NODES 4096
#define OD_POTENTIAL_MAX_LINKS 16
#define OD_POTENTIAL_MAX_COSTS 16
#define OD_POTENTIAL_MAX_CHOICES 16
#define OD_POTENTIAL_MAX_REQUESTS 512
#define OD_POTENTIAL_MAX_RESOURCES 256

typedef enum { OD_POTENTIAL_HP, OD_POTENTIAL_ATK, OD_POTENTIAL_DEF,
    OD_POTENTIAL_SKILL, OD_POTENTIAL_SELECT } od_potential_event_kind;
typedef struct { int64_t id,resource_id,amount; od_potential_event_kind kind; } od_potential_event;
typedef struct { int64_t item_id,quantity; } od_potential_orbs;
typedef struct {
    int64_t id,condition_set_id; int locked,route,has_start_link;
    size_t link_count; int64_t linked_nodes[OD_POTENTIAL_MAX_LINKS];
    size_t cost_count; od_potential_orbs costs[OD_POTENTIAL_MAX_COSTS];
    int64_t minimum_sa; od_potential_event event;
    size_t choice_count; od_potential_event choices[OD_POTENTIAL_MAX_CHOICES];
    int64_t source_reset_stones; /* read-only reset metadata, never an initial-release cost */
} od_potential_node;
typedef struct { int64_t master_id,board_id; size_t node_count; od_potential_node *nodes; } od_potential_board;
typedef struct { int64_t node_id,selected_event_id; } od_potential_request;
typedef struct { int64_t item_id,quantity,available,shortfall; } od_potential_cost;
typedef struct { int64_t node_id; od_potential_event event; } od_potential_effect;
typedef struct {
    int64_t master_id,board_id,minimum_sa;
    int sa_satisfied,materials_satisfied,has_locked_nodes;
    size_t cost_count; od_potential_cost costs[OD_POTENTIAL_MAX_RESOURCES];
    size_t effect_count; od_potential_effect effects[OD_POTENTIAL_MAX_REQUESTS];
} od_potential_plan;

/* Read-only, bounded master facts and cost preview. NOT a release/unlock permission.
 * Relations are preserved as adjacency, including null starter links and cycles. No AND/OR,
 * owned-level eligibility or duplicate-route policy is inferred. The caller resolves same-profile
 * owned identity/level/SA/state. Effective definition may override potential_board_id.
 * No save mutation, material/duplicate consumption, grant multiplier, game HTTP payload or commit.
 * Returns0 success,-1 failure; errors static; views use sqlite3_malloc/free. */
int od_potential_load(sqlite3 *master,int64_t master_id,const char *effective_document,
    od_potential_board **board,const char **error);
void od_potential_free(od_potential_board *board);
int od_potential_view(const od_potential_board *board,char **json,const char **error);
/* All target nodes must be distinct, belong to board, and not already released. A selection node
 * requires an actual permitted event ID; other nodes require selected_event_id=0. Raw orb costs
 * and explicit minimum SA are checked, but even satisfied facts NEVER authorize spending. */
int od_potential_cost_plan(const od_potential_board *board,const int64_t *released,size_t released_count,
    const od_potential_request *requests,size_t request_count,int64_t owned_sa,
    const od_potential_orbs *inventory,size_t inventory_count,od_potential_plan *plan,const char **error);
int od_potential_plan_view(const od_potential_plan *plan,char **json,const char **error);
#ifdef __cplusplus
}
#endif
#endif
