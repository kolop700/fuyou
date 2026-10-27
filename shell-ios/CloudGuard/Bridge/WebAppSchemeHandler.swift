import Foundation
import WebKit

/// 自定义 scheme（cloudapp://）本地资源加载器：把 Bundle 内 WebApp/ 目录以「安全上下文」暴露给 WKWebView，
/// 使 H5 产物具备可用的 Blob / localStorage / 现代 Web API（对齐 Android WebViewAssetLoader 方案）。
///
/// 路径映射：cloudapp://local/<path> -> <Bundle>/WebApp/<path>
/// 未命中且无扩展名时回退 index.html（兼容 SPA history 路由）。
final class WebAppSchemeHandler: NSObject, WKURLSchemeHandler {

    static let scheme = "cloudapp"
    static let startURL = URL(string: "\(scheme)://local/index.html")!

    private let rootURL: URL
    private var tasks: [ObjectIdentifier: WKURLSchemeTask] = [:]
    private let lock = NSLock()

    override init() {
        // WebApp 作为 folder reference 打进 Bundle，保持目录层级
        if let res = Bundle.main.url(forResource: "WebApp", withExtension: nil) {
            rootURL = res
        } else {
            rootURL = Bundle.main.bundleURL.appendingPathComponent("WebApp")
        }
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        lock.lock(); tasks[ObjectIdentifier(urlSchemeTask)] = urlSchemeTask; lock.unlock()
        let url = urlSchemeTask.request.url
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let (data, mime, code) = self.load(for: url)
            // WKURLSchemeTask 回调必须在主线程：iOS 27 beta 起非主线程调用会抛异常
            // 导致整个页面加载失败（App Store 审核 2.1(a)“启动即报错”实锤于 iPadOS 27，2026-10-27）
            DispatchQueue.main.async {
                guard self.isAlive(urlSchemeTask) else { return }
                if let data = data {
                    let headers = [
                        "Content-Type": mime,
                        "Content-Length": String(data.count),
                        "Access-Control-Allow-Origin": "*",
                        "Cache-Control": "no-cache"
                    ]
                    let resp = HTTPURLResponse(url: url ?? URL(string: "about:blank")!,
                                               statusCode: code, httpVersion: "HTTP/1.1", headerFields: headers)!
                    urlSchemeTask.didReceive(resp)
                    urlSchemeTask.didReceive(data)
                    urlSchemeTask.didFinish()
                } else {
                    let resp = HTTPURLResponse(url: url ?? URL(string: "about:blank")!,
                                               statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
                    urlSchemeTask.didReceive(resp)
                    urlSchemeTask.didFinish()
                }
                self.forget(urlSchemeTask)
            }
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // stop 由 WebKit 在主线程回调；若任务已完成被 forget，移除为空操作安全
        forget(urlSchemeTask)
    }

    // MARK: - 资源解析

    private func load(for url: URL?) -> (Data?, String, Int) {
        let path = (url?.path ?? "/").trimmingCharacters(in: .whitespaces)
        guard !path.contains("..") else { return (nil, "text/plain", 403) }
        let rel = String(path.dropFirst())  // 去掉前导 "/"

        func fileURL(_ relative: String) -> URL? {
            guard !relative.isEmpty else { return nil }
            let candidate = rootURL.appendingPathComponent(relative)
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDir) && !isDir.boolValue ? candidate : nil
        }

        if let u = rel.isEmpty ? nil : fileURL(rel) {
            return ((try? Data(contentsOf: u)) ?? nil, Self.mime(for: u.pathExtension), 200)
        }
        // SPA 兜底：无扩展名视为路由，返回 index.html
        let ext = (rel as NSString).pathExtension
        if ext.isEmpty {
            let index = rootURL.appendingPathComponent("index.html")
            if let d = try? Data(contentsOf: index) { return (d, "text/html", 200) }
        }
        return (nil, "text/plain", 404)
    }

    private static func mime(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": return "text/html"
        case "js", "mjs": return "application/javascript"
        case "css": return "text/css"
        case "json", "map": return "application/json"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "webp": return "image/webp"
        case "bmp": return "image/bmp"
        case "ico": return "image/x-icon"
        case "woff": return "font/woff"
        case "woff2": return "font/woff2"
        case "ttf": return "font/ttf"
        case "otf": return "font/otf"
        case "mp4": return "video/mp4"
        case "mp3": return "audio/mpeg"
        default: return "application/octet-stream"
        }
    }

    private func isAlive(_ task: WKURLSchemeTask) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return tasks[ObjectIdentifier(task)] != nil
    }

    private func forget(_ task: WKURLSchemeTask) {
        lock.lock(); tasks.removeValue(forKey: ObjectIdentifier(task)); lock.unlock()
    }
}
