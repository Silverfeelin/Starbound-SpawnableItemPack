spawnableItemPack = {}
sip = spawnableItemPack

sip.lines = root.assetJson("/interface/sip/lines.json")

--[[
  Reference list for image paths to inventory icon rarity borders.
]]
sip.rarities = {
  common = "/interface/inventory/itembordercommon.png",
  commonFlag = "/interface/sip/common.png",
  uncommon = "/interface/inventory/itemborderuncommon.png",
  uncommonFlag = "/interface/sip/uncommon.png",
  rare = "/interface/inventory/itemborderrare.png",
  rareFlag = "/interface/sip/rare.png",
  legendary = "/interface/inventory/itemborderlegendary.png",
  legendaryFlag = "/interface/sip/legendary.png",
  essential = "/interface/inventory/itemborderessential.png",
  essentialFlag = "/interface/sip/essential.png"
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
  itemName = "sipLabelSelectionName",
  itemDescription = "sipLabelSelectionDescription",
  itemRarity = "sipImageSelectionRarity",
  itemImage = "sipImageSelection",
  itemImage2 = "sipImageSelection2",
  itemImage3 = "sipImageSelection3"
}

sip.descriptionMissing = sip.lines.descriptionMissing

--------------------------
-- Engine/MUI Callbacks --
--------------------------

