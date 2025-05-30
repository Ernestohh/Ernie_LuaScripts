-- config.lua
SM:AddTab("General")                                                                -- Create a tab named General, populated by the elements below
SM:Checkbox("Enable Banking", "enableBanking", true)                                -- Will create a checkbox named Enable Banking, is referenced by CONFIG by enableBanking, is default true
SM:TextInput("Food Name", "foodName", "Shark")                                      -- Will create an input box named Food Name, is referenced by CONFIG by foodName, is default Shark
SM:Slider("Eat at HP %", "eatPercent", 0, 100, 50)                                  -- Will create a slider named Eat at HP %, is referenced by CONFIG by eatPercent, min value = 0, max value = 100, is default 50

SM:AddTab("Combat")                                                                 -- Create a tab named Combat, populated by the elements below
SM:Dropdown("Attack Style", "attackStyle", {"Melee", "Range", "Magic"}, "Melee")    -- Will create a dropdown named Attack Style, is referenced by CONFIG by attackStyle, dropdown info, is default Melee
SM:Checkbox("Use Prayers", "usePrayers", false)
SM:PasswordInput("Bank PIN", "bankPin", "")                                         -- Will create a password input named Bank PIN, is referenced by CONFIG by bankPin, is default empty (input is converted to ***)    

SM:AddTab("Advanced")                                                               -- Create a tab named Advanced, populated by the elements below
SM:NumberInput("Max Runtime (minutes)", "maxRuntime", 180, 1, 999)                  -- Will create a number input named Max Runtime (minutes), is referenced by CONFIG by maxRuntime, is default 180, 
                                                                                    -- min value = 1, max value = 999