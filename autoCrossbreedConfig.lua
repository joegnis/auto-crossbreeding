local config = {
    ---the side length of the crossbreeding farm
    ---the recommend value is 9 because it's crop-matron's working area size.
    breedFarmSize = 9,
    ---the side length of the new crop storage farm
    ---the recommend value is 13 because it's just enough to hold all the crops in GTNH
    storageFarmSize = 13,
    ---Whether to double check if a farm block is a farmland that can be placed with crop
    ---sticks. Non-farmland, e.g. water block, will be skipped when saving crops.
    checkStorageFarmland = true,
    checkBreedFarmland = true,
    ---Flag used when passing arg reportStorageCrops
    ---When set, robot will scan seeds in inventory at storagePos and extraSeedStoragePos
    ---if it is set.
    scansSeeds = true,
    ---Position of the extra inventory for seeds, e.g. filing cabinet.
    ---Used when passing arg reportStorageCrops.
    ---When set, seeds inside this inventory will be included in report.
    ---Comment out this option or set it to nil if you don't need it.
    ---This is EXTRA, meaning inventory at storagePos will always be scanned for seeds.
    extraSeedsStoragePos = {0, 7},
    ---A list of crops to ignore saving when crossbreeding
    ---they will not be transported to the storage farm
    ---use ./autoCrossbreed printStorageNames to scan and print an
    ---existing storage farm
    ---Only tested with English names
    cropsBlacklist = {
        "reed",
        "stickreed",
    }
}

return config
