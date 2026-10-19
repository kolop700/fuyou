import Foundation
import WebKit

/// JS 通道：封装「原生 -> JS」的两类回传，与 Android JsChannel 逐一对齐。
///
///  1) 调用回传： window.__nativeCallback(callbackId, "<json string>")
///     其中 json string 为信封 {"code":Int,"data":{...},"msg":"..."}，code===0 成功。
///  2) 事件推送： window.__nativeEmit(eventName, "<json string>")
///
/// 所有回传统一切主线程经 evaluateJavaScript 执行（对齐 Android Handler(mainLooper)）。
final class JsChannel {

    /// 关联的 WKWebView（弱引用，随壳销毁）
    weak var webView: WKWebView?

    init(webView: WKWebView) {
        self.webView = webView
    }

    // MARK: - 调用回传

    func resolve(_ callbackId: String?, code: Int, data: [String: Any]? = nil, msg: String? = nil) {
        guard let callbackId = callbackId, !callbackId.isEmpty else { return }
        var envelope: [String: Any] = ["code": code]
        if let msg = msg { envelope["msg"] = msg }
        if let data = data { envelope["data"] = data }
        let resStr = (Self.jsonString(envelope)) ?? "{\"code\":\(code)}"
        // 两个参数均为字符串：callbackId、信封 JSON 原文（前端会 JSON.parse）
        invokeJS("window.__nativeCallback", args: [callbackId, resStr])
    }

    func resolveOk(_ callbackId: String?, _ data: [String: Any]? = nil) {
        resolve(callbackId, code: 0, data: data)
    }

    func resolveErr(_ callbackId: String?, _ msg: String, code: Int = -1) {
        resolve(callbackId, code: code, data: nil, msg: msg)
    }

    // MARK: - 事件推送

    func emit(_ event: String, data: [String: Any]) {
        let dataStr = Self.jsonString(data) ?? "{}"
        invokeJS("window.__nativeEmit", args: [event, dataStr])
    }

    // MARK: - 内部

    private func invokeJS(_ fn: String, args: [Any]) {
        let argStr = (Self.jsonString(args)) ?? "[]"
        // jsonString([...]) 形如 ["a","b"]，去掉首尾中括号即为 "a","b" 参数列表
        let inner = String(argStr.dropFirst().dropLast())
        let js = "\(fn)(\(inner));"
        let run = { [weak self] in self?.webView?.evaluateJavaScript(js, completionHandler: nil) }
        if Thread.isMainThread { run() } else { DispatchQueue.main.async(execute: run) }
    }

    private static func jsonString(_ obj: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(obj) || obj is [Any] || obj is [String: Any] else { return nil }
        guard let d = try? JSONSerialization.data(withJSONObject: obj, options: []) else { return nil }
        return String(data: d, encoding: .utf8)
    }
}
