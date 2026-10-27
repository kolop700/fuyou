import UIKit
import WebKit

/// 壳主容器：WKWebView 加载 H5 产物（Bundle 内 WebApp/）+ JS 桥接。
///
/// 对齐 shell-android MainActivity：
///  - 本地资源经自定义 scheme(cloudapp://) 以「安全上下文」加载，可用 Blob/localStorage；
///  - window.NativeBridge 由 WKUserScript 注入 shim，转发到 WKScriptMessageHandler；
///  - 广告悬浮层（bannerContainer / splashContainer）叠在 WebView 之上；
///  - scan.qrcode 先确保相机权限，再弹 AVFoundation 扫码页。
final class ViewController: UIViewController {

    private var webView: WKWebView!
    private var channel: JsChannel!
    private(set) var router: BridgeRouter!
    private let permissionBridge = PermissionBridge()
    private let scan = ScanBridge()
    private var schemeHandler: WebAppSchemeHandler!
    /// 主帧加载失败自动重试计数（防偶发导航失败直接白屏/错误页；限 2 次避免死循环）
    private var reloadAttempts = 0

    /// WebView 下层，bannerLayer 上层承载悬浮横幅；splashLayer 最顶层默认隐藏
    let bannerContainer = UIView()
    let splashContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // 1) 先装配 configuration：scheme handler / shim 必须在 WKWebView 初始化前设置
        schemeHandler = WebAppSchemeHandler()
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(schemeHandler, forURLScheme: WebAppSchemeHandler.scheme)
        config.userContentController.addUserScript(
            WKUserScript(source: BridgeShim.source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        )
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // 2) 创建 WebView（此后 configuration.userContentController 仍可动态增删 message handler）
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.uiDelegate = self
        webView.navigationDelegate = self

        // 3) 打通 channel -> router -> messageHandler（router 需持有 webView 引用回传 JS）
        channel = JsChannel(webView: webView)
        router = BridgeRouter(viewController: self, channel: channel, permission: permissionBridge)
        config.userContentController.add(router, name: BridgeRouter.messageHandlerName)

        #if DEBUG
        // 调试包允许 Safari 远程审查 H5；正式包不启用，避免篡改 JS 桥。
        if #available(iOS 16.4, *) { webView.isInspectable = true }
        #endif

        // 4) 视图层级：webView -> bannerContainer -> splashContainer
        view.addSubview(webView)
        bannerContainer.frame = view.bounds
        bannerContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bannerContainer.isUserInteractionEnabled = false // 空白区穿透到 WebView
        view.addSubview(bannerContainer)
        splashContainer.frame = view.bounds
        splashContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        splashContainer.isUserInteractionEnabled = true
        splashContainer.isHidden = true
        view.addSubview(splashContainer)

        webView.load(URLRequest(url: WebAppSchemeHandler.startURL))
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
    }

    deinit {
        router?.dispose()
        channel?.webView?.configuration.userContentController.removeScriptMessageHandler(forName: BridgeRouter.messageHandlerName)
    }

    // MARK: - 供 AdBridge 使用（对齐 Android attachBannerView / getSplashLayer）

    /// 把横幅视图加到悬浮层（按传入 frame，pt 单位）
    func attachBannerView(_ v: UIView, frame: CGRect) {
        v.removeFromSuperview()
        v.frame = frame
        bannerContainer.addSubview(v)
        bannerContainer.isUserInteractionEnabled = true
    }

    func detachBannerView(_ v: UIView) {
        v.removeFromSuperview()
        if bannerContainer.subviews.isEmpty { bannerContainer.isUserInteractionEnabled = false }
    }

    /// 开屏容器（展示期由广告模块填充并 isHidden=false）
    var splashLayer: UIView { splashContainer }

    // MARK: - 扫码（scan.qrcode）

    func requestScan(callbackId: String) {
        permissionBridge.ensure("android.permission.CAMERA") { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                self.channel.resolveErr(callbackId, "缺少相机权限")
                return
            }
            self.scan.present(from: self) { [weak self] result in
                switch result {
                case .success(let text):
                    self?.channel.resolveOk(callbackId, ["result": text, "scanType": "qrCode"])
                case .cancelled:
                    self?.channel.resolveErr(callbackId, "scan cancelled")
                }
            }
        }
    }

    // MARK: - 供 UpdateBridge / 其他使用

    func topViewController() -> UIViewController { self }

    func openURL(_ url: URL) -> Bool { UIApplication.shared.canOpenURL(url) && { UIApplication.shared.open(url); return true }() }
}

// MARK: - WKUIDelegate（target=_blank / JS 弹窗）

extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // H5 window.open：在原 WebView 加载
        if let url = navigationAction.request.url { webView.load(URLRequest(url: url)) }
        return nil
    }
}

// MARK: - WKNavigationDelegate（外链交由系统处理，其余留在壳内）

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == WebAppSchemeHandler.scheme || scheme == "about" {
            decisionHandler(.allow)
        } else if scheme == "http" || scheme == "https" {
            // H5 内点击的外链（如隐私政策）在壳内 WebView 直接加载
            decisionHandler(.allow)
        } else {
            // 其它 scheme（tel/mailto/自定义）交系统
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        }
    }

    // 主帧加载失败（含 scheme handler 异常/导航被中断）：限次自动重载起点页，避免用户/审核员面对错误页
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        retryLoadOnce()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        retryLoadOnce()
    }

    private func retryLoadOnce() {
        guard reloadAttempts < 2 else { return }
        reloadAttempts += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.webView.load(URLRequest(url: WebAppSchemeHandler.startURL))
        }
    }
}
