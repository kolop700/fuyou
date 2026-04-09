import request from '@/utils/request'

const LOCKER_ID = 1 // 快递柜 ID，目前写死

export default {
  // 获取快递柜信息及格口规格列表
  // 代理规则: /locker/* → http://test2.yefiot.com/api/locker/*
  getLockerInfo(id = LOCKER_ID, options = {}) {
    return request({
      url: '/locker/get',
      method: 'get',
      params: { id },
      ...options
    })
  },

  // 快递员存件 —— 开柜
  courierBeginDeposit(data, options = {}) {
    const {
      tracking_number,
      tracking_no,
      phone,
      customer_phone,
      ...rest
    } = data || {}

    return request({
      url: '/locker/courier_begin_deposit',
      method: 'post',
      data: {
        locker_id: LOCKER_ID,
        tracking_no: tracking_no || tracking_number || '',
        customer_phone: customer_phone || phone || '',
        ...rest
      },
      ...options
    })
  },

  // 兼容旧调用
  courierDeposit(data, options = {}) {
    return this.courierBeginDeposit(data, options)
  },

  // 临时存货 —— 开柜
  tempBeginDeposit(data, options = {}) {
    const {
      duration,
      hours,
      openid,
      ...rest
    } = data || {}

    const payload = {
      locker_id: LOCKER_ID,
      hours: Number(hours ?? duration ?? 0),
      ...rest
    }

    if (openid) {
      payload.openid = openid
    }

    return request({
      url: '/locker/temp_begin_deposit',
      method: 'post',
      data: payload,
      ...options
    })
  },

  // 兼容旧调用
  tempStorage(data, options = {}) {
    return this.tempBeginDeposit(data, options)
  },

  // 结束存货
  endDeposit(data, options = {}) {
    return request({
      url: '/locker/end_deposit',
      method: 'post',
      data,
      ...options
    })
  },

  // 取件 —— 输入取件码开柜
  pickup(data, options = {}) {
    const {
      pickup_code,
      pick_code,
      tracking_number,
      tracking_no,
      openid,
      ...rest
    } = data || {}

    return request({
      url: '/locker/pickup',
      method: 'post',
      data: {
        openid: openid || '0',
        pick_code: pick_code || pickup_code || '',
        tracking_no: tracking_no || tracking_number || '',
        ...rest
      },
      ...options
    })
  },

  // 存取记录查询
  getRecords(params = {}, options = {}) {
    return request({
      url: '/locker/get_records',
      method: 'get',
      params: {
        locker_id: LOCKER_ID,
        ...params
      },
      ...options
    })
  },

  // 存货记录查询
  qryComptRecord(params = {}, options = {}) {
    console.log('[locker.qryComptRecord] request params:', params)
    return request({
      url: '/locker/qry_compt_record',
      method: 'get',
      params,
      ...options
    }).then((res) => {
      console.log('[locker.qryComptRecord] response data:', res)
      return res
    }).catch((error) => {
      console.log('[locker.qryComptRecord] response error:', error)
      throw error
    })
  }
}
