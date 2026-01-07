<template>
  <view class="device-container">
    <scroll-view 
      class="device-content" 
      scroll-y
      refresher-enabled
      :refresher-triggered="isRefreshing"
      @refresherrefresh="onRefresh"
    >
      <!-- Header -->
      <view class="header-section">
        <view class="header-top">
          <view class="header-left">
            <text class="page-title">我的房屋</text>
            <text class="page-subtitle">管理您的房屋信息</text>
          </view>
          <view class="header-btn-add" @click="handleAddDevice">
            <text class="iconfont icon-fasfa-plus" style="color: #667eea; font-size: 40rpx;"></text>
          </view>
        </view>
      </view>

      <!-- 房屋认证卡片 -->
      <view class="section">
        <view class="certification-card" @click="handleCertification">
          <view class="cert-content">
            <view class="cert-icon-wrapper">
              <text class="iconfont icon-fa-home" style="color: #fff; font-size: 48rpx;"></text>
            </view>
            <view class="cert-text">
              <text class="cert-title">房屋认证</text>
              <text class="cert-desc">绑定新房屋或更新认证信息</text>
            </view>
            <text class="iconfont icon-fasfa-chevron-rightCopy" style="color: #fff; font-size: 32rpx;"></text>
          </view>
        </view>
      </view>

      <!-- 已认证房屋列表 -->
      <view class="section">
        <text class="section-title">已认证房屋</text>
        
        <!-- 空状态 -->
        <view v-if="deviceList.length === 0" class="empty-state">
          <view class="empty-icon">
            <text class="iconfont icon-fa-home" style="color: #94a3b8; font-size: 80rpx;"></text>
          </view>
          <text class="empty-title">暂无认证房屋</text>
          <text class="empty-desc">请点击上方"房屋认证"添加房屋</text>
        </view>
        
        <!-- 房屋卡片 -->
        <view v-else class="device-item" v-for="(item, index) in deviceList" :key="item.roomid">
          <view class="device-card-bg" :class="{
            'bg-success': item.statusType === 'normal',
            'bg-warning': item.statusType === 'expired',
            'bg-error': item.statusType === 'unauthorized'
          }"></view>
          <view class="device-content">
            <view class="device-icon-wrapper" :class="{
              'icon-success': item.statusType === 'normal',
              'icon-warning': item.statusType === 'expired',
              'icon-error': item.statusType === 'unauthorized'
            }">
              <text class="iconfont icon-fa-home" style="color: #fff; font-size: 44rpx;"></text>
            </view>
            <view class="device-info">
              <view class="device-title-row">
                <text class="device-name">{{ item.name }}</text>
                <view class="status-badge" :class="{
                  'badge-success': item.statusType === 'normal',
                  'badge-warning': item.statusType === 'expired',
                  'badge-error': item.statusType === 'unauthorized'
                }">
                  <view class="status-dot"></view>
                  <text class="status-badge-text">{{ item.statusText }}</text>
                </view>
              </view>
              <view class="device-meta">
                <view class="meta-item">
                  <text class="iconfont icon-fa-clock-o" style="color: #94a3b8; font-size: 24rpx; margin-right: 8rpx;"></text>
                  <text class="meta-text">{{ item.expire_date || '未设置' }}</text>
                </view>
              </view>
            </view>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, getCurrentInstance, onMounted } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()

// 房屋列表数据
const deviceList = ref([])

// 下拉刷新状态
const isRefreshing = ref(false)

// 格式化日期
const getDateOnly = (dateString) => {
  if (!dateString) return ''
  return dateString.split(' ')[0]
}

// 判断房屋状态
const getHouseStatus = (item) => {
  // 如果 status 为 '1'，表示权限正常
  if (item.status === '1') {
    return 'normal'
  }
  
  // 如果有过期日期，判断是否已过期
  if (item.expire_date) {
    const expireDate = new Date(item.expire_date)
    const now = new Date()
    
    // 清除时间部分，只比较日期
    expireDate.setHours(0, 0, 0, 0)
    now.setHours(0, 0, 0, 0)
    
    if (expireDate < now) {
      return 'expired' // 已过期
    }
  }
  
  // 其他情况视为未认证
  return 'unauthorized'
}

