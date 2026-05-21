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
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue';
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
      uni.showModal({
        title: '支付超时费用',
        content: '您的包裹已产生超时费用，需支付后方可开柜',
        confirmText: '去支付',
        success: (modalRes) => {
          if (modalRes.confirm) {
            // 模拟获取金额，实际可根据后端返回字段(如 res.amount)调整
            const amount = res.fee_amount || '2.00'; 
            uni.navigateTo({
              url: `/workbench_package/pages/payment/cashier?amount=${amount}&compt_record_no=${res.compt_record_no || ''}`
            });
          }
        }
      });
    } else {
      // 无需支付，直接开柜
      uni.navigateTo({
        url: `/workbench_package/pages/locker/deposit-success?locker_id=${lockerId.value}&mode=pickup`
      });
    }
  } catch (e) {
    uni.hideLoading();
    uni.showToast({ title: e?.msg || '取件码错误，请重试', icon: 'none' });
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
</style>
