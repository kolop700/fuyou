import request from '@/utils/request'

const BASE_API = '/yefiot/v1/'

// 添加默认配置
const defaultOptions = {
  showLoading: true
}

export default {
  // 获取设备列表
  getDoorList(user_id, options = {}) {
    return request({
      url: BASE_API + 'getDoorList/',
      method: 'post',
      data: {
        app_phone_mac: "",
        user_id
      },
      ...defaultOptions,
      ...options
    })
  },

  // 保存快递员申请
  saveCourier(data, options = {}) {
    return request({
      url: '/locker/save_courier', // 直接使用提供的路径
      method: 'post',
      data,
      ...defaultOptions,
      ...options
    })
  },

  // 获取快递员申请记录
  getCourierHistory(userId, page = 1, size = 50, options = {}) {
    return request({
      url: '/locker/qry_courier',
      method: 'get',
      params: { // GET请求使用params
        page,
        size
      },
      ...defaultOptions,
      ...options
    })
  },

  // 发送开门请求
  openDoor(params, options = {}) {
    return request({
      url: BASE_API + 'mqttpost/',
      method: 'post',
      data: params,
      ...defaultOptions,
      ...options
    })
  },

  // 获取单元列表
  getUnitList(data, options = {}) {
    return request({
      url: BASE_API + 'getUnitLike/',
      method: 'post',
      data,
      ...defaultOptions,
      ...options
    })
  },

  // 获取社区列表
  getCommunityList(name = '', options = {}) {
    return request({
      url: BASE_API + 'openSQL/',
      method: 'post',
      data: {
        sql: `SELECT comm_id, comm_name as unitname FROM t_community WHERE comm_name LIKE ''%${name}%''`
      },
      ...defaultOptions,
      ...options
    })
  },

  // 获取当前用户所属小区列表
  getUserCommunityList(userId, options = {}) {
    return request({
      url: BASE_API + 'openSQL/',
      method: 'post',
      data: {
        sql: `SELECT * FROM v_room_ad_user WHERE user_id =  ''${userId}''`
      },
      ...defaultOptions,
      ...options
    })
  },

  // 获取房间列表
  getRoomList(unit_id, options = {}) {
    return request({
      url: BASE_API + 'getRoomList/',
      method: 'post',
      data: {
        unit_id
      },
      ...defaultOptions,
      ...options
    })
  },

  // 通过二维码获取单元信息
  getUnitByQRCode(qrCode, options = {}) {
    return request({
      url: BASE_API + 'openSQL/',
      method: 'post',
      data: {
        sql: `CALL GetUnitNameByQRCode(''${qrCode}'')`
      },
      ...defaultOptions,
      ...options
    })
  },

  // 按扫码值查门设备（免授权开门用：不限属主，扫码串匹配 door_qr_code 或 door_mac）
  // 注意：t_doorphone 无 liftstr/timegroup 列（多查会整条 SQL 报错），电梯参数由 doorAccessUtils 默认值兜底
  getDoorByScanCode(code, options = {}) {
    return request({
      url: BASE_API + 'openSQL/',
      method: 'post',
      data: {
        sql: `SELECT door_id, door_type, door_mac, door_name FROM t_doorphone WHERE door_qr_code = ''${code}'' OR door_mac = ''${code}'' LIMIT 1`
      },
      ...defaultOptions,
      ...options
    })
  },

  // 获取远程开门设备列表
  getRemoteOpenDoorList(userId, options = {}) {
    return request({
      url: BASE_API + 'openSQL/',
      method: 'post',
      data: {
        sql: `CALL get_remote_open_door_list('''',${userId})`
      },
      ...defaultOptions,
      ...options
    })
  },

  // 保存临时密钥
  saveTempKey(params, options = {}) {
    return request({
      url: BASE_API + 'uptempkey/',
      method: 'post',
      data: params,
      ...defaultOptions,
      ...options
    })
  },

  // 验证访客密码
  checkTempPassword(params, options = {}) {
    return request({
      url: BASE_API + 'checkTempPsw/',
      method: 'post',
      data: {
        OpenPassword: params.password,
        qrcode: params.deviceNumber,
        sn: params.sn
      },
      ...defaultOptions,
      ...options
    })
  },

  // 访客密码开门
  tempPasswordOpen(params, options = {}) {
    return request({
      url: BASE_API + 'temppswOpen/',
      method: 'post',
      data: {
        openid: "0",
        qrcode: params.deviceNumber,
        sn: params.sn
      },
      ...defaultOptions,
      ...options
    })
  }
} 
