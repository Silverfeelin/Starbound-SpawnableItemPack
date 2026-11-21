function init()
  if not (starExtensions or root.assetJson("/player.config:genericScriptContexts").OpenStarbound) then
    update = nil
    script.setUpdateDelta(0)
    return
  end
end

function update()
  if input.bindDown("sip", "open") then
    local script = "/quickbar/spawnableItemPackLoader.lua"
    require(script)
    _SBLOADED[script] = nil
  end
end