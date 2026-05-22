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
          <text class="title" :style="{ color: theme.textPrimary }">请输入取件信息</text>
          <text class="subtitle" :style="{ color: theme.textSecondary }">请选择使用取件码或快递单号开柜</text>
        </view>

        <!-- 切换栏 -->
        <view class="segmented-control-wrapper">
          <view class="segmented-control" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <view 
              class="segment-item" 
              :class="{ active: inputType === 'pickupCode' }"
              @tap="inputType = 'pickupCode'"
              :style="inputType === 'pickupCode' ? { background: theme.bgSecondary, color: theme.colorAccent, boxShadow: '0 2px 8px rgba(0,0,0,0.07)' } : { color: theme.textSecondary }"
            >
              取件码
            </view>
            <view 
              class="segment-item" 
              :class="{ active: inputType === 'trackingNo' }"
              @tap="inputType = 'trackingNo'"
              :style="inputType === 'trackingNo' ? { background: theme.bgSecondary, color: theme.colorAccent, boxShadow: '0 2px 8px rgba(0,0,0,0.07)' } : { color: theme.textSecondary }"
            >
              快递单号
            </view>
          </view>
        </view>

        <!-- 输入框 -->
        <view class="input-section">
          <view class="input-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <input 
              v-if="inputType === 'pickupCode'"
              class="code-input" 
              type="text" 
              v-model="pickupCode" 
              placeholder="输入取件码" 
              :placeholder-style="'color: ' + theme.textTertiary"
              :style="{ color: theme.textPrimary }"
            />
            <input 
              v-else
              class="tracking-input" 
              type="text" 
              v-model="trackingNo" 
              placeholder="输入快递单号" 
              :placeholder-style="'color: ' + theme.textTertiary"
              :style="{ color: theme.textPrimary }"
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

    <!-- 超时支付提示弹窗 -->
    <view class="modal-overlay" v-if="showPaymentModal" @touchmove.stop.prevent></view>
    <view class="custom-modal" :class="{ 'modal-show': showPaymentModal }" :style="{ background: theme.bgCard }">
      <!-- 弹窗关闭按钮 -->
      <view class="modal-close-btn" @tap="showPaymentModal = false">
        <uni-icons type="closeempty" size="24" :color="theme.textTertiary"></uni-icons>
      </view>
      
      <view class="modal-icon-wrapper" :style="{ background: theme.getBadgeBackground('warning') }">
        <text class="iconfont icon-a-fasfa-info-circle" :style="{ color: theme.colorWarning }"></text>
      </view>
      <text class="modal-title" :style="{ color: theme.textPrimary }">支付超时费用</text>
      <text class="modal-content" :style="{ color: theme.textSecondary }">您的包裹已产生超时费用，需支付后方可开柜</text>
      
      <view class="modal-actions">
        <button 
          class="btn-cancel" 
          :style="{ background: theme.bgSecondary, color: theme.textSecondary }"
          @tap="showPaymentModal = false"
        >
          取消
        </button>
        <button 
          class="btn-confirm" 
          :style="{ background: theme.colorAccentGradient, color: '#fff', boxShadow: theme.shadowButton }"
          @tap="goToPayment"
        >
          去支付
        </button>
      </view>
    </view>

    <!-- 支付确认弹窗 (与临时存货一致) -->
    <view class="modal-overlay" v-if="showPaymentConfirm" @touchmove.stop.prevent></view>
    <view class="confirm-modal" :class="{ 'modal-show': showPaymentConfirm }" :style="{ background: theme.bgCard }">
      <view class="modal-header">
        <text class="placeholder" style="width: 48rpx;"></text>
        <text class="modal-title" :style="{ color: theme.textPrimary }">确认支付状态</text>
        <view @tap="closePaymentConfirm" style="padding: 10rpx;">
          <uni-icons type="closeempty" size="24" :color="theme.textSecondary"></uni-icons>
        </view>
      </view>
      
      <view class="modal-body">
        <text class="modal-desc" :style="{ color: theme.textSecondary }">请在微信/支付宝内完成支付，支付成功后点击下方按钮确认。</text>
      </view>
      
      <view class="modal-footer">
        <button 
          class="btn-cancel" 
          :style="{ background: theme.bgSecondary, color: theme.textSecondary }"
          @tap="cancelPayment"
        >
          重新支付
        </button>
        <button 
          class="btn-confirm" 
          :style="{ background: theme.colorAccentGradient, color: '#fff' }"
          @tap="checkPaymentStatus"
        >
          已完成支付
        </button>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onUnmounted } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useThemeStore } from '@/store/modules/theme';
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const userStore = proxy.$store.user.useUserStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const lockerId = ref(1); // 快递柜 ID，目前写死为 1
const pickupCode = ref('');
const trackingNo = ref('');
const inputType = ref('pickupCode'); // 'pickupCode' | 'trackingNo'
const showPaymentModal = ref(false);
const pendingPaymentInfo = ref(null);

