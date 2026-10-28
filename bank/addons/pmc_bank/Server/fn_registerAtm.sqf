// [object, enable] -> true. Server. Makes an object an ATM (or stops it being one)
// for every player, including those who join later.
params [["_object", objNull, [objNull]], ["_enable", true, [true]]];
if (!isServer || {isNull _object}) exitWith {false};
call PMCB_fnc_serverLoad;
if (_enable isEqualTo (_object in PMCB_atms)) exitWith {true};
if (_enable) then {PMCB_atms pushBack _object} else {PMCB_atms deleteAt (PMCB_atms find _object)};
_object setVariable ["PMCB_atm", _enable, true];
// The JIP entry is keyed by the object: the latest call replaces the previous one.
[_object, _enable] remoteExec ["PMCB_fnc_atmInit", 0, _object];
true
