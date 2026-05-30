<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="存取记录" :show-back="true" />

    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="search-section">
        <view class="search-type-group" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
          <view
            class="search-type"
            :style="getSearchTypeStyle('compt_record_no')"
            @tap="switchSearchType('compt_record_no')"
          >
            记录号
          </view>
          <view
            class="search-type"
            :style="getSearchTypeStyle('bill_id')"
            @tap="switchSearchType('bill_id')"
          >
            结算单
          </view>
        </view>

        <view class="search-box" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
          <input
            v-model="searchKeyword"
            class="search-input"
            :type="searchType === 'bill_id' ? 'number' : 'text'"
            :placeholder="searchType === 'bill_id' ? '输入结算单ID' : '输入存货记录编号'"
            :placeholder-style="'color: ' + theme.textTertiary"
            :style="{ color: theme.textPrimary }"
            confirm-type="search"
            @confirm="handleSearch"
          />
          <view v-if="searchKeyword" class="search-clear" @tap="clearSearch">
            <uni-icons type="clear" size="18" :color="theme.textTertiary"></uni-icons>
          </view>
          <button class="search-button" :style="{ background: theme.colorAccentGradient }" @tap="handleSearch">搜索</button>
        </view>
      </view>

      <view class="segmented-control-wrapper">
        <view class="segmented-control" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
          <view
            class="segment-item"
            :class="{ active: currentTab === 'courier' }"
            :style="getSegmentStyle('courier')"
            @tap="switchTab('courier')"
          >
            快递存货
          </view>
          <view
            class="segment-item"
            :class="{ active: currentTab === 'temp' }"
            :style="getSegmentStyle('temp')"
            @tap="switchTab('temp')"
          >
            临时存货
          </view>
        </view>
      </view>

      <scroll-view
        scroll-y
        class="records-list"
        :refresher-enabled="true"
        :refresher-triggered="refreshing"
        :refresher-background="theme.bgPrimary"
        @refresherrefresh="handleRefresh"
        @scrolltolower="loadMore"
      >
        <view v-if="currentList.length > 0" class="list-content">
          <view
            v-for="item in currentList"
            :key="item.id"
            class="record-card"
            :style="{ background: theme.bgCard, borderColor: theme.borderColor }"
          >
            <view class="record-header">
              <view class="record-title-wrap">
                <text class="record-title" :style="{ color: theme.textPrimary }">{{ getRecordTitle(item) }}</text>
                <text class="record-subtitle" :style="{ color: theme.textSecondary }">{{ item.locker_name || '-' }} · {{ item.compt_name || '-' }}</text>
              </view>
              <view class="status-tag" :style="getStoragePayStyle(item.storage_pay_sta)">
                {{ getStatusLabel(item.storage_pay_sta) }}
              </view>
            </view>

            <view class="record-body">
              <view v-if="isCourierRecord(item)" class="info-row">
                <text class="info-label" :style="{ color: theme.textSecondary }">快递单号</text>
                <text class="info-value" :style="{ color: theme.textPrimary }">{{ item.tracking_no || '-' }}</text>
              </view>
              <view v-if="isCourierRecord(item)" class="info-row">
                <text class="info-label" :style="{ color: theme.textSecondary }">客户手机</text>
                <text class="info-value" :style="{ color: theme.textPrimary }">{{ item.customer_phone || '-' }}</text>
              </view>
              <view class="info-row">
                <text class="info-label" :style="{ color: theme.textSecondary }">取件码</text>
                <text class="info-value code-value" :style="{ color: item.pickup_code ? theme.colorAccent : theme.textTertiary }">{{ item.pickup_code || '未生成' }}</text>
              </view>
              <view class="info-row">
                <text class="info-label" :style="{ color: theme.textSecondary }">存件时间</text>
                <text class="info-value" :style="{ color: theme.textPrimary }">{{ item.deposit_time || '-' }}</text>
              </view>
              <view class="info-row">
                <text class="info-label" :style="{ color: theme.textSecondary }">免费截止</text>
                <text class="info-value" :style="{ color: theme.textPrimary }">{{ item.free_deadline || '-' }}</text>
              </view>
            </view>

            <view class="record-footer" :style="{ borderTopColor: theme.borderColor }">
              <text class="footer-text" :style="{ color: theme.textSecondary }">存货费 ¥{{ formatAmount(item.storage_fee) }}</text>
              <text class="footer-text" :style="{ color: theme.textSecondary }">{{ item.settled ? '已结算' : '未结算' }}</text>
            </view>
          </view>

          <view class="load-more" :style="{ color: theme.textSecondary }">{{ loadMoreText }}</view>
        </view>

        <view v-else class="empty-state">
          <text class="iconfont icon-box-open empty-icon" :style="{ color: theme.textTertiary }"></text>
          <text class="empty-text" :style="{ color: theme.textSecondary }">{{ loading ? '加载中...' : '暂无记录' }}</text>
        </view>
      </scroll-view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const currentTab = ref('courier');
