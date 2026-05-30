<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="我的报修" :show-back="true" />

    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="filter-panel" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
        <view class="filter-list">
          <view
            v-for="filter in filters"
            :key="filter.value"
            class="filter-item"
            :class="{ active: currentFilter === filter.value }"
            :style="{
              background: currentFilter === filter.value ? theme.textPrimary : theme.bgPrimary,
              color: currentFilter === filter.value ? theme.bgCard : theme.textSecondary,
              borderColor: currentFilter === filter.value ? 'transparent' : theme.borderColor
            }"
            @tap="changeFilter(filter.value)"
          >
            {{ filter.label }}
          </view>
        </view>
      </view>

      <scroll-view
        scroll-y
        class="list-container"
        refresher-enabled
        :refresher-triggered="refreshing"
        :refresher-background="themeStore.isDark() ? '#0d1520' : '#f1f5f9'"
        :refresher-default-style="themeStore.isDark() ? 'white' : 'black'"
        @refresherrefresh="handleRefresh"
        @scrolltolower="loadMore"
        :lower-threshold="80"
      >
        <view class="list-content">
          <view
            v-for="item in repairList"
            :key="item.id"
            class="repair-card"
            :style="{ background: theme.bgCard, boxShadow: theme.shadowCard, borderColor: theme.dividerColor }"
            @tap="openDetail(item)"
          >
            <view class="card-header">
              <view
                class="status-badge"
                :style="{ background: getStatusBg(item.status), color: getStatusColor(item.status) }"
              >
                {{ getStatusText(item.status) }}
              </view>
              <text class="time-text" :style="{ color: theme.textTertiary }">{{ formatTime(item.created_at) }}</text>
            </view>

            <text class="repair-title" :style="{ color: theme.textPrimary }">{{ item.title || '未命名报修' }}</text>
            <text class="repair-desc" :style="{ color: theme.textSecondary }">{{ item.description || '暂无描述' }}</text>

            <view v-if="item.remark" class="remark-box" :style="{ background: theme.bgSecondary, color: theme.textSecondary, borderColor: theme.dividerColor }">
              备注：{{ item.remark }}
            </view>

            <view class="card-footer" :style="{ borderTopColor: theme.dividerColor }">
              <view class="location-info">
                <text class="iconfont icon-fa-home" :style="{ color: theme.textTertiary }"></text>
                <text class="location-text" :style="{ color: theme.textTertiary }">{{ item.comm_name || '未分配小区' }}</text>
              </view>
              <text class="detail-link" :style="{ color: theme.colorAccent }">查看详情</text>
            </view>
          </view>

          <view v-if="!repairList.length && !loading" class="empty-state" :style="{ color: theme.textTertiary }">
            暂无报修记录
          </view>

          <view v-if="repairList.length" class="load-more" :style="{ color: theme.textTertiary }">
            {{ loadMoreText }}
          </view>
        </view>
      </scroll-view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue';
import { onLoad, onShow } from '@dcloudio/uni-app';
import { useThemeStore } from '@/store/modules/theme';
import { useThemeVars } from '@/utils/themeConfig';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const userStore = proxy.$store.user.useUserStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const currentFilter = ref('all');
const repairList = ref([]);
const loading = ref(false);
const loadingMore = ref(false);
const refreshing = ref(false);
const currentCommunityId = ref(0);
const page = ref(1);
const size = ref(10);
const total = ref(0);
const pages = ref(0);

const filters = [
  { label: '全部', value: 'all' },
  { label: '待处理', value: '0' },
  { label: '已处理', value: '1' },
  { label: '已拒绝', value: '2' }
];

onLoad(async () => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  await initPage();
});

onShow(async () => {
  if (currentCommunityId.value) {
    await fetchRepairList(true);
  }
});

const initPage = async () => {
  await fetchCurrentCommunityId();
  await fetchRepairList(true);
};

const fetchCurrentCommunityId = async () => {
  try {
    const userId = userStore.userInfo?.user_id;

    if (!userId) {
      currentCommunityId.value = 0;
      return;
    }

    const res = await proxy.$api.device.getUserCommunityList(userId, { showLoading: false });
    const list = Array.isArray(res?.data) ? res.data : Array.isArray(res) ? res : [];
    currentCommunityId.value = Number(list[0]?.comm_id || 0);
  } catch (error) {
    currentCommunityId.value = 0;
  }
};

const loadMoreText = computed(() => {
  if (loadingMore.value) return '加载中...';
  if (pages.value > 0 && page.value >= pages.value) return '没有更多了';
  return '上拉加载更多';
});

const fetchRepairList = async (reset = false) => {
  if (!currentCommunityId.value) {
    repairList.value = [];
    return;
  }

  if (reset) {
    page.value = 1;
    total.value = 0;
    pages.value = 0;
    loading.value = true;
  } else {
    if (loadingMore.value) return;
    if (pages.value > 0 && page.value >= pages.value) return;
    loadingMore.value = true;
  }

  try {
    const params = {
      comm_id: currentCommunityId.value,
      page: reset ? 1 : page.value + 1,
      size: size.value
    };

    if (currentFilter.value !== 'all') {
      params.status = currentFilter.value;
    }

    const res = await proxy.$api.repair.qry(params, { showLoading: false });
    const list = Array.isArray(res?.items) ? res.items : [];

    total.value = Number(res?.total || 0);
    page.value = Number(res?.page || params.page);
    size.value = Number(res?.size || size.value);
    pages.value = Number(res?.pages || 0);

    repairList.value = reset ? list : [...repairList.value, ...list];
  } catch (e) {
    if (reset) {
      repairList.value = [];
    }
    uni.showToast({ title: e?.msg || e?.detail || e?.message || '获取报修记录失败', icon: 'none' });
  } finally {
    loading.value = false;
    loadingMore.value = false;
  }
};

