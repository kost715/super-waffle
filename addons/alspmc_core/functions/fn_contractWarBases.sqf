// Pause only the leased base's streaming/capture logic. Original code runs for
// every other base, with original arguments/result; the registry is restored
// before the scheduler can switch to another script.
// LifeSim publishes ALS_war from inside warBases only when a base changes
// hands. Republish the restored registry only then, so clients never keep the
// filtered copy, instead of broadcasting it on every 2-second war tick.
private _out = nil;
isNil {
    private _leases = missionNamespace getVariable ["ALSPMC_garrisonLeases", createHashMap];
    private _bases = ALS_war getOrDefault ["bases", []];
    if (count _leases == 0) exitWith {_out = _this call ALSPMC_nativeWarBases};
    private _owners = {
        private _list = (ALS_war getOrDefault ["own", createHashMap]) toArray false;
        _list sort true;
        str _list
    };
    private _before = call _owners;
    ALS_war set ["bases", _bases select {!((_x select 0) in _leases)}];
    _out = _this call ALSPMC_nativeWarBases;
    ALS_war set ["bases", _bases];
    if ((call _owners) != _before) then {publicVariable "ALS_war"};
    true
};
_out
