<template>
  <view class="history-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏 -->
    <custom-navbar title="快递员申请记录" :show-back="true" />
    
    <scroll-view 
      class="content-scroll" 
      scroll-y
      :style="{ paddingTop: navbarHeight + 'px' }"
      @refresherrefresh="onRefresh"
      :refresher-enabled="true"
      :refresher-triggered="isRefreshing"
    >
      <view v-if="!isLoading && historyList.length > 0" class="list-container">
        <view 
          v-for="item in historyList" 
          :key="item.courier_id"
          class="history-card" 
          :style="{ background: theme.bgCard, borderColor: theme.dividerColor, boxShadow: theme.shadowCard }"
        >
          <view class="card-header">
            <view class="record-info">
                <text class="record-name" :style="{ color: theme.textPrimary }">{{ item.name }}</text>
            </view>
            <view class="record-status" :style="getStatusStyle(item.status)">
                <text>{{ formatStatus(item.status) }}</text>
            </view>
          </view>
          <view class="card-body">
            <view class="record-item">
                <text class="iconfont icon-fa-building" :style="{ color: theme.textSecondary }"></text>
                <text :style="{ color: theme.textSecondary }">{{ item.comm_name }}</text>
            </view>
            <view class="record-item">
                <text class="iconfont icon-phone" :style="{ color: theme.textSecondary }"></text>
                <text :style="{ color: theme.textSecondary }">{{ item.mobile }}</text>
            </view>
            <view class="record-item" v-if="item.remark">
                <text class="iconfont icon-fa-comments" :style="{ color: theme.textSecondary }"></text>
                <text :style="{ color: theme.textSecondary }">{{ item.remark }}</text>
            </view>
          </view>
          <view class="card-footer" :style="{ borderTopColor: theme.dividerColor }">
            <text :style="{ color: theme.textTertiary }">申请于 {{ formatDate(item.create_time) }}</text>
          </view>
        </view>
      </view>

      <!-- 空状态 -->
      <view v-if="!isLoading && historyList.length === 0" class="empty-state">
        <u-empty
          mode="history"
          text="暂无申请记录"
          :icon-color="theme.textTertiary"
          :text-color="theme.textSecondary"
        ></u-empty>
      </view>

    </scroll-view>
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
const historyList = ref([]);
const isLoading = ref(true);

// Mock Data
const mockData = [
  {
    courier_id: 1,
    name: '张三',
    comm_name: '幸福花园小区',
    mobile: '188****8888',
    remark: '顺丰速运 - 负责A区',
    status: 1, // 已通过
    create_time: '2023-04-10T14:30:00Z'
  },
  {
    courier_id: 2,
    name: '李四',
    comm_name: '未来城',
    mobile: '139****1234',
    remark: '',
    status: 0, // 审核中
    create_time: '2023-04-12T09:15:00Z'
  },
  {
    courier_id: 3,
    name: '王五',
    comm_name: '阳光海岸',
    mobile: '150****5678',
    remark: '中通快递',
    status: 2, // 已驳回
    create_time: '2023-04-08T18:00:00Z'
  }
];

const formatStatus = (status) => {
  const statusMap = {
    0: '审核中',
    1: '已通过',
    2: '已驳回'
  };
  return statusMap[status] || '未知';
};

const getStatusStyle = (status) => {
  const styleMap = {
    0: { background: theme.value.getBadgeBackground('warning'), color: theme.value.colorWarning }, // 审核中
    1: { background: theme.value.getBadgeBackground('success'), color: theme.value.colorSuccess }, // 已通过
    2: { background: theme.value.getBadgeBackground('error'), color: theme.value.colorError }    // 已驳回
  };
  return styleMap[status] || { background: theme.value.getBadgeBackground('info'), color: theme.value.colorInfo };
};

const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleString('zh-CN', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
};

onLoad(() => {
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  historyList.value = mockData;
  isLoading.value = false;
});
</script>

<style scoped>
.history-container {
  min-height: 100vh;
}
.content-scroll {
  height: 100vh;
  box-sizing: border-box;
}
.list-container {
  padding: 32rpx;
  display: flex;
  flex-direction: column;
  gap: 32rpx;
}
.history-card {
  border-radius: 32rpx;
  padding: 40rpx;
  border: 1px solid; /* Bound to theme.dividerColor */
  transition: all 0.3s ease;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32rpx;
}
.record-info {
  display: flex;
  align-items: center;
  gap: 24rpx;
}
.record-name {
  font-size: 32rpx;
  font-weight: 600;
}
.record-status {
  font-size: 24rpx;
  font-weight: 600;
  padding: 8rpx 20rpx;
  border-radius: 40rpx;
}
.card-body {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}
.record-item {
  display: flex;
  align-items: center;
  gap: 16rpx;
  font-size: 28rpx;
}
.record-item .iconfont {
  font-size: 28rpx;
  width: 32rpx;
  text-align: center;
}
.card-footer {
  margin-top: 32rpx;
  padding-top: 24rpx;
  border-top: 1px solid; /* Bound to theme.dividerColor */
  font-size: 24rpx;
  text-align: right;
}
.empty-state {
  padding-top: 200rpx;
}
</style>
