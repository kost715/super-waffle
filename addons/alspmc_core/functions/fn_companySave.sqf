if (!isServer || {isRemoteExecuted && {!isNil "_fnc_scriptNameParent"} && {_fnc_scriptNameParent == _fnc_scriptName}} || {!(missionNamespace getVariable ["ALSPMC_companiesReady", false])}) exitWith {};
private _known = [];
private _rows = (keys ALSPMC_companies) apply {
    private _c = ALSPMC_companies get _x;
    private _members = _c get "members";
    _known append (keys _members);
    {_known pushBack (_x select 1)} forEach (_c get "ledger");
    [_x, [_c get "owner", (keys _members) apply {[_x, _members get _x]},
        _c get "balance", _c get "debt", _c get "reserve", _c get "seconds",
        +(_c get "ledger"), +(_c get "receipts"), _c get "revision"]]
};
["alspmc_companies_v1", [1, _rows]] call ALS_fnc_dbSet;
ALSPMC_companySavedAt = diag_tickTime;
// Last seen names, kept only for people a company still lists.
private _names = missionNamespace getVariable ["ALSPMC_playerNames", createHashMap];
{if !(_x in _known) then {_names deleteAt _x}} forEach keys _names;
["alspmc_player_names_v1", [1, (keys _names) apply {[_x, +(_names get _x)]}]] call ALS_fnc_dbSet;
