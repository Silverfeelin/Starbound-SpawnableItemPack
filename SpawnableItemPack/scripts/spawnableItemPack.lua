spawnableItemPack = {}
sip = spawnableItemPack

function sip.init()
  mui.setTitle("^shadow;Spawnable Item Pack", "^shadow;Spawn anything, for free!")
  mui.setIcon("/interface/sip/icon.png")
  
  sip.items = root.assetJson("/sipItemDump.json")
  sip.itemList =  "sipItemScroll.sipItemList"
  sip.categories = {}
  sip.changingCategory = false
  sip.selectedCategory = nil
  
  sip.logENV()
  
  sip.quantity = 1
  
  widget.setVisible("sipCategoryScroll", false)
  widget.setVisible("sipCategoryBackground", false)
  
  sip.showItems()
end

function sip.logENV()
  for i,v in pairs(_ENV) do
    if type(v) == "function" then
      sb.logInfo("%s", i)
    elseif type(v) == "table" then
      for j,_ in pairs(v) do
        sb.logInfo("%s.%s", i, j)
      end
    end
  end
end

function sip.showItems(category)
  widget.clearListItems("sipItemScroll.sipItemList")
  
  local categories = {}
  
  if type(category) == "string" then categories[category] = true end
  if type(category) == "table" then
    categories = Set(category)
  end
  
  sb.logInfo("%s", categories)
  
  local count = 0
  
  for i,v in ipairs(sip.items) do
    if category == nil or categories[v.category:lower()] then
      local li = widget.addListItem("sipItemScroll.sipItemList")
      widget.setText(sip.itemList .. "." .. li .. ".itemName", "^shadow;^white;" .. v.shortdescription)
      widget.setData(sip.itemList .. "." .. li, v)
      if type(v.icon) == "string" and v.icon ~= "null" then
        if v.icon:find("/") == 1 then v.path = "" end
        widget.setImage("sipItemScroll.sipItemList." .. li .. ".itemIcon", v.path .. v.icon)
      elseif type(v.icon) == "table" then
        sip.setDrawableIcon("sipItemScroll.sipItemList." .. li .. ".itemIcon", v.icon[1])
        sip.setDrawableIcon("sipItemScroll.sipItemList." .. li .. ".itemIcon2", v.icon[2])
        sip.setDrawableIcon("sipItemScroll.sipItemList." .. li .. ".itemIcon3", v.icon[3])
      end
      count = count + 1
    end
  end
  
  sb.logInfo("SIP: Done adding " .. count .. " items to the list!")
end

function sip.setDrawableIcon(wid, path, drawable)
  if not d or not d.image then return end
  local image = d.image
  if drawable:find("/") == 1 then path = "" end
  widget.setImage(wid, path .. image)
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
  local item, q = sip.getSelectedItem(), sip.getQuantity()
  if not item or not item.name then return end
  
  if not pcall(function() root.itemConfig(item.name) end) then
    sb.logError("SIP: Item configuration could not be loaded! Please report the following line to the mod author.\n%s", item)
  end
  
  local it, rest = math.floor(q / 1000), q % 1000
  for i=1,it do
    player.giveItem({name=item.name, count=1000})
  end
  player.giveItem({name=item.name, count=rest})

    

end

function sip.getSelectedItem()
  local li = widget.getListSelected(sip.itemList)
  if not li then return end
  local item = widget.getData(sip.itemList .. "." .. li)
  return item
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

function sip.selectCategory(w, category)
  if sip.selectedCategory ~= w then
    sip.selectedCategory = w
    sip.showItems(category)
  else
    sip.selectedCategory = nil
    sip.showItems()
  end
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

--https://www.lua.org/pil/11.5.html
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end