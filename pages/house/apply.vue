<template>
    <view class="container">
      <!-- 表单区域 -->
      <view class="form-section">
        <form @submit="submitForm">
          <view class="input-container">
            <!-- 楼宇地址输入 -->
            <view class="cu-form-group custom-input">
              <view class="input-wrap">
                <input 
                  v-model="formData.building"
                  placeholder="输入楼宇地址"
                  @input="inputChange"
                  data-field="building"
                  class="ellipsis-input"
                />
              </view>
              <view class="icon-group">
                <view class="btn-wrap" @tap.stop="scanQRCode">
                  <button class="action-btn scan-btn">扫一扫</button>
                </view>
                <view class="btn-wrap" @tap.stop="showBuildingSearch">
                  <button class="action-btn search-btn">搜索</button>
                </view>
              </view>
            </view>
            
            <!-- 房号选择 -->
            <view class="cu-form-group custom-input room-select" @click.stop="selectRoom">
              <input 
                v-model="formData.room"
                placeholder="选择房号"
                data-field="room"
                disabled
              />
              <uni-icons class="arrow-icon" type="bottom" size="16" color="#999999"></uni-icons>
            </view>
          </view>
    
          <!-- 提交按钮 -->
          <view class="button-container">
            <button 
              class="cu-btn bg-gray cancel-button"
              @click="handleCancel"
            >稍后申请</button>
            <button 
              class="cu-btn bg-red login-button"
              :class="{'secondary': !isFormValid}"
              @click="submitForm"
              type="submit"
            >提交申请</button>
          </view>
        </form>
      </view>
     
      <!-- 说明卡片 -->
      <view class="info-section">
        <view class="info-card">
          <view class="info-header">
            <view class="info-icon">
              <text class="iconfont icon-info-circle" style="color: #667eea; font-size: 40rpx;"></text>
            </view>
            <text class="info-title">认证说明</text>
          </view>
          <view class="info-content">
            <view class="info-step">
              <view class="step-number">1</view>
              <text class="step-text">输入楼宇地址或使用扫一扫功能</text>
            </view>
            <view class="info-step">
              <view class="step-number">2</view>
              <text class="step-text">选择对应的房号</text>
            </view>
            <view class="info-step">
              <view class="step-number">3</view>
              <text class="step-text">提交申请等待审核</text>
            </view>
          </view>
        </view>
        
        <view class="tip-card">
          <text class="iconfont icon-question-circle-fill" style="color: #ff9500; font-size: 32rpx; margin-right: 16rpx;"></text>
          <text class="tip-text">认证成功后，可在"房屋"页面查看已认证房屋</text>
        </view>
      </view>
    
      <!-- 弹框部分 -->
      <uni-popup ref="buildingPopup" type="center">
        <view class="modal-content">
          <view class="modal-header">
            <text class="header-text">选择楼宇地址</text>
            <text class="close-icon" @click="hideDialog">×</text>
          </view>
          <scroll-view class="modal-body" scroll-y>
            <view 
              v-for="(item, index) in searchResults" 
              :key="item.unit_id"
              class="device-option"
              @click="selectDialogBuilding(item)"
            >
              {{item.unitname}}
            </view>
          </scroll-view>
        </view>
      </uni-popup>
    
      <uni-popup ref="roomPopup" type="center" :animation="true" :maskClick="true">
        <view class="modal-content">
          <view class="modal-header">
            <text class="header-text">选择房号</text>
            <text class="close-icon" @click="hideRoomDialog">×</text>
          </view>
          <scroll-view class="modal-body" scroll-y>
            <view 
              v-for="(item, index) in roomList" 
              :key="item.id"
              class="device-option"
              @click="selectDialogRoom(index)"
              :class="{'selected': item.selected}"
            >
              {{item.floor_name}}{{item.room_name}}
            </view>
          </scroll-view>
        </view>
      </uni-popup>
    
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
import { ref, getCurrentInstance, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import uniIcons from '@/uni_modules/uni-icons/components/uni-icons/uni-icons.vue'
import scanUtils from '@/utils/scanUtils'

const { proxy } = getCurrentInstance()
const userStore = proxy.$store.user.useUserStore()
const deviceApi = proxy.$api.device

// 表单数据
const formData = ref({
  building: '',
  room: ''
})

// 搜索结果
const searchResults = ref([])

// 选中的单元
const selectedUnit = ref(null)

// 房间列表
const roomList = ref([])

onLoad(() => {
  console.log('房屋申请页面加载')
})

// 表单是否有效
const isFormValid = computed(() => {
  return formData.value.building && formData.value.room
})

// 弹窗引用
const buildingPopup = ref(null)
const roomPopup = ref(null)

// 输入变化处理
const inputChange = (e) => {
  const { field } = e.currentTarget.dataset
  formData.value[field] = e.detail.value
  
  // 如果是楼宇地址输入变化，清空房间
  if (field === 'building') {
    formData.value.room = ''
    roomList.value = []
    selectedUnit.value = null
  }
}

// 扫描二维码
const scanQRCode = async () => {
  try {
    const result = await scanUtils.scanQRCode()
    if (result) {
      // 获取单元信息
      const res = await deviceApi.getUnitByQRCode(result)
      if (Array.isArray(res.data) && res.data.length > 0) {
        console.log('单元信息:', res.data)
        const unitInfo = res.data[0]
        
        if (unitInfo.type === '1') {
          // 大门机，显示楼宇选择弹框
          searchResults.value = res.data
          buildingPopup.value.open()
        } else if (unitInfo.type === '2') {
          // 单元机，直接选中单元
          selectedUnit.value = unitInfo
          formData.value.building = unitInfo.unitname
          formData.value.room = ''
          roomList.value = []
          // 加载房间列表
          loadRoomList()
        } else {
          uni.showToast({
            title: '未找到相关单元信息',
            icon: 'none'
          })
        }
      } else {
        uni.showToast({
          title: '未找到相关单元信息',
          icon: 'none'
        })
      }
    }
  } catch (error) {
    console.error('扫码失败:', error)
    uni.showToast({
      title: '扫码失败',
      icon: 'none'
    })
  }
}

// 显示楼宇搜索
const showBuildingSearch = async () => {
  const searchText = formData.value.building.trim()
  if (!searchText) {
    uni.showToast({
      title: '请输入楼宇地址',
      icon: 'none'
    })
    return
  }

  if (searchText.length < 2) {
    uni.showToast({
      title: '请至少输入2个字符',
      icon: 'none'
    })
    return
  }
  
  // 清空房间相关数据
  formData.value.room = ''
  roomList.value = []
  selectedUnit.value = null
  
  try {
    const res = await deviceApi.getUnitList({
      name: searchText
    })
    
    if (Array.isArray(res.data) && res.data.length > 0) {
      searchResults.value = res.data
      buildingPopup.value.open()
    } else {
      uni.showToast({
        title: '未找到相关楼宇',
        icon: 'none'
      })
    }
  } catch (error) {
    console.error('搜索楼宇失败:', error)
    uni.showToast({
      title: '搜索失败',
      icon: 'none'
    })
  }
}

// 隐藏楼宇搜索
const hideDialog = () => {
  buildingPopup.value.close()
}

// 选择房间
const selectRoom = () => {
  if (!formData.value.building) {
    uni.showToast({
      title: '请先选择楼宇',
      icon: 'none'
    })
    return
  }
  roomPopup.value.open()
}

// 隐藏房间选择
const hideRoomDialog = () => {
  roomPopup.value.close()
}

// 选择楼宇
const selectDialogBuilding = (item) => {
  // 清空房间相关数据
  formData.value.room = ''
  roomList.value = []
  
  // 设置新的楼宇信息
  selectedUnit.value = item
  formData.value.building = item.unitname
  hideDialog()
  loadRoomList()
}

// 选择房间
const selectDialogRoom = (index) => {
  const room = roomList.value[index]
  formData.value.room = `${room.floor_name}${room.room_name}`
  hideRoomDialog()
}

// 加载房间列表
const loadRoomList = async () => {
  if (!selectedUnit.value?.unit_id) {
    console.error('未选择单元')
    return
  }
  try {
    const res = await deviceApi.getRoomList(selectedUnit.value.unit_id)
    if (Array.isArray(res.data)) {
      roomList.value = res.data.map(item => ({
        id: item.room_id,
        room_name: item.room_name,
        floor_name: item.floor_name,
        selected: false
      }))
      
      setTimeout(() => {
        roomPopup.value.open()
      }, 100)
    } else {
      uni.showToast({
        title: '获取房间列表失败',
        icon: 'none'
      })
    }
  } catch (error) {
    console.error('获取房间列表失败:', error)
    uni.showToast({
      title: '获取房间列表失败',
      icon: 'none'
    })
  }
}

// 取消申请
const handleCancel = () => {
  uni.navigateBack({
    delta: 1
  })
}

// 提交表单
const submitForm = async () => {
  if (!isFormValid.value) {
    uni.showToast({
      title: '请填写完整信息',
      icon: 'none'
    })
    return
  }
  if (!selectedUnit.value?.unit_id) {
    uni.showToast({
      title: '请选择有效的楼宇',
      icon: 'none'
    })
    return
  }
  // 获取当前选中的房间ID
  const selectedRoom = roomList.value.find(room => 
    `${room.floor_name}${room.room_name}` === formData.value.room
  )
  if (!selectedRoom) {
    uni.showToast({
      title: '请选择有效的房间',
      icon: 'none'
    })
    return
  }
  try {
    const result = await proxy.$api.user.bindUserRoom({
      room_id: selectedRoom.id,
      user_id: userStore.userInfo.user_id,
      auto_author: "0"
    })
    if (result.code === "0") {
      uni.showToast({
        title: '申请成功',
        icon: 'success',
        duration: 1500
      })
      
      // 清空表单
      formData.value.building = ''
      formData.value.room = ''
      selectedUnit.value = null
      roomList.value = []
      
      // 刷新用户房屋列表
      try {
        await userStore.updateRoomList()
      } catch (error) {
        console.log('刷新房屋列表失败:', error)
      }
      
      // 延迟跳转到房屋页面
      setTimeout(() => {
        uni.switchTab({
          url: '/pages/device/index'
        })
      }, 1500)
    } else {
      uni.showToast({
        title: result.msg || '申请失败',
        icon: 'none'
      })
    }
  } catch (error) {
    console.error('申请失败:', error)
    uni.showToast({
      title: '申请失败，请重试',
      icon: 'none'
    })
  }
}

// ===== Taku 底部横幅广告位 ID（空/全关时不展示；随广告开关自动响应更新） =====
import { computed as __takuComputed, getCurrentInstance as __takuGci } from 'vue'
const __takuInst = __takuGci()
const __takuAdStore = __takuInst.proxy.$store.ad.useAdStore()
const bannerAdId = __takuComputed(() => __takuAdStore.getBannerAdId())
</script>

<style lang="scss" scoped>
@import '@/static/fonts/iconfont.css';

.container {
  min-height: 100vh;
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%);
  padding-bottom: 60rpx;
}

