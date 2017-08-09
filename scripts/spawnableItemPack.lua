-- Global and shorthand.
spawnableItemPack = {}
sip = spawnableItemPack

-- Utility methods
require "/scripts/sip_util.lua"

-- Define callbacks
require "/scripts/sip_callback.lua"

--- (Event) Initializes SIP.
function init()
  -- Image paths for rarity border (common) and flag (commonFlag).
  sip.rarityImages = config.getParameter("assets.rarities")
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
  -- Stores last used search text for showItems. sip.filter modifies this.
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

  -- Load previous search filter
  sip.previousSearch = status.statusProperty("sip.previousSearch") or ""
  widget.setText("sipTextSearch", sip.previousSearch)
  sip.searched = true

  -- Load previous rarities
  sip.rarities = status.statusProperty("sip.rarities") or Set({"common", "uncommon", "rare", "legendary", "essential"})
  sip.updateRarityFilters()

  -- Load previous category
  -- Uses index, which means that the wrong category may be selected after installing/uninstalling mods.
  local cat = status.statusProperty("sip.selectedCategory") or -1
  if cat ~= -1 and widget.getData("sipCategoryScroll.sipCategoryGroup." .. cat) then
    -- Will call sip.selectCategory which will refresh items
    widget.setSelectedOption("sipCategoryScroll.sipCategoryGroup", cat)
  else
    sip.showItems()
  end
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
    local path = modFile:find("/") and modFile or ("/sipMods/" .. modFile)
    local items = root.assetJson(path)
    if #items > 0 then
      if root.itemConfig(items[1].name) then
        for i,v in ipairs(items) do
          table.insert(itemList, v)
        end
        sb.logInfo("SIP: Added items from '%s'.", path)
      else
        sb.logInfo("SIP: Skipped items from '%s'. Please update the item file.", path)
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
      if sip.shouldFilter() then
        sip.previousSearch = widget.getText(sip.widgets.search)
        status.setStatusProperty("sip.previousSearch", sip.previousSearch)
        sip.showItems()
      end
    end
  end
