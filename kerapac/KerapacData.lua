local version = "8.3"

local partyLeader = nil -- replace nil with playername like this "Bob" 
local partyMembers = {} -- Add all player names including partyleader like this {"Bob", "Jo", "Mama"}
local bankPin = nil     -- replace nil with your bank pin like this 1234 don't add ""

local prayerType = {
    Curses = { name = "Curses" },
    Prayers = { name = "Prayers" }
}

local foodItems = {
    "Lobster", "Swordfish", "Desert sole", "Catfish", "Monkfish", "Beltfish", 
    "Ghostly sole", "Cooked eeligator", "Shark", "Sea turtle", "Great white shark", 
    "Cavefish", "Manta ray", "Rocktail", "Tiger shark", "Sailfish", 
    "Potato with cheese", "Tuna potato", "Baron shark", "Juju gumbo", 
    "Great maki", "Great gunkan", "Rocktail soup", "Sailfish soup", 
    "Fury shark", "Primal feast"
}

local emergencyFoodItems = {
    "Green blubber jellyfish", "Blue blubber jellyfish", 
    "2/3 green blubber jellyfish", "2/3 blue blubber jellyfish", 
    "1/3 green blubber jellyfish", "1/3 blue blubber jellyfish", 
}

local emergencyDrinkItems = {
    "Guthix rest (4)", "Guthix rest (3)", "Guthix rest (2)", "Guthix rest (1)",
    "Guthix rest flask (6)", "Guthix rest flask (5)", "Guthix rest flask (4)", "Guthix rest flask (3)", "Guthix rest flask (2)", "Guthix rest flask (1)",
    "Saradomin brew (4)", "Saradomin brew (3)", "Saradomin brew (2)", "Saradomin brew (1)",
    "Saradomin brew flask (6)", "Saradomin brew flask (5)", "Saradomin brew flask (4)", "Saradomin brew flask (3)", "Saradomin brew flask (2)", "Saradomin brew flask (1)",
    "Super Guthix rest (4)", "Super Guthix rest (3)", "Super Guthix rest (2)", "Super Guthix rest (1)",
    "Super Guthix rest flask (6)", "Super Guthix rest flask (5)", "Super Guthix rest flask (4)", "Super Guthix rest flask (3)", "Super Guthix rest flask (2)", "Super Guthix rest flask (1)",
    "Super Saradomin brew (4)", "Super Saradomin brew (3)", "Super Saradomin brew (2)", "Super Saradomin brew (1)",
    "Super Saradomin brew flask (6)", "Super Saradomin brew flask (5)", "Super Saradomin brew flask (4)", "Super Saradomin brew flask (3)", "Super Saradomin brew flask (2)", "Super Saradomin brew flask (1)"
}

local prayerRestoreItems = {
    "Super restore (4)", "Super restore (3)", "Super restore (2)", "Super restore (1)",
    "Super restore flask (6)", "Super restore flask (5)", "Super restore flask (4)", 
    "Super restore flask (3)", "Super restore flask (2)", "Super restore flask (1)",
    "Prayer potion (1)", "Prayer potion (2)", "Prayer potion (3)", "Prayer potion (4)",
    "Prayer flask (1)", "Prayer flask (2)", "Prayer flask (3)", "Prayer flask (4)", 
    "Prayer flask (5)", "Prayer flask (6)",
    "Super prayer (1)", "Super prayer (2)", "Super prayer (3)", "Super prayer (4)",
    "Super prayer flask (1)", "Super prayer flask (2)", "Super prayer flask (3)", 
    "Super prayer flask (4)", "Super prayer flask (5)", "Super prayer flask (6)",
    "Extreme prayer (1)", "Extreme prayer (2)", "Extreme prayer (3)", "Extreme prayer (4)",
    "Extreme prayer flask (1)", "Extreme prayer flask (2)", "Extreme prayer flask (3)", 
    "Extreme prayer flask (4)", "Extreme prayer flask (5)", "Extreme prayer flask (6)"
}

