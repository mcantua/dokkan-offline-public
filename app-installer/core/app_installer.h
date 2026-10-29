#ifndef APP_INSTALLER_H
#define APP_INSTALLER_H
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
typedef enum { AI_OK=0, AI_NOT_READY=1, AI_APP_LIMIT=2, AI_APP_ID_LIMIT=3, AI_UNKNOWN_USAGE=4, AI_INVALID_ARGUMENT=5, AI_BUSY=6, AI_STORAGE_LOCKED=7 } AIStatus;
bool ai_backend_ready(void);
AIStatus ai_initialize(const char *work_dir);
AIStatus ai_register_self_bundle(const char *app_bundle_path);
AIStatus ai_restore_session(void);
AIStatus ai_resend_2fa(void);
/* action: 0 resend, 1 trusted devices, 2 SMS to an ID from twoFactorNumbers. */
AIStatus ai_request_2fa(int32_t action, uint32_t number_id);
AIStatus ai_select_team(const char *team_id);
void ai_lock(void);
AIStatus ai_import_pairing(const uint8_t *bytes, size_t length);
AIStatus ai_set_device_host(const char *host);
/* Local runtime configuration only; discovery data is never included in UI JSON. */
AIStatus ai_set_remote_pairing_port(uint16_t port);
int32_t ai_pairing_kind(void);
bool ai_match_remote_pairing_service(const char *identifier, const char *auth_tag);
void ai_cancel(void);
AIStatus ai_sign_out(void);
/* JSON buffers contain only safe UI state and app metadata; free each returned buffer. */
char *ai_poll_event_json(void);
char *ai_snapshot_json(void);
void ai_free_string(char *value);
const char *ai_status_message(void);
AIStatus ai_login(const char *email, const char *password);
AIStatus ai_submit_2fa(const char *code);
AIStatus ai_sign_ipa(const char *path);
AIStatus ai_install_ipa(const char *path);
AIStatus ai_list_installed(void);
AIStatus ai_refresh_all(void);
bool ai_needs_warning(int64_t expiry, int64_t now);
#endif
