import UIKit

#if canImport(AnyThinkSDK)
import AnyThinkSDK
import AppTrackingTransparency

/// Taku（AnyThinkiOS）真实广告网络实现 —— 实现 AdManager.swift 的 `AdNetwork` 协议。
///
/// 集成路径：Podfile 引入 `AnyThinkiOS` 后（`pod install` → 打开 .xcworkspace），
/// `AdNetworkFactory.make()` 编译期自动切换到本类；未集成 Pods 时本文件整体不参与编译，
/// 工程仍可无 Pods 直接构建（回落 UnavailableAdNetwork），与壳的「按需集成」设计一致。
///
/// API 用法对照云卫家 shell-ios AdBridge.swift（AnyThinkSDK 6.5.73 实测签名）：
/// - 加载/展示：ATAdManager.shared() 全套 loadAD/showXXX + Ready 判断；
/// - 事件：五个 delegate 协议统一转成 AdManager.Event（onAdLoaded/onAdFailed/onAdShow/
///   onAdPlayStart/onAdPlayEnd/onAdClosed/onReward/onAdClicked），经 placementId 注册表回给
///   发起 load/show 时传入的回调（AdBridge.fire → ad.onEvent）；
/// - 开屏不免广告、横幅/插屏/激励的 VIP 拦截在 AdManager 层完成，本类不重复判断。
///
/// 与云卫家的两点适配差异：
/// 1. showSplash 协议只给 container UIView（ViewController.splashLayer），window/vc 从
///    container.window 现场取；
/// 2. makeBanner 未就绪时返回 nil（AdManager 会发 -3 "banner not ready"），同时内部继续
///    加载，加载成功经 onAdLoaded 事件通知 —— H5 侧 taku-banner 收到 loaded 后重试 show。
final class TakuNetwork: NSObject, AdNetwork {

    /// 未就绪失败码（与 AdManager.notReadyCode 对齐）
    private let notReadyCode = -3
    /// 参数为空失败码
    private let badParamCode = -2

    /// SDK 已启动标记（ATAPI.start 幂等保护）
    private var sdkStarted = false
    /// 最近一次下发给 Taku 后台的用户类型（仅统计对账用）
    private var userType = "normal"

    /// placementId -> 事件回调注册表：load/show 入口登记，delegate 回调按 placementId 转发。
    /// 同一广告位后到的回调覆盖先前的（show 覆盖 load 阶段的登记，属预期行为）。
    private var callbacks: [String: AdManager.Event] = [:]

    /// error 的 NSError 错误码（-1 兜底）
    private func errCode(_ error: Error?) -> Int {
        guard let error = error else { return -1 }
        return (error as NSError).code
    }

    private func errMsg(_ error: Error?) -> String {
        return error?.localizedDescription ?? ""
    }

    private func fire(_ placementId: String, _ event: String, _ code: Int, _ msg: String) {
        callbacks[placementId]?(event, code, msg)
    }

    // MARK: - 生命周期 / 用户类型

    func initSDK(appId: String, appKey: String) {
        guard !appId.isEmpty, !appKey.isEmpty else { return }
        if sdkStarted {
            requestTrackingIfNeeded() // 已初始化（幂等）：仅补一次 ATT 授权检查
            return
        }
        // customData 在 start 前设置，保证初始化后的首个广告请求即携带用户分组信息
        applyCustomData()
#if DEBUG
        ATAPI.setLogEnabled(true)
#endif
        do {
            // 由 H5 在用户同意隐私政策后经 ad.init 触发，不在 App 启动路径调用
            try ATAPI.sharedInstance().start(withAppID: appId, appKey: appKey)
            sdkStarted = true
            requestTrackingIfNeeded()
        } catch {
            NSLog("[TakuNetwork] ATSDK start failed: %@", errMsg(error))
        }
    }

    func setUserType(_ type: String) {
        userType = type
        applyCustomData()
    }

    /// Taku 全局自定义参数：user_type（免广告拦截在 AdManager 代码级完成，此处仅供后台统计对账）
    private func applyCustomData() {
        ATSDKGlobalSetting.sharedManager().customData = ["user_type": userType]
    }

