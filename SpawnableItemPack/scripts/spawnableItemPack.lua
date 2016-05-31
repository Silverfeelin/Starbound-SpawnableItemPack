spawnableItemPack = {}
sip = spawnableItemPack

sip.rarities = {
  common = "/interface/inventory/grayborder.png",
  uncommon = "/interface/inventory/greenborder.png",
  rare = "/interface/inventory/blueborder.png",
  legendary = "/interface/inventory/purpleborder.png"
}

sip.widgets = {
  quantity = "sipTextQuantity",
  itemList = "sipItemScroll.sipItemList",
  search = "sipTextSearch",
  categoryBackground = "sipCategoryBackground",
  categoryScrollArea = "sipCategoryScroll"
}

--[[
  Initializes SIP.
  This function is called every time SIP is opened from the MUI Main Menu.
]]
function sip.init()
  mui.setTitle("^shadow;Spawnable Item Pack", "^shadow;Spawn anything, for free!")
  mui.setIcon("/interface/sip/icon.png")
  
  sip.searchDelay, sip.searchTick = 10, 10
  sip.searched = true
  sip.previousSearch = ""
  
  sip.items = root.assetJson("/sipItemDump.json")
  sip.categories = nil
  sip.changingCategory = false
  
  sip.selectedCategory = nil
  
  -- TODO: Clear current category selection in radioGroup.
  -- Current callbacks do not appear to allow this.
  
  --logENV()
  
  sip.quantity = 1
  
  sip.showCategories(false)
  
  sip.showItems()
end

function sip.showItems(category) 
  widget.clearListItems("sipItemScroll.sipItemList")
  
  if category then
    sip.categories = nil
    if type(category) == "string" then sip.categories = { [category] = true }
    elseif type(category) == "table" then sip.categories = Set(category) end
  end
  
  local count = 0
  
  for i,v in ipairs(sip.items) do
    if not sip.categories or sip.categories[v.category:lower()] then
      if sip.previousSearch == "" or v.shortdescription:lower():find(sip.previousSearch:lower()) or v.name:lower():find(sip.previousSearch:lower()) then
        local li = widget.addListItem("sipItemScroll.sipItemList")
        widget.setText(sip.widgets.itemList .. "." .. li .. ".itemName", "^shadow;^white;" .. v.shortdescription)
        widget.setData(sip.widgets.itemList .. "." .. li, v)
        widget.setImage("sipItemScroll.sipItemList." .. li .. ".itemRarity", sip.rarities[v.rarity])
        if type(v.icon) == "string" and v.icon ~= "null" then
          if v.icon:find("/") == 1 then v.path = "" end
          local path = v.path .. v.icon
          widget.setImage("sipItemScroll.sipItemList." .. li .. ".itemIcon", path)
        elseif type(v.icon) == "table" then
          sip.setDrawableIcon("sipItemScroll.sipItemList." .. li .. ".itemIcon", v.icon[1])
          sip.setDrawableIcon("sipItemScroll.sipItemList." .. li .. ".itemIcon2", v.icon[2])
          sip.setDrawableIcon("sipItemScroll.sipItemList." .. li .. ".itemIcon3", v.icon[3])
        end
        count = count + 1
      end
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
  if not sip.searched then
    sip.searchTick = sip.searchTick - 1
    if sip.searchTick <= 0 then
      sip.searched = true
      sip.searchTick = sip.searchDelay
      sip.filter()
    end
  end
end

function sip.uninit()
  sip.showCategories(false)
end

function sip.search()
  sip.searchTick = sip.searchDelay
  sip.searched = false
end


function sip.filter()
  local filter = widget.getText(sip.widgets.search)
  if filter == sip.previousSearch then return end
  
  sip.previousSearch = filter
  
  sip.showItems()
end

--[[
  Spawns the given item in the given quantity.
  Does not check for validity.
  @param itemName - Identifier of the item to spawn.
  @param quantity - Amount of items to spawn. Loops every 1000 to work around the engine's limit.
]]
function sip.spawnItem(itemName, quantity)
  local it, rest = math.floor(quantity / 1000), quantity % 1000
  for i=1,it do
    player.giveItem({name=itemName, count=1000})
  end
  player.giveItem({name=itemName, count=rest})
end

--[[
  Returns the currently selected item, if any.
  @return - Item data, as stored in the item dump.
]]
function sip.getSelectedItem()
  local li = widget.getListSelected(sip.widgets.itemList)
  if not li then return nil end
  local item = widget.getData(sip.widgets.itemList .. "." .. li)
  return item
