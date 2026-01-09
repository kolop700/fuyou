<template>
  <view class="register-container" :class="{ 'dark-mode': isDarkMode }">
    <view class="ambient-bg"></view>
    
    <!-- 导航头部 -->
    <view class="nav-header">
      <view class="nav-back" @click="goToLogin">
        <text class="iconfont icon-arrow-left"></text>
      </view>
      <text class="nav-title">注册账号</text>
      <view class="nav-action"></view>
    </view>
    
    <scroll-view scroll-y class="scroll-content">
      <view class="register-content">
        <!-- 步骤指示 -->
        <view class="step-indicator">
          <view class="step-bar active"></view>
          <view class="step-bar"></view>
          <view class="step-bar"></view>
        </view>
        
        <text class="page-title">验证手机号</text>
        <text class="page-subtitle">我们将发送验证码到您的手机</text>

        <!-- 表单 -->
        <view class="form-group">
          <text class="form-label">手机号码</text>
          <view class="input-with-icon">
            <text class="iconfont icon-mobile-alt input-icon"></text>
            <input 
              v-model="form.phone" 
              type="text" 
              class="input-field" 
              placeholder="请输入11位手机号"
              :maxlength="11"
            />
          </view>
        </view>

        <view class="form-group">
          <text class="form-label">验证码</text>
          <view class="verify-row">
            <input 
              v-model="form.code" 
              type="text" 
              class="input-field" 
              placeholder="请输入验证码"
              :maxlength="6"
              style="flex: 1;"
            />
            <button 
              class="btn-secondary" 
              :disabled="counting" 
              @click="getCode"
            >
              {{ counting ? `${counter}s` : '获取验证码' }}
            </button>
          </view>
        </view>

        <view class="form-group">
          <text class="form-label">设置密码</text>
          <view class="input-with-icon">
            <text class="iconfont icon-fa-lock input-icon"></text>
            <input 
              v-model="form.password" 
              :type="showPassword ? 'text' : 'password'" 
              class="input-field" 
              placeholder="请设置6-16位密码"
            />
          </view>
        </view>

        <view class="form-group">
          <text class="form-label">确认密码</text>
          <view class="input-with-icon">
            <text class="iconfont icon-fa-lock input-icon"></text>
            <input 
              v-model="form.confirmPassword" 
              :type="showConfirmPassword ? 'text' : 'password'" 
              class="input-field" 
              placeholder="请再次输入密码"
            />
          </view>
        </view>

        <!-- 协议同意 -->
        <view class="agreement">
          <checkbox 
            :checked="checked" 
            @click="toggleCheck" 
            color="#38bdf8" 
            style="transform:scale(0.8); margin-right: 20rpx;"
          />
          <text class="agreement-text">我已阅读并同意 </text>
          <text class="link-text-inline" @click="openUserAgreement">《用户协议》</text>
          <text class="agreement-text"> 和 </text>
          <text class="link-text-inline" @click="openPrivacyPolicy">《隐私政策》</text>
        </view>

        <!-- 按钮 -->
        <button class="btn-primary" @click="handleSubmit">下一步</button>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed, getCurrentInstance } from 'vue'
import { onLoad } from "@dcloudio/uni-app"

const { proxy } = getCurrentInstance()

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
const counting = ref(false)
const counter = ref(60)
const checked = ref(false)
const savedVerifyCode = ref('')
const savedPhone = ref('')
const isDarkMode = ref(false)

