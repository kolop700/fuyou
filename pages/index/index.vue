<template>
  <view class="page-container" :class="{ 'dark-mode': themeStore.isDark() }">
    <view class="ambient-bg"></view>
    <!-- 自定义导航栏 -->
    <custom-navbar title="福优智家" :transparent="true" />
    
    <!-- 内容区域 -->
    <scroll-view class="app-content" scroll-y :style="{ paddingTop: navbarHeight + 'px' }">
      <!-- Header -->
      <view class="header-section">
        <view class="header-top">
          <view class="header-left">
            <text class="app-title">福优智家</text>
            <text class="app-subtitle">智能守护，安心生活</text>
          </view>
        </view>
      </view>

      <!-- 无房屋和设备的空状态 -->
      <view v-if="!hasRoom && !hasDevice" class="empty-state">
        <view class="empty-icon-wrapper">
          <text class="iconfont icon-fa-home" style="color: #fff; font-size: 80rpx;"></text>
        </view>
        <text class="empty-title">欢迎使用福优智家</text>
        <text class="empty-desc">您还未认证房屋<br>认证后即可使用智能门禁服务</text>
        
        <view class="empty-btn-wrapper">
          <view class="empty-btn" @click="handleCertification">
            <text class="iconfont icon-plus" style="margin-right: 16rpx; font-size: 32rpx;"></text>
            认证房屋
          </view>
        </view>

        <!-- 认证步骤 - 只在没有房屋记录时显示 -->
        <view v-if="!hasRoom" class="steps-guide">
          <text class="steps-title">认证步骤：</text>
          <view class="step-item">
            <view class="step-number">1</view>
            <text class="step-text">前往"房屋"页面</text>
          </view>
          <view class="step-item">
            <view class="step-number">2</view>
            <text class="step-text">点击"房屋认证"</text>
          </view>
          <view class="step-item">
            <view class="step-number">3</view>
            <text class="step-text">输入小区信息完成绑定</text>
          </view>
        </view>
      </view>

      <!-- 有设备时显示的内容 -->
      <view v-else>
        <!-- 常用设备 -->
        <view class="section common-device-section">
          <view class="section-header-row">
            <text class="section-title">常用设备</text>
            <view class="section-action" @tap="handleAllDevices">
              <text>全部</text>
              <text class="iconfont icon-fasfa-chevron-rightCopy"></text>
            </view>
          </view>
          
          <view class="device-carousel-wrapper">
            <swiper 
              class="device-main-display"
              :current="currentIndex"
              @change="handleSwiperChange"
              :circular="carouselList.length > 1"
              :indicator-dots="false"
              :autoplay="false"
              :duration="260"
              previous-margin="28rpx"
              next-margin="28rpx"
            >
              <swiper-item v-for="(device, index) in carouselList" :key="device.door_mac || device.door_id || index">
                <view
                  class="home-device-card"
                  :class="{
                    'home-device-card-all': device.isAllDevices,
                    'home-device-card-offline': !device.isAllDevices && !device.isOnline
                  }"
                >
                  <view class="home-card-glow"></view>
                  <view class="home-device-header">
                    <view
                      class="home-device-icon"
                      :class="{
                        'home-device-icon-all': device.isAllDevices,
                        'home-device-icon-offline': !device.isAllDevices && !device.isOnline
                      }"
                    >
                      <text
                        class="iconfont"
                        :class="device.isAllDevices ? 'icon-door-open' : 'icon-door-closed'"
                      ></text>
                    </view>

                    <view class="home-device-info">
                      <text class="home-device-title">{{ device.name }}</text>
                      <text class="home-device-location">{{ device.location }}</text>
                    </view>

                    <view
                      v-if="!device.isAllDevices"
                      class="home-status-chip"
                      :class="device.isOnline ? 'home-status-online' : 'home-status-offline'"
                    >
                      <view class="home-status-dot"></view>
                      <text>{{ device.statusDetail }}</text>
                    </view>
                  </view>

                  <view class="home-device-body">
                    <text class="home-device-desc">
                      {{ device.isAllDevices ? '查看和管理全部门禁设备' : device.isOnline ? '设备在线，可以远程开门' : '设备离线，可查看离线密码' }}
                    </text>
                    <view
                      class="home-open-button"
                      :class="{
                        'home-open-button-all': device.isAllDevices,
                        'home-open-button-offline': !device.isAllDevices && !device.isOnline
                      }"
                      @tap.stop="handleDeviceAction(device)"
                    >
                      <text
                        class="iconfont"
                        :class="device.isAllDevices ? 'icon-door-open' : device.isOnline ? 'icon-door-closed' : 'icon-fa-key'"
                      ></text>
                      <text>{{ device.isAllDevices ? '查看全部' : device.isOnline ? '一键开门' : '查看离线密码' }}</text>
                    </view>
                  </view>
                </view>
              </swiper-item>
            </swiper>

            <view v-if="carouselList.length > 1" class="carousel-dots">
              <view
                v-for="(device, index) in carouselList"
                :key="device.door_mac || device.door_id || index"
                class="carousel-dot"
                :class="{ active: currentIndex === index }"
                @tap="setCarouselIndex(index)"
              ></view>
            </view>
          </view>
        </view>

        <!-- 快捷功能区 -->
        <view class="section">
          <text class="section-title">快捷功能</text>
          <view class="feature-grid">
            <view class="feature-item" @click="handleScanCode">
              <view class="feature-icon primary-gradient">
                <text class="iconfont icon-saoyisao" style="color: #fff; font-size: 40rpx;"></text>
              </view>
              <text class="feature-name">扫码开门</text>
            </view>

            <view class="feature-item" @click="handleVisitorPassword">
              <view class="feature-icon icon-green">
                <text class="iconfont icon-fa-key" style="color: #fff; font-size: 40rpx;"></text>
              </view>
              <text class="feature-name">访客密码</text>
            </view>

            <view class="feature-item" @click="handleVisitorCode">
              <view class="feature-icon icon-blue">
                <text class="iconfont icon-a-fasfa-qrcode" style="color: #fff; font-size: 40rpx;"></text>
              </view>
              <text class="feature-name">开门二维码</text>
            </view>

            <view class="feature-item" @click="handleFaceUpload">
              <view class="feature-icon icon-purple">
                <text class="iconfont icon-smile-solid" style="color: #fff; font-size: 40rpx;"></text>
              </view>
              <text class="feature-name">人脸上传</text>
            </view>
          </view>
        </view>
      </view>
    </scroll-view>
    
    <!-- 自定义底部标签栏 -->
    <custom-tabbar />

    <!-- 服务协议和隐私政策弹框 -->
    <uni-popup ref="agreementPopup" type="center" :mask-click="false">
      <view class="agreement-popup">
        <view class="agreement-title">服务协议和隐私政策</view>
        <view class="agreement-content">
          欢迎使用福优智家。我们非常重视您的个人信息和隐私保护。在您使用"服务"之前，请务必仔细阅读
          <text class="link" @click="agreementStore.openUserAgreement()">《用户协议》</text>
          <text>和</text>
          <text class="link" @click="agreementStore.openPrivacyPolicy()">《隐私政策》</text>
          ，并充分理解所有关于您的个人信息和隐私的内容。我们将严格按照您同意的各项条款使用您的个人信息，以便更好的为您提供服务。
        </view>
        <view class="agreement-buttons">
          <button class="btn-disagree" @click="handleDisagree">不同意</button>
          <button class="btn-agree" @click="handleAgree">同意并继续</button>
        </view>
      </view>
    </uni-popup>
  
    <!-- 底部横幅广告（Taku）：常驻页面底部，placementId 为空/开关全关时自动隐藏 -->
    <view class="ad-section ad-tab" v-if="bannerAdId">
      <view class="ad-divider"></view>
      <view class="ad-view">
        <taku-banner :placement-id="bannerAdId"></taku-banner>
      </view>
    </view>
    </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onMounted, watch } from 'vue'
