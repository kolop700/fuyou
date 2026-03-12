<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏 -->
    <custom-navbar title="包裹取件" :show-back="true" />

    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="content-wrapper">
        <!-- 图标 -->
        <view class="icon-section">
          <text class="iconfont icon-box-archive main-icon" :style="{ color: theme.colorAccent }"></text>
        </view>

        <!-- 标题 -->
        <view class="text-section">
          <text class="title" :style="{ color: theme.textPrimary }">请输入取件码</text>
          <text class="subtitle" :style="{ color: theme.textSecondary }">输入取件码或快递单号以打开柜门</text>
        </view>

        <!-- 输入框 -->
        <view class="input-section">
          <view class="input-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <input 
              class="code-input" 
              type="text" 
              v-model="pickupCode" 
              placeholder="••••••" 
              :placeholder-style="'color: ' + theme.textTertiary"
              :style="{ color: theme.textPrimary }"
              maxlength="6"
            />
          </view>
        </view>

        <!-- 确认按钮 -->
        <view class="action-section">
          <button 
            class="action-btn" 
            :style="{ background: theme.colorAccentGradient, boxShadow: theme.shadowButton }"
            @tap="submitPickup"
          >
            确认取件
          </button>
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
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const pickupCode = ref('');

onLoad(() => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
});

const submitPickup = () => {
  if (!pickupCode.value || pickupCode.value.length < 4) {
    uni.showToast({ title: '请输入有效的取件码', icon: 'none' });
    return;
  }
  
  uni.showLoading({ title: '验证中...' });
  setTimeout(() => {
    uni.hideLoading();
    // 跳转到成功页面
    uni.navigateTo({
      url: '/workbench_package/pages/locker/deposit-success'
    });
  }, 1500);
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
  height: 100vh;
  box-sizing: border-box;
}

.content-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0 64rpx;
  margin-top: -120rpx; /* 视觉上稍微向上偏移 */
}

.icon-section {
  margin-bottom: 48rpx;
}

.main-icon {
  font-size: 120rpx;
}

.text-section {
  text-align: center;
  margin-bottom: 64rpx;
}

.title {
  font-size: 40rpx;
  font-weight: 700;
  margin-bottom: 16rpx;
  display: block;
}

.subtitle {
  font-size: 28rpx;
  display: block;
}

.input-section {
  width: 100%;
  margin-bottom: 64rpx;
}

.input-wrapper {
  height: 120rpx;
  border-radius: 24rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
  transition: all 0.3s ease;
}

.code-input {
  width: 100%;
  height: 100%;
  font-size: 48rpx;
  text-align: center;
  letter-spacing: 0.5em;
  font-weight: 700;
}

.action-section {
  width: 100%;
}

.action-btn {
  width: 100%;
  height: 96rpx;
  border-radius: 28rpx;
  color: white;
  font-size: 32rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.action-btn:active {
  transform: scale(0.98);
  opacity: 0.9;
}
</style>