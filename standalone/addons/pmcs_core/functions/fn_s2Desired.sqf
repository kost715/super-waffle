// Pure: which side and captive flag a player's group should have now.
// [record, inZone, now, settings] -> [colour, captive, reason].
// Priority: manual test override > contract zone > aura > rear (undercover).
params ["_r", "_inZone", "_now", "_settings"];
private _manual = _r getOrDefault ["manual", ""];
if (_manual != "") exitWith {[_manual, false, "manual"]};
private _contract = _r getOrDefault ["contract", "none"];
if (_inZone && {_contract != "none"}) exitWith {[_contract, false, "zone"]};
if (_now < (_r getOrDefault ["auraUntil", 0])) exitWith {[_r getOrDefault ["combat", "west"], false, "aura"]};
// Rear. "side": civilian group. "captive": keep the current side, set captive
// (the way Antistasi hides undercover players).
if ((_settings getOrDefault ["undercover", "side"]) == "captive") exitWith {[_r getOrDefault ["color", "civ"], true, "undercover"]};
["civ", false, "rear"]
