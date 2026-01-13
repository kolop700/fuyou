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
</style>
