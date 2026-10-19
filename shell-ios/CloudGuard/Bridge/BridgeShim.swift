import Foundation

/// 注入到 WKWebView 的 JS 桥 shim。
///
/// Android 用 @JavascriptInterface 直接暴露 window.NativeBridge；iOS WKWebView 只能通过
/// window.webkit.messageHandlers.xxx.postMessage 通信，故此处以 WKUserScript 注入一段 shim，
/// 把 NativeBridge.call(method, paramsJson, callbackId) 转发给原生 messageHandler，
/// 从而复用前端 utils/h5-native-bridge.js（其协议对双端一致），无需改动任何 H5 代码。
enum BridgeShim {

    /// documentStart 注入，确保早于页面脚本执行（h5-native-bridge.js 在加载期即读取 window.NativeBridge）
    static var source: String {
        return """
        (function () {
          if (window.NativeBridge) { return; }
          var bridge = {
            call: function (method, paramsJson, callbackId) {
              try {
                window.webkit.messageHandlers.NativeBridge.postMessage({
                  method: String(method),
                  params: (paramsJson == null) ? '{}' : String(paramsJson),
                  callbackId: String(callbackId)
                });
              } catch (e) {
                console.error('[NativeBridge] postMessage failed', e);
              }
            }
          };
          try {
            Object.defineProperty(window, 'NativeBridge', {
              value: bridge, enumerable: true, configurable: false, writable: false
            });
          } catch (e) {
            window.NativeBridge = bridge;
          }
        })();
        """
    }
}