--[[
  Initializes SIP.
  This function is called every time SIP is opened from the MUI Main Menu.
]]
function sip.init()
  mui.setTitle("^shadow;" .. sip.lines.title, "^shadow;" .. sip.lines.subtitle)
  mui.setIcon("/interface/sip/icon.png")

  sip.gender = player.gender()

  sip.searchDelay, sip.searchTick = 10, 10
  sip.searched = true
  sip.previousSearch = ""

  sip.items = root.assetJson("/sipItemDump.json")
  sip.customItems = root.assetJson("/sipCustomItems.json")
  
  -- Simple check for the first custom item to exist. Will obviously not catch all missing items.
  -- If the first custom item does not exist, do not load /any/ custom items.
  if #sip.customItems == 0 then
    sip.customItems = nil
  else
    if not sip.customItems[1].name then
      sb.logError(sip.lines.customItemNameMissing)
      sip.customItems = nil
    elseif not pcall(function()
      root.itemConfig(sip.customItems[1].name)
    end) then
      sb.logError(sip.lines.customItemMissing, sip.customItems[1].name)
      sip.customItems = nil
    else
      for k,v in ipairs(sip.customItems) do
        table.insert(sip.items, v)
      end
    end
  end
  
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
  sip.showDummy(false)
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

  if type(category) == "boolean" and category == false then sip.categories = nil
  elseif type(category) ~= "table" and type(category) ~= "string" and type(category) ~= "nil" then error(sip.lines.categoryInvalid)
  elseif type(category) ~= "nil" then sip.categories = category end

  local items = sip.items
  items = sip.filterByCategory(sip.items, sip.categories)
  items = sip.filterByText(items, sip.previousSearch)

  for i,v in ipairs(items) do
    local li = widget.addListItem(sip.widgets.itemList)
    widget.setText(sip.widgets.itemList .. "." .. li .. ".itemName", "^shadow;^white;" .. v.shortdescription)
    widget.setData(sip.widgets.itemList .. "." .. li, v)
    widget.setImage(sip.widgets.itemList .. "." .. li .. ".itemRarity", sip.rarities[v.rarity])

    sip.setInventoryIcon({sip.widgets.itemList .. "." .. li .. ".itemIcon", sip.widgets.itemList .. "." .. li .. ".itemIcon2", sip.widgets.itemList .. "." .. li .. ".itemIcon3"}, v)
  end

  sb.logInfo(sip.lines.itemsAdded,  #items)
end

function sip.setInventoryIcon(widgets, item)
  local directives = item.directives or ""

  if type(item.icon) == "string" and item.icon ~= "null" then
      sip.setDrawableIcon(widgets[1], item.path, item.icon, directives)
      sip.setDrawableIcon(widgets[2])
      sip.setDrawableIcon(widgets[3])
    elseif type(item.icon) == "table" then
      sip.setDrawableIcon(widgets[1], item.path, item.icon[1], directives)
      sip.setDrawableIcon(widgets[2], item.path, item.icon[2], directives)
      sip.setDrawableIcon(widgets[3], item.path, item.icon[3], directives)
    end
end

function sip.setPreviewIcon(widgets, item)
  if type(item.icon) == "string" and item.icon ~= "null" then
    local category = item.category:lower()

    widget.setImage(widgets[1], "/assetMissing.png")
    widget.setImage(widgets[2], "/assetMissing.png")
    widget.setImage(widgets[3], "/assetMissing.png")

    if category == "headarmour" or category == "headwear" or category == "head" then
      sip.showDummy(true)
      widget.setVisible("sipImageDummyHead", true)
      sip.setDrawableIcon(widgets[1], item.path, "head.png:normal?replace;ffffff00=00000001;00000000=00000001", item.directives)
    elseif category == "chestarmour" or category == "chestwear" or category == "chest" then
      sip.showDummy(true)
      local cfg = sip.getItemConfig(item.name)
      local frames = cfg.config[sip.gender .. "Frames"]
      sip.setDrawableIcon(widgets[3], item.path, frames.backSleeve .. ":idle.1?replace;ffffff00=00000001;00000000=00000001", item.directives)
      sip.setDrawableIcon(widgets[2], item.path, frames.body .. ":idle.1?replace;ffffff00=00000001;00000000=00000001", item.directives)
      sip.setDrawableIcon(widgets[1], item.path, frames.frontSleeve .. ":idle.1?replace;ffffff00=00000001;00000000=00000001", item.directives)
    elseif category == "legarmour" or category == "legwear" or category == "legs" then
      sip.showDummy(true)
      local cfg = sip.getItemConfig(item.name)
      local frames = cfg.config[sip.gender .. "Frames"]
      sip.setDrawableIcon(widgets[2], item.path, frames .. ":idle.1?replace;ffffff00=00000001;00000000=00000001", item.directives)
    elseif category == "enviroprotectionpack" or category == "backwear" or category == "back" then
      sip.showDummy(true)
      local cfg = sip.getItemConfig(item.name)
      local frames = cfg.config[sip.gender .. "Frames"]
      sip.setDrawableIcon(widgets[3], item.path, frames .. ":idle.1?replace;ffffff00=00000001;00000000=00000001", item.directives)
    else
      -- Hide dummy
      sip.showDummy(false)

      -- Scan item configs for better image.
      local cfg = sip.getItemConfig(item.name)
      if not cfg then return end

      if cfg.config.animationParts then
        local path = nil
        local l = false
        for k,v in pairs(cfg.config.animationParts) do
          if not l then
            -- Lazy fix for displaying activeitems.
            local ignoreKeys = { muzzleFlash = true, swoosh = true, handleFullbright = true, detectorfullbright = true, gunfullbright = true, bladefullbright = true, beamorigin = true, chargeEffect = true, stone = true, middlefullbright = true, discunlit = true, disc = true, apexkey = true, aviankey = true, florankey = true, humankey = true, glitchkey = true, novakidkey = true, hylotlkey = true }
            if v ~= "" and not ignoreKeys[k] then
              l = true
              path = v
            end
          end
        end
        if not path then path = cfg.config.inventoryIcon end
        if path then
          if item.category == "shield" then
            sip.setDrawableIcon(widgets[1], item.path, path .. ":nearidle", item.directives)
          else
            sip.setDrawableIcon(widgets[1], item.path, path, item.directives)
          end
        end

      elseif cfg.config.orientations then
        local path = nil
        local img = cfg.config.orientations[1].image or cfg.config.orientations[1].dualImage or cfg.config.orientations[1].dualImage or cfg.config.orientations[1].leftImage or cfg.config.orientations[1].rightImage or (cfg.config.orientations[1].imageLayers and (cfg.config.orientations[1].imageLayers[1].image or cfg.config.orientations[1].imageLayers[1].dualImage))

        img = img:match(".-%.png")
        if img and img ~= "" then
          if item.frame then img = img .. ":" .. item.frame end
          sip.setDrawableIcon(widgets[1], item.path, img, item.directives)
        end
      elseif cfg.config.largeImage then
        sip.setDrawableIcon(widgets[1], item.path, cfg.config.largeImage, item.directives)
      elseif cfg.config.placementPreviewImage then
        sip.setDrawableIcon(widgets[1], item.path, cfg.config.placementPreviewImage, item.directives)
      elseif cfg.config.image then
        sip.setDrawableIcon(widgets[1], item.path, cfg.config.image, item.directives)
      elseif cfg.config.inventoryIcon then
        sip.setInventoryIcon(widgets, item)
        sb.logInfo(sip.lines.previewMissing, item)
      else
        error(sip.lines.imageError)
      end
    end
  end
end

function sip.clearPreview()
  local widgets = {"sipImageSelectionIcon", "sipImageSelectionIcon2", "sipImageSelectionIcon3", "sipImageSelection", "sipImageSelection2", "sipImageSelection3"}
  for _,v in ipairs(widgets) do
    widget.setImage(v, "/assetMissing.png")
  end
  widget.setText(sip.widgets.itemDescription, sip.lines.itemDetails)
  widget.setText(sip.widgets.itemName, sip.lines.noSelection)
  widget.setImage(sip.widgets.itemRarity, sip.rarities["commonFlag"])
  sip.showDummy(false)
end

function sip.showDummy(bool)
  widget.setVisible("sipImageDummyFrontArm", bool)
  widget.setVisible("sipImageDummyBackArm", bool)
  widget.setVisible("sipImageDummyBody", bool)
  widget.setVisible("sipImageDummyHead", bool)
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
  Filters the given item list by the given category/categories.
  @param list - Item table, as stored in the item dump.
  @param categories - String representing a category name, or a table of strings representing a collection of categories.
    Items matching one or more category will pass this check.
]]
function sip.filterByCategory(list, categories)
  if categories == nil then return list end
  if type(categories) == "string" then categories = { [categories] = true }
  elseif type(categories) == "table" then categories = Set(categories)
  else error(sip.lines.filterCategoryError) end

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
  if type(text) ~= "string" then error(sip.lines.filterTextError) end
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
  local weaponLevel = nil
  if not pcall(function()
    local cfg = root.itemConfig(itemName)
    
    if cfg.config then
      if cfg.config.level then
        weaponLevel = sip.weaponLevel
      elseif cfg.config.itemTags then
        -- Added check for "weapon" itemTag, since not all weapons that support the level parameter
        -- contain it in their default configuration.
        for k,v in ipairs(cfg.config.itemTags) do
          if v:lower() == "weapon" then
            weaponLevel = sip.weaponLevel
            goto done
          end
        end
        ::done::
      end
    end
  end) then
    sb.logError(sip.lines.spawnItemMissing, itemName)
    return
  end
  
  local params = nil
  if weaponLevel then params = { level = weaponLevel } end
  
  local it, rest = math.floor(quantity / 1000), quantity % 1000
  for i=1,it do
    player.giveItem({name=itemName, count=1000, parameters = params })
  end
  player.giveItem({name=itemName, count=rest, parameters = params })
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
  if type(sip.quantity) ~= "number" then error(sip.lines.quantityInvalid) end
  return sip.quantity
