<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏 -->
    <custom-navbar title="临时存货" :show-back="true" />

    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="form-container">
        <!-- 快递柜 ID（写死为 1） -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">快递柜编号</text>
          <view class="picker-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <text class="picker-text" :style="{ color: theme.textPrimary }">{{ lockerName || '快递柜 #' + lockerId }}</text>
          </view>
        </view>

        <!-- 柜格型号 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">柜格型号</text>
          <view class="spec-list">
            <view 
              v-for="(item) in sizeOptions" 
              :key="item.id"
              class="spec-row"
              :class="{ active: selectedSpecId === item.id, disabled: item.idle_count === 0 }"
              :style="{ 
                background: selectedSpecId === item.id ? theme.getBadgeBackground('warning') : theme.bgCard,
                borderColor: selectedSpecId === item.id ? theme.colorWarning : theme.borderColor,
                opacity: item.idle_count === 0 ? 0.45 : 1
              }"
              @tap="selectSize(item)"
            >
              <!-- 左侧：选中圆点 -->
              <view class="spec-radio" :style="{ borderColor: selectedSpecId === item.id ? theme.colorWarning : theme.borderColor }">
                <view v-if="selectedSpecId === item.id" class="spec-radio-dot" :style="{ background: theme.colorWarning }"></view>
              </view>
              <!-- 中间：规格名 -->
              <text class="spec-name" :style="{ color: item.idle_count === 0 ? theme.textTertiary : selectedSpecId === item.id ? theme.colorWarning : theme.textPrimary }">{{ item.name }}</text>
              <!-- 右侧：数量标签 -->
              <view class="spec-badge" :style="{ background: item.idle_count === 0 ? theme.bgSecondary : theme.getBadgeBackground('success') }">
                <text class="spec-badge-text" :style="{ color: item.idle_count === 0 ? theme.textTertiary : theme.colorSuccess }">
                  {{ item.idle_count === 0 ? '已满' : '剩余 ' + item.idle_count + ' 格' }}
                </text>
              </view>
            </view>
          </view>
        </view>

        <!-- 存货时长 -->
        <view class="form-group">
        <text class="form-label" :style="{ color: theme.textSecondary }">存货时长 (小时)</text>
        <view class="input-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
          <input 
            class="form-input" 
            type="number" 
            v-model="duration" 
            placeholder="请输入整数小时" 
            :placeholder-style="'color: ' + theme.textTertiary"
            :style="{ color: theme.textPrimary }"
            @input="handleDurationInput"
          />
            <view class="icon-wrapper">
              <text class="iconfont icon-fa-clock input-icon" :style="{ color: theme.textSecondary }"></text>
            </view>
          </view>
        </view>

      </view>

      <!-- 底部按钮 -->
      <view class="footer-section">
        <button 
          class="action-btn" 
          :style="{ background: theme.colorAccentGradient, boxShadow: theme.shadowButton }"
          @tap="submitStorage"
        >
          开始存货
        </button>
      </view>
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
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const lockerId = ref(1); // 快递柜 ID，目前写死为 1
const lockerName = ref('');

// 表单数据
const selectedSpecId = ref(null);
const duration = ref(1);
const sizeOptions = ref([]); // 从接口获取

const showPaymentConfirm = ref(false);
const currentComptRecordNo = ref('');
const currentPaymentInfo = ref(null);
let pollTimer = null; // 轮询定时器

const stopPolling = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
};

onUnmounted(() => {
  stopPolling();
});

const fetchLockerInfo = async (id) => {
  try {
    const res = await proxy.$api.locker.getLockerInfo(id, { showLoading: false });
    // 检查快递柜是否已启用
    if (res?.status?.value !== 1) {
      uni.showModal({
        title: '快递柜不可用',
        content: `「${res?.name || '该快递柜'}」当前状态为「${res?.status?.label || '未启用'}」，暂时无法使用`,
        showCancel: false,
        confirmText: '返回',
        success: () => uni.navigateBack()
      });
      return;
    }
    lockerName.value = res?.name || `快递柜 #${id}`;
    const specs = res?.specs || [];
    sizeOptions.value = specs;
    const first = specs.find(s => s.idle_count > 0);
    selectedSpecId.value = first ? first.id : null;
  } catch (e) {
    uni.showToast({ title: '获取格口信息失败', icon: 'none' });
  }
};

onLoad((options) => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  if (options && options.locker_id) {
    lockerId.value = Number(options.locker_id);
  }
  fetchLockerInfo(lockerId.value);
});

const selectSize = (item) => {
  if (item.idle_count === 0) return;
  selectedSpecId.value = item.id;
};

