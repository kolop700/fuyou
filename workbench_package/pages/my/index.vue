<template>
  <view class="page-container">
    <!-- 菜单列表 -->
    <view class="cu-list menu">
      <view class="menu-item" @tap="handleUpdateProfile">
        <view class="content">
          <text>修改用户资料</text>
        </view>
        <view class="right-icon">
          <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
        </view>
      </view>
      
      <view class="menu-item" @tap="handleRefreshDevices">
        <view class="content">
          <text>刷新设备权限资料</text>
        </view>
        <view class="right-icon">
          <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
        </view>
      </view>

      <!-- 添加权限详情选项 -->
      <view class="menu-item" @tap="handleOpenAppSettings">
        <view class="content">
          <text>应用权限详情</text>
        </view>
        <view class="right-icon">
          <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
        </view>
      </view>

      <!-- 绑定微信选项 
      <view class="menu-item" @tap="handleBindWechat">
        <view class="content">
          <text>绑定微信视频通话授权</text>
        </view>
        <view class="right-icon">
          <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
        </view>
      </view>
      -->
            <!-- 管理员入口
      <view 
        v-if="isAdmin" 
        class="menu-item"
        @tap="handleAdminLogin"
      >
        <view class="content">
          <text>管理员登录</text>
        </view>
        <view class="right-icon">
          <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
        </view>
      </view>
       -->

      <!-- 网页全屏预览选项 
      <view class="menu-item" @tap="handleWebviewPreview">
        <view class="content">
          <text>网页全屏预览</text>
        </view>
        <view class="right-icon">
          <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
        </view>
      </view>
      -->

      <!-- 关于我们选项 -->
      <view class="menu-item" @tap="handleAbout">
        <view class="content">
          <text>关于我们</text>
        </view>
        <view class="right-icon">
          <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
        </view>
      </view>

      <!-- 摄像头选项
      <view class="menu-item" @tap="handleCamera">
        <view class="content">
          <text>摄像头</text>
        </view>
        <view class="right-icon">
          <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
        </view>
      </view>
	-->
    </view>
    
    <!-- 底部横幅广告（Taku） -->
    <view class="ad-section" v-if="bannerAdId">
      <view class="ad-divider"></view>
      <view class="ad-view">
        <taku-banner :placement-id="bannerAdId"></taku-banner>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onMounted } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { storeToRefs } from 'pinia'
import { encrypt, decrypt } from '@/utils/aesUtils'
import userApi from '@/api/user/user'
// #ifdef H5
import { isNativeShell, NativeApp } from '@/utils/h5-native-bridge'
// #endif

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const adStore = proxy.$store.ad.useAdStore()
const { userType } = storeToRefs(userStore)

// 横幅广告位 ID（Taku placementId，空/全关时不展示；随开关自动响应更新）
const bannerAdId = computed(() => adStore.getBannerAdId())
const isAdmin = ref(false) // 是否是管理员

// 平台判断
const platform = ref('')

// 初始化版本号
const initVersion = () => {
  // #ifdef APP-PLUS
  appVersion.value = plus.runtime.version
  // #endif

  // #ifdef H5
  // 原生壳：H5 环境无 plus.runtime，经 device.getInfo 桥取真实应用版本（老整包行为对齐）
  if (isNativeShell) {
    NativeApp.getInfo().then((d) => {
      if (d && d.version) appVersion.value = d.version
    }).catch(() => {})
  }
  // #endif
  
  // #ifdef MP-WEIXIN
  const accountInfo = uni.getAccountInfoSync()
  appVersion.value = accountInfo.miniProgram.version
  // #endif
  
  // 如果以上都不匹配，设置默认版本
  if (!appVersion.value) {
    const systemInfo = uni.getSystemInfoSync()
    appVersion.value = systemInfo.appVersion || '1.0.0'
  }
}

// 检查管理员权限
const checkAdminStatus = async () => {
  try {
    // #ifdef MP-WEIXIN
    // 获取用户信息
    const userInfo = uni.getStorageSync('userInfo')
    if (!userInfo) {
      console.log('未获取到用户信息')
      isAdmin.value = false
      return
    }
    
    const res = await userApi.getUserStatus(userInfo.user_id)
    isAdmin.value = res.data && res.data.length > 0
    console.log('管理员权限检查结果:', isAdmin.value)
    // #endif
    
    // #ifdef APP-PLUS
    const resApp = await userApi.getUserStatus(userStore.userId)
    isAdmin.value = resApp.data && resApp.data.length > 0
    console.log('管理员权限检查结果:', isAdmin.value)
    // #endif
  } catch (error) {
    console.error('检查管理员权限失败:', error)
    isAdmin.value = false
  }
}

onMounted(() => {
  initVersion() // 初始化版本号
  // 获取平台信息
  const systemInfo = uni.getSystemInfoSync()
  platform.value = systemInfo.platform.toLowerCase()
  checkAdminStatus()
})

