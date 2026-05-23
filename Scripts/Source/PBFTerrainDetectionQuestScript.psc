Scriptname PBFTerrainDetectionQuestScript extends Quest

import PBFNative
import PO3_SKSEFunctions

; ---------------------------------------------------------------------------
; Surface detection is performed natively by BarefootRealismNG.dll. The
; original implementation cast an invisible spell with surface-specific impact
; decals (Hazards) and then ran nine sequential FindClosestReferenceOfTypeFromRef
; scans every second to figure out which Hazard had spawned. That whole dance
; (PlaceAtMe / MoveTo / Cast / Delete + 9 cell scans) is replaced by a single
; downward havok pick from C++.
;
; The forms backing that old system (PBFDetectSurfaceSpell, the nine PBF*Hazard
; records and the dummyObject activator) were removed from BarefootRealism.esp,
; so their now-orphaned property declarations have been dropped here as well.
; This is a clean-save change: pre-existing saves carry stale VMAD bindings for
; those properties, which the Papyrus VM ignores after the forms are gone.
; ---------------------------------------------------------------------------

GlobalVariable Property PlayerLastDetectedSurface Auto
GlobalVariable Property PlayerIsBarefoot Auto
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
