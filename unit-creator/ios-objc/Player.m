#import <objc/message.h>
// The animation player for the Unit Creator on iPhone (see Player.h).
#import "Player.h"
#import "Host.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <CommonCrypto/CommonDigest.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>


/// JS sends null as NSNull: read flags and numbers safely
static BOOL B(id v) { return ([v isKindOfClass:[NSNumber class]] || [v isKindOfClass:[NSString class]]) ? [v boolValue] : NO; }
static NSInteger I(id v) { return ([v isKindOfClass:[NSNumber class]] || [v isKindOfClass:[NSString class]]) ? [v integerValue] : 0; }

static UIColor *Hex(uint32_t rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0 green:((rgb >> 8) & 255) / 255.0 blue:(rgb & 255) / 255.0 alpha:1];
}

#pragma mark - one HTTP connection

@interface ForgeConnection : NSObject
@property (nonatomic) int fd;
@end
@implementation ForgeConnection
- (BOOL)writeAll:(const void *)bytes length:(size_t)len {
    const uint8_t *p = bytes;
    while (len > 0) {
        ssize_t n = send(self.fd, p, len, 0);
        if (n <= 0) return NO;
        p += n; len -= (size_t)n;
    }
    return YES;
}
- (BOOL)writeData:(NSData *)d { return d.length == 0 || [self writeAll:d.bytes length:d.length]; }
- (void)close { if (self.fd >= 0) { shutdown(self.fd, SHUT_RDWR); close(self.fd); self.fd = -1; } }
@end

#pragma mark - player

@interface ForgePlayer () <WKNavigationDelegate, WKUIDelegate, UIDocumentPickerDelegate>
@end


// ---- "Put it in your game": a game's own Files folder (On My iPhone › Sparking / Eclipse), linked once.
// The person picks the game's folder in the iPhone's folder picker; the app keeps a security-scoped bookmark
// (the only supported way for one app to write into a folder another app shares in Files) and from then on
// saves units straight into it. Nothing is read from the game's private storage.
@interface ForgeFolderPicker : NSObject <UIDocumentPickerDelegate, UIAdaptivePresentationControllerDelegate>
@property (nonatomic, copy) void (^done)(NSURL *_Nullable url);
@end
@implementation ForgeFolderPicker
// take the block first: calling it can release this object (the owner drops its reference)
- (void)finish:(NSURL *)url { void (^d)(NSURL *) = self.done; self.done = nil; if (d) d(url); }
- (void)documentPicker:(UIDocumentPickerViewController *)c didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls { [self finish:urls.firstObject]; }
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)c { [self finish:nil]; }
- (void)presentationControllerDidDismiss:(UIPresentationController *)p { [self finish:nil]; }   // swiped away
@end

static NSString *GameFolderKey(NSString *game) { return [@"forge.gameFolder." stringByAppendingString:game]; }
static NSURL *GameFolderURL(NSString *game, BOOL *stale) {
    NSData *b = [[NSUserDefaults standardUserDefaults] dataForKey:GameFolderKey(game)];
    if (!b) return nil;
    BOOL st = NO; NSError *e = nil;
    NSURL *u = [NSURL URLByResolvingBookmarkData:b options:0 relativeToURL:nil bookmarkDataIsStale:&st error:&e];
    if (stale) *stale = st;
    return u;
}
static NSString *FileSha256(NSURL *u) {
    NSData *d = [NSData dataWithContentsOfURL:u options:NSDataReadingMappedIfSafe error:nil];
    if (!d) return nil;
    unsigned char h[CC_SHA256_DIGEST_LENGTH]; CC_SHA256(d.bytes, (CC_LONG)d.length, h);
    NSMutableString *o = [NSMutableString string]; for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [o appendFormat:@"%02x", h[i]];
    return o;
}

@implementation ForgePlayer {
    int _listenFd;
    dispatch_queue_t _io;
    WKWebView *_player;
    UIView *_panel, *_bar, *_grip, *_overlay;
    UILabel *_title, *_note, *_overlayTitle, *_overlayText;
    UIActivityIndicatorView *_spinner;
    UIStackView *_overlayButtons;
    UIButton *_sizeButton;
    NSString *_mode;           // closed | docked | full
    CGFloat _fraction;
    BOOL _barOn;
    CGRect _bounds;
    UIEdgeInsets _insets;
    WKContentRuleList *_rules;
    void (^_exportReply)(id _Nullable, NSString *_Nullable);
    ForgeFolderPicker *_folderPicker;
    NSURL *_exportTemp;
}

