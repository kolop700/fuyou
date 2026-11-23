import UIKit
#if canImport(AnyThinkSDK)
import AnyThinkSDK
#endif

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 【启动弹窗兜底】先于一切 SDK 调用预置「集成警告」抑制标记：
        // "AnyThink Adx SDK is missing" 弹窗文案由 Taku 服务端下发，只要 SDK 被加载
        // 就可能触发（与该不该初始化无关），审核场景会被判为启动报错（Guideline 2.1(a)）。
        // 酷盈 ADX 适配器已不集成（见 Podfile），此处再提前置位双保险，确保任何触发路径均不弹。
        // 注：ATT 授权弹窗不在此处——追踪数据收集前才需授权，由 TakuNetwork.initSDK
        // 在 SDK start 前拉起（Guideline 2.1 审核要求，2026-11-18）。
        #if canImport(AnyThinkSDK)
        ATAPI.ignoreToastIfNeeded()
        #endif
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
        self.window = window
        // 微信 OpenSDK 注册（未集成 SDK 时为空实现，不影响启动）
        AppSDK.registerWechatIfNeeded()
        return true
    }

    // MARK: - URL Scheme 回调（微信/支付宝 返回）

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // 依次交给运行时集成的 SDK（未集成对应 SDK 时静默返回 false，不影响其它处理）
        if AppSDK.handleOpen(url) { return true }
        return false
    }

    // MARK: - Universal Links（微信 applinks:fuyou.yefiot.com）

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return AppSDK.handleUniversalLink(userActivity)
    }
}
