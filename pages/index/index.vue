<template>
  <view class="page-container" :class="{ 'dark-mode': themeStore.isDark() }">
    <view class="ambient-bg"></view>
    <!-- 自定义导航栏 -->
    <custom-navbar title="优福社区" :transparent="true" />
    
    <!-- 内容区域 -->
    <scroll-view class="app-content" scroll-y :style="{ paddingTop: navbarHeight + 'px' }">
      <!-- Header -->
      <view class="header-section">
        <view class="header-top">
          <view class="header-left">
            <text class="app-title">优福社区</text>
            <text class="app-subtitle">智能守护，安心生活</text>
          </view>
        </view>
      </view>

      <!-- 无房屋和设备的空状态 -->
      <view v-if="!hasRoom && !hasDevice" class="empty-state">
        <view class="empty-icon-wrapper">
          <text class="iconfont icon-fa-home" style="color: #fff; font-size: 80rpx;"></text>
        </view>
        <text class="empty-title">欢迎使用优福社区</text>
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
        <!-- 常用设备 - 单个展示轮播 -->
        <view class="section">
          <text class="section-title">常用设备</text>
          
          <view class="device-carousel-wrapper">
            <!-- 中间设备展示 (使用 Swiper 替代 Transition) -->
            <swiper 
              class="device-main-display"
              :current="currentIndex"
              @change="handleSwiperChange"
              :circular="false"
              :indicator-dots="false"
              :autoplay="false"
              :duration="300"
            >
              <swiper-item v-for="(device, index) in carouselList" :key="index">
                <view class="device-content-wrapper">
                  <!-- 大开门按钮 -->
                  <view 
                    class="door-btn-wrapper"
                    @touchstart="handlePressStart"
                    @touchend="handlePressEnd"
                    @touchcancel="handlePressEnd"
                    @click="handleDeviceAction(device)"
                  >
                    <image 
                      :src="isPressed && currentIndex === index ? '/static/icons/icon_index_pressed_true.png' : '/static/icons/icon_index_pressed_false.png'" 
                      class="door-btn-img"
                      mode="aspectFit"
                    ></image>
                    
                    <!-- 设备名称 (叠加在图片下半部分) -->
                    <view class="device-name-overlay">
                      <text class="device-name-text">{{ device.name }}</text>
                    </view>
                  </view>
                  
                  <!-- 在线状态指示 -->
                  <view v-if="!device.isAllDevices" class="status-indicator">
                    <view class="status-dot" :class="device.online === '1' ? 'online' : 'offline'"></view>
                    <text class="status-text">{{ device.online === '1' ? '设备在线' : '设备离线' }}</text>
                  </view>
                </view>
              </swiper-item>
            </swiper>

            <!-- 左侧切换按钮 (绝对定位，支持点击和滑动) -->
            <view 
              class="nav-btn-side left-btn" 
              @touchstart="handleButtonTouchStart"
              @touchend="(e) => handleButtonTouchEnd(e, true)"
              :class="{ disabled: currentIndex === 0 }"
            >
              <image src="/static/icons/icon_left_index.png" class="nav-icon-img" mode="aspectFit"></image>
            </view>

            <!-- 右侧切换按钮 (绝对定位，支持点击和滑动) -->
            <view 
              class="nav-btn-side right-btn" 
              @touchstart="handleButtonTouchStart"
              @touchend="(e) => handleButtonTouchEnd(e, false)"
              :class="{ disabled: currentIndex >= carouselList.length - 1 }"
            >
              <image src="/static/icons/icon_right_index.png" class="nav-icon-img" mode="aspectFit"></image>
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
          欢迎使用优福社区。我们非常重视您的个人信息和隐私保护。在您使用"服务"之前，请务必仔细阅读
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
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onMounted } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import scanUtils from '@/utils/scanUtils'
import checkVersion from '@/pages/lq-upgrade/checkVersion.js'
import { useThemeVars } from '@/utils/themeConfig.js'

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const deviceStore = proxy.$store.device.useDeviceStore()
const agreementStore = proxy.$store.agreement.useAgreementStore()
const themeStore = proxy.$store.theme.useThemeStore()
const agreementPopup = ref(null)
const notificationCount = ref(3)
const roomList = ref([])
const loading = ref(false)
const deviceOpenCounts = ref({}) // 存储设备开门次数
const currentIndex = ref(0) // 当前展示的设备索引
const isPressed = ref(false) // 按钮按压状态
const btnTouchStartX = ref(0) // 按钮区域触摸起始点

