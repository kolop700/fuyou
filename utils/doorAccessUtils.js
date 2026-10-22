import { useUserStore } from '@/store/modules/user'
import deviceApi from '@/api/device/device'

// 门禁工具类
export default {
  // 将用户卡号格式化为 8 位
  formatCardNumber(card) {
    return (Array(8).join(0) + card).slice(-8)
  },

  // 将用户密码格式化为 8 位
  formatPassword(pswd) {
    if (pswd.length < 3) pswd = '00000000'
    return (Array(8).join(0) + pswd).slice(-8)
  },

  // 将脸部标记转换为 2 位 16 进制字符串
  formatTag(tag) {
    return (Array(2).join(0) + parseInt(tag, 10).toString(16)).slice(-2)
  },

  // 格式化有效日期字符串为 "YYMMDD" 格式
  formatExpireDate(dstrs) {
    let ystr = dstrs.substring(2, 4)
    let mstr = (Array(2).join(0) + dstrs.substring(5, 7)).slice(-2)
    let dstr = (Array(2).join(0) + dstrs.substring(8, 10)).slice(-2)
    return ystr + mstr + dstr
  },

  // 将用户编号格式化为 8 位
  formatUserId(userId) {
    return (Array(8).join(0) + parseInt(userId).toString(16).toUpperCase()).slice(-8)
  },

  // 给数据包加校验
  addChecksum(pkg) {
    let arr = []
    for (let i = 0, j = 0; i < pkg.length; i = i + 2) {
      arr[j] = pkg.substring(i, i + 2)
      j++
    }
    let arrstr = '00'
    for (let i = 0, j = 0; i < pkg.length; i = i + 2) {
      arrstr = (parseInt(arrstr, 16) ^ parseInt(arr[j], 16)).toString(16)
      j++
    }
    if (arrstr.length == 1) arrstr = '0' + arrstr
    return ('H' + pkg + arrstr + 'W').toUpperCase()
  },

  normalizeMac(mac = '') {
    return mac.toString().replace(/[^a-zA-Z0-9]/g, '').toUpperCase()
  },

  // 生成最终的 doorpkg 数据包
  generateDoorPkg(card, tag, datestr, liftstr, user_id, pswd, timegroup) {
    let prefix = 'D2'
    let pkg = prefix + card + tag + datestr + liftstr + timegroup + user_id + pswd
    return this.addChecksum(pkg)
  },

  // 门禁类型映射表
  doorTypes: {
    "1": "yfn01",
    "2": "yfn02",
    "3": "yfn03",
    "4": "yfn04",
    "5": "yfb01",
    "11": "yff01",
    "12": "yff02",
    "13": "yff03",
    "41": "yfv01",
    "42": "yfv02",
    "43": "bxv02",
    "44": "yfv04",
    "45": "bxv05",
    "46": "yfv06",
    "47": "yfv07",
    "48": "yfv08",
    "49": "yfv09",
    "51": "yfl01",
    "91": "yfd01",
    "92": "yfd02"
  },

  // 门类型转换为 16 进制表示，并补足 4 位
  formatDoorType(doorType) {
    const type = doorType.toString()
    console.log('门类型:', type)
    // 如果在映射表中存在，直接返回
    if (this.doorTypes[type]) {
      return this.doorTypes[type]
    }
    
    // 如果大于100，转换为16进制并补足4位
    if (parseInt(type) > 100) {
      const hexType = parseInt(type).toString(16).toUpperCase()
      return (Array(4).join('0') + hexType).slice(-4)
    }
    
    // 默认返回 yfn03
    return 'yfn03'
  },

  handleOpenResponse(res, door) {
    const responseMac = res?.mac || ''
    const expectedMac = door?.door_mac || ''
    const msgInfo = res?.data?.[0]?.msg_info

    console.log('开门响应:', {
      mac: responseMac,
      expectedMac,
      msg_info: msgInfo,
      data: res?.data
    })

    if (responseMac && this.normalizeMac(responseMac) !== this.normalizeMac(expectedMac)) {
      console.warn('开门响应设备不匹配:', {
        expectedMac,
        responseMac
      })
      uni.showToast({
        title: '开门失败(设备不匹配)!',
        icon: 'error',
        duration: 3000
      })
      throw { type: 'DeviceMismatch', msg: '开门响应设备不匹配' }
    }

    switch (msgInfo) {
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
          title: `数据同步失败(${msgInfo})!`,
          icon: 'none',
          duration: 3000
        })
        throw { type: 'SyncFailed', msg: `数据同步失败(${msgInfo})` }

      case 'HD2AA78W':
        uni.showToast({
          title: `开门失败(${msgInfo})!`,
          icon: 'none',
          duration: 3000
        })
        throw { type: 'OpenFailed', msg: `开门失败(${msgInfo})` }

      default:
        if (!msgInfo) {
          const fallbackMessage = res?.msg || res?.message || '开门失败!'
          uni.showToast({
            title: fallbackMessage,
            icon: 'error',
            duration: 3000
          })
          throw { type: 'UnknownError', msg: fallbackMessage }
        }

        uni.showToast({
          title: '开门成功!',
          icon: 'none',
          duration: 3000
        })
        return true
    }
  },

  // 开门方法
  async openDoor(door) {
    try {
      // 获取用户信息
      const userStore = useUserStore()
      const userInfo = userStore.userInfo
      
      if (!userInfo || !userInfo.user_id) {
        uni.showToast({
          title: '请先登录！',
          icon: 'none'
        })
        throw false
      }

      // 格式化数据
      const card = this.formatCardNumber(userInfo.user_card_a)
      const pswd = this.formatPassword(userInfo.user_card_b)
      const tag = this.formatTag(userInfo.user_face_tag)
      // 免授权开门的用户可能没有任何房间，maxExpireDate 为空时兜底远期日期，避免组包日期字段无效
      const expireRaw = (userStore.maxExpireDate || '2099-12-31').toString()
      const datestr = this.formatExpireDate(expireRaw)
      const user_id = this.formatUserId(userInfo.user_id)
      
      // 处理电梯参数
      const liftstr = door.liftstr || '0'.repeat(16)
      const timegroup = door.timegroup || '00'

      // 获取门类型
      const type = this.formatDoorType(door.door_type)

      console.log("开门参数:", {
        card,
        tag,
        datestr,
        liftstr,
        user_id,
        pswd,
        timegroup,
        door_type: door.door_type,
        formatted_type: type
      })

      // 生成开门数据包
      const doorpkg = this.generateDoorPkg(
        card, tag, datestr, liftstr, user_id, pswd, timegroup
      )

      // 显示加载提示
      uni.showLoading({
        title: '开门中...',
        mask: true
      })

      const response = await deviceApi.openDoor({
        type,
        mac: door.door_mac,
        cmd: '0',
        sn: 'APP' + Date.now().toString(),
        info: doorpkg
      }, {
        showLoading: false
      })

      return this.handleOpenResponse(response, door)
    } catch (error) {
      if (error && error.type) {
        // 这是 handleOpenResponse 抛出的已知错误
        throw error
      }

      if (error?.data || error?.mac) {
        return this.handleOpenResponse(error, door)
      }

      uni.showToast({
        title: '开门失败(网络异常或设备离线)!',
        icon: 'error',
        duration: 3000
      })
      console.error('开门失败:', error)
      throw { type: 'NetworkError', msg: '网络异常或设备离线', originalError: error }
    } finally {
      uni.hideLoading()
    }
  }
}