end

--[[
  Sets to currently selected quantity of items to print to the given amount. Errors if the given value is not a number.
  Updates the displayed quantity.
  @param amnt - New quantity. Should be an integer.
]]
function sip.setQuantity(amnt)
  if type(amnt) ~= "number" then error(sip.lines.setQuantityInvalid) end
  sip.quantity = math.clamp(amnt, 0, 9999)

  widget.setText(sip.widgets.quantity, "x" .. sip.getQuantity())
end

--[[
  Adjusts the selected quantity of items to print by the given amount. Errors if the passed value is not a number.
  @param amnt - Amount to adjust the quantity with. Can be positive and negative. Should be an integer.
]]
function sip.adjustQuantity(amnt)
  if type(amnt) ~= "number" then error(sip.lines.adjustQuantityInvalid) end
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
    sb.logError(sip.lines.itemConfigurationMissing, itemName)
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
    sip.showItems(false)
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

  -- Hide category overlay, to show the item.
  sip.changingCategory = false
  sip.showCategories(false)

  widget.setText(sip.widgets.itemName, item.shortdescription or config.shortdescription or item.name)
  widget.setText(sip.widgets.itemDescription, config.description or sip.descriptionMissing)

  local rarity = item.rarity and item.rarity:lower() or "common"
  widget.setImage(sip.widgets.itemRarity, sip.rarities[rarity .. "Flag"])

  local directives = item.directives or ""

  sip.setInventoryIcon({"sipImageSelectionIcon", "sipImageSelectionIcon2", "sipImageSelectionIcon3"}, item)
  sip.setPreviewIcon({"sipImageSelection", "sipImageSelection2", "sipImageSelection3"}, item)
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
  Widget callback function. Parses widget data. If this is a number, adjust quantity by it.
  If this is not a number, fetch quantity from the text field instead.
]]
function sip.changeWeaponLevel(_, data)
  local level = 1
  if type(data) == "number" then
    level = (sip.weaponLevel or 1) + data
  else
    local str = widget.getText("sipSettingsScroll.weaponLevel")
    local n = tonumber(str)
    if n then
      level = n
    else return end
  end
  
  sip.weaponLevel = math.clamp(level, 1, 10)
  widget.setText("sipSettingsScroll.weaponLevel", tostring(sip.weaponLevel))
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
  if type(t) ~= "string" then error(sip.lines.showTypeInvalid) end
  local cats = {
    objects = { "materials", "liqitem", "supports", "railpoint", "decorative", "actionfigure", "artifact", "breakable", "bug", "crafting", "spawner", "door", "light", "storage", "furniture", "trap", "wire", "sapling", "seed", "other", "generic", "teleportmarker" },
    items = { "headwear", "chestwear", "legwear", "backwear", "headarmour", "chestarmour", "legarmour", "enviroprotectionpack", "broadsword", "fistweapon", "chakram", "axe", "dagger", "hammer", "spear", "shortsword", "whip", "melee", "ranged", "sniperrifle", "boomerang", "bow", "shotgun", "assaultrifle", "machinepistol", "rocketlauncher", "pistol", "grenadelauncher", "staff", "wand", "throwableitem", "shield", "vehiclecontroller", "railplatform", "upgrade", "shiplicense", "mysteriousreward", "toy", "clothingdye", "medicine", "drink", "food", "preparedfood", "craftingmaterial", "cookingingredient", "upgradecomponent", "smallfossil", "mediumfossil", "largefossil", "codex", "quest", "junk", "currency", "trophy", "tradingcard", "eppaugment", "petcollar", "musicalinstrument", "tool" }
  }
  if not cats[t] then sb.logError(sip.lines.showTypeFailed, t) return end
  sip.showItems(cats[t])

  widget.setSelectedOption("sipCategoryScroll.sipCategoryGroup", -1)
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
  widget.setImage("bgb", "/interface/sip/settingsBody.png")
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

-- Thanks to Magicks
function player.id()
  local id = nil
  pcall(function()
    local uid = player.ownShipWorldId():match":(.+)"
    local pos =  world.findUniqueEntity(uid):result()
    id = world.entityQuery(pos,3,{order = "nearest",includedTypes = {"player"}})[1]
  end)
  return id
end
