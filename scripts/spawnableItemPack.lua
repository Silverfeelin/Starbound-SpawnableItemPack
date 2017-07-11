-- Global and shorthand.
spawnableItemPack = {}
sip = spawnableItemPack

-- Utility methods
require "/scripts/sip_util.lua"

--------------------------
-- Engine/MUI Callbacks --
--------------------------

--- (Event) Initializes SIP.
function init()
  -- Image paths for rarity border (common) and flag (commonFlag).
  sip.rarities = config.getParameter("assets.rarities")
  -- Widget paths.
  sip.widgets = config.getParameter("widgetNames")
  -- Categories
  sip.knownCategories = config.getParameter("knownCategories")

  -- Default color option button images for clothes. 'colorOptions' directives can be appended to each value.
  -- see sip_util.colorOptionDirectives
  sip.defaultColorButtonImages = config.getParameter("colorButtonImages")
  sip.defaultPressedColorButtonImages = config.getParameter("pressedColorButtonImages")

  -- Some translatable keys. I'm probably going to remove all only used for logging messages at some point.
  sip.lines = root.assetJson("/interface/sip/lines.json")
  sip.loadStaticText()

  -- If item has colorOptions, colorOption is used as 'colorIndex'.
  sip.colorOption = 0
  -- If weaponLevel has a value, it will be used as 'level'.
  sip.weaponLevel = nil
  -- If weaponElement has a value, it will be used as 'elementalType'.
  sip.weaponElement = nil

  -- Delay before searching after last keystroke.
  sip.searchDelay = 10
  sip.searchTick = sip.searchDelay
  sip.searched = true
  sip.previousSearch = ""

  -- Item collections
  sip.items = root.assetJson("/sipItemDump.json")
  sip.customItems = root.assetJson("/sipCustomItems.json")

  -- Simple check for the first custom item to exist. Will obviously not catch all missing items.
  -- If the first custom item does not exist, do not load /any/ custom items.
  if #sip.customItems == 0 then
    sip.customItems = nil
  else
    if not sip.customItems[1].name then
      sb.logError("SIP: Did not load custom items, as a custom item was found with no 'name' set.")
      sip.customItems = nil
    elseif not pcall(function()
      root.itemConfig(sip.customItems[1].name)
    end) then
      sb.logError("SIP: Did not load custom items, as the '%s' item could not be found.", sip.customItems[1].name)
      sip.customItems = nil
    else
      for k,v in ipairs(sip.customItems) do
        table.insert(sip.items, v)
      end
    end
  end

  sip.loadModItems(sip.items)

  sip.categories = nil
  sip.changingCategory = false
  sip.showCategories(false)
  sip.quantity = 1

  sip.clearPreview()

  -- Synchronize UI with script
  sip.previousSearch = ""
  sip.filter()
  sip.changeQuantity()

  local category, categoryData = sip.getSelectedCategory()
  if category then
    widget.setSize("sipCategoryIndex", {0,0})
    sip.selectCategory(category, categoryData)
  else
    sip.showItems()
  end

  local levelStr = widget.getText("sipSettingsScroll.weaponLevel")
  local weaponLevel = tonumber(levelStr)
  if weaponLevel then
    sip.weaponLevel = weaponLevel
  end

  --logENV()
end

--- Load static widget text.
-- Loads static text defined in sip.lines. Can be used to load text translated in 'lines.json'.
function sip.loadStaticText()
  widget.setText(sip.widgets.changeCategory, sip.lines.viewCategories)
  widget.setText(sip.widgets.showItems, sip.lines.showItems)
  widget.setText(sip.widgets.showObjects, sip.lines.showObjects)

  widget.setText(sip.widgets.labelSpecifications, sip.lines.specifications)
  widget.setText(sip.widgets.labelWeaponElement, sip.lines.element)
  widget.setText(sip.widgets.labelWeaponLevel, sip.lines.level)
  widget.setText(sip.widgets.labelClothingColor, sip.lines.color)
end

function sip.loadModItems(itemList)
  itemList = itemList or {}
  for _,modFile in ipairs(root.assetJson("/sipMods/load.config")) do
    local items = root.assetJson("/sipMods/" .. modFile)
    if #items > 0 then
      if pcall(function() root.itemConfig(items[1].name) end) then
        for i,v in ipairs(items) do
          table.insert(itemList, v)
        end
      sb.logInfo("SIP: Added items from '/sipMods/%s'.", modFile)
      end
    end
  end

  return itemList
