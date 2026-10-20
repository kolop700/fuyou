<template>
  <view class="settings-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="设置" show-back />
    
    <scroll-view class="settings-content" scroll-y :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="page-padding">
        <view class="settings-list">
          <!-- 主题切换 -->
          <view class="list-item" :style="{ background: theme.bgCard, borderColor: theme.borderColor, boxShadow: theme.shadowCard }">
            <view class="list-content">
              <text class="list-title" :style="{ color: theme.textPrimary }">深色模式</text>
            </view>
            <switch :checked="isDark" @change="handleThemeChange" color="#6366f1" style="transform:scale(0.8)" />
          </view>
          
          <!-- 关于我们 -->
          <view class="list-item" 
            :style="{ background: theme.bgCard, borderColor: theme.borderColor, boxShadow: theme.shadowCard }"
            @click="handleAbout"
            hover-class="list-item-hover"
          >
            <view class="list-content">
              <text class="list-title" :style="{ color: theme.textPrimary }">关于我们</text>
            </view>
            <text class="iconfont icon-fasfa-chevron-rightCopy list-arrow" :style="{ color: theme.textTertiary }"></text>
          </view>
        </view>

        <!-- 退出登录按钮 -->
        <view class="logout-section">
          <button class="logout-btn" :style="{ background: theme.bgCard, color: theme.colorError, boxShadow: theme.shadowCard }" @click="handleLogout">
            退出登录
          </button>
        </view>
      </view>
    </scroll-view>
  
    <!-- 底部横幅广告（Taku）：常驻页面底部，placementId 为空/开关全关时自动隐藏 -->
    <view class="ad-section" v-if="bannerAdId">
      <view class="ad-divider"></view>
      <view class="ad-view">
        <taku-banner :placement-id="bannerAdId"></taku-banner>
      </view>
    </view>
    </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { useThemeVars } from '@/utils/themeConfig.js'

const { proxy } = getCurrentInstance()
const themeStore = proxy.$store.theme.useThemeStore()
const userStore = proxy.$store.user.useUserStore()

const theme = computed(() => useThemeVars(themeStore.isDark()))
const isDark = computed(() => themeStore.isDark())
const navbarHeight = ref(0)

const handleThemeChange = (e) => {
  themeStore.toggleTheme()
}

const handleAbout = () => {
  uni.navigateTo({
    url: '/workbench_package/pages/about/index'
  })
}

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
        setTimeout(() => {
          uni.reLaunch({
            url: '/user_package/pages/login/index'
          })
        }, 1500)
      }
    }
  })
}

onLoad(() => {
  const systemInfo = uni.getSystemInfoSync()
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44
})

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.settings-container {
  height: 100vh;
}

.settings-content {
  height: 100%;
}

.page-padding {
  padding: 20px 24px;
}

.list-item {
  display: flex;
  align-items: center;
  padding: 16px;
  border-radius: 16px;
  margin-bottom: 12px;
  border: 1px solid;
  transition: all 0.3s ease;
}

.list-item-hover {
  opacity: 0.8;
}

.list-content {
  flex: 1;
}

.list-title {
  font-size: 15px;
  font-weight: 500;
}

.list-arrow {
  font-size: 14px;
  margin-left: 8px;
}

.logout-section {
  margin-top: 32px;
}

.logout-btn {
  width: 100%;
  padding: 12px;
  border-radius: 14px;
  font-size: 16px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.logout-btn::after {
  border: none;
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
  min-height: 120rpx;
  padding: 8rpx 0;
}

/* Tab 页：横幅悬浮在自定义 tabbar（高100rpx+安全区）上方 */
.ad-section.ad-tab {
  bottom: calc(100rpx + env(safe-area-inset-bottom));
  box-shadow: 0 -4rpx 16rpx rgba(31, 48, 152, 0.12);
}
</style>
