import Foundation
import WebKit

/// Serves the bundled web app (the "site" folder inside the app) at app://local/…
/// A real origin (not file://) is needed so workers, fetch() of the game data and the
/// saved-units database (IndexedDB) all work, fully offline.
final class SiteSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "app"
    static let startURL = URL(string: "app://local/index.html")!

    private let root: URL = Bundle.main.resourceURL!.appendingPathComponent("site", isDirectory: true).standardizedFileURL
    private var stopped = Set<ObjectIdentifier>()
    private let lock = NSLock()

    private static let types: [String: String] = [
        "html": "text/html; charset=utf-8",
        "js": "text/javascript; charset=utf-8",
        "cjs": "text/javascript; charset=utf-8",
        "mjs": "text/javascript; charset=utf-8",
        "css": "text/css; charset=utf-8",
        "json": "application/json; charset=utf-8",
        "webmanifest": "application/manifest+json",
        "gz": "application/gzip",
        "wasm": "application/wasm",
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "webp": "image/webp",
        "gif": "image/gif",
        "svg": "image/svg+xml",
        "ico": "image/x-icon",
        "ttf": "font/ttf",
        "otf": "font/otf",
        "woff": "font/woff",
        "woff2": "font/woff2",
        "txt": "text/plain; charset=utf-8",
        "mp3": "audio/mpeg",
        "ogg": "audio/ogg",
        "mp4": "video/mp4",
    ]

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return fail(task, 400) }
        var path = url.path.removingPercentEncoding ?? url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let file = root.appendingPathComponent(String(path.dropFirst())).standardizedFileURL
        // never serve anything outside the site folder
        guard file.path.hasPrefix(root.path + "/") else { return fail(task, 403) }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: file, options: .mappedIfSafe) else {
                return DispatchQueue.main.async { self.fail(task, 404) }
            }
            let type = Self.types[file.pathExtension.lowercased()] ?? "application/octet-stream"
            let headers = [
                "Content-Type": type,
                "Content-Length": String(data.count),
                "Cache-Control": "no-cache",
                "Access-Control-Allow-Origin": "*",
            ]
            DispatchQueue.main.async {
                guard self.isActive(task) else { return }
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
                task.didReceive(response)
                task.didReceive(data)
                task.didFinish()
            }
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {
        lock.lock(); stopped.insert(ObjectIdentifier(task)); lock.unlock()
    }

    private func isActive(_ task: WKURLSchemeTask) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return stopped.remove(ObjectIdentifier(task)) == nil
    }

    private func fail(_ task: WKURLSchemeTask, _ status: Int) {
        guard isActive(task), let url = task.request.url else { return }
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "text/plain", "Content-Length": "0"])!
        task.didReceive(response)
        task.didReceive(Data())
        task.didFinish()
    }
}