const handleDurationInput = (event) => {
  const rawValue = event?.detail?.value ?? duration.value;
  const integerValue = String(rawValue).replace(/[^\d]/g, '');
  duration.value = integerValue;
};

const getComptRecordNo = (res) => {
  return res?.compt_record_no || res?.data?.compt_record_no || res?.record?.compt_record_no || '';
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

const getRecordPayStatus = (record) => {
  return normalizePayStatus(record?.storage_pay_sta);
};

const getTargetRecord = (res) => {
  const items = Array.isArray(res?.items) ? res.items : [];
  return items.find(item => item?.compt_record_no === currentComptRecordNo.value) || items[0] || null;
};

const invokeTempDepositPayment = (paymentInfo) => {
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

    console.log('[temp-storage] requestPayment orderInfo:', orderInfo);

    // #ifdef APP-PLUS
    uni.requestPayment({
      provider: 'wxpay',
      orderInfo,
      success: (res) => {
        console.log('[temp-storage] requestPayment success:', res);
        resolve(res);
      },
      fail: (error) => {
        console.log('[temp-storage] requestPayment fail:', error);
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
  stopPolling(); // 确保不重复启动
  pollTimer = setInterval(async () => {
    if (showPaymentConfirm.value) {
      await checkPaymentStatus(false);
    } else {
      stopPolling();
    }
  }, 2000); // 每 2 秒查一次
};

const submitStorage = async () => {
  if (!selectedSpecId.value) {
    uni.showToast({ title: '请选择柜格型号', icon: 'none' });
    return;
  }
  const hours = parseInt(duration.value, 10);
  if (!Number.isInteger(hours) || hours <= 0) {
    uni.showToast({ title: '请输入有效的整数小时', icon: 'none' });
    return;
  }
  const requestParams = {
    locker_id: lockerId.value,
    spec_id: selectedSpecId.value,
    hours
  };

  console.log('[temp-storage] tempBeginDeposit params:', requestParams);

  uni.showLoading({ title: '提交中...' });

  try {
    const res = await proxy.$api.locker.tempBeginDeposit(requestParams);

    console.log('[temp-storage] tempBeginDeposit response:', res);

    const comptRecordNo = getComptRecordNo(res);

    if (!comptRecordNo) {
      throw new Error('缺少存货记录号，无法确认支付状态');
    }

    currentComptRecordNo.value = comptRecordNo;
    currentPaymentInfo.value = res;

    // 隐藏 loading，并在跳转支付前直接显示确认弹窗
    // 这样当用户从微信/支付宝切回 APP 时，弹窗就已经展示在页面上了
    uni.hideLoading();
    showPaymentConfirm.value = true;
    
    // 开启后台轮询，防止用户点击错误或者忘记点击
    startPolling();

    try {
      // 唤起 APP 支付
      await invokeTempDepositPayment(res);
    } catch (paymentErr) {
      // 如果用户取消了支付，或者支付出错，我们不直接抛出异常
      // 而是允许用户通过弹窗上的按钮去主动查单，或者选择“重新支付”
      console.log('前端支付接口回调未成功:', paymentErr);
    }
  } catch (e) {
    uni.hideLoading();
    uni.showToast({ title: e?.message || '提交失败，请重试', icon: 'none' });
  }
};

const cancelPayment = async () => {
  stopPolling();
  
  if (!currentComptRecordNo.value) return;

  // 在重新支付前，先查一下是不是其实已经支付成功了
  uni.showLoading({ title: '正在确认状态...' });
  try {
    const requestParams = {
      page: 1,
      size: 50,
      compt_record_no: currentComptRecordNo.value,
      bill_id: 0
    };

    console.log('[temp-storage] cancelPayment qryComptRecord params:', requestParams);

    const res = await proxy.$api.locker.qryComptRecord(requestParams, { showLoading: false });

    console.log('[temp-storage] cancelPayment qryComptRecord response:', res);
    
    const record = getTargetRecord(res);
    const payStatus = getRecordPayStatus(record);

    console.log('[temp-storage] cancelPayment matched record:', record);
    console.log('[temp-storage] cancelPayment pay status:', payStatus);
    
    uni.hideLoading();

    if (payStatus === '2') {
      // 如果实际上已经支付成功了，直接跳开柜，防止用户重复支付
      uni.showToast({ title: '您已支付成功', icon: 'success' });
      setTimeout(() => {
        uni.redirectTo({
          url: `/workbench_package/pages/locker/deposit-success?mode=deposit&compt_record_no=${encodeURIComponent(currentComptRecordNo.value)}`
        });
      }, 1000);
      return;
    }

    if (!currentPaymentInfo.value) {
      uni.showToast({ title: '缺少支付参数，请重新开始存货', icon: 'none' });
      return;
    }

    console.log('[temp-storage] retry requestPayment compt_record_no:', currentComptRecordNo.value);
    console.log('[temp-storage] retry requestPayment paymentInfo:', currentPaymentInfo.value);

    showPaymentConfirm.value = true;
    startPolling();

    try {
      await invokeTempDepositPayment(currentPaymentInfo.value);
    } catch (paymentErr) {
      console.log('[temp-storage] retry requestPayment callback fail:', paymentErr);
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
  // 注意如果是在模板中绑定的 @tap="checkPaymentStatus"，默认参数 event 是一个对象，会导致 showLoader 变为 true，这是符合预期的
  const isShowLoader = typeof showLoader === 'boolean' ? showLoader : true;
  
  if (!currentComptRecordNo.value) return;
  
  if (isShowLoader) {
    uni.showLoading({ title: '正在确认...' });
  }
  
  try {
    const requestParams = {
      page: 1,
      size: 50,
      compt_record_no: currentComptRecordNo.value,
      bill_id: 0
    };

    console.log('[temp-storage] checkPaymentStatus params:', requestParams);

    const res = await proxy.$api.locker.qryComptRecord(requestParams, { showLoading: false });

    console.log('[temp-storage] checkPaymentStatus response:', res);
    
    const record = getTargetRecord(res);
    const payStatus = getRecordPayStatus(record);

    console.log('[temp-storage] checkPaymentStatus matched record:', record);
    console.log('[temp-storage] checkPaymentStatus pay status:', payStatus);
    
    if (isShowLoader) {
      uni.hideLoading();
    }
    
    if (payStatus === '2') {
      stopPolling();
      showPaymentConfirm.value = false;
      if (isShowLoader) {
        uni.showToast({ title: '支付成功', icon: 'success' });
      }
      setTimeout(() => {
        uni.redirectTo({
          url: `/workbench_package/pages/locker/deposit-success?mode=deposit&compt_record_no=${encodeURIComponent(currentComptRecordNo.value)}`
        });
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
    console.log('[temp-storage] checkPaymentStatus error:', e);
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

.form-container {
  flex: 1;
  padding: 48rpx;
  overflow-y: auto;
}

.form-group {
  margin-bottom: 48rpx;
}

.form-label {
  font-size: 28rpx;
  margin-bottom: 16rpx;
  display: block;
}

.picker-wrapper, .input-wrapper {
  height: 96rpx;
  border-radius: 24rpx;
  display: flex;
  align-items: center;
  padding: 0 32rpx;
  border: 1px solid transparent; /* 为边框预留空间 */
  transition: all 0.3s ease;
}

.picker-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.picker-text {
  font-size: 30rpx;
}

.picker-icon {
  font-size: 32rpx;
}

.form-input {
  flex: 1;
  height: 100%;
  font-size: 30rpx;
}

.icon-wrapper {
  padding: 16rpx;
  margin-right: -16rpx;
}

.input-icon {
  font-size: 40rpx;
}

/* 规格选择列表 */
.spec-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.spec-row {
  display: flex;
  align-items: center;
  padding: 28rpx 32rpx;
  border-radius: 24rpx;
  border: 1.5px solid transparent;
  transition: all 0.2s ease;
  gap: 24rpx;
}

.spec-row:active {
  transform: scale(0.99);
}

.spec-row.disabled {
  pointer-events: none;
}

/* 单选圆点 */
.spec-radio {
  width: 40rpx;
  height: 40rpx;
  border-radius: 50%;
  border: 2px solid;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: border-color 0.2s ease;
}

.spec-radio-dot {
  width: 22rpx;
  height: 22rpx;
  border-radius: 50%;
  transition: all 0.2s ease;
}

/* 规格名 */
.spec-name {
  flex: 1;
  font-size: 30rpx;
  font-weight: 600;
  transition: color 0.2s ease;
}

/* 数量标签 */
.spec-badge {
  padding: 8rpx 20rpx;
  border-radius: 20rpx;
  flex-shrink: 0;
}

.spec-badge-text {
  font-size: 22rpx;
  font-weight: 600;
}

/* 底部按钮 */
.footer-section {
  padding: 32rpx 48rpx;
  padding-bottom: calc(32rpx + env(safe-area-inset-bottom));
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

/* 支付确认弹窗 */
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
  padding: 64rpx 48rpx;
  text-align: center;
}

.modal-desc {
  font-size: 30rpx;
  line-height: 1.6;
}

.modal-footer {
  display: flex;
  padding: 32rpx;
  gap: 24rpx;
}

.btn-cancel, .btn-confirm {
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

.btn-cancel::after, .btn-confirm::after {
  display: none;
}

.btn-cancel:active, .btn-confirm:active {
  opacity: 0.9;
  transform: scale(0.98);
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
</style>