const showPaymentConfirm = ref(false);
let pollTimer = null;

const stopPolling = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
};

onUnmounted(() => {
  stopPolling();
});

onLoad((options) => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  if (options && options.locker_id) {
    lockerId.value = Number(options.locker_id);
  }
});

const getOpenId = () => {
  const userInfo = userStore.userInfo || {};

  return userInfo.openid || userInfo.wx_openid || userInfo.open_id || uni.getStorageSync('openid') || '0';
};

const submitPickup = async () => {
  let pickCode = '';
  let orderNo = '';
  
  if (inputType.value === 'pickupCode') {
    pickCode = String(pickupCode.value || '').trim();
    if (!pickCode || pickCode.length < 4) {
      uni.showToast({ title: '请输入有效的取件码', icon: 'none' });
      return;
    }
  } else {
    orderNo = String(trackingNo.value || '').trim();
    if (!orderNo) {
      uni.showToast({ title: '请输入快递单号', icon: 'none' });
      return;
    }
  }

  uni.showLoading({ title: '验证中...' });
  try {
    const res = await proxy.$api.locker.pickup({
      pickup_code: pickCode,
      tracking_no: orderNo
    });
    uni.hideLoading();
    
    // 检查是否返回了支付参数 (如 prepayId) 说明需要支付超时费用
    if (res && res.prepayId) {
      pendingPaymentInfo.value = res;
      showPaymentModal.value = true;
    } else {
      // 无需支付，直接开柜
      uni.showToast({ title: '开柜成功', icon: 'success' });
      setTimeout(() => {
        uni.navigateBack();
      }, 1000);
    }
  } catch (e) {
    uni.hideLoading();
    uni.showToast({ title: e?.msg || '取件码错误，请重试', icon: 'none' });
  }
};

const invokePayment = (paymentInfo) => {
  return new Promise((resolve, reject) => {
    const orderInfo = {
      appid: paymentInfo?.appId || '',
      partnerid: paymentInfo?.partnerId || '',
      prepayid: paymentInfo?.prepayId || '',
      package: paymentInfo?.packageValue || 'Sign=WXPay',
      noncestr: paymentInfo?.nonceStr || '',
      timestamp: String(paymentInfo?.timestamp || ''),
      sign: paymentInfo?.sign || ''
    };

    console.log('[pickup] requestPayment orderInfo:', orderInfo);

    // #ifdef APP-PLUS
    uni.requestPayment({
      provider: 'wxpay',
      orderInfo,
      success: (res) => {
        console.log('[pickup] requestPayment success:', res);
        resolve(res);
      },
      fail: (error) => {
        console.log('[pickup] requestPayment fail:', error);
        reject(error);
      }
    });
    // #endif

    // #ifndef APP-PLUS
    reject(new Error('当前平台不支持直接调用微信支付'));
    // #endif
  });
};

const startPolling = () => {
  stopPolling();
  pollTimer = setInterval(async () => {
    if (showPaymentConfirm.value) {
      await checkPaymentStatus(false);
    } else {
      stopPolling();
    }
  }, 2000);
};

const getTargetRecord = (res) => {
  const items = Array.isArray(res?.items) ? res.items : [];
  return items.find(item => item?.compt_record_no === pendingPaymentInfo.value?.compt_record_no) || items[0] || null;
};

const normalizePayStatus = (status) => {
  if (!status) return '';
  if (typeof status === 'object') {
    if (status.value !== undefined && status.value !== null) {
      return String(status.value).trim();
    }
    if (status.label) {
      return String(status.label).match(/[0-4]/)?.[0] || '';
    }
    return '';
  }
  return String(status).match(/[0-4]/)?.[0] || String(status).trim();
};

const goToPayment = async () => {
  showPaymentModal.value = false;
  if (!pendingPaymentInfo.value) return;

  showPaymentConfirm.value = true;
  startPolling();

  try {
    await invokePayment(pendingPaymentInfo.value);
  } catch (e) {
    console.log('前端支付接口回调未成功:', e);
  }
};

const cancelPayment = async () => {
  stopPolling();
  if (!pendingPaymentInfo.value?.compt_record_no) return;

  uni.showLoading({ title: '正在确认状态...' });
  try {
    const res = await proxy.$api.locker.qryComptRecord({
      page: 1,
      size: 50,
      compt_record_no: pendingPaymentInfo.value.compt_record_no,
      bill_id: 0
    }, { showLoading: false });
    
    const record = getTargetRecord(res);
    // 取件超时支付看的是 pickup_pay_sta 字段
    const payStatus = normalizePayStatus(record?.pickup_pay_sta);
    
    uni.hideLoading();

    if (payStatus === '2') {
      uni.showToast({ title: '支付成功，开柜成功', icon: 'success' });
      setTimeout(() => {
        uni.navigateBack();
      }, 1000);
      return;
    }

    showPaymentConfirm.value = true;
    startPolling();

    try {
      await invokePayment(pendingPaymentInfo.value);
    } catch (e) {
      console.log('[pickup] retry requestPayment fail:', e);
    }
  } catch (e) {
    uni.hideLoading();
    uni.showToast({ title: '状态确认失败，请重试', icon: 'none' });
  }
};

