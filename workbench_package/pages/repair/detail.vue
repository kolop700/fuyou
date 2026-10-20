<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="报修详情" :show-back="true" />

    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="detail-card" :style="{ background: theme.bgCard, boxShadow: theme.shadowCard, borderColor: theme.dividerColor }">
        <view class="detail-header">
          <view class="status-badge" :style="{ background: getStatusBg(detail.statusValue), color: getStatusColor(detail.statusValue) }">
            {{ detail.statusLabel || getStatusText(detail.statusValue) }}
          </view>
          <text class="time-text" :style="{ color: theme.textTertiary }">{{ detail.created_at || '--' }}</text>
        </view>

        <text class="detail-title" :style="{ color: theme.textPrimary }">{{ detail.title || '未命名报修' }}</text>
        <text class="detail-desc" :style="{ color: theme.textSecondary }">{{ detail.description || '暂无描述' }}</text>

        <view class="info-list">
          <view class="info-row" :style="{ borderTopColor: theme.dividerColor }">
            <text class="info-label" :style="{ color: theme.textTertiary }">报修单号</text>
            <text class="info-value" :style="{ color: theme.textPrimary }">{{ detail.no || '-' }}</text>
          </view>
          <view class="info-row" :style="{ borderTopColor: theme.dividerColor }">
            <text class="info-label" :style="{ color: theme.textTertiary }">所属小区</text>
            <text class="info-value" :style="{ color: theme.textPrimary }">{{ detail.comm_name || '-' }}</text>
          </view>
          <view class="info-row" :style="{ borderTopColor: theme.dividerColor }">
            <text class="info-label" :style="{ color: theme.textTertiary }">联系电话</text>
            <text class="info-value" :style="{ color: theme.textPrimary }">{{ detail.contact || '-' }}</text>
          </view>
          <view class="info-row" :style="{ borderTopColor: theme.dividerColor }">
            <text class="info-label" :style="{ color: theme.textTertiary }">备注信息</text>
            <text class="info-value multiline" :style="{ color: theme.textPrimary }">{{ detail.remark || '暂无备注' }}</text>
          </view>
        </view>
      </view>

      <view v-if="detailImages.length" class="image-card" :style="{ background: theme.bgCard, boxShadow: theme.shadowCard, borderColor: theme.dividerColor }">
        <text class="section-title" :style="{ color: theme.textPrimary }">报修图片</text>
        <view class="image-list">
          <image
            v-for="(item, index) in detailImages"
            :key="item + index"
            class="preview-image"
            :src="item"
            mode="aspectFill"
            @tap="previewImage(index)"
          />
        </view>
      </view>
    </view>
  
    <!-- 底部横幅广告（Taku）：常驻页面底部，placementId 为空/开关全关时自动隐藏 -->
    <view class="ad-section" v-if="bannerAdId">
      <view class="ad-divider"></view>
      <view class="ad-view">
        <taku-banner :placement-id="bannerAdId"></taku-banner>
      </view>
    </view>
    </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useThemeStore } from '@/store/modules/theme';
import { useThemeVars } from '@/utils/themeConfig';
import { buildImageUrls } from '@/utils/imageUrl';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));

const navbarHeight = ref(0);
const detail = ref({});
const detailImages = computed(() => buildImageUrls(detail.value.images || []));

onLoad((options) => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;

  const cached = uni.getStorageSync('repair_detail_item');
  if (cached && (!options?.id || String(cached.id) === String(options.id))) {
    detail.value = normalizeDetail(cached);
  }
});

const normalizeStatus = (status) => {
  if (status && typeof status === 'object') {
    const objectValue = status.value;
    if (objectValue !== undefined && objectValue !== null && objectValue !== '') {
      return String(objectValue).trim();
    }
  }

  const value = String(status ?? '').trim();
  const match = value.match(/[0-2]/);
  return match ? match[0] : value;
};

const normalizeDetail = (data = {}) => {
  const statusValue = normalizeStatus(data.status);
  const statusLabel = data?.status?.label || getStatusText(statusValue);

  return {
    ...data,
    statusValue,
    statusLabel
  };
};

const getStatusText = (status) => {
  if (status && typeof status === 'object' && status.label) {
    return status.label;
  }

  const map = {
    '0': '待处理',
    '1': '已处理',
    '2': '已拒绝'
  };

  return map[normalizeStatus(status)] || '待处理';
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

const previewImage = (index) => {
  uni.previewImage({
    current: index,
    urls: detailImages.value
  });
};

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
</script>

<style scoped>
.page-container {
  min-height: 100vh;
  transition: background 0.3s ease;
}

.page-content {
  padding: 24rpx 32rpx 48rpx;
  box-sizing: border-box;
}

.detail-card,
.image-card {
  border-radius: 24rpx;
  padding: 32rpx;
  border: 1px solid transparent;
  margin-bottom: 24rpx;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
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

.detail-title {
  font-size: 34rpx;
  font-weight: 700;
  margin-bottom: 16rpx;
  display: block;
}

.detail-desc {
  font-size: 28rpx;
  line-height: 1.7;
  display: block;
  margin-bottom: 28rpx;
}

.info-list {
  display: flex;
  flex-direction: column;
}

.info-row {
  display: flex;
  justify-content: space-between;
  gap: 24rpx;
  padding: 24rpx 0;
  border-top: 1px solid transparent;
}

.info-label {
  font-size: 24rpx;
  flex-shrink: 0;
}

.info-value {
  font-size: 26rpx;
  text-align: right;
  flex: 1;
}

.multiline {
  line-height: 1.6;
}

.section-title {
  font-size: 30rpx;
  font-weight: 600;
  margin-bottom: 20rpx;
  display: block;
}

.image-list {
  display: flex;
  flex-wrap: wrap;
  gap: 20rpx;
}

.preview-image {
  width: 180rpx;
  height: 180rpx;
  border-radius: 18rpx;
}

/* ===== Taku 底部横幅广告 ===== */
.ad-section {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 20;
  width: 100%;
  box-sizing: border-box;
  background: #ffffff;
  box-shadow: 0 -6rpx 20rpx rgba(31, 48, 152, 0.08);
}

.ad-section .ad-divider {
  height: 2rpx;
  background: #eeeeee;
}

.ad-section .ad-view {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 120rpx;
  padding: 8rpx 0;
}

/* Tab 页：横幅悬浮在自定义 tabbar（高100rpx+安全区）上方 */
.ad-section.ad-tab {
  bottom: calc(100rpx + env(safe-area-inset-bottom));
  box-shadow: 0 -4rpx 16rpx rgba(31, 48, 152, 0.12);
}
</style>
