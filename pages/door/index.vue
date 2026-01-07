<template>
  <view class="door-container">
    <scroll-view class="door-content" scroll-y>
      <!-- Header -->
      <view class="header-section">
        <text class="page-title">门禁设备</text>
        <text class="page-subtitle">选择要开启的门禁</text>
      </view>

      <!-- 搜索框 -->
      <view class="search-section">
        <view class="search-box">
          <text class="iconfont icon-search" style="color: #94a3b8; font-size: 32rpx;"></text>
          <input 
            class="search-input"
            type="text" 
            v-model="searchKey" 
            placeholder="搜索设备名称或地址" 
            placeholder-class="search-placeholder"
          />
          <text 
            v-if="searchKey" 
            class="iconfont icon-fasfa-times-circle" 
            style="color: #94a3b8; font-size: 32rpx;"
            @click="clearSearch"
          ></text>
        </view>
      </view>

      <!-- 广告位 -->
      <!-- <view class="section">
        <view class="ad-banner" @click="handleAdClick">
          <view class="ad-bg-circle ad-circle-1"></view>
          <view class="ad-bg-circle ad-circle-2"></view>
          <view class="ad-content">
            <view class="ad-left">
              <text class="ad-tag">智能升级</text>
              <text class="ad-title">人脸识别门禁系统</text>
              <text class="ad-desc">无接触开门 · 更安全更便捷</text>
            </view>
            <view class="ad-icon-wrapper">
              <text class="iconfont icon-fa-user-circle-o" style="color: #fff; font-size: 60rpx;"></text>
            </view>
          </view>
        </view>
      </view> -->

      <!-- 设备列表 -->
      <view class="section">
        <!-- 空状态 -->
        <view v-if="filteredDeviceList.length === 0" class="empty-device-state">
          <view class="empty-device-icon">
            <text class="iconfont icon-door-open" style="color: #94a3b8; font-size: 80rpx;"></text>
          </view>
          <text class="empty-device-title">{{ searchKey ? '未找到匹配的设备' : '暂无门禁设备' }}</text>
          <text class="empty-device-desc">{{ searchKey ? '请尝试其他关键词' : '请先在设备页面添加门禁设备' }}</text>
        </view>
        
        <!-- 设备卡片 -->
        <view 
          v-else
          class="device-card" 
          v-for="(device, index) in filteredDeviceList" 
          :key="index"
          @click="handleQuickUnlock(device)"
        >
          <view class="device-header">
            <view class="device-icon-wrapper" :style="{ background: device.iconGradient }">
              <text class="iconfont" :class="device.icon" style="color: #fff; font-size: 56rpx;"></text>
            </view>
            <view class="device-info">
              <view class="device-title-row">
                <text class="device-name">{{ device.name }}</text>
                <view class="status-indicator" :class="device.online === '1' ? 'status-online' : 'status-offline'"></view>
              </view>
              <text class="device-location">{{ device.location }}</text>
            </view>
            <text class="iconfont icon-fasfa-chevron-rightCopy" style="color: #94a3b8; font-size: 36rpx; opacity: 0.3;"></text>
          </view>
          <view class="device-stats">
            <view class="stat-item">
              <text class="stat-label">信号</text>
              <text class="stat-value">{{ device.signal }}</text>
            </view>
            <view class="stat-item">
              <text class="stat-label">状态</text>
              <text class="stat-value">{{ device.online === '1' ? '在线' : '离线' }}</text>
            </view>
          </view>
        </view>
      </view>
    </scroll-view>

    <!-- 开门成功弹窗 -->
    <uni-popup ref="successPopup" type="center" :mask-click="true">
      <view class="modal-content success-modal">
        <view class="success-content">
          <view class="success-icon-wrapper">
            <text class="success-icon">✓</text>
          </view>
          <text class="success-title">开锁成功！</text>
          <text class="success-device" v-if="currentDevice">{{ currentDevice.name }}</text>
          <text class="success-method">远程开门 · 门锁已打开</text>
          <button class="success-btn" @click="closeSuccessModal">完成</button>
        </view>
      </view>
    </uni-popup>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import doorAccessUtils from '@/utils/doorAccessUtils'

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const deviceStore = proxy.$store.device.useDeviceStore()

const successPopup = ref(null)
const currentDevice = ref(null)
const searchKey = ref('')

// 获取设备开门次数
const getDeviceOpenCount = (doorMac) => {
  try {
    const counts = uni.getStorageSync('device_open_counts') || {}
    return counts[doorMac] || 0
  } catch (e) {
    return 0
  }
}

// 更新设备开门次数
const updateDeviceOpenCount = (doorMac) => {
  try {
    const counts = uni.getStorageSync('device_open_counts') || {}
    counts[doorMac] = (counts[doorMac] || 0) + 1
    uni.setStorageSync('device_open_counts', counts)
    console.log('开门次数已更新:', doorMac, counts[doorMac])
  } catch (e) {
    console.error('更新开门次数失败:', e)
  }
}

