// [patient, body part] -> the stitches the next suture of this part takes: one per
// bandaged wound (ACE keeps wounds of a kind together; an entry of N wounds counts N), at
// most PMCI_sutureMax. The wounds over that wait for the next use of the kit.
params ["_patient", "_bodyPart"];
private _bandaged = _patient getVariable ["ace_medical_bandagedWounds", createHashMap];
if !(_bandaged isEqualType createHashMap) exitWith {0};
private _count = 0;
{_count = _count + ((ceil (_x select 1)) max 1)} forEach (_bandaged getOrDefault [toLower _bodyPart, []]);
_count min (missionNamespace getVariable ["PMCI_sutureMax", 10])