// 轮播列表（常用设备 + 全部设备）
const carouselList = computed(() => {
  const list = [...commonDevices.value]
  // 添加"全部设备"作为最后一项
  list.push({
    isAllDevices: true,
    name: '全部设备',
    online: '1' // 默认在线
  })
  return list
})

// 当前展示的设备
const currentDevice = computed(() => {
  if (carouselList.value.length === 0) return null
  return carouselList.value[currentIndex.value] || carouselList.value[0]
})

// 向左切换
const handlePrev = () => {
  if (currentIndex.value > 0) {
    currentIndex.value--
  }
}

// 向右切换
const handleNext = () => {
  if (currentIndex.value < carouselList.value.length - 1) {
    currentIndex.value++
  }
}

// Swiper 切换事件
const handleSwiperChange = (e) => {
  // 只在非代码触发时更新（避免循环触发）
  if (e.detail.source === 'touch') {
    currentIndex.value = e.detail.current
  }
}

// 按钮区域触摸处理（解决按钮遮挡滑动的问题）
const handleButtonTouchStart = (e) => {
  btnTouchStartX.value = e.changedTouches[0].clientX
}

const handleButtonTouchEnd = (e, isLeftBtn) => {
  const endX = e.changedTouches[0].clientX
  const diff = endX - btnTouchStartX.value
  const threshold = 10 // 点击阈值
  
  // 如果移动距离很小，视为点击
  if (Math.abs(diff) < threshold) {
    if (isLeftBtn) handlePrev()
    else handleNext()
    return
  }
  
  // 否则视为滑动
  if (diff > 0) {
    // 右滑 -> 上一张
    handlePrev()
  } else {
    // 左滑 -> 下一张
    handleNext()
  }
}

// 按钮按压效果
const handlePressStart = () => {
  isPressed.value = true
}

