// ["ace_medical_status_getBloodLoss" event: unit, blood loss] -> nothing. ACE Medical asks
// for a unit's blood loss through this event and hands every handler the same array, so
// the loss is cut in place: x (1 - 0.35) (CBA) while the unit's hemostatic acts. Cheap for
// the units without drugs: one variable read.
params ["_unit", "_loss"];
private _state = _unit getVariable "PMCD_state";
if (isNil "_state" || {CBA_missionTime >= (_state getOrDefault ["hemoEnd", -1])}) exitWith {};
private _cut = _loss * (1 - (missionNamespace getVariable ["PMCD_hemoBleed", 0.35]));
_this set [1, _cut];
_state set ["bleedSeen", [_loss, _cut]];
