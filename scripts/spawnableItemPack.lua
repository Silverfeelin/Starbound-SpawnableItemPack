spawnableItemPack = {}
sip = spawnableItemPack

--[[
  Reference list for image paths to inventory icon rarity borders.
]]
sip.rarities = {
  common = "/interface/inventory/grayborder.png",
  uncommon = "/interface/inventory/greenborder.png",
  rare = "/interface/inventory/blueborder.png",
  legendary = "/interface/inventory/purpleborder.png"
}

--[[
  Reference list for widget names sip uses.
]]
sip.widgets = {
  quantity = "sipTextQuantity",
  itemList = "sipItemScroll.sipItemList",
  search = "sipTextSearch",
  categoryBackground = "sipCategoryBackground",
  categoryScrollArea = "sipCategoryScroll",
  itemDescription = "sipLabelSelectionDescription",
  itemImage = "sipImageSelection",
  itemImage2 = "sipImageSelection2",
  itemImage3 = "sipImageSelection3"
}

sip.descriptionMissing = "No description could be found for this item."

--------------------------
-- Engine/MUI Callbacks --
--------------------------

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
  sip.showCategories(false)
  sip.quantity = 1
  
  -- Synchronize UI with script by checking the dimensions of an invisible widget.
  local category, categoryData = sip.getSelectedCategory()
  if category then
    widget.setSize("sipCategoryIndex", {0,0})
    sip.selectCategory(category, categoryData)
  else
    sip.showItems()
  end
  
  --logENV()
end

--[[
  Update function, called every game tick by MUI while the interface is opened.
  @param dt - Delay between this and the previous update tick.
]]
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

--[[
  Uninitializes SIP. Called by MUI when the interface is closed.
  May not be called properly when the MMU interface is closed directly.
]]
function sip.uninit()
  sip.showCategories(false)
end

-------------------
-- SIP Functions --
-------------------

--[[
  Populates the item list with items for the given category, the previous categories or all categories.
  Filters the list based on text input. Text filtering compares item shortdescription and item name with the input case-insensitive.
  @param [category] - String representing a category or table with strings representing a set of categories. Items matching one category will be listed.
    With no argument supplied, uses the sip.categories value instead. If sip.categories is nil, displays all items filtered by text.
]]
function sip.showItems(category) 
  widget.clearListItems(sip.widgets.itemList)
  
  if type(category) == "nil" then sip.categories = nil
  elseif type(category) ~= "table" and type(category) ~= "string" then error("SIP: Attempted to search for invalid category")
  else sip.categories = category end
  
  local items = sip.filterByCategory(sip.items, sip.categories)
  items = sip.filterByText(items, sip.previousSearch)

  for i,v in ipairs(items) do
    local li = widget.addListItem(sip.widgets.itemList)
    widget.setText(sip.widgets.itemList .. "." .. li .. ".itemName", "^shadow;^white;" .. v.shortdescription)
    widget.setData(sip.widgets.itemList .. "." .. li, v)
    widget.setImage("sipItemScroll.sipItemList." .. li .. ".itemRarity", sip.rarities[v.rarity])
    if type(v.icon) == "string" and v.icon ~= "null" then
      if v.icon:find("/") == 1 then v.path = "" end
      local path = v.path .. v.icon
      widget.setImage("sipItemScroll.sipItemList." .. li .. ".itemIcon", path)
    elseif type(v.icon) == "table" then
      sip.setDrawableIcon("sipItemScroll.sipItemList." .. li .. ".itemIcon", v.path, v.icon[1])
      sip.setDrawableIcon("sipItemScroll.sipItemList." .. li .. ".itemIcon2", v.path, v.icon[2])
      sip.setDrawableIcon("sipItemScroll.sipItemList." .. li .. ".itemIcon3", v.path, v.icon[3])
    end
  end
  
  sb.logInfo("SIP: Done adding " .. #items .. " items to the list!")
end

--[[
  Filters the given item list by the given category/categories.
  @param list - Item table, as stored in the item dump.
  @param categories - String representing a category name, or a table of strings representing a collection of categories.
    Items matching one or more category will pass this check.
]]
function sip.filterByCategory(list, categories)
  if categories == nil then return list end
  if type(categories) == "string" then categories = { [categories] = true }
  elseif type(categories) == "table" then categories = Set(categories)
  else error("SIP: Attempted to filter by an invalid category / invalid categories.") end
  
  local results = {}
  for _,v in pairs(list) do
    if categories[v.category:lower()] then
      table.insert(results, v)
    end
  end
  
  return results
end

--[[
  Filters the given item list by the given text. Both item names and shortdescriptions are checked.
  Checking is case-insensitive.
  @param list - Item table, as stored in the item dump.
  @param text - Text to filter by.
]]
function sip.filterByText(list, text)
  if type(text) ~= "string" then error("SIP: Attempted to filter by invalid text.") end
  if text == "" then return list end
  
  text = text:lower()
  
  local results = {}
  for _,v in pairs(list) do
    if v.shortdescription:lower():find(text) or v.name:lower():find(text) then
      table.insert(results, v)
    end
  end
  
  return results
end

--[[
  Sets a classic drawable formatted image on the given widget.
  @param wid - Image widget to apply the drawable to.
  @param path - Item path.
  @param drawable - Single drawable object. Only the image parameter is used.
]]
function sip.setDrawableIcon(wid, path, drawable)
  if not drawable or not drawable.image then drawable = { image = "/assetMissing.png" } end
  local image = drawable.image
  if image:find("/") == 1 then path = "" end
  widget.setImage(wid, path .. image)
end

--[[
  Gets and uses the current filter text input to filter the item list.
  Filtering checks item names and shortdescriptions case-insensitive.
]]
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
  Returns the currently selected category widget and data, or nil, by checking the
  dimensions of an invisible image widget that's used to keep track of the selection.
  This is necessary due to the currently/previously broken widget.getSelectedOption callback.
  Size[1] > Selected (1 = true, not 1 = false), defaults at image width which is 64.
    Unless this value is 1, we're selecting a category, and the selection can be ignored.
  Size[2] > Selection
    Matches the widget name / index of the selected radioGroup button. Only matters if Selected is true.
  @return - The widget name / index of the selected category button, or nil if no category is selected.
  @return - The widget data of the selected category button, or nil if no category is selected.
  ]]