    /// 请求 ATT 授权（iOS 14.5+，弹窗文案见 Info.plist 的 NSUserTrackingUsageDescription）。
    /// 仅 .notDetermined 时弹；inactive 状态调用不弹也不回调，故不阻塞任何流程（fire-and-forget，
    /// 下次 ad.init 会再尝试）。
    private func requestTrackingIfNeeded() {
        DispatchQueue.main.async {
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }

    /// 广告点击落地页的呈现控制器兜底（横幅/开屏需要；主 window 的 rootViewController）
    private static func rootViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }.first
            let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
            if let root = window?.rootViewController { return root }
        }
        return UIApplication.shared.windows.first?.rootViewController
    }

    // MARK: - 激励视频

    func loadRewarded(_ pid: String, _ cb: @escaping AdManager.Event) {
        guard !pid.isEmpty else { cb("onAdFailed", badParamCode, "empty placementId"); return }
        callbacks[pid] = cb
        ATAdManager.shared().loadAD(withPlacementID: pid, extra: [:], delegate: self)
    }

    func showRewarded(_ pid: String, in vc: UIViewController, _ cb: @escaping AdManager.Event) {
        guard !pid.isEmpty else { cb("onAdFailed", badParamCode, "empty placementId"); return }
        callbacks[pid] = cb
        guard ATAdManager.shared().rewardedVideoReady(forPlacementID: pid) else {
            cb("onAdFailed", notReadyCode, "ad not ready"); return
        }
        let config = ATShowConfig(scene: "", showCustomExt: "")
        // ObjC 参数标签 inViewController: 经 Swift 导入剪枝为 in:（show 系列方法同理）
        ATAdManager.shared().showRewardedVideo(withPlacementID: pid, config: config, in: vc, delegate: self)
    }

    // MARK: - 插屏

    func loadInterstitial(_ pid: String, _ cb: @escaping AdManager.Event) {
        guard !pid.isEmpty else { cb("onAdFailed", badParamCode, "empty placementId"); return }
        callbacks[pid] = cb
        ATAdManager.shared().loadAD(withPlacementID: pid, extra: [:], delegate: self)
    }

    func showInterstitial(_ pid: String, in vc: UIViewController, _ cb: @escaping AdManager.Event) {
        guard !pid.isEmpty else { cb("onAdFailed", badParamCode, "empty placementId"); return }
        callbacks[pid] = cb
        guard ATAdManager.shared().interstitialReady(forPlacementID: pid) else {
            cb("onAdFailed", notReadyCode, "ad not ready"); return
        }
        let config = ATShowConfig(scene: "", showCustomExt: "")
        ATAdManager.shared().showInterstitial(withPlacementID: pid,
                                              showConfig: config,
                                              in: vc,
                                              delegate: self,
                                              nativeMixViewBlock: nil)
    }

    // MARK: - 横幅

    /// 返回待挂载的 ATBannerView；未就绪时触发加载并返回 nil（调用方发 -3，H5 收到 onAdLoaded 后重试）
    func makeBanner(placementId: String, _ cb: @escaping AdManager.Event) -> UIView? {
        guard !placementId.isEmpty else { cb("onAdFailed", badParamCode, "empty placementId"); return nil }
        callbacks[placementId] = cb
        guard ATAdManager.shared().bannerAdReady(forPlacementID: placementId) else {
            // 尺寸交给 Taku 后台配置的横幅比例（H5 容器 100% 宽由 attachBannerView 的 frame 决定）
            ATAdManager.shared().loadAD(withPlacementID: placementId, extra: [:], delegate: self)
            return nil
        }
        let config = ATShowConfig(scene: "", showCustomExt: "")
        guard let view = ATAdManager.shared().retrieveBannerView(forPlacementID: placementId,
                                                                 config: config) else {
            cb("onAdFailed", -1, "retrieve banner view failed"); return nil
        }
        view.delegate = self
        view.presentingViewController = TakuNetwork.rootViewController()
        return view
    }

    // MARK: - 开屏（VIP 不免，拦截与否由 AdManager 决定）

    func loadSplash(_ pid: String, _ cb: @escaping AdManager.Event) {
        guard !pid.isEmpty else { cb("onAdFailed", badParamCode, "empty placementId"); return }
        callbacks[pid] = cb
        var extra: [AnyHashable: Any] = [:]
        // 开屏请求容忍超时（秒）：超时后 didTimeoutLoadingSplashAD 回调下发失败事件
        extra[kATSplashExtraTolerateTimeoutKey] = NSNumber(value: 8)
        ATAdManager.shared().loadAD(withPlacementID: pid, extra: extra, delegate: self, containerView: nil)
    }

    /// 协议只给 container（ViewController.splashLayer）：window / 呈现控制器从 container.window 现场取
    func showSplash(_ pid: String, in container: UIView, _ cb: @escaping AdManager.Event) {
        guard !pid.isEmpty else { cb("onAdFailed", badParamCode, "empty placementId"); return }
        callbacks[pid] = cb
        guard let window = container.window,
              let vc = window.rootViewController ?? TakuNetwork.rootViewController() else {
            cb("onAdFailed", notReadyCode, "window not available"); return
        }
        guard ATAdManager.shared().splashReady(forPlacementID: pid) else {
            cb("onAdFailed", notReadyCode, "ad not ready"); return
        }
        let config = ATShowConfig(scene: "", showCustomExt: "")
        ATAdManager.shared().showSplash(withPlacementID: pid,
                                        config: config,
                                        window: window,
                                        in: vc,
                                        extra: [:],
                                        delegate: self)
    }
}

