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
    ./install

If you run ./install after the installation, it will update all the files except for config.lua

If you want to update config.lua also, you can run:

    ./install main updateconfig

If you want to install dev branch, you can run:

    ./install improve_autocrossbreed

## To Run

For crossbreeding automatically:

    autoCrossbreed

For min-maxing automatically:

    autoStat docleanup

For filling up an entire forestry multifarm:

    autoSpread docleanup

If you want to do mix-maxing before filling up the multifarm:

    autoStat && autoSpread
