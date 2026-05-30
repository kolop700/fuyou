<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="快递结算单" :show-back="true" />

    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="segmented-control-wrapper">
        <view class="segmented-control" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
          <view
            v-for="tab in tabs"
            :key="tab.value"
            class="segment-item"
            :class="{ active: currentStatus === tab.value }"
            :style="getSegmentStyle(tab.value)"
            @tap="switchStatus(tab.value)"
          >
            {{ tab.label }}
          </view>
        </view>
      </view>

      <scroll-view
        scroll-y
        class="bill-list"
        :refresher-enabled="true"
        :refresher-triggered="refreshing"
        :refresher-background="theme.bgPrimary"
        @refresherrefresh="handleRefresh"
        @scrolltolower="loadMore"
      >
        <view v-if="bills.length > 0" class="list-content">
          <view
            v-for="bill in bills"
            :key="bill.id"
            class="bill-card"
            :style="{ background: theme.bgCard, borderColor: theme.borderColor }"
            @tap="toggleDetails(bill)"
          >
            <view class="bill-header">
              <view class="bill-title-wrap">
                <text class="bill-title" :style="{ color: theme.textPrimary }">{{ bill.no || `结算单 #${bill.id}` }}</text>
                <text class="bill-subtitle" :style="{ color: theme.textSecondary }">{{ bill.comm_name || '-' }} · {{ bill.user_name || '-' }}</text>
              </view>
              <view class="status-tag" :style="getBillStatusStyle(bill.status)">
                {{ getBillStatusLabel(bill.status) }}
              </view>
            </view>

            <view class="bill-body">
              <view class="amount-row">
                <text class="amount-label" :style="{ color: theme.textSecondary }">结算金额</text>
                <text class="amount-value" :style="{ color: theme.textPrimary }">¥{{ formatAmount(bill.amount) }}</text>
              </view>
              <view class="info-row">
                <text class="info-label" :style="{ color: theme.textSecondary }">结算周期</text>
                <text class="info-value" :style="{ color: theme.textPrimary }">{{ formatRange(bill.start_date, bill.end_date) }}</text>
              </view>
              <view class="info-row">
                <text class="info-label" :style="{ color: theme.textSecondary }">创建时间</text>
                <text class="info-value" :style="{ color: theme.textPrimary }">{{ formatDateTime(bill.created_at) }}</text>
              </view>
              <view v-if="isPaidBill(bill)" class="info-row">
                <text class="info-label" :style="{ color: theme.textSecondary }">结算时间</text>
                <text class="info-value" :style="{ color: theme.textPrimary }">{{ formatDateTime(bill.settle_time) }}</text>
              </view>
            </view>

            <view class="bill-actions" :style="{ borderTopColor: theme.borderColor }">
              <button
                class="secondary-button"
                :style="{ color: theme.colorAccent, borderColor: theme.borderColor, background: theme.bgSecondary }"
                @tap.stop="toggleDetails(bill)"
              >
                {{ expandedBillId === bill.id ? '收起明细' : '查看明细' }}
              </button>
              <button
                v-if="!isPaidBill(bill)"
                class="primary-button"
                :style="{ background: theme.colorAccentGradient }"
                :disabled="payingBillId === bill.id"
                @tap.stop="handlePay(bill)"
              >
                {{ payingBillId === bill.id ? '支付中...' : '支付结算' }}
              </button>
            </view>

            <view v-if="expandedBillId === bill.id" class="detail-panel" :style="{ borderTopColor: theme.borderColor }">
              <view v-if="detailLoading" class="detail-loading" :style="{ color: theme.textSecondary }">明细加载中...</view>
              <view v-else-if="currentDetails.length > 0" class="detail-list">
                <view
                  v-for="record in currentDetails"
                  :key="record.id"
                  class="detail-item"
                  :style="{ background: theme.bgSecondary }"
                >
                  <view class="detail-title-row">
                    <text class="detail-title" :style="{ color: theme.textPrimary }">{{ getRecordTitle(record) }}</text>
                    <text class="detail-amount" :style="{ color: theme.textPrimary }">¥{{ formatAmount(record.storage_fee) }}</text>
                  </view>
                  <view class="detail-meta" :style="{ color: theme.textSecondary }">
                    {{ record.locker_name || '-' }} · {{ record.compt_name || '-' }}
                  </view>
                  <view class="detail-meta" :style="{ color: theme.textSecondary }">
                    {{ formatDateTime(record.deposit_time) }}
                  </view>
                </view>
              </view>
              <view v-else class="detail-empty" :style="{ color: theme.textSecondary }">暂无结算明细</view>
            </view>
          </view>

          <view class="load-more" :style="{ color: theme.textSecondary }">{{ loadMoreText }}</view>
        </view>

        <view v-else class="empty-state">
          <text class="iconfont icon-clipboard-list empty-icon" :style="{ color: theme.textTertiary }"></text>
          <text class="empty-text" :style="{ color: theme.textSecondary }">{{ loading ? '加载中...' : '暂无结算单' }}</text>
        </view>
      </scroll-view>
    </view>

    <!-- 支付确认弹窗 -->
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
        <text class="modal-desc" :style="{ color: theme.textSecondary }">请在微信内完成结算单支付，支付成功后点击下方按钮确认。</text>
        <view v-if="currentPaymentBill" class="modal-bill" :style="{ background: theme.bgSecondary }">
          <text class="modal-bill-no" :style="{ color: theme.textPrimary }">{{ currentPaymentBill.no || `结算单 #${currentPaymentBill.id}` }}</text>
          <text class="modal-bill-amount" :style="{ color: theme.colorWarning }">¥{{ formatAmount(currentPaymentBill.amount) }}</text>
        </view>
      </view>

      <view class="modal-footer">
        <button
          class="btn-cancel"
          :style="{ background: theme.bgSecondary, color: theme.textSecondary }"
          @tap="retryPayment"
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
import { computed, getCurrentInstance, onUnmounted, ref } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const currentStatus = ref('');
const bills = ref([]);
const page = ref(1);
const size = ref(20);
const pages = ref(0);
const total = ref(0);
const loading = ref(false);
const loadingMore = ref(false);
const refreshing = ref(false);
const expandedBillId = ref(null);
const currentDetails = ref([]);
const detailLoading = ref(false);
const payingBillId = ref(null);
const showPaymentConfirm = ref(false);
const currentPaymentBill = ref(null);
const currentPaymentInfo = ref(null);
let pollTimer = null;