- (instancetype)initWithMainWebView:(WKWebView *)web controller:(UIViewController *)controller {
    if ((self = [super init])) {
        _mainWebView = web;
        _controller = controller;
        _io = dispatch_queue_create("forge.player.io", DISPATCH_QUEUE_CONCURRENT);
        _mode = @"closed";
        _fraction = 0.46;
        _listenFd = -1;
        [self startServer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foreground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)emit:(NSDictionary *)detail {
    NSMutableDictionary *d = [detail mutableCopy];
    d[@"type"] = @"player";
    NSData *json = [NSJSONSerialization dataWithJSONObject:d options:0 error:nil];
    if (!json) return;
    NSString *js = [NSString stringWithFormat:@"dispatchEvent(new CustomEvent('forge-host',{detail:%@}))",
                    [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
    [self.mainWebView evaluateJavaScript:js completionHandler:nil];
}

- (void)foreground {
    if (_listenFd >= 0) return;
    [self startServer];
    _rules = nil;   // the block list names the old port
    [self emit:@{ @"event": @"server", @"port": @(_port) }];
}

#pragma mark server (127.0.0.1, random port)

- (void)startServer {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return;
    int yes = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof yes);
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &yes, sizeof yes);
    struct sockaddr_in addr = {0};
    addr.sin_len = sizeof addr;
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = 0;
    if (bind(fd, (struct sockaddr *)&addr, sizeof addr) != 0 || listen(fd, 32) != 0) { close(fd); return; }
    socklen_t len = sizeof addr;
    getsockname(fd, (struct sockaddr *)&addr, &len);
    _port = ntohs(addr.sin_port);
    _listenFd = fd;
    __weak ForgePlayer *weakSelf = self;
    [NSThread detachNewThreadWithBlock:^{
        while (1) {
            int client = accept(fd, NULL, NULL);
            if (client < 0) { if (errno == EINTR || errno == ECONNABORTED) continue; break; }
            ForgePlayer *me = weakSelf;
            if (!me) { close(client); break; }
            int on = 1;
            setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &on, sizeof on);
            struct timeval tv = { .tv_sec = 30, .tv_usec = 0 };
            setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
            setsockopt(client, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof tv);
            ForgeConnection *c = [ForgeConnection new];
            c.fd = client;
            dispatch_async(me->_io, ^{ [weakSelf serve:c]; });
        }
        // the listening socket is gone (e.g. iOS reclaimed it in the background): start again when back
        close(fd);
        dispatch_async(dispatch_get_main_queue(), ^{ ForgePlayer *me = weakSelf; if (me && me->_listenFd == fd) me->_listenFd = -1; });
    }];
}

static NSString *const kSecurityHeaders[][2] = {
    {@"Cache-Control", @"no-store"},
    {@"Cross-Origin-Opener-Policy", @"same-origin"},
    {@"Cross-Origin-Embedder-Policy", @"require-corp"},
    {@"Cross-Origin-Resource-Policy", @"same-origin"},
    {@"X-Content-Type-Options", @"nosniff"},
    {@"Referrer-Policy", @"no-referrer"},
    {@"Content-Security-Policy", @"default-src 'self' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; media-src 'self' blob: data:; worker-src 'self' blob:; frame-src 'none'; object-src 'none'; base-uri 'self'; form-action 'none'"},
};

- (void)respond:(ForgeConnection *)c status:(NSInteger)status headers:(NSDictionary *)headers length:(unsigned long long)length head:(BOOL)head {
    NSMutableString *h = [NSMutableString stringWithFormat:@"HTTP/1.1 %ld Response\r\n", (long)status];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *k, id v, BOOL *stop) {
        NSString *lk = k.lowercaseString;
        if ([lk isEqualToString:@"content-length"] || [lk isEqualToString:@"connection"]) return;
        NSString *value = [[[v description] stringByReplacingOccurrencesOfString:@"\r" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        [h appendFormat:@"%@: %@\r\n", k, value];
    }];
    [h appendFormat:@"Content-Length: %llu\r\nConnection: close\r\n", length];
    for (size_t i = 0; i < sizeof kSecurityHeaders / sizeof kSecurityHeaders[0]; i++)
        if (!headers[kSecurityHeaders[i][0]]) [h appendFormat:@"%@: %@\r\n", kSecurityHeaders[i][0], kSecurityHeaders[i][1]];
    [h appendString:@"\r\n"];
    [c writeData:[h dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)fail:(ForgeConnection *)c status:(NSInteger)status text:(NSString *)text head:(BOOL)head {
    NSData *body = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self respond:c status:status headers:@{ @"Content-Type": @"text/plain; charset=utf-8" } length:body.length head:head];
    if (!head) [c writeData:body];
    [c close];
}

- (void)serve:(ForgeConnection *)c {
    // read headers (≤ 16 KiB)
    NSMutableData *buf = [NSMutableData data];
    uint8_t chunk[8192];
    NSRange end = NSMakeRange(NSNotFound, 0);
    NSData *sep = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    while (end.location == NSNotFound) {
        ssize_t n = recv(c.fd, chunk, sizeof chunk, 0);
        if (n <= 0) { [c close]; return; }
        [buf appendBytes:chunk length:(NSUInteger)n];
        end = [buf rangeOfData:sep options:0 range:NSMakeRange(0, buf.length)];
        if (end.location == NSNotFound && buf.length > 16384) { [self fail:c status:400 text:@"" head:NO]; return; }
    }
    NSString *head = [[NSString alloc] initWithData:[buf subdataWithRange:NSMakeRange(0, end.location)] encoding:NSUTF8StringEncoding];
    NSData *rest = [buf subdataWithRange:NSMakeRange(end.location + 4, buf.length - end.location - 4)];
    NSArray<NSString *> *lines = [head componentsSeparatedByString:@"\r\n"];
    NSArray<NSString *> *requestLine = [lines.firstObject componentsSeparatedByString:@" "];
    if (!head || requestLine.count != 3 || ![requestLine[2] isEqualToString:@"HTTP/1.1"] || lines.count > 65) { [self fail:c status:400 text:@"" head:NO]; return; }
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    for (NSUInteger i = 1; i < lines.count; i++) {
        NSRange colon = [lines[i] rangeOfString:@":"];
        if (colon.location == NSNotFound || colon.location == 0) { [self fail:c status:400 text:@"" head:NO]; return; }
        NSString *name = [[lines[i] substringToIndex:colon.location] lowercaseString];
        if (headers[name]) { [self fail:c status:400 text:@"" head:NO]; return; }
        headers[name] = [[lines[i] substringFromIndex:colon.location + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    NSString *method = requestLine[0], *target = requestLine[1];
    BOOL isHead = [method isEqualToString:@"HEAD"];

    // body: small ones go to JS directly, big ones (movies) to a temporary file
    NSMutableDictionary *req = [@{ @"method": method, @"target": target, @"headers": headers } mutableCopy];
    long long length = headers[@"content-length"] ? [headers[@"content-length"] longLongValue] : 0;
    if (headers[@"content-length"] && length > 0) {
        if (length > 168 * 1024 * 1024) { [self fail:c status:413 text:@"" head:NO]; return; }
        NSString *rel = [NSString stringWithFormat:@"cache/uploads/%@.bin", [[NSUUID UUID] UUIDString]];
        NSString *file = [ForgeHost resolve:rel];
        [[NSFileManager defaultManager] createDirectoryAtPath:file.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] createFileAtPath:file contents:nil attributes:nil];
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:file];
        long long got = 0;
        NSData *first = rest.length > (NSUInteger)length ? [rest subdataWithRange:NSMakeRange(0, (NSUInteger)length)] : rest;
        BOOL wrote = [fh writeData:first error:nil]; got += (long long)first.length;
        uint8_t *big = malloc(65536);
        while (wrote && got < length) {
            ssize_t n = recv(c.fd, big, (size_t)MIN((long long)65536, length - got), 0);
            if (n <= 0) break;
            if (![fh writeData:[NSData dataWithBytesNoCopy:big length:(NSUInteger)n freeWhenDone:NO] error:nil]) break;   // got < length: answered as incomplete
            got += n;
        }
        free(big);
        [fh closeFile];
        req[@"bodyFile"] = rel;
        req[@"bodyLength"] = @(got);
    }

    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    __block NSDictionary *answer = nil;
    __block NSString *problem = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        WKWebView *main = self.mainWebView;
        if (!main) { problem = @"The app is not ready."; dispatch_semaphore_signal(done); return; }
        [main callAsyncJavaScript:@"return await window.ForgePreviewServer.handle(request)" arguments:@{ @"request": req }
                          inFrame:nil inContentWorld:[WKContentWorld pageWorld] completionHandler:^(id result, NSError *error) {
            if ([result isKindOfClass:[NSDictionary class]]) answer = result;
            else problem = error.localizedDescription ?: @"No answer.";
            dispatch_semaphore_signal(done);
        }];
    });
    dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(600 * NSEC_PER_SEC)));
    if (req[@"bodyFile"] && !B(answer[@"keepBody"])) [[NSFileManager defaultManager] removeItemAtPath:[ForgeHost resolve:req[@"bodyFile"]] error:nil];
    if (!answer) { [self fail:c status:503 text:problem ?: @"The preview did not answer." head:isHead]; return; }

    NSInteger status = I(answer[@"status"]) ?: 200;
    NSDictionary *h = [answer[@"headers"] isKindOfClass:[NSDictionary class]] ? answer[@"headers"] : @{};
    NSString *range = B(answer[@"range"]) ? headers[@"range"] : nil;
    // body: text, base64 or a file (app storage, or the app's own screens with "site:")
    NSData *data = nil; NSString *file = nil;
    if ([answer[@"file"] isKindOfClass:[NSString class]]) {
        NSString *f = answer[@"file"];
        if ([f hasPrefix:@"site:"]) {
            NSString *site = [[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"site"] stringByStandardizingPath];
            NSString *full = [[site stringByAppendingPathComponent:[f substringFromIndex:5]] stringByStandardizingPath];
            file = [full hasPrefix:[site stringByAppendingString:@"/"]] ? full : nil;
        } else {
            file = [ForgeHost resolve:f];
        }
        if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file]) { [self fail:c status:404 text:@"Not found" head:isHead]; return; }
    } else if ([answer[@"base64"] isKindOfClass:[NSString class]]) {
        data = [[NSData alloc] initWithBase64EncodedString:answer[@"base64"] options:0] ?: [NSData data];
    } else {
        data = [([answer[@"body"] isKindOfClass:[NSString class]] ? answer[@"body"] : @"") dataUsingEncoding:NSUTF8StringEncoding];
    }
    unsigned long long total = file ? [[[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil] fileSize] : data.length;
    unsigned long long start = 0, last = total ? total - 1 : 0;
    NSMutableDictionary *out = [h mutableCopy];
    if (range.length && total > 0 && status == 200) {
        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"^bytes=([0-9]*)-([0-9]*)$" options:0 error:nil];
        NSTextCheckingResult *m = [re firstMatchInString:range options:0 range:NSMakeRange(0, range.length)];
        NSString *a = m ? [range substringWithRange:[m rangeAtIndex:1]] : nil, *b = m ? [range substringWithRange:[m rangeAtIndex:2]] : nil;
        BOOL ok = m && (a.length || b.length);
        if (ok && !a.length) { unsigned long long n = strtoull(b.UTF8String, NULL, 10); ok = n > 0; start = n >= total ? 0 : total - n; }
        else if (ok) { start = strtoull(a.UTF8String, NULL, 10); if (b.length) last = MIN(strtoull(b.UTF8String, NULL, 10), total - 1); ok = start <= last && start < total; }
        if (!ok) {
            [self respond:c status:416 headers:@{ @"Content-Range": [NSString stringWithFormat:@"bytes */%llu", total], @"Content-Type": @"text/plain; charset=utf-8" } length:0 head:YES];
            [c close];
            return;
        }
        status = 206;
        out[@"Content-Range"] = [NSString stringWithFormat:@"bytes %llu-%llu/%llu", start, last, total];
    }
    unsigned long long count = total ? last - start + 1 : 0;
    [self respond:c status:status headers:out length:count head:isHead];
    if (!isHead && count) {
        if (file) {
            NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:file];
            [fh seekToFileOffset:start];
            unsigned long long left = count;
            while (left > 0) {
                @autoreleasepool {
                    NSData *part = [fh readDataOfLength:(NSUInteger)MIN(left, (unsigned long long)(1 << 20))];
                    if (!part.length || ![c writeData:part]) break;
                    left -= part.length;
                }
            }
            [fh closeFile];
        } else {
            [c writeData:[data subdataWithRange:NSMakeRange((NSUInteger)start, (NSUInteger)count)]];
        }
    }
    [c close];
}

