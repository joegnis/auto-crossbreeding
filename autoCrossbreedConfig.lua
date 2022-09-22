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
    ---a list of crops to ignore saving when crossbreeding
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
