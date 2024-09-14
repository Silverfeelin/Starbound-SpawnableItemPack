local config = root.assetJson("/interface/sip/sip.config")
local gui = config.gui
local categoryScroll = gui.sipCategoryScroll
local categoryGroup = categoryScroll.children.sipCategoryGroup
local categoryButtons = categoryGroup.buttons

local x, y, i = 1, 0, 0
local buttonOffset = {37, -25}
local labelOffset = {0, -8}

local addCategories = function(categories)
  for groupName, categories in pairs(categories) do
    -- Keep track of next widget location
    y = y - 8
    x = 1

    -- Create group label
    local labelUuid = sb.makeUuid()
    categoryScroll.children[labelUuid] = {
      type = "label",
      position = { x, y + 7 },
      hAnchor = "left",
      vAnchor = "top",
      zLevel = 22,
      value = "^white,shadow;" .. groupName
    }

    i = 0
    y = y + buttonOffset[2]

    for _, category in ipairs(categories) do
      -- After 4 category buttons, move to next row.
      if i >= 4 then
        i = 0
        y = y + buttonOffset[2]
      end

      -- Set horizontal position
      x = 1 + i * buttonOffset[1]
      i = i + 1

      -- Create button
      local categoryButton = {
        baseImage = category.image,
        hoverImage = category.image .. "?brightness=30",
        baseImageChecked = category.selectedImage,
        hoverImageChecked = category.selectedImage .. "?brightness=30",
        pressedOffset = {0, -1},
        fontSize = 6,
        wrapWidth = 40,
        position = {x, y},
        data = category.categories
      }

      -- Optional text
      if category.caption then categoryButton.text = category.caption end

      table.insert(categoryButtons, categoryButton)
    end
  end
end

-- Doing it this way ensures they are in the correct order
local categories = root.assetJson("/interface/sip/categories.config")
for i = 1, #categories do
  addCategories(categories[i])
end

addCategories(root.assetJson("/sipMods/categories.config"))

-- Position anchor at bottom (prevents last row from missing)
categoryScroll.children.sipCatoryAnchor2.position[2] = y - 1

-- Open interface
player.interact("ScriptPane", config)