<template>
  <view class="application-container" :style="{ background: theme.bgPrimary }">
    <!-- 自定义导航栏 -->
    <custom-navbar title="快递员申请" :show-back="true" />
    
    <scroll-view 
      class="content-scroll" 
      scroll-y
      :style="{ paddingTop: navbarHeight + 'px' }"
    >
      <view class="page-content">
        <view class="header-icon">
          <view class="icon-wrapper" :style="{ background: theme.getBadgeBackground('info') }">
            <text class="iconfont icon-shipping-fast" :style="{ color: theme.colorInfo }"></text>
          </view>
        </view>
        
        <view class="title-section">
          <text class="main-title" :style="{ color: theme.textPrimary }">成为合作快递员</text>
          <text class="subtitle" :style="{ color: theme.textSecondary }">请填写真实有效的信息</text>
        </view>

        <!-- 申请表单 -->
        <view class="form-wrapper">
          <view class="form-group">
            <text class="form-label" :style="{ color: theme.textSecondary }">姓名</text>
            <view class="input-with-icon" :style="{ background: theme.bgCard }">
              <text class="iconfont icon-fa-user icon" :style="{ color: theme.textSecondary }"></text>
              <input 
                class="input-field" 
                v-model="form.name"
                placeholder="请输入您的真实姓名"
                placeholder-class="input-placeholder"
                :style="{ color: theme.textPrimary }"
              />
            </view>
          </view>
          
          <view class="form-group">
            <text class="form-label" :style="{ color: theme.textSecondary }">手机号</text>
            <view class="input-with-icon" :style="{ background: theme.bgCard }">
              <text class="iconfont icon-mobile-alt icon" :style="{ color: theme.textSecondary }"></text>
              <input 
                type="tel"
                class="input-field" 
                v-model="form.mobile"
                placeholder="请输入您的11位手机号码"
                placeholder-class="input-placeholder"
                :style="{ color: theme.textPrimary }"
              />
            </view>
          </view>
          
          <view class="form-group">
            <text class="form-label" :style="{ color: theme.textSecondary }">备注</text>
            <view class="input-with-icon" :style="{ background: theme.bgCard }">
               <text class="iconfont icon-fa-comments icon" :style="{ color: theme.textSecondary, top: '32rpx' }"></text>
              <textarea 
                class="textarea-field" 
                v-model="form.remark"
                placeholder="选填，如快递公司、负责区域等"
                placeholder-class="input-placeholder"
                :style="{ color: theme.textPrimary }"
              ></textarea>
            </view>
          </view>

          <button 
            class="btn-primary" 
            :style="{ background: theme.colorAccentGradient, boxShadow: theme.shadowButton }"
            @click="submitApplication"
          >
            提交申请
          </button>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { computed, ref, reactive } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { useThemeStore } from '@/store/modules/theme'
import { useThemeVars } from '@/utils/themeConfig'

const themeStore = useThemeStore()
const theme = computed(() => useThemeVars(themeStore.isDark()))

const navbarHeight = ref(0)
const focusField = ref('')

const form = reactive({
  name: '',
  mobile: '',
  remark: ''
})

onLoad(() => {
  const systemInfo = uni.getSystemInfoSync()
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44
})

const submitApplication = () => {
  // TODO: 在这里实现表单验证和提交逻辑
  console.log('Form submitted:', form)
  uni.showToast({
    title: '申请已提交',
    icon: 'success'
  })
}
</script>

<style scoped>
.application-container {
  min-height: 100vh;
}

.content-scroll {
  height: 100vh;
  box-sizing: border-box;
}

.page-content {
  padding: 40rpx 48rpx;
  position: relative;
  z-index: 10;
}

.header-icon {
  display: flex;
  justify-content: center;
  margin-bottom: 40rpx;
}

.icon-wrapper {
  width: 160rpx;
  height: 160rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-wrapper .iconfont {
  font-size: 72rpx;
}

.title-section {
  text-align: center;
  margin-bottom: 64rpx;
}

.main-title {
  font-size: 44rpx;
  font-weight: 700;
  display: block;
  margin-bottom: 16rpx;
}

.subtitle {
  font-size: 28rpx;
}

.form-wrapper {
  display: flex;
  flex-direction: column;
  gap: 40rpx;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.form-label {
  font-size: 28rpx;
  font-weight: 500;
  margin-bottom: 16rpx;
}

.input-with-icon {
  position: relative;
  display: flex;
  align-items: center;
  border-radius: 28rpx;
  overflow: hidden;
  transition: all 0.3s ease;
}

.icon {
  position: absolute;
  left: 32rpx;
  font-size: 32rpx;
  z-index: 2;
}

.input-field {
  width: 100%;
  height: 96rpx;
  padding: 0 32rpx 0 84rpx;
  font-size: 30rpx;
  border: none;
  outline: none;
  background: transparent;
  transition: all 0.3s ease;
  box-sizing: border-box;
}

.textarea-field {
  width: 100%;
  height: 200rpx;
  padding: 32rpx 32rpx 32rpx 84rpx;
  font-size: 30rpx;
  border: none;
  outline: none;
  background: transparent;
  box-sizing: border-box;
  resize: none;
}

.input-placeholder {
  color: var(--color-text-secondary); /* Fallback, will be overridden by theme */
}

.btn-primary {
  width: 100%;
  height: 96rpx;
  border: none;
  border-radius: 28rpx;
  color: white;
  font-size: 32rpx;
  font-weight: 600;
  transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
  margin-top: 40rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
}

.btn-primary:active {
  transform: scale(0.98);
}
</style>
