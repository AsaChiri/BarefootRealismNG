Scriptname PBFFeetWashEffectScript extends activemagiceffect

import PO3_SKSEFunctions

PlayerBarefootQuestScript Property QuestScript Auto
GlobalVariable Property FeetDirtiness Auto
GlobalVariable Property PlayerLastSurfaceType Auto
FormList Property PBFWaterfallList Auto
FormList Property PBFWaterList Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	Actor PlayerRef = Game.GetPlayer()
	; po3's IsRefInWater covers wading (feet-in-water) and full submersion; the
	; PlayerLastSurfaceType == 8 check is kept as a fast-path for cases where the
	; terrain native already resolved water under the player on its last tick.
	If PlayerLastSurfaceType.GetValueInt() == 8 || PO3_SKSEFunctions.IsRefInWater(PlayerRef)
		if (FeetDirtiness.GetValue() > 0)
			Debug.MessageBox("You wash your feet in the water...")
			QuestScript.CleanFeet()
		else
			Debug.MessageBox("Your feet are already clean!")
		endif
	Else
		Debug.MessageBox("You aren't close to any sources of water!")
	EndIf
EndEvent