import { onLoad, onShow, onUnload } from '@dcloudio/uni-app'
import scanUtils from '@/utils/scanUtils'
import checkVersion from '@/pages/lq-upgrade/checkVersion.js'
import { useThemeVars } from '@/utils/themeConfig.js'
import { formatDoorDevice, sortDoorDevices } from '@/utils/deviceDisplayUtils.js'
import { showOfflinePasswordModal, showOpenDoorFailModal } from '@/utils/offlinePasswordUtils.js'
// #ifdef H5
import { isNativeShell, NativeApp } from '@/utils/h5-native-bridge'
// #endif

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const deviceStore = proxy.$store.device.useDeviceStore()
const agreementStore = proxy.$store.agreement.useAgreementStore()
const themeStore = proxy.$store.theme.useThemeStore()
const agreementPopup = ref(null)
const roomList = ref([])
const loading = ref(false)
const homeDataRefreshing = ref(false)
const deviceOpenCounts = ref({}) // 存储设备开门次数
const currentIndex = ref(0) // 当前展示的设备索引
const HOME_DEVICE_LIMIT = 5

const openAgreementPopup = () => {
  if (!agreementPopup.value?.open) {
    console.warn('协议弹窗未就绪，暂不打开')
    return
  }

  agreementPopup.value.open()
}

