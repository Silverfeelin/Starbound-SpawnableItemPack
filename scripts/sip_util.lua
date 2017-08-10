sip_util = {}

--- Returns a value indicating whether an item has color options.
-- @param itemConfig Item configuration (root.itemConfig().config).
-- @return True if the item supports color options.
function sip_util.isColorable(itemConfig)
  if itemConfig then
    return not not itemConfig.colorOptions
  end
  return false
end

--- Returns a value indicating whether an item is a levelable weapon.
-- TODO: More reliable way to determine if the item is a weapon.
-- @param itemConfig Item configuration (root.itemConfig().config).
-- @return True if the item is a levelable weapon.
function sip_util.isLevelableWeapon(itemConfig)
  if itemConfig then
    if itemConfig.level and not itemConfig.colorOptions then
      -- This is probably not the best check, but whatever.
      return true
    elseif itemConfig.itemTags then
      for k,v in ipairs(itemConfig.itemTags) do
        if v:lower() == "weapon" then
          return true
        end
      end
    end
  end

  return false
end

--- Filters the item list by categories.
-- Categories are identified by name, and are case insensitive.
-- @param list Item table, as stored in the item dump.
-- @param categories Category name or table with category names.
-- @return Filtered item list.
function sip_util.filterByCategory(list, categories)
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

-- Filters the item list by text.
-- Both item names and shortdescriptions are checked, case insensitive.
-- @param list Item table, as stored in the item dump.
-- @param text Text to filter by.
-- @return Filtered item list.
function sip_util.filterByText(list, text)
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

--- Filters the item list by rarity.
-- @param list Item table, as stored in the item dump.
-- @param rarities table with allowed rarities.
-- @return Filtered item list.
function sip_util.filterByRarity(list, rarities)
  if type(rarities) ~= "table" then error("SIP: Attempted to filter by invalid rarities.") end

  if #rarities > 0 then
    rarities = Set(rarities)
  end

  local results = {}
  for _,v in pairs(list) do
    local rarity = v.rarity and v.rarity:lower() or "common"
    if rarities[rarity] then
      table.insert(results, v)
    end
  end

  return results
end

--- Creates replace directives for the given color option.
-- @param colorOption Hex color dictionary (from=to)
-- @return Replace directives string.
function sip_util.colorOptionDirectives(colorOption)
  if type(colorOption) ~= "table" then return "" end

  local dir = "?replace"
  for k,v in pairs(colorOption) do
    dir = string.format("%s;%s=%s", dir, k, v)
  end

  return dir
end

if not math then math = {} end

--- Clamps and returns a number between the minimum and maximum value.
-- @param i Value to clamp.
-- @param low Minimum bound (inclusive).
-- @param high Maximum bound (inclusive).
-- @return Clamped number.
function math.clamp(i, low, high)
  if low > high then low, high = high, low end
  return math.min(high, math.max(low, i))
end

-- Creates a set for the given table, using the values of the table as keys.
-- https://www.lua.org/pil/11.5.html
-- @param list Table containing string values.
-- @return Set
function Set(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

--[[
  http://lua-users.org/wiki/CopyTable
]]
function copyTable(tbl)
    local copy
    if type(tbl) == 'table' then
        copy = {}
        for k,v in pairs(tbl) do
            copy[copyTable(k)] = copyTable(v)
        end
    else
        copy = tbl
    end
    return copy
end