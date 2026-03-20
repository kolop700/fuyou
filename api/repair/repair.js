import request from '@/utils/request'

export default {
  report(data, options = {}) {
    return request({
      url: '/repair/report',
      method: 'post',
      data,
      ...options
    })
  },

  qry(params = {}, options = {}) {
    return request({
      url: '/repair/qry',
      method: 'get',
      params,
      ...options
    })
  }
}
