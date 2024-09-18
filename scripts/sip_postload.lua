local files = {"item", "liqitem", "matitem", "miningtool", "flashlight", "wiretool", "beamaxe", "tillingtool", "painttool", "harvestingtool", "head", "chest", "legs", "back", "currency", "consumable", "blueprint", "inspectiontool", "instrument", "thrownitem", "unlock", "activeitem", "augment", "object", "codex"}

local paletteSwapDirective = function(color)
  local directive = "?replace"
  for key,val in pairs(color) do
    directive = directive .. ";" .. key .. "=" .. val
  end
  return directive
end

local cutColors = function(text) return text:gsub("(%^.-%;)", "") end

local categories = {}
local categoryList = assets.json("/interface/sip/categories.config")
for i = 1, #categoryList do
  for k, v in pairs(categoryList[i]) do
    for j = 1, #v do
      if v[j].categories then
        v[j].categories = type(v[j].categories) == "string" and {v[j].categories} or v[j].categories
        for l = 1, #v[j].categories do
          categories[v[j].categories[l]] = true
        end
      end
    end
  end
end

local addedItems = {}
local itemDumps = assets.json("/sipMods/load.config")
itemDumps[#itemDumps + 1] = "/sipItemDump.json"

for i = 1, #itemDumps do
  local target = itemDumps[i]:sub(1, 1) == "/" and itemDumps[i] or ("/sipMods/"..itemDumps[i])
  local currentItemList = assets.json(target)
--sb.logInfo("Searching "..itemDumps[i])
  for k, v in pairs(currentItemList) do
    if v.name then
      addedItems[v.name] = true
    end
  end
end
itemDumps = nil

local result = {}
for _, value in pairs(files) do
  local items = assets.byExtension(value)
  for _, item in pairs(items) do
    local itemData = assets.json(item)
    if itemData["hasObjectItem"] ~= false then
      local itemName = itemData.objectName or itemData.itemName or (itemData.id and itemData.id.."-codex")
      if not addedItems[itemName] then
        addedItems[itemName] = true

        local rarity = (itemData.rarity or "common"):lower()

        local icon = itemData.icon or (type(itemData.inventoryIcon) == "string" and itemData.inventoryIcon) or (itemData.inventoryIcon and itemData.inventoryIcon[1].image)
        if icon then
          icon = icon:gsub("<directives>", "")..(itemData.colorOptions and #itemData.colorOptions > 0 and paletteSwapDirective(itemData.colorOptions[1]) or "")
        end

        result[#result+1] = {
          path = item:gsub("/[^/]+$", "/"),
          fileName = item:match("/([^/]+)$"),
          name = itemName,
          --Items with no category (including objects automatically assigned the 'Other' category) and no icon go into the unsorted group, since they are likely to be technical items that don't need to be clogging up other categories. Otherwise, they go into the appropriate category
          category = (((not itemData.category or (itemData.category == "other")) and not icon) and "") or (itemData.category and categories[(itemData.category or "other"):lower()] and string.lower(itemData.category)) or value,
          icon = icon,
          shortdescription = itemData.shortdescription or itemData.title or itemName,
          rarity = rarity,
          race = itemData.race or itemData.species or "generic"
        }
      end
    end
  end
end

table.sort(result, function(a, b)
  a = cutColors(a.shortdescription):gsub(" ", ""); a = a == "" and a.name or a
  b = cutColors(b.shortdescription):gsub(" ", ""); b = b == "" and b.name or b
  return a < b
end)

local path = "/interface/sip/unsortedItemCategory.patch"
assets.add(path, assets.json("/interface/sip/sip.config:unsortedItemCategory"))
assets.patch("/interface/sip/categories.config", path)
assets.add("/sipDynamicItemDump.json", result)