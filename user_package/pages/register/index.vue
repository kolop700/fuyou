<template>
  <view class="register-page" :style="{ background: theme.bgPrimary }">
    <!-- 环境光背景 -->
    <view class="ambient-bg"></view>
    
    <!-- 自定义导航栏 -->
    <custom-navbar title="注册账号" :show-back="true" />
    
    <!-- 内容区域 -->
    <scroll-view scroll-y class="scroll-content" :style="{ paddingTop: navbarHeight + 'px' }">
      <view class="page-content">
        <!-- 表单 -->
        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">手机号码</text>
          <view class="input-with-icon" :style="{ background: theme.bgCard }">
            <text class="iconfont icon-mobile-alt icon" :style="{ color: theme.textSecondary }"></text>
            <input 
              v-model="form.phone" 
              type="text" 
              class="input-field" 
              :style="{ color: theme.textPrimary }"
              placeholder="请输入手机号"
              placeholder-class="placeholder"
              :maxlength="11"
            />
          </view>
        </view>

        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">验证码</text>
          <view class="verify-row">
            <view class="input-with-icon verify-input" :style="{ background: theme.bgCard }">
              <input 
                v-model="form.code" 
                type="text" 
                class="input-field" 
                :style="{ color: theme.textPrimary }"
                placeholder="请输入验证码"
                placeholder-class="placeholder"
                :maxlength="6"
              />
            </view>
            <button 
              class="btn-secondary" 
              :style="secondaryBtnStyle"
              :disabled="counting" 
              @click="getCode"
            >
              {{ counting ? `${counter}s` : '获取验证码' }}
            </button>
          </view>
        </view>

        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">姓名</text>
          <view class="input-with-icon" :style="{ background: theme.bgCard }">
            <text class="iconfont icon-fa-user icon" :style="{ color: theme.textSecondary }"></text>
            <input 
              v-model="form.name" 
              type="text" 
              class="input-field" 
              :style="{ color: theme.textPrimary }"
              placeholder="请输入姓名"
              placeholder-class="placeholder"
            />
          </view>
        </view>

        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">设置密码</text>
          <view class="input-with-icon" :style="{ background: theme.bgCard }">
            <text class="iconfont icon-fa-lock icon" :style="{ color: theme.textSecondary }"></text>
            <input 
              v-model="form.password" 
              :type="showPassword ? 'text' : 'password'" 
              class="input-field" 
              :style="{ color: theme.textPrimary }"
              placeholder="请设置6-16位密码"
              placeholder-class="placeholder"
            />
          </view>
        </view>

        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">确认密码</text>
          <view class="input-with-icon" :style="{ background: theme.bgCard }">
            <text class="iconfont icon-fa-lock icon" :style="{ color: theme.textSecondary }"></text>
            <input 
              v-model="form.confirmPassword" 
              :type="showConfirmPassword ? 'text' : 'password'" 
              class="input-field" 
              :style="{ color: theme.textPrimary }"
              placeholder="请再次输入密码"
              placeholder-class="placeholder"
            />
          </view>
        </view>

        <view class="form-group">
          <text class="form-label" :style="{ color: theme.textSecondary }">性别（可选）</text>
          <view class="input-with-icon" :style="{ background: theme.bgCard }" @click="showGenderPicker">
            <text class="iconfont icon-fa-venus-mars icon" :style="{ color: theme.textSecondary }"></text>
            <view class="picker-field" :style="{ color: form.gender ? theme.textPrimary : theme.textSecondary }">
              {{ genderText || '请选择性别' }}
            </view>
            <text class="iconfont icon-arrow-down picker-arrow" :style="{ color: theme.textSecondary }"></text>
          </view>
        </view>

        <!-- 协议同意 -->
        <view class="agreement">
          <checkbox 
            :checked="checked" 
            @click="toggleCheck" 
            :color="theme.colorAccent"
          />
          <text class="agreement-text" :style="{ color: theme.textSecondary }">我已阅读并同意 </text>
          <text class="link-text-inline" :style="{ color: theme.colorAccent }" @click="openUserAgreement">《用户协议》</text>
          <text class="agreement-text" :style="{ color: theme.textSecondary }"> 和 </text>
          <text class="link-text-inline" :style="{ color: theme.colorAccent }" @click="openPrivacyPolicy">《隐私政策》</text>
          <text class="agreement-text" :style="{ color: theme.textSecondary }">，否则将退出应用。</text>
        </view>

        <!-- 提交按钮 -->
        <button class="btn-primary" :style="{ boxShadow: theme.shadowButton }" @click="handleSubmit">提交注册</button>

        <!-- 返回登录 -->
        <view class="register-link">
          <text class="register-text" :style="{ color: theme.textSecondary }">已有账号？</text>
          <text class="link-text" :style="{ color: theme.colorAccent }" @click="goToLogin">立即登录</text>
        </view>
      </view>
    </scroll-view>

    <!-- 性别选择器 -->
    <u-action-sheet 
      :show="showGenderSheet" 
      :actions="genderActions"
      title="选择性别"
      :round="28"
      :closeOnClickOverlay="true"
      :safeAreaInsetBottom="true"
      @close="showGenderSheet = false"
      @select="onGenderSelect"
    ></u-action-sheet>
  
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
import { ref, computed, getCurrentInstance } from 'vue'
import { onLoad } from "@dcloudio/uni-app"
import { useThemeVars } from '@/utils/themeConfig.js'