end

--[[
  Shows or hides the category display.
  @param bool - Value indicating whether to show (true) or hide (false) the categories.
]]
function sip.showCategories(bool)
  widget.setVisible(sip.widgets.categoryBackground, bool)
  widget.setVisible(sip.widgets.categoryScrollArea, bool)
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
  Sets to currently selected quantity of items to print to the given amount. Errors if the given value is not a number.
  Updates the displayed quantity.
  @param amnt - New quantity. Should be an integer.
]]
function sip.setQuantity(amnt)
  if type(amnt) ~= "number" then error("SIP: Attempted to set quantity to an invalid number. Please contact the mod author.") end
  sip.quantity = math.clamp(amnt, 0, 9999)

  widget.setText(sip.widgets.quantity, "x" .. sip.getQuantity())
end

--[[
  Adjusts the selected quantity of items to print by the given amount. Errors if the passed value is not a number.
  @param amnt - Amount to adjust the quantity with. Can be positive and negative. Should be an integer.
]]
function sip.adjustQuantity(amnt)
  if type(amnt) ~= "number" then error("SIP: Attempted to adjust quantity by an invalid number. Please contact the mod author.") end
  sip.setQuantity(sip.getQuantity() + amnt)
end

----------------------
-- Widget Callbacks --
----------------------

--[[
  Widget callback function. Used to toggle the category display.
]]
function sip.changeCategory()
  sip.changingCategory = not sip.changingCategory
  sip.showCategories(sip.changingCategory)
end

--[[
  Widget callback function. Uses the widget name to identify whether a category was selected or deselected.
  Shows items relevant to the category widget, by parsing it's widget data.
  @param w - Widget name.
  @param category - Widget data, structured "category" or ["category", "category2"].
]]
function sip.selectCategory(w, category)
  if sip.selectedCategory ~= w then
    sip.selectedCategory = w
    sip.showItems(category)
  else
    sip.selectedCategory = nil
    sip.categories = nil
    sip.showItems()
  end
end

--[[
  Widget callback function. Parses widget data. If this is a number, adjust quantity by it.
  If this is not a number, fetch quantity from the text field instead.
]]
function sip.changeQuantity(_, data)
  if type(data) == "number" then
    sip.adjustQuantity(data)
  else
    local str = widget.getText(sip.widgets.quantity):gsub("x","")
    local n = tonumber(str)
    if n then sip.setQuantity(n) end
  end  
end

--[[
  Widget callback function. Spawns the current quantity of the current item.
  If the max stack size of the item is 1, spawn 1 instead.
  Logs an error if this item could not be spawned, by checking if it has an item configuration.
  This step costs additional time, but shouldn't affect performance as the callback is only called every time the user presses print.
]]
function sip.print()
  local item, q = sip.getSelectedItem(), sip.getQuantity()
  if not item or not item.name then return end
  
  if not pcall(function()
    local cfg = root.itemConfig(item.name)
    if cfg.config and cfg.config.maxStack == 1 then
      q = 1
    end
  end) then
    sb.logError("SIP: Item configuration could not be loaded! Please report the following line to the mod author.\n%s", item)
  end
  
  sip.spawnItem(item.name, q)
end

function sip.changePage(_, data)
  -- TODO: Remove or implement pages and displaying of items per page. Performance seems decent enough not to require pages.
  -- Could be used at some point when the game or mods add so many items that performance destabilizes.
end

----------------------
-- Useful functions --
----------------------

--[[
  Logs environmental functions, tables and nested functions.
]]
function logENV()
  for i,v in pairs(_ENV) do
    if type(v) == "function" then
      sb.logInfo("%s", i)
    elseif type(v) == "table" then
      for j,k in pairs(v) do
        sb.logInfo("%s.%s (%s)", i, j, type(k))
      end
    end
  end
end

--[[
  Clamps and returns a value between the minimum and maximum value.
  @param i - Value to clamp.
  @param low - Minimum bound (inclusive).
  @param high - Maximum bound (inclusive).
  @return - i, low when i<low or high when i>high.
]]
function math.clamp(i, low, high)
  if low > high then low, high = high, low end
  return math.min(high, math.max(low, i))
end

--[[
  Creates and returns a set for the given table, using the values of the table as keys.
  @param list - Table containing string values.
  @return - Set
]]
--https://www.lua.org/pil/11.5.html
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end