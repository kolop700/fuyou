<template>
  <view class="page-container" :style="{ background: theme.bgSecondary }">
    <!-- 环境光背景 -->
    <view class="ambient-bg"></view>

    <view class="page-content">
      <!-- 动画图标 -->
      <view class="icon-section">
        <view class="icon-circle" :style="{ background: theme.bgCard, boxShadow: theme.shadowLogo }">
          <text class="iconfont icon-door-open animated-icon" :style="{ color: theme.colorAccent }"></text>
        </view>
      </view>

      <!-- 状态文本 -->
      <view class="text-section">
        <text class="title" :style="{ color: theme.textPrimary }">柜门已打开</text>
        <text class="subtitle" :style="{ color: theme.textSecondary }">请尽快存入物品并关闭柜门</text>
      </view>

      <!-- 倒计时圆环 -->
      <view class="countdown-section">
        <view class="countdown-circle">
          <!-- 背景圆环 -->
          <view class="circle-bg" :style="{ borderColor: theme.borderColor }"></view>
          <!-- 进度圆环 -->
          <view class="circle-progress" :style="{ borderColor: theme.colorSuccess }"></view>
          <!-- 倒计时数字 -->
          <text class="countdown-text" :style="{ color: theme.textPrimary }">{{ countdown }}</text>
        </view>
      </view>

      <!-- 操作按钮 -->
      <view class="action-section">
        <button 
          class="btn-primary" 
          :style="{ background: theme.colorSuccess, boxShadow: '0 10px 30px -10px ' + theme.colorSuccess }"
          @tap="handleSuccess"
        >
          存货成功
        </button>
        <button 
          class="btn-ghost" 
          :style="{ color: theme.textSecondary }"
          @tap="handleCancel"
        >
          取消存货
        </button>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onMounted, onUnmounted } from 'vue';
import { useThemeStore } from '@/store/modules/theme';
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const countdown = ref(60);
let timer = null;

onMounted(() => {
  themeStore.loadTheme();
  startCountdown();
});

onUnmounted(() => {
  if (timer) clearInterval(timer);
});

const startCountdown = () => {
  timer = setInterval(() => {
    if (countdown.value > 0) {
      countdown.value--;
    } else {
      clearInterval(timer);
      // 倒计时结束处理，例如自动确认或提示超时
      uni.showToast({ title: '操作超时，请重试', icon: 'none' });
    }
  }, 1000);
};

const handleSuccess = () => {
  uni.showToast({ title: '存货成功', icon: 'success' });
  setTimeout(() => {
    uni.navigateBack({ delta: 2 }); // 返回到首页
  }, 1500);
};

const handleCancel = () => {
  uni.showModal({
    title: '确认取消',
    content: '取消后将无法继续存货，确定要取消吗？',
    success: (res) => {
      if (res.confirm) {
        uni.navigateBack();
      }
    }
  });
};
</script>

<style scoped>
.page-container {
  min-height: 100vh;
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 环境光背景 */
.ambient-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  background: 
    radial-gradient(circle at 50% 30%, hsla(200, 80%, 50%, 0.1), transparent 50%);
}

.page-content {
  width: 100%;
  padding: 64rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  z-index: 10;
}

/* 图标区域 */
.icon-section {
  margin-bottom: 48rpx;
}

.icon-circle {
  width: 200rpx;
  height: 200rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  animation: pulse 2s infinite ease-in-out;
}

.animated-icon {
  font-size: 100rpx;
}

@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.05); }
  100% { transform: scale(1); }
}

/* 文本区域 */
.text-section {
  text-align: center;
  margin-bottom: 64rpx;
}

.title {
  font-size: 48rpx;
  font-weight: 700;
  margin-bottom: 16rpx;
  display: block;
}

.subtitle {
  font-size: 30rpx;
  display: block;
}

/* 倒计时区域 */
.countdown-section {
  margin-bottom: 80rpx;
}

.countdown-circle {
  width: 160rpx;
  height: 160rpx;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

.circle-bg, .circle-progress {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  border: 8rpx solid;
  box-sizing: border-box;
}

.circle-bg {
  opacity: 0.2;
}

.circle-progress {
  border-top-color: transparent;
  border-right-color: transparent;
  transform: rotate(-45deg);
  animation: spin 1s linear infinite; /* 简单的旋转动画，实际倒计时动画需JS配合canvas实现更佳，这里用简化版 */
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.countdown-text {
  font-size: 64rpx;
  font-weight: 700;
  position: relative;
  z-index: 2;
}

/* 按钮区域 */
.action-section {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 32rpx;
}

.btn-primary {
  width: 100%;
  height: 96rpx;
  border-radius: 48rpx;
  color: white;
  font-size: 32rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-primary:active {
  transform: scale(0.98);
  opacity: 0.9;
}

.btn-ghost {
  width: 100%;
  height: 80rpx;
  background: transparent;
  font-size: 28rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-ghost:active {
  opacity: 0.7;
}
</style>