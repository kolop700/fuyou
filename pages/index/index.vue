<template>
  <view class="page-container">
    <!-- 内容区域 -->
    <scroll-view class="app-content" scroll-y>
      <!-- Header -->
      <view class="header-section">
        <view class="header-top">
          <view class="header-left">
            <text class="app-title">玉龙智眸</text>
            <text class="app-subtitle">智能守护，安心生活</text>
          </view>
          <!-- 注释掉右侧按钮 -->
          <!-- <view class="header-right">
            <view class="header-btn" @click="handleScanCode">
              <text class="iconfont icon-a-fasfa-qrcodeCopy2" style="color: #fff; font-size: 40rpx;"></text>
            </view>
            <view class="header-btn-notify" @click="handleNotification">
              <text class="iconfont icon-question-circle-fill" style="color: #667eea; font-size: 36rpx;"></text>
              <view class="badge" v-if="notificationCount > 0">{{ notificationCount }}</view>
            </view>
          </view> -->
        </view>
      </view>

      <!-- 无房屋和设备的空状态 -->
      <view v-if="!hasRoom && !hasDevice" class="empty-state">
        <view class="empty-icon-wrapper">
          <text class="iconfont icon-fa-home" style="color: #fff; font-size: 80rpx;"></text>
        </view>
        <text class="empty-title">欢迎使用玉龙智眸</text>
        <text class="empty-desc">您还未认证房屋<br>认证后即可使用智能门禁服务</text>
        
        <view class="empty-btn-wrapper">
          <view class="empty-btn" @click="handleCertification">
            <text class="iconfont icon-fasfa-plus" style="margin-right: 16rpx; font-size: 32rpx;"></text>
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
      <!-- 常用设备 - 显示使用最频繁的前3个设备 -->
      <view class="section">
        <text class="section-title">常用设备</text>
        <view class="action-grid">
          <view 
            class="action-btn" 
            v-for="(device, index) in top3Devices" 
            :key="index"
            @click="handleQuickOpen(device)"
          >
            <view class="device-status-badge" :class="device.online === '1' ? 'online' : 'offline'">
              <view class="status-dot-small"></view>
              <text class="status-text-small">{{ device.online === '1' ? '在线' : '离线' }}</text>
            </view>
            <text class="iconfont" :class="device.icon" :style="{ color: getIconColor(device.iconGradient), fontSize: '72rpx' }"></text>
            <text class="action-title">{{ device.name }}</text>
            <text class="action-desc">{{ device.location }}</text>
          </view>
          
          <view class="action-btn" @click="handleAllDevices">
            <text class="iconfont icon-a-fasfa-list-ul" style="color: #0a84ff; font-size: 72rpx;"></text>
            <text class="action-title">全部设备</text>
            <text class="action-desc">查看更多</text>
          </view>
        </view>
      </view>

      <!-- 快捷功能区 -->
      <view class="section">
        <text class="section-title">快捷功能</text>
        <view class="quick-functions">
          <view class="function-card primary" @click="handleScanCode">
            <view class="function-icon-wrapper primary-gradient">
              <text class="iconfont icon-a-fasfa-qrcodeCopy2" style="color: #fff; font-size: 56rpx;"></text>
            </view>
            <view class="function-text">
              <text class="function-title">扫码开门</text>
              <text class="function-desc">快速扫码</text>
            </view>
            <text class="iconfont icon-fasfa-chevron-rightCopy" style="color: #94a3b8; font-size: 28rpx;"></text>
          </view>
          
          <view class="function-grid">
            <view class="function-item" @click="handleVisitorPassword">
              <view class="function-icon-small icon-green">
                <text class="iconfont icon-fa-key" style="color: #fff; font-size: 40rpx;"></text>
              </view>
              <text class="function-name">访客密码</text>
            </view>
            <view class="function-item" @click="handleVisitorCode">
              <view class="function-icon-small icon-blue">
                <text class="iconfont icon-a-fasfa-qrcodeCopy2" style="color: #fff; font-size: 40rpx;"></text>
              </view>
              <text class="function-name">开门二维码</text>
            </view>
            <view class="function-item" @click="handleFaceUpload">
              <view class="function-icon-small icon-purple">
                <up-icon name="account-fill" color="#fff" size="40"></up-icon>
              </view>
              <text class="function-name">人脸上传</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 广告位 -->
      <!-- <view class="section">
        <view class="ad-banner" @click="handleAdClick">
          <view class="ad-bg-circle ad-circle-1"></view>
          <view class="ad-bg-circle ad-circle-2"></view>
          <view class="ad-content">
            <view class="ad-left">
              <text class="ad-tag">双十一狂欢</text>
              <text class="ad-title">智能家居套装</text>
              <text class="ad-desc">全场5折起 · 满减优惠</text>
            </view>
            <view class="ad-icon-wrapper">
              <text class="iconfont icon-a-zu394" style="color: #fff; font-size: 56rpx;"></text>
            </view>
          </view>
        </view>
      </view> -->

      <!-- 小区公告 -->
      <!-- <view class="section">
        <text class="section-title">小区公告</text>
        <view class="notice-card">
          <view class="notice-icon-wrapper">
            <text class="iconfont icon-info-circle" style="color: #f59e0b; font-size: 40rpx;"></text>
          </view>
          <view class="notice-content">
            <text class="notice-title">本周停水通知</text>
            <text class="notice-text">本周六（11月2日）上午9:00-12:00进行供水管道维护，请提前储水。</text>
            <text class="notice-footer">物业办 · 10月30日发布</text>
          </view>
        </view>
      </view> -->

      <!-- 注释掉以下区域 -->
      <!-- 访客管理 -->
      <!-- <view class="section">
        <text class="section-title">访客管理</text>
        <view class="house-card" @click="handleVisitorCode">
          <view class="visitor-content">
            <view class="visitor-icon-wrapper">
              <text class="iconfont icon-a-fasfa-qrcodeCopy2" style="color: #fff; font-size: 56rpx;"></text>
            </view>
            <view class="visitor-text">
              <text class="visitor-title">生成访客码</text>
              <text class="visitor-desc">邀请亲友访问，一码通行</text>
            </view>
            <text class="iconfont icon-fasfa-chevron-rightCopy" style="color: #94a3b8; font-size: 36rpx;"></text>
          </view>
        </view>
      </view> -->

      <!-- 快捷联系 -->
      <!-- <view class="section">
        <text class="section-title">快捷联系</text>
        <view class="contact-grid">
          <view class="contact-item" @click="handleContact('property')">
            <view class="contact-icon-wrapper contact-icon-1">
              <text class="iconfont icon-fasfa-building" style="color: #fff; font-size: 44rpx;"></text>
            </view>
            <text class="contact-text">物业客服</text>
          </view>
          <view class="contact-item" @click="handleContact('security')">
            <view class="contact-icon-wrapper contact-icon-2">
              <text class="iconfont icon-unlock-alt" style="color: #fff; font-size: 44rpx;"></text>
            </view>
            <text class="contact-text">保安室</text>
          </view>
          <view class="contact-item" @click="handleContact('repair')">
            <view class="contact-icon-wrapper contact-icon-3">
              <text class="iconfont icon-cog" style="color: #fff; font-size: 44rpx;"></text>
            </view>
            <text class="contact-text">报修服务</text>
          </view>
        </view>
      </view> -->

      <!-- 智能场景 -->
      <!-- <view class="section">
        <text class="section-title">智能场景</text>
        <view class="scene-grid">
          <view class="scene-item" @click="handleScene('home')">
            <view class="scene-icon-wrapper scene-icon-1">
              <text class="iconfont icon-fa-home" style="color: #fff; font-size: 48rpx;"></text>
            </view>
            <text class="scene-title">回家模式</text>
            <text class="scene-desc">自动开门+灯光</text>
          </view>
          <view class="scene-item" @click="handleScene('away')">
            <view class="scene-icon-wrapper scene-icon-2">
              <text class="iconfont icon-fa-key" style="color: #fff; font-size: 48rpx;"></text>
            </view>
            <text class="scene-title">离家模式</text>
            <text class="scene-desc">全部门锁检查</text>
          </view>
        </view>
      </view> -->
      </view>
    </scroll-view>

    <!-- 服务协议和隐私政策弹框 -->
    <uni-popup ref="agreementPopup" type="center" :mask-click="false">
      <view class="agreement-popup">
        <view class="agreement-title">服务协议和隐私政策</view>
        <view class="agreement-content">
          欢迎使用玉龙智眸。我们非常重视您的个人信息和隐私保护。在您使用"服务"之前，请务必仔细阅读
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

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const deviceStore = proxy.$store.device.useDeviceStore()
const agreementStore = proxy.$store.agreement.useAgreementStore()
const agreementPopup = ref(null)
const notificationCount = ref(3)
const roomList = ref([])
const loading = ref(false)
const deviceOpenCounts = ref({}) // 存储设备开门次数

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