const closePaymentConfirm = () => {
  stopPolling();
  showPaymentConfirm.value = false;
};

const checkPaymentStatus = async (showLoader = true) => {
  const isShowLoader = typeof showLoader === 'boolean' ? showLoader : true;
  if (!pendingPaymentInfo.value?.compt_record_no) return;
  
  if (isShowLoader) {
    uni.showLoading({ title: '正在确认...' });
  }
  
  try {
    const res = await proxy.$api.locker.qryComptRecord({
      page: 1,
      size: 50,
      compt_record_no: pendingPaymentInfo.value.compt_record_no,
      bill_id: 0
    }, { showLoading: false });
    
    const record = getTargetRecord(res);
    // 取件超时支付看的是 pickup_pay_sta 字段
    const payStatus = normalizePayStatus(record?.pickup_pay_sta);
    
    if (isShowLoader) {
      uni.hideLoading();
    }
    
    if (payStatus === '2') {
      stopPolling();
      showPaymentConfirm.value = false;
      if (isShowLoader) {
        uni.showToast({ title: '支付成功，开柜成功', icon: 'success' });
      }
      setTimeout(() => {
        uni.navigateBack();
      }, isShowLoader ? 1000 : 0);
    } else {
      if (isShowLoader) {
        uni.showToast({
          title: '尚未查询到支付成功状态，请稍后再试',
          icon: 'none',
          duration: 2000
        });
      }
    }
  } catch (e) {
    console.log('[pickup] checkPaymentStatus error:', e);
    if (isShowLoader) {
      uni.hideLoading();
      uni.showToast({ title: '查询状态失败，请重试', icon: 'none' });
    }
  }
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

/* 顶部切换栏 */
.segmented-control-wrapper {
  width: 100%;
  margin-bottom: 48rpx;
}

.segmented-control {
  display: flex;
  border-radius: 24rpx;
  padding: 8rpx;
  border: 1px solid transparent;
}

.segment-item {
  flex: 1;
  text-align: center;
  padding: 16rpx 0;
  border-radius: 18rpx;
  font-size: 28rpx;
  font-weight: 600;
  transition: all 0.3s ease;
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
  font-size: 40rpx;
  text-align: center;
  font-weight: 700;
}

.tracking-input {
  width: 100%;
  height: 100%;
  font-size: 32rpx;
  text-align: center;
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

/* 自定义弹窗 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 1000;
  animation: fadeIn 0.3s ease;
  backdrop-filter: blur(4px);
}

.custom-modal {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%) scale(0.9);
  width: 600rpx;
  border-radius: 32rpx;
  padding: 48rpx 40rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  z-index: 1001;
  opacity: 0;
  pointer-events: none;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow: 0 20rpx 40rpx rgba(0, 0, 0, 0.1);
}

.custom-modal.modal-show {
  transform: translate(-50%, -50%) scale(1);
  opacity: 1;
  pointer-events: auto;
}

.modal-close-btn {
  position: absolute;
  top: 24rpx;
  right: 24rpx;
  width: 64rpx;
  height: 64rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: opacity 0.2s ease;
}

.modal-close-btn:active {
  opacity: 0.6;
}

.modal-close-btn .iconfont {
  font-size: 40rpx;
}

.modal-icon-wrapper {
  width: 96rpx;
  height: 96rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 24rpx;
}

.modal-icon-wrapper .iconfont {
  font-size: 48rpx;
}

.modal-title {
  font-size: 36rpx;
  font-weight: 700;
  margin-bottom: 16rpx;
}

.modal-content {
  font-size: 28rpx;
  text-align: center;
  line-height: 1.5;
  margin-bottom: 48rpx;
}

.modal-actions {
  width: 100%;
  display: flex;
  gap: 24rpx;
}

.btn-cancel, .btn-confirm {
  flex: 1;
  height: 88rpx;
  border-radius: 24rpx;
  font-size: 30rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-cancel:active, .btn-confirm:active {
  opacity: 0.9;
  transform: scale(0.98);
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* 支付确认弹窗 (底部) */
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
  border-bottom: 1px solid rgba(148, 163, 184, 0.1);
}

.modal-title {
  font-size: 34rpx;
  font-weight: 600;
  flex: 1;
  text-align: center;
}

.modal-desc {
  font-size: 30rpx;
  line-height: 1.6;
}

.modal-body {
  padding: 64rpx 48rpx;
  text-align: center;
}

.modal-footer {
  display: flex;
  padding: 32rpx;
  gap: 24rpx;
}
</style>