// 获取状态文本
const getStatusText = (status) => {
  switch (status) {
    case 'normal':
      return '认证成功'
    case 'expired':
      return '未认证'
    case 'unauthorized':
      return '未认证'
    default:
      return '未知'
  }
}

// 加载房屋列表
const loadHouseList = async () => {
  try {
    const data = await userStore.getUserRoomList()
    if (Array.isArray(data)) {
      deviceList.value = data.map(item => {
        const status = getHouseStatus(item)
        return {
          roomid: item.room_id,
          name: `${item.comm_name || ''}${item.unit_name || ''}${item.floor_name || ''}${item.room_name || ''}`,
          sn: `房间号: ${item.room_id}`,
          expire_date: getDateOnly(item.expire_date),
          online: status === 'normal',
          enabled: status === 'normal',
          battery: 90,
          signal: '良好',
          authority: item.status,
          statusType: status, // 状态类型：normal/expired/unauthorized
          statusText: getStatusText(status) // 状态文本
        }
      })
    }
  } catch (error) {
    console.error('获取房屋列表失败:', error)
    uni.showToast({
      title: '获取房屋列表失败',
      icon: 'none'
    })
  }
}

// 切换房屋状态
const toggleDevice = (index) => {
  uni.showToast({
    title: '该功能暂未开放',
    icon: 'none',
    duration: 1500
  })
}

// 添加房屋
const handleAddDevice = () => {
  uni.navigateTo({
    url: '/pages/house/apply'
  })
}

// 房屋认证
const handleCertification = () => {
  uni.navigateTo({
    url: '/pages/house/apply'
  })
}

// 下拉刷新
const onRefresh = async () => {
  isRefreshing.value = true
  try {
    // 刷新用户房屋列表数据
    await userStore.updateRoomList({ showLoading: false })
    await loadHouseList()
    uni.showToast({
      title: '刷新成功',
      icon: 'success',
      duration: 1000
    })
  } catch (error) {
    console.error('刷新失败:', error)
    uni.showToast({
      title: '刷新失败',
      icon: 'none'
    })
  } finally {
    isRefreshing.value = false
  }
}

onLoad(async () => {
  console.log('房屋页面加载')
  // 只检查登录状态，不自动跳转
  if (userStore.isLogin) {
    await loadHouseList()
  }
})