const handlePressEnd = () => {
  isPressed.value = false
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

// 获取设备开门次数
const getDeviceOpenCount = (doorMac) => {
  return deviceOpenCounts.value[doorMac] || 0
}

// 获取常用设备（按使用频率排序）
const commonDevices = computed(() => {
  if (!deviceStore.deviceList || deviceStore.deviceList.length === 0) {
    return []
  }
  
  // 格式化设备列表
  const formattedList = deviceStore.deviceList.map((device, index) => {
    const location = `${device.comm_name || ''}${device.unit_name || ''}`.trim() || '未知位置'
    const isUnitDoor = (device.unit_name && device.unit_name.includes('单元')) || location.includes('单元')
    const openCount = getDeviceOpenCount(device.door_mac)
    
    // 图标配置
    let icon, iconGradient
    if (isUnitDoor) {
      const unitThemes = [
        { icon: 'icon-fasfa-building', iconGradient: 'linear-gradient(135deg, #34c759 0%, #30d158 100%)' },
        { icon: 'icon-fasfa-building', iconGradient: 'linear-gradient(135deg, #0a84ff 0%, #0066cc 100%)' },
        { icon: 'icon-fasfa-building', iconGradient: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)' }
      ]
      const theme = unitThemes[index % unitThemes.length]
      icon = theme.icon
      iconGradient = theme.iconGradient
    } else {
      const gateThemes = [
        { icon: 'icon-door-open', iconGradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' },
        { icon: 'icon-door-open', iconGradient: 'linear-gradient(135deg, #ff9500 0%, #ff6b00 100%)' },
        { icon: 'icon-door-open', iconGradient: 'linear-gradient(135deg, #ff2d55 0%, #ff375f 100%)' }
      ]
      const theme = gateThemes[index % gateThemes.length]
      icon = theme.icon
      iconGradient = theme.iconGradient
    }
    
    return {
      ...device,
      name: device.door_name || '门禁设备',
      location: location,
      icon: icon,
      iconGradient: iconGradient,
      openCount: openCount
    }
  })
  
  // 按开门次数排序
  return formattedList.sort((a, b) => b.openCount - a.openCount)
})

// 从渐变色中提取主色调
const getIconColor = (gradient) => {
  // 从渐变中提取第一个颜色
  const match = gradient.match(/#[0-9a-fA-F]{6}/)
  return match ? match[0] : '#667eea'
}

// 更新设备开门次数
const updateDeviceOpenCount = (doorMac) => {
  try {
    const counts = uni.getStorageSync('device_open_counts') || {}
    counts[doorMac] = (counts[doorMac] || 0) + 1
    uni.setStorageSync('device_open_counts', counts)
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
  if (device.online !== '1') {
    uni.showToast({
      title: '设备离线，无法开门',
      icon: 'none',
      duration: 2000
    })
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
    uni.showToast({
      title: '开门成功',
      icon: 'success',
      duration: 2000
    })
  } catch (error) {
    console.error('开门失败:', error)
    uni.hideLoading()
    // 错误已经在 doorAccessUtils 中处理
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
  try {
    loading.value = true
    const data = await userStore.getUserRoomList()
    if (Array.isArray(data)) {
      roomList.value = data
    } else {
      roomList.value = []
    }
  } catch (error) {
    console.error('获取房屋列表失败:', error)
    roomList.value = []
  } finally {
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
    agreementPopup.value.open()
    return
  }
  // #endif
  
  // #ifdef H5
  if (!agreementStore.checkAgreement()) {
    agreementPopup.value.open()
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
  // #ifdef APP-PLUS
  navbarHeight.value = uni.getSystemInfoSync().statusBarHeight + 44
  // #endif
  // #ifdef H5
  navbarHeight.value = 44
  // #endif
  
  // 检查是否首次打开
  checkFirstOpen()
  
  // 检查版本更新
  // #ifdef APP-PLUS
  checkAppUpdate()
  // #endif
  
  // 加载开门次数
  loadDeviceOpenCounts()
})

onShow(() => {
  // 隐藏原生TabBar
  uni.hideTabBar({
    animation: false
  })
  
  // 页面显示时刷新数据
  if (userStore.isLogin) {
    // 刷新房屋列表
    if (roomList.value.length === 0) {
      loadRoomList()
    }
    // 刷新设备列表（如果 store 中有相关方法）
    // deviceStore.getDeviceList()
  }
})

// 处理不同意协议
const handleDisagree = () => {
  // #ifdef APP-PLUS
  plus.runtime.quit()
  // #endif
  // #ifdef H5
  window.close()
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

.section-title {
  font-size: 36rpx;
  font-weight: 600;
  color: var(--color-support);
  margin-bottom: 24rpx;
  padding-left: 16rpx;
  border-left: 6rpx solid var(--color-accent);
  display: block;
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
  height: 520rpx; /* 确保高度足够 */
  display: flex;
  justify-content: center;
  align-items: center;
}

.nav-btn-side {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  z-index: 10;
  width: 80rpx;
  height: 80rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 1;
  transition: opacity 0.3s ease;
  
  &.left-btn {
    left: 10rpx;
  }
  
  &.right-btn {
    right: 10rpx;
  }
  
  &.disabled {
    opacity: 0.3;
    pointer-events: none;
  }
  
  &:active {
    transform: translateY(-50%) scale(0.9);
  }
}

.nav-icon-img {
  width: 60rpx;
  height: 60rpx;
}

.device-main-display {
  width: 100%;
  height: 100%;
}

.door-btn-wrapper {
  width: 440rpx;
  height: 440rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.1s ease;
  margin-bottom: 24rpx;
  position: relative;
  
  &:active {
    transform: scale(0.95);
  }
}

.door-btn-img {
  width: 100%;
  height: 100%;
}

.device-name-overlay {
  position: absolute;
  bottom: 110rpx;
  left: 0;
  right: 0;
  text-align: center;
  z-index: 2;
  padding: 0 80rpx; /* 收窄文字区域，避开图片透明边缘 */
  pointer-events: none; /* 防止文字遮挡点击 */
}

.device-name-text {
  font-size: 36rpx;
  font-weight: 600;
  color: #fff;
  text-shadow: 0 2rpx 8rpx rgba(0,0,0,0.6);
  width: 100%;
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 12rpx;
  padding: 8rpx 20rpx;
  background: rgba(0,0,0,0.05);
  border-radius: 20rpx;
  
  .dark-mode & {
    background: rgba(255,255,255,0.05);
  }
}

.status-dot {
  width: 12rpx;
  height: 12rpx;
  border-radius: 50%;
  
  &.online {
    background-color: #34c759;
    box-shadow: 0 0 8rpx rgba(52, 199, 89, 0.5);
  }
  
  &.offline {
    background-color: #94a3b8;
  }
}

.status-text {
  font-size: 24rpx;
  color: var(--color-text-secondary);
}

.device-content-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
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
</style>
