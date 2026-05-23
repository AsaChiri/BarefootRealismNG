Scriptname PlayerBarefootQuestScript extends Quest  

import NiOverride
import NetImmerse
import SlaveTats
import PBFNative

PBFConfig Property Config Auto

Actor Property PlayerRef Auto
spell Property DamageSpeedSpell1 Auto
spell Property DamageSpeedSpell2 Auto
spell Property DamageSpeedSpell3 Auto
spell Property DamageSpeedSpell4 Auto

spell Property DirtyFeetSpell1 Auto
spell Property DirtyFeetSpell2 Auto
spell Property DirtyFeetSpell3 Auto
spell Property DirtyFeetSpell4 Auto
spell Property DirtyFeetSpell5 Auto

Spell Property PBFWashFeetSpell Auto

ActiveMagicEffect Property CurrentDamageSpeedEffect Auto
ActiveMagicEffect Property CurrentDamageBarterEffect Auto

GlobalVariable Property FeetDirtiness Auto
GlobalVariable Property FeetRoughness Auto
GlobalVariable Property FeetPain Auto

GlobalVariable Property StepsBarefoot Auto
GlobalVariable Property PlayerIsBarefoot Auto
GlobalVariable Property PlayerCellType Auto
GlobalVariable Property PlayerLastSurfaceType  Auto  

GlobalVariable Property PlayerLastSurfaceDirtiness  Auto  

Sound Property PainSound Auto
Sound Property PainSoundMale Auto

; Detection keywords distributed by Keyword Item Distributor (see BarefootRealism_KID.ini).
; KID is REQUIRED for the ankle-restraint / shoes / barefoot-exception features: it auto-creates
; these keywords (they are NOT stored in BarefootRealism.esp) and the shipped INI reproduces the old
; zbfWornAnkles / zad_DeviousAnkleShackles / " Shoes" behavior. Replaced the old zbfWornAnkles /
; zad_DeviousAnkleShackles properties and PBFConfig's BarefootFootwearException Armor; existing saves
; may log benign "property not found" warnings for those (clean save optional).
Keyword Property BarefootRealism_AnkleRestraint Auto
Keyword Property BarefootRealism_Shoes Auto
Keyword Property BarefootRealism_BarefootException Auto

float LastUpdateTime = 0.0
Armor CurrentFootwear = None

Race Property WerewolfRace auto

; Bathing In Skyrim support: if the dirtiness percentage decreases,
; the player has bathed and so we clean their feet too.
GlobalVariable Property DirtinessPercentage Auto
Bool BISLoaded = False
Float LastDirtinessPercentage = 0.0

Function DetectBIS()
	if Game.GetModByName("Bathing in Skyrim.esp") != 255
		BISLoaded = True
		DirtinessPercentage = (Game.GetFormFromFile(0x00000DA8, "Bathing in Skyrim.esp") as GlobalVariable)
	endif
EndFunction

; 0: owned interior (clean)
; 1: owned interior (jail/mine/cave)
; 2: city (skydome)
; 3: unowned interior
; 4: wilderness
;
; Implementation now lives in BarefootRealismNG.dll. The native runs the same
; Sky::mode + cell-owner + cell-name-substring checks but at C++ speed. The
; PlayerCellType global write stays here so all side-effects remain auditable
; on the Papyrus side.
Int Function GetCurrentLocationType()
	Int t = PBFNative.GetActorLocationType(PlayerRef)
	PlayerCellType.SetValue(t)
	return t
EndFunction

Event OnInit()
	Game.GetPlayer().AddSpell(PBFWashFeetSpell)
	DetectBIS()
	; Hand the native plugin the global pointers it reads/writes per step.
	; Also re-called from PBFBISPlayerScript.OnPlayerLoadGame so the cached
	; pointers survive a process restart (the C++ singleton starts empty each
	; time the game launches).
	PBFNative.InitGlobals(FeetDirtiness, FeetPain, FeetRoughness, PlayerLastSurfaceDirtiness)
	LastUpdateTime = Utility.GetCurrentGameTime()
	RegisterForUpdate(1)
	GoToState("Shod")
EndEvent

