-- Prevent loading if another scriptHooks has been loaded (i.e. same script in a different folder)
if tooltip then return end
require "/scripts/sip/tooltip/scriptHooks.lua"
require "/scripts/sip/tooltip/tooltip_util.lua"
require "/scripts/vec2.lua"

tooltip = {}
tooltip.util = tooltipUtil

--- Initializes the tooltip library.
function tooltip.init()
  tooltip.paneConfig = config.getParameter("tooltip", { canvas = "tooltipCanvas", label = "tooltipLabel" })
  tooltip.config = root.assetJson("/scripts/sip/tooltip/tooltip.config")

  tooltip.canvas = widget.bindCanvas(tooltip.paneConfig.canvas)
  tooltip.label = tooltip.paneConfig.label
end

--- Draws a tooltip (if any).
-- Prevents drawing the same tooltip multiple times.
-- @param screenPosition Screen position.
function tooltip.cursorOverride(screenPosition)
  local w = widget.getChildAt(screenPosition)
  local t, pos
  local tipped = false
  if w then
    w = w:sub(2)
    local d = widget.getData(w)
    if type(d) == "table" and type(d.tooltip) == "table" then
      t = d.tooltip
    end
  end

  if t and tooltip.previousWidget ~= w then
    -- Only draw new tooltip if w is different.
    tooltip.canvas:clear()
    pos = t.position or widget.getPosition(w)
    local size = widget.getSize(w)

    tooltip.draw(t, pos, size)
  elseif not t and tooltip.previousWidget then
    -- Clear tooltip when no longer hovering.
    tooltip.canvas:clear()
  end
  tooltip.previousWidget = w
end

--- Draws a tooltip next to the given widget.
-- @param ttip Tooltip data.
-- @param wPos Target widget position.
-- @param wSize Target widget size.
function tooltip.draw(ttip, wPos, wSize)
  local c = tooltip.canvas

  local text = tooltip.getText(ttip)
  if text == "" then return end

  widget.setText(tooltip.label, text)
  local labelSize = widget.getSize(tooltip.label)

  -- Params
  local margin = tooltip.parameter(ttip, "margin")
  local padding = tooltip.parameter(ttip, "padding")
  local border = tooltip.parameter(ttip, "border")
  local background = tooltip.parameter(ttip, "background")
  local borderWidth = tooltip.parameter(ttip, "borderWidth")
  local position = tooltip.parameter(ttip, "position")
  local fontSize = tooltip.parameter(ttip, "fontSize") or 7
  local p = position or tooltip.offset(wPos, wSize, labelSize, ttip.direction or "top", margin + padding)

  -- Label rect
  local rect = {
    p[1] - labelSize[1]/2,
    p[2] - labelSize[2]/2,
    p[1] + labelSize[1]/2,
    p[2] + labelSize[2]/2
  }

  -- Border
  local padRect = tooltipUtil.growRect(rect, padding)
  c:drawRect(padRect, border)

  -- Background
  padRect = tooltipUtil.growRect(padRect, -borderWidth)
  c:drawRect(padRect, background)

  -- Arrow
  local tabPos, tabRot = tooltip.drawTab(ttip, p, vec2.add(labelSize,padding * 2))

  -- Text
  c:drawText(text, {position = p, horizontalAnchor = "mid", verticalAnchor = "mid"}, fontSize, tooltip.parameter(ttip, "color"))
end

--- Gets the text for a tooltip.
-- @param Tooltip.
-- @return Tooltip text, callback return value or an empty string.
function tooltip.getText(ttip)
  return ttip.text or ttip.callback and _ENV[ttip.callback]() or ""
end

--- Gets a parameter from the tooltip, or the default value.
-- @param ttip Tooltip.
-- @param param Tooltip parameter name.
function tooltip.parameter(ttip, param)
  return ttip[param] or tooltip.config.default[param]
end

-- Draws a small arrow pointing to the widget.
-- @param ttip Tooltip
-- @param tPos Center of tooltip.
-- @param tSize Size of tooltip (border rect)
function tooltip.drawTab(ttip, tPos, tSize)
  local border = tooltip.parameter(ttip, "border")
  local background = tooltip.parameter(ttip, "background")

  local pos = {}
  local dir = string.format("?replace;ffffff=%s;000000=%s", background:sub(2), border:sub(2))
  local tab

  if ttip.direction == "left" then -- Right
    pos[1] = tPos[1] + tSize[1] / 2
    pos[2] = tPos[2]
    tab = "/interface/tooltip/tabright.png"
  elseif ttip.direction == "right" then -- Left
    pos[1] = tPos[1] - tSize[1] / 2
    pos[2] = tPos[2]
    tab = "/interface/tooltip/tableft.png"
  elseif ttip.direction == "top" then -- Bottom
    pos[1] = tPos[1]
    pos[2] = tPos[2] - tSize[2] / 2
    tab = "/interface/tooltip/tabdown.png"
  elseif ttip.direction == "bottom" then -- Top
    pos[1] = tPos[1]
    pos[2] = tPos[2] + tSize[2] / 2
    tab = "/interface/tooltip/tabup.png"
  end

  tooltip.canvas:drawImage(tab .. dir, pos, nil, nil, true)
end

--- Offsets a tooltip to line up next to the widget
-- For example, when passing (buttonPos, buttonSize, tooltipSize, "top", 2), the returned position will center the tooltip above the button with a 2 pixel gap.
-- @param wPos widget.getPosition (bottom left corner)
-- @param wSize widget.getSize
-- @param tooltipSize Size of the tooltip (border rect)
-- @param [distance=0] amount of pixels between widget and tooltip.
--   This should usually be margin + padding.
function tooltip.offset(wPos, wSize, tooltipSize, direction, distance)
  local newPos = {}
  if not distance then distance = 0 end

  if direction == "left" then -- Left center
    newPos[1] = wPos[1] - tooltipSize[1] / 2 - distance
    newPos[2] = wPos[2] + wSize[2] / 2
  elseif direction == "right" then -- Right center
    newPos[1] = wPos[1] + wSize[1] + tooltipSize[1] / 2 + distance
    newPos[2] = wPos[2] + wSize[2] / 2
  elseif direction == "top" then -- Center top
    newPos[1] = wPos[1] + wSize[1] / 2
    newPos[2] = wPos[2] + wSize[2] + tooltipSize[2] / 2 + distance
  elseif direction == "bottom" then -- Center bottom
    newPos[1] = wPos[1] + wSize[1] / 2
    newPos[2] = wPos[2] - tooltipSize[2] / 2 - distance
  else
    error(string.format("Direction %s not supported.", direction))
  end

  return newPos
end

-- Hook functions
hook("init", tooltip.init)
hook("cursorOverride", tooltip.cursorOverride)
