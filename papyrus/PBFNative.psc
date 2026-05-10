Scriptname PBFNative Hidden

; ---------------------------------------------------------------------------
; Native accelerator stubs for Barefoot Realism. Implementations live in
; BarefootRealismNG.dll (CommonLibSSE-NG plugin). Each function is stateless
; and safe to call from any Papyrus thread.
; ---------------------------------------------------------------------------

; Returns the surface material id under the actor's feet.
;   0 Stone   1 Dirt   2 Mud    3 Wood    4 Grass
;   5 Snow    6 Carpet 7 Gravel 8 Water  -1 Unknown / no hit
;
; Callers should short-circuit to 8 (Water) using PO3_SKSEFunctions.IsRefInWater
; before invoking this — the native does not duplicate water detection, except
; as a fallback when a downward havok pick happens to land on a water shape.
Int Function GetSurfaceMaterialUnderActor(Actor akActor) global native

; Returns the cell category for the actor:
;   0 owned interior (clean)         1 owned interior (Mine/Dungeon/Jail)
;   2 exterior city skydome          3 unowned interior
;   4 exterior wilderness skydome
;
; Mirrors the original PlayerBarefootQuestScript.GetCurrentLocationType()
; semantics 1:1; the caller still writes the PlayerCellType global.
Int Function GetActorLocationType(Actor akActor) global native
