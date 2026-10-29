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
static int scan_file(const char *path) {
    FILE *file = fopen(path, "r");
    if (!file) return fail(path);
    char buffer[4096];
    size_t carry = 0;
    int saw_guard = 0, saw_disable = 0, bad = 0;
    while (fgets(buffer + carry, (int)(sizeof buffer - carry), file)) {
        if (strstr(buffer, "sqlite3_key(") || strstr(buffer, "PRAGMA cipher") || strstr(buffer, "cipher_compatibility")) bad = 1;
        if (strstr(buffer, "SQLITE_OMIT_LOAD_EXTENSION")) saw_guard = 1;
        if (strstr(buffer, "sqlite3_enable_load_extension") && strstr(buffer, ", 0)")) saw_disable = 1;
        if (strstr(buffer, "sqlite3_enable_load_extension") && strstr(buffer, ", 1)")) bad = 1;
        carry = 0;
    }
    fclose(file);
    if (bad) return fail(path);
    if (strstr(path, "engine_master_attach.c") && (!saw_guard || !saw_disable)) return fail("extension guard missing");
    return 0;
}

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
    if (scan_file("offline-dokkan/original-client/content/engine_master_attach.c")) return 1;
    if (scan_file("offline-dokkan/original-client/content/engine_master_attach.h")) return 1;
    if (scan_file("offline-dokkan/original-client/duo/ODUnifiedDuoHost.m")) return 1;
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
    if (receipt.keyed_open_refused || receipt.flags6_refused || receipt.readonly_resolved)
        return fail("attach claimed the readonly gate");
    struct stat mode;
    if (stat(published, &mode) || (mode.st_mode & 0777) != 0400) return fail("published master is writable");
    int writable = open(published, O_RDWR | O_NOFOLLOW | O_CLOEXEC);
    if (writable >= 0) { close(writable); return fail("published master accepted a write open"); }
    char key_bytes[] = "sample-key-material";
    char key_copy[sizeof key_bytes];
    memcpy(key_copy, key_bytes, sizeof key_bytes);
    int readonly = -1;
    if (od_engine_master_resolve_readonly(source, state, state_path, "en", digest, (uint64_t)source_stat.st_size,
            SQLITE_OPEN_READONLY, key_bytes, sizeof key_bytes - 1, 0, 0, 0, &readonly, &receipt) != -5 || readonly >= 0)
        return fail("key was accepted");
    if (memcmp(key_bytes, key_copy, sizeof key_bytes) || !receipt.keyed_open_refused) return fail("key bytes changed");
    if (od_engine_master_resolve_readonly(source, state, state_path, "en", digest, (uint64_t)source_stat.st_size,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL, 0, 0, 0, 0, &readonly, &receipt) != -6 || !receipt.flags6_refused)
        return fail("flags 6 were accepted");
    if (od_engine_master_resolve_readonly(source, state, state_path, "en", digest, (uint64_t)source_stat.st_size,
            SQLITE_OPEN_READONLY, NULL, 0, 1, 0, 0, &readonly, &receipt) != -7)
        return fail("cipher pragma was accepted");
    if (od_engine_master_resolve_readonly(source, state, state_path, "en", digest, (uint64_t)source_stat.st_size,
            SQLITE_OPEN_READONLY, NULL, 0, 0, 1, 0, &readonly, &receipt) != -7)
        return fail("extension loading was accepted");
    if (od_engine_master_resolve_readonly(source, patcher, patcher_path, "en", digest, (uint64_t)source_stat.st_size,
            SQLITE_OPEN_READONLY, NULL, 0, 0, 0, 0, &readonly, &receipt) != -8 || !receipt.patcher_path_used)
        return fail("patcher path was resolved");
    if (od_engine_master_resolve_readonly(source, state, state_path, "en", digest, (uint64_t)source_stat.st_size,
            SQLITE_OPEN_READONLY, NULL, 0, 0, 0, 1, &readonly, &receipt) != -8 || !receipt.cached_handle_redirected)
        return fail("cached handle redirect was accepted");
    if (od_engine_master_resolve_readonly(source, state, state_path, "en", digest, (uint64_t)source_stat.st_size,
            OD_ENGINE_MASTER_OPEN_READONLY, NULL, 0, 0, 0, 0, &readonly, &receipt) != 0)
        return fail("readonly resolve");
    char probe = 0;
    if (readonly < 0 || write(readonly, &probe, 1) >= 0 || !receipt.readonly_resolved || !receipt.keyed_open_refused ||
        !receipt.flags6_refused || receipt.engine_keyed_open_observed || receipt.source_key_applied ||
        receipt.extension_loading_enabled || strcmp(receipt.relative_path, "sqlite/current/en/database.db"))
        return fail("readonly receipt");
    close(readonly);
    int same = 0;
    if (od_engine_master_asset_root_matches(source, state, state_path, state, state_path, "en", &same) != 0 || same != 1)
        return fail("state root should see its own published copy");
    char other_path[256];
    snprintf(other_path, sizeof other_path, "%s/other-root", dir);
    if (mkdir(other_path, 0700)) return fail("other root");
    int other = open(other_path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    same = 1;
    if (other < 0 || od_engine_master_asset_root_matches(source, state, state_path, other, other_path, "en", &same) != 0 || same != 0)
        return fail("empty asset root matched");
    if (od_engine_master_asset_root_matches(source, state, state_path, patcher, patcher_path, "en", &same) != -8)
        return fail("patcher asset root was compared");
    char linked_root[256], linked_sqlite[256], linked_current[256], linked_lang[256], linked_db[256];
    snprintf(linked_root, sizeof linked_root, "%s/linked-root", dir);
    snprintf(linked_sqlite, sizeof linked_sqlite, "%s/sqlite", linked_root);
    snprintf(linked_current, sizeof linked_current, "%s/current", linked_sqlite);
    snprintf(linked_lang, sizeof linked_lang, "%s/en", linked_current);
    snprintf(linked_db, sizeof linked_db, "%s/database.db", linked_lang);
    if (mkdir(linked_root, 0700) || mkdir(linked_sqlite, 0700) || mkdir(linked_current, 0700) || mkdir(linked_lang, 0700) ||
        link(source_path, linked_db))
        return fail("source link");
    int linked = open(linked_root, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    same = 1;
    if (linked < 0 || od_engine_master_asset_root_matches(source, state, state_path, linked, linked_root, "en", &same) != 0 || same != 0)
        return fail("source inode was treated as the engine master");
    if (unlink(linked_db) || link(published, linked_db)) return fail("copy link");
    if (od_engine_master_asset_root_matches(source, state, state_path, linked, linked_root, "en", &same) != 0 || same != 1)
        return fail("published inode was not recognized");
    close(other); close(linked);
    close(source); close(state); close(patcher);
    puts("engine master attach checks passed");
    return 0;
}