// MARK: - Taku 回调（delegate 事件 -> AdManager.Event 转发）
//
// 签名严格按 AnyThinkSDK 6.5.73 framework Headers 的 Swift 导入形态（与云卫家实测一致）：
// - ATAdLoadingDelegate.h 无 NS_ASSUME_NONNULL，参数导入为 IUO（String! / Error!）；
// - 其余协议头在非可选区；不使用显式 @objc(selector)（Xcode 26 按导入后 Swift 签名严格校验）。

extension TakuNetwork: ATAdLoadingDelegate, ATRewardedVideoDelegate, ATInterstitialDelegate, ATSplashDelegate, ATBannerDelegate {

    // ---- 加载通用（ATAdLoadingDelegate） ----

    func didFinishLoadingAD(withPlacementID placementID: String!) {
        fire(placementID, "onAdLoaded", 0, "")
    }

    func didFailToLoadAD(withPlacementID placementID: String!, error: Error!) {
        fire(placementID, "onAdFailed", errCode(error), errMsg(error))
    }

    // ---- 激励视频（ATRewardedVideoDelegate；头文件拼写即 PlacemenID） ----

    func rewardedVideoDidRewardSuccess(forPlacemenID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onReward", 0, "")
    }

    // 二次激励回调（「再看一个」重播奖励）：预留，不重复下发 onReward
    func onRewardedSuccessRetry(forPlacemenID placementID: String, extra: [AnyHashable: Any]?) {}

    func rewardedVideoDidStartPlaying(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdPlayStart", 0, "")
    }

    func rewardedVideoDidEndPlaying(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdPlayEnd", 0, "")
    }

    func rewardedVideoDidFailToPlay(forPlacementID placementID: String, error: Error, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdFailed", errCode(error), errMsg(error))
    }

    func rewardedVideoDidClose(forPlacementID placementID: String, rewarded: Bool, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdClosed", 0, rewarded ? "rewarded" : "")
    }

    func rewardedVideoDidClick(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdClicked", 0, "")
    }

    // ---- 插屏（ATInterstitialDelegate） ----

    func interstitialDidShow(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdShow", 0, "")
    }

    func interstitialFailedToShow(forPlacementID placementID: String, error: Error, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdFailed", errCode(error), errMsg(error))
    }

    func interstitialDidStartPlayingVideo(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdPlayStart", 0, "")
    }

    func interstitialDidEndPlayingVideo(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdPlayEnd", 0, "")
    }

    func interstitialDidClose(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdClosed", 0, "")
    }

    func interstitialDidClick(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdClicked", 0, "")
    }

    // ---- 开屏（ATSplashDelegate） ----

    func splashDidShow(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdShow", 0, "")
    }

    func splashDidClick(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdClicked", 0, "")
    }

    func splashDidClose(forPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdClosed", 0, "")
    }

    func didFinishLoadingSplashAD(withPlacementID placementID: String, isTimeout: Bool) {
        // isTimeout=true 表示加载完成但已超时（仍视为加载成功，展示窗口由 JS 控制）
        fire(placementID, "onAdLoaded", 0, isTimeout ? "timeout" : "")
    }

    func didTimeoutLoadingSplashAD(withPlacementID placementID: String) {
        fire(placementID, "onAdFailed", -1, "splash load timeout")
    }

    func splashDidShowFailed(forPlacementID placementID: String, error: Error, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdFailed", errCode(error), errMsg(error))
    }

    // ---- 横幅（ATBannerDelegate） ----

    func bannerView(_ bannerView: ATBannerView, didShowAdWithPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdShow", 0, "")
    }

    func bannerView(_ bannerView: ATBannerView, didClickWithPlacementID placementID: String, extra: [AnyHashable: Any]) {
        fire(placementID, "onAdClicked", 0, "")
    }

    func bannerView(_ bannerView: ATBannerView, didTapCloseButtonWithPlacementID placementID: String, extra: [AnyHashable: Any]) {
        // 用户点击横幅关闭按钮：移除视图（AdManager 缓存条目由 hideBanner/下次 show 覆盖清理）
        bannerView.removeFromSuperview()
        fire(placementID, "onAdClosed", 0, "")
    }
}

#endif
