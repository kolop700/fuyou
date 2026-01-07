<template>
  <view class="register-container">
    <view class="register-content">
      <!-- Form Card -->
      <view class="form-card">
        <text class="form-title">注册账户</text>
        <text class="form-subtitle">创建您的账户开始使用</text>

        <view class="input-group">
          <text class="input-label">手机号</text>
          <u-input
            v-model="form.phone"
            type="text"
            placeholder="请输入手机号"
            :maxlength="11"
            :border="false"
            :customStyle="inputStyle"
            shape="round"
          >
            <template #suffix>
              <text class="iconfont icon-mobile-alt" style="color: #94a3b8; font-size: 36rpx;"></text>
            </template>
          </u-input>
        </view>

        <view class="input-group">
          <text class="input-label">验证码</text>
          <view class="verify-code-wrapper">
            <u-input
              v-model="form.code"
              type="text"
              placeholder="请输入验证码"
              :maxlength="6"
              :border="false"
              :customStyle="inputStyle"
              shape="round"
              style="flex: 1; margin-right: 16rpx;"
            />
            <u-button
              :text="counting ? `${counter}s` : '发送验证码'"
              type="primary"
              size="small"
              :plain="false"
              shape="round"
              :disabled="counting"
              :customStyle="codeButtonStyle"
              @click="getCode"
            ></u-button>
          </view>
        </view>

        <view class="input-group">
          <text class="input-label">姓名</text>
          <u-input
            v-model="form.name"
            type="text"
            placeholder="请输入姓名"
            :border="false"
            :customStyle="inputStyle"
            shape="round"
          >
            <template #suffix>
              <text class="iconfont icon-fa-user-circle-o" style="color: #94a3b8; font-size: 36rpx;"></text>
            </template>
          </u-input>
        </view>

        <view class="input-group">
          <text class="input-label">密码</text>
          <u-input
            v-model="form.password"
            :type="showPassword ? 'text' : 'password'"
            placeholder="请输入密码"
            :border="false"
            :customStyle="inputStyle"
            shape="round"
          >
            <template #suffix>
              <view @click="togglePasswordVisibility" style="padding: 0 10rpx;">
                <text 
                  class="iconfont" 
                  :class="showPassword ? 'icon-a-fasfa-eye' : 'icon-fa-eye-close'"
                  style="color: #94a3b8; font-size: 36rpx;"
                ></text>
              </view>
            </template>
          </u-input>
        </view>

        <view class="input-group">
          <text class="input-label">确认密码</text>
          <u-input
            v-model="form.confirmPassword"
            :type="showConfirmPassword ? 'text' : 'password'"
            placeholder="请再次输入密码"
            :border="false"
            :customStyle="inputStyle"
            shape="round"
          >
            <template #suffix>
              <view @click="toggleConfirmPasswordVisibility" style="padding: 0 10rpx;">
                <text 
                  class="iconfont" 
                  :class="showConfirmPassword ? 'icon-a-fasfa-eye' : 'icon-fa-eye-close'"
                  style="color: #94a3b8; font-size: 36rpx;"
                ></text>
              </view>
            </template>
          </u-input>
        </view>

        <view class="input-group">
          <text class="input-label">性别</text>
          <picker 
            @change="onGenderChange" 
            :value="genderIndex >= 0 ? genderIndex : 0" 
            :range="genderColumns"
          >
            <view class="picker-wrapper">
              <u-input
                :modelValue="form.gender || '请选择性别'"
                type="text"
                placeholder="请选择性别"
                :border="false"
                :customStyle="inputStyle"
                shape="round"
                :disabled="true"
              >
                <template #suffix>
                  <text class="iconfont icon-fasfa-chevron-rightCopy" style="color: #94a3b8; font-size: 36rpx;"></text>
                </template>
              </u-input>
            </view>
          </picker>
        </view>

        <!-- 协议同意 -->
        <view class="agreement">
          <checkbox-group @change="onCheckboxChange">
            <checkbox 
              value="agree"
              :checked="checked" 
              color="#667eea"
              style="transform:scale(0.75); margin-right: 8rpx;"
            />
          </checkbox-group>
          <text class="agreement-text">我已阅读并同意</text>
          <text class="link-text-inline" @click="openUserAgreement">《用户协议》</text>
          <text class="agreement-text-inline">和</text>
          <text class="link-text-inline" @click="openPrivacyPolicy">《隐私政策》</text>
        </view>

        <!-- 提交按钮 -->
        <view class="btn-wrapper">
          <u-button
            text="提交"
            type="primary"
            size="normal"
            :plain="false"
            shape="round"
            :disabled="!isFormValid"
            :customStyle="buttonStyle"
            @click="handleSubmit"
          ></u-button>
        </view>

        <!-- 返回登录 -->
        <view class="register-link">
          <text class="register-text">已有账户？</text>
          <text class="link-text" @click="goToLogin">返回登录</text>
        </view>
      </view>
    </view>
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

