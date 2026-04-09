const IMAGE_BASE_URL = 'https://test2.yefiot.com/'

export const buildImageUrl = (path = '') => {
  const value = String(path || '').trim()

  if (!value) return ''
  if (/^https?:\/\//i.test(value)) return value

  return `${IMAGE_BASE_URL}${value.replace(/^\/+/, '')}`
}

export const buildImageUrls = (list = []) => {
  if (!Array.isArray(list)) return []
  return list.map(item => buildImageUrl(item)).filter(Boolean)
}

export default {
  IMAGE_BASE_URL,
  buildImageUrl,
  buildImageUrls
}