const { proxy } = getCurrentInstance()

// 数据
const form = ref({
  phone: '',
  code: '',
  name: '',
  password: '',
  confirmPassword: '',
  gender: ''
})

const showPassword = ref(false)
const showConfirmPassword = ref(false)
const checked = ref(false)
const counting = ref(false)
const counter = ref(60)
const savedVerifyCode = ref('')
const savedPhone = ref('')
const navbarHeight = ref(0)
const showGenderSheet = ref(false)

// 性别选项
const genderOptions = ['男', '女', '保密']
const genderValues = ['male', 'female', 'secret']
const genderIndex = ref(-1)

// uview 性别选项数组
const genderActions = [
  { name: '男', value: 'male' },
  { name: '女', value: 'female' },
  { name: '保密', value: 'secret' }
]

// 获取主题 Store
const themeStore = proxy.$store.theme.useThemeStore()

// 主题变量
const theme = computed(() => useThemeVars(themeStore.isDark()))

// uview 组件主题样式
const actionSheetBg = computed(() => theme.value.bgCard)
const actionSheetTitleColor = computed(() => theme.value.textPrimary)
const actionSheetItemColor = computed(() => theme.value.textPrimary)
const actionSheetCancelColor = computed(() => theme.value.textSecondary)
const actionSheetHoverBg = computed(() => theme.value.bgCardHover)
const actionSheetCloseBg = computed(() => theme.value.bgInput)
const actionSheetLineColor = computed(() => theme.value.borderColor)
const actionSheetGapBg = computed(() => theme.value.bgInput)

// 性别显示文本
const genderText = computed(() => {
  if (genderIndex.value >= 0) {
    return genderOptions[genderIndex.value]
  }
  return ''
})

// 次要按钮样式
const secondaryBtnStyle = computed(() => {
  const shadow = themeStore.isDark() ? 'none' : '0 4rpx 16rpx rgba(0,0,0,0.06)'
  return {
    background: theme.value.bgCard,
    color: theme.value.textPrimary,
    borderColor: theme.value.borderColor,
    boxShadow: shadow
  }
})

// 显示性别选择器
const showGenderPicker = () => {
  showGenderSheet.value = true
}

// 性别选择改变
const onGenderSelect = (item) => {
  const index = genderActions.findIndex(action => action.value === item.value)
  genderIndex.value = index
  form.value.gender = item.value
  showGenderSheet.value = false
}

// 切换协议勾选
const toggleCheck = () => {
  checked.value = !checked.value
}

// 验证手机号
const validatePhone = () => {
  if (!form.value.phone) {
    uni.showToast({ title: '请输入手机号', icon: 'none' })
    return false
  }
  if (!/^1[3-9]\d{9}$/.test(form.value.phone)) {
    uni.showToast({ title: '手机号格式不正确', icon: 'none' })
    return false
  }
  return true
}

// 生成90位随机验证码
const generateVerifyCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString()
}

