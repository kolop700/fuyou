const MAC_LIKE_RE = /^[0-9a-f]{10,}$/i
const IMEI_LIKE_RE = /^\d{14,17}$/

const ONLINE_STATUS = '1'

const cleanText = (value) => {
  return (value ?? '').toString().trim()
}

export const isDoorOnline = (device = {}) => {
  return device.online === ONLINE_STATUS
}

export const getDoorShortCode = (device = {}) => {
  const code = device.door_mac || device.door_qr_code || device.door_name || ''
  return code ? code.toString().slice(-4).toUpperCase() : ''
}

export const formatDoorLocation = (device = {}) => {
  const parts = [
    device.comm_name,
    device.unit_name,
    device.floor_name,
    device.room_name
  ].map(cleanText).filter(Boolean)

  return parts.length > 0 ? parts.join('') : '未知位置'
}

export const formatDoorName = (device = {}) => {
  const unitName = cleanText(device.unit_name)
  if (unitName) return unitName

  const rawName = cleanText(device.door_name)
  if (rawName && !isSystemDoorName(device)) {
    return rawName
  }

  const commName = cleanText(device.comm_name)
  return commName || '门禁设备'
}

export const isSystemDoorName = (device = {}) => {
  const name = (device.door_name || '').trim()
  if (!name) return true

  const mac = (device.door_mac || '').trim()
  const qrCode = (device.door_qr_code || '').trim()

  return name === mac || name === qrCode || MAC_LIKE_RE.test(name) || IMEI_LIKE_RE.test(name)
}

export const isUnitDoor = (device = {}) => {
  const location = formatDoorLocation(device)
  return Boolean(device.unit_name?.includes('单元') || location.includes('单元'))
}

/**
 * 格式化门禁设备数据用于展示
 * @param {Object} device 原始设备数据
 * @param {Number} index 索引
 * @param {Function} getDeviceOpenCount 获取开门次数的函数
 * @returns {Object} 格式化后的设备数据
 */
export const formatDoorDevice = (device, index, getDeviceOpenCount = () => 0) => {
  // 根据用户提供的数据结构，设备名称使用 door_name，位置/小区名使用 comm_name + door_name
  const name = device.door_name || `门禁设备 ${index + 1}`
  const location = device.comm_name && device.door_name 
    ? `${device.comm_name} ${device.door_name}`
    : (device.comm_name || device.door_name || '小区门禁')
  
  // 检查设备是否在线：online 字段为 "1" 或者 1 时表示在线
  const isOnline = String(device.online) === '1'
  
  return {
    ...device,
    name,
    location,
    isOnline,
    statusDetail: isOnline ? '设备在线' : '设备离线',
    openCount: getDeviceOpenCount(device.door_mac)
  }
}

export const sortDoorDevices = (devices = []) => {
  return [...devices].sort((a, b) => {
    if (a.isOnline !== b.isOnline) return a.isOnline ? -1 : 1
    if (b.openCount !== a.openCount) return b.openCount - a.openCount
    return (b.door_last_heart_beat || '').localeCompare(a.door_last_heart_beat || '')
  })
}