#pragma mark the player panel

- (void)buildPanel {
    if (_panel) return;
    UIView *host = self.mainWebView.superview;
    _panel = [UIView new];
    _panel.backgroundColor = Hex(0x0B141A);
    _panel.clipsToBounds = YES;
    _panel.hidden = YES;
    [host addSubview:_panel];

    _bar = [UIView new];
    _bar.backgroundColor = Hex(0x152329);
    _title = [UILabel new];
    _title.textColor = Hex(0xF2F5F7);
    _title.font = [UIFont boldSystemFontOfSize:15];
    [_bar addSubview:_title];
    _sizeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_sizeButton setTitleColor:Hex(0xFFB15D) forState:UIControlStateNormal];
    [_sizeButton addTarget:self action:@selector(toggleSize) forControlEvents:UIControlEventTouchUpInside];
    [_bar addSubview:_sizeButton];
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"✕  Close" forState:UIControlStateNormal];
    [close setTitleColor:Hex(0xFFB15D) forState:UIControlStateNormal];
    close.tag = 7;
    [close addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [_bar addSubview:close];
    [_panel addSubview:_bar];

    _grip = [UIView new];
    _grip.backgroundColor = Hex(0x152329);
    UILabel *g = [UILabel new];
    g.text = @"━━━";
    g.textColor = Hex(0x7A8C94);
    g.textAlignment = NSTextAlignmentCenter;
    g.tag = 9;
    [_grip addSubview:g];
    [_grip addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)]];
    [_panel addSubview:_grip];

    _note = [UILabel new];
    _note.backgroundColor = Hex(0xFFB15D);
    _note.textColor = Hex(0x0B141A);
    _note.numberOfLines = 0;
    _note.font = [UIFont systemFontOfSize:14];
    _note.hidden = YES;
    _note.userInteractionEnabled = YES;
    [_note addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideNote)]];

    _overlay = [UIView new];
    _overlay.backgroundColor = Hex(0x0B141A);
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _spinner.color = Hex(0xFFB15D);
    _overlayTitle = [UILabel new];
    _overlayTitle.textColor = Hex(0xF2F5F7);
    _overlayTitle.font = [UIFont boldSystemFontOfSize:18];
    _overlayTitle.textAlignment = NSTextAlignmentCenter;
    _overlayText = [UILabel new];
    _overlayText.textColor = Hex(0xB8C4CA);
    _overlayText.numberOfLines = 0;
    _overlayText.textAlignment = NSTextAlignmentCenter;
    _overlayButtons = [UIStackView new];
    _overlayButtons.axis = UILayoutConstraintAxisVertical;
    _overlayButtons.spacing = 8;
    for (UIView *v in @[_spinner, _overlayTitle, _overlayText, _overlayButtons]) [_overlay addSubview:v];
}

