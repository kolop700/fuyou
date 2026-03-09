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
            <text class="form-label" :style="{ color: theme.textSecondary }">选择小区</text>
            <view class="input-with-icon" :style="{ background: theme.bgCard }" @click="showCommunitySearch">
              <text class="iconfont icon-fa-building icon" :style="{ color: theme.textSecondary }"></text>
              <view class="picker-field" :class="{ 'placeholder': !form.communityName }" :style="{ color: form.communityName ? theme.textPrimary : theme.textSecondary }">
                {{ form.communityName || '请选择您负责的小区' }}
              </view>
              <text class="iconfont icon-arrow-down picker-arrow" :style="{ color: theme.textSecondary }"></text>
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

    <!-- 小区搜索弹窗 -->
    <uni-popup ref="communityPopup" type="bottom">
      <view class="popup-content" :style="{ background: theme.bgCard, color: theme.textPrimary }">
        <view class="popup-header">
          <input 
            class="search-input" 
            v-model="communitySearchText"
            placeholder="请输入小区名称搜索"
            placeholder-class="input-placeholder"
            :style="{ background: theme.bgInput, color: theme.textPrimary }"
          />
          <button class="search-btn" @click="searchCommunities">搜索</button>
        </view>
        <scroll-view class="popup-body" scroll-y>
          <view 
            v-for="item in communityResults" 
            :key="item.comm_id"
            class="popup-option"
            @click="selectCommunity(item)"
          >
            {{ item.unitname }}
          </view>
          <view v-if="communityResults.length === 0" class="no-results" :style="{ color: theme.textSecondary }">
            没有搜索结果
          </view>
        </scroll-view>
      </view>
    </uni-popup>

  </view>
</template>

<script setup>
import { computed, ref, reactive, getCurrentInstance } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { useThemeStore } from '@/store/modules/theme'
import { useThemeVars } from '@/utils/themeConfig'

const { proxy } = getCurrentInstance()
const themeStore = useThemeStore()
const userStore = proxy.$store.user.useUserStore()
const theme = computed(() => useThemeVars(themeStore.isDark()))

const communityPopup = ref(null)
const communitySearchText = ref('')
const communityResults = ref([])

const navbarHeight = ref(0)

const form = reactive({
  name: '',
  communityId: '',
  communityName: '',
  mobile: '',
  remark: ''
})

onLoad(() => {
  const systemInfo = uni.getSystemInfoSync()
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44
})

const showCommunitySearch = () => {
  communityPopup.value.open()
}

const searchCommunities = async () => {
  if (!communitySearchText.value) {
    uni.showToast({ title: '请输入小区名称', icon: 'none' })
    return
  }
  try {
    const res = await proxy.$api.device.getCommunityList(communitySearchText.value)
    if (res.data && res.data.length > 0) {
      communityResults.value = res.data
    } else {
      communityResults.value = []
      uni.showToast({ title: '未找到相关小区', icon: 'none' })
    }
  } catch (error) {
    console.error('搜索小区失败:', error)
    uni.showToast({ title: '搜索失败', icon: 'none' })
  }
}

const selectCommunity = (community) => {
  form.communityId = community.comm_id
  form.communityName = community.unitname
  communityPopup.value.close()
}

const submitApplication = async () => {
  if (!form.name) {
    return uni.showToast({ title: '请输入姓名', icon: 'none' })
  }
  if (!form.communityId) {
    return uni.showToast({ title: '请选择小区', icon: 'none' })
  }
  if (!form.mobile || !/^1[3-9]\d{9}$/.test(form.mobile)) {
    return uni.showToast({ title: '请输入正确的手机号', icon: 'none' })
  }

  const params = {
    comm_id: form.communityId,
    courier_id: 0, // 新增申请时，ID通常为0
    user_id: userStore.userInfo.user_id,
    name: form.name,
    mobile: form.mobile,
    status: "0", // 默认为未启用
    remark: form.remark
  }

  try {
    const res = await proxy.$api.device.saveCourier(params)
    if (res.code === "0") {
      uni.showToast({
        title: '申请已提交',
        icon: 'success'
      })
      setTimeout(() => uni.navigateBack(), 1500)
    } else {
      uni.showToast({ title: res.msg || '申请失败', icon: 'none' })
    }
  } catch (error) {
    console.error('提交申请失败:', error)
    if (error.statusCode === 454) {
      uni.showToast({
        title: '您已经申请过该小区',
        icon: 'none',
        duration: 3000
      });
    } else {
      uni.showToast({
        title: error.msg || '申请失败，请重试',
        icon: 'none',
        duration: 3000
      });
    }
  }
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

.picker-arrow {
  position: absolute;
  right: 32rpx;
  font-size: 24rpx;
  transition: transform 0.3s ease;
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

.picker-field {
  flex: 1;
  height: 96rpx;
  display: flex;
  align-items: center;
  padding: 0 32rpx 0 84rpx;
  font-size: 30rpx;
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

/* 弹窗样式 */
.popup-content {
  border-radius: 28rpx 28rpx 0 0;
  padding: 32rpx;
  height: 60vh;
  display: flex;
  flex-direction: column;
}

.popup-header {
  display: flex;
  gap: 16rpx;
  margin-bottom: 24rpx;
}

.search-input {
  flex: 1;
  height: 80rpx;
  padding: 0 24rpx;
  border-radius: 20rpx;
  font-size: 28rpx;
}

.search-btn {
  height: 80rpx;
  padding: 0 32rpx;
  border-radius: 20rpx;
  background: #007AFF;
  color: white;
  font-size: 28rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

.popup-body {
  flex: 1;
}

.popup-option {
  padding: 24rpx;
  border-bottom: 1px solid;
  border-color: rgba(128, 128, 128, 0.2);
  font-size: 30rpx;
}

.popup-option:active {
  background-color: rgba(128, 128, 128, 0.1);
}

.no-results {
  text-align: center;
  padding: 40rpx;
  font-size: 28rpx;
}
</style>