end

--- (Event) Updates SIP.
-- Updates search timer. If timer expires, show filtered items.
function update(dt)
  -- Update search filter.
  if not sip.searched then
    sip.searchTick = sip.searchTick - 1
    if sip.searchTick <= 0 then
      sip.searched = true
      sip.searchTick = sip.searchDelay
      sip.filter()
    end
  end
end

--- (Event) Uninitializes SIP.
function uninit()
  sip.showCategories(false)
end

-------------------
-- SIP Functions --
-------------------

--- Shows items in a category.
-- Populates the item list with items for the given category, the previous categories or all categories.
-- Filters the list based on text input. Text filtering compares item shortdescription and item name with the input case-insensitive.
-- @param[opt] category String or array of strings representing categories.
--             With no argument supplied, uses the sip.categories value instead. If sip.categories is nil, displays all items filtered by text.
function sip.showItems(category)
  widget.clearListItems(sip.widgets.itemList)

  if type(category) == "boolean" and category == false then sip.categories = nil
  elseif type(category) ~= "table" and type(category) ~= "string" and type(category) ~= "nil" then error("SIP: Attempted to search for invalid category.")
  elseif type(category) ~= "nil" then sip.categories = category end

  local items = sip.items
  items = sip_util.filterByCategory(sip.items, sip.categories)
  items = sip_util.filterByText(items, sip.previousSearch)

  for i,v in ipairs(items) do
    local li = widget.addListItem(sip.widgets.itemList)
    widget.setText(sip.widgets.itemList .. "." .. li .. ".itemName", "^shadow;^white;" .. v.shortdescription)
    widget.setData(sip.widgets.itemList .. "." .. li, v)
    widget.setImage(sip.widgets.itemList .. "." .. li .. ".itemRarity", sip.rarities[v.rarity])

    sip.setListIcon(sip.widgets.itemList .. "." .. li .. ".itemIcon", v)
  end

  sb.logInfo("SIP: Done adding %s items to the list!",  #items)
end

function sip.setItemSlotItem(w, item, params)
  if not item then return end

  if type(w) == "string" then
    if type(item) == "string" then
      item = {name=item, parameters = params}
    end
    widget.setItemSlotItem(w, item)
  end
end

function sip.setListIcon(w, item)
  local directives = item.directives or ""
  sip.setDrawableIcon(w, item.path, item.icon, directives)
end

function sip.clearPreview()
  widget.setItemSlotItem(sip.widgets.itemSlot, nil);
  widget.setText(sip.widgets.itemDescription, sip.lines.itemDetails)
  widget.setText(sip.widgets.itemName, sip.lines.noSelection)
  widget.setImage(sip.widgets.itemRarity, sip.rarities["commonFlag"])

  sip.showSpecifications(nil)
end

--[[
  Sets a classic drawable formatted image or regular image on the given widget.
  @param wid - Image widget to apply the drawable to.
  @param path - Item path.
  @param drawable - Single drawable object or image path. Only the image parameter is used.
    Image path can be relative or absolute. All below arguments are valid.
    path "/" drawable "assetMissing.png" || path "/" drawable "/assetMissing.png" || path "" drawable "/assetMissing.png"
]]
function sip.setDrawableIcon(wid, path, drawable, directives)
  local image = drawable and drawable.image or drawable or "/assetMissing.png"
  if image:find("/") == 1 then path = "" end
  directives = directives or ""
  if not pcall(root.imageSize,path .. image) then image = "/assetMissing.png"; path = "" end
  widget.setImage(wid, path .. image .. directives)
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
  @param itemName Identifier of the item to spawn.
  @param itemConfig Full item configuration. Parameters are not used.
  @param quantity Amount of items to spawn. Loops every 1000 to work around the engine's limit.
]]
function sip.spawnItem(itemConfig, quantity)
  quantity = quantity or 1
  if itemConfig.maxStack == 1 then quantity = 1 end

  local item = widget.itemSlotItem(sip.widgets.itemSlot)

  local it, rest = math.floor(quantity / 1000), quantity % 1000
  for i=1,it do
    player.giveItem({name=itemName, count=1000, parameters = params })
  end

  player.giveItem(item)

  -- Refresh
  sip.randomizeItem()
end

function sip.randomizeItem()
  if sip.item then
    local params = sip.getSpawnItemParameters(sip_util.itemConfig(sip.item.name).config)
    sip.setItemSlotItem(sip.widgets.itemSlot, sip.item.name, params)
  end
