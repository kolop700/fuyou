import Foundation

/// 原生 HTTP 桥（http.*）——对齐 shell-android HttpManager。
///
/// 为什么需要：业务后端 fuyou.yefiot.com 未返回 CORS 允许头，H5 在 WKWebView 内用 XHR 会被
/// 同源策略拦截。本桥让 JS 经原生 URLSession 发请求，彻底绕开 CORS。
///
///   http.request {url, method, header, data, timeout} -> {statusCode, data}（data 尝试 JSON 解析）
///   http.upload  {url, name, fileName, mimeType, fileBase64, formData, header} -> {statusCode, data}（data 为原文）
final class HttpBridge: BridgeModule {

    private let channel: JsChannel
    private let session: URLSession

    init(channel: JsChannel) {
        self.channel = channel
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForResource = 60
        cfg.waitsForConnectivity = false
        self.session = URLSession(configuration: cfg)
    }

    func handle(_ method: String, _ params: [String: Any], _ callbackId: String) -> Bool {
        switch method {
        case "http.request": doRequest(params, callbackId); return true
        case "http.upload": doUpload(params, callbackId); return true
        default: channel.resolveErr(callbackId, "unknown http method: \(method)"); return true
        }
    }

    // MARK: - http.request

    private func doRequest(_ params: [String: Any], _ callbackId: String) {
        guard let rawUrl = params["url"] as? String, !rawUrl.isEmpty else {
            channel.resolveErr(callbackId, "empty url"); return
        }
        let verb = ((params["method"] as? String) ?? "GET").uppercased()
        let header = params["header"] as? [String: Any] ?? [:]
        let data = params["data"]
        let needsBody = verb != "GET" && verb != "HEAD"

        guard let url = buildURL(rawUrl, verb: verb, data: data) else {
            channel.resolveErr(callbackId, "invalid url: \(rawUrl)"); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = verb
        applyHeaders(header, to: &req, skipContentType: needsBody)
        if let timeoutMs = params["timeout"] as? NSNumber {
            req.timeoutInterval = max(1, timeoutMs.doubleValue / 1000.0)
        }
        if needsBody {
            req.httpBody = bodyData(from: data, header: header)
        }

        session.dataTask(with: req) { [weak self] bodyData, resp, err in
            guard let self = self else { return }
            if let err = err {
                self.channel.resolveErr(callbackId, "http error: \(err.localizedDescription)")
                return
            }
            let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let text = String(data: bodyData ?? Data(), encoding: .utf8) ?? ""
            self.channel.resolveOk(callbackId, ["statusCode": status, "data": Self.parseBody(text)])
        }.resume()
    }

    // MARK: - http.upload

    private func doUpload(_ params: [String: Any], _ callbackId: String) {
        guard let urlString = params["url"] as? String, !urlString.isEmpty,
              let url = URL(string: urlString) else {
            channel.resolveErr(callbackId, "empty url"); return
        }
        let name = (params["name"] as? String) ?? "file"
        let fileName = (params["fileName"] as? String) ?? "upload_\(Int(Date().timeIntervalSince1970 * 1000))"
        let mime = (params["mimeType"] as? String) ?? "application/octet-stream"
        let fileBase64 = (params["fileBase64"] as? String) ?? ""
        let formData = params["formData"] as? [String: Any] ?? [:]
        let header = params["header"] as? [String: Any] ?? [:]

        let fileData = Data(base64Encoded: fileBase64) ?? Data()
        let boundary = "----CloudGuard\(Int(Date().timeIntervalSince1970 * 1000))"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        applyHeaders(header, to: &req, skipContentType: true)

        var body = Data()
        for (k, v) in formData {
            body.appendString("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(k)\"\r\n\r\n\(Self.scalarString(v))\r\n")
        }
        body.appendString("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\nContent-Type: \(mime)\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n--\(boundary)--\r\n")
        req.httpBody = body

        session.uploadTask(with: req, from: body) { [weak self] respData, resp, err in
            guard let self = self else { return }
            if let err = err {
                self.channel.resolveErr(callbackId, "upload error: \(err.localizedDescription)")
                return
            }
            let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let text = String(data: respData ?? Data(), encoding: .utf8) ?? ""
            self.channel.resolveOk(callbackId, ["statusCode": status, "data": text])
        }.resume()
    }

    // MARK: - 工具

    private func applyHeaders(_ header: [String: Any], to req: inout URLRequest, skipContentType: Bool) {
        for (k, v) in header {
            if skipContentType && k.lowercased() == "content-type" { continue }
            let s = Self.scalarString(v)
            if !s.isEmpty { req.setValue(s, forHTTPHeaderField: k) }
        }
    }

    private func bodyData(from data: Any?, header: [String: Any]) -> Data {
        switch data {
        case let d as Data: return d
        case is [String: Any], is [Any]:
            if let obj = data, JSONSerialization.isValidJSONObject(obj),
               let d = try? JSONSerialization.data(withJSONObject: obj, options: []) { return d }
            return Data()
        case let s as String: return s.data(using: .utf8) ?? Data()
        case nil: return Data()
        default: return String(describing: data!).data(using: .utf8) ?? Data()
        }
    }

    private func buildURL(_ raw: String, verb: String, data: Any?) -> URL? {
        if verb != "GET" && verb != "HEAD" { return URL(string: raw) }
        guard let dict = data as? [String: Any], !dict.isEmpty else { return URL(string: raw) }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        var pairs: [String] = []
        for (k, v) in dict {
            let ek = k.addingPercentEncoding(withAllowedCharacters: allowed) ?? k
            let ev = Self.scalarString(v).addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
            pairs.append("\(ek)=\(ev)")
        }
        let joined = pairs.joined(separator: "&")
        let full = raw.contains("?") ? "\(raw)&\(joined)" : "\(raw)?\(joined)"
        return URL(string: full)
    }

    private static func scalarString(_ v: Any?) -> String {
        switch v {
        case nil: return ""
        case let n as NSNumber: return n.stringValue
        case let s as String: return s
        default: return String(describing: v!)
        }
    }

    /// 尝试把响应体解析为 JSON（对齐 uni.request），失败则原样返回字符串
    private static func parseBody(_ text: String) -> Any {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "" }
        guard let d = t.data(using: .utf8) else { return t }
        if let obj = try? JSONSerialization.jsonObject(with: d, options: [.allowFragments]) {
            return obj
        }
        return t
    }
}

private extension Data {
    mutating func appendString(_ s: String) {
        if let d = s.data(using: .utf8) { append(d) }
    }
}
