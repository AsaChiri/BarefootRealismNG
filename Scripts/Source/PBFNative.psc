Scriptname PBFNative Hidden

; ---------------------------------------------------------------------------
; Native accelerator stubs for Barefoot Realism. Implementations live in
; BarefootRealismNG.dll (CommonLibSSE-NG plugin). Each function is stateless
; (or relies on the cached state populated by InitGlobals) and safe to call
; from the Papyrus VM thread.
; ---------------------------------------------------------------------------

; ---- v1 ------------------------------------------------------------------

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

; ---- v1.1 — per-footstep math -------------------------------------------

; Caches the four GlobalVariable pointers the per-step natives read/write.
; Call from PlayerBarefootQuestScript.OnInit AND OnPlayerLoadGame so the
; cached pointers are re-established after each save reload.
Function InitGlobals( \
    GlobalVariable feetDirtiness, \
    GlobalVariable feetPain, \
    GlobalVariable feetRoughness, \
    GlobalVariable playerLastSurfaceDirtiness \
) global native

; Pure compute. Reads FeetRoughness from the cached global, picks the
; movement-mode multiplier (sneaking / sprinting / walking / running) using
; the corrected branch order from 1.2, and scales by location * surface
; roughness. Caller supplies the config scalars and the per-cell coefficients.
Float Function GetStaggerChanceNative( \
    Actor akActor, \
    Float staggerMultiplier, Float staggerExponent, \
    Float sprintingMod,      Float walkingMod,      Float sneakingMod, \
    Float locationRoughness, Float surfaceRoughness \
) global native

; Updates FeetDirtiness / FeetPain / FeetRoughness / PlayerLastSurfaceDirtiness
; using the original Papyrus formulas (with the Clamp() bug fixed inline since
; C++ has no pass-by-value trap). Caller pre-resolves the weather multiplier
; on adjustedSurfaceDirtiness (i.e. doubles it when raining in an exterior
; skydome).
;
; Returns the new dirtiness tier (-1..3) when it transitioned this step;
; otherwise returns Int.MinValue (-2147483648) — the caller treats that as
; "no change, skip SlaveTats refresh".
Int Function ApplyDirtinessPainStep( \
    Float adjustedSurfaceDirtiness, \
    Float locationDirtiness, \
    Float locationRoughness, Float surfaceRoughness, \
    Float positiveDeltaMul,  Float negativeDeltaMul, \
    Float painIncreaseMul,   Float painIncreaseExp, \
    Float roughnessIncreaseMul \
) global native