function sip.getSelectedCategory()
  local index = widget.getSize("sipCategoryIndex")
  if index[1] ~= 1 then return nil end
  return index[2], widget.getData("sipCategoryScroll.sipCategoryGroup." .. index[2])
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

--[[
  Returns the game's item configuration for the given item, handling errors when an invalid item is given.
  Note that details are generally stored in returnValue.config. The parameter returnValue.parameters
  may also contain useful data.
  @param itemName - Item identifier used to spawn the item with (usually itemName or objectName).
  @return - Item configuration as root.itemConfig returns it, or nil if the item configuration could not be found.
]]
function sip.getItemConfig(itemName)
  local cfg
  if pcall(function()
    cfg = root.itemConfig(itemName)
  end) then
    return cfg
  else
    sb.logError("SIP: Item configuration could not be loaded! Please report the following line to the mod author.\n%s", item)
    return nil
  end
end

----------------------
-- Widget Callbacks --
----------------------

--[[
  Widget callback function. Resets the search timeout when a key was pressed.
  Each update searchTick is lowered by one. When this value reaches 0, the list will be filtered (see sip.update).
]]
function sip.search()
  sip.searchTick = sip.searchDelay
  sip.searched = false
end

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
  local index = widget.getSize("sipCategoryIndex")
  local selecting = index[1] == 0
  local selected = index[2]
  local newSelection = tonumber(w)
  
  if selecting or newSelection ~= selected then
    widget.setSize("sipCategoryIndex", {1, newSelection})
    sip.showItems(category)
  else
    widget.setSize("sipCategoryIndex", {0, -1})
    sip.categories = nil
    sip.showItems()
  end
end

