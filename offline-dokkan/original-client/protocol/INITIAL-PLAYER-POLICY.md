# Initial offline player: approved policy and missing inputs

Tin’s latest request removes the intro/tutorial sequence for new players.
New profiles skip that sequence; existing profiles and their progress stay
unchanged. There are no invented free stones, cards or event unlocks. The existing canonical Core already creates an empty collection
and ledger. Its rank1/EXP0/max ACT facts and friends capacity come from the
selected master, not a copied played account or hard-coded response sample.
The projector already exposes those persisted facts. No additional starting
grant was found in the approved notes.

Read for this reconciliation:

- `context/PROJECT-NOTES.md`, Offline Dokkan section.
- `projects/OFFLINE-DOKKAN-PLAN.md`, progression and created-character rules.
- `offline-dokkan/docs/SERVER-SPEC.md`, especially fresh offline login and
  initial-state requirements.
- `original-client/protocol/README.md`, `fresh-state-policy.js` and
  `ios/ODFreshStatePolicy.h/.m`.
- `original-client/master/fresh-policy-findings.json` and
  `research/fresh-master-structural-contract.json`.
- `protocol-inspection/TUTORIAL-STATE-CONTRACT.md`,
  `TUTORIAL-UPDATE-CONTRACT.md` and `FRESH-MASTER-SOURCE-FACTS.md`.

All these local files were accessible. No old repository, account cache,
personal configuration, save folder or signing material was read. No app
build, database rescan or repeated completed-feature check was needed.

## Native-owned partial tutorial state

The actual native finished flag selects the original TitleLoadingLayer’s
normal continuation; false enters its tutorial. Schema14 stores the explicitly
authorized new-player policy only on a successful new-profile INSERT:
`{schema:1,policy:"offline-new-player-skip-v1",progress:0,is_finished:true}`.
No999999 marker, arbitrary tutorial content level, reward or starter unit is
inferred. This is our own approved skip policy, not a copied server default.

Every old tutorial row is copied unchanged during migration. Old unfinished
checkpoints keep their `original-tutorial-entry-v1` policy and native writer;
skip profiles refuse that writer. Older profiles with no tutorial row remain
unresolved. The snapshot emits the actual stored boolean. The full fresh-state
gate and new-profile projector accept only the exact canonical policy tuples.
See `../protocol-inspection/TUTORIAL-RUNTIME-CONSUMERS.md` and
`../../core/new-player-skip-evidence.json` for source/check limits.

## Remaining state and authority

The real iPhone User decoder places these fields as follows:

| Field | Native representation | Missing authority |
|---|---|---|
| `user.tutorial.progress` | unsigned32 | Canonical Schema14 state; unresolved for older profiles without it |
| `user.tutorial.contents_lv` | unsigned32 | Initial tutorial content level and its consumer mapping |
| `user.tutorial.is_finished` | boolean | New-only skip policy is true; existing checkpoints preserved; older missing state unresolved |
| `user.card_capacity` | unsigned32 | Initial owned-card capacity |
| `user.total_card_capacity` | unsigned32 | Relationship to the initial card capacity; do not assume equality |
| `user.support_item_capacity` | unsigned32 | Initial support-item capacity |
| `user.is_support_item_capacity_extended` | boolean | Initial capacity-extension state |

Absent scalar members preserve the native object's prior value; present JSON null is not the same condition. This is
decoder behavior, not proof of a valid fresh-account server default. The
fresh policy keeps remaining fields unresolved. It must not be unlocked by
treating pre-server capacity0 or an unbound finished flag as authoritative. Only the exact canonical new-profile skip policy supplies true.

The master has tutorial definitions but no column establishing these seven
initial user values. Its first phase is not automatically wire `progress` or
`contents_lv`. Shop expansion settings are not starting capacities.

## Smallest actual decision or evidence needed

There are two policy groups, not seven unrelated feature requests:

1. **First-run tutorial:** new-profile skip is now explicitly authorized and
   persisted. Preserve old checkpoints and finish the original normal
   continuation without inventing units or filling unknown fields.
2. **Starting storage limits:** establish the four card/support capacity
   fields from a verified fresh-state source, or obtain one explicit approved
   local capacity policy. Do not use a played account's expanded limits.

Remaining inputs are not yet configured. `initial-player-policy-requirements.json`
is a gap audit, **not a runtime configuration or default response**. Existing
gates remain closed. Auth, startup, resource and original combat work can
continue independently while this evidence is recovered.

## First battle and teams

A genuinely fresh empty collection cannot be assumed to contain a legal normal
team. Preserve the original tutorial's starter/temporary combat flow; the first
real battle may occur before Home. Do not grant arbitrary units or skip the
tutorial merely to satisfy a home→team→battle checklist.

The original team DTO also differs from canonical Core storage. Core stores
`teams[{slot,members}]`; the native reader expects selected team metadata and
`user_card_teams[{num,name,user_card_ids,bgm}]`. Slot mapping, initial selected
team and BGM/name policy are separate native-adapter requirements owned by the
player/team workstream. No mapping or populated team was invented here.

This reconciliation implements no new gameplay or response route. It preserves
the approved fresh profile while identifying the exact input boundary that
still prevents claiming a complete first-run player response.
