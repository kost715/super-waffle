// Shared across phone/desktop. Only expiry or a settled operation changes slots.
// Each replacement gets a new ticket; consuming/cancelling cannot replay an offer.
params ["_unit", ["_settledType", ""], ["_success", true], ["_slot", ""]];
private _uid = [_unit] call ALS_fnc_uid;
private _c = [_uid] call ALSPMC_fnc_companyOf;
if (count _c > 0) then {_uid = _c get "owner"};
private _boards = missionNamespace getVariable ["ALSPMC_contractBoards", createHashMap];
private _board = _boards getOrDefault [_uid, createHashMap];
private _keep = count _board > 0 && {diag_tickTime < (_board get "expires")};
if (_keep && {_settledType == ""}) exitWith {_board};
private _level = ([_uid] call ALSPMC_fnc_contractProfile) get "level";
private _catalog = (call ALSPMC_fnc_contractCatalog) select {(_x select 3) <= _level};
private _army = count (["army", _unit] call ALSPMC_fnc_contractSites);
private _government = count (["government", _unit] call ALSPMC_fnc_contractSites);
private _commercial = count (["commercial", _unit] call ALSPMC_fnc_contractSites);
private _bases = count (["assaultBase", _unit] call ALSPMC_fnc_contractSites);
_catalog = _catalog select {
    switch (_x select 0) do {
        case "gov_convoy": {_army > 0 && {_army + _government > 1}};
        case "gov_guard": {_government > 0};
        case "gov_base": {_bases > 0};
        case "private_guard": {_commercial > 0};
        case "private_convoy";
        case "private_vip": {_commercial > 1};
        default {true};
    }
};
private _offers = if (_keep) then {+(_board get "offers")} else {[]};
// Remove only the accepted operation's reserved slot, if this is still its board.
if (_keep && {_slot != ""}) then {_offers = _offers select {(_x select 0) != _slot}};
private _add = {
    params ["_entry"];
    ALSPMC_boardSequence = (missionNamespace getVariable ["ALSPMC_boardSequence", 0]) + 1;
    _offers pushBack ["o" + str ALSPMC_boardSequence + "_" + (_entry select 0), _entry select 0];
};
private _gov = (round getNumber (configFile >> "ALSPMC_Settings" >> "contractPoolGovernment")) max 1 min 7;
private _private = (round getNumber (configFile >> "ALSPMC_Settings" >> "contractPoolPrivate")) max 1 min 3;
private _total = (_gov + _private) max 6;
if (!_keep) then {
    {
        _x params ["_category", "_count"];
        private _candidates = _catalog select {(_x select 1) == _category};
        for "_i" from 1 to (_count min count _candidates) do {
            [(_candidates deleteAt (floor random count _candidates))] call _add;
        };
    } forEach [["government", _gov], ["private", _private]];
} else {
    // Failed/cancelled tasks return the same type, so cancellation is not a reroll.
    if (!_success && {count _offers < _total}) then {
        private _old = _catalog select {(_x select 0) == _settledType};
        if (_old isNotEqualTo []) then {[_old select 0] call _add};
    };
};
// On maps without six distinct supported types, use independent field offers.
// Repeated types still have unique tickets and are planned as separate missions.
for "_i" from (count _offers) to (_total - 1) do {
    private _candidates = _catalog select {private _type = _x select 0; (_offers findIf {(_x select 1) == _type}) < 0};
    if (_candidates isEqualTo []) then {_candidates = _catalog};
    if (_candidates isEqualTo []) exitWith {};
    [selectRandom _candidates] call _add;
};
private _ttl = (getNumber (configFile >> "ALSPMC_Settings" >> "contractPoolSeconds")) max 300 min 3600;
_board = createHashMapFromArray [["expires", if (_keep) then {_board get "expires"} else {diag_tickTime + _ttl}], ["offers", _offers]];
_boards set [_uid, _board]; ALSPMC_contractBoards = _boards;
_board
