import Foundation
import UIKit

#if canImport(WechatOpenSDK)
import WechatOpenSDK
#endif
#if canImport(AlipaySDK)
import AlipaySDK
#endif

/// SDK 调起结果（与具体厂商无关的三态）
enum SDKOutcome {
    case launched          // 拉起指令已发出（结果经事件异步回传）
    case failed(String)    // 立即失败（参数错误 / 未安装 App 等）
    case notIntegrated     // 对应 SDK 未集成（工程未链接该 framework）
}

/// 支付事件载荷（对齐 h5-native-bridge pay.onEvent）
struct PayEventPayload {
    let channel: String     // wechat / alipay / iap
    let event: String       // pay.success / pay.cancel / pay.fail
    let code: Int
    let msg: String
    var extra: [String: Any] = [:]
}

/// 集中管理第三方 SDK（微信 OpenSDK / 支付宝）的对接。
///
/// 设计要点：所有厂商 API 都包在 `#if canImport(...)` 内——工程默认无 Pods 也能编译；
/// 集成对应 framework 后（见 Podfile），支付/分享/小程序自动生效，无需改动各 Bridge。
enum AppSDK {

    // ===== 与 manifest.json / Android 壳一致的微信配置 =====
    static let wechatAppId = "wx8ea71b7e50187f1d"
    static let wechatUniversalLink = "https://fuyou.yefiot.com/app/"
    static let alipayReturnScheme = "ap.yefiot.fuyou"

    /// 支付/小程序结果监听（由 PayBridge / MiniProgramBridge 设置）
    static var onPayEvent: ((PayEventPayload) -> Void)?

    // MARK: - 注册

    static func registerWechatIfNeeded() {
        #if canImport(WechatOpenSDK)
        _ = WechatHandler.shared
        WXApi.registerApp(wechatAppId, universalLink: wechatUniversalLink)
        #endif
    }

    // MARK: - URL / UniversalLink 回调

    @discardableResult
    static func handleOpen(_ url: URL) -> Bool {
        #if canImport(WechatOpenSDK)
        if url.scheme == wechatAppId {
            return WXApi.handleOpen(url, delegate: WechatHandler.shared)
        }
        #endif
        #if canImport(AlipaySDK)
        return AlipaySDK.defaultService().processOrder(withPaymentResult: url, standbyCallback: { dict in
            if let d = dict { AppSDK.deliverAlipay(d) }
        }) ?? false
        #else
        return false
        #endif
    }

    @discardableResult
    static func handleUniversalLink(_ activity: NSUserActivity) -> Bool {
        #if canImport(WechatOpenSDK)
        return WXApi.handleOpenUniversalLink(activity, delegate: WechatHandler.shared)
        #else
        return false
        #endif
    }

    // MARK: - 微信支付

    static func requestWechatPay(_ p: [String: Any]) -> SDKOutcome {
        #if canImport(WechatOpenSDK)
        guard WXApi.isWXAppInstalled() else { return .failed("未安装微信") }
        let req = PayReq()
        req.partnerId = Self.str(p["partnerid"] ?? p["partnerId"]) ?? ""
        req.prepayId = Self.str(p["prepayid"] ?? p["prepayId"]) ?? ""
        req.nonceStr = Self.str(p["noncestr"] ?? p["nonceStr"]) ?? ""
        req.package = Self.str(p["package"]) ?? "Sign=WXPay"
        req.timeStamp = UInt32(Self.str(p["timestamp"]) ?? "0") ?? 0
        req.sign = Self.str(p["sign"]) ?? ""
        req.extData = Self.str(p["extData"]) ?? ""
        return WXApi.send(req, delegate: WechatHandler.shared) ? .launched : .failed("微信下单失败")
        #else
        return .notIntegrated
        #endif
    }

    // MARK: - 微信小程序

    static func launchMiniProgram(appId: String?, userName: String?, path: String?, type: Int) -> SDKOutcome {
        #if canImport(WechatOpenSDK)
        guard WXApi.isWXAppInstalled() else { return .failed("未安装微信") }
        guard let userName = userName, !userName.isEmpty else { return .failed("缺少小程序 userName(gh_)") }
        let req = WXLaunchMiniProgramReq()
        req.userName = userName
        req.path = path ?? ""
        req.miniprogramType = WXMiniProgramType(rawValue: type) ?? .release
        return WXApi.send(req, delegate: WechatHandler.shared) ? .launched : .failed("拉起小程序失败")
        #else
        return .notIntegrated
        #endif
    }