const records = ref([]);
const page = ref(1);
const size = ref(50);
const pages = ref(0);
const total = ref(0);
const loading = ref(false);
const loadingMore = ref(false);
const refreshing = ref(false);
const searchType = ref('compt_record_no');
const searchKeyword = ref('');

const normalizeValue = (value) => {
  if (value && typeof value === 'object') {
    return String(value.value ?? '').trim();
  }
  const matched = String(value ?? '').match(/[0-9]/);
  return matched ? matched[0] : String(value ?? '').trim();
};

const getStatusLabel = (status) => {
  if (status && typeof status === 'object' && status.label) {
    return status.label;
  }

  const value = normalizeValue(status);
  const labels = {
    0: '无费用',
    1: '待支付',
    2: '已支付',
    3: '已取消',
    4: '已退款'
  };
  return labels[value] || '未知状态';
};

const isCourierRecord = (item) => normalizeValue(item?.storage_type) === '0';
const isTempRecord = (item) => normalizeValue(item?.storage_type) === '1';

const currentList = computed(() => {
  return records.value.filter(item => currentTab.value === 'courier' ? isCourierRecord(item) : isTempRecord(item));
});

const currentStorageType = computed(() => currentTab.value === 'courier' ? 0 : 1);

const loadMoreText = computed(() => {
  if (loadingMore.value) return '加载中...';
  if (pages.value && page.value >= pages.value) return '没有更多了';
  return '上拉加载更多';
});

const getSegmentStyle = (tab) => {
  if (currentTab.value === tab) {
    return {
      background: theme.value.bgSecondary,
      color: theme.value.colorAccent,
      boxShadow: '0 2px 8px rgba(0,0,0,0.07)'
    };
  }

  return { color: theme.value.textSecondary };
};

const getSearchTypeStyle = (type) => {
  if (searchType.value === type) {
    return {
      background: theme.value.bgSecondary,
      color: theme.value.colorAccent
    };
  }

  return { color: theme.value.textSecondary };
};

const getStoragePayStyle = (status) => {
  const value = normalizeValue(status);
  const colorMap = {
    0: theme.value.colorInfo,
    1: theme.value.colorWarning,
    2: theme.value.colorSuccess,
    3: theme.value.colorError,
    4: theme.value.colorError
  };
  const color = colorMap[value] || theme.value.textSecondary;

  return {
    background: value === '2'
      ? theme.value.getBadgeBackground('success')
      : value === '1'
        ? theme.value.getBadgeBackground('warning')
        : theme.value.bgSecondary,
    color
  };
};

const getRecordTitle = (item) => {
  if (isCourierRecord(item)) {
    return item.tracking_no ? `快递 ${item.tracking_no}` : '快递存货';
  }

  return `临时存货 #${item.id}`;
};

const formatAmount = (amount) => {
  const number = Number(amount || 0);
  return number.toFixed(2);
};

