【Android 支付 SDK 放置说明】
=====================================================================
编译前置条件：本目录（app/libs/）必须放入以下两个 aar，否则
PayBridge.kt / WXEntryActivity.kt 会因缺少 SDK 类而编译失败。
gradle 已通过 fileTree(dir:'libs', include:['*.aar','*.jar']) 自动加载。

1) 微信 OpenSDK（支付 + 后续分享）
   - 下载地址（官方）：
     https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/Android.html
     下载页选择 Android 资源 → 下载最新版 OpenSDK（含 aar 与 demo）
   - 将 aar 重命名为：wechat-sdk-android.aar
   - 建议版本：6.8.x（与微信开放平台移动应用配套）

2) 支付宝 SDK
   - 下载地址（官方）：
     https://opendocs.alipay.com/open/02np8p
     （App 支付 SDK 下载页，产物形如 alipaySdk-15.8.xx-日期.aar）
   - 保持原名放入即可（alipaySdk-15.8.x.aar），单 aar 无额外依赖
   - 建议版本：15.8.11 及以上

【配套配置检查清单】（微信支付）
   a. 微信开放平台（open.weixin.qq.com）创建「移动应用」：
      - 包名：com.yefiot.fuyou
      - 应用签名：release 签名（与 shell-android/keystore.properties 中的 keystore 一致）
      - 移动应用审核通过后关联福优智家微信支付商户号
   b. 微信商户平台（pay.weixin.qq.com）：产品中心 → 开通「APP 支付」
   c. 将移动应用 AppId（wx8ea71b7e50187f1d）填入福优智家后端下单配置：
      支付单由后端下发给 H5，壳经 pay.wechat 桥取 orderInfo.appid（壳内不硬编码）

【配套配置检查清单】（支付宝，如福优智家启用）
   a. 支付宝开放平台（open.alipay.com）创建「移动应用」并签约「APP 支付」
   b. 生成 RSA2 密钥对：应用私钥填入福优智家后端支付宝支付配置
   c. 支付宝公钥填入后端配置
      （是「支付宝公钥」，不是应用公钥；用于回调验签）
   d. 应用 AppId 填入后端配置
