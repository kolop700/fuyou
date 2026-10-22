export const genOfflineTempPassword = (factoryCode, mac, date = new Date()) => {
  if (!factoryCode || !mac) {
    return ''
  }

  const year = date.getFullYear()
  const month = date.getMonth() + 1
  const day = date.getDate()
  const minutes = date.getHours() * 60 + date.getMinutes()
  const dateSeed = year * month * day
  const timeSeed = dateSeed * (Math.floor(minutes / 30) + 1)
  const source = `${factoryCode}${mac}`

  let hash = 0
  for (let i = 0; i < source.length; i++) {
    hash = (Math.imul(hash, 31) + source.charCodeAt(i)) >>> 0
  }

  hash = (hash ^ timeSeed) >>> 0
  return String(hash).padStart(6, '0').slice(-6)
}

export const showOfflinePasswordModal = (device = {}) => {
  const password = genOfflineTempPassword(device.factory_code, device.door_mac)

  if (!password) {
    uni.showToast({
      title: '缺少离线密码参数',
      icon: 'none'
    })
    return
  }

  uni.showModal({
    title: '设备离线',
    content: `当前设备离线，可在门禁键盘输入离线密码开门。\n\n离线密码：**${password}#`,
    confirmText: '复制密码',
    cancelText: '关闭',
    success: (res) => {
      if (!res.confirm) return

      uni.setClipboardData({
        data: password,
        success: () => {
          uni.showToast({
            title: '密码已复制',
            icon: 'success'
          })
        }
      })
    }
  })
}

export const showOpenDoorFailModal = () => {
  uni.showModal({
    title: '开门失败',
    content: '远程开门失败，请稍后重试。若设备离线，请使用离线密码开门。',
    showCancel: false,
    confirmText: '知道了'
  })
}