const tabs = [
  { label: '全部', value: '' },
  { label: '待结算', value: '0' },
  { label: '已结算', value: '1' }
];

const normalizeValue = (value) => {
  if (value && typeof value === 'object') {
    return String(value.value ?? '').trim();
  }
  const matched = String(value ?? '').match(/[0-9]/);
  return matched ? matched[0] : String(value ?? '').trim();
};

const loadMoreText = computed(() => {
  if (loadingMore.value) return '加载中...';
  if (pages.value && page.value >= pages.value) return '没有更多了';
  return '上拉加载更多';
});

const getSegmentStyle = (status) => {
  if (currentStatus.value === status) {
    return {
      background: theme.value.bgSecondary,
      color: theme.value.colorAccent,
      boxShadow: '0 2px 8px rgba(0,0,0,0.07)'
    };
  }

  return { color: theme.value.textSecondary };
};

const getBillStatusLabel = (status) => {
  const value = normalizeValue(status);
  return value === '1' ? '已结算' : '待结算';
};

const getBillStatusStyle = (status) => {
  const paid = normalizeValue(status) === '1';
  return {
    background: paid ? theme.value.getBadgeBackground('success') : theme.value.getBadgeBackground('warning'),
    color: paid ? theme.value.colorSuccess : theme.value.colorWarning
  };
};

