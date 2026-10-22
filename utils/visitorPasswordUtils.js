import request from '@/utils/request'

class VisitorPasswordUtils {
  // 处理开门响应
  handleOpenResponse(res) {
    console.log('开门响应:', res)
      // 防御：后端查无门/通讯失败时响应体为空或 {code:'1'}，无 data 数组，
      // 不能直接解构 res.data[0]（会抛 TypeError 吞掉真实原因）
      const rows = res && Array.isArray(res.data) ? res.data : null
      if (!rows || rows.length === 0 || !rows[0].msg_info) {
        uni.showToast({
          title: (res && (res.msg || res.detail)) || '设备未响应开门指令',
          icon: 'none',
          duration: 3000
        })
        return false
      }
      const { msg_info } = rows[0]
      console.log('开门响应:', msg_info)
      switch (msg_info) {
        case 'HD2BB69W':
          uni.showToast({
            title: '开门成功!',
            icon: 'success',
            duration: 3000
          })
          return true

        case 'HD3BB68W':
          uni.showToast({
            title: '数据同步成功!',
            icon: 'none',
            duration: 1000
          })
          return true

        case 'HD3AA79W':
          uni.showToast({
            title: `数据同步失败(${msg_info})!`,
            icon: 'none',
            duration: 3000
          })
          return false

        case 'HD2AA78W':
          uni.showToast({
            title: `开门失败(${msg_info})!`,
            icon: 'none',
            duration: 3000
          })
          return false

        default:
          uni.showToast({
            title: '开门失败!',
            icon: 'error',
            duration: 3000
          })
          return false
      }
  }

  // 验证访客密码
  async verifyPassword(params) {
    try {
      const res = await request({
        url: '/yefiot/v1/checkTempPsw/',
        method: 'post',
        data: {
          OpenPassword: params.password,
          qrcode: params.deviceNumber,
          sn: params.sn
        }
      })
      
      if (res.code === 0 || res.code === '0') {
        // 把命中的门/密码记录带回：temppswOpen 需要其中的 user_WeChat_id 作 openid（后端按它查主人权限）
        return { success: true, sn: params.sn, doorInfo: Array.isArray(res.data) ? res.data[0] : null }
      } else {
        uni.showToast({
          title: res.msg || '密码错误或已过期',
          icon: 'none'
        })
        return { success: false }
      }
    } catch (error) {
      console.error('访客密码验证失败:', error)
      // request.js 对业务错误码直接 reject，真实失败原因在 error.msg，不再吞成通用文案
      uni.showToast({
        title: (error && (error.msg || error.message || error.detail)) || '验证失败，请重试',
        icon: 'none'
      })
      return { success: false }
    }
  }

  // 访客密码开门
  async openDoor(params) {
    try {
      const res = await request({
        url: '/yefiot/v1/temppswOpen/',
        method: 'post',
        data: {
          // 后端 WeChart_qr_open 过程按 user_WeChat_id 查密码主人再下开门指令，
          // 传固定 '0' 查不到用户会静默失败（老小程序传 checkTempPsw 返回的 user_WeChat_id）
          openid: params.openid || '0',
          qrcode: params.deviceNumber,
          sn: params.sn
        }
      })
      
      return this.handleOpenResponse(res)
    } catch (error) {
       return this.handleOpenResponse(error)
    }
  }
}

export default new VisitorPasswordUtils() 