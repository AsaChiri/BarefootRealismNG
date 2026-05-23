Scriptname PBFConfig extends SKI_ConfigBase Conditional

import PO3_SKSEFunctions

; Config variables

; Dirtiness
Float[] Property SurfaceDirtiness Auto
Float[] Property LocationDirtiness Auto
Float Property PositiveDeltaDirtinessMultiplier = 0.001 Auto
Float Property NegativeDeltaDirtinessMultiplier = 0.0005 Auto
Bool Property BarterDamageSpells = True Auto

; Roughness
Float[] Property SurfaceRoughness Auto
Float[] Property LocationRoughness Auto
Float Property RoughnessDecay = 0.005 Auto
Float Property RoughnessIncreaseMul = 0.1 Auto

Float[] SurfaceDirtinessDefault
Float[] LocationDirtinessDefault
Float[] SurfaceRoughnessDefault
Float[] LocationRoughnessDefault

Float PositiveDeltaDirtinessMultiplierDefault = 0.001
Float NegativeDeltaDirtinessMultiplierDefault = 0.0005
Float RoughnessDecayDefault = 0.005
Float RoughnessIncreaseMulDefault = 0.1


; Stagger
; Default is set so that the base chance is 0.1 at roughness 0 and 0.001 at roughness 1
Float Property StaggerMultiplier = 0.1 Auto
Float Property StaggerExponent = -4.6052 Auto
Float Property SprintingStaggerModifier = 2.0 Auto
Float Property WalkingStaggerModifier = 0.25 Auto
Float Property SneakingStaggerModifier = 0.1 Auto
Bool Property StaggerSound = True Auto

; Not really calibrated: after about 3 game hours of wandering around Whiterun and outskirts
; my character gets pain 0.18 which takes about a day to clear.
Float Property PainIncreaseMul = 0.01 Auto
Float Property PainIncreaseExp = 4.0 Auto
Float Property PainDecay = 0.25 Auto
Bool Property SpeedDamageSpells = True Auto

Float StaggerExponentDefault = -4.6052
Float StaggerMultiplierDefault = 0.1
Float SprintingStaggerModifierDefault = 2.0
Float WalkingStaggerModifierDefault = 0.25
Float SneakingStaggerModifierDefault = 0.1
Float PainDecayDefault = 0.01
Float PainIncreaseMulDefault = 0.01
Float PainIncreaseExpDefault = 4.0

; Miscellaneous
Bool Property AnkleCuffsPreventFootwear = True Auto
Bool Property AnkleCuffsAllowShoes = True Auto
Int Property VendorMode = 1 Auto Conditional
Int VendorModeDefault = 1
; The old single-Armor BarefootFootwearException was replaced by the BarefootRealism_BarefootException
; keyword, tagged on the worn item at runtime via PO3_SKSEFunctions.AddKeywordToForm (persists across
; saves) and distributable in bulk via BarefootRealism_KID.ini. Existing saves may log a benign
; "property not found" warning for the removed property; clean save optional.
Bool Property FootwearChangeableInCombat = True Auto

String[] SurfaceTypes
String[] LocationTypes
String[] VendorModes

; OIDs
Int[] SurfaceDirtinessOID
Int[] SurfaceRoughnessOID
Int[] LocationDirtinessOID
Int[] LocationRoughnessOID
Int PositiveDeltaDirtinessMultiplierOID
Int NegativeDeltaDirtinessMultiplierOID
Int BarterDamageSpellsOID

Int PainDecayOID
Int PainIncreaseMulOID
Int PainIncreaseExpOID
Int RoughnessDecayOID
Int RoughnessIncreaseMulOID
Int SpeedDamageSpellsOID

Int StaggerExponentOID
Int StaggerMultiplierOID
Int SprintingStaggerModifierOID
Int WalkingStaggerModifierOID
Int SneakingStaggerModifierOID
Int StaggerSoundOID

Int AnkleCuffsPreventFootwearOID
Int AnkleCuffsAllowShoesOID
Int FootwearChangeableInCombatOID