Int Function GetDirtinessTier(float dirty)
	if (dirty <= 0.03)
		return -1 ;None
	elseif (dirty <= 0.1)
		return 0 ;Light
	elseif (dirty <= 0.3)
		return 1 ;Medium
	elseif(dirty <= 0.9)
		return 2 ;Heavy
	else
		return 3 ;Extreme
	endif
EndFunction

Int Function GetPainTier(float pain)
	int result = (pain / 0.25) as int
	if (result >= 4)
		result = 3
	endif
	return result
EndFunction

Bool Function IsPlayerBarefoot()
	if BarefootRealism_BarefootException == None
		BarefootRealism_BarefootException = Keyword.GetKeyword("BarefootRealism_BarefootException")
	endif
	Armor boots = PlayerRef.GetWornForm(0x00000080) as Armor
	return (boots == None || boots.HasKeyword(BarefootRealism_BarefootException)) && PlayerRef.GetActorBase().GetRace() != WerewolfRace
EndFunction

Function UpdateTattoo(int tier)
	
	int template = JValue.retain(JMap.object())
	JMap.setStr(template, "texture", "BarefootRealism\\barefoot_*")
	JMap.setStr(template, "area", "Feet")
	JMap.setStr(template, "section", "Barefoot")

	remove_tattoos(PlayerRef, template, true, false)

	if (tier != -1)
		JMap.setStr(template, "texture", "BarefootRealism\\barefoot_*")
		JMap.setStr(template, "area", "Feet")
		JMap.setStr(template, "section", "Barefoot")
	
		int tattoo = JValue.retain(JArray.object())
		query_available_tattoos(template, tattoo)
		add_tattoo(PlayerRef, JArray.GetObj(tattoo, 3 - tier))

		JValue.release(tattoo)
	endif
	
	synchronize_tattoos(PlayerRef, silent=True)
	JValue.release(template)
EndFunction

Spell Function ClearDirtinessSpells()
	PlayerRef.RemoveSpell(DirtyFeetSpell1)
	PlayerRef.RemoveSpell(DirtyFeetSpell2)
	PlayerRef.RemoveSpell(DirtyFeetSpell3)
	PlayerRef.RemoveSpell(DirtyFeetSpell4)
	PlayerRef.RemoveSpell(DirtyFeetSpell5)
EndFunction

Spell Function ClearPainSpells()
	PlayerRef.RemoveSpell(DamageSpeedSpell1)
	PlayerRef.RemoveSpell(DamageSpeedSpell2)
	PlayerRef.RemoveSpell(DamageSpeedSpell3)
	PlayerRef.RemoveSpell(DamageSpeedSpell4)
EndFunction

Spell Function GetDirtinessSpell(Int tier)
	if (tier == -1)
		return DirtyFeetSpell1
	elseif (tier == 0)
		return DirtyFeetSpell2
	elseif (tier == 1)
		return DirtyFeetSpell3
	elseif (tier == 2)
		return DirtyFeetSpell4
	else
		return DirtyFeetSpell5
	endif
EndFunction

Spell Function GetPainSpell(Int tier)
	if (tier == 0)
		return DamageSpeedSpell1
	elseif (tier == 1)
		return DamageSpeedSpell2
	elseif (tier == 2)
		return DamageSpeedSpell3
	else
		return DamageSpeedSpell4
	endif
EndFunction