local overloadItems = {
    "Overload (4)", "Overload (3)", "Overload (2)", "Overload (1)",
    "Overload Flask (6)", "Overload Flask (5)", "Overload Flask (4)", 
    "Overload Flask (3)", "Overload Flask (2)", "Overload Flask (1)",
    "Holy overload (6)", "Holy overload (5)", "Holy overload (4)", 
    "Holy overload (3)", "Holy overload (2)", "Holy overload (1)",
    "Searing overload (6)", "Searing overload (5)", "Searing overload (4)", 
    "Searing overload (3)", "Searing overload (2)", "Searing overload (1)",
    "Overload salve (6)", "Overload salve (5)", "Overload salve (4)", 
    "Overload salve (3)", "Overload salve (2)", "Overload salve (1)",
    "Aggroverload (6)", "Aggroverload (5)", "Aggroverload (4)", 
    "Aggroverload (3)", "Aggroverload (2)", "Aggroverload (1)",
    "Holy aggroverload (6)", "Holy aggroverload (5)", "Holy aggroverload (4)", 
    "Holy aggroverload (3)", "Holy aggroverload (2)", "Holy aggroverload (1)",
    "Supreme overload salve (6)", "Supreme overload salve (5)", 
    "Supreme overload salve (4)", "Supreme overload salve (3)", 
    "Supreme overload salve (2)", "Supreme overload salve (1)",
    "Elder overload potion (6)", "Elder overload potion (5)", 
    "Elder overload potion (4)", "Elder overload potion (3)", 
    "Elder overload potion (2)", "Elder overload potion (1)",
    "Elder overload salve (6)", "Elder overload salve (5)", 
    "Elder overload salve (4)", "Elder overload salve (3)", 
    "Elder overload salve (2)", "Elder overload salve (1)",
    "Supreme overload potion (1)", "Supreme overload potion (2)", 
    "Supreme overload potion (3)", "Supreme overload potion (4)", 
    "Supreme overload potion (5)", "Supreme overload potion (6)"
}

local weaponPoisonItems = {
    "Weapon poison (1)", "Weapon poison (2)", "Weapon poison (3)", "Weapon poison (4)",
    "Weapon poison+ (1)", "Weapon poison+ (2)", "Weapon poison+ (3)", "Weapon poison+ (4)",
    "Weapon poison++ (1)", "Weapon poison++ (2)", "Weapon poison++ (3)", "Weapon poison++ (4)",
    "Weapon poison+++ (1)", "Weapon poison+++ (2)", "Weapon poison+++ (3)", "Weapon poison+++ (4)",
    "Weapon poison flask (1)", "Weapon poison flask (2)", "Weapon poison flask (3)", 
    "Weapon poison flask (4)", "Weapon poison flask (5)", "Weapon poison flask (6)",
    "Weapon poison+ flask (1)", "Weapon poison+ flask (2)", "Weapon poison+ flask (3)", 
    "Weapon poison+ flask (4)", "Weapon poison+ flask (5)", "Weapon poison+ flask (6)",
    "Weapon poison++ flask (1)", "Weapon poison++ flask (2)", "Weapon poison++ flask (3)", 
    "Weapon poison++ flask (4)", "Weapon poison++ flask (5)", "Weapon poison++ flask (6)",
    "Weapon poison+++ flask (1)", "Weapon poison+++ flask (2)", "Weapon poison+++ flask (3)", 
    "Weapon poison+++ flask (4)", "Weapon poison+++ flask (5)", "Weapon poison+++ flask (6)"
}

local summoningPouches = {
    "Blood nihil pouch", "Ice nihil pouch", "Shadow nihil pouch", "Smoke nihil pouch", 
    "Binding contract (ripper demon)", "Binding contract (kal'gerion demon)", 
    "Binding contract (blood reaver)", "Binding contract (hellhound)"
}

local extraItems = {
        excalibur = 14632,
        augmentedExcalibur = 36619
}

