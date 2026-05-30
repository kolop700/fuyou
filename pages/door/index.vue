<template>
  <view
    class="door-container"
    :class="{ 'dark-mode': isDarkMode }"
    :style="{ background: theme.bgPrimary }"
  >
    <!-- 自定义导航栏 -->
    <custom-navbar title="门禁设备" />
    
    <scroll-view
      class="door-content"
      scroll-y
      :style="{ paddingTop: navbarHeight + 'px' }"
      refresher-enabled
      :refresher-triggered="isRefreshing"
      @refresherrefresh="onRefresh"
    >
      <!-- Header -->
      <view class="header-section">
        <text class="page-title" :style="{ color: theme.textPrimary }">门禁设备</text>
        <text class="page-subtitle" :style="{ color: theme.textSecondary }">选择要开启的门禁</text>
      </view>

      <!-- 搜索框 -->
      <view class="search-section">
        <view class="search-box" :style="{ background: theme.bgInput, borderColor: theme.borderColor }">
          <text class="iconfont icon-search" :style="{ color: theme.textTertiary, fontSize: '32rpx' }"></text>
          <input 
            class="search-input"
            :style="{ color: theme.textPrimary }"
            type="text" 
            v-model="searchKey" 
            placeholder="搜索设备名称或地址" 
            placeholder-class="search-placeholder"
          />
          <text 
            v-if="searchKey" 
            class="iconfont icon-fasfa-times-circle" 
            :style="{ color: theme.textTertiary, fontSize: '32rpx' }"
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
            <text class="iconfont icon-door-open" :style="{ color: theme.textTertiary, fontSize: '80rpx' }"></text>
          </view>
          <text class="empty-device-title" :style="{ color: theme.textPrimary }">{{ searchKey ? '未找到匹配的设备' : '暂无门禁设备' }}</text>
          <text class="empty-device-desc" :style="{ color: theme.textSecondary }">{{ searchKey ? '请尝试其他关键词' : '请先在设备页面添加门禁设备' }}</text>
        </view>
        
        <!-- 设备卡片 -->
        <view
          v-else
          class="device-card"
          :class="{ 'device-card-offline': !device.isOnline }"
          :style="{ background: theme.bgCard, borderColor: theme.borderColor, boxShadow: theme.shadowCard }"
          v-for="(device, index) in filteredDeviceList"
          :key="device.door_id || device.door_mac || index"
          @click="handleQuickUnlock(device)"
        >
          <view v-if="!device.isOnline" class="offline-rail"></view>
          <view class="device-header">
            <view class="device-icon-wrapper" :class="{ 'device-icon-offline': !device.isOnline }">
              <text class="iconfont icon-door-closed device-icon"></text>
            </view>
            <view class="device-info">
              <view class="device-title-row">
                <text class="device-name" :style="{ color: theme.textPrimary }">{{ device.name }}</text>
                <view class="status-pill" :class="device.isOnline ? 'status-online-pill' : 'status-offline-pill'">
                  <view class="status-indicator" :class="device.isOnline ? 'status-online' : 'status-offline'"></view>
                  <text class="status-pill-text">{{ device.statusText }}</text>
                </view>
              </view>
              <text class="device-location" :style="{ color: theme.textSecondary }">{{ device.location }}</text>
            </view>
            <text class="iconfont icon-fasfa-chevron-rightCopy" :style="{ color: theme.textTertiary, fontSize: '36rpx', opacity: '0.3' }"></text>
          </view>
        </view>
      </view>
    </scroll-view>
    
    <!-- 自定义底部标签栏 -->
    <custom-tabbar />
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import doorAccessUtils from '@/utils/doorAccessUtils'
import { useThemeVars } from '@/utils/themeConfig.js'
import { formatDoorDevice, sortDoorDevices } from '@/utils/deviceDisplayUtils.js'
import { showOfflinePasswordModal, showOpenDoorFailModal } from '@/utils/offlinePasswordUtils.js'

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const deviceStore = proxy.$store.device.useDeviceStore()
const themeStore = proxy.$store.theme.useThemeStore()

// 主题变量
const isDarkMode = computed(() => themeStore.isDark())
const theme = computed(() => useThemeVars(isDarkMode.value))

const currentDevice = ref(null)
const searchKey = ref('')
const isRefreshing = ref(false)

// 导航栏高度
const navbarHeight = ref(0)

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
    return formatDoorDevice(device, index, getDeviceOpenCount)
  })

  return sortDoorDevices(formattedList)
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
    const macMatch = device.door_mac?.toLowerCase().includes(keyword)
    const codeMatch = device.shortCode?.toLowerCase().includes(keyword)
    return nameMatch || locationMatch || macMatch || codeMatch
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
  if (!device.isOnline) {
    showOfflinePasswordModal(device)
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
    
    // 成功提示在 utils 里面已经报了
  } catch (error) {
    console.error('设备列表页开门失败:', error)
    uni.hideLoading()
    // 开门失败时弹出离线密码备选
    showOfflinePasswordModal(device)
  } finally {
    currentDevice.value = null
  }
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

