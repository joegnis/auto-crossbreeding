# auto-crossbreeding

## Setup

**Robot upgrades:**

- Inventory Upgrade
- Inventory Controller Upgrade
- Redstone Card
- Geolyzer (block)
- Internet Card (if you want to install over internet, not necessary.)

**Robot inventory:**

You need to put a spade in the last slot of the robot (if you have multiple inventory upgrades, you may scroll down to reach the last slot.)

You need to put a transvector binder in the second last slot.

The crop sticks will end up in the third last slot. You don't need to put them manually. The robot will automatically retrieve them from crop stick container automatically if needed.

![robot inventory](readme_images/robot-inventory.png)

**Farm setup:**

Setup for crossbreeding:

**_The setup below is outdated, you should check the config file to see where you should put machines and containers._**

![setup for crossbreeding](readme_images/farm-birdview.png)

![the save as above but different view angle](readme_images/farm-normal-view.png)

Setup for min-maxing:

The setup is pretty much the same except you don't need the 13\*13 farmland on the left

Setup for spreading:
The script is completely re-written in this forked repository.
The usage guide can be found on [GTNH wiki](https://gtnh.miraheze.org/wiki/Open_Computers_Crop_Breeding).

## Config

Explanation in config.lua

## To Install

    wget https://raw.githubusercontent.com/joegnis/auto-crossbreeding/main/install.lua
    ./install.lua

```
Usage:
./install [-b|--branch BRANCH] [-u|--update-file FILE]
./install [-b|--branch BRANCH] [-c|--update-config]
./install --help | -h

Options:
  -b --branch BRANCH     Downloads from a specific branch. Default is main.
  -u --update-file FILE  Updates a specific file.
  -c --update-config     Updates all config files.
  -h --help              Shows this message.

By default, this script always (re)downloads all source files except for
config files. For config files, it downloads all missing ones but does
not download existing ones.

When it updates a config file, it backs up existing one before proceeding.
```

## To Run

For crossbreeding automatically:

    autoCrossbreed

## Development

To install dev branch:

    wget https://raw.githubusercontent.com/joegnis/auto-crossbreeding/dev/install.lua
    ./install.lua -b dev
