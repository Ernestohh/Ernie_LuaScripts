-- Kerapac Configuration
SM:AddTab("General Settings")
SM:Dropdown("Passive Prayer/Curse", "selectedPassive", {"None", "Piety", "Rigour", "Augury", "Sanctity", "Turmoil", "Malevolence", "Anguish", "Desolation", "Torment", "Affliction", "Ruination", "Sorrow"}, "Turmoil")
SM:Checkbox("Hard Mode", "isHardMode", false)
SM:Checkbox("Adrenaline Crystal Unlocked", "hasAdrenalineCrystal", false)

SM:AddTab("Party Settings")
SM:Checkbox("In Party", "isInParty", false)
SM:Checkbox("Am I Party Leader", "isPartyLeader", false)
SM:TextInput("Party Leader Name", "partyLeader", "")
SM:TextInput("Party Members (comma separated)", "partyMembersText", "")

SM:AddTab("Combat Settings")
SM:NumberInput("HP Threshold %", "hpThreshold", 70, 1, 99)
SM:NumberInput("Prayer Threshold %", "prayerThreshold", 30, 1, 99)
SM:NumberInput("Emergency Eat Threshold %", "emergencyEatThreshold", 50, 1, 99)

SM:AddTab("Advanced Settings")
SM:TextInput("Discord Webhook URL", "discordWebhookUrl", "")
SM:TextInput("Discord User ID", "discordUserId", "")
SM:NumberInput("Bank PIN", "bankPin", 0, 0, 9999)