- (void)makePlayer {
    [_player removeFromSuperview];
    [_player removeObserver:self forKeyPath:@"title"];
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
    config.allowsInlineMediaPlayback = YES;
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    if (_rules) [config.userContentController addContentRuleList:_rules];
    _player = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _player.navigationDelegate = self;
    _player.UIDelegate = self;
    _player.opaque = NO;
    _player.backgroundColor = UIColor.blackColor;
    _player.scrollView.backgroundColor = UIColor.blackColor;
    _player.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    if (@available(iOS 16.4, *)) _player.inspectable = YES;
    [_player addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    [_panel insertSubview:_player atIndex:0];
    [_panel addSubview:_overlay];
    [_panel addSubview:_note];
}

- (void)dealloc {
    [_player removeObserver:self forKeyPath:@"title"];
    if (_listenFd >= 0) close(_listenFd);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _player && [keyPath isEqualToString:@"title"]) {
        NSString *t = _player.title ?: @"";
        if ([t hasPrefix:@"forge-dock:"]) [self emit:@{ @"event": @"title", @"title": t }];
    }
}

- (void)layoutInBounds:(CGRect)bounds safeArea:(UIEdgeInsets)insets {
    _bounds = bounds; _insets = insets;
    [self relayout];
}

- (void)relayout {
    WKWebView *main = self.mainWebView;
    if (!main || CGRectIsEmpty(_bounds)) return;
    CGRect b = _bounds;
    if ([_mode isEqualToString:@"closed"] || !_panel) {
        _panel.hidden = YES;
        main.hidden = NO;
        main.frame = b;
        [self screenEdgesChanged];
        return;
    }
    _panel.hidden = NO;
    BOOL full = [_mode isEqualToString:@"full"];
    CGFloat top = _insets.top;
    CGFloat avail = b.size.height - top;
    CGFloat minH = MIN(200, avail / 2), maxH = MAX(minH, avail - 140);
    CGFloat docked = MAX(minH, MIN(maxH, round(avail * _fraction)));
    CGFloat panelH = full ? b.size.height : top + docked;
    _panel.frame = CGRectMake(0, 0, b.size.width, panelH);
    main.hidden = NO;   // stays live under the panel: it answers the player's requests
    main.frame = full ? b : CGRectMake(0, panelH, b.size.width, b.size.height - panelH);
    CGFloat barH = _barOn ? 44 : 0, gripH = full ? 0 : 22;
    _bar.hidden = !_barOn;
    _bar.frame = CGRectMake(0, top, b.size.width, barH);
    CGFloat w = b.size.width;
    UIView *close = [_bar viewWithTag:7];
    close.frame = CGRectMake(w - 100 - _insets.right, 0, 92, barH);
    _sizeButton.frame = CGRectMake(w - 210 - _insets.right, 0, 108, barH);
    [_sizeButton setTitle:full ? @"Smaller" : @"Full screen" forState:UIControlStateNormal];
    _title.frame = CGRectMake(12 + _insets.left, 0, w - 230 - _insets.left - _insets.right, barH);
    _grip.hidden = full;
    _grip.frame = CGRectMake(0, panelH - gripH, w, gripH);
    [_grip viewWithTag:9].frame = _grip.bounds;
    CGFloat playerTop = top + barH;
    CGFloat playerBottom = full ? panelH - _insets.bottom : panelH - gripH;
    if (full && !_barOn) playerTop = 0, playerBottom = panelH;   // the page handles the notch itself
    _player.frame = CGRectMake(0, playerTop, w, MAX(0, playerBottom - playerTop));
    _overlay.frame = _player.frame;
    CGFloat ow = MIN(_overlay.bounds.size.width - 40, 420), cx = _overlay.bounds.size.width / 2;
    _spinner.center = CGPointMake(cx, _overlay.bounds.size.height * 0.30);
    _overlayTitle.frame = CGRectMake(cx - ow / 2, CGRectGetMaxY(_spinner.frame) + 12, ow, 26);
    CGSize textSize = [_overlayText sizeThatFits:CGSizeMake(ow, 400)];
    _overlayText.frame = CGRectMake(cx - ow / 2, CGRectGetMaxY(_overlayTitle.frame) + 6, ow, textSize.height);
    CGFloat bh = _overlayButtons.arrangedSubviews.count * 48;
    _overlayButtons.frame = CGRectMake(cx - ow / 2, CGRectGetMaxY(_overlayText.frame) + 14, ow, bh);
    CGSize noteSize = [_note sizeThatFits:CGSizeMake(w - 24, 200)];
    _note.frame = CGRectMake(0, playerTop, w, _note.hidden ? 0 : noteSize.height + 16);
    if ([_mode isEqualToString:@"docked"] || full)
        [_player evaluateJavaScript:[NSString stringWithFormat:@"window.ForgeDockPage&&ForgeDockPage.layout(%@)", full ? @"true" : @"false"] completionHandler:nil];
    [self screenEdgesChanged];
}

