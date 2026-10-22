<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="物业报修" :show-back="true" />
    
    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="header-section">
        <text class="page-title" :style="{ color: theme.textPrimary }">物业报修</text>
        <text class="page-subtitle" :style="{ color: theme.textSecondary }">快捷报修，即时响应</text>
      </view>

      <view class="cards-section">
        <!-- 我要报修 -->
        <view class="action-card" 
              :style="{ background: theme.bgCard, boxShadow: theme.shadowCard }"
              @tap="handleNavigate('/workbench_package/pages/repair/report')">
          <view class="card-header">
            <view class="icon-wrapper" style="background: rgba(59, 130, 246, 0.1); color: #3b82f6;">
              <text class="iconfont icon-screwdriver-wrench"></text>
            </view>
            <text class="card-title" :style="{ color: theme.textPrimary }">我要报修</text>
          </view>
          <text class="card-desc" :style="{ color: theme.textSecondary }">提交新的报修工单，如水电、家电维修等。</text>
          <button class="action-btn btn-primary" :style="{ background: theme.colorAccent }">立即提交</button>
        </view>

        <!-- 我的报修 -->
        <view class="action-card" 
              :style="{ background: theme.bgCard, boxShadow: theme.shadowCard }"
              @tap="handleNavigate('/workbench_package/pages/repair/my-repairs')">
          <view class="card-header">
            <view class="icon-wrapper" style="background: rgba(34, 197, 94, 0.1); color: #22c55e;">
              <text class="iconfont icon-clipboard-list"></text>
            </view>
            <text class="card-title" :style="{ color: theme.textPrimary }">我的报修</text>
          </view>
          <text class="card-desc" :style="{ color: theme.textSecondary }">查看历史报修记录及处理进度。</text>
          <button class="action-btn btn-secondary" 
                  :style="{ background: theme.bgSecondary, color: theme.colorAccent, borderColor: theme.borderColor }">
            查看记录
          </button>
        </view>
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

const handleNavigate = (url) => {
  uni.navigateTo({ url });
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
  transition: background 0.3s ease;
}

.page-content {
  padding: 48rpx;
  box-sizing: border-box;
}

.header-section {
  margin-bottom: 64rpx;
  padding-top: 24rpx;
}

.page-title {
  font-size: 48rpx;
  font-weight: 700;
  margin-bottom: 16rpx;
  display: block;
}

.page-subtitle {
  font-size: 30rpx;
  display: block;
}

.cards-section {
  display: flex;
  flex-direction: column;
  gap: 40rpx;
}

.action-card {
  border-radius: 32rpx;
  padding: 40rpx;
  transition: transform 0.2s ease;
}

.action-card:active {
  transform: scale(0.98);
}

.card-header {
  display: flex;
  align-items: center;
  margin-bottom: 24rpx;
}

.icon-wrapper {
  width: 80rpx;
  height: 80rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 24rpx;
}

.icon-wrapper .iconfont {
  font-size: 40rpx;
}

.card-title {
  font-size: 36rpx;
  font-weight: 700;
}

.card-desc {
  font-size: 28rpx;
  margin-bottom: 32rpx;
  display: block;
  line-height: 1.5;
}

.action-btn {
  width: 100%;
  height: 88rpx;
  border-radius: 24rpx;
  font-size: 28rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
}

.btn-primary {
  color: white;
  border: none;
}

.btn-secondary {
  border-width: 1px;
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
}

/* Tab 页：横幅悬浮在自定义 tabbar（高100rpx+安全区）上方 */
.ad-section.ad-tab {
  bottom: calc(100rpx + env(safe-area-inset-bottom));
  box-shadow: 0 -4rpx 16rpx rgba(31, 48, 152, 0.12);
}
</style>