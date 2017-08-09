sip.callback = sip.callback or {}

--- Reset search timer.
-- Each update searchTick is lowered by one. When this value reaches 0, the list will be filtered.
-- @see update
function sip.callback.search()
  sip.searchTick = sip.searchDelay
  sip.searched = false
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
    sip.showItems(category)
  else
    sip.categories = nil
    sip.showItems(false)
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
  widget.setImage(sip.widgets.itemRarity, sip.rarities[rarity .. "Flag"])

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

function sip.callback.takeItem()
  if not player.swapSlotItem() then
    local item = widget.itemSlotItem(sip.widgets.itemSlot)
    player.setSwapSlotItem(item)
  end
end

--- Shows all item of the given type.
-- @param _
-- @param t Widget data representing the type to show. Should be items or objects
function sip.callback.showType(_, t)
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
function sip.callback.changePage(_, data)
  -- TODO: Remove or implement pages and displaying of items per page. Performance seems decent enough not to require pages.
  -- Could be used at some point when the game or mods add so many items that performance destabilizes.
end
