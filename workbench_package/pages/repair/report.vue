<template>
  <view class="page-container" :style="{ background: theme.bgPrimary }">
    <custom-navbar title="提交报修" :show-back="true" />
    
    <view class="page-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="form-container">
        <!-- 所属小区 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">所属小区</text>
          <view class="picker-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <picker class="picker-trigger" @change="bindCommunityChange" :value="communityIndex" :range="communityNames">
              <view class="picker-content">
                <text class="picker-text" :style="{ color: theme.textPrimary }">
                  {{ communityNames[communityIndex] || '请选择小区' }}
                </text>
                <text class="iconfont icon-arrow-right picker-icon" :style="{ color: theme.textTertiary }"></text>
              </view>
            </picker>
          </view>
        </view>

        <!-- 标题 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">报修标题</text>
          <view class="input-wrapper" :style="{ background: theme.bgCard, borderColor: theme.borderColor }">
            <input
              class="form-input"
              type="text"
              v-model="title"
              placeholder="请输入报修标题"
              :placeholder-style="'color: ' + theme.textTertiary"
              :style="{ color: theme.textPrimary }"
            />
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
          <view class="upload-header">
            <text class="form-label" :style="{ color: theme.textSecondary }">上传照片</text>
            <text class="upload-tip" :style="{ color: theme.textTertiary }">{{ imageList.length }}/2</text>
          </view>
          <view class="upload-container">
            <view 
              v-if="imageList.length < 2"
              class="upload-btn" 
              :style="{ borderColor: theme.borderColor, background: theme.bgCard }"
              @tap="chooseImage"
            >
              <uni-icons type="plusempty" :size="34" :color="theme.textTertiary" />
            </view>
            <view
              v-for="(item, index) in imageList"
              :key="item.path + index"
              class="preview-item"
            >
              <image
                class="preview-image"
                :src="item.path"
                mode="aspectFill"
                @tap="previewImage(index)"
              />
              <view
                class="remove-image-btn"
                @tap.stop="removeImage(index)"
              >
                ×
              </view>
            </view>
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

    <t-cropper
      mode="free"
      :imageUrl="cropImageUrl"
      :width="600"
      :height="600"
      :maxWidth="900"
      :maxHeight="900"
      :scaleRatio="0.85"
      :delay="150"
      @cancel="handleCropCancel"
      @confirm="handleCropConfirm"
    />
  
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
import TCropper from '@/uni_modules/t-cropper/components/t-cropper/t-cropper.vue';

const { proxy } = getCurrentInstance();
const themeStore = proxy.$store.theme.useThemeStore();
const userStore = proxy.$store.user.useUserStore();
const theme = computed(() => useThemeVars(themeStore.isDark()));
// base64 会比原文件更大，因此这里把原始图片目标压到更低，尽量控制最终上传体积
const MAX_UPLOAD_IMAGE_SIZE = 120 * 1024;

const navbarHeight = ref(0);

// 表单数据
const communityIndex = ref(0);
const communityList = ref([]);
const title = ref('');
const description = ref('');
const contactName = ref('');
const contactPhone = ref('');
const imageList = ref([]);
const cropImageUrl = ref('');

const communityNames = computed(() => communityList.value.map(item => item.comm_name));
const selectedCommunity = computed(() => communityList.value[communityIndex.value] || null);

onLoad(async () => {
  themeStore.loadTheme();
  const systemInfo = uni.getSystemInfoSync();
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44;
  contactName.value = userStore.userInfo?.user_name || '';
  contactPhone.value = userStore.userInfo?.user_acct || '';
  await fetchCommunityList();
});

const bindCommunityChange = (e) => {
  communityIndex.value = Number(e.detail.value);
};

const fetchCommunityList = async () => {
  try {
    const userId = userStore.userInfo?.user_id;

    if (!userId) {
      communityList.value = [];
      return;
    }

    const res = await proxy.$api.device.getUserCommunityList(userId, { showLoading: false });
    const list = Array.isArray(res?.data) ? res.data : Array.isArray(res) ? res : [];
    const communityMap = new Map();

    list.forEach(item => {
      const commId = Number(item.comm_id);

      if (!commId || communityMap.has(commId)) return;

      communityMap.set(commId, {
        comm_id: commId,
        comm_name: item.comm_name || `小区 ${commId}`
      });
    });

    communityList.value = Array.from(communityMap.values());
    communityIndex.value = 0;
  } catch (error) {
    communityList.value = [];
  }
};

