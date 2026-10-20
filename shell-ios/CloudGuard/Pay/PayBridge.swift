import Foundation
import StoreKit

/// 支付桥（pay.*）——对齐 shell-android PayBridge。
///
///   pay.wechat {appid,prepayid,sign,partnerid,package,noncestr,timestamp}  -> 微信（需集成 OpenSDK）
///   pay.alipay {orderStr}                                                  -> 支付宝（需集成 AlipaySDK）
///   pay.iap   {productId, orderNo}                                         -> 苹果内购（StoreKit，系统框架，无需 SDK）
///
/// 事件：pay.onEvent {channel, event:'pay.success'|'pay.cancel'|'pay.fail', code, msg, receipt?, transactionId?}
/// resolveOk 语义 = 拉起指令已发出；VIP 订单最终状态以后端 queryVipOrder 为准。
final class PayBridge: NSObject, BridgeModule, SKPaymentTransactionObserver {

    private weak var viewController: ViewController?
    private let channel: JsChannel

    /// productId -> orderNo / callbackId
    private var iapOrder: [String: String] = [:]
    private var iapCallbacks: [String: String] = [:]

    init(viewController: ViewController, channel: JsChannel) {
        self.viewController = viewController
        self.channel = channel
        super.init()
        // 微信/支付宝结果 -> 统一事件
        AppSDK.onPayEvent = { [weak self] payload in
            var data: [String: Any] = [
                "channel": payload.channel, "event": payload.event,
                "code": payload.code, "msg": payload.msg
            ]
            payload.extra.forEach { data[$0.key] = $0.value }
            self?.channel.emit("pay.onEvent", data: data)
        }
        SKPaymentQueue.default().add(self)
    }

    func handle(_ method: String, _ params: [String: Any], _ callbackId: String) -> Bool {
        switch method {
        case "pay.wechat": requestWechat(params, callbackId)
        case "pay.alipay": requestAlipay(params, callbackId)
        case "pay.iap": requestIap(params, callbackId)
        default: return false
        }
        return true
    }

    // MARK: - 微信

    private func requestWechat(_ params: [String: Any], _ callbackId: String) {
        switch AppSDK.requestWechatPay(params) {
        case .launched: channel.resolveOk(callbackId)
        case .failed(let m): channel.resolveErr(callbackId, m)
        case .notIntegrated: channel.resolveErr(callbackId, "未集成微信支付 SDK")
        }
    }

    // MARK: - 支付宝

    private func requestAlipay(_ params: [String: Any], _ callbackId: String) {
        let orderStr = (params["orderStr"] as? String) ?? ""
        AppSDK.requestAlipay(orderStr: orderStr) { outcome in
            DispatchQueue.main.async {
                switch outcome {
                case .launched: self.channel.resolveOk(callbackId)
                case .failed(let m): self.channel.resolveErr(callbackId, m)
                case .notIntegrated: self.channel.resolveErr(callbackId, "未集成支付宝 SDK")
                }
            }
        }
    }

    // MARK: - 苹果内购（StoreKit）

    private func requestIap(_ params: [String: Any], _ callbackId: String) {
        guard let productId = (params["productId"] as? String), !productId.isEmpty else {
            channel.resolveErr(callbackId, "productId 为空"); return
        }
        let orderNo = (params["orderNo"] as? String) ?? ""
        iapOrder[productId] = orderNo
        iapCallbacks[productId] = callbackId

        guard SKPaymentQueue.canMakePayments() else {
            iapCallbacks.removeValue(forKey: productId)
            emitIap(orderNo: orderNo, event: "pay.fail", code: -1, msg: "设备不支持内购")
            channel.resolveErr(callbackId, "设备不支持内购"); return
        }

        let productRequest = SKProductsRequest(productIdentifiers: [productId])
        // 用独立 UUID 作登记表键值：避免初始化闭包内引用尚未声明完成的 handler 自身（capture before declared）
        let token = UUID()
        let handler = ProductsHandler(productId: productId) { [weak self] ok, errMsg in
            guard let self = self else { return }
            if ok {
                self.beginPayment(productId)
            } else {
                self.iapCallbacks.removeValue(forKey: productId)
                self.channel.resolveErr(callbackId, errMsg ?? "商品查询失败")
            }
            self.productsHandlers.removeValue(forKey: token)
        }
        productsHandlers[token] = handler
        handler.productRequest = productRequest
        productRequest.delegate = handler
        productRequest.start()
    }

    private var productsHandlers: [UUID: ProductsHandler] = [:]

    /// 商品校验通过后：回传「拉起已发出」并加入支付队列
    private func beginPayment(_ productId: String) {
        let cb = iapCallbacks.removeValue(forKey: productId)
        channel.resolveOk(cb)
        let payment = SKMutablePayment()
        payment.productIdentifier = productId
        payment.applicationUsername = iapOrder[productId] ?? ""
        SKPaymentQueue.default().add(payment)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for tx in transactions {
            let pid = tx.payment.productIdentifier
            let orderNo = iapOrder[pid] ?? tx.payment.applicationUsername ?? ""
            switch tx.transactionState {
            case .purchasing, .deferred:
                break
            case .purchased, .failed, .restored:
                if case .purchased = tx.transactionState {
                    let receipt = Self.receiptBase64()
                    emitIap(orderNo: orderNo, event: "pay.success", code: 0, msg: "ok",
                            extra: ["transactionId": tx.transactionIdentifier ?? "",
                                    "receipt": receipt,
                                    "productId": pid])
                    queue.finishTransaction(tx)
                } else if case .failed = tx.transactionState {
                    let e = tx.error as NSError?
                    let cancel = e?.code == SKError.paymentCancelled.rawValue
                    emitIap(orderNo: orderNo, event: cancel ? "pay.cancel" : "pay.fail",
                            code: e?.code ?? -1, msg: e?.localizedDescription ?? "fail")
                    queue.finishTransaction(tx)
                } else {
                    queue.finishTransaction(tx)
                }
            @unknown default:
                break
            }
        }
    }

    private func emitIap(orderNo: String, event: String, code: Int, msg: String, extra: [String: Any] = [:]) {
        var data: [String: Any] = ["channel": "iap", "event": event, "code": code, "msg": msg, "orderNo": orderNo]
        extra.forEach { data[$0.key] = $0.value }
        channel.emit("pay.onEvent", data: data)
    }

    private static func receiptBase64() -> String {
        guard let url = Bundle.main.appStoreReceiptURL, let d = try? Data(contentsOf: url) else { return "" }
        return d.base64EncodedString()
    }
}

// MARK: - 商品查询持有者

/// SKProductsRequest 代理：校验商品是否存在，结果经 completion 回调后自释放。
private final class ProductsHandler: NSObject, SKProductsRequestDelegate {
    let productId: String
    let completion: (Bool, String?) -> Void
    var productRequest: SKProductsRequest?

    init(productId: String, completion: @escaping (Bool, String?) -> Void) {
        self.productId = productId
        self.completion = completion
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let found = response.products.contains(where: { $0.productIdentifier == productId })
        completion(found, found ? nil : "商品不存在: \(productId)")
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        completion(false, "商品查询失败: \(error.localizedDescription)")
    }
}
