<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="收银台" :show-back="true" />
    
    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <!-- 支付金额头部 -->
      <view class="amount-header" :style="{ background: theme.bgCard }">
        <text class="amount-label" :style="{ color: theme.textSecondary }">需支付金额</text>
        <view class="amount-value">
          <text class="currency" :style="{ color: theme.textPrimary }">¥</text>
          <text class="price" :style="{ color: theme.textPrimary }">{{ amount }}</text>
        </view>
      </view>

      <!-- 支付方式列表 -->
      <view class="payment-methods" :style="{ background: theme.bgCard }">
        <text class="section-title" :style="{ color: theme.textSecondary }">请选择支付方式</text>
        
        <view 
          class="method-item" 
          v-for="(item, index) in paymentMethods" 
          :key="index"
          @tap="selectMethod(item.id)"
          :style="{ borderBottomColor: index === paymentMethods.length - 1 ? 'transparent' : theme.dividerColor }"
        >
          <view class="method-left">
            <text class="iconfont method-icon" :class="item.icon" :style="{ color: item.color }"></text>
            <view class="method-info">
              <text class="method-name" :style="{ color: theme.textPrimary }">{{ item.name }}</text>
              <text v-if="item.desc" class="method-desc" :style="{ color: theme.textTertiary }">{{ item.desc }}</text>
            </view>
          </view>
          <view class="radio-box" :class="{ active: selectedMethod === item.id }">
            <text v-if="selectedMethod === item.id" class="iconfont icon-fa-check" style="color: white; font-size: 24rpx;"></text>
          </view>
        </view>
      </view>

      <!-- 底部支付按钮 -->
      <view class="footer-section" :style="{ background: theme.bgPrimary, borderTopColor: theme.dividerColor }">
        <button 
          class="pay-btn" 
          :style="{ background: selectedMethod === 'wechat' ? '#07C160' : '#1677FF' }"
          @tap="showConfirmModal = true"
        >
          {{ selectedMethod === 'wechat' ? '微信支付' : '支付宝支付' }} ¥{{ amount }}
        </button>
      </view>
    </view>

    <!-- 确认支付弹窗 (底部半屏) -->
    <view class="modal-overlay" v-if="showConfirmModal" @tap="showConfirmModal = false"></view>
    <view class="confirm-modal" :class="{ 'modal-show': showConfirmModal }" :style="{ background: theme.bgCard }">
      <view class="modal-header">
        <text class="cancel-text" :style="{ color: theme.textSecondary }" @tap="showConfirmModal = false">取消</text>
        <text class="modal-title" :style="{ color: theme.textPrimary }">确认支付</text>
        <text class="placeholder">取消</text> <!-- 用于占位居中 -->
      </view>
      
      <view class="modal-body">
        <text class="merchant-name" :style="{ color: theme.textSecondary }">智能快递柜服务</text>
        <text class="modal-amount" :style="{ color: theme.textPrimary }">¥ {{ amount }}</text>
        
        <view class="payment-detail-row" :style="{ borderTopColor: theme.dividerColor, borderBottomColor: theme.dividerColor }">
          <text class="detail-label" :style="{ color: theme.textSecondary }">支付方式</text>
          <view class="detail-value">
            <text class="iconfont" :class="selectedMethod === 'wechat' ? 'icon-a-fabfa-weixin' : 'icon-f-alipay'" 
                  :style="{ color: selectedMethod === 'wechat' ? '#07C160' : '#1677FF', marginRight: '12rpx' }"></text>
            <text :style="{ color: theme.textPrimary }">{{ selectedMethod === 'wechat' ? '微信支付' : '支付宝' }}</text>
          </view>
        </view>
      </view>
      
      <view class="modal-footer">
        <button 
          class="confirm-btn" 
          :style="{ background: selectedMethod === 'wechat' ? '#07C160' : '#1677FF' }"
          @tap="processPayment"
        >
          确认支付
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
import { ref, computed, getCurrentInstance } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useThemeStore } from '@/store/modules/theme';
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const amount = ref('2.00');
const selectedMethod = ref('wechat');
const showConfirmModal = ref(false);

