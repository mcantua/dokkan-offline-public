#ifndef OD_STARTUP_PROVENANCE_H
#define OD_STARTUP_PROVENANCE_H
/* Native-only, own org.offlinedokkan.duo container descriptors. The marker
 * stores no account/save data. It binds fixed source identities and the same
 * actual Documents/assets/state directories, not their path spelling.
 * It never opens User/current or changes existing native game data.
 * Read returns 1 for the exact own receipt, 0 if absent, -1 if invalid. */
int od_startup_provenance_read(int state, int documents, int assets);
/* Publish only after trusted first resource preparation; never replaces an
 * existing marker. Return 0 on success, -1 on error. */
int od_startup_provenance_publish(int state, int documents, int assets);
#endif
