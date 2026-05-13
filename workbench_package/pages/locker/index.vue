<template>
  <view class="locker-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏 -->
    <custom-navbar title="智能快递柜" :show-back="true" />
    
    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="header-section">
        <text class="greeting" :style="{ color: theme.textSecondary }">欢迎您，王师傅！</text>
      </view>

      <view class="cards-grid">
        <!-- 快递员存件 (宽卡片) -->
        <view class="action-card full-width-card" 
              :style="{ background: theme.courierCardBg, boxShadow: theme.courierCardShadow }"
              @tap="handleCourierDeposit">
          <text class="iconfont icon-shipping-fast card-icon"></text>
          <text class="card-title">快递员存件</text>
          <text class="card-desc">为小区住户存入包裹</text>
        </view>

        <!-- 临时存货 (宽卡片) -->
        <view class="action-card full-width-card" 
              :style="{ background: theme.tempCardBg, boxShadow: theme.tempCardShadow }"
              @tap="handleTempStorage">
          <text class="iconfont icon-boxes-packing card-icon"></text>
          <text class="card-title">临时存货</text>
          <text class="card-desc">临时存放个人物品</text>
        </view>

        <!-- 包裹取件 (窄卡片) -->
        <view class="action-card half-width-card" 
              :style="{ background: theme.pickupCardBg, boxShadow: theme.pickupCardShadow }"
              @tap="handlePickup">
          <text class="iconfont icon-box-archive card-icon-small"></text>
          <text class="card-title-small">包裹取件</text>
          <text class="card-desc-small">输入取件码</text>
        </view>

        <!-- 存取记录 (窄卡片) -->
        <view class="action-card half-width-card" 
              :style="{ background: theme.recordCardBg, boxShadow: theme.recordCardShadow }"
              @tap="handleRecords">
          <text class="iconfont icon-clipboard-list card-icon-small"></text>
          <text class="card-title-small">存取记录</text>
          <text class="card-desc-small">查看历史记录</text>
        </view>
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
// 使用主题配置，实现深色/浅色模式切换
const theme = computed(() => {
  const vars = useThemeVars(themeStore.isDark());
  const isDark = themeStore.isDark();
  
  if (isDark) {
    // 深色模式下的卡片样式
    return {
      ...vars,
      courierCardBg: 'linear-gradient(135deg, #1e4b8a 0%, #10b981 100%)',
      courierCardShadow: '0 20rpx 40rpx -10rpx rgba(30, 75, 138, 0.4)',
      
      tempCardBg: 'linear-gradient(135deg, #b45309 0%, #d97706 100%)',
      tempCardShadow: '0 20rpx 40rpx -10rpx rgba(180, 83, 9, 0.4)',
      
      pickupCardBg: 'linear-gradient(135deg, #6b21a8 0%, #a21caf 100%)', // 紫色系
      pickupCardShadow: '0 20rpx 40rpx -10rpx rgba(107, 33, 168, 0.4)',
      
      recordCardBg: 'linear-gradient(135deg, #334155 0%, #475569 100%)', // 蓝灰色系
      recordCardShadow: '0 20rpx 40rpx -10rpx rgba(51, 65, 85, 0.4)'
    };
  } else {
    // 浅色模式下的卡片样式
    return {
      ...vars,
      courierCardBg: 'linear-gradient(135deg, #4A90E2 0%, #50E3C2 100%)',
      courierCardShadow: '0 20rpx 40rpx -10rpx rgba(74, 144, 226, 0.3)',
      
      tempCardBg: 'linear-gradient(135deg, #F5A623 0%, #F8E71C 100%)',
      tempCardShadow: '0 20rpx 40rpx -10rpx rgba(245, 166, 35, 0.3)',
      
      pickupCardBg: 'linear-gradient(135deg, #9F44D3 0%, #E233FF 100%)',
      pickupCardShadow: '0 20rpx 40rpx -10rpx rgba(159, 68, 211, 0.3)',
      
      recordCardBg: 'linear-gradient(135deg, #5B6C8F 0%, #8A9CBF 100%)',
      recordCardShadow: '0 20rpx 40rpx -10rpx rgba(91, 108, 143, 0.3)'
    };
  }
});

const navbarHeight = ref(0);
const lockerId = ref(1);

onLoad((options) => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;

  const id = Number(options?.locker_id);
  if (Number.isFinite(id) && id > 0) {
    lockerId.value = id;
  }
});

const handleCourierDeposit = () => {
  uni.navigateTo({
    url: `/workbench_package/pages/locker/courier-deposit?locker_id=${lockerId.value}`
  });
};

const handleTempStorage = () => {
  uni.navigateTo({
    url: `/workbench_package/pages/locker/temp-storage?locker_id=${lockerId.value}`
  });
};

const handlePickup = () => {
  uni.navigateTo({
    url: `/workbench_package/pages/locker/pickup?locker_id=${lockerId.value}`
  });
};

const handleRecords = () => {
  uni.navigateTo({
    url: `/workbench_package/pages/locker/storage-records?locker_id=${lockerId.value}`
  });
};
</script>

<style scoped>
/* 引入 HTML 原型中的设计变量 */
.locker-container {
  min-height: 100vh;
  position: relative;
  font-family: 'Poppins', sans-serif;
  transition: background 0.3s ease;
  padding-bottom: 48rpx;
}

.page-content {
  padding: 0 48rpx;
  box-sizing: border-box;
}

.header-section {
  margin-bottom: 40rpx;
  padding-top: 24rpx;
}

.greeting {
  font-size: 32rpx;
  transition: color 0.3s ease;
}

/* 网格布局 */
.cards-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 32rpx;
}

.action-card {
  border-radius: 32rpx;
  padding: 48rpx;
  box-sizing: border-box;
  color: white;
  transition: transform 0.2s ease;
  position: relative;
  overflow: hidden;
}

.full-width-card {
  width: 100%;
}

.half-width-card {
  width: calc(50% - 16rpx);
  padding: 40rpx 32rpx;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.action-card:active {
  transform: scale(0.98);
}

.card-icon {
  font-size: 64rpx;
  margin-bottom: 32rpx;
  display: block;
  opacity: 0.9;
}

.card-title {
  font-size: 40rpx;
  font-weight: 700;
  display: block;
  margin-bottom: 8rpx;
}

.card-desc {
  font-size: 28rpx;
  opacity: 0.8;
  display: block;
}

.card-icon-small {
  font-size: 48rpx;
  margin-bottom: 24rpx;
  display: block;
  opacity: 0.9;
}

.card-title-small {
  font-size: 32rpx;
  font-weight: 700;
  display: block;
  margin-bottom: 8rpx;
}

.card-desc-small {
  font-size: 24rpx;
  opacity: 0.8;
  display: block;
}
</style>
