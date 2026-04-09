<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="支付结果" :show-back="false" />
    
    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <!-- 成功图标区域 -->
      <view class="success-header">
        <view class="icon-circle" :style="{ background: '#07C160' }">
          <text class="iconfont icon-fa-check"></text>
        </view>
        <text class="success-title" :style="{ color: theme.textPrimary }">支付成功</text>
        <text class="amount-text" :style="{ color: theme.textPrimary }">¥ {{ amount }}</text>
      </view>

      <!-- 订单信息卡片 -->
      <view class="info-card" :style="{ background: theme.bgCard, boxShadow: theme.shadowCard }">
        <view class="info-row">
          <text class="info-label" :style="{ color: theme.textSecondary }">支付方式</text>
          <text class="info-value" :style="{ color: theme.textPrimary }">{{ methodText }}</text>
        </view>
        <view class="info-row">
          <text class="info-label" :style="{ color: theme.textSecondary }">订单金额</text>
          <text class="info-value amount-highlight" :style="{ color: '#ef4444' }">¥{{ amount }}</text>
        </view>
      </view>

      <!-- 提示信息 -->
      <view class="tips-section">
        <view class="tip-item">
          <text class="iconfont icon-a-fasfa-info-circle" :style="{ color: '#ef4444' }"></text>
          <text class="tip-text" :style="{ color: theme.textSecondary }">柜门即将打开，请尽快存入物品。</text>
        </view>
      </view>

      <!-- 操作按钮 -->
      <view class="action-section">
        <button 
          class="action-btn btn-primary" 
          :style="{ background: theme.colorAccent }"
          @tap="handleComplete"
        >
          完成并开柜
        </button>
        <button 
          class="action-btn btn-secondary" 
          :style="{ background: theme.bgCard, color: theme.textPrimary, borderColor: theme.borderColor }"
          @tap="viewOrder"
        >
          查看订单
        </button>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useThemeStore } from '@/store/modules/theme';
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const amount = ref('0.00');
const method = ref('wechat');

const methodText = computed(() => {
  return method.value === 'wechat' ? '微信支付' : '支付宝支付';
});

onLoad((options) => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  
  if (options.amount) {
    amount.value = options.amount;
  }
  if (options.method) {
    method.value = options.method;
  }
});

const handleComplete = () => {
  // 支付完成后，跳转到柜门打开倒计时页面
  uni.redirectTo({
    url: '/workbench_package/pages/locker/deposit-success'
  });
};

const viewOrder = () => {
  // 跳转到记录页面
  uni.redirectTo({
    url: '/workbench_package/pages/locker/storage-records'
  });
};
</script>

<style scoped>
.page-container {
  min-height: 100vh;
  transition: background 0.3s ease;
}

.page-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 64rpx 48rpx;
  box-sizing: border-box;
}

/* 头部成功状态 */
.success-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 64rpx;
}

.icon-circle {
  width: 120rpx;
  height: 120rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32rpx;
}

.icon-circle .iconfont {
  font-size: 64rpx;
  color: white;
}

.success-title {
  font-size: 36rpx;
  font-weight: 600;
  margin-bottom: 16rpx;
}

.amount-text {
  font-size: 56rpx;
  font-weight: 700;
}

/* 订单信息卡片 */
.info-card {
  width: 100%;
  border-radius: 24rpx;
  padding: 32rpx;
  margin-bottom: 48rpx;
  box-sizing: border-box;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16rpx 0;
}

.info-label {
  font-size: 28rpx;
}

.info-value {
  font-size: 28rpx;
  font-weight: 500;
}

.amount-highlight {
  font-weight: 700;
  font-size: 32rpx;
}

/* 提示信息 */
.tips-section {
  width: 100%;
  margin-bottom: 64rpx;
}

.tip-item {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12rpx;
}

.tip-item .iconfont {
  font-size: 28rpx;
}

.tip-text {
  font-size: 26rpx;
}

/* 操作按钮 */
.action-section {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 32rpx;
}

.action-btn {
  width: 100%;
  height: 96rpx;
  border-radius: 48rpx;
  font-size: 32rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-primary {
  color: white;
  border: none;
}

.btn-primary:active {
  opacity: 0.9;
  transform: scale(0.98);
}

.btn-secondary {
  border-width: 1px;
  border-style: solid;
}

.btn-secondary:active {
  opacity: 0.7;
}
</style>