.form-section {
  background: transparent;
  padding: 40rpx 40rpx 0;
}

.info-section {
  padding: 32rpx 40rpx;
}

.info-card {
  background: white;
  border-radius: 32rpx;
  padding: 40rpx;
  margin-bottom: 24rpx;
  border: 1px solid rgba(0, 0, 0, 0.06);
  box-shadow: 0 8rpx 24rpx rgba(0, 0, 0, 0.06);
}

.info-header {
  display: flex;
  align-items: center;
  margin-bottom: 32rpx;
}

.info-icon {
  width: 80rpx;
  height: 80rpx;
  border-radius: 20rpx;
  background: rgba(102, 126, 234, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 20rpx;
}

.info-title {
  font-size: 32rpx;
  font-weight: 700;
  color: #1e293b;
}

.info-content {
  display: flex;
  flex-direction: column;
  gap: 24rpx;
}

.info-step {
  display: flex;
  align-items: center;
  gap: 20rpx;
}

.step-number {
  width: 48rpx;
  height: 48rpx;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  font-weight: 700;
  flex-shrink: 0;
}

.step-text {
  font-size: 28rpx;
  color: #64748b;
  line-height: 1.6;
}

.tip-card {
  background: rgba(255, 149, 0, 0.1);
  border-radius: 24rpx;
  padding: 24rpx 32rpx;
  display: flex;
  align-items: center;
  border: 1px solid rgba(255, 149, 0, 0.2);
}

.tip-text {
  font-size: 26rpx;
  color: #ff9500;
  line-height: 1.6;
  flex: 1;
}

.input-container {
  margin-top: 15rpx;
  padding: 0 40rpx;
}

.input-wrap {
  flex: 1;
  margin-right: 240rpx; /* 为两个按钮预留空间 */
  overflow: hidden;
}

.ellipsis-input {
  width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.custom-input {
  border: 2rpx solid rgba(0, 0, 0, 0.1);
  border-radius: 24rpx;
  margin-bottom: 24rpx;
  background: white;
  height: 108rpx;
  display: flex;
  align-items: center;
  padding-left: 40rpx;
  font-size: 30rpx;
  line-height: 30rpx;
  box-sizing: border-box;
  width: 100%;
  position: relative;
  box-shadow: 0 4rpx 12rpx rgba(0, 0, 0, 0.05);
  transition: all 0.3s;
}

.custom-input:focus-within {
  border-color: #667eea;
  box-shadow: 0 4rpx 12rpx rgba(102, 126, 234, 0.15);
}

/* 弹框样式 */
.modal-content {
  background-color: #fff;
  width: 600rpx;
  height: 800rpx;
  border-radius: 24rpx;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 30rpx;
  border-bottom: 1rpx solid #EEEEEE;
  position: relative;
}

.header-text {
  font-size: 35rpx;
  color: #333;
  font-weight: 500;
  flex: 1;
  text-align: center;
}

.close-icon {
  font-size: 40rpx;
  color: #999;
  padding: 20rpx;
  position: absolute;
  right: 0;
}

.modal-body {
  flex: 1;
  padding: 20rpx;
  overflow-y: auto;
}

/* 选项样式 */
.device-option {
  height: 88rpx;
  line-height: 88rpx;
  text-align: center;
  font-size: 28rpx;
  color: #333;
  background: #F5F5F5;
  margin-bottom: 20rpx;
  border-radius: 8rpx;
}

.device-option.selected {
  background-color: #FF4B4B;
  color: #fff;
}

/* 修改弹出层背景 */
:deep(.uni-popup) {
  /* #ifdef MP-WEIXIN || APP-PLUS */
  z-index: 999;
  /* #endif */
  background-color: rgba(0, 0, 0, 0.5) !important;
}

/* 图标组样式 */
.icon-group {
  display: flex;
  align-items: center;
  position: absolute;
  right: 0;
  top: 0;
  bottom: 0;
}

.btn-wrap {
  width: 120rpx;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2;
}

.action-btn {
  font-size: 24rpx;
  padding: 10rpx 20rpx;
  border-radius: 8rpx;
  border: none;
  color: #fff;
  line-height: 1.5;
}

.scan-btn {
  background-color: #007AFF;
}

.search-btn {
  background-color: #FF4B4B;
}

/* 去除按钮默认边框 */
.action-btn::after {
  border: none;
}

.room-select {
  position: relative;
  cursor: pointer;
}

.room-select input {
  pointer-events: none;
}

.divider {
  height: 1rpx;
  background: #EEEEEE;
  width: 100%;
}

.button-container {
  display: flex;
  justify-content: space-between;
  gap: 24rpx;
  padding: 32rpx 0;
}

.cancel-button {
  flex: 1;
  padding: 0 30rpx;
  font-size: 32rpx;
  height: 100rpx;
  text-align: center;
  font-weight: 700;
  border-radius: 24rpx;
  background-color: #f1f5f9 !important;
  color: #64748b !important;
  box-shadow: 0 4rpx 12rpx rgba(148, 163, 184, 0.2);
  transition: all 0.3s;
}

.login-button {
  flex: 1;
  padding: 0 30rpx;
  font-size: 32rpx;
  height: 100rpx;
  text-align: center;
  font-weight: 700;
  border-radius: 24rpx;
  box-shadow: 0 8rpx 24rpx rgba(255, 75, 75, 0.3);
  transition: all 0.3s;
}

.login-button.secondary {
  background-color: #cbd5e1;
  box-shadow: 0 4rpx 12rpx rgba(203, 213, 225, 0.3);
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