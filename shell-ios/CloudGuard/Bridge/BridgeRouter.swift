import Foundation
import UIKit
import WebKit

/// 各原生能力模块的统一处理协议（对齐 Android 各 Manager 的 handle(method, params, callbackId): Boolean）。
protocol BridgeModule: AnyObject {
    /// 返回 true 表示已消费该 method；false 表示不归属本模块（交由路由器继续分发）
    @discardableResult
    func handle(_ method: String, _ params: [String: Any], _ callbackId: String) -> Bool
}

/// 桥接路由器：把 JS 的 method 分发到各原生能力模块，与 Android BridgeRouter 严格一致。
///
///   device.getInfo / permission.request / scan.qrcode
///   ble.* image.* share.* app.* ad.* pay.* miniprogram.* http.*
///
/// 所有处理统一切主线程（UIKit / WKWebView / 广告 SDK 均要求主线程）。
final class BridgeRouter: NSObject, WKScriptMessageHandler {

    static let messageHandlerName = "NativeBridge"

    private weak var viewController: ViewController?
    private let channel: JsChannel

    private let ble: BleBridge
    private let media: MediaBridge
    private let share: ShareBridge
    private let update: UpdateBridge
    private let ad: AdBridge
    private let http: HttpBridge
    private let pay: PayBridge
    private let miniProgram: MiniProgramBridge
    private let permission: PermissionBridge

    init(viewController: ViewController, channel: JsChannel, permission: PermissionBridge) {
        self.viewController = viewController
        self.channel = channel
        self.ble = BleBridge(channel: channel)
        self.media = MediaBridge(viewController: viewController, channel: channel)
        self.share = ShareBridge(viewController: viewController, channel: channel)
        self.update = UpdateBridge(viewController: viewController, channel: channel)
        self.ad = AdBridge(viewController: viewController, channel: channel)
        self.http = HttpBridge(channel: channel)
        self.pay = PayBridge(viewController: viewController, channel: channel)
        self.miniProgram = MiniProgramBridge(viewController: viewController, channel: channel)
        self.permission = permission
        super.init()
    }

    /// 页面销毁时释放资源
    func dispose() {
        ble.closeAdapter()
    }

    // MARK: - WKScriptMessageHandler（接收 shim 转发）

    func userContentController(_ userContentController: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        guard message.name == Self.messageHandlerName else { return }
        guard let body = message.body as? [String: Any],
              let method = body["method"] as? String else { return }
        let callbackId = (body["callbackId"] as? String) ?? ""
        let paramsJson = (body["params"] as? String) ?? "{}"
        let params: [String: Any]
        if let d = paramsJson.data(using: .utf8),
           let obj = (try? JSONSerialization.jsonObject(with: d, options: [])) as? [String: Any] {
            params = obj
        } else {
            params = [:]
        }
        dispatch(method, params, callbackId)
    }

    func dispatch(_ method: String, _ params: [String: Any], _ callbackId: String) {
        let run = { [weak self] in self?.safeRoute(method, params, callbackId) }
        if Thread.isMainThread { run() } else { DispatchQueue.main.async(execute: run) }
    }

    private func safeRoute(_ method: String, _ params: [String: Any], _ callbackId: String) {
        do {
            try route(method, params, callbackId)
        } catch {
            channel.resolveErr(callbackId, "bridge error: \(error.localizedDescription)")
        }
    }

    private func route(_ method: String, _ params: [String: Any], _ callbackId: String) throws {
        switch true {
        case method == "device.getInfo":
            channel.resolveOk(callbackId, deviceInfo())
        case method == "permission.request":
            handlePermission(params, callbackId)
        case method == "scan.qrcode":
            viewController?.requestScan(callbackId: callbackId)
        case method.hasPrefix("ble."):
            ble.handle(method, params, callbackId)
        case method.hasPrefix("image."):
            media.handle(method, params, callbackId)
        case method.hasPrefix("share."):
            share.handle(method, params, callbackId)
        case method.hasPrefix("app."):
            update.handle(method, params, callbackId)
        case method.hasPrefix("ad."):
            ad.handle(method, params, callbackId)
        case method.hasPrefix("pay."):
            pay.handle(method, params, callbackId)
        case method.hasPrefix("miniprogram."):
            miniProgram.handle(method, params, callbackId)
        case method.hasPrefix("http."):
            http.handle(method, params, callbackId)
        default:
            channel.resolveErr(callbackId, "unknown method: \(method)")
        }
    }

    // MARK: - device.getInfo

    private func handlePermission(_ params: [String: Any], _ callbackId: String) {
        let arr = (params["permissions"] as? [String]) ?? []
        permission.request(perms: arr) { result in
            self.channel.resolveOk(callbackId, result)
        }
    }

    private func deviceInfo() -> [String: Any] {
        let info = Bundle.main.infoDictionary
        let version = (info?["CFBundleShortVersionString"] as? String) ?? ""
        let build = (info?["CFBundleVersion"] as? String) ?? ""
        return [
            "platform": "ios",
            "system": "iOS \(UIDevice.current.systemVersion)",
            "model": DeviceInfo.machineIdentifier(),
            "brand": "Apple",
            "version": version,
            "buildNumber": build,
            "appId": Bundle.main.bundleIdentifier ?? ""
        ]
    }
}