// the main page moved or changed size: it gets its new screen edges (WebViewController -pushGeometry)
- (void)screenEdgesChanged {
    SEL push = NSSelectorFromString(@"pushGeometry");
    UIViewController *c = self.controller;
    if ([c respondsToSelector:push]) ((void (*)(id, SEL))objc_msgSend)(c, push);
}

- (void)setMode:(NSString *)mode {
    if ([_mode isEqualToString:mode]) { [self relayout]; return; }
    _mode = mode;
    [UIView animateWithDuration:0.18 animations:^{ [self relayout]; }];
    [self emit:@{ @"event": @"mode", @"mode": mode }];
}

- (void)toggleSize { [self emit:@{ @"event": @"button", @"button": @"size" }]; }
- (void)closeTapped { [self emit:@{ @"event": @"button", @"button": @"close" }]; }
- (void)hideNote { _note.hidden = YES; [self relayout]; }

- (void)drag:(UIPanGestureRecognizer *)pan {
    CGFloat avail = _bounds.size.height - _insets.top;
    if (avail <= 0) return;
    CGFloat y = [pan locationInView:_panel.superview].y - _insets.top;
    _fraction = MAX(0.2, MIN(0.85, y / avail));
    [self relayout];
    if (pan.state == UIGestureRecognizerStateEnded) [self emit:@{ @"event": @"fraction", @"fraction": @(_fraction) }];
}

- (void)overlayButton:(UIButton *)b { [self emit:@{ @"event": @"overlay", @"button": b.accessibilityIdentifier ?: @"" }]; }

#pragma mark navigation (only the local player is allowed)

- (BOOL)isLocal:(NSURL *)url {
    return [url.scheme isEqualToString:@"http"] && [url.host isEqualToString:@"127.0.0.1"] && url.port.integerValue == _port && !url.user;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    NSURL *u = action.request.URL;
    BOOL ok = [self isLocal:u] || [u.scheme isEqualToString:@"about"] || [u.scheme isEqualToString:@"blob"] || [u.scheme isEqualToString:@"data"];
    handler(ok ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)response decisionHandler:(void (^)(WKNavigationResponsePolicy))handler {
    if ([response.response isKindOfClass:[NSHTTPURLResponse class]] && ((NSHTTPURLResponse *)response.response).statusCode == 503)
        [self emit:@{ @"event": @"http503", @"url": response.response.URL.absoluteString ?: @"" }];
    handler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self emit:@{ @"event": @"started", @"url": webView.URL.absoluteString ?: @"" }];
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self emit:@{ @"event": @"finished", @"url": webView.URL.absoluteString ?: @"" }];
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code != NSURLErrorCancelled) [self emit:@{ @"event": @"error", @"message": error.localizedDescription ?: @"" }];
}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code != NSURLErrorCancelled) [self emit:@{ @"event": @"error", @"message": error.localizedDescription ?: @"" }];
}
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [self emit:@{ @"event": @"crashed" }];
}
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)action windowFeatures:(WKWindowFeatures *)windowFeatures {
    return nil;
}

#pragma mark ops from the app's code

- (void)compileRules:(void (^)(void))done {
    if (_rules) { done(); return; }
    NSString *json = [NSString stringWithFormat:@"[{\"trigger\":{\"url-filter\":\".*\"},\"action\":{\"type\":\"block\"}},"
                      "{\"trigger\":{\"url-filter\":\"^http://127\\\\.0\\\\.0\\\\.1:%u/\"},\"action\":{\"type\":\"ignore-previous-rules\"}},"
                      "{\"trigger\":{\"url-filter\":\"^blob:\"},\"action\":{\"type\":\"ignore-previous-rules\"}},"
                      "{\"trigger\":{\"url-filter\":\"^data:\"},\"action\":{\"type\":\"ignore-previous-rules\"}},"
                      "{\"trigger\":{\"url-filter\":\"^about:\"},\"action\":{\"type\":\"ignore-previous-rules\"}}]", _port];
    [[WKContentRuleListStore defaultStore] compileContentRuleListForIdentifier:[NSString stringWithFormat:@"forge-player-%u", _port]
        encodedContentRuleList:json completionHandler:^(WKContentRuleList *list, NSError *error) {
        if (error) NSLog(@"Player block list: %@", error);
        self->_rules = list;
        done();
    }];
}