// 获取设备开门次数
const getDeviceOpenCount = (doorMac) => {
  return deviceOpenCounts.value[doorMac] || 0
}

// 获取常用设备（按使用频率排序）
const commonDevices = computed(() => {
  if (!deviceStore.deviceList || deviceStore.deviceList.length === 0) {
    return []
  }

  const formattedList = deviceStore.deviceList.map((device, index) => {
    return formatDoorDevice(device, index, getDeviceOpenCount)
  })

  return sortDoorDevices(formattedList).slice(0, HOME_DEVICE_LIMIT)
})

// 轮播列表（常用设备 + 全部设备）
const carouselList = computed(() => {
  const list = [...commonDevices.value]
  // 添加"全部设备"作为最后一项
  list.push({
    isAllDevices: true,
    name: '全部设备',
    location: '查看完整门禁列表',
    isOnline: true,
    door_id: 'all_devices_special_key' // 增加唯一标识，避免重复渲染时无 key
  })
  return list
})

watch(carouselList, (list) => {
  if (currentIndex.value >= list.length) {
    currentIndex.value = Math.max(list.length - 1, 0)
  }
})

// Swiper 切换事件
const handleSwiperChange = (e) => {
  // 只在非代码触发时更新（避免循环触发）
  if (e.detail.source === 'touch') {
    currentIndex.value = e.detail.current
  }
}

const setCarouselIndex = (index) => {
  currentIndex.value = index
}

// 处理设备操作（开门或跳转）
const handleDeviceAction = (device) => {
  if (device.isAllDevices) {
    handleAllDevices()
  } else {
    handleQuickOpen(device)
  }
}

// 导航栏高度（状态栏 + 导航栏）
const navbarHeight = ref(0)

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))

// 检查是否有房屋认证
const hasRoom = computed(() => {
  return roomList.value && roomList.value.length > 0
})

// 检查是否有设备
const hasDevice = computed(() => {
  return deviceStore.deviceList && deviceStore.deviceList.length > 0
})

// 加载设备开门次数
const loadDeviceOpenCounts = () => {
  try {
    const counts = uni.getStorageSync('device_open_counts') || {}
    deviceOpenCounts.value = counts
    console.log('加载开门次数:', counts)
  } catch (e) {
    console.error('加载开门次数失败:', e)
    deviceOpenCounts.value = {}
  }
}

// 监听开门次数更新事件
uni.$on('deviceOpenCountUpdated', () => {
  loadDeviceOpenCounts()
})

// 更新设备开门次数
const updateDeviceOpenCount = (doorMac) => {
  try {
    const counts = uni.getStorageSync('device_open_counts') || {}
    counts[doorMac] = (counts[doorMac] || 0) + 1
    uni.setStorageSync('device_open_counts', counts)
    deviceOpenCounts.value = { ...counts } // 同步更新响应式数据，触发重新计算和排序
    uni.$emit('deviceOpenCountUpdated') // 通知其他页面
  } catch (e) {
    console.error('更新开门次数失败:', e)
  }
}

// 快速开门
const handleQuickOpen = async (device) => {
  console.log('快速开门:', device)
  
  // 检查登录状态
  if (!userStore.checkLogin()) {
    return
  }
  
  // 检查设备是否在线
  if (!device.isOnline) {
    showOfflinePasswordModal(device)
    return
  }
  
  try {
    // 显示开门中提示
    uni.showLoading({
      title: '开门中...',
      mask: true
    })
    
    // 导入开门工具
    const doorAccessUtils = await import('@/utils/doorAccessUtils')
    
    // 调用远程开门接口
    await doorAccessUtils.default.openDoor(device)
    
    // 隐藏加载提示
    uni.hideLoading()
    
    // 开门成功后更新开门次数
    updateDeviceOpenCount(device.door_mac)
    
    // 显示成功提示
    // uni.showToast 已经在 openDoor 里面调用过了，这里可以不用重复调用
  } catch (error) {
    console.error('开门失败 caught in index:', error)
    uni.hideLoading()
    
    // 无论是设备不匹配、网路异常、还是响应失败，都弹出离线密码备用方案
    showOfflinePasswordModal(device)
  }
}