// 从 store 获取设备列表并格式化
const deviceList = computed(() => {
  if (!deviceStore.deviceList || deviceStore.deviceList.length === 0) {
    return []
  }
  
  const formattedList = deviceStore.deviceList.map((device, index) => {
    // 拼接地址：小区名 + 单元名
    const location = `${device.comm_name || ''}${device.unit_name || ''}`.trim() || '未知位置'
    
    // 判断是否为单元机：检查 unit_name 或地址中是否包含"单元"
    const isUnitDoor = (device.unit_name && device.unit_name.includes('单元')) || 
                       location.includes('单元')
    
    // 根据设备类型和索引分配不同的图标和渐变色
    let icon, iconGradient
    
    if (isUnitDoor) {
      // 单元机 - 使用建筑图标
      const unitThemes = [
        {
          icon: 'icon-fasfa-building',
          iconGradient: 'linear-gradient(135deg, #34c759 0%, #30d158 100%)'
        },
        {
          icon: 'icon-fasfa-building',
          iconGradient: 'linear-gradient(135deg, #0a84ff 0%, #0066cc 100%)'
        },
        {
          icon: 'icon-fasfa-building',
          iconGradient: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)'
        }
      ]
      const theme = unitThemes[index % unitThemes.length]
      icon = theme.icon
      iconGradient = theme.iconGradient
    } else {
      // 大门机 - 使用门图标
      const gateThemes = [
        {
          icon: 'icon-door-open',
          iconGradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
        },
        {
          icon: 'icon-door-open',
          iconGradient: 'linear-gradient(135deg, #ff9500 0%, #ff6b00 100%)'
        },
        {
          icon: 'icon-door-open',
          iconGradient: 'linear-gradient(135deg, #ff2d55 0%, #ff375f 100%)'
        }
      ]
      const theme = gateThemes[index % gateThemes.length]
      icon = theme.icon
      iconGradient = theme.iconGradient
    }
    
    // 获取该设备的开门次数
    const openCount = getDeviceOpenCount(device.door_mac)
    
    return {
      ...device,
      name: device.door_name || '门禁设备',
      location: location,
      icon: icon,
      iconGradient: iconGradient,
      signal: device.online === '1' ? '优秀' : '离线',
      distance: '未知',
      todayCount: 0,
      openCount: openCount, // 开门次数
      isUnitDoor: isUnitDoor // 保存设备类型标识
    }
  })
  
  // 按开门次数排序（从高到低）
  return formattedList.sort((a, b) => b.openCount - a.openCount)
})

// 过滤后的设备列表（支持搜索）
const filteredDeviceList = computed(() => {
  if (!searchKey.value) {
    return deviceList.value
  }
  
  const keyword = searchKey.value.toLowerCase().trim()
  return deviceList.value.filter(device => {
    const nameMatch = device.name.toLowerCase().includes(keyword)
    const locationMatch = device.location.toLowerCase().includes(keyword)
    return nameMatch || locationMatch
  })
})

// 清除搜索
const clearSearch = () => {
  searchKey.value = ''
}

// 一键快速开门
const handleQuickUnlock = async (device) => {
  currentDevice.value = device
  
  // 检查登录状态（不自动跳转）
  if (!userStore.isLogin) {
    uni.showToast({
      title: '请先登录',
      icon: 'none'
    })
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
    console.log('一键开门:', device)
    
    // 显示开门中提示
    uni.showLoading({
      title: '开门中...',
      mask: true
    })
    
    // 调用远程开门接口
    await doorAccessUtils.openDoor(device)
    
    // 隐藏加载提示
    uni.hideLoading()
    
    // 开门成功后更新开门次数
    updateDeviceOpenCount(device.door_mac)
    
    // 显示成功弹窗
    setTimeout(() => {
      successPopup.value.open()
    }, 300)
  } catch (error) {
    console.error('开门失败:', error)
    uni.hideLoading()
    
    // 开门失败的错误提示已经在 doorAccessUtils.openDoor 中处理
    // 这里不再重复显示
  }
}

// 关闭成功弹窗
const closeSuccessModal = () => {
  successPopup.value.close()
  currentDevice.value = null
}

// 广告点击
const handleAdClick = () => {
  console.log('广告点击')
  uni.showToast({
    title: '敬请期待',
    icon: 'none'
  })
}

// 加载设备列表
const loadDeviceList = async () => {
  if (!userStore.isLogin) {
    return
  }
  
  // 如果设备列表为空，可以在这里重新加载
  if (deviceStore.deviceList.length === 0) {
    console.log('设备列表为空，请先在设备页面添加设备')
  }
}

onLoad(async () => {
  console.log('开门页面加载')
  // 只加载数据，不检查登录跳转
  await loadDeviceList()
})