const isPaidBill = (bill) => normalizeValue(bill?.status) === '1';

const formatAmount = (amount) => {
  const number = Number(amount || 0);
  return number.toFixed(2);
};

const formatDateTime = (value) => {
  if (!value) return '-';
  return String(value).replace('T', ' ').replace(/\.\d+$/, '').slice(0, 19);
};

const formatDate = (value) => {
  const text = formatDateTime(value);
  return text === '-' ? text : text.slice(0, 10);
};

const formatRange = (start, end) => `${formatDate(start)} 至 ${formatDate(end)}`;

const getRecordTitle = (record) => {
  if (normalizeValue(record?.storage_type) === '0') {
    return record.tracking_no ? `快递 ${record.tracking_no}` : '快递存货';
  }
  return `临时存货 #${record.id}`;
};

const invokeBillPayment = (paymentInfo) => {
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

    console.log('[settlement-bills] requestPayment orderInfo:', orderInfo);

    // #ifdef APP-PLUS
    uni.requestPayment({
      provider: 'wxpay',
      orderInfo,
      success: (res) => {
        console.log('[settlement-bills] requestPayment success:', res);
        resolve(res);
      },
      fail: (error) => {
        console.log('[settlement-bills] requestPayment fail:', error);
        reject(error);
      }
    });
    // #endif

    // #ifndef APP-PLUS
    reject(new Error('当前平台不支持直接调用微信支付'));
    // #endif
  });
};

const stopPolling = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
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

const fetchBills = async (reset = false) => {
  if (loading.value || loadingMore.value) return;

  if (reset) {
    page.value = 1;
    loading.value = true;
    expandedBillId.value = null;
    currentDetails.value = [];
  } else {
    if (pages.value && page.value >= pages.value) return;
    page.value += 1;
    loadingMore.value = true;
  }

  const requestParams = {
    page: page.value,
    size: size.value
  };

  if (currentStatus.value !== '') {
    requestParams.status = Number(currentStatus.value);
  }

  try {
    const res = await proxy.$api.locker.qryComptBill(requestParams, { showLoading: reset });
    const items = Array.isArray(res?.items) ? res.items : [];
    total.value = Number(res?.total || 0);
    pages.value = Number(res?.pages || 0);
    page.value = Number(res?.page || page.value);
    bills.value = reset ? items : bills.value.concat(items);
  } catch (error) {
    uni.showToast({ title: error?.msg || error?.detail || error?.message || '获取结算单失败', icon: 'none' });
    if (!reset) {
      page.value = Math.max(1, page.value - 1);
    }
  } finally {
    loading.value = false;
    loadingMore.value = false;
    refreshing.value = false;
  }
};

const fetchDetails = async (billId) => {
  detailLoading.value = true;
  currentDetails.value = [];

  try {
    const res = await proxy.$api.locker.qryComptRecord({
      bill_id: billId,
      page: 1,
      size: 100
    }, { showLoading: false });
    currentDetails.value = Array.isArray(res?.items) ? res.items : [];
  } catch (error) {
    uni.showToast({ title: error?.msg || error?.detail || error?.message || '获取明细失败', icon: 'none' });
  } finally {
    detailLoading.value = false;
  }
};

const toggleDetails = (bill) => {
  if (expandedBillId.value === bill.id) {
    expandedBillId.value = null;
    currentDetails.value = [];
    return;
  }

  expandedBillId.value = bill.id;
  fetchDetails(bill.id);
};

const handlePay = async (bill) => {
  if (!bill?.id || payingBillId.value) return;

  payingBillId.value = bill.id;
  try {
    const paymentInfo = await proxy.$api.locker.comptBillPay({ bill_id: bill.id });
    currentPaymentBill.value = bill;
    currentPaymentInfo.value = paymentInfo;
    showPaymentConfirm.value = true;
    startPolling();

    try {
      await invokeBillPayment(paymentInfo);
    } catch (paymentErr) {
      console.log('[settlement-bills] requestPayment callback fail:', paymentErr);
    }
  } catch (error) {
    uni.showToast({ title: error?.msg || error?.detail || error?.message || '支付失败，请重试', icon: 'none' });
  } finally {
    payingBillId.value = null;
  }
};

