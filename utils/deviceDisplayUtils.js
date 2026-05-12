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

export const formatDoorDevice = (device = {}, index = 0, getOpenCount = () => 0) => {
  const online = isDoorOnline(device)
  const unitDoor = isUnitDoor(device)
  const shortCode = getDoorShortCode(device)
  const location = formatDoorLocation(device)
  const name = formatDoorName(device)

  const unitThemes = [
    { icon: 'icon-fasfa-building', iconGradient: 'linear-gradient(135deg, #34c759 0%, #30d158 100%)' },
    { icon: 'icon-fasfa-building', iconGradient: 'linear-gradient(135deg, #0a84ff 0%, #0066cc 100%)' },
    { icon: 'icon-fasfa-building', iconGradient: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)' }
  ]
  const gateThemes = [
    { icon: 'icon-door-open', iconGradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' },
    { icon: 'icon-door-open', iconGradient: 'linear-gradient(135deg, #ff9500 0%, #ff6b00 100%)' },
    { icon: 'icon-door-open', iconGradient: 'linear-gradient(135deg, #ff2d55 0%, #ff375f 100%)' }
  ]
  const theme = unitDoor ? unitThemes[index % unitThemes.length] : gateThemes[index % gateThemes.length]

  return {
    ...device,
    name,
    location,
    icon: theme.icon,
    iconGradient: theme.iconGradient,
    signal: online ? '可用' : '不可用',
    statusText: online ? '在线' : '离线',
    statusDetail: online ? '在线' : '离线',
    shortCode,
    isOnline: online,
    isUnitDoor: unitDoor,
    openCount: getOpenCount(device.door_mac)
  }
}

export const sortDoorDevices = (devices = []) => {
  return [...devices].sort((a, b) => {
    if (a.isOnline !== b.isOnline) return a.isOnline ? -1 : 1
    if (b.openCount !== a.openCount) return b.openCount - a.openCount
    return (b.door_last_heart_beat || '').localeCompare(a.door_last_heart_beat || '')
  })
}
