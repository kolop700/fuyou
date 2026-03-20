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
const userStore = proxy.$store.user.useUserStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const lockerId = ref(1); // 快递柜 ID，目前写死为 1
const lockerName = ref('');

// 表单数据
const selectedSpecId = ref(null);
const duration = ref(1);
const sizeOptions = ref([]); // 从接口获取

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

const calculateCost = () => {}; // 保留占位，费用由后端定价

const getOpenId = () => {
  const userInfo = userStore.userInfo || {};

  return userInfo.openid || userInfo.wx_openid || userInfo.open_id || uni.getStorageSync('openid') || '0';
};

const getComptRecordNo = (res) => {
  return res?.compt_record_no || res?.data?.compt_record_no || res?.record?.compt_record_no || '';
};

const submitStorage = async () => {
  if (!selectedSpecId.value) {
    uni.showToast({ title: '请选择柜格型号', icon: 'none' });
    return;
  }
  if (!duration.value || duration.value <= 0) {
    uni.showToast({ title: '请输入有效的存货时长', icon: 'none' });
    return;
  }

  uni.showLoading({ title: '处理中...' });
  try {
    const res = await proxy.$api.locker.tempStorage({
      openid: getOpenId(),
      locker_id: lockerId.value,
      spec_id: selectedSpecId.value,
      hours: parseInt(duration.value, 10)
    });
    const comptRecordNo = getComptRecordNo(res);
    uni.hideLoading();
    uni.navigateTo({
      url: `/workbench_package/pages/locker/deposit-success?locker_id=${lockerId.value}&compt_record_no=${encodeURIComponent(comptRecordNo)}`
    });
  } catch (e) {
    uni.hideLoading();
    uni.showToast({ title: e?.msg || '操作失败，请重试', icon: 'none' });
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
