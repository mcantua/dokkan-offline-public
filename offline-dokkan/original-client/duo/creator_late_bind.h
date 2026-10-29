#ifndef OD_CREATOR_LATE_BIND_H
#define OD_CREATOR_LATE_BIND_H
#ifdef __cplusplus
extern "C" {
#endif
/* Decision for Creator services that arrive after UIApplicationMain.
 * OD_LATE_BIND_QUEUE means the caller must retry on main and must not wait.
 * ACCEPT_WAITING keeps a queued shortcut until the admitted renderer attaches.
 */
enum {
    OD_LATE_BIND_QUEUE = 1,
    OD_LATE_BIND_REJECT = 2,
    OD_LATE_BIND_ACCEPT_WAITING = 3,
    OD_LATE_BIND_ACCEPT_ATTACH = 4
};
typedef struct {
    int on_main;
    int installed;
    int services_pending;
    int services_already_bound;
    int services_supplied;
    int context_current;
    int content_matches;
    int scope_current;
    int scene_observed;
    int controller_present;
    int renderer_present;
} od_creator_late_bind_input;
typedef struct {
    int action;
    int install_lifecycle;
    int try_attach;
    int refresh_shortcut;
    int clear_pending;
} od_creator_late_bind_result;
int od_creator_late_bind_decide(const od_creator_late_bind_input *in, od_creator_late_bind_result *out);
#ifdef __cplusplus
}
#endif
#endif
