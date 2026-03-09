<template>
  <view class="locker-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏 -->
    <custom-navbar title="快递柜" :show-back="true" />
    
    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="action-card" :style="{ background: theme.bgCard, boxShadow: theme.shadowCard }">
        <view class="card-icon-wrapper" :style="{ background: theme.getBadgeBackground('info') }">
          <text class="iconfont icon-plus" :style="{ color: theme.colorInfo }"></text>
        </view>
        <text class="card-title" :style="{ color: theme.textPrimary }">存件服务</text>
        <text class="card-subtitle" :style="{ color: theme.textSecondary }">将包裹存入快递柜</text>
        <button class="action-btn" :style="{ background: theme.colorAccentGradient, boxShadow: theme.shadowButton }">前往存件</button>
      </view>

      <view class="action-card" :style="{ background: theme.bgCard, boxShadow: theme.shadowCard }">
        <view class="card-icon-wrapper" :style="{ background: theme.getBadgeBackground('success') }">
          <text class="iconfont icon-fa-key" :style="{ color: theme.colorSuccess }"></text>
        </view>
        <text class="card-title" :style="{ color: theme.textPrimary }">取件服务</text>
        <text class="card-subtitle" :style="{ color: theme.textSecondary }">通过取件码或扫码取件</text>
        <button class="action-btn" :style="{ background: theme.colorAccentGradient, boxShadow: theme.shadowButton }">前往取件</button>
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

onLoad(() => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
});
</script>

<style scoped>
.locker-container {
  min-height: 100vh;
}
.page-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 48rpx;
  padding: 48rpx;
  height: 100%;
  box-sizing: border-box;
}
.action-card {
  width: 100%;
  border-radius: 32rpx;
  padding: 64rpx 48rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}
.card-icon-wrapper {
  width: 128rpx;
  height: 128rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32rpx;
}
.card-icon-wrapper .iconfont {
  font-size: 64rpx;
}
.card-title {
  font-size: 40rpx;
  font-weight: 700;
  margin-bottom: 16rpx;
}
.card-subtitle {
  font-size: 28rpx;
  margin-bottom: 48rpx;
}
.action-btn {
  width: 100%;
  height: 96rpx;
  border: none;
  border-radius: 24rpx;
  color: white;
  font-size: 32rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
  transition: all 0.3s ease;
}
.action-btn:active {
  transform: scale(0.98);
  opacity: 0.9;
}
</style>