// 修改用户资料
const handleUpdateProfile = () => {
  uni.navigateTo({
    url: '/user_package/pages/profile/index'
  })
}

// 刷新设备权限
const handleRefreshDevices = async () => {
  try {
    await userStore.login()
    uni.showToast({
      title: '刷新成功',
      icon: 'success'
    })
  } catch (error) {
    uni.showToast({
      title: '刷新失败',
      icon: 'none'
    })
  }
}

// 使用帮助
const handleHelp = () => {
  uni.navigateTo({
    url: '/deviceMode/pages/help/help'
  })
}

// 管理员登录
const handleAdminLogin = () => {
  // #ifdef MP-WEIXIN
  uni.navigateTo({
    url: '/manageModule/pages/adminLogin/adminLogin'
  })
  // #endif

  // #ifdef H5
  // 原生壳：经 miniprogram.launch 桥由微信 OpenSDK 拉起管理小程序（与 APP-PLUS 分支同目标）
  if (isNativeShell) {
    NativeApp.launchMiniProgram({
      appId: 'wx8ea71b7e50187f1d',
      userName: 'gh_1329871b16ba',
      path: 'manageModule/pages/adminLogin/adminLogin?fromApp=1',
      type: 0
    }).catch(() => {
      uni.showToast({ title: '拉起微信小程序失败', icon: 'none' })
    })
  }
  // #endif

  // #ifdef APP-PLUS
  plus.share.getServices(
    (services) => {
      console.log('获取到的服务列表：', services)
      const weixinService = services.find(item => item.id === "weixin")
      if (weixinService) {
        console.log('找到微信服务，准备打开小程序')
        weixinService.launchMiniProgram({
          id: "gh_1329871b16ba",  // 微信小程序原始 ID
          path: `manageModule/pages/adminLogin/adminLogin?fromApp=1`, // 小程序页面路径，添加fromApp标识
          type: 0,          // 0-正式版；1-测试版；2-体验版
        })
      } else {
        console.log('未找到微信服务')
        uni.showToast({
          title: '请安装微信',
          icon: 'none'
        })
      }
    },
    (error) => {
      console.error('获取服务失败:', error)
      uni.showToast({
        title: '获取微信服务失败',
        icon: 'none'
      })
    }
  )
  // #endif
}

// 处理绑定微信
const handleBindWechat = () => {
  console.log('点击绑定微信按钮')
  
  // #ifdef MP-WEIXIN
  uni.showModal({
    title: '提示',
    content: '您当前已在微信小程序中，无需绑定',
    showCancel: false
  })
  // #endif
  
  // #ifdef H5
  // 原生壳：复用 APP-PLUS 分支的加密对账流程，经 miniprogram.launch 拉起绑定小程序
  if (isNativeShell) {
    uni.showModal({
      title: '绑定微信',
      content: '是否跳转到微信小程序进行绑定？',
      success: (res) => {
        if (!res.confirm) return
        const originalData = {
          account: userStore.userAcct,
          password: userStore.userPassword,
          timestamp: Date.now()
        }
        const encryptedAccount = encrypt(originalData.account)
        const encryptedPassword = encrypt(originalData.password)
        if (!encryptedAccount || !encryptedPassword) {
          uni.showToast({ title: '数据加密失败', icon: 'none' })
          return
        }
        const query = `account=${encodeURIComponent(encryptedAccount)}&password=${encodeURIComponent(encryptedPassword)}&timestamp=${originalData.timestamp}`
        NativeApp.launchMiniProgram({
          appId: 'wx8ea71b7e50187f1d',
          userName: 'gh_1329871b16ba',
          path: `pages/voipbind/voipbind?${query}`,
          type: 0
        }).catch(() => {
          uni.showToast({ title: '拉起微信小程序失败', icon: 'none' })
        })
      }
    })
    return
  }
  // #endif

  // #ifdef APP-PLUS
  console.log('当前用户信息：', {
    account: userStore.userAcct,
    password: userStore.userPassword
  })
  
  uni.showModal({
    title: '绑定微信',
    content: '是否跳转到微信小程序进行绑定？',
    success: (res) => {
      if (res.confirm) {
        console.log('用户确认跳转')
        
        // 加密前的原始数据
        const originalData = {
          account: userStore.userAcct,
          password: userStore.userPassword,
          timestamp: Date.now()
        }
        
        // 对数据进行加密
        const encryptedAccount = encrypt(originalData.account)
        const encryptedPassword = encrypt(originalData.password)
        
        // 检查加密是否成功
        if (!encryptedAccount || !encryptedPassword) {
          uni.showToast({
            title: '数据加密失败',
            icon: 'none'
          })
          return
        }
        
        // 构建加密后的查询参数
        const query = `account=${encodeURIComponent(encryptedAccount)}&password=${encodeURIComponent(encryptedPassword)}&timestamp=${originalData.timestamp}`
        
        // 使用 plus.share.getServices 打开微信小程序
        plus.share.getServices(
          (services) => {
            console.log('获取到的服务列表：', services)
            const weixinService = services.find(item => item.id === "weixin")
            if (weixinService) {
              console.log('找到微信服务，准备打开小程序')
              weixinService.launchMiniProgram({
                id: "gh_1329871b16ba",  // 微信小程序原始 ID
                path: `"pages/voipbind/voipbind?${query}`, // 小程序页面路径，带参数
                type: 0,          // 0-正式版；1-测试版；2-体验版
              })
            } else {
              console.log('未找到微信服务')
              uni.showToast({
                title: '请安装微信',
                icon: 'none'
              })
            }
          },
          (error) => {
            console.error('获取服务失败:', error)
            uni.showToast({
              title: '获取微信服务失败',
              icon: 'none'
            })
          }
        )
      } else {
        console.log('用户取消跳转')
      }
    }
  })
  // #endif
}

