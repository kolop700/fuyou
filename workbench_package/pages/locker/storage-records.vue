<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏 -->
    <custom-navbar title="存取记录" :show-back="true" />

    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <!-- 顶部切换栏 -->
      <view class="segmented-control-wrapper">
        <view class="segmented-control" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
          <view 
            class="segment-item" 
            :class="{ active: currentTab === 'courier' }"
            @tap="switchTab('courier')"
            :style="currentTab === 'courier' ? { background: theme.bgSecondary, color: theme.colorAccent, boxShadow: '0 2px 8px rgba(0,0,0,0.07)' } : { color: theme.textSecondary }"
          >
            快递存货
          </view>
          <view 
            class="segment-item" 
            :class="{ active: currentTab === 'temp' }"
            @tap="switchTab('temp')"
            :style="currentTab === 'temp' ? { background: theme.bgSecondary, color: theme.colorAccent, boxShadow: '0 2px 8px rgba(0,0,0,0.07)' } : { color: theme.textSecondary }"
          >
            临时存货
          </view>
        </view>
      </view>

      <!-- 记录列表 -->
      <scroll-view scroll-y class="records-list">
        <view v-if="currentList.length > 0" class="list-content">
          <view 
            v-for="(item, index) in currentList" 
            :key="index"
            class="record-card"
            :style="{ background: theme.bgCard }"
          >
            <!-- 图标 -->
            <view 
              class="icon-wrapper" 
              :style="{ background: theme.getBadgeBackground('info'), color: theme.colorAccent }"
            >
              <text class="iconfont" :class="currentTab === 'courier' ? 'icon-shipping-fast' : 'icon-boxes-packing'"></text>
            </view>

            <!-- 信息 -->
            <view class="info-content">
              <text class="record-title" :style="{ color: theme.textPrimary }">
                {{ currentTab === 'courier' ? '快递单号: ' + item.trackingNumber : '临时寄存' }}
              </text>
              <text class="record-time" :style="{ color: theme.textSecondary }">{{ item.time }}</text>
            </view>

            <!-- 状态标签 -->
            <view 
              class="status-tag" 
              :style="{ 
                background: item.status === 'stored' ? theme.getBadgeBackground('success') : theme.bgSecondary,
                color: item.status === 'stored' ? theme.colorSuccess : theme.textSecondary
              }"
            >
              {{ item.status === 'stored' ? '已存入' : '已取出' }}
            </view>
          </view>
        </view>

        <!-- 空状态 -->
        <view v-else class="empty-state">
          <text class="iconfont icon-box-open empty-icon" :style="{ color: theme.textTertiary }"></text>
          <text class="empty-text" :style="{ color: theme.textSecondary }">暂无记录</text>
        </view>
      </scroll-view>
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
const lockerId = ref(1); // 快递柜 ID，目前写死为 1
const currentTab = ref('courier');
const courierRecords = ref([]);
const tempRecords = ref([]);
const loading = ref(false);

const currentList = computed(() => {
  return currentTab.value === 'courier' ? courierRecords.value : tempRecords.value;
});

const fetchRecords = async () => {
  loading.value = true;
  try {
    const res = await proxy.$api.locker.getRecords({ type: currentTab.value }, { showLoading: false });
    const list = res?.list || res?.data || [];
    if (currentTab.value === 'courier') {
      courierRecords.value = list;
    } else {
      tempRecords.value = list;
    }
  } catch (e) {
    // 接口异常时保持空列表
  } finally {
    loading.value = false;
  }
};

onLoad((options) => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  if (options && options.locker_id) {
    lockerId.value = Number(options.locker_id);
  }
  fetchRecords();
});

const switchTab = (tab) => {
  currentTab.value = tab;
  fetchRecords();
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

/* 顶部切换栏 */
.segmented-control-wrapper {
  padding: 0 48rpx 32rpx;
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

/* 记录列表 */
.records-list {
  flex: 1;
  overflow-y: auto;
}

.list-content {
  padding: 0 48rpx 48rpx;
  display: flex;
  flex-direction: column;
  gap: 24rpx;
}

.record-card {
  border-radius: 24rpx;
  padding: 32rpx;
  display: flex;
  align-items: center;
  transition: all 0.2s ease;
}

.icon-wrapper {
  width: 96rpx;
  height: 96rpx;
  border-radius: 20rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 24rpx;
}

.icon-wrapper .iconfont {
  font-size: 48rpx;
}

.info-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.record-title {
  font-size: 30rpx;
  font-weight: 700;
  margin-bottom: 8rpx;
}

.record-time {
  font-size: 24rpx;
}

.status-tag {
  padding: 8rpx 16rpx;
  border-radius: 12rpx;
  font-size: 22rpx;
  font-weight: 700;
}

/* 空状态 */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding-top: 120rpx;
}

.empty-icon {
  font-size: 96rpx;
  margin-bottom: 24rpx;
  opacity: 0.5;
}

.empty-text {
  font-size: 28rpx;
}
</style>