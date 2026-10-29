#include "creator_late_bind.h"
#include <string.h>

static int ready(const od_creator_late_bind_input *in) {
    return in->installed && in->services_pending && !in->services_already_bound && in->services_supplied &&
        in->context_current && in->content_matches && in->scope_current;
}
int od_creator_late_bind_decide(const od_creator_late_bind_input *in, od_creator_late_bind_result *out) {
    if (!out) return -1;
    memset(out, 0, sizeof *out);
    if (!in || !in->on_main) {
        out->action = OD_LATE_BIND_QUEUE;
        return OD_LATE_BIND_QUEUE;
    }
    if (!ready(in)) {
        out->action = OD_LATE_BIND_REJECT;
        return OD_LATE_BIND_REJECT;
    }
    int attach = in->scene_observed && in->controller_present && in->renderer_present;
    out->action = attach ? OD_LATE_BIND_ACCEPT_ATTACH : OD_LATE_BIND_ACCEPT_WAITING;
    out->install_lifecycle = 1;
    out->try_attach = attach;
    out->refresh_shortcut = 1;
    out->clear_pending = 1;
    return out->action;
}
