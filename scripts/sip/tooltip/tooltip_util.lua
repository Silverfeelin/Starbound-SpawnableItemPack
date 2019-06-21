tooltipUtil = {}

function tooltipUtil.growRect(rect, size)
  if type(size) == "number" then size = {size, size} end
  return {
    rect[1] - size[1],
    rect[2] - size[2],
    rect[3] + size[1],
    rect[4] + size[2]
  }
end