- (void)handle:(NSString *)op message:(NSDictionary *)m reply:(void (^)(id _Nullable, NSString *_Nullable))reply {
    if ([op isEqualToString:@"serverInfo"]) {
        reply(@{ @"port": @(_port), @"origin": [NSString stringWithFormat:@"http://127.0.0.1:%u", _port] }, nil);
    } else if ([op isEqualToString:@"playerOpen"]) {
        NSURL *url = [m[@"url"] isKindOfClass:[NSString class]] ? [NSURL URLWithString:m[@"url"]] : nil;
        if (!url || ![self isLocal:url] || !_port) { reply(nil, @"Could not open the animation player."); return; }
        [self buildPanel];
        if ([m[@"fraction"] isKindOfClass:[NSNumber class]]) _fraction = MAX(0.2, MIN(0.85, [m[@"fraction"] doubleValue]));
        _title.text = [m[@"title"] isKindOfClass:[NSString class]] ? m[@"title"] : @"Animation preview";
        [self compileRules:^{
            [self makePlayer];
            self->_note.hidden = YES;
            [self setMode:B(m[@"full"]) ? @"full" : @"docked"];
            [self->_player loadRequest:[NSURLRequest requestWithURL:url]];
            reply(@YES, nil);
        }];
    } else if ([op isEqualToString:@"playerLayout"]) {
        NSString *mode = [m[@"mode"] isKindOfClass:[NSString class]] ? m[@"mode"] : @"";
        if ([mode isEqualToString:@"closed"]) {
            [_player stopLoading];
            [_player removeObserver:self forKeyPath:@"title"];
            [_player removeFromSuperview];
            _player = nil;
            _barOn = NO;
            [self setMode:@"closed"];
        } else if (_player && ([mode isEqualToString:@"full"] || [mode isEqualToString:@"docked"])) {
            [self setMode:mode];
        }
        reply(_mode, nil);
    } else if ([op isEqualToString:@"playerEval"]) {
        if (!_player) { reply(nil, @"The animation player is closed."); return; }
        [_player evaluateJavaScript:[m[@"script"] isKindOfClass:[NSString class]] ? m[@"script"] : @"" completionHandler:^(id result, NSError *error) {
            if (error) reply(nil, error.localizedDescription ?: @"Script failed.");
            else reply(result ?: [NSNull null], nil);
        }];
    } else if ([op isEqualToString:@"playerBar"]) {
        _barOn = B(m[@"on"]);
        [self relayout];
        reply(@YES, nil);
    } else if ([op isEqualToString:@"playerNote"]) {
        NSString *t = [m[@"text"] isKindOfClass:[NSString class]] ? m[@"text"] : @"";
        _note.text = t.length ? [NSString stringWithFormat:@"  %@  ", t] : @"";
        _note.hidden = t.length == 0;
        [self relayout];
        reply(@YES, nil);
    } else if ([op isEqualToString:@"playerOverlay"]) {
        BOOL show = B(m[@"show"]);
        _overlay.hidden = !show;
        _overlayTitle.text = [m[@"title"] isKindOfClass:[NSString class]] ? m[@"title"] : @"";
        _overlayText.text = [m[@"message"] isKindOfClass:[NSString class]] ? m[@"message"] : @"";
        if (B(m[@"spinner"])) [_spinner startAnimating]; else [_spinner stopAnimating];
        for (UIView *v in _overlayButtons.arrangedSubviews) { [_overlayButtons removeArrangedSubview:v]; [v removeFromSuperview]; }
        for (NSDictionary *b in [m[@"buttons"] isKindOfClass:[NSArray class]] ? m[@"buttons"] : @[]) {
            if (![b isKindOfClass:[NSDictionary class]] || ![b[@"label"] isKindOfClass:[NSString class]]) continue;
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:b[@"label"] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            [button setTitleColor:Hex(0x0B141A) forState:UIControlStateNormal];
            button.backgroundColor = Hex(0xFFB15D);
            button.layer.cornerRadius = 10;
            button.accessibilityIdentifier = b[@"id"];
            [button.heightAnchor constraintEqualToConstant:40].active = YES;
            [button addTarget:self action:@selector(overlayButton:) forControlEvents:UIControlEventTouchUpInside];
            [_overlayButtons addArrangedSubview:button];
        }
        [self relayout];
        reply(@YES, nil);
    } else if ([op isEqualToString:@"playerSnapshot"]) {
        [self snapshot:m reply:reply];
    } else if ([op isEqualToString:@"playerCookieClear"]) {
        WKHTTPCookieStore *store = [WKWebsiteDataStore defaultDataStore].httpCookieStore;
        [store getAllCookies:^(NSArray<NSHTTPCookie *> *cookies) {
            for (NSHTTPCookie *c in cookies) if ([c.domain isEqualToString:@"127.0.0.1"] && [c.name hasPrefix:@"forge_preview_"]) [store deleteCookie:c completionHandler:nil];
            reply(@YES, nil);
        }];
    } else if ([op isEqualToString:@"saveDocument"]) {
        [self saveDocument:m reply:reply];
    } else if ([op hasPrefix:@"gameFolder"]) {
        [self gameFolder:op message:m reply:reply];
    } else {
        reply(nil, [NSString stringWithFormat:@"Unknown action: %@", op]);
    }
}

#pragma mark stage capture ("Save video" frames)