const getLatestPaymentBill = async () => {
  if (!currentPaymentBill.value?.id) return null;

  const res = await proxy.$api.locker.qryComptBill({
    page: 1,
    size: 100
  }, { showLoading: false });

  const items = Array.isArray(res?.items) ? res.items : [];
  return items.find(item => item?.id === currentPaymentBill.value.id) || null;
};

const closePaymentConfirm = () => {
  stopPolling();
  showPaymentConfirm.value = false;
};

const finishPaymentSuccess = (showToast = true) => {
  stopPolling();
  showPaymentConfirm.value = false;
  currentPaymentInfo.value = null;
  currentPaymentBill.value = null;

  if (showToast) {
    uni.showToast({ title: '支付成功', icon: 'success' });
  }

  setTimeout(() => {
    fetchBills(true);
  }, showToast ? 800 : 0);
};

const checkPaymentStatus = async (showLoader = true) => {
  const isShowLoader = typeof showLoader === 'boolean' ? showLoader : true;

  if (!currentPaymentBill.value?.id) return;

  if (isShowLoader) {
    uni.showLoading({ title: '正在确认...' });
  }

  try {
    const latestBill = await getLatestPaymentBill();

    if (isShowLoader) {
      uni.hideLoading();
    }

    if (latestBill && isPaidBill(latestBill)) {
      finishPaymentSuccess(isShowLoader);
      return;
    }

    if (isShowLoader) {
      uni.showToast({
        title: '尚未查询到支付成功状态，请稍后再试',
        icon: 'none',
        duration: 2000
      });
    }
  } catch (error) {
    console.log('[settlement-bills] checkPaymentStatus error:', error);
    if (isShowLoader) {
      uni.hideLoading();
      uni.showToast({ title: '查询状态失败，请重试', icon: 'none' });
    }
  }
};

const retryPayment = async () => {
  stopPolling();

  if (!currentPaymentBill.value?.id) return;

  uni.showLoading({ title: '正在确认状态...' });
  try {
    const latestBill = await getLatestPaymentBill();
    uni.hideLoading();

    if (latestBill && isPaidBill(latestBill)) {
      finishPaymentSuccess(true);
      return;
    }

    if (!currentPaymentInfo.value) {
      uni.showToast({ title: '缺少支付参数，请重新发起支付', icon: 'none' });
      return;
    }

    showPaymentConfirm.value = true;
    startPolling();

    try {
      await invokeBillPayment(currentPaymentInfo.value);
    } catch (paymentErr) {
      console.log('[settlement-bills] retry requestPayment callback fail:', paymentErr);
    }
  } catch (error) {
    uni.hideLoading();
    uni.showToast({ title: '状态确认失败，请重试', icon: 'none' });
  }
};

const handleRefresh = () => {
  refreshing.value = true;
  fetchBills(true);
};

const loadMore = () => {
  fetchBills(false);
};

const switchStatus = (status) => {
  if (currentStatus.value === status) return;
  currentStatus.value = status;
  fetchBills(true);
};

onLoad(() => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  fetchBills(true);
});

onUnmounted(() => {
  stopPolling();
});
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

.segmented-control-wrapper {
  padding: 0 48rpx 28rpx;
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

.bill-list {
  flex: 1;
  overflow-y: auto;
}

.list-content {
  padding: 0 32rpx 48rpx;
  display: flex;
  flex-direction: column;
  gap: 24rpx;
}

.bill-card {
  border-radius: 28rpx;
  padding: 28rpx;
  border: 1px solid transparent;
  box-shadow: 0 14rpx 40rpx rgba(15, 23, 42, 0.06);
}

.bill-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20rpx;
}