const handleRefresh = async () => {
  refreshing.value = true;
  await fetchRepairList(true);
  refreshing.value = false;
};

const changeFilter = async (value) => {
  currentFilter.value = value;
  await fetchRepairList(true);
};

const loadMore = async () => {
  await fetchRepairList(false);
};

const openDetail = (item) => {
  uni.setStorageSync('repair_detail_item', item);
  uni.navigateTo({
    url: `/workbench_package/pages/repair/detail?id=${encodeURIComponent(item.id || '')}`
  });
};

const normalizeStatus = (status) => {
  if (status && typeof status === 'object') {
    const objectValue = status.value;
    if (objectValue !== undefined && objectValue !== null && objectValue !== '') {
      return String(objectValue).trim();
    }
  }

  const value = String(status ?? '').trim();
  if (!value) return '';

  const lowerValue = value.toLowerCase();

  if (lowerValue.includes('拒绝')) return '2';
  if (lowerValue.includes('处理') && (lowerValue.includes('已') || lowerValue.includes('完成'))) return '1';
  if (lowerValue.includes('待')) return '0';
  if (lowerValue === 'pending') return '0';
  if (lowerValue === 'processed' || lowerValue === 'done' || lowerValue === 'completed') return '1';
  if (lowerValue === 'rejected' || lowerValue === 'refused') return '2';

  const directMap = {
    '0': '0',
    '1': '1',
    '2': '2'
  };

  if (directMap[value] !== undefined) {
    return directMap[value];
  }

  const match = value.match(/[0-2]/);
  return match ? match[0] : '';
};

const getStatusText = (status) => {
  if (status && typeof status === 'object' && status.label) {
    return status.label;
  }

  const statusKey = normalizeStatus(status);
  const map = {
    '0': '待处理',
    '1': '已处理',
    '2': '已拒绝'
  };

  return map[statusKey] || '待处理';
};

const getStatusBg = (status) => {
  const statusKey = normalizeStatus(status);
  const map = {
    '0': theme.value.getBadgeBackground('warning'),
    '1': theme.value.getBadgeBackground('success'),
    '2': theme.value.getBadgeBackground('error')
  };

  return map[statusKey] || theme.value.getBadgeBackground('warning');
};

const getStatusColor = (status) => {
  const statusKey = normalizeStatus(status);
  const map = {
    '0': theme.value.colorWarning,
    '1': theme.value.colorSuccess,
    '2': theme.value.colorError
  };

  return map[statusKey] || theme.value.colorWarning;
};

const formatTime = (value) => {
  return value || '--';
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
  padding-bottom: 24rpx;
}

.filter-panel {
  margin: 24rpx 32rpx;
  padding: 24rpx;
  border-radius: 28rpx;
  border: 1px solid transparent;
}

.filter-list {
  display: flex;
  gap: 16rpx;
  flex-wrap: wrap;
}

.filter-item {
  padding: 12rpx 28rpx;
  border-radius: 32rpx;
  font-size: 26rpx;
  font-weight: 500;
  border: 1px solid;
  transition: all 0.2s ease;
}

.list-container {
  flex: 1;
  overflow-y: auto;
}

.list-content {
  padding: 0 32rpx 48rpx;
  display: flex;
  flex-direction: column;
  gap: 24rpx;
}

.repair-card {
  border-radius: 24rpx;
  padding: 32rpx;
  transition: transform 0.2s ease;
  border: 1px solid transparent;
}

.repair-card:active {
  transform: scale(0.99);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16rpx;
}

.status-badge {
  padding: 8rpx 18rpx;
  border-radius: 999rpx;
  font-size: 22rpx;
  font-weight: 600;
}

.time-text {
  font-size: 22rpx;
}

.repair-title {
  font-size: 30rpx;
  font-weight: 700;
  margin-bottom: 8rpx;
  display: block;
}

.repair-desc {
  font-size: 26rpx;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  overflow: hidden;
  margin-bottom: 20rpx;
}

.remark-box {
  font-size: 24rpx;
  line-height: 1.5;
  border-radius: 16rpx;
  padding: 18rpx 20rpx;
  margin-bottom: 24rpx;
  border: 1px solid transparent;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16rpx;
  padding-top: 24rpx;
  border-top: 1px solid;
}

.location-info {
  display: flex;
  align-items: center;
  gap: 8rpx;
  min-width: 0;
  flex: 1;
}

.location-info .iconfont {
  font-size: 24rpx;
}

.location-text {
  font-size: 22rpx;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.detail-link {
  font-size: 24rpx;
  font-weight: 600;
  flex-shrink: 0;
}

.empty-state {
  padding: 120rpx 0;
  text-align: center;
  font-size: 28rpx;
}

.load-more {
  padding: 8rpx 0 24rpx;
  text-align: center;
  font-size: 24rpx;
}
</style>
