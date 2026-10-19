import UIKit

/// 分享桥（share.*）——对齐 shell-android ShareManager（Android 用系统 Intent 定向微信，
/// iOS 经微信 OpenSDK SendMessageToWXReq；未集成 SDK 时返回明确错误）。
///
///   share.wechat {provider, scene, type, imageUrl, imageBase64, imageMimeType, title, summary, href}
final class ShareBridge: BridgeModule {

    private weak var viewController: ViewController?
    private let channel: JsChannel

    init(viewController: ViewController, channel: JsChannel) {
        self.viewController = viewController
        self.channel = channel
    }

    func handle(_ method: String, _ params: [String: Any], _ callbackId: String) -> Bool {
        guard method.hasPrefix("share.") else { return false }
        // scene: 0 会话 / 1 朋友圈 / 2 收藏
        let scene = (params["scene"] as? NSNumber)?.intValue ?? 0
        let imageBase64 = (params["imageBase64"] as? String) ?? ""
        let href = (params["href"] as? String) ?? ""
        let title = (params["title"] as? String) ?? ""
        let summary = (params["summary"] as? String) ?? ""

        // 依内容推断类型（优先图片，其次网页链接，最后纯文本）
        let kind: String
        if !imageBase64.isEmpty {
            kind = "image"
        } else if !href.isEmpty {
            kind = "webpage"
        } else {
            kind = "text"
        }

        switch AppSDK.shareWechat(scene: scene, type: kind, title: title.isEmpty ? nil : title,
                                  summary: summary.isEmpty ? nil : summary,
                                  href: href.isEmpty ? nil : href,
                                  imageBase64: imageBase64.isEmpty ? nil : imageBase64) {
        case .launched: channel.resolveOk(callbackId)
        case .failed(let m): channel.resolveErr(callbackId, m)
        case .notIntegrated: channel.resolveErr(callbackId, "未集成微信分享 SDK")
        }
        return true
    }
}