onShow(async () => {
  // 页面显示时刷新设备列表和房屋列表
  if (userStore.isLogin) {
    try {
      // 刷新用户房屋列表和设备列表
      await userStore.updateRoomList({ showLoading: false })
    } catch (error) {
      console.log('更新房屋和设备列表失败:', error)
    }
    await loadDeviceList()
  }
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.door-container {
  height: 100vh;
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%);
}

.door-content {
  height: 100%;
  background: transparent;
}

.header-section {
  padding: 40rpx 40rpx 0;
}

.page-title {
  display: block;
  font-size: 56rpx;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 16rpx;
}

.page-subtitle {
  display: block;
  font-size: 28rpx;
  color: #64748b;
  opacity: 0.6;
}

.search-section {
  padding: 32rpx 40rpx;
}

.search-box {
  background: white;
  border-radius: 24rpx;
  padding: 24rpx 32rpx;
  display: flex;
  align-items: center;
  gap: 20rpx;
  border: 2rpx solid rgba(0, 0, 0, 0.06);
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.04);
}

.search-input {
  flex: 1;
  font-size: 28rpx;
  color: #1e293b;
  height: 40rpx;
  line-height: 40rpx;
}

.search-placeholder {
  color: #94a3b8;
  font-size: 28rpx;
}

.section {
  padding: 0 40rpx 48rpx;
}

.ad-banner {
  background: linear-gradient(135deg, #ec4899 0%, #f43f5e 100%);
  border-radius: 32rpx;
  padding: 40rpx;
  box-shadow: 0 16rpx 40rpx rgba(236, 72, 153, 0.3);
  position: relative;
  overflow: hidden;
  margin-bottom: 48rpx;
}

.ad-bg-circle {
  position: absolute;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
}

.ad-circle-1 {
  top: -60rpx;
  right: -60rpx;
  width: 240rpx;
  height: 240rpx;
}

.ad-circle-2 {
  bottom: -40rpx;
  left: -40rpx;
  width: 160rpx;
  height: 160rpx;
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

.device-card {
  background: white;
  border-radius: 32rpx;
  padding: 40rpx;
  margin-bottom: 32rpx;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
}

.device-header {
  display: flex;
  align-items: center;
  margin-bottom: 24rpx;
}

.device-icon-wrapper {
  width: 112rpx;
  height: 112rpx;
  border-radius: 28rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 32rpx;
}

.device-info {
  flex: 1;
}

.device-title-row {
  display: flex;
  align-items: center;
  margin-bottom: 8rpx;
}

.device-name {
  font-size: 36rpx;
  font-weight: 600;
  color: #1e293b;
  margin-right: 16rpx;
}

.status-indicator {
  width: 16rpx;
  height: 16rpx;
  border-radius: 50%;
}

.status-online {
  background: #34c759;
  box-shadow: 0 0 16rpx rgba(52, 199, 89, 0.5);
}

.status-offline {
  background: #94a3b8;
  box-shadow: 0 0 16rpx rgba(148, 163, 184, 0.5);
}

.device-location {
  font-size: 26rpx;
  color: #64748b;
  opacity: 0.6;
}

.device-stats {
  display: flex;
  gap: 24rpx;
  padding-top: 24rpx;
  border-top: 1px solid rgba(0, 0, 0, 0.05);
}

.stat-item {
  flex: 1;
  text-align: center;
}

.stat-label {
  display: block;
  color: #64748b;
  font-size: 22rpx;
  margin-bottom: 8rpx;
}

.stat-value {
  display: block;
  color: #1e293b;
  font-size: 26rpx;
  font-weight: 600;
}

// 成功弹窗
.modal-content {
  width: 700rpx;
  background: white;
  border-radius: 40rpx;
  padding: 60rpx;
  position: relative;
}
.success-modal {
  text-align: center;
}

.success-content {
  padding: 40rpx 0;
}

.success-icon-wrapper {
  width: 160rpx;
  height: 160rpx;
  border-radius: 50%;
  background: rgba(52, 199, 89, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto;
}

.success-icon {
  font-size: 120rpx;
  color: #34c759;
  font-weight: bold;
  line-height: 1;
}

.success-title {
  display: block;
  font-size: 56rpx;
  font-weight: 700;
  color: #1e293b;
  margin: 32rpx 0 16rpx;
}

.success-device {
  display: block;
  font-size: 32rpx;
  color: #64748b;
  opacity: 0.6;
  margin-bottom: 12rpx;
}

.success-method {
  display: block;
  font-size: 26rpx;
  color: #64748b;
  opacity: 0.5;
  margin-bottom: 60rpx;
}

.success-btn {
  width: 100%;
  padding: 32rpx;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 24rpx;
  font-size: 32rpx;
  font-weight: 600;
  box-shadow: 0 16rpx 40rpx rgba(102, 126, 234, 0.4);
}

.success-btn::after {
  border: none;
}

// 空设备状态
.empty-device-state {
  padding: 120rpx 60rpx;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.empty-device-icon {
  width: 160rpx;
  height: 160rpx;
  border-radius: 50%;
  background: rgba(148, 163, 184, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32rpx;
}

.empty-device-title {
  font-size: 32rpx;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 16rpx;
}

.empty-device-desc {
  font-size: 26rpx;
  color: #64748b;
  opacity: 0.6;
}
</style>