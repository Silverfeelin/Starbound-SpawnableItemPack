sip_util = {}

--[[
  Returns the game's item configuration for the given item, handling errors when an invalid item is given.
  Note that details are generally stored in returnValue.config. The parameter returnValue.parameters
  may also contain useful data.
  @param itemName - Item identifier used to spawn the item with (usually itemName or objectName).
  @return - Item configuration as root.itemConfig returns it, or nil if the item configuration could not be found.
]]
function sip_util.itemConfig(itemName)
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

function sip_util.isColorable(itemConfig)
  if itemConfig then
    return not not itemConfig.colorOptions
  end
  return false
end

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

--[[
  Filters the given item list by the given category/categories.
  @param list - Item table, as stored in the item dump.
  @param categories - String representing a category name, or a set of strings representing a collection of categories.
    Items matching one or more category will pass this check.
]]
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

--[[
  Filters the given item list by the given text. Both item names and shortdescriptions are checked.
  Checking is case-insensitive.
  @param list - Item table, as stored in the item dump.
  @param text - Text to filter by.
]]
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

function sip_util.colorOptionDirectives(colorOption)
  if type(colorOption) ~= "table" then return "" end

  local dir = "?replace"
  for k,v in pairs(colorOption) do
    dir = string.format("%s;%s=%s", dir, k, v)
  end

  return dir
end

--[[
  Logs environmental functions, tables and nested functions.
  Less important now that we have the Lua documentation, but still useful.
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

if not math then math = {} end

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