const genderColumns = ['男', '女', '未知']
const genderIndex = ref(-1)
const showPassword = ref(false)
const showConfirmPassword = ref(false)
const counting = ref(false)
const counter = ref(60)
const checked = ref(false)
const savedVerifyCode = ref('')
const savedPhone = ref('')

// 输入框样式
const inputStyle = {
  border: '4rpx solid #e2e8f0',
  borderRadius: '20rpx',
  padding: '24rpx 28rpx',
  backgroundColor: '#fff',
  fontSize: '28rpx'
}

// 按钮样式
const buttonStyle = {
  width: '100%',
  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
}

// 验证码按钮样式
const codeButtonStyle = {
  width: 'auto',
  minWidth: '140rpx',
  padding: '0 20rpx',
  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
}

// 切换密码显示/隐藏
const togglePasswordVisibility = () => {
  showPassword.value = !showPassword.value
}

// 切换确认密码显示/隐藏
const toggleConfirmPasswordVisibility = () => {
  showConfirmPassword.value = !showConfirmPassword.value
}

// 计算属性判断表单是否有效
const isFormValid = computed(() => {
  return form.value.phone && 
         form.value.code && 
         form.value.name && 
         form.value.password && 
         form.value.confirmPassword && 
         checked.value
})

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
  if (form.value.code !== savedVerifyCode.value) {
    uni.showToast({ title: '验证码错误', icon: 'none' })
    return false
  }
  return true
}

// 性别选择改变
const onGenderChange = (e) => {
  const index = e.detail.value
  genderIndex.value = index
  form.value.gender = genderColumns[index]
  console.log('性别选择:', form.value.gender, '索引:', index)
}

// 协议勾选改变
const onCheckboxChange = (e) => {
  checked.value = e.detail.value.includes('agree')
}

// 提交表单
const handleSubmit = async () => {
  if (!checked.value) {
    uni.showToast({ title: '请先同意用户协议和隐私政策', icon: 'none' })
    return
  }
  
  if (validateForm()) {
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
})
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.register-container {
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0 60rpx 20rpx;
  box-sizing: border-box;
  overflow-y: auto;
}

.register-content {
  width: 100%;
  max-width: 750rpx;
  padding: 20rpx 0;
}

.form-card {
  background: white;
  border-radius: 40rpx;
  padding: 36rpx 32rpx;
  width: 100%;
  box-shadow: 0 40rpx 80rpx rgba(0, 0, 0, 0.15);
  box-sizing: border-box;
}

.form-title {
  display: block;
  font-size: 40rpx;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 8rpx;
}

.form-subtitle {
  display: block;
  font-size: 24rpx;
  color: #64748b;
  margin-bottom: 24rpx;
}

.input-group {
  margin-bottom: 24rpx;
}

.input-label {
  display: block;
  font-size: 24rpx;
  font-weight: 600;
  color: #64748b;
  margin-bottom: 12rpx;
}

.verify-code-wrapper {
  display: flex;
  align-items: center;
}


.picker-wrapper {
  width: 100%;
}

.forgot-password-wrapper {
  text-align: right;
  margin-bottom: 20rpx;
}

.agreement {
  display: flex;
  align-items: center;
  flex-wrap: nowrap;
  margin-bottom: 24rpx;
  font-size: 22rpx;
  line-height: 1.4;
  white-space: nowrap;
}

.agreement-text {
  color: #64748b;
  font-size: 22rpx;
  white-space: nowrap;
}

.agreement-text-inline {
  color: #64748b;
  font-size: 22rpx;
  white-space: nowrap;
  margin: 0 4rpx;
}

.link-text-inline {
  color: #667eea;
  font-weight: 600;
  font-size: 22rpx;
  white-space: nowrap;
  margin: 0 2rpx;
}

.link-text {
  color: #667eea;
  font-weight: 600;
  font-size: 26rpx;
}

.btn-wrapper {
  margin-bottom: 20rpx;
}

.register-link {
  text-align: center;
  font-size: 24rpx;
  color: #64748b;
  margin-top: 0;
}

.register-text {
  color: #64748b;
}
</style>