end

function sip.getSpawnItemParameters(itemConfig)
  local params = {}
  if sip.weaponLevel then params.level = sip.weaponLevel end

  local elem = sip.getWeaponElement()
  if elem then params.elementalType = elem end
  if sip_util.isColorable(itemConfig) then params.colorIndex = sip.colorOption end

  return params
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

--- Set item quantity.
-- @param amnt New quantity
function sip.setQuantity(amnt)
  if type(amnt) ~= "number" then error("SIP: Attempted to set quantity to an invalid number. Please contact the mod author.") end
  sip.quantity = math.clamp(amnt, 0, 9999)

  widget.setText(sip.widgets.quantity, "x" .. sip.getQuantity())
end

--- Adjust item quantity.
-- @param amnt Amount to adjust the quantity with
function sip.adjustQuantity(amnt)
  if type(amnt) ~= "number" then error("SIP: Attempted to adjust quantity by an invalid number. Please contact the mod author.") end
  sip.setQuantity(sip.getQuantity() + amnt)
end

-- Widget Callbacks --
----------------------

--- Reset search timer.
-- Each update searchTick is lowered by one. When this value reaches 0, the list will be filtered.
-- @see update
function sip.search()
  sip.searchTick = sip.searchDelay
  sip.searched = false
end

--- Show or hide category panel.
function sip.changeCategory()
  sip.changingCategory = not sip.changingCategory
  sip.showCategories(sip.changingCategory)
end

--- Shows items for a category.
-- @param w Widget name. Used to determine index.
-- @param category Category to select, structured "category" or ["category", "category2"].
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
    sip.showItems(false)
  end
end

--- Displays item information and options.
-- Shows option containers based on item type (weapon, clothing).
function sip.selectItem()
  sip.item = sip.getSelectedItem()
  local config
  if sip.item then config = sip_util.itemConfig(sip.item.name).config else return end

  -- Hide category overlay
  sip.changingCategory = false
  sip.showCategories(false)

  -- Show text
  widget.setText(sip.widgets.itemName, config.shortdescription or sip.item.name)
  widget.setText(sip.widgets.itemDescription, config.description or sip.lines.descriptionMissing)

  -- Rarity
  local rarity = sip.item.rarity and sip.item.rarity:lower() or "common"
  widget.setImage(sip.widgets.itemRarity, sip.rarities[rarity .. "Flag"])

  -- Item slot
  sip.randomizeItem()
  sip.showSpecifications(config)
end

--- Adjusts item quantity.
--  Parses widget data. If this is a number, adjust quantity by it.
-- If this is not a number, fetch quantity from the text field instead.
function sip.changeQuantity(_, data)
  if type(data) == "number" then
    sip.adjustQuantity(data)
  else
    local str = widget.getText(sip.widgets.quantity):gsub("x","")
    local n = tonumber(str)
    if n then sip.setQuantity(n) end
  end
end

function sip.showSpecifications(itemConfig)
  local pane = nil

  local levelable = sip_util.isLevelableWeapon(itemConfig)

  if sip_util.isColorable(itemConfig) then
    pane = sip.widgets.specificationPanes.clothingPane
    sip.showClothingColors(itemConfig)
  elseif levelable then
    pane = sip.widgets.specificationPanes.weaponPane
    sip.showWeaponElements(itemConfig)
  end

  -- Allow rolling items with a 'builderConfig'
  local rollable = false
  if itemConfig and itemConfig.builderConfig then rollable = true end
  widget.setVisible(sip.widgets.dice, rollable)

  -- Ensure proper weapon level.
  if not levelable then
    sip.weaponLevel = nil
  elseif not sip.weaponLevel then
    sip.weaponLevel = sip.getWeaponLevel()
  end

  for _,v in pairs(sip.widgets.specificationPanes) do
    widget.setVisible(v, pane == v)
  end
end

--- Changes the weapon level.
-- Parses widget data. If this is a number, adjust weapon level by it.
-- If this is not a number, fetch quantity from the text field instead.
-- Value is clamped between 1 and 10.
function sip.changeWeaponLevel(_, data)
  local level = 1
  if type(data) == "number" then
    level = (sip.weaponLevel or 1) + data
  else
    local n = sip.getWeaponLevel()
    if n then
      level = n
    else return end
  end

  sip.weaponLevel = math.clamp(level, 1, 10)
  widget.setText(sip.widgets.weaponLevel, tostring(sip.weaponLevel))
  sip.randomizeItem()
