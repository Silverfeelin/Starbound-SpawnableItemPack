# Spawnable Item Pack
Spawnable Item Pack (SIP) is an interface mod that allows you to spawn any item in the game for free, in quantities up to 9999.

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Features](#features)
- [Adding Items](https://github.com/Silverfeelin/Starbound-SpawnableItemPack/wiki/Adding-Items)
- [Potential Issues](#potential-issues)
- [Contributing](#contributing)

## Installation
* [Download](https://github.com/Silverfeelin/SpawnableItemPack/releases) the release for the current version of Starbound.
* Place the `SpawnableItemPack.pak` file in your mods folder (eg. `D:\Steam\steamapps\common\Starbound\mods\`). Overwrite the existing file if necessary.
* Optionally, place the `QuickbarMini.pak` in the same mods folder. This step is necessary if you don't have the mod (or StardustLib) yet.
 * This file is included in the zipped release.

## Usage
##### Opening the interface
* Open the matter manipulator upgrade panel.
* Select 'Open Spawnable Item Pack' from the available options.

Don't worry, the bundled [Quickbar Mini][qbm] mod ensures you still have access to the original functionality of the upgrade panel! This menu is used for the mod as it's multiplayer-friendly and can be accessed anywhere.

![Open MMU](https://raw.githubusercontent.com/Silverfeelin/SpawnableItemPack/master/readme/openInterface.png "Open the matter manipulator upgrade panel")

##### Using the interface
After opening the interface, you will be presented with a list of items. Note that the interface may take a second or two to load, as the item lists are being populated when you open the interface.

The functionality of the interface is shown in the below image.  
You can only select one category at once. Deselecting the current category is possible.
![Interface](https://raw.githubusercontent.com/Silverfeelin/SpawnableItemPack/master/readme/sip.png "Interface")

## Features
* View item information by selecting an item.
* Spawn any item in any quantity.
* Filter items by categories.
* Filter items by item identifiers or names.
* Filter items by rarities.
* Change settings such as the level of generated weapons.
* Randomize generated items before spawning them.
* Copy existing items by dragging them on the item slot.

## Potential Issues
* Game updates that remove items may cause issues, as the mod uses it's own item dump to populate lists.
* Game updates that add items requires an update to the item dump to show in SIP.

## Contributing
If you have any suggestions or feedback that might help improve this mod, please do post them [on the discussion page](http://community.playstarbound.com/resources/spawnable-item-pack-spawn-all-items-for-free.515/)!
You can also create pull requests and contribute directly to the mod!

[qbm]:(https://github.com/Silverfeelin/Starbound-Quickbar-Mini)
[qbmRelease]:(https://github.com/Silverfeelin/Starbound-Quickbar-Mini/releases)
