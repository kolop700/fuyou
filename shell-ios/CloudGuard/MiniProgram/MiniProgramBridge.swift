import UIKit

/// 小程序桥（miniprogram.*）——对齐 shell-android MiniProgramBridge。
///
///   miniprogram.launch {appId, userName(gh_xxx), path, type(0 正式/1 开发/2 体验)}
///   iOS 经微信 OpenSDK WXLaunchMiniProgramReq；前置：微信开放平台移动应用与目标小程序同账号绑定。
final class MiniProgramBridge: BridgeModule {

    private weak var viewController: ViewController?
    private let channel: JsChannel

    init(viewController: ViewController, channel: JsChannel) {
        self.viewController = viewController
        self.channel = channel
    }

    func handle(_ method: String, _ params: [String: Any], _ callbackId: String) -> Bool {
        guard method == "miniprogram.launch" else { return false }
        let appId = params["appId"] as? String
        let userName = params["userName"] as? String
        let path = params["path"] as? String
        let type = (params["type"] as? NSNumber)?.intValue ?? 0

        switch AppSDK.launchMiniProgram(appId: appId, userName: userName, path: path, type: type) {
        case .launched: channel.resolveOk(callbackId)
        case .failed(let m): channel.resolveErr(callbackId, m)
        case .notIntegrated: channel.resolveErr(callbackId, "未集成微信小程序 SDK")
        }
        return true
    }
}
