// Loads balances, treasurers and the journal once. Server.
// Saved as PMCB_bank_v1 = [1, group balance, [[uid, balance, name], ...],
// [[uid, name], ...] treasurers, journal, last journal number].
if (!isServer || {!isNil "PMCB_accounts"}) exitWith {};
PMCB_group = 0;
PMCB_accounts = createHashMap;
PMCB_treasurers = createHashMap;
PMCB_log = [];
PMCB_seq = 0;
PMCB_dirty = false;
PMCB_saveBlocked = false;
PMCB_atms = [];
PMCB_pending = createHashMap;
PMCB_viewers = createHashMap;
private _money = {_this isEqualType 0 && {_this >= 0} && {_this == floor _this} && {_this < 1e12}};
private _saved = profileNamespace getVariable ["PMCB_bank_v1", [1, 0, [], [], [], 0]];
private _valid = _saved isEqualType [] && {count _saved == 6} && {(_saved select 0) isEqualTo 1} && {(_saved select 1) call _money} && {
    (_saved select 2) isEqualType []} && {(_saved select 3) isEqualType []} && {(_saved select 4) isEqualType []} && {(_saved select 5) call _money};
if (_valid) then {
    {
        if (_x isEqualTypeArray ["", 0, ""] && {(_x select 0) != ""} && {(_x select 1) call _money}) then {
            PMCB_accounts set [_x select 0, [_x select 1, _x select 2]];
        } else {_valid = false};
    } forEach (_saved select 2);
    {
        if (_x isEqualTypeArray ["", ""] && {(_x select 0) != ""}) then {PMCB_treasurers set [_x select 0, _x select 1]} else {_valid = false};
    } forEach (_saved select 3);
    if (((_saved select 4) findIf {!(_x isEqualTypeArray [0, "", "", "", "", 0, 0, "", "", ""])}) >= 0) then {_valid = false};
};
if (_valid) then {
    PMCB_group = _saved select 1;
    PMCB_log = +(_saved select 4);
    PMCB_seq = _saved select 5;
} else {
    // Fail closed: the damaged key stays on disk for recovery and is never overwritten.
    PMCB_accounts = createHashMap;
    PMCB_treasurers = createHashMap;
    PMCB_saveBlocked = true;
    diag_log text "[PMCB] ERROR: saved bank data is invalid; it is kept untouched and this session will not save";
};
