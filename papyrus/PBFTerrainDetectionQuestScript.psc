Scriptname PBFTerrainDetectionQuestScript extends Quest

import PBFNative
import PO3_SKSEFunctions

; ---------------------------------------------------------------------------
; Surface detection is now performed natively by BarefootRealismNG.dll. The
; original implementation cast an invisible spell with surface-specific impact
; decals (Hazards) and then ran nine sequential FindClosestReferenceOfTypeFromRef
; scans every second to figure out which Hazard had spawned. That whole dance
; (PlaceAtMe / MoveTo / Cast / Delete + 9 cell scans) is replaced by a single
; downward havok pick from C++.
;
; The Hazard / Spell / Activator properties below are kept declared so existing
; save games keep their form bindings. They are no longer used at runtime.
; ---------------------------------------------------------------------------

Spell Property PBFDetectSurfaceSpell Auto
GlobalVariable Property PlayerLastDetectedSurface Auto
GlobalVariable Property PlayerIsBarefoot Auto

Hazard Property PBFStoneHazard  Auto
Hazard Property PBFDirtHazard   Auto
Hazard Property PBFMudHazard    Auto
Hazard Property PBFWoodHazard   Auto
Hazard Property PBFGrassHazard  Auto
Hazard Property PBFSnowHazard   Auto
Hazard Property PBFGravelHazard Auto
Hazard Property PBFCarpetHazard Auto
Hazard Property PBFWaterHazard  Auto

Activator Property DummyObject Auto
Actor Property PlayerRef Auto

Int Function DetectTerrain()
	return PBFNative.GetSurfaceMaterialUnderActor(PlayerRef)
EndFunction

Event OnInit()
	RegisterForUpdate(1)
EndEvent

Event OnUpdate()
	If !PlayerRef.IsOnMount() && PlayerRef.GetSitState() == 0 && PlayerIsBarefoot.GetValue() == 1
		If PO3_SKSEFunctions.IsRefInWater(PlayerRef)
			PlayerLastDetectedSurface.SetValue(8) ; Water
		Else
			PlayerLastDetectedSurface.SetValue(PBFNative.GetSurfaceMaterialUnderActor(PlayerRef))
		EndIf
	EndIf
EndEvent