--[[
  Widget callback function. Used to display item information on the currently selected item.
]]
function sip.itemSelected()
  local item = sip.getSelectedItem()
  local config
  if item then config = sip.getItemConfig(item.name) else return end
  -- Config is a parameter of the returned item config.. for reasons.
  config = config and config.config or {}
    
  widget.setText(sip.widgets.itemDescription, config.description or sip.descriptionMissing)
  
  if type(item.icon) == "string" and item.icon ~= "null" then
    if item.icon:find("/") == 1 then item.path = "" end
    local path = item.path .. item.icon
    widget.setImage("sipImageSelection", path)
    widget.setImage("sipImageSelection2", "/assetMissing.png")
    widget.setImage("sipImageSelection3", "/assetMissing.png")
    widget.setImage("sipImageSelectionIcon", path)
    widget.setImage("sipImageSelectionIcon2", "/assetMissing.png")
    widget.setImage("sipImageSelectionIcon3", "/assetMissing.png")
  elseif type(item.icon) == "table" then
    sip.setDrawableIcon("sipImageSelection", item.path, item.icon[1])
    sip.setDrawableIcon("sipImageSelection2", item.path, item.icon[2])
    sip.setDrawableIcon("sipImageSelection3", item.path, item.icon[3])
    sip.setDrawableIcon("sipImageSelectionIcon", item.path, item.icon[1])
    sip.setDrawableIcon("sipImageSelectionIcon2", item.path, item.icon[2])
    sip.setDrawableIcon("sipImageSelectionIcon3", item.path, item.icon[3])
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
  
  local cfg = sip.getItemConfig(item.name)
  if cfg and cfg.config.maxStack == 1 then q = 1 end
  
  sip.spawnItem(item.name, q)
end

--[[
  Widget callback function. Shows all item of the given type.
  @param _ - Widget name. Unused.
  @param t - Widget data representing the type to show. Should be items or objects
]]
function sip.showType(_, t)
  if type(t) ~= "string" then error("SIP: Attempted to run sip.showType with a value other than a string.") end
  local cats = {
    objects = { "materials", "liqitem", "supports", "railpoint", "decorative", "actionfigure", "artifact", "breakable", "bug", "crafting", "spawner", "door", "light", "storage", "furniture", "trap", "wire", "sapling", "seed", "other", "generic", "teleportmarker" },
    items = { "headwear", "chestwear", "legwear", "backwear", "headarmour", "chestarmour", "legarmour", "enviroprotectionpack", "broadsword", "fistweapon", "chakram", "axe", "dagger", "hammer", "spear", "shortsword", "whip", "melee", "ranged", "sniperrifle", "boomerang", "bow", "shotgun", "assaultrifle", "machinepistol", "rocketlauncher", "pistol", "grenadelauncher", "staff", "wand", "throwableitem", "shield", "vehiclecontroller", "railplatform", "upgrade", "shiplicense", "mysteriousreward", "toy", "clothingdye", "medicine", "drink", "food", "preparedfood", "craftingmaterial", "cookingingredient", "upgradecomponent", "smallfossil", "mediumfossil", "largefossil", "codex", "quest", "junk", "currency", "trophy", "tradingcard", "eppaugment", "petcollar", "musicalinstrument", "tool" }
  }
  if not cats[t] then sb.logError("SIP: Could now show items for the type '" .. t .. "'") return end
  sip.showItems(cats[t])
end

--[[
  NOT IMPLEMENTED
  Widget callback function. Used to scroll between item pages when there's a set limit on the amount
  of items displayed per page, and the amount of items to be listed exceeds this number.
  @param _ - Widget name; not used.
  @param data - Widget data. -2 = First page. -1 = Previous page. 1 = Next page. 2 = Last page.
]]
function sip.changePage(_, data)
  -- TODO: Remove or implement pages and displaying of items per page. Performance seems decent enough not to require pages.
  -- Could be used at some point when the game or mods add so many items that performance destabilizes.
end

-------------------
-- MUI Callbacks --
-------------------

--[[
  MUI Callback function. Called when the settings menu is opened.
  Sets the background body image to the default one of MUI.
]]
function sip.settingsOpened()
  widget.setImage("bgb", "/resources/blankbody.png")
  sip.showCategories(false)
end

--[[
  MUI Callback function. Called when the settings menu is closed.
  Sets the background body image to the default one of SIP.
]]
function sip.settingsClosed()
  widget.setImage("bgb", "/interface/sip/body.png")
  sip.showCategories(sip.changingCategory)
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
  @return - low when i<low, high when i>high, or i.
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