const onRefresh = async () => {
  if (!userStore.isLogin) {
    isRefreshing.value = false
    return
  }

  isRefreshing.value = true
  try {
    await userStore.updateRoomList({ showLoading: false })
    await loadDeviceList()
    uni.showToast({
      title: '刷新成功',
      icon: 'success',
      duration: 1000
    })
  } catch (error) {
    console.log('刷新门禁设备失败:', error)
    uni.showToast({
      title: '刷新失败',
      icon: 'none'
    })
  } finally {
    isRefreshing.value = false
  }
}

onLoad(async () => {
  console.log('开门页面加载')
  // 计算导航栏高度
  const systemInfo = uni.getSystemInfoSync()
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44
  // 只加载数据，不检查登录跳转
  await loadDeviceList()
})

onShow(async () => {
  // 隐藏原生TabBar
  uni.hideTabBar({
    animation: false
  })
  
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

.dark-mode .search-box {
  box-shadow: 0 8rpx 24rpx rgba(0, 0, 0, 0.28);
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

.dark-mode .search-placeholder {
  color: #64748b;
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
  position: relative;
  overflow: hidden;
}

.device-card-offline {
  background: #f8fafc !important;
  border-color: rgba(148, 163, 184, 0.24) !important;
  box-shadow: 0 6rpx 20rpx rgba(100, 116, 139, 0.08) !important;
}

.dark-mode .device-card-offline {
  background: rgba(15, 23, 42, 0.92) !important;
  border-color: rgba(148, 163, 184, 0.22) !important;
  box-shadow: 0 8rpx 28rpx rgba(0, 0, 0, 0.32) !important;
}

.offline-rail {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 8rpx;
  background: #94a3b8;
}

.dark-mode .offline-rail {
  background: #64748b;
}

.device-header {
  display: flex;
  align-items: center;
}

.device-icon-wrapper {
  width: 112rpx;
  height: 112rpx;
  border-radius: 28rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 32rpx;
  background: rgba(14, 165, 233, 0.1);
  border: 1px solid rgba(14, 165, 233, 0.18);
}

.dark-mode .device-icon-wrapper {
  background: rgba(56, 189, 248, 0.14);
  border-color: rgba(56, 189, 248, 0.24);
}

.device-icon {
  color: #0ea5e9;
  font-size: 58rpx;
}

.dark-mode .device-icon {
  color: #38bdf8;
}

.device-icon-offline {
  background: rgba(148, 163, 184, 0.12);
  border-color: rgba(148, 163, 184, 0.22);
}

.dark-mode .device-icon-offline {
  background: rgba(148, 163, 184, 0.1);
  border-color: rgba(148, 163, 184, 0.18);
}

.device-icon-offline .device-icon {
  color: #94a3b8;
}

.device-info {
  flex: 1;
  min-width: 0;
}

.device-title-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
  margin-bottom: 8rpx;
}

.device-name {
  flex: 1;
  min-width: 0;
  display: block;
  font-size: 36rpx;
  font-weight: 600;
  color: #1e293b;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.status-indicator {
  width: 16rpx;
  height: 16rpx;
  border-radius: 50%;
  flex-shrink: 0;
}

.status-pill {
  display: flex;
  align-items: center;
  gap: 8rpx;
  flex-shrink: 0;
  padding: 6rpx 14rpx;
  border-radius: 999rpx;
}

.status-online-pill {
  background: rgba(52, 199, 89, 0.12);
}

.dark-mode .status-online-pill {
  background: rgba(34, 197, 94, 0.16);
}

.status-offline-pill {
  background: rgba(100, 116, 139, 0.14);
}

.dark-mode .status-offline-pill {
  background: rgba(148, 163, 184, 0.16);
}

.status-pill-text {
  font-size: 22rpx;
  font-weight: 600;
  color: #64748b;
}

.status-online-pill .status-pill-text {
  color: #15803d;
}

.status-offline-pill .status-pill-text {
  color: #64748b;
}

.dark-mode .status-online-pill .status-pill-text {
  color: #86efac;
}

.dark-mode .status-offline-pill .status-pill-text {
  color: #cbd5e1;
}

.status-online {
  background: #34c759;
  box-shadow: 0 0 16rpx rgba(52, 199, 89, 0.5);
}

.status-offline {
  background: #64748b;
  box-shadow: 0 0 16rpx rgba(100, 116, 139, 0.4);
}

.device-location {
  display: block;
  font-size: 26rpx;
  color: #64748b;
  opacity: 0.6;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
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

.dark-mode .empty-device-icon {
  background: rgba(148, 163, 184, 0.12);
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
