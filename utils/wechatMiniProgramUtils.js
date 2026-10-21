import { encrypt } from '@/utils/aesUtils'
// #ifdef H5
import { isNativeShell, NativeApp } from '@/utils/h5-native-bridge'
// #endif

// 福优智家微信开放平台移动应用 AppId（拉起小程序调用方标识，与壳内微信 SDK 配置一致）
const WX_APP_ID = 'wx8ea71b7e50187f1d'
// 福优智家小程序 AppID: wxe83614305a9d58f2
// App 端 launchMiniProgram 需要使用原始 ID。
const MINI_PROGRAM_ORIGINAL_ID = 'gh_f502cf522c81'
const MINI_PROGRAM_TYPE = 0

const showUnsupportedToast = () => {
  uni.showToast({
    title: '请在App中打开',
    icon: 'none'
  })
}

const launchMiniProgram = (path) => {
  // #ifdef MP-WEIXIN
  uni.showModal({
    title: '提示',
    content: '您当前已在微信小程序中，无需跳转',
    showCancel: false
  })
  return
  // #endif

  // #ifdef APP-PLUS
  plus.share.getServices(
    (services) => {
      const weixinService = services.find(item => item.id === 'weixin')
      if (!weixinService) {
        uni.showToast({
          title: '请安装微信',
          icon: 'none'
        })
        return
      }

      weixinService.launchMiniProgram({
        id: MINI_PROGRAM_ORIGINAL_ID,
        path,
        type: MINI_PROGRAM_TYPE
      })
    },
    (error) => {
      console.error('获取微信服务失败:', error)
      uni.showToast({
        title: '获取微信服务失败',
        icon: 'none'
      })
    }
  )
  return
  // #endif

  // #ifdef H5
  // 原生壳：经 miniprogram.launch 桥由微信 OpenSDK 拉起（与 APP-PLUS 分支同目标小程序）
  if (isNativeShell) {
    NativeApp.launchMiniProgram({
      appId: WX_APP_ID,
      userName: MINI_PROGRAM_ORIGINAL_ID,
      path,
      type: MINI_PROGRAM_TYPE
    }).catch(() => {
      uni.showToast({ title: '拉起微信小程序失败', icon: 'none' })
    })
    return
  }
  // #endif

  showUnsupportedToast()
}

export const openWechatCallBind = (userStore) => {
  const account = userStore?.userAcct || ''
  const password = userStore?.userPassword || ''

  if (!account || !password) {
    uni.showToast({
      title: '请先登录',
      icon: 'none'
    })
    return
  }

  const encryptedAccount = encrypt(account)
  const encryptedPassword = encrypt(password)

  if (!encryptedAccount || !encryptedPassword) {
    uni.showToast({
      title: '数据加密失败',
      icon: 'none'
    })
    return
  }

  const query = `account=${encodeURIComponent(encryptedAccount)}&password=${encodeURIComponent(encryptedPassword)}&timestamp=${Date.now()}`
  launchMiniProgram(`pages/voip/bind?${query}`)
}

export const openWechatAdminLogin = () => {
  launchMiniProgram('manageModule/pages/adminLogin/adminLogin?fromApp=1')
}
