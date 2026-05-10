Scriptname PBFBISPlayerScript extends ReferenceAlias

PlayerBarefootQuestScript Property QuestScript Auto

Event OnPlayerLoadGame()
	QuestScript.DetectBIS()
	; Re-cache global pointers in the native plugin: the C++ singleton holding
	; them is reset whenever the game process restarts, but PlayerBarefootQuestScript.OnInit
	; only fires once-ever per save, so without this the per-step natives
	; would no-op after every fresh game launch until a manual MCM apply.
	PBFNative.InitGlobals( \
		QuestScript.FeetDirtiness, \
		QuestScript.FeetPain, \
		QuestScript.FeetRoughness, \
		QuestScript.PlayerLastSurfaceDirtiness)
EndEvent
