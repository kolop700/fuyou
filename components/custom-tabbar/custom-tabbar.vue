<template>
  <view class="custom-tabbar" :style="{ background: theme.bgCard, borderTopColor: theme.borderColor }">
    <view 
      v-for="(item, index) in tabList" 
      :key="index"
      class="tabbar-item"
      @click="switchTab(item, index)"
    >
      <view class="tabbar-icon-wrapper">
        <text 
          class="iconfont" 
          :class="currentIndex === index ? item.selectedIcon : item.icon"
          :style="{ 
            color: currentIndex === index ? theme.colorAccent : theme.textTertiary,
            fontSize: getIconSize(index)
          }"
        ></text>
      </view>
      <text 
        class="tabbar-text" 
        :style="{ 
          color: currentIndex === index ? theme.colorAccent : theme.textTertiary 
        }"
      >
        {{ item.text }}
      </text>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onMounted, onBeforeUnmount } from 'vue'
import { useThemeVars } from '@/utils/themeConfig.js'

const { proxy } = getCurrentInstance()
const themeStore = proxy.$store.theme.useThemeStore()

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))

// 获取图标大小（工作台和我的图标稍大）
const getIconSize = (index) => {
  // 索引2是工作台，索引3是我的
  if (index === 2 || index === 3) {
    return '52rpx'  // 工作台和我的图标稍大
  }
  return '48rpx'  // 首页和开门保持原大小
}

// 当前选中的索引
const currentIndex = ref(0)

// 标签列表配置
const tabList = [
  {
    text: '首页',
    pagePath: '/pages/index/index',
    icon: 'icon-fa-home',
    selectedIcon: 'icon-fa-home'
  },
  {
    text: '开门',
    pagePath: '/pages/door/index',
    icon: 'icon-door-open',
    selectedIcon: 'icon-door-open'
  },
  {
    text: '工作台',
    pagePath: '/pages/device/index',
    icon: 'icon-th-large',
    selectedIcon: 'icon-th-large'
  },
  {
    text: '我的',
    pagePath: '/pages/my/index',
    icon: 'icon-fa-user',
    selectedIcon: 'icon-fa-user'
  }
]

// 切换标签
const switchTab = (item, index) => {
  if (currentIndex.value === index) return
  
  currentIndex.value = index
  uni.switchTab({
    url: item.pagePath
  })
}

// 初始化当前索引
const initCurrentIndex = () => {
  const pages = getCurrentPages()
  if (pages.length > 0) {
    const currentPage = pages[pages.length - 1]
    const route = '/' + currentPage.route
    
    const index = tabList.findIndex(item => item.pagePath === route)
    if (index !== -1) {
      currentIndex.value = index
    }
  }
}

// 定时检查定时器ID
let checkTimer = null

// 定时检查当前页面状态
const startRouteCheck = () => {
  checkTimer = setInterval(() => {
    initCurrentIndex()
  }, 300) // 每300ms检查一次
}

// 停止检查
const stopRouteCheck = () => {
  if (checkTimer) {
    clearInterval(checkTimer)
    checkTimer = null
  }
}

onMounted(() => {
  uni.hideTabBar()
  initCurrentIndex()
  startRouteCheck()
})

onBeforeUnmount(() => {
  stopRouteCheck()
})

// 暴露方法供父组件调用
defineExpose({
  setCurrentIndex: (index) => {
    currentIndex.value = index
  }
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.custom-tabbar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 100rpx;
  display: flex;
  justify-content: space-around;
  align-items: center;
  padding-bottom: env(safe-area-inset-bottom);
  border-top: 1px solid;
  z-index: 9999; // 提高z-index确保在最上层
  backdrop-filter: blur(20rpx);
  box-shadow: 0 -2rpx 12rpx rgba(0, 0, 0, 0.08);
}

.tabbar-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 8rpx 0;
  cursor: pointer;
  transition: all 0.3s ease;
}

.tabbar-icon-wrapper {
  margin-bottom: 6rpx;
  transition: transform 0.3s ease;
}

.tabbar-item:active .tabbar-icon-wrapper {
  transform: scale(0.9);
}

.tabbar-text {
  font-size: 20rpx;
  font-weight: 500;
  transition: all 0.3s ease;
}
</style>
