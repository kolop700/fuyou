import request from '@/utils/request'

const LOCKER_ID = 1 // 快递柜 ID，目前写死

export default {
  // 获取快递柜信息及格口规格列表
  // 代理规则: /locker/* → http://test2.yefiot.com/api/locker/*
  getLockerInfo(params = LOCKER_ID, options = {}) {
    const queryParams = {}

    if (typeof params === 'object' && params !== null) {
      if (params.mac || params.locker_mac || params.c) {
        queryParams.mac = params.mac || params.locker_mac || params.c
      } else if (params.id || params.locker_id) {
        queryParams.id = params.id || params.locker_id
      }
    } else if (params !== undefined && params !== null && params !== '') {
      queryParams.id = params
    }

    return request({
      url: '/locker/get',
      method: 'get',
      params: Object.keys(queryParams).length ? queryParams : { id: LOCKER_ID },
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
        locker_id: rest.locker_id || LOCKER_ID,
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
      locker_id: rest.locker_id || LOCKER_ID,
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
      tracking_no
    } = data || {}

    return request({
      url: '/locker/pickup',
      method: 'post',
      data: {
        pickup_code: pickup_code || pick_code || '',
        tracking_no: tracking_no || tracking_number || ''
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
  },

  // 快递结算单查询
  qryComptBill(params = {}, options = {}) {
    return request({
      url: '/locker/qry_compt_bill',
      method: 'get',
      params,
      ...options
    })
  },

  // 快递结算单支付
  comptBillPay(data, options = {}) {
    return request({
      url: '/locker/compt_bill_pay',
      method: 'post',
      data,
      ...options
    })
  }
}
