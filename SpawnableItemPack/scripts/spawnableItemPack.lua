spawnableItemPack = {}
sip = spawnableItemPack

function sip.init()
  mui.setTitle("^shadow;Spawnable Item Pack", "^shadow;Spawn anything, for free!")
  mui.setIcon("/interface/sip/icon.png")
  sip.items = {}
  sip.categories = {}

  widget.addListItem("sipItemScroll.sipItemList")
end

function sip.update(dt)

end

function sip.uninit()

end

function sip.categorySelected()

end

function sip.search()

end

function sip.changePage(_, data)

end

function sip.print()

end