// 全部设备 - 跳转到开门页面
const handleAllDevices = () => {
  // 检查登录状态
  if (!userStore.checkLogin()) {
    return
  }
  uni.switchTab({
    url: '/pages/door/index'
  })
}

// 广告点击
const handleAdClick = () => {
  console.log('广告点击')
}

// 扫码开门
const handleScanCode = async () => {
  if (!userStore.checkLogin()) return
  const result = await scanUtils.scanQRCode()
  console.log('扫码结果', result)
  if (result) {
    uni.navigateTo({
      url: `/pages/door/scan?device_number=${result}`
    })
  } else {
    uni.showToast({
      title: '扫码失败，请重试',
      icon: 'none',
      duration: 2000
    })
  }
}

// 访客密码
const handleVisitorPassword = () => {
  if (!userStore.checkLogin()) return
  uni.navigateTo({
    url: '/workbench_package/pages/visitor-password/index'
  })
}

// 访客二维码
const handleVisitorCode = () => {
  // 检查登录状态
  if (!userStore.checkLogin()) {
    return
  }
  uni.navigateTo({
    url: '/workbench_package/pages/qrcode/index'
  })
}

// 人脸上传
const handleFaceUpload = () => {
  if (!userStore.checkLogin()) return
  uni.navigateTo({
    url: '/workbench_package/pages/face-upload/index'
  })
}

// 快捷联系
const handleContact = (type) => {
  console.log('联系:', type)
  uni.showToast({
    title: `正在联系${type === 'property' ? '物业客服' : type === 'security' ? '保安室' : '报修服务'}`,
    icon: 'none'
  })
}

// 智能场景
const handleScene = (type) => {
  console.log('场景:', type)
  uni.showToast({
    title: `${type === 'home' ? '回家' : '离家'}模式已激活`,
    icon: 'none'
  })
}

// 通知
const handleNotification = () => {
  console.log('通知')
    uni.showToast({
      title: '暂无新通知',
      icon: 'none'
    })
}

// 房屋认证
const handleCertification = () => {
  // 检查登录状态
  if (!userStore.checkLogin()) {
    return
  }
  uni.navigateTo({
    url: '/pages/device/index'
  })
}

// 检查是否已登录（不自动跳转）
const isLoggedIn = computed(() => {
  return userStore.isLogin
})

// 加载房屋列表
const loadRoomList = async () => {
  if (!userStore.isLogin) {
    return
  }
  if (homeDataRefreshing.value) {
    return
  }
  try {
    homeDataRefreshing.value = true
    loading.value = true
    const res = await userStore.updateRoomList({ showLoading: false })
    const data = res?.data || []
    if (Array.isArray(data)) {
      roomList.value = data
    } else {
      roomList.value = []
    }
  } catch (error) {
    console.error('获取房屋列表失败:', error)
    if (roomList.value.length === 0) {
      roomList.value = []
    }
  } finally {
    homeDataRefreshing.value = false
    loading.value = false
  }
}

// 检查版本更新
const checkAppUpdate = () => {
  console.log('检查版本更新')
  const userApi = proxy.$api.user
  userApi.getAppVersion().then(res => {
    console.log('版本信息', res)
    if (res.code === '0' && res.data && res.data.length > 0) {
      const versionInfo = res.data[0]
      console.log('版本信息', versionInfo)
      // 检查是否需要更新
      checkVersion({
        name: versionInfo.ver_name,         // 版本名称
        code: parseInt(versionInfo.ver_no), // 版本号
        content: versionInfo.ver_des,       // 更新内容
        url: versionInfo.ver_link,          // 下载链接
        forceUpdate: versionInfo.ver_forced_update === '1'  // 是否强制更新
      })
    }
  }).catch(err => {
    console.error('获取版本信息失败:', err)
  })
}

// 检查是否首次打开应用
const checkFirstOpen = () => {
  // #ifdef APP-PLUS
  const platform = uni.getSystemInfoSync().osName
  if (platform === 'ios' && !agreementStore.checkAgreement()) {
    openAgreementPopup()
    return
  }
  // #endif
  
  // #ifdef H5
  if (!agreementStore.checkAgreement()) {
    openAgreementPopup()
    return
  }
  // #endif
  
  // 协议已同意，只加载数据，不主动跳转登录（避免重复跳转）
  if (userStore.isLogin && agreementStore.checkAgreement()) {
    loadRoomList()
  }
}

