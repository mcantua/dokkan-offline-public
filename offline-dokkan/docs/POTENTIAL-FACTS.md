# Hidden Potential source facts and cost preview

`core/potential.h/.c` implements a bounded read-only board view and raw-orb-cost planner. It does **not** release nodes, unlock routes, consume duplicate cards or authorize a transaction. No game request or response format is claimed. This separation is necessary because the supplied master proves the graph, conditions and rewards but lacks several activation rules.

## What the source establishes

A source/effective card's `potential_board_id` references `potential_boards`. The module requires a real source card and existing selected board; an effective settings document may override that board through a strict integer field. Each board node comes from `potential_squares`: event, condition set, locked flag and optional route. A source-null route is exposed as internal `-1`.

`potential_square_relations` is preserved exactly as adjacency. It is **not** a prerequisite DAG. For example, the supplied board10 contains334 nodes and674 relation rows, with670 reciprocal nonnull links and4 null starter links. Its four locked route roots0–3 each connect to three neighbors. Interpreting all predecessors as mandatory would deadlock the cyclic graph. The module neither symmetrizes nor invents an AND/OR activation rule.

Explicit square conditions are:

- `PotentialSquareCondition::PotentialItem`: actual `item_id` and positive integer `quantity`, checked against `potential_items`.
- `PotentialSquareCondition::SkillLv`: explicit `skill_lv`; the preview reports the highest required value among the selected nodes.

Supported source events are HP, ATK, DEF, skill and selection. Skill references must resolve to actual `potential_skills`. Selection tables expose their actual permitted skill events and `required_stone_for_unrelease`. That last value is **reset metadata**, not an initial-release cost; it is never added to orb totals or automatically charged. Unsupported conditions/events or unresolved references fail explicitly.

## API

```c
od_potential_load(master, master_id, effective_document, &board, &error);
od_potential_view(board, &json, &error);
od_potential_cost_plan(board, released_ids, released_count,
    requests, request_count, owned_sa, orb_inventory, inventory_count,
    &plan, &error);
od_potential_plan_view(&plan, &json, &error);
od_potential_free(board);
```

JSON results use `sqlite3_malloc` and the existing core free boundary. All errors are fixed strings. The module uses SQLite and standard C only. It opens no second database, writes no save, owns no transaction and adds no schema or core operation.

The trusted caller must resolve the same-profile owned card, effective document, current Super Attack level, persisted released-node IDs and actual orb inventory. Requests select distinct unreleased board nodes. A selection node requires one of its actual permitted event IDs; a normal node cannot substitute another event. Already released targets fail to prevent a preview from suggesting another charge. Foreign/duplicate state and duplicate inventory IDs fail. Aggregate quantities use checked JSON-safe integer addition; invalid or insufficient balances are distinguished.

The resulting preview contains exact **unmultiplied** orb requirements, available quantities and shortfalls; the explicit minimum Super Attack level; source-selected effects; and whether requested nodes include locked route roots. Drop multipliers never affect costs. Even when all displayed material and Super Attack requirements pass, every JSON preview returns:

```json
{"can_commit":false,"missing_policy":["owned_card_eligibility","graph_activation","duplicate_route_unlock"]}
```

This is an estimate of explicit source costs, not proof that any selected node is currently reachable or releasable. The module is bounded to4,096 board nodes,16 neighbors/costs/choices per node,512 requested nodes,256 distinct cost resources and4,096 supplied inventory entries. Complete source references and same-board links are checked. Cycles are retained, while self-links, duplicate links, missing relation rows, unsupported route values, invalid JSON types and absent sources fail.

## Required before atomic unlocks

The source does not establish the owned-card/player eligibility gate, exact adjacency activation rule, duplicate identity/awakening-family matching, route-opening operation/cost, or consume/refund semantics. No level, player rank, duplicate match, Dragon Stone cost or default route order is guessed here.

A future verified transaction needs persisted per-instance released nodes/selected events and route state, a validated Potential Orb inventory kind, and lock/current-run checks before any duplicate consumption. It must pin the source content/board and actual owned identity, validate all conditions, atomically debit exact raw materials, consume only an eligible same-profile duplicate, update the board and persist one idempotent receipt. Save import must revalidate that state before activation. None of these future mutations is reachable through this preview API.

## Focused verification

`check_potential.py` opens the supplied master read-only and independently compares the C view with actual SQL relations, conditions and quantities. One combined scenario checks reciprocal/cyclic graph preservation; exact raw orb totals and minimum Super Attack requirements; valid/invalid selections; a one-orb shortfall; duplicate/already-released guards; invalid boolean board overrides; nonexistent source identity; output unchanged after failure; and zero database changes. It passed with strict C11 warnings enabled. No existing gameplay tests, browser build or native package build were run by this module's task.

Reproduce in the cloud with the already available SQLite runtime/header:

```sh
cc -std=c11 -Wall -Wextra -Werror -fPIC -shared \
  -I downloads/sqlite-header offline-dokkan/core/potential.c \
  -Wl,-l:libsqlite3.so.0 -o offline-dokkan/core/build/libpotential-check.so
python3 offline-dokkan/core/check_potential.py
```

Game databases remain ignored and are never committed with the module or its scenario.
