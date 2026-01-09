<<template>
  <view class="custom-navbar" :style="{ background: navbarBg, paddingTop: statusBarHeight + 'px' }">
    <view class="navbar-content" :style="{ height: navbarHeight + 'px' }">
      <!-- 左侧返回按钮/占位 -->
      <view class="navbar-left">
        <view 
          v-if="showBack" 
          class="navbar-back"
          :style="{ background: theme.bgCard, boxShadow: backBtnShadow }"
          @click="handleBack"
        >
          <text class="iconfont icon-arrow-left" :style="{ color: theme.textPrimary }"></text>
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
  // 导航栏透明，让页面背景透过来
  return 'transparent'
})

// 返回按钮阴影（浅色模式有阴影，深色模式无）
const backBtnShadow = computed(() => {
  return themeStore.isDark() ? 'none' : '0 4rpx 16rpx rgba(0,0,0,0.06)'
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
  // 背景色由动态绑定
}

.navbar-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20rpx 48rpx;
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
  width: 80rpx;
  height: 80rpx;
  border-radius: 24rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  // 背景色和阴影由动态绑定
  
  .iconfont {
    font-size: 32rpx;
    // 颜色由动态绑定
  }
}

.navbar-back:active {
  transform: scale(0.95);
}

.navbar-center {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.navbar-title {
  font-size: 34rpx;
  font-weight: 600;
  // 颜色由动态绑定
}
</style>