const fetchRecords = async (reset = false) => {
  if (loading.value || loadingMore.value) return;

  if (reset) {
    page.value = 1;
    loading.value = true;
  } else {
    if (pages.value && page.value >= pages.value) return;
    page.value += 1;
    loadingMore.value = true;
  }

  const requestParams = {
    page: page.value,
    size: size.value,
    storage_type: currentStorageType.value
  };

  const keyword = String(searchKeyword.value || '').trim();
  if (keyword) {
    if (searchType.value === 'bill_id') {
      requestParams.bill_id = Number(keyword);
    } else {
      requestParams.compt_record_no = keyword;
    }
  }

  console.log('[storage-records] qryComptRecord params:', requestParams);

  try {
    const res = await proxy.$api.locker.qryComptRecord(requestParams, { showLoading: reset });
    console.log('[storage-records] qryComptRecord response:', res);

    const items = Array.isArray(res?.items) ? res.items : [];
    total.value = Number(res?.total || 0);
    pages.value = Number(res?.pages || 0);
    page.value = Number(res?.page || page.value);

    records.value = reset ? items : records.value.concat(items);
  } catch (error) {
    console.log('[storage-records] qryComptRecord error:', error);
    uni.showToast({ title: error?.msg || error?.detail || error?.message || '获取记录失败', icon: 'none' });
    if (!reset) {
      page.value = Math.max(1, page.value - 1);
    }
  } finally {
    loading.value = false;
    loadingMore.value = false;
    refreshing.value = false;
  }
};

const handleRefresh = () => {
  refreshing.value = true;
  fetchRecords(true);
};

const loadMore = () => {
  fetchRecords(false);
};

const switchTab = (tab) => {
  if (currentTab.value === tab) return;
  currentTab.value = tab;
  fetchRecords(true);
};

const switchSearchType = (type) => {
  if (searchType.value === type) return;
  searchType.value = type;
  searchKeyword.value = '';
  fetchRecords(true);
};

const handleSearch = () => {
  const keyword = String(searchKeyword.value || '').trim();
  if (searchType.value === 'bill_id' && keyword && !/^\d+$/.test(keyword)) {
    uni.showToast({ title: '请输入正确的结算单ID', icon: 'none' });
    return;
  }

  searchKeyword.value = keyword;
  fetchRecords(true);
};

const clearSearch = () => {
  if (!searchKeyword.value) return;
  searchKeyword.value = '';
  fetchRecords(true);
};

onLoad(() => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  fetchRecords(true);
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

.search-section {
  padding: 0 32rpx 24rpx;
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.search-type-group {
  display: flex;
  align-self: flex-start;
  border-radius: 18rpx;
  padding: 6rpx;
  border: 1px solid transparent;
}

.search-type {
  min-width: 112rpx;
  height: 56rpx;
  line-height: 56rpx;
  text-align: center;
  border-radius: 14rpx;
  font-size: 24rpx;
  font-weight: 700;
}

.search-box {
  min-height: 88rpx;
  border-radius: 24rpx;
  border: 1px solid transparent;
  display: flex;
  align-items: center;
  padding: 0 12rpx 0 28rpx;
  gap: 12rpx;
}

.search-input {
  flex: 1;
  min-width: 0;
  height: 88rpx;
  font-size: 28rpx;
}

.search-clear {
  width: 48rpx;
  height: 48rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.search-button {
  margin: 0;
  width: 128rpx;
  height: 64rpx;
  line-height: 64rpx;
  border-radius: 18rpx;
  color: #ffffff;
  font-size: 26rpx;
  font-weight: 700;
  border: none;
  flex-shrink: 0;
}

.search-button::after {
  display: none;
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

.records-list {
  flex: 1;
  overflow-y: auto;
}

.list-content {
  padding: 0 32rpx 48rpx;
  display: flex;
  flex-direction: column;
  gap: 24rpx;
}

.record-card {
  border-radius: 28rpx;
  padding: 28rpx;
  border: 1px solid transparent;
  box-shadow: 0 14rpx 40rpx rgba(15, 23, 42, 0.06);
}

.record-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20rpx;
}

.record-title-wrap {
  flex: 1;
  min-width: 0;
}

.record-title {
  display: block;
  font-size: 32rpx;
  font-weight: 700;
  line-height: 1.4;
}

.record-subtitle {
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

.record-body {
  margin-top: 24rpx;
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.info-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24rpx;
}

.info-label,
.info-value {
  font-size: 26rpx;
  line-height: 1.5;
}

.info-value {
  flex: 1;
  text-align: right;
  word-break: break-all;
}

.code-value {
  font-size: 30rpx;
  font-weight: 800;
  letter-spacing: 1rpx;
}

.record-footer {
  margin-top: 24rpx;
  padding-top: 20rpx;
  border-top: 1px solid transparent;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.footer-text {
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
</style>
