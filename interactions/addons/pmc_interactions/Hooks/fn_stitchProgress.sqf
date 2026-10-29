// "callbackProgress" of the surgical kit: [args, elapsed, total] -> keep going. While the
// short preparation bar before the game runs, nothing is stitched (the game decides);
// otherwise ACE's own progress stitches as usual.
params ["_args"];
_args params ["_medic"];
if ([_medic, "suture"] call PMCI_fnc_plays) exitWith {true};
_this call ace_medical_treatment_fnc_surgicalKitProgress