// 打开应用权限设置
const handleOpenAppSettings = () => {
  // #ifdef APP-PLUS
  try {
    // iOS权限检查
    if (uni.getSystemInfoSync().platform === 'ios') {
      const UIApplicationClass = plus.ios.importClass("UIApplication")
      const NSURLClass = plus.ios.importClass("NSURL")
      const settingsUrl = NSURLClass.URLWithString('app-settings:')
      const application = UIApplicationClass.sharedApplication()
      application.openURL(settingsUrl)
    } else {
      // Android权限检查
      const main = plus.android.runtimeMainActivity()
      const Intent = plus.android.importClass('android.content.Intent')
      const Settings = plus.android.importClass('android.provider.Settings')
      const Uri = plus.android.importClass('android.net.Uri')
      
      const intent = new Intent()
      intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
      const uri = Uri.fromParts('package', main.getPackageName(), null)
      intent.setData(uri)
      
      main.startActivity(intent)
    }
  } catch (e) {
    console.error('打开设置失败:', e)
    uni.showToast({
      title: '打开设置失败',
      icon: 'none'
    })
  }
  // #endif

  // #ifdef H5
  // 原生壳：经 app.openSettings 桥打开本应用系统设置页
  NativeApp.openSettings().catch(() => {
    uni.showToast({ title: '打开设置失败', icon: 'none' })
  })
  // #endif
  
  // #ifdef MP-WEIXIN
  uni.showModal({
    title: '提示',
    content: '小程序环境下无法直接打开权限设置',
    showCancel: false
  })
  // #endif
}

// 打开网页全屏预览
const handleWebviewPreview = () => {
  uni.navigateTo({
    url: '/user_package/pages/webview?url=' + encodeURIComponent('https://48fe2d41.r37.cpolar.top/tg/') + '&title=网页全屏预览'
  })
}

// 在 script 部分添加 handleAbout 函数
const handleAbout = () => {
  uni.navigateTo({
    url: '/workbench_package/pages/about/index'
  })
}

// 跳转到摄像头页面
const handleCamera = () => {
  uni.navigateTo({
    url: '/pages/camera/index'
  })
}

const appVersion = ref('')

const handleVersion = () => {
  uni.showToast({
    title: `当前版本：${appVersion.value}`,
    icon: 'none'
  })
}
</script>

<style lang="scss">
page {
  background: #F5F5F5;
  height: 100vh;
}

.page-container {
  padding: 20rpx;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
}

.cu-list.menu {
  background: #FFFFFF;
  border-radius: 12rpx;
  overflow: hidden;
  margin-bottom: auto;
  
  .menu-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 32rpx 24rpx;
    position: relative;
    
    // 分割线
    &:not(:last-child)::after {
      content: '';
      position: absolute;
      left: 24rpx;
      right: 24rpx;
      bottom: 0;
      height: 1px;
      background-color: #EEEEEE;
      transform: scaleY(0.5);
    }
    
    .content {
      flex: 1;
      text {
        font-size: 28rpx;
        color: #333333;
        font-weight: 400;
      }
    }
    
    .right-icon {
      width: 32rpx;
      height: 32rpx;
      display: flex;
      align-items: center;
      justify-content: center;
      
      image {
        width: 100%;
        height: 100%;
      }
    }
  }
}

.custom-text {
  font-size: 32rpx;
  font-weight: 500;
  color: #333333;
}

.delete-text {
  color: #FF0000 !important;
}

/* ===== 底部横幅广告（Taku）：常驻页面底部 ===== */
.ad-section {
  position: fixed;
  left: 24rpx;
  right: 24rpx;
  bottom: 0;
  z-index: 20;
  box-sizing: border-box;
  background: #ffffff;
  border-radius: 24rpx 24rpx 0 0;
  box-shadow: 0 -6rpx 20rpx rgba(74, 108, 247, 0.08);

  .ad-divider {
    height: 2rpx;
    background: #EEEEEE;
  }

  .ad-view {
    display: flex;
    justify-content: center;
    align-items: center;
  }
}

.right-text {
  font-size: 28rpx;
  color: #999;
  margin-right: 10rpx;
}
</style>