const chooseImage = () => {
  if (imageList.value.length >= 2) {
    uni.showToast({ title: '最多上传2张图片', icon: 'none' });
    return;
  }

  uni.chooseImage({
    count: 1,
    sizeType: ['compressed'],
    success: (res) => {
      const filePath = res.tempFilePaths?.[0];

      if (!filePath) return;

      if (typeof uni.compressImage === 'function') {
        uni.showLoading({ title: '处理中...', mask: true });
        uni.compressImage({
          src: filePath,
          quality: 80,
          success: (compressRes) => {
            cropImageUrl.value = compressRes.tempFilePath || filePath;
          },
          fail: () => {
            cropImageUrl.value = filePath;
          },
          complete: () => {
            uni.hideLoading();
          }
        });
        return;
      }

      cropImageUrl.value = filePath;
    }
  });
};

const previewImage = (index) => {
  uni.previewImage({
    current: index,
    urls: imageList.value.map(item => item.path)
  });
};

const removeImage = (index) => {
  imageList.value.splice(index, 1);
};

const handleCropCancel = () => {
  cropImageUrl.value = '';
};

const handleCropConfirm = (res) => {
  const tempFilePath = res?.tempFilePath;

  if (!tempFilePath) {
    cropImageUrl.value = '';
    uni.showToast({ title: '裁剪失败，请重试', icon: 'none' });
    return;
  }

  imageList.value.push({
    path: tempFilePath,
    name: `repair_${Date.now()}.jpg`
  });
  cropImageUrl.value = '';
};

const getBase64FromPath = (filePath) => {
  return new Promise((resolve, reject) => {
    const fs = uni.getFileSystemManager && uni.getFileSystemManager();

    if (fs && fs.readFile) {
      fs.readFile({
        filePath,
        encoding: 'base64',
        success: (res) => resolve(res.data),
        fail: reject
      });
      return;
    }

    if (typeof fetch !== 'function' || typeof FileReader === 'undefined') {
      reject(new Error('当前环境不支持读取图片'));
      return;
    }

    fetch(filePath)
      .then(res => res.blob())
      .then(blob => {
        const reader = new FileReader();
        reader.onloadend = () => {
          const result = String(reader.result || '');
          resolve(result.includes(',') ? result.split(',')[1] : result);
        };
        reader.onerror = reject;
        reader.readAsDataURL(blob);
      })
      .catch(reject);
  });
};

const getFileSize = (filePath) => {
  return new Promise((resolve) => {
    if (typeof uni.getFileInfo !== 'function') {
      resolve(null);
      return;
    }

    uni.getFileInfo({
      filePath,
      success: (res) => resolve(Number(res.size) || null),
      fail: () => resolve(null)
    });
  });
};

const blobToBase64 = (blob, quality = 0.92, scale = 1) => {
  return new Promise((resolve, reject) => {
    if (typeof FileReader === 'undefined') {
      reject(new Error('当前环境不支持图片压缩'));
      return;
    }

    const image = new Image();
    const objectUrl = URL.createObjectURL(blob);

    image.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = Math.max(1, Math.floor(image.width * scale));
      canvas.height = Math.max(1, Math.floor(image.height * scale));

      const ctx = canvas.getContext('2d');
      if (!ctx) {
        URL.revokeObjectURL(objectUrl);
        reject(new Error('当前环境不支持图片压缩'));
        return;
      }

      ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
      canvas.toBlob((compressedBlob) => {
        URL.revokeObjectURL(objectUrl);

        if (!compressedBlob) {
          reject(new Error('图片压缩失败'));
          return;
        }

        const reader = new FileReader();
        reader.onloadend = () => {
          const result = String(reader.result || '');
          resolve({
            size: compressedBlob.size,
            data: result.includes(',') ? result.split(',')[1] : result
          });
        };
        reader.onerror = reject;
        reader.readAsDataURL(compressedBlob);
      }, 'image/jpeg', quality);
    };

    image.onerror = (error) => {
      URL.revokeObjectURL(objectUrl);
      reject(error);
    };
    image.src = objectUrl;
  });
};

const compressBlobToTargetBase64 = async (blob) => {
  const attempts = [
    { quality: 0.82, scale: 0.85 },
    { quality: 0.72, scale: 0.72 },
    { quality: 0.62, scale: 0.62 },
    { quality: 0.52, scale: 0.55 },
    { quality: 0.42, scale: 0.48 },
    { quality: 0.32, scale: 0.4 },
    { quality: 0.22, scale: 0.32 }
  ];

  let bestResult = null;

  for (const attempt of attempts) {
    const result = await blobToBase64(blob, attempt.quality, attempt.scale);

    if (!bestResult || result.size < bestResult.size) {
      bestResult = result;
    }

    if (result.size <= MAX_UPLOAD_IMAGE_SIZE) {
      return result.data;
    }
  }

  return bestResult?.data || '';
};

