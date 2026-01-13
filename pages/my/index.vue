<template>
  <view class="my-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏（不显示标题） -->
    <custom-navbar title="我的" :transparent="false" />
    
    <scroll-view class="my-content" scroll-y :style="{ paddingTop: navbarHeight + 'px', paddingBottom: '120rpx' }">
      <view class="page-padding">
        <!-- 用户信息卡片 -->
        <view class="glass-card user-card" :style="{ background: theme.bgCard, borderColor: theme.borderColor, boxShadow: theme.shadowCard }">
          <view class="user-avatar-box" :style="{ background: theme.gradientBlue }">
            <image v-if="userStore.avatarUrl" :src="userStore.avatarUrl" mode="aspectFill" class="avatar-img" @click="handleAvatarClick"></image>
            <text v-else class="iconfont icon-fa-user" style="font-size: 64rpx; color: white;" @click="handleAvatarClick"></text>
          </view>
          <text class="user-name" :style="{ color: theme.textPrimary }">{{ userStore.userName || '未登录' }}</text>
          <text class="user-phone" :style="{ color: theme.textSecondary }">{{ formatPhone(userStore.userAcct) }}</text>
          
          <view class="user-badges">
            <view class="badge" :style="{ background: theme.getBadgeBackground('success'), color: theme.colorSuccess }">已认证</view>
            <view class="badge" :style="{ background: theme.getBadgeBackground('info'), color: theme.colorAccent }">业主</view>
          </view>
        </view>
        
        <!-- 功能列表 -->
        <view class="menu-list">
          <view 
            v-for="(item, index) in menuItems" 
            :key="index" 
            class="list-item"
            :style="{ background: theme.bgCard, borderColor: 'transparent', boxShadow: theme.shadowCard }"
            @click="handleItemClick(item)"
            hover-class="list-item-hover"
          >
            <view class="list-icon" :style="{ background: item.gradient }">
              <text class="iconfont" :class="item.icon"></text>
            </view>
            <view class="list-content">
              <text class="list-title" :style="{ color: theme.textPrimary }">{{ item.title }}</text>
              <text class="list-subtitle" :style="{ color: theme.textSecondary }">{{ item.subtitle }}</text>
            </view>
            <text class="iconfont icon-fasfa-chevron-rightCopy list-arrow" :style="{ color: theme.textTertiary }"></text>
          </view>
        </view>
      </view>
    </scroll-view>
    
    <!-- 自定义底部标签栏 -->
    <custom-tabbar />
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onMounted } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import { useThemeVars } from '@/utils/themeConfig.js'

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const themeStore = proxy.$store.theme.useThemeStore()

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))
const isDark = computed(() => themeStore.isDark())

// 状态栏高度
const statusBarHeight = ref(0)
// 导航栏高度（用于页面内边距）
const navbarHeight = ref(0)

// 菜单项配置
const menuItems = computed(() => [
  {
    title: '我的房屋',
    subtitle: '已绑定房屋信息',
    icon: 'icon-fa-home',
    gradient: 'linear-gradient(135deg, #f59e0b, #d97706)',
    action: () => uni.switchTab({ url: '/pages/device/index' }),
    requiresAuth: true
  },
  {
    title: '个人资料',
    subtitle: '修改头像、昵称等信息',
    icon: 'icon-user-edit',
    gradient: 'linear-gradient(135deg, #8b5cf6, #7c3aed)',
    action: () => uni.navigateTo({ url: '/user_package/pages/profile/index' }),
    requiresAuth: true
  },
  {
    title: '人脸管理',
    subtitle: '管理门禁人脸信息',
    icon: 'icon-smile-solid',
    gradient: 'linear-gradient(135deg, #ec4899, #db2777)',
    action: handleFaceUpload,
    requiresAuth: true
  },
  {
    title: '账户安全',
    subtitle: '密码、手机号管理',
    icon: 'icon-fa-shield-alt',
    gradient: 'linear-gradient(135deg, #10b981, #059669)',
    action: handlePassword,
    requiresAuth: true
  },
  {
    title: '设置',
    subtitle: '主题、关于我们',
    icon: 'icon-a-fasfa-cog',
    gradient: 'linear-gradient(135deg, #6366f1, #4f46e5)',
    action: handleSettings,
    requiresAuth: false
  }
])

// 格式化手机号显示
const formatPhone = (phone) => {
  if (!phone) return '未绑定'
  if (phone.length === 11) {
    return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
  }
  return phone
}

// 检查是否已登录
const isLoggedIn = computed(() => {
  return userStore.isLogin
})

// 处理菜单点击
const handleItemClick = (item) => {
  if (item.requiresAuth && !isLoggedIn.value) {
    uni.navigateTo({
      url: '/user_package/pages/login/index'
    })
    return
  }
  item.action()
}

// 点击头像
const handleAvatarClick = () => {
  if (!isLoggedIn.value) {
    uni.navigateTo({
      url: '/user_package/pages/login/index'
    })
    return
  }
  
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

// 设置 (跳转到设置页面)
const handleSettings = () => {
  uni.navigateTo({
    url: '/workbench_package/pages/settings/index'
  })
}



onLoad(() => {
  try {
    // 加载主题设置
    themeStore.loadTheme()
    // 计算状态栏高度
    const systemInfo = uni.getSystemInfoSync()
    statusBarHeight.value = systemInfo.statusBarHeight || 0
    
    // 计算导航栏总高度 (状态栏高度 + 内容区域高度)
    // #ifdef MP-WEIXIN
    const menuButtonInfo = uni.getMenuButtonBoundingClientRect()
    const navContentHeight = menuButtonInfo.height + (menuButtonInfo.top - statusBarHeight.value) * 2
    navbarHeight.value = statusBarHeight.value + navContentHeight
    // #endif
    
    // #ifndef MP-WEIXIN
    navbarHeight.value = statusBarHeight.value + 44
    // #endif
  } catch (error) {
    console.error('我的页面加载失败:', error)
    statusBarHeight.value = 20
    navbarHeight.value = 64 // 20 + 44 fallback
  }
})

onShow(() => {
  // 隐藏原生TabBar
  uni.hideTabBar({
    animation: false
  })
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.my-container {
  height: 100vh;
  // 背景色由动态绑定
}

.my-content {
  height: 100%;
  background: transparent;
}

.page-padding {
  padding: 20px 24px;
}

// 玻璃拟态卡片通用样式
.glass-card {
  border-radius: 20px;
  border: 1px solid;
  // 背景和边框颜色由动态绑定
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1);
}

// 用户卡片
.user-card {
  padding: 30px 20px;
  text-align: center;
  margin-bottom: 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.user-avatar-box {
  width: 80px;
  height: 80px;
  margin: 0 auto 16px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
}

.avatar-img {
  width: 100%;
  height: 100%;
}

.user-name {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 4px;
}

.user-phone {
  font-size: 14px;
  margin-bottom: 12px;
}

.user-badges {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-top: 4px;
}

.badge {
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
}

// 列表项
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
  transform: translateY(-2px);
}

.list-icon {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  flex-shrink: 0;
}

.list-icon .iconfont {
  font-size: 20px;
  color: white;
}

.list-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.list-title {
  font-size: 15px;
  font-weight: 500;
  margin-bottom: 4px;
}

.list-subtitle {
  font-size: 12px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.list-arrow {
  font-size: 14px;
  margin-left: 8px;
}
</style>