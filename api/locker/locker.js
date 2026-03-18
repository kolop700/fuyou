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
  courierDeposit(data, options = {}) {
    return request({
      url: '/locker/courier_deposit',
      method: 'post',
      data: {
        locker_id: LOCKER_ID,
        ...data
      },
      ...options
    })
  },

  // 临时存货 —— 开柜
  tempStorage(data, options = {}) {
    return request({
      url: '/locker/temp_storage',
      method: 'post',
      data: {
        locker_id: LOCKER_ID,
        ...data
      },
      ...options
    })
  },

  // 取件 —— 输入取件码开柜
  pickup(data, options = {}) {
    return request({
      url: '/locker/pickup',
      method: 'post',
      data: {
        locker_id: LOCKER_ID,
        ...data
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
  }
}
