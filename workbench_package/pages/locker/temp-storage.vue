<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏 -->
    <custom-navbar title="临时存货" :show-back="true" />

    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="form-container">
        <!-- 快递柜选择 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">快递柜</text>
          <view class="picker-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <picker @change="bindLockerChange" :value="lockerIndex" :range="lockerList" style="width: 100%;">
              <view class="picker-content">
                <text class="picker-text" :style="{ color: theme.textPrimary }">
                  {{ lockerList[lockerIndex] }}
                </text>
                <text class="iconfont icon-arrow-right picker-icon" :style="{ color: theme.textTertiary }"></text>
              </view>
            </picker>
          </view>
        </view>

        <!-- 柜格型号 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">柜格型号</text>
          <view class="spec-grid">
            <view 
              v-for="(item, index) in sizeOptions" 
              :key="index"
              class="spec-item"
              :class="{ active: selectedSize === item.value }"
              :style="{ 
                background: selectedSize === item.value ? theme.getBadgeBackground('warning') : theme.bgCard,
                borderColor: selectedSize === item.value ? theme.colorWarning : theme.borderColor,
                color: selectedSize === item.value ? theme.colorWarning : theme.textPrimary
              }"
              @tap="selectSize(item.value)"
            >
              <text class="spec-text">{{ item.label }}</text>
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
              placeholder="输入整数小时" 
              :placeholder-style="'color: ' + theme.textTertiary"
              :style="{ color: theme.textPrimary }"
              @input="calculateCost"
            />
            <view class="icon-wrapper">
              <text class="iconfont icon-fa-clock input-icon" :style="{ color: theme.textSecondary }"></text>
            </view>
          </view>
        </view>

        <!-- 费用提示 -->
        <view class="cost-card" :style="{ background: theme.getBadgeBackground('info'), color: theme.colorInfo }">
          <text class="cost-amount">费用: ¥{{ totalCost.toFixed(2) }}</text>
          <text class="cost-desc">小号柜 2元/小时</text>
        </view>
      </view>

      <!-- 底部按钮 -->
      <view class="footer-section">
        <button 
          class="action-btn" 
          :style="{ background: theme.colorAccentGradient, boxShadow: theme.shadowButton }"
          @tap="submitStorage"
        >
          开始存货并支付
        </button>
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

// 表单数据
const lockerIndex = ref(0);
const lockerList = ['幸福里小区 A栋-01号柜', '幸福里小区 B栋-02号柜'];
const selectedSize = ref('s');
const duration = ref(1);
const totalCost = ref(2.00);

const sizeOptions = [
  { label: '小号', value: 's', price: 2 },
  { label: '中号', value: 'm', price: 3 },
  { label: '大号', value: 'l', price: 4 },
  { label: '超大号', value: 'xl', price: 6 },
  { label: '文件柜', value: 'doc', price: 1 },
  { label: '生鲜柜', value: 'fresh', price: 5 }
];

onLoad(() => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
});

const bindLockerChange = (e) => {
  lockerIndex.value = e.detail.value;
};

const selectSize = (value) => {
  selectedSize.value = value;
  calculateCost();
};

const calculateCost = () => {
  const selectedOption = sizeOptions.find(opt => opt.value === selectedSize.value);
  const pricePerHour = selectedOption ? selectedOption.price : 2;
  const hours = parseInt(duration.value) || 0;
  totalCost.value = pricePerHour * hours;
};

const submitStorage = () => {
  if (!duration.value || duration.value <= 0) {
    uni.showToast({ title: '请输入有效的存货时长', icon: 'none' });
    return;
  }
  
  uni.showLoading({ title: '处理中...' });
  setTimeout(() => {
    uni.hideLoading();
    // 跳转到成功/倒计时页面
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

/* 规格选择网格 */
.spec-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24rpx;
}

.spec-item {
  height: 88rpx;
  border-radius: 20rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
  transition: all 0.2s ease;
}

.spec-text {
  font-size: 28rpx;
  font-weight: 600;
}

/* 费用卡片 */
.cost-card {
  padding: 32rpx;
  border-radius: 24rpx;
  text-align: center;
  margin-top: 48rpx;
}

.cost-amount {
  font-size: 36rpx;
  font-weight: 700;
  display: block;
  margin-bottom: 8rpx;
}

.cost-desc {
  font-size: 24rpx;
  opacity: 0.8;
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
</style>