end

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

  -- Filter items
  local items = sip.items
  items = sip_util.filterByCategory(sip.items, sip.categories)
  items = sip_util.filterByRarity(items, sip.rarities)
  items = sip_util.filterByText(items, sip.previousSearch)

  -- Add filtered items
  for i,v in ipairs(items) do
    local li = widget.addListItem(sip.widgets.itemList)
    widget.setText(sip.widgets.itemList .. "." .. li .. ".itemName", "^shadow;^white;" .. v.shortdescription)
    widget.setData(sip.widgets.itemList .. "." .. li, v)
    widget.setImage(sip.widgets.itemList .. "." .. li .. ".itemRarity", sip.rarityImages.borders[v.rarity])

    sip.setListIcon(sip.widgets.itemList .. "." .. li .. ".itemIcon", v)
  end

  sb.logInfo("SIP: Done adding %s items to the list!",  #items)
end

--- Sets the item slot item.
-- @param w Item slot widget.
-- @param item Item descriptor or name.
-- @param[opt] params Item parameters.
function sip.setItemSlotItem(w, item, params)
  if not item then return end

  if type(w) == "string" then
    if type(item) == "string" then
      item = {name=item, parameters = params}
    end
    widget.setItemSlotItem(w, item)
  end
end

--- Sets the icon for a list items.
-- @param w Full widget path to the list item image widget.
-- @param item SIP item.
function sip.setListIcon(w, item)
  local directives = item.directives or ""
  sip.setDrawableIcon(w, item.path, item.icon, directives)
end

--- Clears the item selection.
-- Does not unset the selected list item.
function sip.clearPreview()
  widget.setItemSlotItem(sip.widgets.itemSlot, nil);
  widget.setText(sip.widgets.itemDescription, sip.lines.itemDetails)
  widget.setText(sip.widgets.itemName, sip.lines.noSelection)
  widget.setImage(sip.widgets.itemRarity, sip.rarityImages.flags["common"])

  sip.showSpecifications(nil)
end

--- Sets a drawable or regular image on the given image widget.
-- Drawable position is ignored.
-- @param wid - Image widget to apply the drawable to.
-- @param path - Item path.
-- @param drawable - Single drawable object or image path. Only the image parameter is used.
--  Image path can be relative or absolute. All below arguments will work.
--  path "/" drawable "assetMissing.png" || path "/" drawable "/assetMissing.png" || path "" drawable "/assetMissing.png"
function sip.setDrawableIcon(wid, path, drawable, directives)
  local image = type(drawable) == "table" and drawable.image or drawable or "/assetMissing.png"
  if image:find("/") == 1 then path = "" end
  directives = directives or ""
  widget.setImage(wid, path .. image .. directives)
end

--- Returns a value indicating whether the item list should be refreshed.
-- The value indicates whether the search text has changed, by comparing the entered text to sip.previousSearch.
-- sip.previousSearch should be updated before sip.showItems is called.
-- @return True if the items should be refreshed, false otherwise.
-- @see sip.previousSearch
function sip.shouldFilter()
  local filter = widget.getText(sip.widgets.search)
  return filter ~= sip.previousSearch
end

--- Spawns the selected item in the given quantity.
-- The item in the item slot is used.
-- @param[opt] itemConfig Item configuration (root.itemConfig().config).
-- @param[opt=1] quantity Amount of items to spawn. If maxStack = 1, then 1.
function sip.spawnItem(itemConfig, quantity)
  quantity = quantity or 1
  local item = widget.itemSlotItem(sip.widgets.itemSlot)

  if not itemConfig then
    itemConfig = root.itemConfig(item.name)
    itemConfig = itemConfig and itemConfig.config or {}
  end

  if itemConfig.maxStack == 1 then quantity = 1 end

  local maxItem = {name=item.name, count=1000, parameters = item.parameters }

  local it, rest = math.floor(quantity / 1000), quantity % 1000
  for i=1,it do
    player.giveItem(maxItem)
  end

  item.count = rest
  if item.count > 0 then
    player.giveItem(item)
  end
end

--- Randomizes the item slot item.
-- The selected details are used when randomizing (level/color/element).
-- @see sip.getSpawnItemParameters
function sip.randomizeItem()
  if sip.item then
    local params = sip.getSpawnItemParameters(root.itemConfig(sip.item.name).config)
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

--- Gets the currently selected item from the list.
-- If no item is selected in the list, the current item is returned.
-- @return - Item data, as stored in the item dump.
-- @see sip.widgets.itemList, sip.item
function sip.getSelectedItem()
  local li = widget.getListSelected(sip.widgets.itemList)
  if not li then return sip.item end
  local item = widget.getData(sip.widgets.itemList .. "." .. li)
  return item or sip.item
end

--- Shows or hides the category display.
-- @param bool - Value indicating whether to show the categories.
function sip.showCategories(bool)
  widget.setVisible(sip.widgets.categoryBackground, bool)
  widget.setVisible(sip.widgets.categoryScrollArea, bool)
end

--- Returns the currently selected category widget and data
-- @return The selected widget name (index), the widget data (categories).
function sip.getSelectedCategory()
  local opt = widget.getSelectedOption("sipCategoryScroll.sipCategoryGroup")
  return opt, widget.getData("sipCategoryScroll.sipCategoryGroup." .. opt)
end

-- Returns the currently selected quantity of items to print, or 1.
-- @return - Quantity of item to print.
-- @see sip.quantity
function sip.getQuantity()
  return sip.quantity or 1
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

--- Shows widgets depending on the given item config.
-- If the item can be dyed, show dye options. If the item can be leveled, show
-- the level and element options. If the item has a builderConfig, allow randomizing.
-- @param itemConfig Item configuration (root.itemConfig().config).
function sip.showSpecifications(itemConfig)
  local pane = nil

  local levelable = sip_util.isLevelableWeapon(itemConfig)

  -- Clothing or weapon?
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

  -- Show the proper pane and hide other panes.
  for _,v in pairs(sip.widgets.specificationPanes) do
    widget.setVisible(v, pane == v)
  end
end

--- Returns the selected weapon level.
-- If no level is entered, returns 1.
-- @return Weapon level, always a number.
function sip.getWeaponLevel()
  local str = widget.getText(sip.widgets.weaponLevel)
  return tonumber(str) or 1
end

--- Show weapon elements allowed in the given item config.
-- Parameters elementalType or builderConfig[n].elementalType are used to determine
-- what elements are allowed for the given item.
-- @param itemConfig Item configuration (root.itemConfig().config).
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

--- Enables buttons for the given weapon elements.
-- Elements not in the collection can't be selected by the user.
-- The previous selection will be cleared.
-- @param elements Array or set of elements, or nil for no elements.
function sip.enableWeaponElements(elements)
  elements = type(elements) == "table" and elements or
             type(elements) == "string" and { [elements] = true } or
             {}

  for k,v in pairs(sip.widgets.elementOptions) do
    widget.setOptionEnabled(sip.widgets.weaponElement, v, elements[k])
  end

  widget.setSelectedOption(sip.widgets.weaponElement, -1)
end

--- Returns the selected weapon element, if any.
-- @return Weapon element name, or nil.
function sip.getWeaponElement()
  local index = widget.getSelectedOption(sip.widgets.weaponElement)
  local d = widget.getData(sip.widgets.weaponElement .. "." .. index)
  return d
end

--- Updates available color options for an item.
-- Enables and disabled option buttons, and applies directives for the colors.
-- @param itemConfig Full item parameters
-- @see root.itemConfig
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

function sip.updateRarityFilters()
  local r = { "common", "uncommon", "rare", "legendary", "essential" }
  sip.rarities = sip.rarities or {}

  for _,v in ipairs(r) do
    local suffix = sip.rarities[v] and "" or "?brightness=-60"
    widget.setButtonImages("rarityFrame." .. v, {
      base = "/interface/sip/rarities/filters/" .. v .. ".png" .. suffix,
      hover = "/interface/sip/rarities/filters/" .. v .. ".png?brightness=15" .. suffix
    })
  end
end