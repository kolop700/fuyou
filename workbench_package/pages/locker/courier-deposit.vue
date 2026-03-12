<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏 -->
    <custom-navbar title="快递员存件" :show-back="true" />

    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="form-container">
        <!-- 快递柜选择 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">快递柜</text>
          <view class="picker-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <picker @change="bindLockerChange" :value="lockerIndex" :range="lockerList">
              <view class="picker-text" :style="{ color: theme.textPrimary }">
                {{ lockerList[lockerIndex] }}
              </view>
            </picker>
            <text class="iconfont icon-arrow-right picker-icon" :style="{ color: theme.textTertiary }"></text>
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
                background: selectedSize === item.value ? theme.getBadgeBackground('info') : theme.bgCard,
                borderColor: selectedSize === item.value ? theme.colorInfo : theme.borderColor,
                color: selectedSize === item.value ? theme.colorInfo : theme.textPrimary
              }"
              @tap="selectSize(item.value)"
            >
              <text class="spec-text">{{ item.label }}</text>
            </view>
          </view>
        </view>

        <!-- 快递单号 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">快递单号</text>
          <view class="input-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <input 
              class="form-input" 
              type="text" 
              v-model="trackingNumber" 
              placeholder="输入或扫描单号" 
              :placeholder-style="'color: ' + theme.textTertiary"
              :style="{ color: theme.textPrimary }"
            />
            <view class="icon-wrapper" @tap="scanCode">
              <text class="iconfont icon-fa-barcode input-icon" :style="{ color: theme.textSecondary }"></text>
            </view>
          </view>
        </view>

        <!-- 客户手机 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">客户手机</text>
          <view class="input-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <input 
              class="form-input" 
              type="number" 
              v-model="phoneNumber" 
              placeholder="输入收件人手机号" 
              :placeholder-style="'color: ' + theme.textTertiary"
              :style="{ color: theme.textPrimary }"
              maxlength="11"
            />
          </view>
        </view>
      </view>

      <!-- 底部按钮 -->
      <view class="footer-section">
        <button 
          class="action-btn" 
          :style="{ background: theme.colorAccentGradient, boxShadow: theme.shadowButton }"
          @tap="submitDeposit"
        >
          开始存货
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
const trackingNumber = ref('');
const phoneNumber = ref('');

const sizeOptions = [
  { label: '小号', value: 's' },
  { label: '中号', value: 'm' },
  { label: '大号', value: 'l' },
  { label: '超大号', value: 'xl' },
  { label: '文件柜', value: 'doc' },
  { label: '生鲜柜', value: 'fresh' }
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
};

const scanCode = () => {
  uni.scanCode({
    success: (res) => {
      trackingNumber.value = res.result;
    }
  });
};

const submitDeposit = () => {
  if (!trackingNumber.value) {
    uni.showToast({ title: '请输入快递单号', icon: 'none' });
    return;
  }
  if (!phoneNumber.value || phoneNumber.value.length !== 11) {
    uni.showToast({ title: '请输入正确的手机号', icon: 'none' });
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

.picker-wrapper {
  justify-content: space-between;
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