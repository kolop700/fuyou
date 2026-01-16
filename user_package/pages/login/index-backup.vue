<template>
  <view class="login-container" :class="{ 'dark-mode': isDarkMode }">
    <view class="ambient-bg"></view>
    
    <!-- 自定义导航栏 -->
    <view class="custom-navbar">
      <view class="status-bar" :style="{ height: statusBarHeight + 'px' }"></view>
      <view class="nav-content">
        <view class="nav-title">登录</view>
      </view>
    </view>
    
    <scroll-view scroll-y class="scroll-content">
      <view class="login-content">
      <!-- Logo图标 -->
      <view class="logo-section">
        <view class="logo-box">
          <text class="iconfont icon-fa-building"></text>
        </view>
        <text class="welcome-title">欢迎回来</text>
        <text class="welcome-subtitle">登录您的福优智家账户</text>
      </view>

      <!-- 表单 -->
      <view class="form-group">
        <view class="input-with-icon">
          <text class="iconfont icon-mobile-alt input-icon"></text>
          <input 
            v-model="form.user_account" 
            type="text" 
            class="input-field" 
            placeholder="请输入手机号"
            :maxlength="11"
          />
        </view>
      </view>

      <view class="form-group">
        <view class="input-with-icon">
          <text class="iconfont icon-fa-lock input-icon"></text>
          <input 
            v-model="form.password" 
            :type="showPassword ? 'text' : 'password'" 
            class="input-field" 
            placeholder="请输入密码"
          />
        </view>
      </view>

      <!-- 记住密码和忘记密码 -->
      <view class="options-row">
        <label class="remember-label" @click="toggleRemember">
          <checkbox :checked="remember" color="#38bdf8" style="transform:scale(0.8);" />
          <text class="remember-text">记住密码</text>
        </label>
        <text class="link-text" @click="goToForgotPassword">忘记密码?</text>
      </view>

      <!-- 登录按钮 -->
      <button class="btn-primary" @click="handleLogin">登 录</button>

      <!-- 其他方式登录 -->
      <view class="divider">
        <view class="divider-line"></view>
        <text class="divider-text">其他方式登录</text>
        <view class="divider-line"></view>
      </view>

      <view class="social-login">
        <view class="social-btn wechat">
          <text class="iconfont icon-a-fabfa-weixin"></text>
        </view>
        <view class="social-btn alipay">
          <text class="iconfont icon-f-alipay"></text>
        </view>
        <view class="social-btn apple">
          <text class="iconfont icon-f-apple"></text>
        </view>
      </view>

      <!-- 注册链接 -->
      <view class="register-link">
        <text class="register-text">还没有账号? </text>
        <text class="link-text" @click="goToRegister">立即注册</text>
      </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, getCurrentInstance } from 'vue'
import { onLoad } from "@dcloudio/uni-app"

const { proxy } = getCurrentInstance()
const form = ref({
  user_account: '',
  password: ''
})
const showPassword = ref(false)
const remember = ref(false)
const isDarkMode = ref(false)
const msgType = ref('')
const messageText = ref('')
const message = ref(null)
const statusBarHeight = ref(0)

// 获取状态栏高度
const getStatusBarHeight = () => {
  const systemInfo = uni.getSystemInfoSync()
  statusBarHeight.value = systemInfo.statusBarHeight || 0
}

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

// 切换记住密码
const toggleRemember = () => {
  remember.value = !remember.value
}



// 切换密码显示/隐藏
const togglePasswordVisibility = () => {
  showPassword.value = !showPassword.value
}

const handleLogin = async () => {

  // 手机号验证
  if (!form.value.user_account) {
    uni.showToast({
      title: '请输入手机号',
      icon: 'none',
      duration: 2000
    })
    return
  }

  if (!/^1[3-9]\d{9}$/.test(form.value.user_account)) {
    uni.showToast({
      title: '请输入正确的手机号',
      icon: 'none',
      duration: 2000
    })
    return
  }

  if (!form.value.password) {
    uni.showToast({
      title: '请输入密码',
      icon: 'none',
      duration: 2000
    })
    return
  }

  if (form.value.password.length < 6) {
    uni.showToast({
      title: '密码长度至少6位',
      icon: 'none',
      duration: 2000
    })
    return
  }

  try {
    const loginData = {
      app_phone_mac: "0",
      app_login_type: "2",
      user_acct: form.value.user_account,
      user_password: form.value.password
    }
    console.log(loginData)
    const res = await proxy.$api.user.UserLogin(loginData)
    console.log(res)
    if (res.code === "0") {
      // 先保存用户信息到pinia store（这样才能确保登录状态更新）
      const userData = res.data[0]
      await proxy.$store.user.useUserStore().loginSuccess(userData)
      
      // 显示成功提示
      uni.showToast({
        title: '登录成功',
        icon: 'success',
        duration: 1500
      })
      
      // 延迟跳转到首页，使用 reLaunch 清除页面栈，避免重复跳转
      setTimeout(() => {
        uni.reLaunch({
          url: '/pages/index/index'
        })
      }, 1500)
    } else {
      uni.showToast({
        title: res.msg || '登录失败',
        icon: 'none'
      })
    }
  } catch (error) {
    uni.showToast({
      title: '登录失败，请检查账号密码是否正确',
      icon: 'none'
    })
    console.error('登录错误:', error)
  }
}

const goToRegister = () => {
  uni.navigateTo({
    url: '../register/index'
  })
}