const paymentMethods = [
  { id: 'wechat', name: '微信支付', desc: '微信安全支付', icon: 'icon-a-fabfa-weixin', color: '#07C160' },
  { id: 'alipay', name: '支付宝支付', desc: '支付宝安全支付', icon: 'icon-f-alipay', color: '#1677FF' }
];

onLoad((options) => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  
  if (options.amount) {
    amount.value = parseFloat(options.amount).toFixed(2);
  }
});

const selectMethod = (id) => {
  selectedMethod.value = id;
};

const processPayment = () => {
  showConfirmModal.value = false;
  uni.showLoading({ title: '支付中...', mask: true });
  
  setTimeout(() => {
    uni.hideLoading();
    uni.navigateTo({
      url: `/workbench_package/pages/payment/success?amount=${amount.value}&method=${selectedMethod.value}`
    });
  }, 1500);
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
  position: relative;
}

.page-content {
  box-sizing: border-box;
}

/* 金额头部 */
.amount-header {
  padding: 80rpx 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin-bottom: 24rpx;
}

.amount-label {
  font-size: 28rpx;
  margin-bottom: 16rpx;
}

.amount-value {
  display: flex;
  align-items: baseline;
}

.currency {
  font-size: 48rpx;
  font-weight: 600;
  margin-right: 8rpx;
}

.price {
  font-size: 80rpx;
  font-weight: 700;
}

/* 支付方式列表 */
.payment-methods {
  padding: 0 32rpx;
}

.section-title {
  font-size: 26rpx;
  padding: 32rpx 0 16rpx;
  display: block;
}

.method-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 32rpx 0;
  border-bottom: 1px solid;
}

.method-left {
  display: flex;
  align-items: center;
}

.method-icon {
  font-size: 56rpx;
  margin-right: 24rpx;
}

.method-info {
  display: flex;
  flex-direction: column;
}

.method-name {
  font-size: 32rpx;
  font-weight: 500;
}

.method-desc {
  font-size: 24rpx;
  margin-top: 4rpx;
}

/* 单选框 */
.radio-box {
  width: 44rpx;
  height: 44rpx;
  border-radius: 50%;
  border: 2rpx solid #d1d5db;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  box-sizing: border-box;
}

.radio-box.active {
  background-color: #ef4444; /* 可以跟随主题，这里用红色表示选中，或者跟随支付方式颜色 */
  border-color: #ef4444;
}

/* 底部按钮 */
.footer-section {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 24rpx 32rpx;
  padding-bottom: calc(24rpx + env(safe-area-inset-bottom));
  border-top: 1px solid;
}

.pay-btn {
  width: 100%;
  height: 96rpx;
  border-radius: 48rpx;
  color: white;
  font-size: 34rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.pay-btn:active {
  opacity: 0.9;
  transform: scale(0.98);
}

/* 确认支付弹窗 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 1000;
  animation: fadeIn 0.3s ease;
}

.confirm-modal {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  border-radius: 32rpx 32rpx 0 0;
  z-index: 1001;
  transform: translateY(100%);
  transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  padding-bottom: env(safe-area-inset-bottom);
}

.confirm-modal.modal-show {
  transform: translateY(0);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 32rpx;
}

.cancel-text {
  font-size: 30rpx;
}

.modal-title {
  font-size: 34rpx;
  font-weight: 600;
}

.placeholder {
  font-size: 30rpx;
  opacity: 0;
  pointer-events: none;
}

.modal-body {
  padding: 48rpx 32rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.merchant-name {
  font-size: 30rpx;
  margin-bottom: 16rpx;
}

.modal-amount {
  font-size: 72rpx;
  font-weight: 700;
  margin-bottom: 64rpx;
}

.payment-detail-row {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 32rpx 0;
  border-top: 1px solid;
  border-bottom: 1px solid;
}

.detail-label {
  font-size: 30rpx;
}

.detail-value {
  display: flex;
  align-items: center;
  font-size: 30rpx;
  font-weight: 500;
}

.modal-footer {
  padding: 32rpx;
}

.confirm-btn {
  width: 100%;
  height: 96rpx;
  border-radius: 16rpx;
  color: white;
  font-size: 34rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.confirm-btn:active {
  opacity: 0.9;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
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