// 获取验证码
const getCode = async () => {
  if (counting.value) return
  if (!validatePhone()) return
  
  try {
    const verifyCode = generateVerifyCode()
    const res = await proxy.$api.user.sendSMS(form.value.phone, verifyCode)
    savedVerifyCode.value = verifyCode
    savedPhone.value = form.value.phone
    
    uni.showToast({ title: '验证码已发送', icon: 'success' })
    counting.value = true
    counter.value = 60
    const timer = setInterval(() => {
      if (counter.value > 0) {
        counter.value--
      } else {
        counting.value = false
        clearInterval(timer)
      }
    }, 1000)
  } catch (error) {
    console.error('发送验证码错误:', error)
  }
}

// 表单验证
const validateForm = () => {
  if (!form.value.phone) {
    uni.showToast({ title: '请输入手机号', icon: 'none' })
    return false
  }
  if (!/^1[3-9]\d{9}$/.test(form.value.phone)) {
    uni.showToast({ title: '手机号格式不正确', icon: 'none' })
    return false
  }
  if (!form.value.code) {
    uni.showToast({ title: '请输入验证码', icon: 'none' })
    return false
  }
  if (!savedVerifyCode.value || !savedPhone.value) {
    uni.showToast({ title: '请先获取验证码', icon: 'none' })
    return false
  }
  if (savedPhone.value !== form.value.phone) {
    uni.showToast({ title: '手机号与获取验证码时不一致', icon: 'none' })
    return false
  }
  if (form.value.code !== savedVerifyCode.value) {
    uni.showToast({ title: '验证码错误', icon: 'none' })
    return false
  }
  if (!form.value.name) {
    uni.showToast({ title: '请输入姓名', icon: 'none' })
    return false
  }
  if (!form.value.password) {
    uni.showToast({ title: '请输入密码', icon: 'none' })
    return false
  }
  if (form.value.password.length < 6) {
    uni.showToast({ title: '密码不能少于6位', icon: 'none' })
    return false
  }
  if (form.value.password !== form.value.confirmPassword) {
    uni.showToast({ title: '两次输入的密码不一致', icon: 'none' })
    return false
  }
  // 性别可选，不验证
  if (!checked.value) {
    uni.showToast({ title: '请先同意用户协议和隐私政策', icon: 'none' })
    return false
  }
  return true
}

// 提交表单
const handleSubmit = async () => {
  if (!validateForm()) return
  
  try {
    const res = await proxy.$api.user.UserRegister(form.value)
    if(res.code === "0") {
      uni.showToast({ 
        title: '注册成功', 
        icon: 'success',
        duration: 2000
      })
      setTimeout(() => {
        uni.reLaunch({
          url: '/user_package/pages/login/index'
        })
      }, 2000)
    }
  } catch (error) {
    console.error('注册失败:', error)
    uni.showToast({ 
      title: error.msg || '注册失败', 
      icon: 'none' 
    })
  }
}

// 打开用户协议
const openUserAgreement = () => {
  uni.navigateTo({
    url: `/user_package/pages/webview?title=${encodeURIComponent('用户协议')}&url=${encodeURIComponent('http://fuyou.yefiot.com/user.html')}`
  })
}

// 打开隐私政策
const openPrivacyPolicy = () => {
  uni.navigateTo({
    url: `/user_package/pages/webview?title=${encodeURIComponent('隐私政策')}&url=${encodeURIComponent('http://fuyou.yefiot.com/privacy.html')}`
  })
}

// 返回登录页
const goToLogin = () => {
  uni.navigateBack()
}

onLoad((params) => {
  // 加载主题设置
  themeStore.loadTheme()
  // 计算导航栏高度（状态栏 + 导航栏）
  const systemInfo = uni.getSystemInfoSync()
  navbarHeight.value = (systemInfo.statusBarHeight || 0) + 44
})

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.register-page {
  width: 100%;
  min-height: 100vh;
  position: relative;
  overflow: hidden;
  // 背景色由动态绑定
}

/* 环境光背景 */
.ambient-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  background: 
    radial-gradient(circle at 20% 20%, hsla(200, 80%, 50%, 0.15), transparent 40%),
    radial-gradient(circle at 80% 80%, hsla(280, 60%, 40%, 0.1), transparent 40%);
}

/* 滚动区域 */
.scroll-content {
  height: 100vh;
  // padding-top 由动态绑定
}

.page-content {
  padding: 80rpx 48rpx 80rpx;
}

/* 表单组 */
.form-group {
  margin-bottom: 32rpx;
}

.form-label {
  display: block;
  font-size: 26rpx;
  margin-bottom: 16rpx;
  // 颜色由动态绑定
}