local extraAbilities = {
    darknessAbility = {
        name = "Darkness", 
        buffId = 30122, 
        AB = nil,
        threshold = 0
    },
    invokeDeathAbility = {
        name = "Invoke Death", 
        debuffId = 30100, 
        AB = nil,
        threshold = 0
    },
    splitSoulAbility = {
        name = "Split Soul", 
        buffId = 30126, 
        AB = nil,
        threshold = 0
    },
    devotionAbility = {
        name = "Devotion", 
        buffId = 21665, 
        AB = nil,
        threshold = 50,
        adrenaline = -15
    },
    debilitateAbility = {
        name = "Debilitate", 
        debuffId = 14226, 
        AB = nil,
        threshold = 50,
        adrenaline = -15
    },
    freedomAbility = {
        name = "Freedom", 
        buffId = 14220, 
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    reflectAbility = {
        name = "Reflect", 
        buffId = 14225, 
        AB = nil,
        threshold = 50,
        adrenaline = -15
    },
    resonanceAbility = {
        name = "Resonance", 
        buffId = 14222, 
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    preparationAbility = {
        name = "Preparation",
        buffId = 14223,
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    immortalityAbility = {
        name = "Immortality", 
        buffId = 14230, 
        AB = nil,
        threshold = 100,
        adrenaline = -100
    },
    sacrificeAbility = {
        name = "Sacrifice",
        AB = nil,
        threshold = 0,
        adrenaline = 8
    },
    necroBasicAbility = {
        name = "Necromancy basic attack",
        AB = nil,
        threshold = 0,
        adrenaline = 9
    },
    touchOfDeathAbility = {
        name = "Touch of Death",
        AB = nil,
        threshold = 0,
        adrenaline = 9
    },
    soulSapAbility = {
        name = "Soul Sap",
        AB = nil,
        threshold = 0,
        adrenaline = 9
    },
    volleyOfSoulsAbility = {
        name = "Volley of Souls",
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    conjureUndeadArmyAbility = {
        name = "Conjure Undead Army",
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    conjureSkeletonWarriorAbility = {
        name = "Conjure Skeleton Warrior",
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    conjureVengefulGhostAbility = {
        name = "Conjure Vengeful Ghost",
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    conjurePutridZombieAbility = {
        name = "Conjure Putrid Zombie",
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    commandSkeletonWarriorAbility = {
        name = "Command Skeleton Warrior",
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    commandVengefulGhostAbility = {
        name = "Command Vengeful Ghost",
        AB = nil,
        threshold = 0,
        adrenaline = 0
    },
    fingerOfDeathAbility = {
        name = "Finger of Death",
        AB = nil,
        threshold = 60,
        adrenaline = -60
    },
    bloatAbility = {
        name = "Bloat",
        AB = nil,
        threshold = 10,
        adrenaline = -10
    },
    deathGraspAbility = {
        name = "Death Grasp",
        AB = nil,
        threshold = 25,
        adrenaline = -25
    },
    deathEssenceAbility = {
        name = "Death Essence",
        AB = nil,
        threshold = 30,
        adrenaline = -30
    },
    deathSkullsAbility = {
        name = "Death Skulls",
        AB = nil,
        threshold = 100,
        adrenaline = -100
    },
    livingDeathAbility = {
        name = "Living Death",
        AB = nil,
        threshold = 100,
        adrenaline = -100
    },
}

local overheadPrayersBuffs = {
    PrayMage = { 
        name = "Protect from Magic", 
        buffId = 25959, 
        AB = nil
    },
    PrayMelee = { 
        name = "Protect from Melee", 
        buffId = 25961, 
        AB = nil
    }
}

local overheadCursesBuffs = {
    PrayMage = { 
        name = "Deflect Magic", 
        buffId = 26041, 
        AB = nil
    },
    PrayMelee = { 
        name = "Deflect Melee", 
        buffId = 26040, 
        AB = nil
    },
    SoulSplit = {
        name = "Soul Split",
        buffId = 26033,
        AB = nil
    }
}

local passiveBuffs = {
    Ruination = { 
        name = "Ruination", 
        buffId = 30769, 
        AB = nil,
        type = prayerType.Curses.name 
    },
    Sorrow = { 
        name = "Sorrow", 
        buffId = 30771, 
        AB = nil,
        type = prayerType.Curses.name 
    },
    Turmoil = { 
        name = "Turmoil", 
        buffId = 26019, 
        AB = nil,
        type = prayerType.Curses.name 
    },
    Malevolence = { 
        name = "Malevolence", 
        buffId = 29262, 
        AB = nil,
        type = prayerType.Curses.name 
    },
    Anguish = { 
        name = "Anguish", 
        buffId = 26020, 
        AB = nil,
        type = prayerType.Curses.name 
    },
    Desolation = { 
        name = "Desolation", 
        buffId = 29263, 
        AB = nil,
        type = prayerType.Curses.name 
    },
    Torment = { 
        name = "Torment", 
        buffId = 26021, 
        AB = nil,
        type = prayerType.Curses.name 
    },
    Affliction = { 
        name = "Affliction", 
        buffId = 29264, 
        AB = nil,
        type = prayerType.Curses.name 
    },
    Piety = { 
        name = "Piety", 
        buffId = 25973, 
        AB = nil,
        type = prayerType.Prayers.name 
    },
    Rigour = { 
        name = "Rigour", 
        buffId = 25982, 
        AB = nil,
        type = prayerType.Prayers.name 
    },
    Augury = { 
        name = "Augury", 
        buffId = 25974, 
        AB = nil,
        type = prayerType.Prayers.name 
    },
    Sanctity = { 
        name = "Sanctity", 
        buffId = 30925, 
        AB = nil,
        type = prayerType.Prayers.name 
    },
    None = {
        name = "None", 
        buffId = nil, 
        AB = nil, 
        type = nil
    }
}

local overloadBuff = {
    Overload = {
        buffId = 26093
    },
    ElderOverload = {
        buffId = 49039
    },
    SupremeOverload = {
        buffId = 33210
    }
}

local extraBuffs = {
    scriptureOfJas = {
        name = "Scripture of Jas", 
        itemId = 51814,
        buffId = 51814, 
        AB = nil
    },
    scriptureOfWen = {
        name = "Scripture of Wen", 
        itemId = 52117,
        buffId = 52117, 
        AB = nil
    },
    scriptureOfFul = {
        name = "Scripture of Ful", 
        itemId = 52494,
        buffId = 52494, 
        AB = nil
    },
    scriptureOfAmascut = {
        name = "Scripture of Amascut", 
        itemId = 57126,
        buffId = 57126, 
        AB = nil
    },
}

local bossStateEnum = {
    BASIC_ATTACK = { 
        name = "BASIC_ATTACK", 
        animations = { 34192 } 
    },
    TEAR_RIFT_ATTACK_COMMENCE = { 
        name = "TEAR_RIFT_ATTACK_COMMENCE", 
        animations = { 34198 } 
    },
    TEAR_RIFT_ATTACK_MOVE = { 
        name = "TEAR_RIFT_ATTACK_MOVE", 
        animations = { 34199 } 
    },
    JUMP_ATTACK_COMMENCE = { 
        name = "JUMP_ATTACK_COMMENCE", 
        animations = { 34193 } 
    },
    JUMP_ATTACK_IN_AIR = { 
        name = "JUMP_ATTACK_IN_AIR", 
        animations = { 34194 } 
    },
    JUMP_ATTACK_LANDED = {
        name = "JUMP_ATTACK_LANDED", 
        animations = { 34195 }
    },
    LIGHTNING_ATTACK = { 
        name = "LIGHTNING_ATTACK", 
        animations = { 34197 } 
    },
    PHASE4 = {
        name = "PHASE4",
        animations = {34201}
    }
}

local MARGIN = 100
local PADDING_Y = 6
local PADDING_X = 5
local LINE_HEIGHT = 12
local BOX_WIDTH = 280
local BOX_HEIGHT = 200
local BOX_START_Y = 600
local BOX_END_Y = BOX_START_Y + BOX_HEIGHT
local BOX_END_X = MARGIN + BOX_WIDTH + (2 * PADDING_X)
local BUTTON_WIDTH = 70
local BUTTON_HEIGHT = 25
local BUTTON_MARGIN = 8

local hpThreshold = 70
local prayerThreshold = 30
local emergencyEatThreshold = 50
local foodCooldown = 3
local drinkCooldown = 3
local phaseTransitionThreshold = 50000
local lootPosition = 5
local stun = 26103
local dodgeCooldown = 4
local distanceThreshold = 6
local proximityThreshold = 9
local weaponPoisonBuff = 30095
local waitForCheckTicks = 0
local playerClone = 28073
local kerapacClones = 28076
local summoningPointsForScroll = 20 -- change this to your scroll value

return {
    version = version,
    prayerType = prayerType,
    foodItems = foodItems,
    emergencyFoodItems = emergencyFoodItems,
    emergencyDrinkItems = emergencyDrinkItems,
    prayerRestoreItems = prayerRestoreItems,
    overloadItems = overloadItems,
    weaponPoisonItems = weaponPoisonItems,
    summoningPouches = summoningPouches,
    extraItems = extraItems,
    extraAbilities = extraAbilities,
    overheadPrayersBuffs = overheadPrayersBuffs,
    overheadCursesBuffs = overheadCursesBuffs,
    passiveBuffs = passiveBuffs,
    overloadBuff = overloadBuff,
    extraBuffs = extraBuffs,
    bossStateEnum = bossStateEnum,
    partyLeader = partyLeader,
    bankPin = bankPin,
    partyMembers = partyMembers,
    summoningPointsForScroll = summoningPointsForScroll,

    MARGIN = MARGIN,
    PADDING_Y = PADDING_Y, 
    PADDING_X = PADDING_X,
    LINE_HEIGHT = LINE_HEIGHT,
    BOX_WIDTH = BOX_WIDTH,
    BOX_HEIGHT = BOX_HEIGHT,
    BOX_START_Y = BOX_START_Y,
    BOX_END_Y = BOX_END_Y,
    BOX_END_X = BOX_END_X,
    BUTTON_WIDTH = BUTTON_WIDTH,
    BUTTON_HEIGHT = BUTTON_HEIGHT,
    BUTTON_MARGIN = BUTTON_MARGIN,

    hpThreshold = hpThreshold,
    prayerThreshold = prayerThreshold,
    emergencyEatThreshold = emergencyEatThreshold,
    foodCooldown = foodCooldown,
    drinkCooldown = drinkCooldown,
    phaseTransitionThreshold = phaseTransitionThreshold,
    lootPosition = lootPosition,
    stun = stun,
    dodgeCooldown = dodgeCooldown,
    distanceThreshold = distanceThreshold,
    proximityThreshold = proximityThreshold,
    weaponPoisonBuff = weaponPoisonBuff,
    waitForCheckTicks = waitForCheckTicks,
    playerClone = playerClone,
    kerapacClones = kerapacClones
}