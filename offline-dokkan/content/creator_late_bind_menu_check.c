#include "../original-client/duo/creator_late_bind.h"
#include "../original-client/duo/creator_menu_policy.h"
#include <stdio.h>
#include <string.h>

static int fail(const char *message) { fprintf(stderr, "%s\n", message); return 1; }
static od_creator_late_bind_input bound_input(void) {
    od_creator_late_bind_input in;
    memset(&in, 0, sizeof in);
    in.on_main = 1;
    in.installed = 1;
    in.services_pending = 1;
    in.services_supplied = 1;
    in.context_current = 1;
    in.content_matches = 1;
    in.scope_current = 1;
    return in;
}
static int check_bind(void) {
    od_creator_late_bind_result out;
    od_creator_late_bind_input in = bound_input();
    in.on_main = 0;
    in.installed = 0;
    if (od_creator_late_bind_decide(&in, &out) != OD_LATE_BIND_QUEUE || out.refresh_shortcut || out.clear_pending)
        return fail("off-main bind must queue without applying");
    if (od_creator_late_bind_decide(NULL, &out) != OD_LATE_BIND_QUEUE) return fail("null input must queue");
    if (od_creator_late_bind_decide(&in, NULL) != -1) return fail("null result");
    in = bound_input();
    in.installed = 0;
    if (od_creator_late_bind_decide(&in, &out) != OD_LATE_BIND_REJECT) return fail("bind before install");
    in = bound_input();
    in.content_matches = 0;
    if (od_creator_late_bind_decide(&in, &out) != OD_LATE_BIND_REJECT) return fail("content mismatch");
    in = bound_input();
    in.scope_current = 0;
    if (od_creator_late_bind_decide(&in, &out) != OD_LATE_BIND_REJECT) return fail("scope mismatch");
    in = bound_input();
    in.services_already_bound = 1;
    if (od_creator_late_bind_decide(&in, &out) != OD_LATE_BIND_REJECT) return fail("second bind");
    in = bound_input();
    if (od_creator_late_bind_decide(&in, &out) != OD_LATE_BIND_ACCEPT_WAITING || out.try_attach || !out.refresh_shortcut || !out.clear_pending || !out.install_lifecycle)
        return fail("bind should wait for the renderer and keep the shortcut");
    in.scene_observed = 1;
    in.controller_present = 1;
    in.renderer_present = 1;
    if (od_creator_late_bind_decide(&in, &out) != OD_LATE_BIND_ACCEPT_ATTACH || !out.try_attach || !out.refresh_shortcut)
        return fail("admitted scene should attach");
    return 0;
}
static int check_menu(void) {
    od_creator_menu_admission menu;
    memset(&menu, 0, sizeof menu);
    if (od_creator_menu_admit(NULL) != OD_CREATOR_MENU_REJECTED) return fail("null menu");
    if (od_creator_menu_admit(&menu) != OD_CREATOR_MENU_REJECTED) return fail("dead context");
    menu.context_current = 1;
    menu.creator_already_open = 1;
    if (od_creator_menu_admit(&menu) != OD_CREATOR_MENU_ALREADY_OPEN) return fail("already open");
    menu.creator_already_open = 0;
    menu.installed = 1;
    menu.scene_observed = 1;
    menu.services_pending = 1;
    if (od_creator_menu_admit(&menu) != OD_CREATOR_MENU_WAITING) return fail("pending services must wait");
    menu.services_pending = 0;
    menu.services_bound = 1;
    if (od_creator_menu_admit(&menu) != OD_CREATOR_MENU_WAITING) return fail("bound services must wait until attached");
    menu.services_bound = 0;
    if (od_creator_menu_admit(&menu) != OD_CREATOR_MENU_REJECTED) return fail("no services");
    menu.services_bound = 1;
    menu.creator_attached = 1;
    if (od_creator_menu_admit(&menu) != OD_CREATOR_MENU_REJECTED) return fail("identity mismatch");
    menu.scene_identity_matches = 1;
    if (od_creator_menu_admit(&menu) != OD_CREATOR_MENU_READY) return fail("ready menu");
    menu.installed = 0;
    if (od_creator_menu_admit(&menu) != OD_CREATOR_MENU_WAITING) return fail("scene before install");
    if (od_creator_player_menu_should_install(1, 1, 1, 1, 0, 0)) return fail("player menu before the bar");
    if (!od_creator_player_menu_should_install(1, 1, 1, 1, 1, 0)) return fail("player menu should install");
    if (od_creator_player_menu_should_install(1, 1, 1, 1, 1, 1)) return fail("player menu installed twice");
    if (od_creator_player_menu_should_install(0, 1, 1, 1, 1, 0)) return fail("unscoped player menu");
    if (strcmp(od_creator_return_title(1), "Menu") || strcmp(od_creator_return_title(0), "Back to Offline Dokkan"))
        return fail("return title");
    if (strcmp(od_creator_player_menu_identifier(), "in-game-creator-menu")) return fail("identifier");
    if (od_creator_menu_cocos_hook_installed()) return fail("cocos hook");
    od_creator_shortcut_input shortcut;
    memset(&shortcut, 0, sizeof shortcut);
    od_creator_shortcut_decision decision;
    shortcut.context_current = 1;
    shortcut.application_available = 1;
    char payload[] = "not-authority";
    if (od_creator_shortcut_decide(&shortcut, payload, &decision) || !decision.mark_installed || !decision.add_dynamic_item ||
        decision.cocos_hook_installed || decision.user_info_grants_access)
        return fail("shortcut registration");
    shortcut.dynamic_has_type = 1;
    if (od_creator_shortcut_decide(&shortcut, payload, &decision) || !decision.mark_installed || decision.add_dynamic_item)
        return fail("existing shortcut");
    shortcut.dynamic_has_type = 0;
    shortcut.static_count = 4;
    if (od_creator_shortcut_decide(&shortcut, NULL, &decision) || !decision.report_unavailable || decision.mark_installed || decision.add_dynamic_item)
        return fail("full shortcut menu");
    shortcut.static_count = 0;
    shortcut.application_available = 0;
    if (od_creator_shortcut_decide(&shortcut, NULL, &decision) || decision.mark_installed) return fail("missing application");
    if (strcmp(od_creator_shortcut_type(), "org.offlinedokkan.integrated-creator") || strcmp(od_creator_shortcut_title(), "Unit Creator"))
        return fail("shortcut label");
    return 0;
}
int main(void) {
    if (check_bind() || check_menu()) return 1;
    puts("late bind and creator menu checks passed");
    return 0;
}