- (void)snapshot:(NSDictionary *)m reply:(void (^)(id _Nullable, NSString *_Nullable))reply {
    WKWebView *web = _player;
    NSString *origin = [NSString stringWithFormat:@"http://127.0.0.1:%u/tools/lua-player/", _port];
    if (!web || ![web.URL.absoluteString hasPrefix:origin]) { reply(nil, @"Open the animation player before recording."); return; }
    NSString *js = @"(()=>{const e=document.getElementById('stage');if(!e)return null;const p=e.parentElement;const r=e.dataset.phone==='1'&&(p&&p.classList.contains('stage-fit'))?p.getBoundingClientRect():e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,vw:innerWidth,vh:innerHeight};})()";
    [web evaluateJavaScript:js completionHandler:^(id result, NSError *error) {
        NSDictionary *r = [result isKindOfClass:[NSDictionary class]] ? result : nil;
        double x = [r[@"x"] doubleValue], y = [r[@"y"] doubleValue], w = [r[@"width"] doubleValue], h = [r[@"height"] doubleValue];
        double vw = [r[@"vw"] doubleValue], vh = [r[@"vh"] doubleValue];
        if (!r || x < 0 || y < 0 || w < 2 || h < 2 || w > 4096 || h > 4096 || x + w > vw + 1 || y + h > vh + 1) {
            reply(nil, @"Keep the complete animation stage visible before recording.");
            return;
        }
        if (x + w > web.bounds.size.width + 1 || y + h > web.bounds.size.height + 1) { reply(nil, @"The animation stage is outside this preview."); return; }
        WKSnapshotConfiguration *cfg = [WKSnapshotConfiguration new];
        cfg.rect = CGRectMake(x, y, w, h);
        cfg.afterScreenUpdates = NO;
        [web takeSnapshotWithConfiguration:cfg completionHandler:^(UIImage *image, NSError *err) {
            NSData *png = image ? UIImagePNGRepresentation(image) : nil;
            if (!png) { reply(nil, @"The device could not capture the current animation frame (0)."); return; }
            if (png.length > 8 * 1024 * 1024) { reply(nil, @"The animation snapshot exceeds8MiB."); return; }
            NSString *rel = [NSString stringWithFormat:@"cache/uploads/stage-%@.png", [[NSUUID UUID] UUIDString]];
            NSString *file = [ForgeHost resolve:rel];
            [[NSFileManager defaultManager] createDirectoryAtPath:file.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
            [png writeToFile:file atomically:NO];
            reply(@{ @"file": rel, @"bytes": @(png.length) }, nil);
        }];
    }];
}


#pragma mark a game's Files folder (Import to Sparking / Eclipse)

- (void)gameFolder:(NSString *)op message:(NSDictionary *)m reply:(void (^)(id _Nullable, NSString *_Nullable))reply {
    NSString *game = [m[@"game"] isKindOfClass:[NSString class]] ? m[@"game"] : @"";
    if (![game isEqualToString:@"sparking"] && ![game isEqualToString:@"eclipse"]) { reply(nil, @"Choose Eclipse or Sparking."); return; }
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if ([op isEqualToString:@"gameFolderStatus"]) {
        BOOL stale = NO; NSURL *u = GameFolderURL(game, &stale);
        BOOL ok = NO, had = [ud dataForKey:GameFolderKey(game)] != nil;   // a saved link that no longer opens = "link again"
        if (u && [u startAccessingSecurityScopedResource]) { ok = [[NSFileManager defaultManager] fileExistsAtPath:u.path]; [u stopAccessingSecurityScopedResource]; }
        reply(@{ @"linked": @(had), @"ok": @(ok), @"name": u.lastPathComponent ?: @"" }, nil);
    } else if ([op isEqualToString:@"gameFolderUnlink"]) {
        [ud removeObjectForKey:GameFolderKey(game)];
        reply(@YES, nil);
    } else if ([op isEqualToString:@"gameFolderLink"]) {
        if (_folderPicker) { reply(nil, @"Finish choosing the folder first."); return; }
        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeFolder]];
        picker.allowsMultipleSelection = NO;
        picker.shouldShowFileExtensions = YES;
        __weak ForgePlayer *weakSelf = self;
        _folderPicker = [ForgeFolderPicker new];
        _folderPicker.done = ^(NSURL *url) {
            ForgePlayer *me = weakSelf; if (me) me->_folderPicker = nil;
            if (!url) { reply(@{ @"linked": @NO }, nil); return; }
            BOOL acc = [url startAccessingSecurityScopedResource];
            NSError *e = nil;
            NSData *bm = [url bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:&e];
            if (acc) [url stopAccessingSecurityScopedResource];
            if (!bm) { reply(nil, @"The iPhone didn't allow saving into that folder. Pick the game's folder under On My iPhone."); return; }
            [ud setObject:bm forKey:GameFolderKey(game)];
            reply(@{ @"linked": @YES, @"name": url.lastPathComponent ?: @"" }, nil);
        };
        picker.delegate = _folderPicker;
        picker.presentationController.delegate = _folderPicker;
        UIViewController *top = self.controller;
        while (top.presentedViewController) top = top.presentedViewController;
        if (!top || top.isBeingDismissed) { _folderPicker = nil; reply(nil, @"Can't show the folder picker right now."); return; }
        ForgeFolderPicker *fp = _folderPicker;
        [top presentViewController:picker animated:YES completion:^{
            if (picker.presentingViewController == nil) [fp finish:nil];   // never appeared
        }];
    } else if ([op isEqualToString:@"gameFolderCopyIn"]) {
        // Reuse a file the game already has (its own downloads live under <game folder>/assets/...) instead of downloading
        // it again: copy <linked folder>/<rel> into the app's storage at <to>. Read-only for the game's folder.
        NSString *rel = [m[@"rel"] isKindOfClass:[NSString class]] ? m[@"rel"] : @"";
        NSString *to = [ForgeHost resolve:[m[@"to"] isKindOfClass:[NSString class]] ? m[@"to"] : @""];
        if (!to || rel.length == 0 || rel.length > 400 || [rel hasPrefix:@"/"] || [rel containsString:@".."] || [rel containsString:@"\\"]) { reply(nil, @"Bad file path."); return; }
        BOOL stale = NO; NSURL *dir = GameFolderURL(game, &stale);
        if (!dir) { reply(@{ @"linked": @NO }, nil); return; }
        void (^R)(id, NSString *) = ^(id v, NSString *e) { dispatch_async(dispatch_get_main_queue(), ^{ reply(v, e); }); };
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            if (![dir startAccessingSecurityScopedResource]) { R(@{ @"linked": @NO, @"lost": @YES }, nil); return; }
            NSURL *src = [dir URLByAppendingPathComponent:rel isDirectory:NO];
            NSFileManager *fm = [NSFileManager defaultManager];
            BOOL isDir = NO;
            if (![fm fileExistsAtPath:src.path isDirectory:&isDir] || isDir) { [dir stopAccessingSecurityScopedResource]; R(@{ @"linked": @YES, @"missing": @YES }, nil); return; }
            __block NSError *err = nil; __block unsigned long long bytes = 0;
            NSError *ce = nil;
            [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:src options:NSFileCoordinatorReadingWithoutChanges error:&ce byAccessor:^(NSURL *from) {
                NSString *part = [to stringByAppendingFormat:@".part%u", arc4random_uniform(1000000)];
                [fm createDirectoryAtPath:[to stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                [fm removeItemAtPath:part error:nil];
                if (![fm copyItemAtPath:from.path toPath:part error:&err]) { [fm removeItemAtPath:part error:nil]; return; }
                bytes = [[fm attributesOfItemAtPath:part error:nil] fileSize];
                [fm removeItemAtPath:to error:nil];
                if (![fm moveItemAtPath:part toPath:to error:&err]) [fm removeItemAtPath:part error:nil];
            }];
            [dir stopAccessingSecurityScopedResource];
            if (ce || err) { R(nil, [NSString stringWithFormat:@"Couldn't read %@ from the %@ folder.", rel.lastPathComponent, dir.lastPathComponent]); return; }
            R(@{ @"linked": @YES, @"copied": @YES, @"bytes": @(bytes) }, nil);
        });
    } else if ([op isEqualToString:@"gameFolderWrite"]) {
        NSString *file = [ForgeHost resolve:[m[@"path"] isKindOfClass:[NSString class]] ? m[@"path"] : @""];
        NSString *name = [m[@"name"] isKindOfClass:[NSString class]] ? [(NSString *)m[@"name"] lastPathComponent] : @"";
        BOOL isDir = NO;
        if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDir] || isDir) { reply(nil, @"The unit file is unavailable."); return; }
        NSString *ext = name.pathExtension.lowercaseString;
        if (name.length == 0 || [name hasPrefix:@"."] || [name containsString:@"/"] || !([ext isEqualToString:@"sprk"] || [ext isEqualToString:@"eclp"])) { reply(nil, @"Bad file name."); return; }
        BOOL stale = NO; NSURL *dir = GameFolderURL(game, &stale);
        if (!dir) { reply(@{ @"linked": @NO, @"lost": @([ud dataForKey:GameFolderKey(game)] != nil) }, nil); return; }
        // hashing, coordinating and copying can take a while (big units, the game holding the file): off the main thread
        void (^R)(id, NSString *) = ^(id v, NSString *e) { dispatch_async(dispatch_get_main_queue(), ^{ reply(v, e); }); };
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            if (![dir startAccessingSecurityScopedResource]) { R(@{ @"linked": @NO, @"lost": @YES }, nil); return; }
            if (stale) { NSData *bm = [dir bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:nil]; if (bm) [ud setObject:bm forKey:GameFolderKey(game)]; }
            NSURL *dest = [dir URLByAppendingPathComponent:name isDirectory:NO];
            NSURL *src = [NSURL fileURLWithPath:file];
            __block NSError *err = nil; __block BOOL existed = NO; __block BOOL same = NO;
            NSString *newHash = FileSha256(src);
            // the app already sent this exact unit (same content, timestamps aside): keep the file that is there
            BOOL onlyIfMissing = [m[@"onlyIfMissing"] boolValue];
            // the unit was renamed: its old file (one this app wrote) is replaced, not left behind as a duplicate
            NSString *replaces = [m[@"replaces"] isKindOfClass:[NSString class]] ? [(NSString *)m[@"replaces"] lastPathComponent] : @"";
            NSFileCoordinator *fc = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            NSError *ce = nil;
            [fc coordinateWritingItemAtURL:dest options:NSFileCoordinatorWritingForReplacing error:&ce byAccessor:^(NSURL *to) {
                NSFileManager *fm = [NSFileManager defaultManager];
                BOOL toDir = NO;
                existed = [fm fileExistsAtPath:to.path isDirectory:&toDir];
                if (existed && toDir) { err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteFileExistsError userInfo:@{ NSLocalizedDescriptionKey: @"a folder with that name is in the way" }]; return; }
                if (existed && (onlyIfMissing || (newHash && [newHash isEqualToString:FileSha256(to) ?: @""]))) { same = YES; return; }
                NSURL *tmp = [dir URLByAppendingPathComponent:[NSString stringWithFormat:@".%@.part", name]];
                [fm removeItemAtURL:tmp error:nil];
                if (![fm copyItemAtURL:src toURL:tmp error:&err]) { [fm removeItemAtURL:tmp error:nil]; return; }
                if (existed) { NSURL *res = nil; if (![fm replaceItemAtURL:to withItemAtURL:tmp backupItemName:nil options:0 resultingItemURL:&res error:&err]) [fm removeItemAtURL:tmp error:nil]; }
                else if (![fm moveItemAtURL:tmp toURL:to error:&err]) [fm removeItemAtURL:tmp error:nil];
            }];
            __block BOOL removedOld = NO;
            NSString *rext = replaces.pathExtension.lowercaseString;
            if (!ce && !err && replaces.length && ![replaces hasPrefix:@"."] && ![replaces isEqualToString:name] && ([rext isEqualToString:@"sprk"] || [rext isEqualToString:@"eclp"])) {
                NSURL *oldURL = [dir URLByAppendingPathComponent:replaces isDirectory:NO];
                [fc coordinateWritingItemAtURL:oldURL options:NSFileCoordinatorWritingForDeleting error:nil byAccessor:^(NSURL *u) {
                    removedOld = [[NSFileManager defaultManager] removeItemAtURL:u error:nil];
                }];
            }
            [dir stopAccessingSecurityScopedResource];
            if (ce || err) { R(nil, [NSString stringWithFormat:@"Couldn't save into the %@ folder: %@", dir.lastPathComponent, (ce ?: err).localizedDescription]); return; }
            R(@{ @"linked": @YES, @"written": @(!same), @"existed": @(existed), @"same": @(same), @"removedOld": @(removedOld), @"folder": dir.lastPathComponent ?: @"" }, nil);
        });
    } else {
        reply(nil, [NSString stringWithFormat:@"Unknown action: %@", op]);
    }
}

