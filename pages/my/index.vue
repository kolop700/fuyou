<template>
  <view class="my-container">
    <scroll-view class="my-content" scroll-y>
      <!-- 用户信息头部 -->
      <view class="profile-header">
        <view class="profile-avatar" @click="handleAvatarClick">
          <image v-if="userStore.avatarUrl" :src="userStore.avatarUrl" mode="aspectFill" class="avatar-img"></image>
          <text v-else class="iconfont icon-fa-user-circle-o" style="font-size: 72rpx; color: #667eea;"></text>
        </view>
        <text class="profile-name">{{ userStore.userName || '未登录' }}</text>
        <text class="profile-phone">手机号: {{ formatPhone(userStore.userAcct) }}</text>
      </view>

      <!-- 菜单列表 -->
      <view class="menu-section">
        <view class="menu-item" @click="handleFaceUpload">
          <view class="menu-left">
            <text class="iconfont icon-fa-user-circle-o menu-icon" style="color: #667eea;"></text>
            <text class="menu-text">人脸录入</text>
          </view>
          <text class="iconfont icon-fasfa-chevron-rightCopy menu-arrow"></text>
        </view>
        <view class="menu-item" @click="handlePassword">
          <view class="menu-left">
            <text class="iconfont icon-fa-key menu-icon" style="color: #ff9500;"></text>
            <text class="menu-text">密码管理</text>
          </view>
          <text class="iconfont icon-fasfa-chevron-rightCopy menu-arrow"></text>
        </view>
        <view class="menu-item" @click="handleAbout">
          <view class="menu-left">
            <text class="iconfont icon-info-circle menu-icon" style="color: #34c759;"></text>
            <text class="menu-text">关于玉龙智眸</text>
          </view>
          <text class="iconfont icon-fasfa-chevron-rightCopy menu-arrow"></text>
        </view>
      </view>

      <!-- 登录/退出登录 -->
      <view class="logout-section">
        <button class="logout-btn" :class="{ 'login-btn': !isLoggedIn }" @click="handleAuthAction">
          {{ isLoggedIn ? '退出登录' : '登录' }}
        </button>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onMounted } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()

// 格式化手机号显示
const formatPhone = (phone) => {
  if (!phone) return '未绑定'
  if (phone.length === 11) {
    return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
  }
  return phone
}

// 点击头像
const handleAvatarClick = () => {
  if (userStore.avatarUrl) {
    uni.previewImage({
      urls: [userStore.avatarUrl],
      current: 0
    })
  } else {
    uni.navigateTo({
      url: '/user_package/pages/profile/index'
    })
  }
}

// 人脸录入
const handleFaceUpload = () => {
  uni.navigateTo({
    url: '/workbench_package/pages/face-upload/index'
  })
}

// 密码管理
const handlePassword = () => {
  uni.navigateTo({
    url: '/user_package/pages/forgot-password/index'
  })
}

// 关于我们
const handleAbout = () => {
  uni.navigateTo({
    url: '/workbench_package/pages/about/index'
  })
}

// 处理登录/退出登录按钮点击
const handleAuthAction = () => {
  if (isLoggedIn.value) {
    // 已登录，执行退出登录
    handleLogout()
  } else {
    // 未登录，跳转到登录页
    uni.navigateTo({
      url: '/user_package/pages/login/index'
    })
  }
}

// 退出登录
const handleLogout = () => {
  uni.showModal({
    title: '提示',
    content: '确定要退出登录吗？',
    success: (res) => {
      if (res.confirm) {
        userStore.logout()
        uni.showToast({
          title: '已退出登录',
          icon: 'success',
          duration: 1500
        })
        // 退出登录后跳转到登录页
        setTimeout(() => {
          uni.reLaunch({
            url: '/user_package/pages/login/index'
          })
        }, 1500)
      }
    }
  })
}

// 检查是否已登录（不自动跳转）
const isLoggedIn = computed(() => {
  return userStore.isLogin
})

onLoad(() => {
  // 只检查登录状态，不自动跳转
  console.log('我的页面加载，登录状态:', userStore.isLogin)
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.my-container {
  height: 100vh;
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%);
}

.my-content {
  height: 100%;
  background: transparent;
}

.profile-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 100rpx 40rpx 60rpx;
  text-align: center;
  color: white;
}

.profile-avatar {
  width: 160rpx;
  height: 160rpx;
  border-radius: 50%;
  background: white;
  margin: 0 auto 24rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 8rpx solid rgba(255, 255, 255, 0.5);
  overflow: hidden;
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.profile-name {
  display: block;
  font-size: 48rpx;
  font-weight: 700;
  margin-bottom: 8rpx;
}

.profile-phone {
  display: block;
  opacity: 0.8;
  font-size: 28rpx;
}

.menu-section {
  margin-bottom: 40rpx;
}

.menu-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 32rpx 40rpx;
  background: white;
  margin: 0 40rpx 2rpx;
  color: #1e293b;
}

.menu-item:first-child {
  border-radius: 24rpx 24rpx 0 0;
  margin-top: 40rpx;
}

.menu-item:last-child {
  border-radius: 0 0 24rpx 24rpx;
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
}

.menu-left {
  display: flex;
  align-items: center;
}

.menu-icon {
  font-size: 40rpx;
  margin-right: 24rpx;
}

.menu-text {
  font-size: 32rpx;
}

.menu-arrow {
  opacity: 0.4;
  font-size: 36rpx;
  color: #94a3b8;
}

.logout-section {
  padding: 40rpx;
}

.logout-btn {
  width: 100%;
  padding: 32rpx;
  background: rgba(255, 59, 48, 0.1);
  color: #ff3b30;
  border: none;
  border-radius: 24rpx;
  font-size: 32rpx;
  font-weight: 600;
}

.logout-btn.login-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.logout-btn::after {
  border: none;
}
</style>