Function SynchronizeSpells()
	; A bit hacky. Use the current effect's magnitude to find out which tier it is;
	; if the tiers don't match, then remove the current spell and apply the new one.
	if (PlayerIsBarefoot.GetValue() == 0)
		return
	endif

	int currentSpeedTier
	if CurrentDamageSpeedEffect == None
		currentSpeedTier = 0
	elseif CurrentDamageSpeedEffect.GetMagnitude() == -20.0
		currentSpeedTier = 1
	elseif CurrentDamageSpeedEffect.GetMagnitude() == -40.0
		currentSpeedTier = 2
	elseif CurrentDamageSpeedEffect.GetMagnitude() == -60.0
		currentSpeedTier = 3
	endif
	
	If !Config.SpeedDamageSpells
		if currentSpeedTier != 0
			ClearPainSpells()
		endif
	Else
		int requiredSpeedTier = GetPainTier(FeetPain.GetValue())
		if requiredSpeedTier != currentSpeedTier
			ClearPainSpells()
			PlayerRef.AddSpell(GetPainSpell(requiredSpeedTier))
		endif
	EndIf
	
	int currentBarterTier
	if CurrentDamageBarterEffect == None
		currentBarterTier = -2
	elseif CurrentDamageBarterEffect.GetMagnitude() == -10.0
		currentBarterTier = -1
	elseif CurrentDamageBarterEffect.GetMagnitude() == -20.0
		currentBarterTier = 0
	elseif CurrentDamageBarterEffect.GetMagnitude() == -30.0
		currentBarterTier = 1
	elseif CurrentDamageBarterEffect.GetMagnitude() == -40.0
		currentBarterTier = 2
	elseif CurrentDamageBarterEffect.GetMagnitude() == -50.0
		currentBarterTier = 3
	endif
	
	If !Config.BarterDamageSpells
		if currentBarterTier != -2
			ClearDirtinessSpells()
		EndIf
	Else
		int requiredBarterTier = GetDirtinessTier(FeetDirtiness.GetValue())
		if requiredBarterTier != currentBarterTier
			ClearDirtinessSpells()
			PlayerRef.AddSpell(GetDirtinessSpell(requiredBarterTier))
		endif
	EndIf
	
EndFunction

Float Function Clamp(Float val, Float min, Float max)
	if (val < min)
		val = min
	endif
	if (val > max)
		val = max
	endif
	return val
EndFunction

Float Function GetStaggerChance(Int placeType, Int surfaceType)
;Stagger chance scales exponentially
;The default is set so that f completely pampered feet (toughness 0) the chance is 10% (once every 10 steps, on average)
;For completely tough (toughness 1) the chance is 0.1%
	float base = Config.StaggerMultiplier * Math.pow(2.71828, Config.StaggerExponent * FeetRoughness.GetValue())
	; Base is calculated for running, for sprinting/walking/sneaking the values are scaled.
	; Sneaking is checked first because the engine sets IsSneaking and IsRunning together when
	; the player is sneak-walking — the previous order made the sneak branch unreachable.
	if (PlayerRef.IsSneaking())
		base *= Config.SneakingStaggerModifier
	elseif (PlayerRef.IsSprinting())
		base *= Config.SprintingStaggerModifier
	elseif (!PlayerRef.IsRunning())
		base *= Config.WalkingStaggerModifier
	endif

	; Also scale by the "roughness coefficient" inferred from the cell type and the surface roughness
	base *= Config.LocationRoughness[placeType] * Config.SurfaceRoughness[surfaceType]

	return base
EndFunction

Float Function GetCurrentDirtinessRate(Int placeType, Int surfaceType)
; How quickly do the player's feet get dirty (score per step)
	float surfaceDirtiness = Config.SurfaceDirtiness[surfaceType]
	; Exterior and is raining: wet feet (TODO: separate magic effect?)
	if ((Weather.GetSkyMode() == 2 || Weather.GetSkyMode() == 3) && Weather.GetCurrentWeather().GetClassification() == 2)
		surfaceDirtiness = surfaceDirtiness * 2
	endif

	float target = surfaceDirtiness * Config.LocationDirtiness[placeType]
	PlayerLastSurfaceDirtiness.SetValue(target)
	float delta = target - FeetDirtiness.GetValue()
	if (delta > 0)
		return Config.PositiveDeltaDirtinessMultiplier * delta
	else
		return Config.NegativeDeltaDirtinessMultiplier * delta
	endif
EndFunction

Float Function GetCurrentPainRate(Int placeType, Int surfaceType)
	; This might be a bit overengineered. The idea is that the pain increase dramatically decreases when feet roughness
	; is greater than the total surface roughness. Let's say the feet roughness is 0 and the player is walking around Whiterun
	; (location roughness 1.0, surface roughness 0.4 for a total of 0.4). Then, with the default settings, the pain increase
	; is 0.01 * (0.4 / (0 + 1)) ^ 4 = 0.000256 per step or 0.256 per thousand steps (will take a whole day to clear).
	; If the roughness is 0.4, we get 0.01 * (0.4 / 1.4)^4; 0.067 per thousand steps, about 6 hours to clear.
	; If the roughness is 1, we get 0.016, about 1.5 hours to clear.
	; TODO perhaps come up with something simpler.
	float score = Config.LocationRoughness[placeType] * Config.SurfaceRoughness[surfaceType] / (FeetRoughness.GetValue() + 1)
	return Config.PainIncreaseMul * Math.Pow(score, Config.PainIncreaseExp)