// 检测系统主题
const checkTheme = () => {
  // #ifdef APP-PLUS
  const systemInfo = uni.getSystemInfoSync()
  isDarkMode.value = systemInfo.theme === 'dark'
  // #endif
  // #ifdef H5
  isDarkMode.value = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
  // #endif
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

// 生成6位随机验证码
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

// 性别选择改变

// 提交表单
const handleSubmit = async () => {
  if (!checked.value) {
    uni.showToast({ title: '请先同意用户协议和隐私政策', icon: 'none' })
    return
  }
  
  // 验证手机号
  if (!form.value.phone) {
    uni.showToast({ title: '请输入手机号', icon: 'none' })
    return
  }
  if (!/^1[3-9]\d{9}$/.test(form.value.phone)) {
    uni.showToast({ title: '手机号格式不正确', icon: 'none' })
    return
  }
  if (!form.value.code) {
    uni.showToast({ title: '请输入验证码', icon: 'none' })
    return
  }
  if (!form.value.password) {
    uni.showToast({ title: '请输入密码', icon: 'none' })
    return
  }
  if (form.value.password.length < 6) {
    uni.showToast({ title: '密码不能少于6位', icon: 'none' })
    return
  }
  if (form.value.password !== form.value.confirmPassword) {
    uni.showToast({ title: '两次输入的密码不一致', icon: 'none' })
    return
  }
  
  try {
    const res = await proxy.$api.user.UserRegister(form.value)
    if(res.code === "0") {
      uni.showToast({ 
        title: '注册成功，请登录', 
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
  uni.navigateTo({ url: '/user_package/pages/agreement/user' })
}

// 打开隐私政策
const openPrivacyPolicy = () => {
  uni.navigateTo({ url: '/user_package/pages/agreement/privacy' })
}

// 返回登录页
const goToLogin = () => {
  uni.navigateBack()
}

onLoad((params) => {
  console.log(params)
  checkTheme()
  
  // 监听主题变化
  // #ifdef H5
  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', checkTheme)
  }
  // #endif
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

/* 深色模式变量 */
.register-container {
  --color-dominant: hsl(220, 25%, 12%);
  --color-support: hsl(220, 15%, 96%);
  --color-accent: hsl(200, 85%, 55%);
  --color-text-secondary: hsl(220, 15%, 65%);
  --color-glass: rgba(255, 255, 255, 0.08);
  --color-glass-border: rgba(255, 255, 255, 0.12);
  
  height: 100vh;
  background: linear-gradient(135deg, #0a0f1a 0%, #141c2e 50%, #0d1520 100%);
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  position: relative;
  overflow: hidden;
}

/* 浅色模式 */
.register-container:not(.dark-mode) {
  --color-dominant: hsl(220, 20%, 97%);
  --color-support: hsl(220, 25%, 20%);
  --color-accent: hsl(210, 100%, 50%);
  --color-text-secondary: hsl(220, 10%, 55%);
  --color-glass: rgba(255, 255, 255, 0.8);
  --color-glass-border: rgba(0, 0, 0, 0.06);
  --color-card: hsl(0, 0%, 100%);
  --color-divider: hsl(220, 15%, 92%);
  
  background: linear-gradient(135deg, #e8ecf4 0%, #f5f7fa 50%, #eef1f5 100%);
}

/* 环境光背景 */
.ambient-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
}

.dark-mode .ambient-bg {
  background: 
    radial-gradient(circle at 20% 20%, hsla(200, 80%, 50%, 0.15), transparent 40%),
    radial-gradient(circle at 80% 80%, hsla(280, 60%, 40%, 0.1), transparent 40%);
}

.register-container:not(.dark-mode) .ambient-bg {
  background: 
    radial-gradient(circle at 20% 20%, hsla(210, 100%, 70%, 0.08), transparent 40%),
    radial-gradient(circle at 80% 80%, hsla(280, 80%, 70%, 0.05), transparent 40%);
}

/* 导航头部 */
.nav-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20rpx 48rpx 40rpx;
  position: relative;
  z-index: 100;
}

.nav-back {
  width: 80rpx;
  height: 80rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 24rpx;
  cursor: pointer;
  transition: all 0.3s ease;
  
  .iconfont {
    font-size: 32rpx;
    color: var(--color-support);
  }
}

.dark-mode .nav-back {
  background: var(--color-glass);
  
  &:active {
    background: rgba(255,255,255,0.12);
  }
}

.register-container:not(.dark-mode) .nav-back {
  background: var(--color-card);
  box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.06);
  
  &:active {
    background: var(--color-divider);
  }
}

.nav-title {
  font-size: 34rpx;
  font-weight: 600;
  color: var(--color-support);
}

.nav-action {
  width: 80rpx;
  height: 80rpx;
}

/* 滚动区域 */
.scroll-content {
  flex: 1;
  position: relative;
  z-index: 10;
}

.register-content {
  padding: 0 48rpx 80rpx;
}

/* 步骤指示 */
.step-indicator {
  display: flex;
  justify-content: center;
  gap: 16rpx;
  margin-bottom: 80rpx;
}

.step-bar {
  width: 64rpx;
  height: 8rpx;
  border-radius: 4rpx;
  transition: all 0.3s ease;
}

.dark-mode .step-bar {
  background: var(--color-glass);
  
  &.active {
    background: var(--color-accent);
  }
}

.register-container:not(.dark-mode) .step-bar {
  background: var(--color-divider);
  
  &.active {
    background: var(--color-accent);
  }
}

/* 页面标题 */
.page-title {
  display: block;
  font-size: 40rpx;
  font-weight: 600;
  color: var(--color-support);
  margin-bottom: 16rpx;
}

.page-subtitle {
  display: block;
  font-size: 28rpx;
  color: var(--color-text-secondary);
  margin-bottom: 64rpx;
}

/* 表单组 */
.form-group {
  margin-bottom: 32rpx;
}

.form-label {
  display: block;
  font-size: 26rpx;
  color: var(--color-text-secondary);
  margin-bottom: 16rpx;
}

.input-with-icon {
  position: relative;
  display: flex;
  align-items: center;
}

.input-icon {
  position: absolute;
  left: 32rpx;
  font-size: 32rpx;
  color: var(--color-text-secondary);
  z-index: 2;
}

.input-field {
  width: 100%;
  padding: 32rpx;
  border-radius: 28rpx;
  font-size: 30rpx;
  color: var(--color-support);
  border: none;
  outline: none;
  transition: all 0.3s ease;
}

.input-with-icon .input-field {
  padding-left: 76rpx;
}

.dark-mode .input-field {
  background: rgba(255,255,255,0.06);
  
  &::placeholder {
    color: var(--color-text-secondary);
  }
  
  &:focus {
    background: rgba(255,255,255,0.1);
    box-shadow: 0 0 0 4rpx rgba(56, 189, 248, 0.3);
  }
}

.register-container:not(.dark-mode) .input-field {
  background: var(--color-divider);
  
  &::placeholder {
    color: var(--color-text-secondary);
  }
  
  &:focus {
    background: white;
    box-shadow: 0 0 0 4rpx rgba(59, 130, 246, 0.3);
  }
}

/* 验证码行 */
.verify-row {
  display: flex;
  gap: 24rpx;
}

/* 次要按钮 */
.btn-secondary {
  padding: 28rpx 40rpx;
  border-radius: 28rpx;
  font-size: 28rpx;
  font-weight: 500;
  color: var(--color-support);
  border: none;
  white-space: nowrap;
  transition: all 0.3s ease;
}

.dark-mode .btn-secondary {
  background: var(--color-glass);
  border: 2rpx solid var(--color-glass-border);
  
  &:active:not(:disabled) {
    background: rgba(255,255,255,0.12);
  }
  
  &:disabled {
    opacity: 0.5;
  }
}

.register-container:not(.dark-mode) .btn-secondary {
  background: var(--color-divider);
  border: 2rpx solid var(--color-glass-border);
  
  &:active:not(:disabled) {
    background: #e5e9f0;
  }
  
  &:disabled {
    opacity: 0.5;
  }
}

/* 协议同意 */
.agreement {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  margin-bottom: 48rpx;
  line-height: 1.6;
}

.agreement-text {
  color: var(--color-text-secondary);
  font-size: 24rpx;
}

.link-text-inline {
  color: var(--color-accent);
  font-weight: 600;
  font-size: 24rpx;
}

/* 主按钮 */
.btn-primary {
  width: 100%;
  padding: 32rpx;
  border-radius: 28rpx;
  font-size: 32rpx;
  font-weight: 600;
  color: white;
  border: none;
  background: linear-gradient(135deg, var(--color-accent) 0%, hsl(210, 85%, 50%) 100%);
  transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
}

.dark-mode .btn-primary {
  box-shadow: 0 20rpx 60rpx -20rpx rgba(56, 189, 248, 0.5);
  
  &:active {
    transform: scale(0.98);
  }
}

.register-container:not(.dark-mode) .btn-primary {
  box-shadow: 0 16rpx 48rpx -16rpx rgba(59, 130, 246, 0.5);
  
  &:active {
    transform: scale(0.98);
  }
}
</style>