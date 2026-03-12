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
          :key="item.id"
          class="history-card" 
          :style="{ background: theme.bgCard, borderColor: theme.dividerColor, boxShadow: theme.shadowCard }"
        >
          <view class="card-header">
            <view class="record-info">
                <text class="record-name" :style="{ color: theme.textPrimary }">{{ item.name }}</text>
            </view>
            <view class="record-status" :style="getStatusStyle(item.status.value)">
                <text>{{ item.status.label }}</text>
            </view>
          </view>
          <view class="card-body">
            <view class="record-item">
                <text class="iconfont icon-phone" :style="{ color: theme.textSecondary }"></text>
                <text :style="{ color: theme.textSecondary }">{{ item.mobile }}</text>
            </view>
            <view class="record-item" v-if="item.remark">
                <text class="iconfont icon-fa-comments" :style="{ color: theme.textSecondary }"></text>
                <text :style="{ color: theme.textSecondary }">{{ item.remark }}</text>
            </view>
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
const userStore = proxy.$store.user.useUserStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const historyList = ref([]);
const isLoading = ref(true);
const isRefreshing = ref(false);

const fetchHistory = async () => {
  const showLoading = !isRefreshing.value;
  try {
    const userId = userStore.userInfo.user_id;
    const res = await proxy.$api.device.getCourierHistory(userId, 1, 50, { showLoading });
    if (res.items) {
      historyList.value = res.items.sort((a, b) => b.id - a.id);
    } else {
      historyList.value = [];
    }
  } catch (error) {
    console.error('获取申请记录失败:', error);
  } finally {
    isLoading.value = false;
    isRefreshing.value = false;
  }
};

const onRefresh = async () => {
  isRefreshing.value = true;
  await fetchHistory();
};

const getStatusStyle = (statusValue) => {
  const styleMap = {
    0: { background: theme.value.getBadgeBackground('warning'), color: theme.value.colorWarning }, // 未启用
    1: { background: theme.value.getBadgeBackground('success'), color: theme.value.colorSuccess }, // 已启用
  };
  return styleMap[statusValue] || { background: theme.value.getBadgeBackground('info'), color: theme.value.colorInfo };
};

onLoad(() => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  fetchHistory();
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