const compressImagePathToTarget = async (filePath) => {
  const originalSize = await getFileSize(filePath);
  if (originalSize && originalSize <= MAX_UPLOAD_IMAGE_SIZE) {
    return filePath;
  }

  if (typeof uni.compressImage !== 'function') {
    return filePath;
  }

  const qualities = [60, 40, 25, 15, 8];
  let bestPath = filePath;
  let bestSize = originalSize || Number.MAX_SAFE_INTEGER;
  let currentPath = filePath;

  for (const quality of qualities) {
    const compressedPath = await new Promise((resolve) => {
      uni.compressImage({
        src: currentPath,
        quality,
        success: (res) => resolve(res.tempFilePath || currentPath),
        fail: () => resolve(currentPath)
      });
    });

    const compressedSize = await getFileSize(compressedPath);
    if (compressedSize && compressedSize < bestSize) {
      bestSize = compressedSize;
      bestPath = compressedPath;
    }
    currentPath = compressedPath;

    if (compressedSize && compressedSize <= MAX_UPLOAD_IMAGE_SIZE) {
      return compressedPath;
    }
  }

  return bestPath;
};

const getUploadImageData = async (filePath) => {
  const canUseCanvasCompress = typeof document !== 'undefined' && typeof fetch === 'function' && typeof FileReader !== 'undefined';

  if (canUseCanvasCompress) {
    const response = await fetch(filePath);
    const blob = await response.blob();

    if (blob.size <= MAX_UPLOAD_IMAGE_SIZE) {
      const base64 = await getBase64FromPath(filePath);
      return base64;
    }

    return await compressBlobToTargetBase64(blob);
  }

  const compressedPath = await compressImagePathToTarget(filePath);
  return await getBase64FromPath(compressedPath);
};

const buildImagesPayload = async () => {
  const files = [];

  for (const item of imageList.value) {
    const data = await getUploadImageData(item.path);
    const filename = item.name || item.path.split('/').pop() || `repair_${Date.now()}.jpg`;
    files.push({ filename, data });
  }

  return files;
};

const submitReport = async () => {
  if (!selectedCommunity.value?.comm_id) {
    uni.showToast({ title: '请选择所属小区', icon: 'none' });
    return;
  }
  if (!title.value.trim()) {
    uni.showToast({ title: '请填写报修标题', icon: 'none' });
    return;
  }
  if (!description.value) {
    uni.showToast({ title: '请填写详细描述', icon: 'none' });
    return;
  }
  if (!contactPhone.value) {
    uni.showToast({ title: '请填写联系电话', icon: 'none' });
    return;
  }

  uni.showLoading({ title: '提交中...' });
  try {
    const images = await buildImagesPayload();
    await proxy.$api.repair.report({
      comm_id: selectedCommunity.value.comm_id,
      title: title.value.trim(),
      description: description.value,
      contact: [String(contactName.value || '').trim(), String(contactPhone.value || '').trim()].filter(Boolean).join(' '),
      images
    });
    uni.hideLoading();
    uni.showToast({ title: '提交成功', icon: 'success' });
    setTimeout(() => {
      uni.navigateBack();
    }, 1500);
  } catch (e) {
    uni.hideLoading();
    uni.showToast({ title: e?.msg || e?.detail || e?.message || '提交失败，请重试', icon: 'none' });
  }
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

.upload-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.upload-tip {
  font-size: 24rpx;
  margin-bottom: 16rpx;
}

.picker-wrapper, .input-wrapper {
  height: 96rpx;
  border-radius: 24rpx;
  display: flex;
  align-items: center;
  padding: 0 32rpx;
  border: 1px solid transparent;
}

.picker-trigger {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
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
  flex-wrap: wrap;
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

.preview-image {
  width: 160rpx;
  height: 160rpx;
  border-radius: 16rpx;
}

.preview-item {
  position: relative;
  width: 160rpx;
  height: 160rpx;
}

.remove-image-btn {
  position: absolute;
  top: -12rpx;
  right: -12rpx;
  width: 40rpx;
  height: 40rpx;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.7);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
  line-height: 1;
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