// 页面生命周期
onLoad(() => {
  navbarHeight.value = (uni.getSystemInfoSync().statusBarHeight || 0) + 44
  
  // 检查版本更新（原生壳为 H5，同样需要触发）
  // #ifdef APP-PLUS || H5
  checkAppUpdate()
  // #endif
  
  // 加载开门次数
  loadDeviceOpenCounts()
})

onMounted(() => {
  checkFirstOpen()
})

onShow(() => {
  // 隐藏原生TabBar
  uni.hideTabBar({
    animation: false
  })
  
  // 页面显示时刷新数据
  if (userStore.isLogin) {
    // 加载开门次数
    loadDeviceOpenCounts()
    // 每次首页显示都静默刷新房屋和设备，避免认证成功后仍显示认证入口。
    loadRoomList()
  }
})

onUnload(() => {
  uni.$off('deviceOpenCountUpdated')
})

// 处理不同意协议
const handleDisagree = () => {
  // #ifdef APP-PLUS
  plus.runtime.quit()
  // #endif
  // #ifdef H5
  // 原生壳内：window.close() 会被 WebView 忽略，改走 app.quit 桥退出应用；普通浏览器仍用 window.close
  if (isNativeShell) {
    NativeApp.quit().catch(() => {})
  } else {
    window.close()
  }
  // #endif
}

// 处理同意协议
const handleAgree = () => {
  agreementStore.setAgreement(true)
  agreementPopup.value.close()
  
  // 检查登录状态并跳转
  if (!userStore.isLogin) {
    uni.reLaunch({
      url: '/pages/ioslogin/index'
    })
  } else {
    loadRoomList()
  }
}

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
</script>

<style lang="scss">
/* 
 * 优福智家管理 APP 配色方案 - CSS Variables
 */
.page-container {
  /* 默认浅色主题变量 */
  --color-dominant: hsl(220, 20%, 97%);
  --color-support: hsl(220, 25%, 20%);
  --color-accent: hsl(210, 100%, 50%);
  --color-text-secondary: hsl(220, 10%, 55%);
  --color-card: hsl(0, 0%, 100%);
  --color-glass: rgba(255, 255, 255, 0.8);
  --color-glass-border: rgba(0, 0, 0, 0.06);
  --color-divider: hsl(220, 15%, 92%);
  --shadow-card: 0 2px 12px rgba(0,0,0,0.04);
  --shadow-card-hover: 0 12px 32px -8px rgba(0,0,0,0.12);
  
  /* 深色主题变量覆盖 */
  &.dark-mode {
    --color-dominant: hsl(220, 25%, 12%);
    --color-support: hsl(220, 15%, 96%);
    --color-accent: hsl(200, 85%, 55%);
    --color-text-secondary: hsl(220, 15%, 65%);
    --color-card: rgba(30, 41, 59, 0.95);
    --color-glass: rgba(255, 255, 255, 0.08);
    --color-glass-border: rgba(255, 255, 255, 0.12);
    --color-divider: rgba(255, 255, 255, 0.08);
    --shadow-card: 0 4rpx 16rpx rgba(0, 0, 0, 0.3);
    --shadow-card-hover: 0 20rpx 40rpx -10px rgba(0, 0, 0, 0.4);
  }

  min-height: 100vh;
  background-color: var(--color-dominant);
  position: relative;
  overflow: hidden;
}

/* 环境光背景 */
.ambient-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    radial-gradient(circle at 20% 20%, hsla(210, 100%, 70%, 0.08), transparent 40%),
    radial-gradient(circle at 80% 80%, hsla(280, 80%, 70%, 0.05), transparent 40%);
  pointer-events: none;
  z-index: 0;
  
  .dark-mode & {
    background: 
      radial-gradient(circle at 20% 20%, hsla(200, 80%, 50%, 0.15), transparent 40%),
      radial-gradient(circle at 80% 80%, hsla(280, 60%, 40%, 0.1), transparent 40%);
  }
}

.app-content {
  height: 100vh;
  position: relative;
  z-index: 1;
}

.header-section {
  padding: 20rpx 40rpx;
  margin-bottom: 20rpx;
}

.header-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.app-title {
  font-size: 48rpx;
  font-weight: bold;
  color: var(--color-support);
  display: block;
}