Int VendorModeOID
Int BarefootFootwearExceptionOID
Int BarefootFootwearExceptionSetOID
Int BarefootFootwearExceptionResetOID

; Globals for the debug menu
GlobalVariable Property FeetDirtiness Auto
GlobalVariable Property FeetRoughness Auto
GlobalVariable Property FeetPain Auto

GlobalVariable Property StepsBarefoot Auto
GlobalVariable Property PlayerIsBarefoot Auto
GlobalVariable Property PlayerCellType Auto
GlobalVariable Property PlayerLastSurfaceType Auto  
GlobalVariable Property PlayerLastSurfaceDirtiness Auto  

Function SetupStuff()
	SurfaceTypes = new String[9]
	SurfaceTypes[0] = "Stone"
	SurfaceTypes[1] = "Dirt"
	SurfaceTypes[2] = "Mud"
	SurfaceTypes[3] = "Wood"
	SurfaceTypes[4] = "Grass"
	SurfaceTypes[5] = "Snow"
	SurfaceTypes[6] = "Carpet"
	SurfaceTypes[7] = "Gravel"
	SurfaceTypes[8] = "Water"
	
	LocationTypes = new String[5]
	LocationTypes[0] = "Home"
	LocationTypes[1] = "Mine/prison"
	LocationTypes[2] = "City"
	LocationTypes[3] = "Dungeon"
	LocationTypes[4] = "Wilderness"
	
	VendorModes = new String[3]
	VendorModes[0] = "Ignore"
	VendorModes[1] = "Low clothing value"
	VendorModes[2] = "No shoes, no service"
	
	LocationDirtinessDefault = new Float[5]
	LocationDirtinessDefault[0] = 1.0
	LocationDirtinessDefault[1] = 1.5
	LocationDirtinessDefault[2] = 2.0
	LocationDirtinessDefault[3] = 2.0
	LocationDirtinessDefault[4] = 2.5
	
	LocationRoughnessDefault = new Float[5]
	LocationRoughnessDefault[0] = 0.1
	LocationRoughnessDefault[1] = 1.2
	LocationRoughnessDefault[2] = 1.0
	LocationRoughnessDefault[3] = 1.5
	LocationRoughnessDefault[4] = 1.5

	SurfaceDirtinessDefault = new Float[9]
	SurfaceDirtinessDefault[0] = 0.2
	SurfaceDirtinessDefault[1] = 0.4
	SurfaceDirtinessDefault[2] = 1.0
	SurfaceDirtinessDefault[3] = 0.2
	SurfaceDirtinessDefault[4] = 0.3
	SurfaceDirtinessDefault[5] = 0.1
	SurfaceDirtinessDefault[6] = 0.05
	SurfaceDirtinessDefault[7] = 0.2
	SurfaceDirtinessDefault[8] = -5.0
	
	SurfaceRoughnessDefault = new Float[9]
	SurfaceRoughnessDefault[0] = 0.4
	SurfaceRoughnessDefault[1] = 0.2
	SurfaceRoughnessDefault[2] = 0.1
	SurfaceRoughnessDefault[3] = 0.2
	SurfaceRoughnessDefault[4] = 0.1
	; Gravel (7 at 1.0) and snow (5 at 0.7) were way too painful (at roughness 0 it would take
	; 100 steps on gravel to get to max pain so I've bumped these defaults down to 0.6 and 0.5, respectively.
	; Now gravel is about 7 times more manageable to walk on with roughness 0.
	SurfaceRoughnessDefault[5] = 0.5
	SurfaceRoughnessDefault[6] = 0.05
	SurfaceRoughnessDefault[7] = 0.6
	SurfaceRoughnessDefault[8] = 0.05
EndFunction

Function SetupPages()
	ModName = "Barefoot Realism"
	Pages = new string[5]	
	Pages[0] = "Dirtiness"
	Pages[1] = "Roughness"
	Pages[2] = "Pain and Stagger"
	Pages[3] = "Miscellaneous"
	Pages[4] = "Debug"
EndFunction

Event OnConfigInit()
	SetupPages()
	SetupStuff()
	SurfaceDirtinessOID = new Int[9]
	SurfaceRoughnessOID = new Int[9]
	LocationDirtinessOID = new Int[5]
	LocationRoughnessOID = new Int[5]
EndEvent

Event OnConfigRegister()
	; Who knows why FeetPain is nonzero at game start
	FeetPain.SetValue(0)
	FeetDirtiness.SetValue(0)
	FeetRoughness.SetValue(0)
EndEvent

Event OnPageReset(string page)
	If (page == "Dirtiness")
		SetCursorFillMode(TOP_TO_BOTTOM)
		AddHeaderOption("Surface Dirtiness")
		
		Int i = 0
		While i < 9
			SurfaceDirtinessOID[i] = AddSliderOption(SurfaceTypes[i], SurfaceDirtiness[i], "{2}")
			i += 1
		EndWhile
		
		AddHeaderOption("Location Dirtiness")
		i = 0
		While i < 5
			LocationDirtinessOID[i] = AddSliderOption(LocationTypes[i], LocationDirtiness[i], "{2}")
			i += 1
		EndWhile
		
		AddHeaderOption("Dirtiness Rate")
		PositiveDeltaDirtinessMultiplierOID = AddSliderOption("When surface dirtiness greater than feet", PositiveDeltaDirtinessMultiplier, "{5}")
		NegativeDeltaDirtinessMultiplierOID = AddSliderOption("When surface dirtiness less than feet", NegativeDeltaDirtinessMultiplier, "{5}")
		BarterDamageSpellsOID = AddToggleOption("Drain barter spells", BarterDamageSpells)
	ElseIf (page == "Roughness")
		SetCursorFillMode(TOP_TO_BOTTOM)
		AddHeaderOption("Surface Roughness")
		
		Int i = 0
		While i < 9
			SurfaceRoughnessOID[i] = AddSliderOption(SurfaceTypes[i], SurfaceRoughness[i], "{2}")
			i += 1
		EndWhile
		
		AddHeaderOption("Location Roughness")
		
		i = 0
		While i < 5
			LocationRoughnessOID[i] = AddSliderOption(LocationTypes[i], LocationRoughness[i], "{2}")
			i += 1
		EndWhile
		
		AddHeaderOption("Feet Roughness")
		RoughnessIncreaseMulOID = AddSliderOption("Increase per pain increase", RoughnessIncreaseMul, "{2}")
		RoughnessDecayOID = AddSliderOption("Decay rate per game day", RoughnessDecay, "{4}")
	ElseIf (page == "Pain and Stagger")
		SetCursorFillMode(TOP_TO_BOTTOM)
		
		AddHeaderOption("Pain")
		PainDecayOID = AddSliderOption("Decay rate per game day", PainDecay, "{4}")
		PainIncreaseMulOID = AddSliderOption("Increase multipler", PainIncreaseMul, "{3}")
		PainIncreaseExpOID = AddSliderOption("Increase exponent", PainIncreaseExp, "{2}")
		SpeedDamageSpellsOID = AddToggleOption("Drain speed spells", SpeedDamageSpells)
		
		AddHeaderOption("Stagger")		
		StaggerMultiplierOID = AddSliderOption("Stagger multipler", StaggerMultiplier, "{3}")
		StaggerExponentOID = AddSliderOption("Stagger exponent", StaggerExponent, "{4}")
		SprintingStaggerModifierOID = AddSliderOption("Sprinting Chance Multiplier", SprintingStaggerModifier, "{2}")
		WalkingStaggerModifierOID = AddSliderOption("Walking Chance Multiplier", WalkingStaggerModifier, "{2}")
		SneakingStaggerModifierOID = AddSliderOption("Sneaking Chance Multiplier", SneakingStaggerModifier, "{2}")
		StaggerSoundOID = AddToggleOption("Stagger Pain Sound", StaggerSound)
		
	ElseIf (page == "Miscellaneous")
		SetCursorFillMode(TOP_TO_BOTTOM)
		AddHeaderOption("Equipment")
		
		AnkleCuffsPreventFootwearOID = AddToggleOption("Ankle cuffs prevent wearing footwear", AnkleCuffsPreventFootwear)
		AnkleCuffsAllowShoesOID = AddToggleOption("Ankle cuffs allow shoes", AnkleCuffsAllowShoes)
		FootwearChangeableInCombatOID = AddToggleOption("Footwear changeable in combat", FootwearChangeableInCombat)
		
		AddHeaderOption("Interactions")
		VendorModeOID = AddMenuOption("Vendor reaction", VendorModes[VendorMode])
		
		AddHeaderOption("Exceptions")
		Armor bfeWorn = Game.GetPlayer().GetWornForm(0x00000080) as Armor
		Keyword bfeKw = Keyword.GetKeyword("BarefootRealism_BarefootException")
		String bfeLabel = "(no footwear worn)"
		if bfeWorn
			if bfeKw && bfeWorn.HasKeyword(bfeKw)
				bfeLabel = bfeWorn.GetName() + " (counts as barefoot)"
			else
				bfeLabel = bfeWorn.GetName()
			endif
		endif
		BarefootFootwearExceptionOID = AddTextOption("Worn footwear", bfeLabel, OPTION_FLAG_DISABLED)
		BarefootFootwearExceptionSetOID = AddTextOption("Set worn as barefoot exception", "")
		BarefootFootwearExceptionResetOID = AddTextOption("Remove exception from worn", "")
	ElseIf (page == "Debug")
		SetCursorFillMode(TOP_TO_BOTTOM)
		AddHeaderOption("Player Feet Status")
		AddTextOption("Feet Dirtiness", FeetDirtiness.GetValue(), OPTION_FLAG_DISABLED)
		AddTextOption("Feet Roughness", FeetRoughness.GetValue(), OPTION_FLAG_DISABLED)
		AddTextOption("Feet Pain", FeetPain.GetValue(), OPTION_FLAG_DISABLED)
		AddTextOption("Steps Barefoot", StepsBarefoot.GetValue(), OPTION_FLAG_DISABLED)
		
		AddHeaderOption("Last Location/Surface")
		AddTextOption("Last Surface", SurfaceTypes[PlayerLastSurfaceType.GetValueInt()], OPTION_FLAG_DISABLED)
		AddTextOption("Last Location", LocationTypes[PlayerCellType.GetValueInt()], OPTION_FLAG_DISABLED)
		AddTextOption("Total Surface Dirtiness", PlayerLastSurfaceDirtiness.GetValue(), OPTION_FLAG_DISABLED)
	EndIf
EndEvent

Function InitializeSlider(float start, float default, float min, float max, float interval)
	SetSliderDialogStartValue(start)
	SetSliderDialogDefaultValue(default)
	SetSliderDialogRange(min, max)
	SetSliderDialogInterval(interval)
EndFunction

Event OnOptionSliderOpen(int option)
	; I already regret making this so customizable...
	If (option == PositiveDeltaDirtinessMultiplierOID)
		InitializeSlider(PositiveDeltaDirtinessMultiplier, PositiveDeltaDirtinessMultiplierDefault, 0.0, 0.005, 0.0001)
	ElseIf (option == NegativeDeltaDirtinessMultiplierOID)
		InitializeSlider(NegativeDeltaDirtinessMultiplier, NegativeDeltaDirtinessMultiplierDefault, 0.0, 0.005, 0.0001)
	ElseIf (option == StaggerMultiplierOID)
		InitializeSlider(StaggerMultiplier, StaggerMultiplierDefault, 0.0, 0.5, 0.005)
	ElseIf (option == StaggerExponentOID)
		InitializeSlider(StaggerExponent, StaggerExponentDefault, -10, 0, 0.0001)
	ElseIf (option == SprintingStaggerModifierOID)
		InitializeSlider(SprintingStaggerModifier, SprintingStaggerModifierDefault, 0.0, 5.0, 0.05)
	ElseIf (option == WalkingStaggerModifierOID)
		InitializeSlider(WalkingStaggerModifier, WalkingStaggerModifierDefault, 0.0, 5.0, 0.05)
	ElseIf (option == SneakingStaggerModifierOID)
		InitializeSlider(SneakingStaggerModifier, SneakingStaggerModifierDefault, 0.0, 5.0, 0.05)
	ElseIf (option == RoughnessDecayOID)
		InitializeSlider(RoughnessDecay, RoughnessDecayDefault, 0.0, 1.0, 0.001)
	ElseIf (option == RoughnessIncreaseMulOID)
		InitializeSlider(RoughnessIncreaseMul, RoughnessIncreaseMulDefault, 0.0, 1.0, 0.01)
	ElseIf (option == PainIncreaseMulOID)
		InitializeSlider(PainIncreaseMul, PainIncreaseMulDefault, 0.0, 0.1, 0.001)
	ElseIf (option == PainIncreaseExpOID)
		InitializeSlider(PainIncreaseExp, PainIncreaseExpDefault, 0.0, 10.0, 0.1)
	ElseIf (option == PainDecayOID)
		InitializeSlider(PainDecay, PainDecayDefault, 0.0, 1.0, 0.001)
	Else	
		int i = 0
		While i < 9
			If (option == SurfaceDirtinessOID[i])
				InitializeSlider(SurfaceDirtiness[i], SurfaceDirtinessDefault[i], -5.0, 5.0, 0.05)
				Return
			EndIf
			
			if (option == SurfaceRoughnessOID[i])
				InitializeSlider(SurfaceRoughness[i], SurfaceRoughnessDefault[i], 0.0, 2.0, 0.05)
				Return
			EndIf
			
			i += 1
		EndWhile
		i = 0
		While i < 5
			If (option == LocationDirtinessOID[i])
				InitializeSlider(LocationDirtiness[i], LocationDirtinessDefault[i], 0.0, 3.0, 0.05)
				Return
			EndIf
			
			if (option == LocationRoughnessOID[i])
				InitializeSlider(LocationRoughness[i], LocationRoughnessDefault[i], 0.0, 3.0, 0.05)
				Return
			EndIf
		
			i += 1
		EndWhile
	EndIf
EndEvent

Event OnOptionSliderAccept(int option, float value)
	If (option == PositiveDeltaDirtinessMultiplierOID)
		PositiveDeltaDirtinessMultiplier = value
		SetSliderOptionValue(option, value, "{5}")
	ElseIf (option == NegativeDeltaDirtinessMultiplierOID)
		NegativeDeltaDirtinessMultiplier = value
		SetSliderOptionValue(option, value, "{4}")
	ElseIf (option == StaggerExponentOID)
		StaggerExponent = value
		SetSliderOptionValue(option, value, "{4}")		
	ElseIf (option == StaggerMultiplierOID)
		StaggerMultiplier = value
		SetSliderOptionValue(option, value, "{3}")
	ElseIf (option == SprintingStaggerModifierOID)
		SprintingStaggerModifier = value
		SetSliderOptionValue(option, value, "{2}")
	ElseIf (option == WalkingStaggerModifierOID)
		WalkingStaggerModifier = value
		SetSliderOptionValue(option, value, "{2}")
	ElseIf (option == SneakingStaggerModifierOID)
		SneakingStaggerModifier = value
		SetSliderOptionValue(option, value, "{2}")
	ElseIf (option == RoughnessIncreaseMulOID)
		RoughnessIncreaseMul = value
		SetSliderOptionValue(option, value, "{2}")
	ElseIf (option == PainIncreaseMulOID)
		PainIncreaseMul = value
		SetSliderOptionValue(option, value, "{3}")
	ElseIf (option == PainIncreaseExpOID)
		PainIncreaseExp = value
		SetSliderOptionValue(option, value, "{2}")
	ElseIf (option == RoughnessDecayOID)
		RoughnessDecay = value
		SetSliderOptionValue(option, value, "{3}")
	ElseIf (option == PainDecayOID)
		PainDecay = value
		SetSliderOptionValue(option, value, "{3}")
	Else	
		int i = 0
		While i < 9
			If (option == SurfaceDirtinessOID[i])
				SurfaceDirtiness[i] = value
				SetSliderOptionValue(option, value, "{2}")
				Return
			EndIf
			
			if (option == SurfaceRoughnessOID[i])
				SurfaceRoughness[i] = value
				SetSliderOptionValue(option, value, "{2}")
				Return
			EndIf
			
			i += 1
		EndWhile
		i = 0
		While i < 5
			If (option == LocationDirtinessOID[i])
				LocationDirtiness[i] = value
				SetSliderOptionValue(option, value, "{2}")
				Return
			EndIf
			
			if (option == LocationRoughnessOID[i])
				LocationRoughness[i] = value
				SetSliderOptionValue(option, value, "{2}")
				Return
			EndIf
		
			i += 1
		EndWhile
	EndIf
EndEvent

Event OnOptionMenuOpen(int option)
	If option == VendorModeOID
		SetMenuDialogOptions(VendorModes)
		SetMenuDialogStartIndex(VendorMode)
		SetMenuDialogDefaultIndex(VendorModeDefault)
	EndIf
EndEvent

Event OnOptionMenuAccept(int option, int index)
	If option == VendorModeOID
		VendorMode = index
		SetMenuOptionValue(option, VendorModes[index])
	EndIf
EndEvent

Event OnOptionSelect(int option)
	If (option == BarterDamageSpellsOID)
		BarterDamageSpells = !BarterDamageSpells
		SetToggleOptionValue(option, BarterDamageSpells)
	ElseIf (option == SpeedDamageSpellsOID)
		SpeedDamageSpells = !SpeedDamageSpells
		SetToggleOptionValue(option, SpeedDamageSpells)
	ElseIf (option == AnkleCuffsPreventFootwearOID)
		AnkleCuffsPreventFootwear = !AnkleCuffsPreventFootwear
		SetToggleOptionValue(option, AnkleCuffsPreventFootwear)
	ElseIf(option == AnkleCuffsAllowShoesOID)
		AnkleCuffsAllowShoes = !AnkleCuffsAllowShoes
		SetToggleOptionValue(option, AnkleCuffsAllowShoes)
	ElseIf option == BarefootFootwearExceptionSetOID
		Armor bfeSetWorn = Game.GetPlayer().GetWornForm(0x00000080) as Armor
		Keyword bfeSetKw = Keyword.GetKeyword("BarefootRealism_BarefootException")
		if !bfeSetKw
			SetTextOptionValue(BarefootFootwearExceptionOID, "(KID not installed)")
		elseif !bfeSetWorn
			SetTextOptionValue(BarefootFootwearExceptionOID, "(no footwear worn)")
		else
			AddKeywordToForm(bfeSetWorn, bfeSetKw)
			SetTextOptionValue(BarefootFootwearExceptionOID, bfeSetWorn.GetName() + " (counts as barefoot)")
		endif
	ElseIf option == BarefootFootwearExceptionResetOID
		Armor bfeResetWorn = Game.GetPlayer().GetWornForm(0x00000080) as Armor
		Keyword bfeResetKw = Keyword.GetKeyword("BarefootRealism_BarefootException")
		if !bfeResetKw
			SetTextOptionValue(BarefootFootwearExceptionOID, "(KID not installed)")
		elseif !bfeResetWorn
			SetTextOptionValue(BarefootFootwearExceptionOID, "(no footwear worn)")
		else
			RemoveKeywordOnForm(bfeResetWorn, bfeResetKw)
			SetTextOptionValue(BarefootFootwearExceptionOID, bfeResetWorn.GetName())
		endif
	ElseIf option == StaggerSoundOID
		StaggerSound = !StaggerSound
		SetToggleOptionValue(option, StaggerSound)
	ElseIf option == FootwearChangeableInCombatOID
		FootwearChangeableInCombat = !FootwearChangeableInCombat
		SetToggleOptionValue(option, FootwearChangeableInCombat)
	EndIf
EndEvent

Event OnOptionDefault(int option)
	; There should really be some sort of a templating language for this shit
	If (option == PositiveDeltaDirtinessMultiplierOID)
		SetSliderOptionValue(option, PositiveDeltaDirtinessMultiplierDefault, "{5}")
	ElseIf (option == NegativeDeltaDirtinessMultiplierOID)
		SetSliderOptionValue(option, NegativeDeltaDirtinessMultiplierDefault, "{5}")
	ElseIf (option == StaggerExponentOID)
		SetSliderOptionValue(option, StaggerExponentDefault, "{5}")
	ElseIf (option == StaggerMultiplierOID)
		SetSliderOptionValue(option, StaggerMultiplierDefault, "{3}")
	ElseIf (option == SprintingStaggerModifierOID)
		SetSliderOptionValue(option, SprintingStaggerModifierDefault, "{2}")
	ElseIf (option == WalkingStaggerModifierOID)
		SetSliderOptionValue(option, WalkingStaggerModifierDefault, "{2}")
	ElseIf (option == SneakingStaggerModifierOID)
		SetSliderOptionValue(option, SneakingStaggerModifierDefault, "{2}")
	ElseIf (option == RoughnessDecayOID)
		SetSliderOptionValue(option, RoughnessDecayDefault, "{3}")
	ElseIf (option == RoughnessIncreaseMulOID)
		SetSliderOptionValue(option, RoughnessIncreaseMulDefault, "{2}")
	ElseIf (option == PainIncreaseMulOID)
		SetSliderOptionValue(option, PainIncreaseMulDefault, "{3}")
	ElseIf (option == PainIncreaseExpOID)
		SetSliderOptionValue(option, PainIncreaseExpDefault, "{2}")
	ElseIf (option == PainDecayOID)
		SetSliderOptionValue(option, PainDecayDefault, "{3}")
	ElseIf (option == AnkleCuffsAllowShoesOID || option == AnkleCuffsPreventFootwearOID || option == StaggerSoundOID || option == BarterDamageSpellsOID || option == SpeedDamageSpellsOID)
		SetToggleOptionValue(option, True)
	Else	
		int i = 0
		While i < 9
			If (option == SurfaceDirtinessOID[i])
				SetSliderOptionValue(option, SurfaceDirtinessDefault[i], "{2}")
				Return
			EndIf
			
			if (option == SurfaceRoughnessOID[i])
				SetSliderOptionValue(option, SurfaceRoughnessDefault[i], "{2}")
				Return
			EndIf
			
			i += 1
		EndWhile
		i = 0
		While i < 5
			If (option == LocationDirtinessOID[i])
				SetSliderOptionValue(option, LocationDirtinessDefault[i], "{2}")
				Return
			EndIf
			
			if (option == LocationRoughnessOID[i])
				SetSliderOptionValue(option, LocationRoughnessDefault[i], "{2}")
				Return
			EndIf
		
			i += 1
		EndWhile
	EndIf
EndEvent

Event OnOptionHighlight(int option)
	If (option == PositiveDeltaDirtinessMultiplierOID || option == NegativeDeltaDirtinessMultiplierOID)
		SetInfoText("This multiplier * the difference between the feet dirtiness and the surface dirtiness is added to the feet dirtiness every step.")
	ElseIf (option == BarterDamageSpellsOID)
		SetInfoText("Apply barter skill damage spells at different dirtiness tiers")
	ElseIf (option == SpeedDamageSpellsOID)
		SetInfoText("Apply speed damage spells at different pain tiers")
	ElseIf (option == StaggerExponentOID || option == StaggerMultiplierOID)
		SetInfoText("Stagger chance every step is calculated as multipler * e ^ (exponent * feet roughness), the default is calibrated so that you'll stagger roughly every 10 steps with 0 feet roughness and every 1000 steps with maximum roughness (until surface roughness modifiers are applied).")
	ElseIf (option == RoughnessDecayOID)
		SetInfoText("Feet roughness decays by this amount every game day")
	ElseIf (option == RoughnessIncreaseMulOID)
		SetInfoText("Every step, total feet roughness increases by this * pain increase")
	ElseIf (option == PainIncreaseMulOID || option == PainIncreaseExpOID)
		SetInfoText("Every step, the feet pain increases by multiplier * (total surface roughness / (feet roughness + 1)) ^ exponent. Higher exponent means that higher feet roughness decreases the pain much more dramatically.")
	ElseIf (option == PainDecayOID)
		SetInfoText("Feet pain decays by this amount every game day")
	ElseIf (option == AnkleCuffsPreventFootwearOID)
		SetInfoText("Footwear/ankle items tagged BarefootRealism_AnkleRestraint (via the BarefootRealism KID config) prevent wearing any footwear")
	ElseIf (option == AnkleCuffsAllowShoesOID)
		SetInfoText("Ankle restraints still allow wearing footwear tagged BarefootRealism_Shoes (via KID; by default anything with 'Shoes' in its name)")
	ElseIf (option == FootwearChangeableInCombatOID)
		SetInfoText("Player can't equip/remove footwear when in combat state")
	ElseIf (option == VendorModeOID)
		SetInfoText("Vendor reaction when player is barefoot. Ignore: offer service always; Low clothing value: refuse service if clothing value < 20; No Shoes, No Service: refuse service always")
	ElseIf (option == BarefootFootwearExceptionOID || option == BarefootFootwearExceptionSetOID || option == BarefootFootwearExceptionResetOID)
		SetInfoText("Tags the worn footwear as 'counts as barefoot' (BarefootRealism_BarefootException). Persists across saves; whole categories (e.g. DDx slave heels) can be tagged via BarefootRealism_KID.ini")
	ElseIf (option == StaggerSoundOID)
		SetInfoText("Play a random ZaZ gag moan when staggering")
	Else	
		int i = 0
		While i < 9
			If (option == SurfaceDirtinessOID[i])
				SetInfoText("Total surface dirtiness is surface dirtiness * location dirtiness modifier. Player feet dirtiness asymptotically approaches the total location dirtiness with every step and can be cleaned by either walking around in a stream or using the Wash spell near a stream/water body. Different effects and tattoos are applied at dirtiness 0.03, 0.1, 0.3 and 0.9")
				Return
			EndIf
			
			if (option == SurfaceRoughnessOID[i])
				SetInfoText("Total surface roughness is surface roughness * location roughness modifier. It determines stagger chances, the rate at which the player's feet get rougher and more sore. Different speed damaging effects are applied at pain 0.25, 0.5 and 0.75.")
				Return
			EndIf
			
			i += 1
		EndWhile
		i = 0
		While i < 5
			If (option == LocationDirtinessOID[i])
				SetInfoText("Total surface dirtiness is surface dirtiness * location dirtiness modifier. Player feet dirtiness asymptotically approaches the total location dirtiness with every step and can be cleaned by either walking around in a stream or using the Wash spell near a stream/water body. Different effects and tattoos are applied at dirtiness 0.03, 0.1, 0.3 and 0.9")
				Return
			EndIf
			
			if (option == LocationRoughnessOID[i])
				SetInfoText("Total surface roughness is surface roughness * location roughness modifier. It determines stagger chances, the rate at which the player's feet get rougher and more sore. Different speed damaging effects are applied at pain 0.25, 0.5 and 0.75.")
				Return
			EndIf
		
			i += 1
		EndWhile
	EndIf
EndEvent