.bill-title-wrap {
  flex: 1;
  min-width: 0;
}

.bill-title {
  display: block;
  font-size: 32rpx;
  font-weight: 700;
  line-height: 1.4;
  word-break: break-all;
}

.bill-subtitle {
  display: block;
  margin-top: 8rpx;
  font-size: 24rpx;
}

.status-tag {
  padding: 8rpx 18rpx;
  border-radius: 999rpx;
  font-size: 22rpx;
  font-weight: 700;
  flex-shrink: 0;
}

.bill-body {
  margin-top: 24rpx;
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.amount-row,
.info-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24rpx;
}

.amount-label,
.info-label,
.info-value {
  font-size: 26rpx;
  line-height: 1.5;
}

.amount-value {
  font-size: 38rpx;
  line-height: 1.2;
  font-weight: 800;
}

.info-value {
  flex: 1;
  text-align: right;
  word-break: break-all;
}

.bill-actions {
  margin-top: 24rpx;
  padding-top: 20rpx;
  border-top: 1px solid transparent;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 20rpx;
}

.primary-button,
.secondary-button {
  margin: 0;
  min-width: 180rpx;
  height: 72rpx;
  line-height: 72rpx;
  border-radius: 18rpx;
  font-size: 26rpx;
  font-weight: 700;
  border: 1px solid transparent;
}

.primary-button {
  color: #ffffff;
}

.primary-button[disabled] {
  opacity: 0.65;
}

.detail-panel {
  margin-top: 24rpx;
  padding-top: 20rpx;
  border-top: 1px solid transparent;
}

.detail-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.detail-item {
  border-radius: 20rpx;
  padding: 20rpx;
}

.detail-title-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20rpx;
}

.detail-title {
  flex: 1;
  min-width: 0;
  font-size: 26rpx;
  font-weight: 700;
  line-height: 1.4;
  word-break: break-all;
}

.detail-amount {
  font-size: 26rpx;
  font-weight: 800;
  flex-shrink: 0;
}

.detail-meta {
  margin-top: 8rpx;
  font-size: 24rpx;
  line-height: 1.4;
}

.detail-loading,
.detail-empty {
  padding: 16rpx 0;
  text-align: center;
  font-size: 24rpx;
}

.load-more {
  text-align: center;
  padding: 16rpx 0 8rpx;
  font-size: 24rpx;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding-top: 160rpx;
}

.empty-icon {
  font-size: 96rpx;
  margin-bottom: 24rpx;
  opacity: 0.5;
}

.empty-text {
  font-size: 28rpx;
}

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
  border-bottom: 1px solid rgba(148, 163, 184, 0.1);
}

.modal-title {
  font-size: 34rpx;
  font-weight: 600;
  flex: 1;
  text-align: center;
}

.modal-body {
  padding: 48rpx;
  text-align: center;
}

.modal-desc {
  font-size: 30rpx;
  line-height: 1.6;
}

.modal-bill {
  margin-top: 32rpx;
  border-radius: 24rpx;
  padding: 24rpx;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24rpx;
}

.modal-bill-no {
  flex: 1;
  min-width: 0;
  text-align: left;
  font-size: 28rpx;
  font-weight: 700;
  word-break: break-all;
}

.modal-bill-amount {
  flex-shrink: 0;
  font-size: 32rpx;
  font-weight: 800;
}

.modal-footer {
  display: flex;
  padding: 32rpx;
  gap: 24rpx;
}

.btn-cancel,
.btn-confirm {
  flex: 1;
  height: 88rpx;
  border-radius: 44rpx;
  font-size: 32rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-cancel::after,
.btn-confirm::after {
  display: none;
}

.btn-cancel:active,
.btn-confirm:active {
  opacity: 0.9;
  transform: scale(0.98);
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
</style>
