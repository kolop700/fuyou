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
        <text class="title" :style="{ color: theme.textPrimary }">{{ pageTitle }}</text>
        <text class="subtitle" :style="{ color: theme.textSecondary }">{{ pageSubtitle }}</text>
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
          {{ primaryButtonText }}
        </button>
        <button 
          v-if="pageMode !== 'pickup'"
          class="btn-ghost" 
          :style="{ color: theme.textSecondary }"
          @tap="handleCancel"
        >
          取消存货
        </button>
      </view>
    </view>
  
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
import { ref, computed, getCurrentInstance, onMounted, onUnmounted } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useThemeStore } from '@/store/modules/theme';
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const countdown = ref(60);
const comptRecordNo = ref('');
const submitting = ref(false);
const pageMode = ref('deposit');
let timer = null;

onLoad((options) => {
  comptRecordNo.value = options?.compt_record_no ? decodeURIComponent(options.compt_record_no) : '';
  pageMode.value = options?.mode || 'deposit';
});

const pageTitle = computed(() => pageMode.value === 'pickup' ? '柜门已打开' : '柜门已打开');
const pageSubtitle = computed(() => pageMode.value === 'pickup' ? '请尽快取出包裹并关闭柜门' : '请尽快存入物品并关闭柜门');
const primaryButtonText = computed(() => pageMode.value === 'pickup' ? '完成取件' : '存货成功');

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

const finishDeposit = async (op, successText) => {
  if (submitting.value) return;

  if (!comptRecordNo.value) {
    uni.showToast({ title: '缺少存货记录号，无法完成操作', icon: 'none' });
    return false;
  }

  submitting.value = true;
  uni.showLoading({ title: '处理中...' });

  try {
    await proxy.$api.locker.endDeposit({
      compt_record_no: comptRecordNo.value,
      op
    });
    uni.hideLoading();
    uni.showToast({ title: successText, icon: 'success' });
    setTimeout(() => {
      uni.navigateBack({ delta: 2 });
    }, 1500);
    return true;
  } catch (e) {
    uni.hideLoading();
    uni.showToast({ title: e?.msg || e?.detail || e?.message || '操作失败，请重试', icon: 'none' });
    return false;
  } finally {
    submitting.value = false;
  }
};

const handleSuccess = async () => {
  if (pageMode.value === 'pickup') {
    uni.showToast({ title: '取件完成', icon: 'success' });
    setTimeout(() => {
      uni.navigateBack({ delta: 2 });
    }, 1500);
    return;
  }

  await finishDeposit('1', '存货成功');
};

const handleCancel = () => {
  uni.showModal({
    title: '确认取消',
    content: '取消后将无法继续存货，确定要取消吗？',
    success: async (res) => {
      if (res.confirm) {
        await finishDeposit('0', '已取消存货');
      }
    }
  });
};

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
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