#pragma mark save a file with the iPhone's Save dialog (recordings)

- (void)saveDocument:(NSDictionary *)m reply:(void (^)(id _Nullable, NSString *_Nullable))reply {
    if (_exportReply) { reply(nil, @"Finish the existing recording save dialog first."); return; }
    NSString *file = [ForgeHost resolve:[m[@"path"] isKindOfClass:[NSString class]] ? m[@"path"] : @""];
    if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file]) { reply(nil, @"The recording is unavailable."); return; }
    NSString *name = [m[@"name"] isKindOfClass:[NSString class]] ? m[@"name"] : @"animation-recording.mp4";
    NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"save"];
    [[NSFileManager defaultManager] removeItemAtPath:dir error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *copy = [dir stringByAppendingPathComponent:name];
    if (![[NSFileManager defaultManager] copyItemAtPath:file toPath:copy error:nil]) { reply(nil, @"The recording is unavailable."); return; }
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForExportingURLs:@[[NSURL fileURLWithPath:copy]] asCopy:YES];
    picker.delegate = self;
    _exportReply = reply;
    _exportTemp = [NSURL fileURLWithPath:copy];
    UIViewController *top = self.controller;
    while (top.presentedViewController) top = top.presentedViewController;
    if (!top || top.isBeingDismissed) { _exportReply = nil; [[NSFileManager defaultManager] removeItemAtURL:_exportTemp error:nil]; _exportTemp = nil; reply(nil, @"Can't show the Save dialog right now."); return; }
    [top presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    [self finishExport:YES];
}
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [self finishExport:NO];
}
- (void)finishExport:(BOOL)saved {
    void (^r)(id, NSString *) = _exportReply;
    _exportReply = nil;
    if (_exportTemp) [[NSFileManager defaultManager] removeItemAtURL:_exportTemp error:nil];
    _exportTemp = nil;
    if (r) r(@{ @"saved": @(saved) }, nil);
}
@end
