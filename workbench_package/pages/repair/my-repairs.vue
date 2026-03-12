<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="我的报修" :show-back="true" />
    
    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <!-- 过滤器 -->
      <scroll-view scroll-x class="filter-scroll" :show-scrollbar="false">
        <view class="filter-list">
          <view 
            v-for="(filter, index) in filters" 
            :key="index"
            class="filter-item"
            :class="{ active: currentFilter === filter.value }"
            :style="{ 
              background: currentFilter === filter.value ? theme.textPrimary : theme.bgCard,
              color: currentFilter === filter.value ? theme.bgCard : theme.textSecondary,
              borderColor: currentFilter === filter.value ? 'transparent' : theme.borderColor
            }"
            @tap="currentFilter = filter.value"
          >
            {{ filter.label }}
          </view>
        </view>
      </scroll-view>

      <!-- 报修列表 -->
      <scroll-view scroll-y class="list-container">
        <view class="list-content">
          <view 
            v-for="(item, index) in repairList" 
            :key="index"
            class="repair-card"
            :style="{ background: theme.bgCard, boxShadow: theme.shadowCard }"
          >
            <view class="card-header">
              <view 
                class="status-badge"
                :style="{ background: getStatusBg(item.status), color: getStatusColor(item.status) }"
              >
                {{ getStatusText(item.status) }}
              </view>
              <text class="time-text" :style="{ color: theme.textTertiary }">{{ item.time }}</text>
            </view>
            
            <text class="repair-title" :style="{ color: theme.textPrimary }">{{ item.title }}</text>
            <text class="repair-desc" :style="{ color: theme.textSecondary }">{{ item.desc }}</text>
            
            <view class="card-footer" :style="{ borderTopColor: theme.dividerColor }">
              <view class="location-info">
                <text class="iconfont icon-fa-home" :style="{ color: theme.textTertiary }"></text>
                <text class="location-text" :style="{ color: theme.textTertiary }">{{ item.location }}</text>
              </view>
              <text class="detail-link" :style="{ color: theme.colorAccent }">查看详情</text>
            </view>
          </view>
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
const currentFilter = ref('all');

const filters = [
  { label: '全部', value: 'all' },
  { label: '待处理', value: 'pending' },
  { label: '处理中', value: 'processing' },
  { label: '已完成', value: 'completed' }
];

const repairList = [
  {
    status: 'processing',
    time: '2023-10-24 14:30',
    title: '客厅灯具故障',
    desc: '客厅主灯打开后闪烁，有时候完全不亮，需要维修师傅上门查看。',
    location: '幸福里 A栋-101'
  },
  {
    status: 'pending',
    time: '2023-10-23 09:15',
    title: '厨房水管漏水',
    desc: '水槽下方管道接口处有渗水现象，地面有积水。',
    location: '幸福里 A栋-101'
  },
  {
    status: 'completed',
    time: '2023-10-15 10:00',
    title: '门禁卡失效',
    desc: '门禁卡无法刷开单元门，需要重新激活。',
    location: '幸福里 A栋-101'
  }
];

onLoad(() => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
});

const getStatusText = (status) => {
  const map = { pending: '待处理', processing: '处理中', completed: '已完成' };
  return map[status];
};

const getStatusBg = (status) => {
  if (themeStore.isDark()) {
    const map = { 
      pending: 'rgba(250, 204, 21, 0.2)', 
      processing: 'rgba(59, 130, 246, 0.2)', 
      completed: 'rgba(34, 197, 94, 0.2)' 
    };
    return map[status];
  } else {
    const map = { 
      pending: 'hsl(40, 90%, 95%)', 
      processing: 'hsl(210, 90%, 95%)', 
      completed: 'hsl(140, 60%, 95%)' 
    };
    return map[status];
  }
};

const getStatusColor = (status) => {
  if (themeStore.isDark()) {
    const map = { 
      pending: 'hsl(45, 90%, 60%)', 
      processing: 'hsl(210, 90%, 70%)', 
      completed: 'hsl(140, 60%, 60%)' 
    };
    return map[status];
  } else {
    const map = { 
      pending: 'hsl(40, 90%, 45%)', 
      processing: 'hsl(210, 90%, 45%)', 
      completed: 'hsl(140, 60%, 45%)' 
    };
    return map[status];
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

/* 过滤器 */
.filter-scroll {
  padding: 24rpx 32rpx;
  box-sizing: border-box;
  white-space: nowrap;
}

.filter-list {
  display: flex;
  gap: 16rpx;
}

.filter-item {
  padding: 12rpx 32rpx;
  border-radius: 32rpx;
  font-size: 26rpx;
  font-weight: 500;
  border: 1px solid;
  transition: all 0.2s ease;
}

/* 列表 */
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
  padding: 6rpx 16rpx;
  border-radius: 8rpx;
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
  margin-bottom: 24rpx;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 24rpx;
  border-top: 1px solid;
}

.location-info {
  display: flex;
  align-items: center;
  gap: 8rpx;
}

.location-info .iconfont {
  font-size: 24rpx;
}

.location-text {
  font-size: 22rpx;
}

.detail-link {
  font-size: 24rpx;
  font-weight: 600;
}
</style>