<template>
  <view class="page-container">
    <scroll-view scroll-y class="page-scroll">
      <view class="hero-card">
        <image class="hero-logo" src="/static/logo.png" mode="aspectFit"></image>
        <text class="app-name">福优智家</text>
        <text class="app-desc">智慧社区服务平台，连接门禁、报修、快递柜与住户日常生活。</text>
        <view class="version-pill">
          <text>当前版本 v{{ appVersion }}</text>
        </view>
      </view>

      <view class="menu-card">
        <view class="menu-item" @tap="handleUserAgreement">
          <view class="content">
            <text>用户协议</text>
          </view>
          <view class="right-icon">
            <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
          </view>
        </view>

        <view class="menu-item" @tap="handlePrivacyPolicy">
          <view class="content">
            <text>隐私政策</text>
          </view>
          <view class="right-icon">
            <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
          </view>
        </view>

        <view class="menu-item" @tap="handleVersion">
          <view class="content">
            <text>程序版本</text>
          </view>
          <view class="right-text">
            <text>v{{ appVersion }}</text>
          </view>
        </view>

        <view class="menu-item" @tap="handleAccountDelete">
          <view class="content">
            <text class="delete-text">注销账号</text>
          </view>
          <view class="right-icon">
            <image src="/static/icons/icon_right.png" mode="aspectFit"></image>
          </view>
        </view>
      </view>

      <view class="footer-card">
        <text class="footer-company">{{ companyName }}</text>
        <text class="footer-copy">Copyright © {{ currentYear }}</text>
        <text class="footer-rights">All Rights Reserved</text>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, onMounted, getCurrentInstance } from 'vue'
import { storeToRefs } from 'pinia'

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const { userType } = storeToRefs(userStore)

const appVersion = ref('')
const companyName = ref('内蒙古优福运营管理有限公司')
const currentYear = new Date().getFullYear()

// 初始化版本号
const initVersion = () => {
  // #ifdef APP-PLUS
  appVersion.value = plus.runtime.version
  // #endif

  // #ifdef MP-WEIXIN
  const accountInfo = uni.getAccountInfoSync()
  appVersion.value = accountInfo.miniProgram.version
  // #endif

  if (!appVersion.value) {
    const systemInfo = uni.getSystemInfoSync()
    appVersion.value = systemInfo.appVersion || '1.0.0'
  }
}

const handleUserAgreement = () => {
  uni.navigateTo({
    url: `/user_package/pages/webview?title=${encodeURIComponent('用户协议')}&url=${encodeURIComponent('http://fuyou.yefiot.com/user.html')}`
  })
}

const handlePrivacyPolicy = () => {
  uni.navigateTo({
    url: `/user_package/pages/webview?title=${encodeURIComponent('隐私政策')}&url=${encodeURIComponent('http://fuyou.yefiot.com/privacy.html')}`
  })
}

const handleVersion = () => {
  uni.showToast({
    title: `当前版本：${appVersion.value}`,
    icon: 'none'
  })
}

const handleAccountDelete = () => {
  uni.showModal({
    title: '注销账号',
    content: '注销后，您的所有数据（包括人脸数据）将在30天内删除，且无法恢复。确定要注销吗？',
    confirmText: '确认注销',
    confirmColor: '#FF0000',
    cancelText: '再想想',
    success: async (res) => {
      if (res.confirm) {
        try {
          await userStore.deleteAccount()
          uni.showToast({
            title: '账号注销成功',
            icon: 'success'
          })
          setTimeout(() => {
            uni.reLaunch({
              url: '/pages/index/index',
              success: () => {
                setTimeout(() => {
                  uni.redirectTo({
                    url: '/user_package/pages/login/index'
                  })
                }, 100)
              }
            })
          }, 1500)
        } catch (error) {
          uni.showToast({
            title: '注销失败，请稍后重试',
            icon: 'none'
          })
        }
      }
    }
  })
}

onMounted(() => {
  initVersion()
})
</script>

<style lang="scss">
page {
  background: linear-gradient(180deg, #f5f9ff 0%, #eef3fb 100%);
  height: 100vh;
}

.page-container {
  min-height: 100vh;
}

.page-scroll {
  height: 100vh;
}

.hero-card,
.menu-card,
.footer-card {
  margin: 24rpx;
  border-radius: 32rpx;
  box-sizing: border-box;
}

.hero-card {
  padding: 48rpx 36rpx 40rpx;
  background: linear-gradient(135deg, #14213d 0%, #1f4f8f 100%);
  color: #ffffff;
  text-align: center;
  box-shadow: 0 20rpx 60rpx rgba(20, 33, 61, 0.18);
}

.hero-logo {
  width: 128rpx;
  height: 128rpx;
  margin: 0 auto 20rpx;
  border-radius: 28rpx;
  background: rgba(255, 255, 255, 0.14);
  padding: 16rpx;
  box-sizing: border-box;
}

.app-name {
  display: block;
  font-size: 40rpx;
  font-weight: 700;
  margin-bottom: 12rpx;
}

.app-desc {
  display: block;
  font-size: 26rpx;
  line-height: 1.7;
  color: rgba(255, 255, 255, 0.82);
}

.version-pill {
  margin: 28rpx auto 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 184rpx;
  padding: 14rpx 26rpx;
  border-radius: 999rpx;
  background: rgba(255, 255, 255, 0.14);
  font-size: 24rpx;
}

.menu-card,
.footer-card {
  background: rgba(255, 255, 255, 0.96);
  box-shadow: 0 16rpx 48rpx rgba(32, 78, 146, 0.08);
}

.menu-card {
  overflow: hidden;
}

.menu-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 32rpx 24rpx;
  position: relative;
}

.menu-item:not(:last-child)::after {
  content: '';
  position: absolute;
  left: 24rpx;
  right: 24rpx;
  bottom: 0;
  height: 1px;
  background-color: #e8edf5;
  transform: scaleY(0.5);
}

.content {
  flex: 1;
}

.content text {
  font-size: 28rpx;
  color: #1f2937;
  font-weight: 500;
}

.right-icon {
  width: 32rpx;
  height: 32rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

.right-icon image {
  width: 100%;
  height: 100%;
}

.right-text {
  font-size: 28rpx;
  color: #94a3b8;
  margin-right: 10rpx;
}

.delete-text {
  color: #ef4444 !important;
}

.footer-card {
  padding: 28rpx 24rpx 44rpx;
  margin-bottom: 36rpx;
  text-align: center;
}

.footer-company {
  display: block;
  font-size: 26rpx;
  font-weight: 600;
  color: #64748b;
}

.footer-copy,
.footer-rights {
  display: block;
  margin-top: 8rpx;
  font-size: 22rpx;
  color: #94a3b8;
}
</style>