end

function sip.getWeaponLevel()
  local str = widget.getText(sip.widgets.weaponLevel)
  return tonumber(str) or 1
end

function sip.selectWeaponElement(_, data)
  sip.randomizeItem()
end

function sip.showWeaponElements(itemConfig)
  local c = itemConfig
  if c.elementalType then
    sip.enableWeaponElements(c.elementalType)
  elseif c.builderConfig then
    local elements = {}
    for _,v in ipairs(c.builderConfig) do
      if v.elementalType then
        for _,w in ipairs(v.elementalType) do
          elements[w] = true
        end
      end
    end
    sip.enableWeaponElements(elements)
  else
    sip.enableWeaponElements(nil)
  end
end

function sip.enableWeaponElements(elements)
  elements = type(elements) == "table" and elements or
             type(elements) == "string" and { [elements] = true } or
             {}

  for k,v in pairs(sip.widgets.elementOptions) do
    widget.setOptionEnabled(sip.widgets.weaponElement, v, elements[k])
  end

  widget.setSelectedOption(sip.widgets.weaponElement, -1)
end

function sip.getWeaponElement()
  local index = widget.getSelectedOption(sip.widgets.weaponElement)
  local d = widget.getData(sip.widgets.weaponElement .. "." .. index)
  return d
end

--- Updates available color options for an item.
-- Enables and disabled option buttons, and applies directives for the colors.
-- @param itemConfig Full item parameters
-- @see sip_util.itemConfig
function sip.showClothingColors(itemConfig)
  local colors = itemConfig.colorOptions or {}
  for i=1,12 do
    widget.setOptionEnabled("paneClothing.clothingColor", i - 1, not not colors[i])
    local c = copyTable(sip.defaultColorButtonImages)
    local cp = copyTable(sip.defaultPressedColorButtonImages)
    if colors[i] then
      local d = sip_util.colorOptionDirectives(colors[i])
      for k,v in pairs(c) do
        c[k] = c[k] .. d
      end
      for k,v in pairs(cp) do
        cp[k] = cp[k] .. d
      end
    end

    widget.setButtonImages("paneClothing.clothingColor." .. (i - 1), c)
    widget.setButtonCheckedImages("paneClothing.clothingColor." .. (i - 1), cp)
  end

  widget.setSelectedOption("paneClothing.clothingColor", 0)
  sip.colorOption = 0
end

--- Selects a color option.
-- The selection option (index) is used by printed items.
-- @param _
-- @param data Color option index (starting at 1).
function sip.selectClothingColor(_, data)
  if data then
    sip.colorOption = data
    sb.logInfo("RAndomizing for clothing")
    sip.randomizeItem()
  end
end

--- Spawns the current quantity of the current item.
-- If the max stack size of the item is 1, spawn 1 instead.
-- Logs an error if this item could not be spawned, by checking if it has an item configuration.
function sip.print()
  local item, q = sip.getSelectedItem(), sip.getQuantity()
  if not item or not item.name then return end

  local cfg = sip_util.itemConfig(item.name)

  sip.spawnItem(cfg.config, q)
end

function sip.takeItem()
  if not player.swapSlotItem() then
    local item = widget.itemSlotItem(sip.widgets.itemSlot)
    player.setSwapSlotItem(item)
    sip.randomizeItem()
  end
end

--- Shows all item of the given type.
-- @param _
-- @param t Widget data representing the type to show. Should be items or objects
function sip.showType(_, t)
  if type(t) ~= "string" then error("SIP: Attempted to run sip.showType with a value other than a string.") end
  if not sip.knownCategories[t] then sb.logError("SIP: Could now show items for the type '%s'.", t) return end
  sip.showItems(sip.knownCategories[t])

  widget.setSelectedOption(sip.widgets.categoryGroup, -1)
end

--- Changes item pages.
-- NOT IMPLEMENTED
-- Widget callback function. Used to scroll between item pages when there's a set limit on the amount
-- of items displayed per page, and the amount of items to be listed exceeds this number.
-- @param _
-- @param data Widget data. -2 = First page. -1 = Previous page. 1 = Next page. 2 = Last page
function sip.changePage(_, data)
  -- TODO: Remove or implement pages and displaying of items per page. Performance seems decent enough not to require pages.
  -- Could be used at some point when the game or mods add so many items that performance destabilizes.
end
