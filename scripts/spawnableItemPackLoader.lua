local config = quickbarConfig
local gui = config.gui
local categoryScroll = gui.sipCategoryScroll
local categoryGroup = categoryScroll.children.sipCategoryGroup
local categoryButtons = categoryGroup.buttons

local modCategories = root.assetJson("/sipMods/categories.config")

local x, y, i = 1, -372, 0
local buttonOffset = {37, -25}
local labelOffset = {0, -8}

for groupName, categories in pairs(modCategories) do
  local labelUuid = sb.makeUuid()

  y = y - 8
  x = 1

  categoryScroll.children[labelUuid] = {
    type = "label",
    position = { x, y + 7 },
    hAnchor = "left",
    vAnchor = "top",
    zLevel = 22,
    value = "^white;^shadow;" .. groupName
  }

  i = 0
  y = y + buttonOffset[2]

  for _, category in ipairs(categories) do
    if i >= 4 then
      i = 0
      y = y + buttonOffset[2]
    end
    x = 1 + i * buttonOffset[1]
    i = i + 1

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

    if category.caption then categoryButton.text = category.caption end

    table.insert(categoryButtons, categoryButton)
  end
end

categoryScroll.children.sipCatoryAnchor2.position[2] = y - 1