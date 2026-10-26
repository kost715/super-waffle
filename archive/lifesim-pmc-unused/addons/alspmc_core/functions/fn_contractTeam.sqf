params ["_job"];
private _crew = ALS_crews getOrDefault [_job get "crew", createHashMap];
private _dead = _job getOrDefault ["alspmcCasualties", []];
private _permanent = (getNumber (configFile >> "ALSPMC_Settings" >> "contractPermanentCasualties")) > 0;
private _living = [];
{
    _x params ["_uid", "_body"];
    if (!isNull _body && {!alive _body}) then {_dead pushBackUnique _uid};
    private _now = [_uid] call ALS_fnc_findPlayer;
    if (!_permanent && {!isNull _now} && {alive _now}) then {_x set [1, _now]};
    if (!isNull _now && {alive _now} && {_uid in (_crew getOrDefault ["members", []])} && {
        !_permanent || {!(_uid in _dead)}
    }) then {_living pushBack _now};
} forEach (_job get "alspmcRoster");
_job set ["alspmcCasualties", _dead];
_living
