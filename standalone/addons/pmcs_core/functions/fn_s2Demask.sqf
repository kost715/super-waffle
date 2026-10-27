// Take a hidden player group out of its civilian cover: combat colour of its
// contract, WEST without one (Override GDD 4.4: government spy), held by the
// aura. Returns true when the group was hidden.
params ["_r", ["_why", ""]];
if !((_r get "reason") in ["rear", "undercover"]) exitWith {false};
private _contract = _r get "contract";
_r set ["combat", if (_contract == "none") then {"west"} else {_contract}];
_r set ["auraUntil", diag_tickTime + (PMCS2_settings get "aura")];
[format ["demask %1: %2, combat colour %3", _r get "uid", _why, _r get "combat"]] call PMCS_fnc_s2Log;
true
