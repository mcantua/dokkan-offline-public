#ifndef __APPLE__
#define _GNU_SOURCE
#endif
#include "engine_master_attach.h"
#include "sqlite3.h"
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#if OD_ENGINE_MASTER_OPEN_READONLY != SQLITE_OPEN_READONLY
#error OD_ENGINE_MASTER_OPEN_READONLY drifted from SQLITE_OPEN_READONLY
#endif
#if (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE) != 6
#error MAIN open flags 6 are no longer READWRITE|CREATE
#endif

static int hex64(const char *s) {
    if (!s || strlen(s) != 64) return 0;
    for (int i = 0; i < 64; i++) if (!((s[i] >= '0' && s[i] <= '9') || (s[i] >= 'a' && s[i] <= 'f'))) return 0;
    return 1;
}
static int language_ok(const char *s) {
    return s && s[0] >= 'a' && s[0] <= 'z' && s[1] >= 'a' && s[1] <= 'z' && s[2] == 0;
}
static int patcher_path(const char *path) {
    const char *mark = "/Documents/assets";
    const char *found = path ? strstr(path, mark) : NULL;
    if (!found) return 0;
    char next = found[strlen(mark)];
    return next == '/' || next == 0;
}
static uint32_t rotr(uint32_t x, uint32_t n) { return (x >> n) | (x << (32 - n)); }
typedef struct { uint32_t s[8]; uint64_t bits; unsigned char buf[64]; size_t n; } od_sha256;
static void sha_block(od_sha256 *h, const unsigned char *p) {
    static const uint32_t k[64] = {
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
    uint32_t w[64];
    for (int i = 0; i < 16; i++) w[i] = ((uint32_t)p[i * 4] << 24) | ((uint32_t)p[i * 4 + 1] << 16) | ((uint32_t)p[i * 4 + 2] << 8) | p[i * 4 + 3];
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
        uint32_t s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }
    uint32_t a = h->s[0], b = h->s[1], c = h->s[2], d = h->s[3], e = h->s[4], f = h->s[5], g = h->s[6], hh = h->s[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = hh + S1 + ch + k[i] + w[i];
        uint32_t S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
        uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
        hh = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + S0 + maj;
    }
    h->s[0] += a; h->s[1] += b; h->s[2] += c; h->s[3] += d; h->s[4] += e; h->s[5] += f; h->s[6] += g; h->s[7] += hh;
}
static void sha_init(od_sha256 *h) {
    memset(h, 0, sizeof *h);
    h->s[0] = 0x6a09e667; h->s[1] = 0xbb67ae85; h->s[2] = 0x3c6ef372; h->s[3] = 0xa54ff53a;
    h->s[4] = 0x510e527f; h->s[5] = 0x9b05688c; h->s[6] = 0x1f83d9ab; h->s[7] = 0x5be0cd19;
}
static void sha_update(od_sha256 *h, const unsigned char *p, size_t n) {
    h->bits += (uint64_t)n * 8;
    while (n) {
        size_t room = 64 - h->n;
        size_t take = n < room ? n : room;
        memcpy(h->buf + h->n, p, take);
        h->n += take; p += take; n -= take;
        if (h->n == 64) { sha_block(h, h->buf); h->n = 0; }
    }
}
static void sha_final(od_sha256 *h, char out[65]) {
    uint64_t bits = h->bits;
    h->buf[h->n++] = 0x80;
    if (h->n > 56) {
        while (h->n < 64) h->buf[h->n++] = 0;
        sha_block(h, h->buf);
        h->n = 0;
    }
    while (h->n < 56) h->buf[h->n++] = 0;
    for (int i = 0; i < 8; i++) h->buf[56 + i] = (unsigned char)(bits >> (56 - 8 * i));
    sha_block(h, h->buf);
    for (int i = 0; i < 8; i++) snprintf(out + i * 8, 9, "%08x", h->s[i]);
}
static int hash_fd(int fd, uint64_t expected, char out[65]) {
    od_sha256 hash; sha_init(&hash);
    unsigned char buffer[65536];
    uint64_t total = 0;
    off_t at = 0;
    for (;;) {
        ssize_t n = pread(fd, buffer, sizeof buffer, at);
        if (n < 0) { if (errno == EINTR) continue; return -1; }
        if (n == 0) break;
        if (total + (uint64_t)n > expected) return -1;
        sha_update(&hash, buffer, (size_t)n);
        total += (uint64_t)n; at += n;
    }
    if (total != expected) return -1;
    sha_final(&hash, out);
    return 0;
}
static int same_dir(int fd, const char *path) {
    struct stat pinned, current;
    return !fstat(fd, &pinned) && !lstat(path, &current) && S_ISDIR(current.st_mode) &&
        !S_ISLNK(current.st_mode) && current.st_dev == pinned.st_dev && current.st_ino == pinned.st_ino;
}
static int subdir(int parent, const char *name) {
    int fd = openat(parent, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (fd >= 0) return fd;
    if (errno != ENOENT) return -1;
    if (mkdirat(parent, name, 0700) && errno != EEXIST) return -1;
    if (fsync(parent)) return -1;
    return openat(parent, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
}
static int relative_for(const char *language, char out[64]) {
    int n = snprintf(out, 64, "sqlite/current/%s/database.db", language);
    return n > 0 && n < 64;
}
static int verify_plaintext(const char *path, int fd) {
    struct stat file, live;
    if (fstat(fd, &file) || lstat(path, &live) || S_ISLNK(live.st_mode) || !S_ISREG(live.st_mode) ||
        file.st_dev != live.st_dev || file.st_ino != live.st_ino) return -4;
    sqlite3 *db = NULL;
    sqlite3_stmt *statement = NULL;
    int rc = -4;
    if (sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOFOLLOW, NULL) != SQLITE_OK) goto done;
#ifndef SQLITE_OMIT_LOAD_EXTENSION
    if (sqlite3_enable_load_extension(db, 0) != SQLITE_OK) goto done;
#endif
    if (sqlite3_db_readonly(db, "main") != 1) goto done;
    if (sqlite3_exec(db, "PRAGMA query_only=ON;", NULL, NULL, NULL) != SQLITE_OK) goto done;
    if (sqlite3_prepare_v2(db, "SELECT count(*) FROM sqlite_master", -1, &statement, NULL) != SQLITE_OK) goto done;
    if (sqlite3_step(statement) != SQLITE_ROW) goto done;
    rc = 0;
done:
    sqlite3_finalize(statement);
    sqlite3_close(db);
    return rc;
}
static int arguments_ok(int source_fd, int state_dir_fd, const char *state_dir_path, const char *language, const char *expected_sha256, uint64_t expected_bytes) {
    struct stat source;
    return source_fd >= 0 && state_dir_fd >= 0 && state_dir_path && state_dir_path[0] == '/' &&
        !strstr(state_dir_path, "/../") && !patcher_path(state_dir_path) && language_ok(language) &&
        hex64(expected_sha256) && expected_bytes >= 100 && expected_bytes <= 256ull * 1024ull * 1024ull &&
        !fstat(source_fd, &source) && S_ISREG(source.st_mode) && source.st_size == (off_t)expected_bytes &&
        same_dir(state_dir_fd, state_dir_path);
}
static void clear_receipt(od_engine_master_receipt *receipt) {
    if (!receipt) return;
    memset(receipt, 0, sizeof *receipt);
}
static int publish(int source_fd, int state_dir_fd, const char *state_dir_path, const char *language, const char *expected_sha256, uint64_t expected_bytes, int create, od_engine_master_receipt *receipt) {
    clear_receipt(receipt);
    if (!arguments_ok(source_fd, state_dir_fd, state_dir_path, language, expected_sha256, expected_bytes) || (create && !receipt)) return -1;
    char relative[64];
    if (!relative_for(language, relative)) return -1;
    char source_hash[65];
    if (hash_fd(source_fd, expected_bytes, source_hash) || strcmp(source_hash, expected_sha256)) return -2;
    unsigned char header[16];
    if (pread(source_fd, header, sizeof header, 0) != sizeof header || memcmp(header, "SQLite format 3", 16)) return -2;
    struct stat source;
    if (fstat(source_fd, &source)) return -2;
    int sqlite_fd = subdir(state_dir_fd, "sqlite");
    int current_fd = sqlite_fd < 0 ? -1 : subdir(sqlite_fd, "current");
    int language_fd = current_fd < 0 ? -1 : subdir(current_fd, language);
    if (language_fd < 0) { if (sqlite_fd >= 0) close(sqlite_fd); if (current_fd >= 0) close(current_fd); return -3; }
    int created = 0;
    int dest = openat(language_fd, "database.db", O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
    if (dest < 0 && errno == ENOENT && create) {
        dest = openat(language_fd, "database.db", O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
        created = dest >= 0;
        if (created) {
            unsigned char buffer[65536];
            uint64_t total = 0;
            off_t at = 0;
            int write_ok = 1;
            while (write_ok && total < expected_bytes) {
                ssize_t n = pread(source_fd, buffer, sizeof buffer, at);
                if (n < 0) { if (errno == EINTR) continue; write_ok = 0; break; }
                if (n == 0) { write_ok = 0; break; }
                size_t wrote = 0;
                while (wrote < (size_t)n) {
                    ssize_t w = write(dest, buffer + wrote, (size_t)n - wrote);
                    if (w < 0 && errno == EINTR) continue;
                    if (w <= 0) { write_ok = 0; break; }
                    wrote += (size_t)w;
                }
                total += (uint64_t)n; at += n;
            }
            if (!write_ok || total != expected_bytes || fsync(dest)) {
                close(dest); unlinkat(language_fd, "database.db", 0);
                close(language_fd); close(current_fd); close(sqlite_fd); return -3;
            }
            close(dest);
            dest = openat(language_fd, "database.db", O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
        }
    }
    if (dest < 0) { close(language_fd); close(current_fd); close(sqlite_fd); return create ? -3 : -3; }
    char dest_hash[65];
    struct stat copy;
    int hashed = hash_fd(dest, expected_bytes, dest_hash);
    int identity = fstat(dest, &copy);
    if (hashed || identity || strcmp(dest_hash, expected_sha256) || (copy.st_dev == source.st_dev && copy.st_ino == source.st_ino)) {
        if (created) { close(dest); unlinkat(language_fd, "database.db", 0); }
        else close(dest);
        close(language_fd); close(current_fd); close(sqlite_fd); return -3;
    }
    char full[1024];
    int length = snprintf(full, sizeof full, "%s/%s", state_dir_path, relative);
    if (length < 0 || (size_t)length >= sizeof full || verify_plaintext(full, dest)) {
        if (created) { close(dest); unlinkat(language_fd, "database.db", 0); }
        else close(dest);
        close(language_fd); close(current_fd); close(sqlite_fd); return -4;
    }
    if (fchmod(dest, 0400) || fsync(dest) || fsync(language_fd)) {
        if (created) { close(dest); unlinkat(language_fd, "database.db", 0); }
        else close(dest);
        close(language_fd); close(current_fd); close(sqlite_fd); return -3;
    }
    close(dest); close(language_fd); close(current_fd); close(sqlite_fd);
    if (!receipt) return 0;
    snprintf(receipt->relative_path, sizeof receipt->relative_path, "%s", relative);
    receipt->attached = 1;
    receipt->plaintext = 1;
    receipt->source_preserved = 1;
    return 0;
}
int od_engine_master_attach(int source_fd, int state_dir_fd, const char *state_dir_path, const char *language, const char *expected_sha256, uint64_t expected_bytes, od_engine_master_receipt *receipt) {
    return publish(source_fd, state_dir_fd, state_dir_path, language, expected_sha256, expected_bytes, 1, receipt);
}
int od_engine_master_confirm(int source_fd, int state_dir_fd, const char *state_dir_path, const char *language, const char *expected_sha256, uint64_t expected_bytes) {
    return publish(source_fd, state_dir_fd, state_dir_path, language, expected_sha256, expected_bytes, 0, NULL);
}
static int open_published_db(int root, const char *language, int *missing) {
    if (missing) *missing = 0;
    if (root < 0 || !language_ok(language)) return -1;
    const char *parts[3] = {"sqlite", "current", language};
    int fd = root, owned = 0;
    for (int i = 0; i < 3; i++) {
        int next = openat(fd, parts[i], O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        int err = errno;
        if (owned) close(fd);
        if (next < 0) { if (missing && err == ENOENT) *missing = 1; return -1; }
        fd = next; owned = 1;
    }
    int db = openat(fd, "database.db", O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
    int err = errno;
    close(fd);
    if (db < 0 && missing && err == ENOENT) *missing = 1;
    return db;
}
static void mark_refused(od_engine_master_receipt *receipt) {
    if (receipt) receipt->keyed_open_refused = 1;
}
int od_engine_master_resolve_readonly(int source_fd, int state_dir_fd, const char *state_dir_path, const char *language, const char *expected_sha256, uint64_t expected_bytes, int requested_sqlite_flags, const void *key, size_t key_length, int cipher_requested, int extension_requested, int cached_handle_requested, int *out_fd, od_engine_master_receipt *receipt) {
    if (out_fd) *out_fd = -1;
    clear_receipt(receipt);
    if (!out_fd || source_fd < 0) return -1;
    if (key || key_length) { mark_refused(receipt); return -5; }
    if (requested_sqlite_flags != SQLITE_OPEN_READONLY) { mark_refused(receipt); if (receipt) receipt->flags6_refused = 1; return -6; }
    if (cipher_requested || extension_requested) { mark_refused(receipt); return -7; }
    if (cached_handle_requested || patcher_path(state_dir_path)) {
        mark_refused(receipt);
        if (receipt) {
            receipt->patcher_path_used = patcher_path(state_dir_path) ? 1 : 0;
            receipt->cached_handle_redirected = cached_handle_requested ? 1 : 0;
        }
        return -8;
    }
    if (publish(source_fd, state_dir_fd, state_dir_path, language, expected_sha256, expected_bytes, 0, NULL)) return -3;
    int missing = 0;
    int dest = open_published_db(state_dir_fd, language, &missing);
    if (dest < 0) return -3;
    unsigned char header[16];
    struct stat copy, source;
    int flags = fcntl(dest, F_GETFL);
    int header_ok = pread(dest, header, sizeof header, 0) == (ssize_t)sizeof header && !memcmp(header, "SQLite format 3", 16);
    int readonly = flags >= 0 && (flags & O_ACCMODE) == O_RDONLY;
    int identity = !fstat(dest, &copy) && !fstat(source_fd, &source) && S_ISREG(copy.st_mode) &&
        !(copy.st_dev == source.st_dev && copy.st_ino == source.st_ino) &&
        (copy.st_mode & (S_IWUSR | S_IWGRP | S_IWOTH)) == 0;
    if (!header_ok || !readonly || !identity) { close(dest); return -4; }
    if (receipt) {
        if (!relative_for(language, receipt->relative_path)) { close(dest); clear_receipt(receipt); return -1; }
        receipt->attached = 1;
        receipt->plaintext = 1;
        receipt->source_preserved = 1;
        receipt->keyed_open_refused = 1;
        receipt->flags6_refused = 1;
        receipt->readonly_resolved = 1;
    }
    *out_fd = dest;
    return 0;
}
int od_engine_master_asset_root_matches(int source_fd, int state_dir_fd, const char *state_dir_path, int asset_root_fd, const char *asset_root_path, const char *language, int *matches) {
    if (matches) *matches = 0;
    if (!matches || source_fd < 0 || state_dir_fd < 0 || asset_root_fd < 0 || !state_dir_path || !asset_root_path || !language_ok(language)) return -1;
    if (patcher_path(state_dir_path) || patcher_path(asset_root_path)) return -8;
    if (!same_dir(state_dir_fd, state_dir_path) || !same_dir(asset_root_fd, asset_root_path)) return -1;
    struct stat source;
    if (fstat(source_fd, &source) || !S_ISREG(source.st_mode)) return -1;
    int missing = 0;
    int published = open_published_db(state_dir_fd, language, &missing);
    if (published < 0) return missing ? -3 : -1;
    struct stat copy;
    int copy_ok = !fstat(published, &copy);
    close(published);
    if (!copy_ok || !S_ISREG(copy.st_mode) || (copy.st_dev == source.st_dev && copy.st_ino == source.st_ino)) return -3;
    missing = 0;
    int candidate = open_published_db(asset_root_fd, language, &missing);
    if (candidate < 0) return missing ? 0 : -1;
    struct stat live;
    int live_ok = !fstat(candidate, &live);
    close(candidate);
    if (!live_ok || !S_ISREG(live.st_mode)) return -1;
    if (live.st_dev == source.st_dev && live.st_ino == source.st_ino) return 0;
    *matches = live.st_dev == copy.st_dev && live.st_ino == copy.st_ino;
    return 0;
}
