function init()
  if not (starExtensions or root.assetJson("/player.config:genericScriptContexts").OpenStarbound) then
    update = nil
    script.setUpdateDelta(0)
    return
  end

  player.setProperty("sip.paneOpen", false)
  player.setProperty("sip.closeRequest", false)
end

function update()
  if input.bindDown("sip", "open") then
    if player.getProperty("sip.paneOpen") then
      player.setProperty("sip.closeRequest", true)
      return
    end

    local script = "/quickbar/spawnableItemPackLoader.lua"
    require(script)
    _SBLOADED[script] = nil
  end
end
