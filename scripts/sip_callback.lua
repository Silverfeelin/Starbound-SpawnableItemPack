sip.callback = sip.callback or {}

--- Reset search timer.
-- Each update searchTick is lowered by one. When this value reaches 0, the list will be filtered.
-- @see update
function sip.callback.search()
  sip.searchTick = sip.searchDelay
  sip.searched = false
end

--- Clears the text filter.
function sip.callback.clearText()
  widget.setText(sip.widgets.search, "")
  sip.searchTick = 0 -- force update immediately (well, 1 frame)
end

--- Toggles a rarity filter.
-- The item list is refreshed after the toggle.
-- @param _
-- @param rarity Lowercase rarity name.
function sip.callback.toggleRarity(_, rarity)
  sip.rarities[rarity] = not sip.rarities[rarity]
  status.setStatusProperty("sip.rarities", sip.rarities)
  sip.updateRarityFilters()
  sip.showItems()
end

--- Show or hide category panel.
function sip.callback.changeCategory()
  sip.changingCategory = not sip.changingCategory
  sip.showCategories(sip.changingCategory)
end

--- Shows items for a category.
-- @param w Widget name. Used to determine index.
-- @param category Category to select, structured "category" or ["category", "category2"].
function sip.callback.selectCategory(w, category)
  local cat, data = sip.getSelectedCategory()
  status.setStatusProperty("sip.selectedCategory", cat)
  if cat ~= -1 then
    sip.categories = data
    sip.showItems()
  else
    sip.categories = nil
    sip.showItems()
  end
end

--- Displays item information and options.
-- Shows option containers based on item type (weapon, clothing).
function sip.callback.selectItem()
  sip.item = sip.getSelectedItem()

  local config
  if sip.item then config = root.itemConfig(sip.item.name).config else return end

  -- Hide category overlay
  sip.changingCategory = false
  sip.showCategories(false)

  -- Show text
  widget.setText(sip.widgets.itemName, config.shortdescription or sip.item.name)
  widget.setText(sip.widgets.itemDescription, config.description or sip.lines.descriptionMissing)

  -- Rarity
  local rarity = sip.item.rarity and sip.item.rarity:lower() or "common"
  widget.setImage(sip.widgets.itemRarity, sip.rarityImages.flags[rarity])

  -- Item slot
  sip.randomizeItem()
  sip.showSpecifications(config)
end

--- Adjusts item quantity.
--  Parses widget data. If this is a number, adjust quantity by it.
-- If this is not a number, fetch quantity from the text field instead.
function sip.callback.changeQuantity(_, data)
  if type(data) == "number" then
    sip.adjustQuantity(data)
  else
    local str = widget.getText(sip.widgets.quantity):gsub("x","")
    local n = tonumber(str)
    if n then sip.setQuantity(n) end
  end
end

--- Changes the weapon level.
-- Parses widget data. If this is a number, adjust weapon level by it.
-- If this is not a number, fetch quantity from the text field instead.
-- Value is clamped between 1 and 10.
function sip.callback.changeWeaponLevel(_, data)
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

function sip.callback.selectWeaponElement(_, data)
  sip.randomizeItem()
end

function sip.callback.randomizeItem()
  sip.randomizeItem()
end

--- Selects a color option.
-- The selection option (index) is used by printed items.
-- @param _
-- @param data Color option index (starting at 1).
function sip.callback.selectClothingColor(_, data)
  if data then
    sip.colorOption = data
    sip.randomizeItem()
  end
end

--- Spawns the current quantity of the current item.
-- If the max stack size of the item is 1, spawn 1 instead.
-- Logs an error if this item could not be spawned, by checking if it has an item configuration.
function sip.callback.print()
  local item, q = sip.item, sip.getQuantity()
  if not item or not item.name then return end

  local cfg = root.itemConfig(item.name)

  sip.spawnItem(cfg.config, q)
end

--- Spawns the upgraded version of the item.
function sip.callback.printUpgrade()
  local item, q = sip.item, sip.getQuantity()
  if not item or not item.name then return end

  local cfg = root.itemConfig(item.name)
  if not sip_util.isUpgradeable(cfg.config) then return end

  sip.spawnItem(cfg.config, q, true)
end

--- Spawns a recipe for the current item, if the item supports a recipe.
function sip.callback.printBlueprint()
  local item = sip.item
  if item and item.name and sip_util.hasBlueprint(item.name) then
    player.giveItem({name=item.name .. "-recipe", count=1})
  end
end

--- Takes the item, or place an item to copy.
-- If no item is held, the item will be taken (without consuming it). This acts similar to print, but only (x1).
-- If an item is held, the selection is overwritten, allowing users to copy their existing items.
function sip.callback.takeItem()
  local swapItem = player.swapSlotItem()
  if not swapItem then
    -- Take the item
    local item = widget.itemSlotItem(sip.widgets.itemSlot)
    player.setSwapSlotItem(item)
  else
    -- Refresh to unselect previous item.
    sip.showItems()

    -- Place the item
    swapItem.count = 1
    sip.item = swapItem
    sip.setItemSlotItem(sip.widgets.itemSlot, swapItem)
    widget.setText(sip.widgets.itemDescription, sip.lines.copy)
    widget.setText(sip.widgets.itemName, swapItem.parameters and swapItem.parameters.shortdescription or sip.lines.copiedItem)
    widget.setImage(sip.widgets.itemRarity, sip.rarityImages.flags[swapItem.parameters and swapItem.parameters.rarity or "common"])

    sip.showSpecifications(nil)
  end
end

--- Shows all item of the given type.
-- @param _
-- @param t Widget data representing the type to show. Should be items or objects
function sip.callback.showType(_, t)
  if type(t) ~= "string" then error("SIP: Attempted to run sip.showType with a value other than a string.") end
  if not sip.knownCategories[t] then sb.logError("SIP: Could now show items for the type '%s'.", t) return end
  sip.categories = sip.knownCategories[t]
  sip.showItems()

  widget.setSelectedOption(sip.widgets.categoryGroup, -1)
end

function sip.callback.openEditor()
  if not sip.editor then return end
  --Get the item from the itemSlot
  local itemSlot = widget.itemSlotItem(sip.widgets.itemSlot)
  if not itemSlot then return end
  --loads the api
  if not itemeditork then
    pcall(require, "/api/itemeditork.lua")
  end

  --Get Quantity
  local quantity = sip.getQuantity() or 1
  itemConfig = root.itemConfig(itemSlot.name).config or {}
	if itemConfig.maxStack and itemConfig.maxStack < quantity then quantity = itemConfig.maxStack end

  --Open interface
  local finalItem = {name=itemSlot.name, count=quantity, parameters = itemSlot.parameters }
	itemeditork.open(finalItem)
end
