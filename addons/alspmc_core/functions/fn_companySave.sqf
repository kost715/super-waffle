if (!isServer || {!(missionNamespace getVariable ["ALSPMC_companiesReady", false])}) exitWith {};
private _rows = (keys ALSPMC_companies) apply {
    private _c = ALSPMC_companies get _x;
    private _members = _c get "members";
    [_x, [_c get "owner", (keys _members) apply {[_x, _members get _x]},
        _c get "balance", _c get "debt", _c get "reserve", _c get "seconds",
        +(_c get "ledger"), +(_c get "receipts"), _c get "revision"]]
};
["alspmc_companies_v1", [1, _rows]] call ALS_fnc_dbSet;