.input-with-icon {
  position: relative;
  display: flex;
  align-items: center;
  border-radius: 28rpx;
  overflow: hidden;
  transition: all 0.3s ease;
  // 背景色由动态绑定
}

.icon {
  position: absolute;
  left: 32rpx;
  font-size: 32rpx;
  z-index: 2;
  // 颜色由动态绑定
}

.input-field {
  width: 100%;
  height: 96rpx;
  padding: 0 32rpx;
  border-radius: 28rpx;
  font-size: 30rpx;
  border: none;
  outline: none;
  background: transparent;
  transition: all 0.3s ease;
  // 颜色由动态绑定
}

.input-with-icon .input-field {
  padding-left: 76rpx;
}

/* 选择器字段 */
.picker-field {
  flex: 1;
  height: 96rpx;
  display: flex;
  align-items: center;
  padding: 0 32rpx 0 76rpx;
  font-size: 30rpx;
  // 颜色由动态绑定
}

.picker-arrow {
  position: absolute;
  right: 32rpx;
  font-size: 24rpx;
  transition: transform 0.3s ease;
  // 颜色由动态绑定
}

/* 验证码行 */
.verify-row {
  display: flex;
  gap: 24rpx;
  align-items: center;
}

.verify-input {
  flex: 1;
}

/* 次要按钮 */
.btn-secondary {
  height: 96rpx;
  padding: 0 32rpx;
  border-radius: 28rpx;
  font-size: 28rpx;
  font-weight: 500;
  border: 2rpx solid;
  white-space: nowrap;
  transition: all 0.3s ease;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
  // 背景色、颜色、边框色由动态绑定
}

.btn-secondary:active:not(:disabled) {
  transform: scale(0.98);
}

.btn-secondary:disabled {
  opacity: 0.5;
}

/* 协议同意 */
.agreement {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  margin-bottom: 48rpx;
  line-height: 1.6;
  gap: 8rpx;
}

.agreement-text {
  font-size: 24rpx;
  // 颜色由动态绑定
}

.link-text-inline {
  font-weight: 600;
  font-size: 24rpx;
  // 颜色由动态绑定
}

/* 主按钮 */
.btn-primary {
  width: 100%;
  height: 96rpx;
  background: linear-gradient(135deg, #38bdf8 0%, #3b82f6 100%);
  border-radius: 28rpx;
  border: none;
  font-size: 32rpx;
  font-weight: 600;
  color: white;
  transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
  margin-bottom: 48rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
  // 阴影由动态绑定
}

.btn-primary:active {
  transform: scale(0.98);
}

/* 注册链接 */
.register-link {
  text-align: center;
  font-size: 28rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
}

.register-text {
  display: inline-flex;
  align-items: center;
  line-height: 1;
  // 颜色由动态绑定
}

.link-text {
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  line-height: 1;
  // 颜色由动态绑定
}

/* uview 组件主题样式 */
:deep(.u-popup__content) {
  background: v-bind(actionSheetBg) !important;
  border-radius: 28rpx 28rpx 0 0 !important;
}

:deep(.u-action-sheet) {
  background: v-bind(actionSheetBg) !important;
}

:deep(.u-action-sheet__header__title) {
  color: v-bind(actionSheetTitleColor) !important;
  font-weight: 600;
}

:deep(.u-action-sheet__header__icon-wrap) {
  background: v-bind(actionSheetCloseBg) !important;
  border-radius: 50%;
  width: 48rpx;
  height: 48rpx;
  display: flex;
  align-items: center;
  justify-content: center;
}

:deep(.u-action-sheet__item-wrap__item__name) {
  color: v-bind(actionSheetItemColor) !important;
  font-size: 32rpx;
}

:deep(.u-action-sheet__cancel-text) {
  color: v-bind(actionSheetCancelColor) !important;
  font-size: 32rpx;
}

:deep(.u-action-sheet__item-wrap__item) {
  background: v-bind(actionSheetBg) !important;
  padding: 32rpx;
}

:deep(.u-action-sheet--hover) {
  background: v-bind(actionSheetHoverBg) !important;
}

:deep(.u-line) {
  border-color: v-bind(actionSheetLineColor) !important;
}

:deep(.u-gap) {
  background: v-bind(actionSheetGapBg) !important;
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
