spawnableItemPack = {}
sip = spawnableItemPack

function sip.init()
  mui.setTitle("^shadow;Spawnable Item Pack", "^shadow;Spawn anything, for free!")
  mui.setIcon("/interface/sip/icon.png")
end

function sip.update(dt)

end

function sip.uninit()

end

function sip.test()
  mui.setTitle("Test case success!")
end