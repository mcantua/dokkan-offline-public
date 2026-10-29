#ifndef OD_CREATOR_MENU_POLICY_H
#define OD_CREATOR_MENU_POLICY_H
#ifdef __cplusplus
extern "C" {
#endif
/* Same numeric values as ODDuoCreatorQuickActionReadiness. */
enum {
    OD_CREATOR_MENU_WAITING = 0,
    OD_CREATOR_MENU_READY = 1,
    OD_CREATOR_MENU_ALREADY_OPEN = 2,
    OD_CREATOR_MENU_REJECTED = 3
};
typedef struct {
    int context_current;
    int creator_already_open;
    int installed;
    int scene_observed;
    int creator_attached;
    int services_pending;
    int services_bound;
    int scene_identity_matches;
} od_creator_menu_admission;
typedef struct {
    int context_current;
    int application_available;
    int menu_already_installed;
    int dynamic_has_type;
    int static_has_type;
    int static_count;
    int dynamic_count;
} od_creator_shortcut_input;
typedef struct {
    int mark_installed;
    int add_dynamic_item;
    int report_unavailable;
    int cocos_hook_installed;
    int user_info_grants_access;
} od_creator_shortcut_decision;
int od_creator_menu_admit(const od_creator_menu_admission *in);
int od_creator_shortcut_decide(const od_creator_shortcut_input *in, const void *user_info, od_creator_shortcut_decision *out);
int od_creator_player_menu_should_install(int scoped, int current, int has_target, int has_action, int bar_ready, int button_exists);
const char *od_creator_return_title(int original_client_mode);
const char *od_creator_shortcut_type(void);
const char *od_creator_shortcut_title(void);
const char *od_creator_shortcut_subtitle(void);
const char *od_creator_player_menu_identifier(void);
int od_creator_menu_cocos_hook_installed(void);
#ifdef __cplusplus
}
#endif
#endif