.app-subtitle {
  font-size: 28rpx;
  color: var(--color-text-secondary);
  margin-top: 8rpx;
  display: block;
}

.section {
  margin: 40rpx 24rpx;
}

.common-device-section {
  margin-top: 28rpx;
}

.section-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24rpx;
}

.section-title {
  font-size: 36rpx;
  font-weight: 600;
  color: var(--color-support);
  padding-left: 16rpx;
  border-left: 6rpx solid var(--color-accent);
  display: block;
}

.section > .section-title {
  margin-bottom: 24rpx;
}

.section-action {
  display: flex;
  align-items: center;
  gap: 4rpx;
  padding: 10rpx 18rpx;
  border-radius: 999rpx;
  color: var(--color-accent);
  background: rgba(14, 132, 255, 0.1);
  font-size: 24rpx;
  font-weight: 600;
}

.section-action .iconfont {
  font-size: 22rpx;
}

/* 玻璃拟态卡片 */
.glass-card {
  background: var(--color-glass);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-radius: 24rpx;
  border: 1px solid var(--color-glass-border);
  box-shadow: var(--shadow-card);
  transition: all 0.3s ease;
  
  &:active {
    transform: scale(0.98);
    box-shadow: var(--shadow-card-hover);
  }
}

.action-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 24rpx;
}

.action-btn {
  padding: 32rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 240rpx;
  position: relative;
}

.action-title {
  font-size: 32rpx;
  font-weight: 600;
  color: var(--color-support);
  margin-top: 24rpx;
  text-align: center;
}

.action-desc {
  font-size: 24rpx;
  color: var(--color-text-secondary);
  margin-top: 8rpx;
  text-align: center;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 32rpx;
  padding: 10rpx 0;
}

.feature-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16rpx;
}

