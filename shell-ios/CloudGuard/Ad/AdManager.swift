import UIKit

/// 广告管理（对齐 shell-android AdManager.java 的方法/事件/VIP 逻辑）。
final class AdManager {

    /// 事件回调：(event, code, msg)
    typealias Event = (String, Int, String?) -> Void

    static let shared = AdManager()

    private let vipBlockCode = -10
    private let notReadyCode = -3
    private let keyUserType = "ad_user_type"

    private(set) var isInited = false

    /// 位图广告视图缓存（positionKey -> view），供 banner show/hide 复用
    private var bannerViews: [String: UIView] = [:]

    private let network: AdNetwork = AdNetworkFactory.make()

    private init() {}

    // MARK: - 生命周期

    @discardableResult
    func initAd(appId: String, appKey: String) -> Bool {
        isInited = true
        network.initSDK(appId: appId, appKey: appKey)
        return true
    }

    // MARK: - VIP 免广告（user_type 本地持久化）

    func setUserType(_ type: String) {
        let t = type.lowercased() == "vip" ? "vip" : "normal"
        UserDefaults.standard.set(t, forKey: keyUserType)
        network.setUserType(t)
    }

    private var userType: String { UserDefaults.standard.string(forKey: keyUserType) ?? "normal" }
    private var isVip: Bool { userType == "vip" }

    // MARK: - 激励视频（VIP 免）

    func loadRewarded(_ pid: String, _ cb: @escaping Event) {
        if isVip { cb("onAdFailed", vipBlockCode, "vip_no_ad"); return }
        network.loadRewarded(pid, cb)
    }

    func showRewarded(_ pid: String, vc: UIViewController?, _ cb: @escaping Event) {
        if isVip { cb("onAdFailed", vipBlockCode, "vip_no_ad"); return }
        guard let vc = vc else { cb("onAdFailed", notReadyCode, "no view controller"); return }
        network.showRewarded(pid, in: vc, cb)
    }

    // MARK: - 插屏（VIP 免）

    func loadInterstitial(_ pid: String, _ cb: @escaping Event) {
        if isVip { cb("onAdFailed", vipBlockCode, "vip_no_ad"); return }
        network.loadInterstitial(pid, cb)
    }

    func showInterstitial(_ pid: String, vc: UIViewController?, _ cb: @escaping Event) {
        if isVip { cb("onAdFailed", vipBlockCode, "vip_no_ad"); return }
        guard let vc = vc else { cb("onAdFailed", notReadyCode, "no view controller"); return }
        network.showInterstitial(pid, in: vc, cb)
    }

    // MARK: - 横幅（VIP 免）

    /// 返回待挂载的 banner 视图（未就绪/未集成/VIP 时为 nil）
    func showBanner(positionKey: String, placementId: String, _ cb: @escaping Event) -> UIView? {
        if isVip { cb("onAdFailed", vipBlockCode, "vip_no_ad"); return nil }
        let view = network.makeBanner(placementId: placementId, cb)
        if let view = view { bannerViews[positionKey] = view }
        else { cb("onAdFailed", notReadyCode, "banner not ready") }
        return view
    }

    func hideBanner(positionKey: String, container: UIViewController?) {
        guard let v = bannerViews.removeValue(forKey: positionKey) else { return }
        if let vc = container as? ViewController { vc.detachBannerView(v) } else { v.removeFromSuperview() }
    }

    // MARK: - 开屏（VIP 不免）

    func loadSplash(_ pid: String, _ cb: @escaping Event) {
        network.loadSplash(pid, cb)
    }

    func showSplash(_ pid: String, vc: UIViewController?, _ cb: @escaping Event) {
        guard let vc = vc as? ViewController else { cb("onAdFailed", notReadyCode, "no container"); return }
        network.showSplash(pid, in: vc.splashLayer, cb)
    }
}

// MARK: - 广告网络抽象

protocol AdNetwork: AnyObject {
    func initSDK(appId: String, appKey: String)
    func setUserType(_ type: String)
    func loadRewarded(_ pid: String, _ cb: @escaping AdManager.Event)
    func showRewarded(_ pid: String, in vc: UIViewController, _ cb: @escaping AdManager.Event)
    func loadInterstitial(_ pid: String, _ cb: @escaping AdManager.Event)
    func showInterstitial(_ pid: String, in vc: UIViewController, _ cb: @escaping AdManager.Event)
    func makeBanner(placementId: String, _ cb: @escaping AdManager.Event) -> UIView?
    func loadSplash(_ pid: String, _ cb: @escaping AdManager.Event)
    func showSplash(_ pid: String, in container: UIView, _ cb: @escaping AdManager.Event)
}

enum AdNetworkFactory {
    static func make() -> AdNetwork {
        // 集成 Taku iOS（AnyThinkiOS）后，在此返回 TakuNetwork()；当前使用占位实现。
        return UnavailableAdNetwork()
    }
}

/// 未集成广告 SDK 时的占位网络：所有请求即刻以「未集成」失败事件回落，保证 JS 侧不卡加载态。
final class UnavailableAdNetwork: AdNetwork {
    private let code = -1
    private let msg = "ad sdk not integrated"

    func initSDK(appId: String, appKey: String) {}
    func setUserType(_ type: String) {}
    func loadRewarded(_ pid: String, _ cb: @escaping AdManager.Event) { cb("onAdFailed", code, msg) }
    func showRewarded(_ pid: String, in vc: UIViewController, _ cb: @escaping AdManager.Event) { cb("onAdFailed", code, msg) }
    func loadInterstitial(_ pid: String, _ cb: @escaping AdManager.Event) { cb("onAdFailed", code, msg) }
    func showInterstitial(_ pid: String, in vc: UIViewController, _ cb: @escaping AdManager.Event) { cb("onAdFailed", code, msg) }
    func makeBanner(placementId: String, _ cb: @escaping AdManager.Event) -> UIView? { return nil }
    func loadSplash(_ pid: String, _ cb: @escaping AdManager.Event) { cb("onAdFailed", code, msg) }
    func showSplash(_ pid: String, in container: UIView, _ cb: @escaping AdManager.Event) { cb("onAdFailed", code, msg) }
}
