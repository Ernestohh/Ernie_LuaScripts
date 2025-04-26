-- Adrenaline Generators
local adrenalineGenerator = {
    -- Necromancy Adrenaline Generators
    necromancy = {
        {
            name = "Basic Attack",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Soul Sap",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Touch of Death",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Touch of Death (Living Death)",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        }
    },
    
    -- Magic Adrenaline Generators
    magic = {
        {
            name = "Wrack",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Impact",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Dragon Breath",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Greater Sonic Wave",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Shock",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Greater Concentrated Blast",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Combust",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Greater Chain",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Magma Tempest",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Corruption Blast",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        }
    },
    
    -- Ranged Adrenaline Generators
    ranged = {
        {
            name = "Piercing Shot",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Binding Shot",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Snipe",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Dazing Shot",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Demoralise",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Needle Strike",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Fragmentation Shot",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Greater Ricochet",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Corruption Shot",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        }
    },
    
    -- Melee Adrenaline Generators
    melee = {
        {
            name = "Slice",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Backhand",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Havoc",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Smash",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Greater Barge",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Sever",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Kick",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Punish",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Dismember",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Greater Fury",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Cleave",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Decimate",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Chaos Roar",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        }
    },
    
    -- Defensive Adrenaline Generators
    defensive = {
        {
            name = "Sacrifice",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Storm Shards",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        },
        {
            name = "Tuska's Wrath",
            buffId = nil,
            AB = nil,
            threshold = false,
            ultimate = false
        }
    }
}

-- Adrenaline Spenders
local adrenalineSpender = {
    -- Necromancy Adrenaline Spenders
    necromancy = {
        thresholds = {
            {
                name = "Finger of Death",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Bloat",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Spectral Scythe 1",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Spectral Scythe 2",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Spectral Scythe 3",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            }
        },
        ultimates = {
            {
                name = "Death Skulls",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Living Death",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            }
        }
    },
    
    -- Magic Adrenaline Spenders
    magic = {
        thresholds = {
            {
                name = "Asphyxiate",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Deep Impact",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Horror",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Detonate",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Wild Magic",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Smoke Tendrils",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            }
        },
        ultimates = {
            {
                name = "Omnipower",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Metamorphosis",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Tsunami",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Greater Sunshine",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            }
        }
    },
    
    -- Ranged Adrenaline Spenders
    ranged = {
        thresholds = {
            {
                name = "Snap Shot",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Tight Bindings",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Rout",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Rapid Fire",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Bombardment",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Shadow Tendrils",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            }
        },
        ultimates = {
            {
                name = "Deadshot",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Incendiary Shot",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Unload",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Greater Death's Swiftness",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            }
        }
    },
    
    -- Melee Adrenaline Spenders
    melee = {
        thresholds = {
            {
                name = "Slaughter",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Forceful Backhand",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Greater Flurry",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Hurricane",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Blood Tendrils",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Stomp",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Quake",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Destroy",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Assault",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            }
        },
        ultimates = {
            {
                name = "Overpower",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Massacre",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Meteor Strike",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Balanced Strike",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Berserk",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Pulverise",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Frenzy",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            }
        }
    },
    
    -- Defensive Adrenaline Spenders
    defensive = {
        thresholds = {
            {
                name = "Shatter",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Reprisal",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Devotion",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Revenge",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Reflect",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            },
            {
                name = "Debilitate",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false
            }
        },
        ultimates = {
            {
                name = "Guthix's Blessing",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Onslaught",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Ice Asylum",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Immortality",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Rejuvenate",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Barricade",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            },
            {
                name = "Natural Instinct",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = true
            }
        }
    }
}

local necromancyResourceAbilities = {
    generators = {
        residualSouls = {
            {
                name = "Soul Sap",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = false
            },
            {
                name = "Spectral Scythe 1",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = false,
                chance = 0.25
            },
            {
                name = "Spectral Scythe 2",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = false,
                chance = 0.25
            }
        },
        necrosis = {
            {
                name = "Touch of Death",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = false,
                amount = 4
            },
            {
                name = "Basic Attack (Living Death)",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = false,
                amount = 2
            }
        }
    },
    spenders = {
        residualSouls = {
            {
                name = "Soul Strike",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = false,
                cost = 1
            },
            {
                name = "Volley of Souls",
                buffId = nil,
                AB = nil,
                threshold = false,
                ultimate = false,
                cost = "ALL"
            }
        },
        necrosis = {
            {
                name = "Finger of Death",
                buffId = nil,
                AB = nil,
                threshold = true,
                ultimate = false,
                cost = 6
            }
        }
    }
}

local API = require("api")
print(API.Buffbar_GetAllIDs(true)[1])
-- Improved function to extract the ability name from text with color formatting
    function extractAbilityName(formattedText)
        -- Check if the input is nil first
        if not formattedText then
            return ""
        end
        
        -- Handle cases where the format is <col=XXXXX>TEXT (without closing tag)
        if formattedText:match("^<col=[^>]+>(.+)$") and not formattedText:match("</col>") then
            return formattedText:match("^<col=[^>]+>(.+)$")
        end
        
        -- Handle the standard case where the format is <col=XXXXX>TEXT</col>
        if formattedText:match("<col=[^>]+>.-</col>") then
            return formattedText:match("<col=[^>]+>(.-)</col>")
        end
        
        -- If no color formatting is found, return the original text
        return formattedText
    end
    
    -- Usage with your loop:
    for i = 0, 4 do 
        print("Ability bar " .. i+1)
        for j = 1, 14 do 
            local ability = API.GetABarInfo(i)[j]
            local rawName = ability.name
            local cleanName = extractAbilityName(rawName)
            print("Ability ".. j ..": " ..cleanName .. " id: ".. ability.id)
        end 
    end