.feature-icon {
  width: 100rpx;
  height: 100rpx;
  border-radius: 32rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  
  &.primary-gradient {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    box-shadow: 0 10rpx 20rpx rgba(118, 75, 162, 0.3);
  }
  
  &.icon-green {
    background: linear-gradient(135deg, #34c759 0%, #30d158 100%);
    box-shadow: 0 10rpx 20rpx rgba(52, 199, 89, 0.3);
  }
  
  &.icon-blue {
    background: linear-gradient(135deg, #0a84ff 0%, #0066cc 100%);
    box-shadow: 0 10rpx 20rpx rgba(10, 132, 255, 0.3);
  }
  
  &.icon-purple {
    background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
    box-shadow: 0 10rpx 20rpx rgba(139, 92, 246, 0.3);
  }
  
  &:active {
    transform: scale(0.95);
  }
}

.feature-name {
  font-size: 26rpx;
  color: var(--color-support);
}

/* 空状态 */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60rpx 40rpx;
  margin: 40rpx 24rpx;
  background: var(--color-card);
  border-radius: 32rpx;
  border: 1px solid var(--color-glass-border);
  box-shadow: var(--shadow-card);
}

.empty-icon-wrapper {
  width: 160rpx;
  height: 160rpx;
  background: linear-gradient(135deg, var(--color-accent) 0%, #2563eb 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32rpx;
  box-shadow: 0 20rpx 40rpx rgba(37, 99, 235, 0.3);
}

.empty-title {
  font-size: 40rpx;
  font-weight: bold;
  color: var(--color-support);
  margin-bottom: 16rpx;
}

.empty-desc {
  font-size: 28rpx;
  color: var(--color-text-secondary);
  text-align: center;
  line-height: 1.6;
  margin-bottom: 48rpx;
}

.empty-btn-wrapper {
  width: 100%;
  margin-bottom: 40rpx;
}

.empty-btn {
  width: 100%;
  height: 96rpx;
  background: linear-gradient(135deg, var(--color-accent) 0%, #2563eb 100%);
  border-radius: 48rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 32rpx;
  font-weight: 600;
  box-shadow: 0 16rpx 32rpx rgba(37, 99, 235, 0.3);
  transition: all 0.3s ease;
  
  &:active {
    transform: scale(0.98);
  }
}

.steps-guide {
  width: 100%;
  padding-top: 32rpx;
  border-top: 1px solid var(--color-divider);
}

.steps-title {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--color-support);
  margin-bottom: 24rpx;
  display: block;
}

.step-item {
  display: flex;
  align-items: center;
  margin-bottom: 20rpx;
  
  &:last-child {
    margin-bottom: 0;
  }
}

.step-number {
  width: 40rpx;
  height: 40rpx;
  background: rgba(37, 99, 235, 0.1);
  color: var(--color-accent);
  border-radius: 50%;
  font-size: 24rpx;
  font-weight: bold;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16rpx;
}

.step-text {
  font-size: 26rpx;
  color: var(--color-text-secondary);
}

/* 设备状态徽标 */
.device-status-badge {
  position: absolute;
  top: 20rpx;
  right: 20rpx;
  padding: 4rpx 12rpx;
  border-radius: 20rpx;
  display: flex;
  align-items: center;
  gap: 6rpx;
  
  &.online {
    background: rgba(52, 199, 89, 0.15);
    .status-dot-small { background: #34c759; }
    .status-text-small { color: #34c759; }
  }
  
  &.offline {
    background: rgba(148, 163, 184, 0.15);
    .status-dot-small { background: #94a3b8; }
    .status-text-small { color: #94a3b8; }
  }
}

.status-dot-small {
  width: 8rpx;
  height: 8rpx;
  border-radius: 50%;
}

.status-text-small {
  font-size: 20rpx;
  font-weight: 500;
}

/* 协议弹框 */
.agreement-popup {
  width: 600rpx;
  background: var(--color-card);
  border-radius: 24rpx;
  padding: 40rpx;
}

.agreement-title {
  font-size: 36rpx;
  font-weight: bold;
  color: var(--color-support);
  text-align: center;
  margin-bottom: 30rpx;
}

.agreement-content {
  font-size: 28rpx;
  color: var(--color-text-secondary);
  line-height: 1.6;
  margin-bottom: 40rpx;
  
  .link {
    color: var(--color-accent);
    text-decoration: underline;
  }
}

.agreement-buttons {
  display: flex;
  justify-content: space-between;
  gap: 20rpx;
}

.btn-disagree {
  flex: 1;
  background: var(--color-divider);
  color: var(--color-text-secondary);
  font-size: 28rpx;
  padding: 20rpx 0;
  border-radius: 40rpx;
  border: none;
  &::after { border: none; }
}

.device-carousel-wrapper {
  position: relative;
  width: 100%;
  padding-bottom: 26rpx;
}

.device-main-display {
  width: 100%;
  height: 360rpx;
}

.home-device-card {
  position: relative;
  height: 320rpx;
  margin: 0 10rpx;
  padding: 34rpx;
  border-radius: 36rpx;
  overflow: hidden;
  background:
    linear-gradient(135deg, rgba(14, 165, 233, 0.12) 0%, rgba(37, 99, 235, 0.04) 48%, rgba(255, 255, 255, 0.9) 100%);
  border: 1px solid var(--color-glass-border);
  box-shadow: 0 18rpx 44rpx rgba(15, 23, 42, 0.08);
  box-sizing: border-box;
}

.dark-mode .home-device-card {
  background:
    linear-gradient(135deg, rgba(56, 189, 248, 0.18) 0%, rgba(30, 41, 59, 0.92) 54%, rgba(15, 23, 42, 0.98) 100%);
  box-shadow: 0 18rpx 48rpx rgba(0, 0, 0, 0.34);
}

.home-device-card-offline {
  background:
    linear-gradient(135deg, rgba(148, 163, 184, 0.18) 0%, rgba(248, 250, 252, 0.95) 100%);
}

.dark-mode .home-device-card-offline {
  background:
    linear-gradient(135deg, rgba(100, 116, 139, 0.22) 0%, rgba(15, 23, 42, 0.96) 100%);
}

.home-device-card-all {
  background:
    linear-gradient(135deg, rgba(16, 185, 129, 0.16) 0%, rgba(14, 165, 233, 0.1) 48%, rgba(255, 255, 255, 0.92) 100%);
}

.dark-mode .home-device-card-all {
  background:
    linear-gradient(135deg, rgba(16, 185, 129, 0.2) 0%, rgba(14, 165, 233, 0.12) 48%, rgba(15, 23, 42, 0.98) 100%);
}

.home-card-glow {
  position: absolute;
  right: -70rpx;
  top: -90rpx;
  width: 260rpx;
  height: 260rpx;
  border-radius: 50%;
  background: rgba(14, 165, 233, 0.18);
  filter: blur(2rpx);
}

.home-device-card-offline .home-card-glow {
  background: rgba(100, 116, 139, 0.16);
}

.home-device-card-all .home-card-glow {
  background: rgba(16, 185, 129, 0.2);
}

.home-device-header {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 22rpx;
}

.home-device-icon {
  width: 96rpx;
  height: 96rpx;
  border-radius: 28rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%);
  box-shadow: 0 16rpx 30rpx rgba(37, 99, 235, 0.28);
}

.home-device-icon .iconfont {
  color: #fff;
  font-size: 48rpx;
}

.home-device-icon-offline {
  background: linear-gradient(135deg, #94a3b8 0%, #64748b 100%);
  box-shadow: 0 16rpx 30rpx rgba(100, 116, 139, 0.2);
}

.home-device-icon-all {
  background: linear-gradient(135deg, #10b981 0%, #0ea5e9 100%);
  box-shadow: 0 16rpx 30rpx rgba(16, 185, 129, 0.24);
}

.home-device-info {
  flex: 1;
  min-width: 0;
}

.home-device-title {
  display: block;
  color: var(--color-support);
  font-size: 36rpx;
  font-weight: 700;
  line-height: 1.25;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.home-device-location {
  display: block;
  margin-top: 8rpx;
  color: var(--color-text-secondary);
  font-size: 24rpx;
  line-height: 1.35;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.home-status-chip {
  display: flex;
  align-items: center;
  gap: 8rpx;
  flex-shrink: 0;
  padding: 8rpx 14rpx;
  border-radius: 999rpx;
  font-size: 22rpx;
  font-weight: 600;
}

.home-status-online {
  color: #16a34a;
  background: rgba(34, 197, 94, 0.14);
}

.home-status-offline {
  color: #64748b;
  background: rgba(100, 116, 139, 0.14);
}

.dark-mode .home-status-online {
  color: #86efac;
}

.dark-mode .home-status-offline {
  color: #cbd5e1;
}

.home-status-dot {
  width: 12rpx;
  height: 12rpx;
  border-radius: 50%;
  background: currentColor;
  box-shadow: 0 0 10rpx currentColor;
}

.home-device-body {
  position: relative;
  z-index: 1;
  margin-top: 38rpx;
}

.home-device-desc {
  display: block;
  color: var(--color-text-secondary);
  font-size: 26rpx;
  margin-bottom: 24rpx;
}

.home-open-button {
  height: 82rpx;
  border-radius: 26rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12rpx;
  color: #fff;
  font-size: 30rpx;
  font-weight: 700;
  background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%);
  box-shadow: 0 16rpx 28rpx rgba(37, 99, 235, 0.24);
  transition: transform 0.18s ease, opacity 0.18s ease;
}

.home-open-button:active {
  transform: scale(0.98);
  opacity: 0.9;
}

.home-open-button .iconfont {
  font-size: 30rpx;
}

.home-open-button-offline {
  background: linear-gradient(135deg, #64748b 0%, #475569 100%);
  box-shadow: 0 16rpx 28rpx rgba(71, 85, 105, 0.18);
}

.home-open-button-all {
  background: linear-gradient(135deg, #10b981 0%, #0ea5e9 100%);
  box-shadow: 0 16rpx 28rpx rgba(16, 185, 129, 0.2);
}

.carousel-dots {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10rpx;
}

.carousel-dot {
  width: 10rpx;
  height: 10rpx;
  border-radius: 999rpx;
  background: rgba(100, 116, 139, 0.35);
  transition: all 0.2s ease;
}

.carousel-dot.active {
  width: 32rpx;
  background: var(--color-accent);
}


.btn-agree {
  flex: 1;
  background: var(--color-accent);
  color: #fff;
  font-size: 28rpx;
  padding: 20rpx 0;
  border-radius: 40rpx;
  border: none;
  &::after { border: none; }
}

/* ===== Taku 底部横幅广告 ===== */
.ad-section {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 20;
  width: 100%;
  box-sizing: border-box;
  background: #ffffff;
  box-shadow: 0 -6rpx 20rpx rgba(31, 48, 152, 0.08);
}

.ad-section .ad-divider {
  height: 2rpx;
  background: #eeeeee;
}

.ad-section .ad-view {
  display: flex;
  justify-content: center;
  align-items: center;
}

/* Tab 页：横幅悬浮在自定义 tabbar（高100rpx+安全区）上方 */
.ad-section.ad-tab {
  bottom: calc(100rpx + env(safe-area-inset-bottom));
  box-shadow: 0 -4rpx 16rpx rgba(31, 48, 152, 0.12);
}
</style>
