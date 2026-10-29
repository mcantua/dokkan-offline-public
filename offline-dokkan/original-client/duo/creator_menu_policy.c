#include "creator_menu_policy.h"
#include <string.h>

int od_creator_menu_cocos_hook_installed(void) { return 0; }
const char *od_creator_return_title(int original_client_mode) {
    return original_client_mode ? "Menu" : "Back to Offline Dokkan";
}
const char *od_creator_shortcut_type(void) { return "org.offlinedokkan.integrated-creator"; }
const char *od_creator_shortcut_title(void) { return "Unit Creator"; }
const char *od_creator_shortcut_subtitle(void) { return "Open from the game menu"; }
const char *od_creator_player_menu_identifier(void) { return "in-game-creator-menu"; }
int od_creator_player_menu_should_install(int scoped, int current, int has_target, int has_action, int bar_ready, int button_exists) {
    return scoped && current && has_target && has_action && bar_ready && !button_exists;
}
int od_creator_menu_admit(const od_creator_menu_admission *in) {
    if (!in || !in->context_current) return OD_CREATOR_MENU_REJECTED;
    if (in->creator_already_open) return OD_CREATOR_MENU_ALREADY_OPEN;
    if (!in->installed || !in->scene_observed) return OD_CREATOR_MENU_WAITING;
    /* Late bind: the scene can be up before services attach. Waiting keeps the
     * queued shortcut. Rejecting here drops the tap. */
    if (!in->creator_attached && (in->services_pending || in->services_bound)) return OD_CREATOR_MENU_WAITING;
    if (!in->creator_attached || !in->scene_identity_matches) return OD_CREATOR_MENU_REJECTED;
    return OD_CREATOR_MENU_READY;
}
int od_creator_shortcut_decide(const od_creator_shortcut_input *in, const void *user_info, od_creator_shortcut_decision *out) {
    (void)user_info;
    if (!out) return -1;
    memset(out, 0, sizeof *out);
    if (!in || in->static_count < 0 || in->dynamic_count < 0 || in->static_count > 100000 || in->dynamic_count > 100000) return -1;
    if (in->menu_already_installed || !in->context_current || !in->application_available) return 0;
    int existing = in->dynamic_has_type || in->static_has_type;
    int full = !existing && (in->static_count >= 4 || in->dynamic_count >= 4 || in->static_count + in->dynamic_count >= 4);
    if (full) {
        out->report_unavailable = 1;
        return 0;
    }
    out->mark_installed = 1;
    out->add_dynamic_item = !existing;
    return 0;
}
