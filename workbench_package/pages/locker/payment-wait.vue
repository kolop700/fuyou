<template>
  <view class="page-container" :style="{ background: theme.bgSecondary }">
    <view class="ambient-bg"></view>

    <view class="page-content">
      <view class="icon-section">
        <view class="icon-circle" :style="{ background: theme.bgCard, boxShadow: theme.shadowLogo }">
          <text class="iconfont icon-fa-clock-o animated-icon" :style="{ color: theme.colorInfo }"></text>
        </view>
      </view>

      <view class="text-section">
        <text class="title" :style="{ color: theme.textPrimary }">支付结果确认中</text>
        <text class="subtitle" :style="{ color: theme.textSecondary }">支付成功后，系统会自动确认存货状态，请稍候</text>
      </view>

      <view class="status-card" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
        <view class="status-row">
          <text class="status-label" :style="{ color: theme.textSecondary }">存货单号</text>
          <text class="status-value" :style="{ color: theme.textPrimary }">{{ comptRecordNo }}</text>
        </view>
        <view class="status-row">
          <text class="status-label" :style="{ color: theme.textSecondary }">支付状态</text>
          <text class="status-value" :style="{ color: paymentStatusColor }">{{ paymentStatusText }}</text>
        </view>
        <view class="status-row">
          <text class="status-label" :style="{ color: theme.textSecondary }">剩余等待</text>
          <text class="status-value" :style="{ color: theme.colorWarning }">{{ remainSeconds }}s</text>
        </view>
      </view>

      <view class="hint-text" :style="{ color: theme.textSecondary }">系统每 2 秒自动查询一次，确认成功后会自动进入存货确认界面</view>
    </view>
  </view>
</template>

<script setup>
import { computed, getCurrentInstance, onMounted, onUnmounted, ref } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const comptRecordNo = ref('');
const remainSeconds = ref(20);
const currentStatus = ref('1');
const polling = ref(false);

let pollTimer = null;
let countdownTimer = null;

const normalizeStatusValue = (status) => {
  if (status && typeof status === 'object') {
    if (status.value !== undefined && status.value !== null) {
      return String(status.value).trim();
    }
    if (status.label) {
      const match = String(status.label).match(/[0-4]/);
      if (match) return match[0];
    }
  }

  const text = String(status ?? '').trim();
  const matched = text.match(/[0-4]/);
  return matched ? matched[0] : text;
};

const paymentStatusText = computed(() => {
  switch (normalizeStatusValue(currentStatus.value)) {
    case '0':
      return '无费用';
    case '1':
      return '待支付';
    case '2':
      return '已支付';
    case '3':
      return '已取消';
    case '4':
      return '已退款';
    default:
      return '确认中';
  }
});

const paymentStatusColor = computed(() => {
  switch (normalizeStatusValue(currentStatus.value)) {
    case '2':
      return theme.value.colorSuccess;
    case '3':
    case '4':
      return theme.value.colorError;
    case '1':
      return theme.value.colorWarning;
    default:
      return theme.value.colorInfo;
  }
});

const stopTimers = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
  if (countdownTimer) {
    clearInterval(countdownTimer);
    countdownTimer = null;
  }
};

const getTargetRecord = (res) => {
  const items = Array.isArray(res?.items) ? res.items : [];
  return items.find(item => item?.compt_record_no === comptRecordNo.value) || items[0] || null;
};

const goToDepositConfirm = () => {
  stopTimers();
  uni.redirectTo({
    url: `/workbench_package/pages/locker/deposit-success?mode=deposit&compt_record_no=${encodeURIComponent(comptRecordNo.value)}`
  });
};

const fetchPaymentStatus = async () => {
  if (polling.value || !comptRecordNo.value) return;

  polling.value = true;
  try {
    const requestParams = {
      page: 1,
      size: 50,
      compt_record_no: comptRecordNo.value,
      bill_id: 0
    };

    console.log('[payment-wait] qryComptRecord params:', requestParams);

    const res = await proxy.$api.locker.qryComptRecord(requestParams, { showLoading: false });

    const record = getTargetRecord(res);
    const payStatus = normalizeStatusValue(record?.storage_pay_sta);

    if (payStatus) {
      currentStatus.value = payStatus;
    }

    console.log('[payment-wait] qryComptRecord matched record:', record);
    console.log('[payment-wait] qryComptRecord pay status:', payStatus);

    if (payStatus === '2') {
      goToDepositConfirm();
    }
  } catch (error) {
    console.error('查询存货支付状态失败:', error);
  } finally {
    polling.value = false;
  }
};

const startPolling = async () => {
  await fetchPaymentStatus();

  pollTimer = setInterval(() => {
    fetchPaymentStatus();
  }, 2000);

  countdownTimer = setInterval(() => {
    if (remainSeconds.value > 0) {
      remainSeconds.value -= 1;
      return;
    }

    stopTimers();
    uni.showToast({
      title: '支付结果确认超时，请稍后在记录中查看',
      icon: 'none'
    });
    setTimeout(() => {
      uni.navigateBack();
    }, 1600);
  }, 1000);
};

onLoad((options) => {
  comptRecordNo.value = options?.compt_record_no ? decodeURIComponent(options.compt_record_no) : '';
});

onMounted(() => {
  themeStore.loadTheme();

  if (!comptRecordNo.value) {
    uni.showToast({ title: '缺少存货记录号', icon: 'none' });
    setTimeout(() => {
      uni.navigateBack();
    }, 1200);
    return;
  }

  startPolling();
});

onUnmounted(() => {
  stopTimers();
});
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

.ambient-bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    radial-gradient(circle at 50% 25%, hsla(204, 90%, 60%, 0.12), transparent 48%);
}

.page-content {
  width: 100%;
  padding: 64rpx 48rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  z-index: 2;
}

.icon-section {
  margin-bottom: 44rpx;
}

.icon-circle {
  width: 200rpx;
  height: 200rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  animation: pulse 1.8s infinite ease-in-out;
}

.animated-icon {
  font-size: 96rpx;
}

.text-section {
  text-align: center;
  margin-bottom: 48rpx;
}

.title {
  display: block;
  font-size: 46rpx;
  font-weight: 700;
  margin-bottom: 14rpx;
}

.subtitle {
  display: block;
  font-size: 28rpx;
  line-height: 1.7;
}

.status-card {
  width: 100%;
  border-radius: 32rpx;
  border: 1px solid transparent;
  padding: 18rpx 28rpx;
  box-sizing: border-box;
  margin-bottom: 32rpx;
}

.status-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22rpx 0;
}

.status-row:not(:last-child) {
  border-bottom: 1px solid rgba(148, 163, 184, 0.18);
}

.status-label,
.status-value {
  font-size: 28rpx;
}

.status-value {
  max-width: 60%;
  text-align: right;
  word-break: break-all;
}

.hint-text {
  font-size: 24rpx;
  line-height: 1.7;
  text-align: center;
}

@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.04); }
  100% { transform: scale(1); }
}
</style>