EndFunction

Function CleanFeet()
	UpdateTattoo(-1)
	ClearDirtinessSpells()
	FeetDirtiness.SetValue(0)
	PlayerRef.AddSpell(GetDirtinessSpell(-1))
EndFunction

Function TrackBISGlobal()
	if BISLoaded
		if LastDirtinessPercentage > DirtinessPercentage.GetValue()
			CleanFeet()
		endif
		LastDirtinessPercentage = DirtinessPercentage.GetValue()
	endif
EndFunction

Auto State Shod

Event OnUpdate()
	if BarefootRealism_AnkleRestraint == None
		BarefootRealism_AnkleRestraint = Keyword.GetKeyword("BarefootRealism_AnkleRestraint")
	endif
	if BarefootRealism_Shoes == None
		BarefootRealism_Shoes = Keyword.GetKeyword("BarefootRealism_Shoes")
	endif

	If IsPlayerBarefoot()
		if !Config.FootwearChangeableInCombat && PlayerRef.IsInCombat()
			Debug.Notification("You can't remove footwear during combat!")
			PlayerRef.EquipItem(CurrentFootwear)
			Return
		endif
		
		if (Config.BarterDamageSpells)
			PlayerRef.AddSpell(GetDirtinessSpell(GetDirtinessTier(FeetDirtiness.GetValue())))
		EndIf
		if (Config.SpeedDamageSpells)
			PlayerRef.AddSpell(GetPainSpell(GetPainTier(FeetPain.GetValue())))
		EndIf
		
		;Register for walking animations
		RegisterForAnimationEvent(PlayerRef, "FootLeft")
		RegisterForAnimationEvent(PlayerRef, "FootRight")
		
		PlayerIsBarefoot.SetValue(1)

		GoToState("Barefoot")
	EndIf
	
	Armor boots = PlayerRef.GetWornForm(0x00000080) as Armor
	if (PlayerRef.WornHasKeyword(BarefootRealism_AnkleRestraint) && Config.AnkleCuffsPreventFootwear) && (!Config.AnkleCuffsAllowShoes || !PlayerRef.WornHasKeyword(BarefootRealism_Shoes))
		Debug.MessageBox("Your fetters are preventing you from wearing these boots.")
		PlayerRef.UnequipItem(boots)
	EndIf

	CurrentFootwear = boots

	float CurrentTime = Utility.GetCurrentGameTime()
	float TimePassed = CurrentTime - LastUpdateTime
	LastUpdateTime = CurrentTime

	FeetRoughness.SetValue(Clamp(FeetRoughness.GetValue() - TimePassed * Config.RoughnessDecay, 0, 1))
	FeetPain.SetValue(Clamp(FeetPain.GetValue() - TimePassed * Config.PainDecay, 0, 1))

	TrackBISGlobal()
EndEvent

EndState

State Barefoot

Event OnUpdate()
	if BarefootRealism_AnkleRestraint == None
		BarefootRealism_AnkleRestraint = Keyword.GetKeyword("BarefootRealism_AnkleRestraint")
	endif
	if BarefootRealism_Shoes == None
		BarefootRealism_Shoes = Keyword.GetKeyword("BarefootRealism_Shoes")
	endif

	If !IsPlayerBarefoot()
		Armor boots = PlayerRef.GetWornForm(0x00000080) as Armor
		If PlayerRef.GetActorBase().GetRace() != WerewolfRace
			if !Config.FootwearChangeableInCombat && PlayerRef.IsInCombat()
				Debug.Notification("You can't put footwear on during combat!")
				PlayerRef.UnequipItem(boots)
				Return
			endif

			if (PlayerRef.WornHasKeyword(BarefootRealism_AnkleRestraint) && Config.AnkleCuffsPreventFootwear) && (!Config.AnkleCuffsAllowShoes || !PlayerRef.WornHasKeyword(BarefootRealism_Shoes))
				Debug.MessageBox("As you try to put the boots on, you realise that you can't fit your shackled ankles into them.")
				PlayerRef.UnequipItem(boots)
				return
			EndIf
		EndIf
		
		CurrentFootwear = boots
		
		ClearDirtinessSpells()
		ClearPainSpells()

		UnregisterForAnimationEvent(PlayerRef, "FootLeft")
		UnregisterForAnimationEvent(PlayerRef, "FootRight")
		PlayerIsBarefoot.SetValue(0)

		GoToState("Shod")
	EndIf

	float CurrentTime = Utility.GetCurrentGameTime()
	float TimePassed = CurrentTime - LastUpdateTime
	LastUpdateTime = CurrentTime

	FeetRoughness.SetValue(Clamp(FeetRoughness.GetValue() - TimePassed * Config.RoughnessDecay, 0, 1))
	FeetPain.SetValue(Clamp(FeetPain.GetValue() - TimePassed * Config.PainDecay, 0, 1))
	
	TrackBISGlobal()
	SynchronizeSpells()
