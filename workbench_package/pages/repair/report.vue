<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="提交报修" :show-back="true" />
    
    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="form-container">
        <!-- 所属小区 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">所属小区</text>
          <view class="picker-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <picker @change="bindCommunityChange" :value="communityIndex" :range="communityList">
              <view class="picker-content">
                <text class="picker-text" :style="{ color: theme.textPrimary }">
                  {{ communityList[communityIndex] }}
                </text>
                <text class="iconfont icon-arrow-right picker-icon" :style="{ color: theme.textTertiary }"></text>
              </view>
            </picker>
          </view>
        </view>

        <!-- 报修类型 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">报修类型</text>
          <view class="type-grid">
            <view 
              v-for="(type, index) in repairTypes" 
              :key="index"
              class="type-item"
              :class="{ active: selectedType === type.value }"
              :style="{ 
                background: selectedType === type.value ? theme.getBadgeBackground('info') : theme.bgCard,
                borderColor: selectedType === type.value ? theme.colorInfo : theme.borderColor,
                color: selectedType === type.value ? theme.colorInfo : theme.textSecondary
              }"
              @tap="selectType(type.value)"
            >
              {{ type.label }}
            </view>
          </view>
        </view>

        <!-- 详细描述 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">详细描述</text>
          <textarea 
            class="form-textarea" 
            v-model="description" 
            placeholder="请详细描述故障情况，例如：客厅灯不亮，已检查开关..." 
            :placeholder-style="'color: ' + theme.textTertiary"
            :style="{ background: theme.bgCard, borderColor: theme.borderColor, color: theme.textPrimary }"
          />
        </view>

        <!-- 上传照片 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">上传照片</text>
          <view class="upload-container">
            <view 
              class="upload-btn" 
              :style="{ borderColor: theme.borderColor }"
              @tap="chooseImage"
            >
              <text class="iconfont icon-camera" :style="{ color: theme.textTertiary }"></text>
            </view>
            <!-- 这里省略了图片预览逻辑，实际开发中需要实现 -->
          </view>
        </view>

        <!-- 联系人 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">联系人</text>
          <view class="input-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <input 
              class="form-input" 
              type="text" 
              v-model="contactName" 
              :style="{ color: theme.textPrimary }"
            />
          </view>
        </view>

        <!-- 联系电话 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">联系电话</text>
          <view class="input-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <input 
              class="form-input" 
              type="number" 
              v-model="contactPhone" 
              :style="{ color: theme.textPrimary }"
              maxlength="11"
            />
          </view>
        </view>
      </view>

      <view class="footer-section" :style="{ background: theme.bgPrimary, borderTopColor: theme.borderColor }">
        <button 
          class="submit-btn" 
          :style="{ background: theme.colorAccent }"
          @tap="submitReport"
        >
          提交工单
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
const communityIndex = ref(0);
const communityList = ['幸福里小区', '阳光花园'];
const selectedType = ref('electric');
const description = ref('');
const contactName = ref('王先生');
const contactPhone = ref('13800138000');

const repairTypes = [
  { label: '水电维修', value: 'electric' },
  { label: '家电维修', value: 'appliance' },
  { label: '公共设施', value: 'public' }
];

onLoad(() => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
});

const bindCommunityChange = (e) => {
  communityIndex.value = e.detail.value;
};

const selectType = (value) => {
  selectedType.value = value;
};

const chooseImage = () => {
  uni.chooseImage({
    count: 1,
    success: (res) => {
      console.log('Selected image:', res.tempFilePaths);
    }
  });
};

const submitReport = () => {
  if (!description.value) {
    uni.showToast({ title: '请填写详细描述', icon: 'none' });
    return;
  }
  
  uni.showLoading({ title: '提交中...' });
  setTimeout(() => {
    uni.hideLoading();
    uni.showToast({ title: '提交成功', icon: 'success' });
    setTimeout(() => {
      uni.navigateBack();
    }, 1500);
  }, 1000);
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
  padding: 32rpx 48rpx;
  overflow-y: auto;
}

.form-group {
  margin-bottom: 40rpx;
}

.form-label {
  font-size: 28rpx;
  font-weight: 500;
  margin-bottom: 16rpx;
  display: block;
}

.picker-wrapper, .input-wrapper {
  height: 96rpx;
  border-radius: 24rpx;
  display: flex;
  align-items: center;
  padding: 0 32rpx;
  border: 1px solid transparent;
}

.picker-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.picker-text, .form-input {
  font-size: 30rpx;
  flex: 1;
}

.picker-icon {
  font-size: 32rpx;
}

.form-input {
  height: 100%;
}

/* 报修类型网格 */
.type-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24rpx;
}

.type-item {
  height: 80rpx;
  border-radius: 16rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 26rpx;
  border: 1px solid transparent;
  transition: all 0.2s ease;
}

.type-item.active {
  font-weight: 600;
}

.form-textarea {
  width: 100%;
  height: 200rpx;
  padding: 24rpx 32rpx;
  border-radius: 24rpx;
  font-size: 30rpx;
  box-sizing: border-box;
  border: 1px solid transparent;
}

.upload-container {
  display: flex;
  gap: 24rpx;
}

.upload-btn {
  width: 160rpx;
  height: 160rpx;
  border-radius: 16rpx;
  border: 2rpx dashed;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-camera {
  font-size: 48rpx;
}

.footer-section {
  padding: 32rpx 48rpx;
  padding-bottom: calc(32rpx + env(safe-area-inset-bottom));
  border-top: 1px solid transparent;
}

.submit-btn {
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

.submit-btn:active {
  opacity: 0.9;
  transform: scale(0.98);
}
</style>