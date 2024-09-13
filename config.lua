Config = {
    Framework = "QBCore", -- Set "QBCore" or "ESX" based on the framework being used
    ShovelObject = "prop_tool_shovel2",
    ShovelIdleBone = 57005,
    ShovelDiggingBone = 28422,

    ShovelAnimDict = "random@burial",
    ShovelAnim = "a_burial",

    ShovelIdlePlacement = {
        XCoords = 0.11,
        YCoords = 0.81,
        ZCoords = 0.37,
        XRotation = 119.99,
        YRotation = 0.0,
        ZRotation = 0.0,
    },

    ShovelDiggingPlacement = {
        XCoords = 0.0,
        YCoords = -0.08,
        ZCoords = -0.9,
        XRotation = 0.0,
        YRotation = 0.0,
        ZRotation = 0.0,
    },

    DigButton = 38,
    StopButton = 73,

    StartDiggingText = "~INPUT_PICKUP~ Bury",
    DiggingText = "~INPUT_PICKUP~ Bury\n~INPUT_VEH_DUCK~ Stop",

    ShovelItem = 'sandwich', -- Shovel item in inventory

    groundHashes = {
        [-1885547121] = {name = "Dirt", canDig = true},
        [282940568] = {name = "Road", canDig = false},
        [510490462] = {name = "Sand", canDig = true},
        [951832588] = {name = "Sand 2", canDig = true},
        [2128369009] = {name = "Grass and Dirt Combined", canDig = true},
        [-840216541] = {name = "Rock Surface", canDig = false},
        [-1286696947] = {name = "Grass and Dirt Combined 2", canDig = true},
        [1333033863] = {name = "Grass", canDig = true},
        [1187676648] = {name = "Concrete", canDig = false},
        [1144315879] = {name = "Grass 2", canDig = true},
        [-1942898710] = {name = "Gravel, Dirt, and Cobblestone", canDig = true},
        [560985072] = {name = "Sand Grass", canDig = true},
        [-1775485061] = {name = "Cement", canDig = false},
        [581794674] = {name = "Grass 3", canDig = true},
        [1993976879] = {name = "Cement 2", canDig = false},
        [-1084640111] = {name = "Cement 3", canDig = false},
        [-700658213] = {name = "Dirt with Grass", canDig = true},
        [0] = {name = "Air", canDig = false},
        [-124769592] = {name = "Dirt with Grass 4", canDig = true},
        [-461750719] = {name = "Dirt with Grass 5", canDig = true},
        [-1595148316] = {name = "Concrete 4", canDig = false},
        [1288448767] = {name = "Water", canDig = false},
        [765206029] = {name = "Marble Tiles", canDig = false},
        [-1186320715] = {name = "Pool Water", canDig = false},
        [1639053622] = {name = "Concrete 3", canDig = false},
    },
}

