#ifndef __APPLE__
#define _GNU_SOURCE
#endif
#include "../original-client/content/engine_master_attach.h"
#include <errno.h>
#include <fcntl.h>
#include <sqlite3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static int fail(const char *message) { fprintf(stderr, "%s\n", message); return 1; }
static int sha_file(const char *path, char out[65]) {
    char command[512];
    snprintf(command, sizeof command, "sha256sum '%s'", path);
    FILE *pipe = popen(command, "r");
    if (!pipe || fread(out, 1, 64, pipe) != 64) { if (pipe) pclose(pipe); return -1; }
    out[64] = 0;
    return pclose(pipe) == 0 ? 0 : -1;
}
static int make_db(const char *path) {
    sqlite3 *db = NULL;
    if (sqlite3_open(path, &db) != SQLITE_OK) { sqlite3_close(db); return -1; }
    int rc = sqlite3_exec(db, "CREATE TABLE cards(id INTEGER PRIMARY KEY, name TEXT); INSERT INTO cards(name) VALUES ('sample');", NULL, NULL, NULL);
    sqlite3_close(db);
    return rc == SQLITE_OK ? 0 : -1;
}
int main(void) {
    char dir[] = "/tmp/od-engine-master-check-XXXXXX";
    if (!mkdtemp(dir)) return fail("temp");
    char source_path[256], state_path[256], documents_path[256], patcher_path[256];
    snprintf(source_path, sizeof source_path, "%s/source.db", dir);
    snprintf(state_path, sizeof state_path, "%s/state", dir);
    snprintf(documents_path, sizeof documents_path, "%s/Documents", dir);
    snprintf(patcher_path, sizeof patcher_path, "%s/Documents/assets", dir);
    if (mkdir(state_path, 0700) || mkdir(documents_path, 0700) || mkdir(patcher_path, 0700) || make_db(source_path)) return fail("setup");
    char digest[65];
    if (sha_file(source_path, digest)) return fail("hash");
    struct stat source_stat;
    if (stat(source_path, &source_stat)) return fail("stat");
    int source = open(source_path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
    int state = open(state_path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    int patcher = open(patcher_path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    od_engine_master_receipt receipt;
    if (source < 0 || state < 0 || patcher < 0) return fail("open");
    if (od_engine_master_attach(source, patcher, patcher_path, "en", digest, (uint64_t)source_stat.st_size, &receipt) != -1)
        return fail("patcher path was accepted");
    if (od_engine_master_attach(source, state, state_path, "..", digest, (uint64_t)source_stat.st_size, &receipt) != -1)
        return fail("bad language was accepted");
    if (od_engine_master_attach(source, state, state_path, "en", digest, (uint64_t)source_stat.st_size, &receipt) != 0)
        return fail("attach");
    if (!receipt.attached || !receipt.plaintext || !receipt.source_preserved || receipt.source_key_applied ||
        receipt.extension_loading_enabled || receipt.patcher_path_used || receipt.cached_handle_redirected ||
        receipt.engine_keyed_open_observed || strcmp(receipt.relative_path, "sqlite/current/en/database.db"))
        return fail("receipt");
    char published[512];
    snprintf(published, sizeof published, "%s/%s", state_path, receipt.relative_path);
    struct stat copy;
    if (stat(published, &copy) || (copy.st_dev == source_stat.st_dev && copy.st_ino == source_stat.st_ino))
        return fail("working copy aliases the source");
    char again[65];
    if (sha_file(source_path, again) || strcmp(again, digest) || sha_file(published, again) || strcmp(again, digest))
        return fail("bytes changed");
    if (od_engine_master_attach(source, state, state_path, "en", digest, (uint64_t)source_stat.st_size, &receipt) != 0)
        return fail("second attach");
    if (od_engine_master_confirm(source, state, state_path, "en", digest, (uint64_t)source_stat.st_size) != 0)
        return fail("confirm");
    if (od_engine_master_confirm(source, state, state_path, "en", "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", (uint64_t)source_stat.st_size) == 0)
        return fail("wrong hash confirmed");
    close(source); close(state); close(patcher);
    puts("engine master attach checks passed");
    return 0;
}