// 获取使用最频繁的前3个设备
const top3Devices = computed(() => {
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
  
  // 按开门次数排序，取前3个
  return formattedList.sort((a, b) => b.openCount - a.openCount).slice(0, 3)
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
  uni.switchTab({
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

// 处理同意协议
const handleAgree = () => {
  agreementStore.setAgreement(true)
  agreementPopup.value.close()
  // 同意协议后检查登录状态（只在首次同意时检查）
  if (!userStore.isLogin) {
    userStore.checkLogin()
  } else {
    loadRoomList()
  }
}

// 处理不同意协议
const handleDisagree = () => {
  uni.showModal({
    title: '提示',
    content: '您需要同意服务协议和隐私政策才能使用本应用',
    showCancel: false,
    confirmText: '我知道了',
    success: () => {
      // 如果用户是第一次打开应用，点击不同意后退出应用
      if (!agreementStore.checkAgreement()) {
        // #ifdef APP-PLUS
        plus.runtime.quit()
        // #endif
        // #ifdef H5
        window.location.reload()
        // #endif
      }
    }
  })
}

onLoad(async () => {
  console.log('首页加载')
  // 检查版本更新
  checkAppUpdate()
  // 加载开门次数
  loadDeviceOpenCounts()
})

// 在组件挂载后检查首次打开状态
onMounted(() => {
  checkFirstOpen()
})

// 页面显示时刷新房屋列表（从设备页面返回时可能需要更新，但不检查登录）
onShow(async () => {
  // 重新加载开门次数（从开门页面返回时更新）
  loadDeviceOpenCounts()
  // 只刷新数据，不再检查登录（避免重复跳转）
  if (userStore.isLogin && agreementStore.checkAgreement()) {
    // 刷新用户房屋列表和设备列表
    try {
      await userStore.updateRoomList({ showLoading: false })
    } catch (error) {
      console.log('更新房屋列表失败:', error)
    }
    await loadRoomList()
  }
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.page-container {
  height: 100vh;
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%);
}

.app-content {
  height: 100%;
  background: transparent;
}

.header-section {
  padding: 40rpx 40rpx 0;
}

.header-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 48rpx;
}

.header-left {
  flex: 1;
}

.app-title {
  display: block;
  font-size: 64rpx;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 8rpx;
}

.app-subtitle {
  display: block;
  font-size: 28rpx;
  color: #64748b;
  opacity: 0.6;
}

.header-right {
  display: flex;
  gap: 24rpx;
  align-items: center;
}

.header-btn {
  width: 92rpx;
  height: 92rpx;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8rpx 24rpx rgba(102, 126, 234, 0.4);
}

.header-btn-notify {
  width: 80rpx;
  height: 80rpx;
  border-radius: 50%;
  background: rgba(102, 126, 234, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.badge {
  position: absolute;
  top: -10rpx;
  right: -10rpx;
  background: #ff3b30;
  color: white;
  border-radius: 20rpx;
  padding: 4rpx 12rpx;
  font-size: 20rpx;
  font-weight: bold;
  min-width: 32rpx;
  text-align: center;
}

.section {
  padding: 0 40rpx 48rpx;
}

.section-title {
  display: block;
  color: #1e293b;
  font-size: 36rpx;
  font-weight: 600;
  margin-bottom: 32rpx;
}

.action-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 24rpx;
}

.action-btn {
  background: white;
  border-radius: 32rpx;
  padding: 48rpx 32rpx;
  text-align: center;
  color: #1e293b;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

.device-status-badge {
  position: absolute;
  top: 16rpx;
  right: 16rpx;
  display: flex;
  align-items: center;
  gap: 8rpx;
  padding: 8rpx 16rpx;
  border-radius: 20rpx;
  font-size: 20rpx;
}

.device-status-badge.online {
  background: rgba(52, 199, 89, 0.1);
  color: #34c759;
}

.device-status-badge.offline {
  background: rgba(148, 163, 184, 0.1);
  color: #94a3b8;
}

.status-dot-small {
  width: 12rpx;
  height: 12rpx;
  border-radius: 50%;
}

.device-status-badge.online .status-dot-small {
  background: #34c759;
  box-shadow: 0 0 12rpx rgba(52, 199, 89, 0.6);
}

.device-status-badge.offline .status-dot-small {
  background: #94a3b8;
}

.status-text-small {
  font-size: 20rpx;
  font-weight: 500;
}

.action-title {
  display: block;
  font-size: 28rpx;
  font-weight: 500;
  margin-top: 16rpx;
}

.action-desc {
  display: block;
  font-size: 22rpx;
  opacity: 0.6;
  margin-top: 8rpx;
}

.ad-banner {
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
  border-radius: 32rpx;
  padding: 40rpx;
  box-shadow: 0 16rpx 40rpx rgba(139, 92, 246, 0.3);
  position: relative;
  overflow: hidden;
}

.ad-bg-circle {
  position: absolute;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
}

.ad-circle-1 {
  top: -50rpx;
  right: -50rpx;
  width: 200rpx;
  height: 200rpx;
}

.ad-circle-2 {
  bottom: -30rpx;
  left: -30rpx;
  width: 140rpx;
  height: 140rpx;
  background: rgba(255, 255, 255, 0.08);
}

.ad-content {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.ad-left {
  flex: 1;
}

.ad-tag {
  display: block;
  font-size: 24rpx;
  color: rgba(255, 255, 255, 0.9);
  font-weight: 500;
  margin-bottom: 8rpx;
}

.ad-title {
  display: block;
  font-size: 38rpx;
  font-weight: 700;
  color: white;
  margin-bottom: 12rpx;
}

.ad-desc {
  display: block;
  font-size: 26rpx;
  color: rgba(255, 255, 255, 0.95);
}

.ad-icon-wrapper {
  width: 120rpx;
  height: 120rpx;
  background: rgba(255, 255, 255, 0.2);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  backdrop-filter: blur(20rpx);
}

.notice-card {
  background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
  border-radius: 32rpx;
  padding: 32rpx;
  display: flex;
  align-items: flex-start;
}

.notice-icon-wrapper {
    width: 80rpx;
    height: 80rpx;
  border-radius: 20rpx;
  background: rgba(255, 255, 255, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
  margin-right: 24rpx;
  flex-shrink: 0;
}

.notice-content {
  flex: 1;
}

.notice-title {
  display: block;
  font-weight: 600;
  margin-bottom: 12rpx;
  color: #92400e;
  font-size: 32rpx;
}

.notice-text {
  display: block;
  font-size: 26rpx;
  color: #78350f;
  line-height: 1.5;
  margin-bottom: 12rpx;
}

.notice-footer {
  display: block;
  font-size: 22rpx;
  color: #b45309;
}

.house-card {
  background: white;
  border-radius: 32rpx;
  padding: 32rpx;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
}

.visitor-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.visitor-icon-wrapper {
  width: 112rpx;
  height: 112rpx;
  border-radius: 28rpx;
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 28rpx;
}

.visitor-text {
  flex: 1;
}

.visitor-title {
  display: block;
  font-weight: 600;
  font-size: 32rpx;
  margin-bottom: 8rpx;
  color: #1e293b;
}

.visitor-desc {
  display: block;
  font-size: 26rpx;
  color: #64748b;
}

.contact-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24rpx;
}

.contact-item {
  background: white;
  border-radius: 32rpx;
  padding: 40rpx 24rpx;
  text-align: center;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
}

.contact-icon-wrapper {
  width: 96rpx;
  height: 96rpx;
  border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  margin: 0 auto 20rpx;
}

.contact-icon-1 {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
    }

.contact-icon-2 {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
    }

.contact-icon-3 {
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
  }

.contact-text {
  font-size: 26rpx;
  font-weight: 600;
  color: #1e293b;
}

.scene-grid {
  display: flex;
  gap: 24rpx;
}

.scene-item {
  flex: 1;
  background: white;
  border-radius: 32rpx;
  padding: 32rpx;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
    display: flex;
    flex-direction: column;
  align-items: center;
  text-align: center;
}

.scene-icon-wrapper {
  width: 100rpx;
  height: 100rpx;
  border-radius: 24rpx;
  display: flex;
    align-items: center;
    justify-content: center;
  margin-bottom: 20rpx;
}

.scene-icon-1 {
  background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
}

.scene-icon-2 {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
}

.scene-title {
  display: block;
  font-weight: 600;
  font-size: 28rpx;
  color: #1e293b;
  margin-bottom: 8rpx;
}

.scene-desc {
  display: block;
  font-size: 22rpx;
  color: #64748b;
}

// 空状态样式
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 120rpx 80rpx;
  text-align: center;
}

.empty-icon-wrapper {
  width: 160rpx;
  height: 160rpx;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32rpx;
  box-shadow: 0 20rpx 60rpx rgba(102, 126, 234, 0.3);
}

.empty-title {
  display: block;
  font-size: 36rpx;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 16rpx;
}

.empty-desc {
  display: block;
  font-size: 26rpx;
  color: #64748b;
  line-height: 1.6;
  margin-bottom: 48rpx;
}

.empty-btn-wrapper {
  width: 100%;
  max-width: 600rpx;
  margin-bottom: 60rpx;
}

.empty-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 36rpx 96rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 28rpx;
  font-size: 34rpx;
  font-weight: 600;
  box-shadow: 0 20rpx 48rpx rgba(102, 126, 234, 0.35);
}

.steps-guide {
  width: 100%;
  max-width: 600rpx;
  background: #f8fafc;
  border-radius: 24rpx;
  padding: 40rpx;
  border: 1px solid rgba(0, 0, 0, 0.08);
}

.steps-title {
  display: block;
  font-size: 26rpx;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 24rpx;
}

.step-item {
  display: flex;
  align-items: flex-start;
  margin-bottom: 20rpx;
}

.step-item:last-child {
  margin-bottom: 0;
}

.step-number {
  width: 48rpx;
  height: 48rpx;
  border-radius: 50%;
  background: #667eea;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  font-weight: 600;
  margin-right: 20rpx;
  flex-shrink: 0;
}

.step-text {
  font-size: 26rpx;
  color: #64748b;
  text-align: left;
  line-height: 1.5;
}

// 快捷功能区样式
.quick-functions {
  display: flex;
  flex-direction: column;
  gap: 24rpx;
}

.function-card {
  background: white;
  border-radius: 32rpx;
  padding: 32rpx;
  display: flex;
  align-items: center;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 8rpx 24rpx rgba(0, 0, 0, 0.08);
  
  &.primary {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border: none;
    box-shadow: 0 12rpx 32rpx rgba(102, 126, 234, 0.4);
  }
}

.function-icon-wrapper {
  width: 96rpx;
  height: 96rpx;
  border-radius: 24rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 28rpx;
  
  &.primary-gradient {
    background: rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(20rpx);
  }
}

.function-text {
  flex: 1;
}

.function-title {
  display: block;
  font-size: 32rpx;
  font-weight: 700;
  color: white;
  margin-bottom: 8rpx;
}

.function-desc {
  display: block;
  font-size: 24rpx;
  color: rgba(255, 255, 255, 0.9);
}

.function-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20rpx;
}

.function-item {
  background: white;
  border-radius: 24rpx;
  padding: 32rpx 24rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
}

.function-icon-small {
  width: 80rpx;
  height: 80rpx;
  border-radius: 20rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16rpx;
  
  &.icon-green {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  }
  
  &.icon-blue {
    background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
  }
  
  &.icon-purple {
    background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
  }
}

.function-name {
  font-size: 24rpx;
  font-weight: 600;
  color: #1e293b;
  text-align: center;
}

// 服务协议弹框样式
.agreement-popup {
  width: 600rpx;
  background: #FFFFFF;
  border-radius: 24rpx;
  padding: 40rpx;
  box-sizing: border-box;

  .agreement-title {
    font-size: 32rpx;
    font-weight: 600;
    color: #1e293b;
    text-align: center;
    margin-bottom: 30rpx;
  }

  .agreement-content {
    font-size: 28rpx;
    color: #64748b;
    line-height: 1.8;
    margin-bottom: 40rpx;
    text-align: justify;

    .link {
      color: #667eea;
      font-weight: 600;
      padding: 0 4rpx;
    }
  }

  .agreement-buttons {
    display: flex;
    gap: 20rpx;

    button {
      flex: 1;
      height: 88rpx;
      line-height: 88rpx;
      text-align: center;
      border-radius: 24rpx;
      font-size: 28rpx;
      font-weight: 600;
      border: none;

      &::after {
        border: none;
      }

      &.btn-disagree {
        background: #f1f5f9;
        color: #64748b;

        &:active {
          background: #e2e8f0;
        }
      }

      &.btn-agree {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: #FFFFFF;
        box-shadow: 0 8rpx 24rpx rgba(102, 126, 234, 0.3);

        &:active {
          opacity: 0.9;
        }
      }
    }
  }
}
</style>