    // MARK: - 微信分享

    /// type: text / image / webpage(miniprogram 另有专用方法)
    static func shareWechat(scene: Int, type: String, title: String?, summary: String?,
                            href: String?, imageBase64: String?) -> SDKOutcome {
        #if canImport(WechatOpenSDK)
        guard WXApi.isWXAppInstalled() else { return .failed("未安装微信") }
        let msg = WXMediaMessage()
        msg.title = title ?? ""
        msg.description = summary ?? ""

        let obj: WXMediaMessageObject
        switch type {
        case "image":
            guard let b64 = imageBase64, let data = Data(base64Encoded: b64), let image = UIImage(data: data) else {
                return .failed("图片数据无效")
            }
            let im = WXImageObject()
            im.imageData = data
            obj = im
            msg.thumbImage = Self.thumbData(from: image)
        case "webpage", "link", "news":
            let web = WXWebpageObject()
            web.webpageUrl = href ?? ""
            obj = web
            if let b64 = imageBase64, let data = Data(base64Encoded: b64), let image = UIImage(data: data) {
                msg.thumbImage = Self.thumbData(from: image)
            }
        default:
            let txt = WXTextObject()
            txt.text = summary ?? title ?? ""
            obj = txt
        }
        msg.mediaObject = obj
        if msg.mediaObject is WXTextObject { /* 文本无需 thumb */ }

        let req = SendMessageToWXReq()
        req.bText = (type != "image" && type != "webpage" && type != "link" && type != "news")
        req.text = req.bText ? (summary ?? title ?? "") : ""
        req.message = msg
        req.scene = Int32(scene)  // 0 会话 / 1 朋友圈 / 2 收藏
        return WXApi.send(req, delegate: WechatHandler.shared) ? .launched : .failed("微信分享失败")
        #else
        return .notIntegrated
        #endif
    }

    // MARK: - 支付宝支付

    static func requestAlipay(orderStr: String, completion: @escaping (SDKOutcome) -> Void) {
        #if canImport(AlipaySDK)
        guard !orderStr.isEmpty else { completion(.failed("orderStr 为空")); return }
        AlipaySDK.defaultService().payOrder(orderStr, fromScheme: alipayReturnScheme) { dict in
            AppSDK.deliverAlipay(dict)
            completion(.launched)
        }
        #else
        completion(.notIntegrated)
        #endif
    }

    /// 解析支付宝结果字典并转为统一支付事件
    static func deliverAlipay(_ dict: [AnyHashable: Any]) {
        let status = (dict["resultStatus"] as? String)
            ?? ((dict as? [String: Any])?["resultStatus"] as? String) ?? ""
        var event = "pay.fail"
        switch status {
        case "9000": event = "pay.success"
        case "6001": event = "pay.cancel"
        case "6002": event = "pay.fail"
        default: event = "pay.fail"
        }
        let memo = (dict["memo"] as? String) ?? ""
        onPayEvent?(PayEventPayload(channel: "alipay", event: event,
                                    code: Int(status) ?? -1, msg: memo.isEmpty ? "alipay \(status)" : memo))
    }

    // MARK: - 工具

    private static func str(_ v: Any?) -> String? {
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        return nil
    }

    #if canImport(WechatOpenSDK)
    private static func thumbData(from image: UIImage) -> Data? {
        let maxSide: CGFloat = 120
        let scale = min(1.0, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumb = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumb?.pngData()
    }
    #endif
}

// MARK: - 微信回调代理（响应分发）

#if canImport(WechatOpenSDK)
/// WXApiDelegate 实现：把微信返回的 BaseResp 映射为统一支付事件。
final class WechatHandler: NSObject, WXApiDelegate {

    static let shared = WechatHandler()

    func onResp(_ resp: BaseResp) {
        if resp is PayResp {
            let r = resp as! PayResp
            var event = "pay.fail"
            switch r.errCode {
            case 0: event = "pay.success"
            case Int(WXErrorCode.userCancel.rawValue): event = "pay.cancel"
            default: event = "pay.fail"
            }
            AppSDK.onPayEvent?(PayEventPayload(channel: "wechat", event: event,
                                               code: r.errCode, msg: r.errStr ?? ""))
        } else if resp is WXLaunchMiniProgramResp {
            // 小程序返回：业务侧如需可从此读取 extMsg；当前无需回传
        }
    }
}
#endif