const goToForgotPassword = () => {
  uni.navigateTo({
    url: '../forgot-password/index'
  })
}

onLoad((params) => {
  console.log(params)
  getStatusBarHeight()
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
.login-container {
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
.login-container:not(.dark-mode) {
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

.login-container:not(.dark-mode) .ambient-bg {
  background: 
    radial-gradient(circle at 20% 20%, hsla(210, 100%, 70%, 0.08), transparent 40%),
    radial-gradient(circle at 80% 80%, hsla(280, 80%, 70%, 0.05), transparent 40%);
}

/* 自定义导航栏 */
.custom-navbar {
  position: relative;
  z-index: 100;
}

.status-bar {
  width: 100%;
}

.nav-content {
  height: 88rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 32rpx;
}

.nav-title {
  font-size: 34rpx;
  font-weight: 600;
  color: var(--color-support);
}

/* 滚动内容区 */
.scroll-content {
  flex: 1;
  position: relative;
  z-index: 10;
}

.login-content {
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 0 48rpx 80rpx;
  min-height: calc(100vh - var(--nav-height, 200rpx));
  position: relative;
  z-index: 10;
}

/* Logo区域 */
.logo-section {
  text-align: center;
  margin-bottom: 80rpx;
}

.logo-box {
  width: 160rpx;
  height: 160rpx;
  margin: 0 auto 40rpx;
  border-radius: 48rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, var(--color-accent) 0%, hsl(210, 85%, 50%) 100%);
  box-shadow: 0 40rpx 80rpx -20rpx rgba(56, 189, 248, 0.5);
  
  .iconfont {
    font-size: 72rpx;
    color: white;
  }
}

.login-container:not(.dark-mode) .logo-box {
  box-shadow: 0 24rpx 64rpx -16rpx rgba(59, 130, 246, 0.4);
}

.welcome-title {
  display: block;
  font-size: 48rpx;
  font-weight: 700;
  color: var(--color-support);
  margin-bottom: 16rpx;
  letter-spacing: -0.02em;
}

.welcome-subtitle {
  display: block;
  font-size: 28rpx;
  color: var(--color-text-secondary);
}

/* 表单组 */
.form-group {
  margin-bottom: 32rpx;
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
  padding: 32rpx 32rpx 32rpx 76rpx;
  border-radius: 28rpx;
  font-size: 30rpx;
  color: var(--color-support);
  border: none;
  outline: none;
  transition: all 0.3s ease;
  -webkit-appearance: none;
}

.dark-mode .input-field {
  background: rgba(255,255,255,0.08);
  
  &::placeholder {
    color: rgba(255, 255, 255, 0.4);
  }
  
  &:focus {
    background: rgba(255,255,255,0.12);
    box-shadow: 0 0 0 4rpx rgba(56, 189, 248, 0.25);
  }
}

.login-container:not(.dark-mode) .input-field {
  background: #f1f5f9;
  
  &::placeholder {
    color: #94a3b8;
  }
  
  &:focus {
    background: white;
    box-shadow: 0 0 0 4rpx rgba(59, 130, 246, 0.2);
  }
}
/* 选项行 */
.options-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 64rpx;
}

.remember-label {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.remember-text {
  font-size: 26rpx;
  color: var(--color-text-secondary);
}

.link-text {
  color: var(--color-accent);
  font-weight: 600;
  font-size: 26rpx;
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
  margin-bottom: 48rpx;
}

.dark-mode .btn-primary {
  box-shadow: 0 20rpx 60rpx -20rpx rgba(56, 189, 248, 0.5);
  
  &:active {
    transform: scale(0.98);
  }
}

.login-container:not(.dark-mode) .btn-primary {
  box-shadow: 0 16rpx 48rpx -16rpx rgba(59, 130, 246, 0.5);
  
  &:active {
    transform: scale(0.98);
  }
}

/* 分割线 */
.divider {
  display: flex;
  align-items: center;
  gap: 32rpx;
  margin-bottom: 48rpx;
}

.divider-line {
  flex: 1;
  height: 2rpx;
}

.dark-mode .divider-line {
  background: var(--color-glass-border);
}

.login-container:not(.dark-mode) .divider-line {
  background: var(--color-divider);
}

.divider-text {
  font-size: 26rpx;
  color: var(--color-text-secondary);
}

/* 社交登录 */
.social-login {
  display: flex;
  justify-content: center;
  gap: 40rpx;
  margin-bottom: 64rpx;
}

.social-btn {
  width: 112rpx;
  height: 112rpx;
  border-radius: 32rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  
  .iconfont {
    font-size: 48rpx;
  }
  
  &:active {
    transform: translateY(-4rpx);
  }
}

.dark-mode .social-btn {
  background: var(--color-glass);
  border: 2rpx solid var(--color-glass-border);
}

.login-container:not(.dark-mode) .social-btn {
  background: var(--color-card);
  border: 2rpx solid var(--color-glass-border);
  box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.04);
  
  &:active {
    background: white;
    box-shadow: 0 16rpx 40rpx rgba(0,0,0,0.1);
  }
}

.social-btn.wechat .iconfont { color: #07C160; }
.social-btn.alipay .iconfont { color: #1677FF; }

.dark-mode .social-btn.apple .iconfont { color: white; }
.login-container:not(.dark-mode) .social-btn.apple .iconfont { color: #333; }

/* 注册链接 */
.register-link {
  text-align: center;
  font-size: 28rpx;
}

.register-text {
  color: var(--color-text-secondary);
}
</style>