EndEvent


Event OnAnimationEvent(ObjectReference aktarg, String EventName)
	; Resolve once per step. The per-step math is now in C++ via
	; PBFNative.ApplyDirtinessPainStep; this event reduces to a few VM ops
	; plus two native calls.
	Int placeType = GetCurrentLocationType()
	Int surfaceType = PlayerLastSurfaceType.GetValueInt()
	if (surfaceType == -1)
		surfaceType = 0
	endif

	; --- Stagger (pure compute in C++, side effects stay here for sound/anim) ---
	Float staggerChance = PBFNative.GetStaggerChanceNative( \
		PlayerRef, \
		Config.StaggerMultiplier, Config.StaggerExponent, \
		Config.SprintingStaggerModifier, Config.WalkingStaggerModifier, Config.SneakingStaggerModifier, \
		Config.LocationRoughness[placeType], Config.SurfaceRoughness[surfaceType])

	if (Utility.RandomFloat(0.0, 1.0) < staggerChance)
		Debug.SendAnimationEvent(PlayerRef, "staggerStart")
		PlayerRef.CreateDetectionEvent(PlayerRef, 10)
		if Config.StaggerSound
			if PlayerRef.GetActorBase().GetSex() == 1
				PainSound.Play(PlayerRef)
			else
				PainSoundMale.Play(PlayerRef)
			endif
		endif
	endif

	StepsBarefoot.SetValue(StepsBarefoot.GetValue() + 1)

	; --- Dirtiness / Pain / Roughness math (all globals updated in C++) ---
	Float surfaceDirtiness = Config.SurfaceDirtiness[surfaceType]
	; Exterior + raining: wet feet (weather mul stays in Papyrus since SkyMode +
	; classification are already cheap C-side natives in vanilla).
	if ((Weather.GetSkyMode() == 2 || Weather.GetSkyMode() == 3) && Weather.GetCurrentWeather().GetClassification() == 2)
		surfaceDirtiness = surfaceDirtiness * 2
	endif

	; Snapshot the pain tier BEFORE the native mutates FeetPain, so we can
	; detect a tier transition for the pain spell sync (the native only
	; reports dirtiness-tier transitions because SlaveTats is the only thing
	; that hard-cares — pain spells are managed entirely on the Papyrus side).
	Int oldPainTier = GetPainTier(FeetPain.GetValue())

	Int newDirtinessTier = PBFNative.ApplyDirtinessPainStep( \
		surfaceDirtiness, Config.LocationDirtiness[placeType], \
		Config.LocationRoughness[placeType], Config.SurfaceRoughness[surfaceType], \
		Config.PositiveDeltaDirtinessMultiplier, Config.NegativeDeltaDirtinessMultiplier, \
		Config.PainIncreaseMul, Config.PainIncreaseExp, Config.RoughnessIncreaseMul)

	; Sentinel -2147483648 = "no dirtiness tier change". Anything else is the
	; new tier and means we should refresh SlaveTats + the barter-damage spell.
	if newDirtinessTier != -2147483648
		UpdateTattoo(newDirtinessTier)
		ClearDirtinessSpells()
		PlayerRef.AddSpell(GetDirtinessSpell(newDirtinessTier))
	endif

	Int newPainTier = GetPainTier(FeetPain.GetValue())
	if newPainTier != oldPainTier
		ClearPainSpells()
		PlayerRef.AddSpell(GetPainSpell(newPainTier))
	endif
EndEvent

EndState