import UIKit

/// 广告桥（ad.*）——对齐 shell-android AdBridge + AdManager 的方法/事件契约与 VIP 免广告逻辑。
///
/// 事件（ad.onEvent）事件名严格一致：
///   onAdLoaded / onAdFailed / onAdShow / onAdPlayStart / onAdPlayEnd / onAdClosed / onReward / onAdClicked
/// 载荷：{ placementId, event, code, msg }
/// load 类方法立即 resolveOk 释放调用，实际结果经事件异步下发。
///
/// VIP 免广告（代码级拦截，不依赖 Taku 后台分组）：
///   - 横幅/插屏/激励视频：VIP 时 load/show 入口直接拒绝，经 onAdFailed code=-10 msg="vip_no_ad"；
///   - 开屏广告不免（VIP 仅免 App 界面内广告，启动封面照常）。
///
/// 底层广告网络经 `AdNetwork` 抽象：未集成 Taku iOS 时使用 UnavailableAdNetwork（发 -1 失败事件），
/// 工程无 Pods 也能编译运行；集成 Taku 后在 Mac 侧补 TakuNetwork 即可点亮真实广告。
final class AdBridge: BridgeModule {

    private weak var viewController: ViewController?
    private let channel: JsChannel
    private let manager = AdManager.shared

    init(viewController: ViewController, channel: JsChannel) {
        self.viewController = viewController
        self.channel = channel
    }

    func handle(_ method: String, _ params: [String: Any], _ callbackId: String) -> Bool {
        guard method.hasPrefix("ad.") else { return false }
        switch method {
        case "ad.init": initAd(params, callbackId)
        case "ad.setUserType":
            manager.setUserType((params["userType"] as? String) ?? "normal")
            channel.resolveOk(callbackId)
        case "ad.loadRewarded":
            let pid = (params["placementId"] as? String) ?? ""
            manager.loadRewarded(pid, fire(pid)); channel.resolveOk(callbackId)
        case "ad.showRewarded":
            let pid = (params["placementId"] as? String) ?? ""
            manager.showRewarded(pid, vc: viewController, fire(pid)); channel.resolveOk(callbackId)
        case "ad.loadInterstitial":
            let pid = (params["placementId"] as? String) ?? ""
            manager.loadInterstitial(pid, fire(pid)); channel.resolveOk(callbackId)
        case "ad.showInterstitial":
            let pid = (params["placementId"] as? String) ?? ""
            manager.showInterstitial(pid, vc: viewController, fire(pid)); channel.resolveOk(callbackId)
        case "ad.banner.show": showBanner(params, callbackId)
        case "ad.banner.hide":
            let key = (params["positionKey"] as? String).flatMap { $0.isEmpty ? "default" : $0 } ?? "default"
            manager.hideBanner(positionKey: key, container: viewController)
            channel.resolveOk(callbackId)
        case "ad.splash.load":
            let pid = (params["placementId"] as? String) ?? ""
            manager.loadSplash(pid, fire(pid)); channel.resolveOk(callbackId)
        case "ad.splash.show":
            let pid = (params["placementId"] as? String) ?? ""
            manager.showSplash(pid, vc: viewController, fire(pid)); channel.resolveOk(callbackId)
        case "ad.native.show", "ad.native.hide":
            channel.resolveOk(callbackId)
        default:
            channel.resolveErr(callbackId, "unknown ad method: \(method)")
        }
        return true
    }

    private func initAd(_ params: [String: Any], _ callbackId: String) {
        let appId = (params["appId"] as? String) ?? ""
        let appKey = (params["appKey"] as? String) ?? ""
        if let ut = params["userType"] as? String, !ut.isEmpty { manager.setUserType(ut) }
        if appId.isEmpty || appKey.isEmpty {
            channel.resolve(callbackId, code: 0, data: ["msg": "success"])  // 无配置：视为空成功（对齐 Android）
            return
        }
        if manager.isInited {
            channel.resolve(callbackId, code: 0, data: ["msg": "already inited"]); return
        }
        _ = manager.initAd(appId: appId, appKey: appKey)
        channel.resolve(callbackId, code: 0, data: ["msg": "success"])
    }

    private func showBanner(_ params: [String: Any], _ callbackId: String) {
        guard let pid = params["placementId"] as? String, !pid.isEmpty else {
            channel.resolveErr(callbackId, "empty placementId"); return
        }
        let key = ((params["positionKey"] as? String)).flatMap { $0.isEmpty ? "default" : $0 } ?? "default"
        let view = manager.showBanner(positionKey: key, placementId: pid, fire(pid))
        if let view = view, let rect = params["rect"] as? [String: Any] {
            let dpr = (params["dpr"] as? NSNumber)?.doubleValue ?? 1.0
            // iOS 以 pt 布局：CSS px 直接作为 pt（无需 ×dpr，屏幕缩放由系统处理）
            _ = dpr
            let f = CGRect(x: CGFloat((rect["left"] as? NSNumber)?.doubleValue ?? 0),
                           y: CGFloat((rect["top"] as? NSNumber)?.doubleValue ?? 0),
                           width: CGFloat((rect["width"] as? NSNumber)?.doubleValue ?? 0),
                           height: CGFloat((rect["height"] as? NSNumber)?.doubleValue ?? 0))
            viewController?.attachBannerView(view, frame: f)
        }
        channel.resolveOk(callbackId)
    }

    /// 生成事件下发闭包（绑定 placementId）
    private func fire(_ placementId: String) -> AdManager.Event {
        return { [weak self] event, code, msg in
            self?.channel.emit("ad.onEvent", [
                "placementId": placementId, "event": event, "code": code, "msg": msg ?? ""
            ])
        }
    }
}
