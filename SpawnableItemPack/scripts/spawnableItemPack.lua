spawnableItemPack = {}
sip = spawnableItemPack

function sip.init()
  mui.setTitle("^shadow;Spawnable Item Pack", "^shadow;Spawn anything, for free!")
  mui.setIcon("/interface/sip/icon.png")
  sip.items = {}
  sip.categories = {}
  sip.changingCategory = false
  
  sip.quantity = 1
  
  widget.setVisible("sipCategoryScroll", false)
  widget.setVisible("sipCategoryBackground", false)
  
  widget.addListItem("sipItemScroll.sipItemList")
end

function sip.update(dt)

end

function sip.uninit()
  sip.showCategories(false)
end

function sip.categorySelected()

end

function sip.search()

end

function sip.changePage(_, data)

end

function sip.print()

end

--[[

]]
function sip.changeCategory()
  sip.changingCategory = not sip.changingCategory
  sip.showCategories(sip.changingCategory)
end

function sip.showCategories(bool)
  widget.setVisible("sipCategoryBackground", bool)
  widget.setVisible("sipCategoryScroll", bool)
end

function sip.changeType()

end

--[[
  Returns the currently selected quantity of items to print. Errors if quantity somehow ends up not being a number.
  @return - Quantity of item to print.
]]
function sip.getQuantity()
  if type(sip.quantity) ~= "number" then error("SIP: Quantity is stored incorrectly. Please contact the mod author.") end
  return sip.quantity
end

--[[
  Adjusts the selected quantity of items to print by the given amount. Errors if the passed value is not a number.
  @param amnt - Amount to adjust the quantity with. Can be positive and negative. Should be an integer.
]]
function sip.adjustQuantity(amnt)
  if type(amnt) ~= "number" then error("SIP: Attempted to adjust quantity by an invalid number. Please contact the mod author.") end
  sip.setQuantity(sip.getQuantity() + amnt)
end

--[[
  Sets to currently selected quantity of items to print to the given amount. Errors if the given value is not a number.
  @param amnt - New quantity. Should be an integer.
]]
function sip.setQuantity(amnt)
  if type(amnt) ~= "number" then error("SIP: Attempted to set quantity to an invalid number. Please contact the mod author.") end
  sip.quantity = math.clamp(amnt, 0, 9999)
  
  widget.setText("sipTextQuantity", "x" .. sip.getQuantity())
end

--[[
  Widget callback function. Parses widget data. If this is a number, adjust quantity by it.
  Otherwise, fetch quantity from text field.
]]
function sip.changeQuantity(_, data)
  if type(data) == "number" then
    sip.adjustQuantity(data)
  else
    local str = widget.getText("sipTextQuantity"):gsub("x","")
    local n = tonumber(str)
    if n then sip.setQuantity(n) end
  end  
end

--[[
  Clamps and returns a value between the minimum and maximum value.
  @param i - Value to clamp.
  @param low - Minimum bound (inclusive).
  @param high - Maximum bound (inclusive).
]]
function math.clamp(i, low, high)
  if low > high then low, high = high, low end
  return math.min(high, math.max(low, i))
end