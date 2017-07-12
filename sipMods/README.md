This page will show you how to create a file that adds the items from any mod or asset folder to the Spawnable Item Pack interface.

If you're only trying to use the mod, please return to the [repository overview](https://github.com/Silverfeelin/Starbound-SpawnableItemPack).  
If you want to add your own category buttons to the interface, please see [Adding Categories](https://github.com/Silverfeelin/Starbound-SpawnableItemPack/wiki/Adding-Categories).

**Quick Navigation**

* [Known Limitations](#known-limitations)
* [Requirements](#requirements)
* [Creating the Item File](#creating-the-item-file)
* [Applying the Patch](#applying-the-patch)

### Known Limitations

* If the first item in your file doesn't exist in-game, no items from the file will be loaded. If the first item does exist, every item (including other items that don't exist) will be loaded. This is done to keep the load timers lower than they would otherwise be.
* Duplicate items are not filtered out. If mods overwrite existing items (or items are also present in other mods), these items will be listed twice.

### Requirements

To make a patch file, you'll need the following:

**<li>Spawnable Item Fetcher</li>** *(Requires [.NET Framework 4.5](https://www.microsoft.com/en-us/download/details.aspx?id=30653))*

You can find the tool in the [source code](https://github.com/Silverfeelin/Starbound-SpawnableItemPack/archive/master.zip) (`/SpawnableItemFetcher/build/`). Make sure you unpack the files.

**<li>Unpacked Mod</li>**

The mod you're trying to make a file for should be unpacked. If you have a packed mod, please [unpack it](http://community.playstarbound.com/threads/how-to-successfully-pack-and-unpack-pak-files.66649/) first.

On this page, Frackin' Universe 5.3.94 is used as an example.  
You can find Frackin' Universe by Sayter here: https://github.com/sayterdarkwynd/FrackinUniverse

### Creating the Item File

1. Run `SpawnableItemFetcher.exe`.
1. Enter the full path to your assets.  
I.e. `C:\Steam\steamapps\common\Starbound\mods\FrackinUniverse-5.3.94`
3. Enter the full path for your item file.  
I.e. `C:\Program Files\SpawnableItemFetcher\sipMods\frackinUniverse.json`
4. If the item file already exists, you will be asked to overwrite the file. Press <kbd>1</kbd> to overwrite, or any other key to cancel.
5. Choose whether you want to make a normal item file, or a patch file. The differences are explained later.
6. Wait until the application is done, and then check your item file.

![Generation progress](https://raw.githubusercontent.com/Silverfeelin/Starbound-SpawnableItemPack/master/wiki/fetcher-console.png)

---

For both file types, you must make sure your file is loaded after the Spawnable Item Pack mod. You can accomplish this by including the Spawnable Item Pack in your metadata file.  
[*What's a metadata file?*](http://starbounder.org/Modding:Basics)

```json
"includes" : [
  "SpawnableItemPack"
]
```


#### Item File

Choose this if you want to make and distribute an add-on. It requires a bit more setting up, but will cause less issues down the road.

The output file should be placed in the `sipMods` folder. Make sure you choose a name that won't cause conflicts with other mods.  
`/Starbound/mods/SIP-FUAddOn/sipMods/frackinUniverse.json`

You now need a patch file that tells the Spawnable Item Pack to load the items from this file. In the same `sipMods` folder, create the file `load.config.patch` with the following in it:

```json
[{"op":"add","path":"/-","value":"frackinUniverse.json"}]
```

Of course, make sure the file name (`value`) matches your file name.  
You can also put the item file in another location. If you choose to do this, please use the full asset path to the file as the value.

#### Patch File

Choose this if you want to quickly add some items.

The output file should be placed in the root of an asset / mod folder, named `sipCustomItems.json.patch`. You can also apply the same patch to item files from other mods.  
`/Starbound/mods/SIP-FUAddOn/sipCustomItems.json.patch`

---

You should now see the items in the Spawnable Item Pack. If you had your game open, make sure to restart it first.

![In-game result](https://raw.githubusercontent.com/Silverfeelin/Starbound-SpawnableItemPack/master/wiki/fetcher-furesult.png)
