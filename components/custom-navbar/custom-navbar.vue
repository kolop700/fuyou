<template>
  <view class="custom-navbar" :style="{ background: navbarBg, paddingTop: statusBarHeight + 'px' }">
    <view class="navbar-content" :style="{ height: navbarHeight + 'px' }">
      <!-- 左侧返回按钮/占位 -->
      <view class="navbar-left">
        <view 
          v-if="showBack" 
          class="navbar-back"
          :style="{ background: theme.bgCard, borderColor: theme.borderColor }"
          @click="handleBack"
        >
          <text class="iconfont icon-fasfa-chevron-left" :style="{ color: theme.textPrimary, fontSize: '32rpx' }"></text>
        </view>
      </view>
      
      <!-- 中间标题 -->
      <view class="navbar-center">
        <text class="navbar-title" :style="{ color: theme.textPrimary }">{{ title }}</text>
      </view>
      
      <!-- 右侧操作区 -->
      <view class="navbar-right">
        <slot name="right"></slot>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onMounted } from 'vue'
import { useThemeVars } from '@/utils/themeConfig.js'

const { proxy } = getCurrentInstance()
const themeStore = proxy.$store.theme.useThemeStore()

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))

// Props
const props = defineProps({
  title: {
    type: String,
    default: ''
  },
  showBack: {
    type: Boolean,
    default: false
  },
  bgColor: {
    type: String,
    default: ''
  },
  transparent: {
    type: Boolean,
    default: false
  }
})

// 状态栏高度
const statusBarHeight = ref(0)
// 导航栏高度
const navbarHeight = ref(44)

// 计算导航栏背景色
const navbarBg = computed(() => {
  if (props.transparent) {
    return 'transparent'
  }
  if (props.bgColor) {
    return props.bgColor
  }
  return theme.value.bgCard
})

// 返回上一页
const handleBack = () => {
  uni.navigateBack({
    delta: 1
  })
}

onMounted(() => {
  // 获取系统信息
  const systemInfo = uni.getSystemInfoSync()
  statusBarHeight.value = systemInfo.statusBarHeight || 0
  
  // 根据平台设置导航栏高度
  // #ifdef APP-PLUS || H5
  navbarHeight.value = 44
  // #endif
  
  // #ifdef MP-WEIXIN
  // 微信小程序胶囊按钮位置信息
  const menuButtonInfo = uni.getMenuButtonBoundingClientRect()
  navbarHeight.value = menuButtonInfo.height + (menuButtonInfo.top - systemInfo.statusBarHeight) * 2
  // #endif
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.custom-navbar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 999;
  backdrop-filter: blur(20rpx);
  box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.08);
}

.navbar-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 32rpx;
}

.navbar-left,
.navbar-right {
  width: 120rpx;
  display: flex;
  align-items: center;
}

.navbar-left {
  justify-content: flex-start;
}

.navbar-right {
  justify-content: flex-end;
}

.navbar-back {
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid;
  transition: all 0.3s ease;
}

.navbar-back:active {
  transform: scale(0.9);
  opacity: 0.8;
}

.navbar-center {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.navbar-title {
  font-size: 32rpx;
  font-weight: 600;
}
</style>