onShow(async () => {
  // 页面显示时刷新房屋列表
  if (userStore.isLogin) {
    await loadHouseList()
  }
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.device-container {
  height: 100vh;
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%);
}

.device-content {
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
}

.header-left {
  flex: 1;
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

.header-btn-add {
  width: 80rpx;
  height: 80rpx;
  border-radius: 50%;
  background: rgba(102, 126, 234, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
}

.section {
  padding: 0 40rpx 48rpx;
}

.certification-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 32rpx;
  padding: 40rpx;
  box-shadow: 0 20rpx 60rpx rgba(102, 126, 234, 0.25);
  margin-bottom: 48rpx;
  position: relative;
  overflow: hidden;
}

.certification-card::before {
  content: '';
  position: absolute;
  top: -50%;
  right: -20%;
  width: 400rpx;
  height: 400rpx;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
}

.certification-card::after {
  content: '';
  position: absolute;
  bottom: -30%;
  left: -10%;
  width: 300rpx;
  height: 300rpx;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 50%;
}

.cert-content {
  display: flex;
  align-items: center;
  color: white;
  position: relative;
  z-index: 1;
}

.cert-icon-wrapper {
  width: 96rpx;
  height: 96rpx;
  border-radius: 24rpx;
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 32rpx;
}

.cert-text {
  flex: 1;
}

.cert-title {
  display: block;
  font-size: 32rpx;
  font-weight: 600;
  margin-bottom: 8rpx;
}

.cert-desc {
  display: block;
  font-size: 24rpx;
  opacity: 0.8;
}

.section-title {
  display: block;
  color: #1e293b;
  font-size: 32rpx;
  font-weight: 600;
  margin-bottom: 24rpx;
}

.device-item {
  background: white;
  border-radius: 32rpx;
  margin-bottom: 24rpx;
  border: 1px solid rgba(0, 0, 0, 0.06);
  box-shadow: 0 8rpx 24rpx rgba(0, 0, 0, 0.06);
  overflow: hidden;
  position: relative;
  transition: all 0.3s;
}

.device-card-bg {
  position: absolute;
  top: 0;
  left: 0;
  width: 8rpx;
  height: 100%;
  z-index: 1;
}

.device-card-bg.bg-success {
  background: linear-gradient(180deg, #34c759 0%, #30d158 100%);
}

.device-card-bg.bg-warning {
  background: linear-gradient(180deg, #ff9500 0%, #ff8c00 100%);
}

.device-card-bg.bg-error {
  background: linear-gradient(180deg, #ff3b30 0%, #ff2d55 100%);
}

.device-content {
  padding: 32rpx;
  display: flex;
  align-items: center;
  position: relative;
  z-index: 2;
}

.device-icon-wrapper {
  width: 96rpx;
  height: 96rpx;
  border-radius: 24rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 24rpx;
  flex-shrink: 0;
  position: relative;
}

.device-icon-wrapper::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 24rpx;
  opacity: 0.1;
}

.icon-success {
  background: linear-gradient(135deg, #34c759 0%, #30d158 100%);
}

.icon-warning {
  background: linear-gradient(135deg, #ff9500 0%, #ff8c00 100%);
}

.icon-error {
  background: linear-gradient(135deg, #ff3b30 0%, #ff2d55 100%);
}

.device-info {
  flex: 1;
  min-width: 0;
}

.device-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16rpx;
  gap: 16rpx;
}

.device-name {
  font-size: 30rpx;
  font-weight: 600;
  color: #1e293b;
  line-height: 1.4;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.device-meta {
  display: flex;
  align-items: center;
  gap: 24rpx;
  flex-wrap: wrap;
}

.meta-item {
  display: flex;
  align-items: center;
  font-size: 24rpx;
  color: #64748b;
}

.meta-text {
  font-size: 24rpx;
  color: #64748b;
}

.status-badge {
  display: flex;
  align-items: center;
  gap: 8rpx;
  padding: 6rpx 16rpx;
  border-radius: 20rpx;
  flex-shrink: 0;
}

.badge-success {
  background: rgba(52, 199, 89, 0.15);
}

.badge-warning {
  background: rgba(255, 149, 0, 0.15);
}

.badge-error {
  background: rgba(255, 59, 48, 0.15);
}

.status-dot {
  width: 12rpx;
  height: 12rpx;
  border-radius: 50%;
}

.badge-success .status-dot {
  background: #34c759;
  box-shadow: 0 0 12rpx rgba(52, 199, 89, 0.6);
  animation: pulse 2s infinite;
}

.badge-warning .status-dot {
  background: #ff9500;
  box-shadow: 0 0 12rpx rgba(255, 149, 0, 0.6);
}

.badge-error .status-dot {
  background: #ff3b30;
  box-shadow: 0 0 12rpx rgba(255, 59, 48, 0.6);
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.6;
  }
}

.status-badge-text {
  font-size: 22rpx;
  font-weight: 600;
}

.badge-success .status-badge-text {
  color: #34c759;
}

.badge-warning .status-badge-text {
  color: #ff9500;
}

.badge-error .status-badge-text {
  color: #ff3b30;
}

.empty-state {
  background: white;
  border-radius: 32rpx;
  padding: 120rpx 60rpx;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  border: 2rpx dashed rgba(148, 163, 184, 0.3);
}

.empty-icon {
  width: 160rpx;
  height: 160rpx;
  border-radius: 50%;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32rpx;
  position: relative;
}

.empty-icon::after {
  content: '';
  position: absolute;
  inset: -8rpx;
  border-radius: 50%;
  border: 2rpx dashed rgba(102, 126, 234, 0.2);
}

.empty-title {
  font-size: 32rpx;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 16rpx;
}

.empty-desc {
  font-size: 26rpx;
  color: #64748b;
  line-height: 1.6;
}
</style>