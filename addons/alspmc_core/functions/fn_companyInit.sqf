if (!isServer || {isRemoteExecuted && {!isNil "_fnc_scriptNameParent"} && {_fnc_scriptNameParent == _fnc_scriptName}}) exitWith {};
ALSPMC_companiesReady = false;
ALSPMC_companies = createHashMap;
ALSPMC_companyInvites = createHashMap;
ALSPMC_companyRequestAt = createHashMap;
// Optional last-seen display names. Invalid data only loses names, never money.
ALSPMC_playerNames = createHashMap;
[["alspmc_player_names_v1"]] call ALS_fnc_dbLoading;
private _known = ["alspmc_player_names_v1", [1, []]] call ALS_fnc_dbGet;
if (_known isEqualType [] && {count _known == 2} && {(_known select 0) isEqualTo 1} && {(_known select 1) isEqualType []} && {
    ((_known select 1) findIf {!(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""} && {(_x select 1) isEqualType []} && {
        count (_x select 1) <= 256} && {((_x select 1) findIf {!(_x isEqualType 0)}) < 0})}) < 0
}) then {
    {ALSPMC_playerNames set [_x select 0, +(_x select 1)]} forEach (_known select 1);
    [["alspmc_player_names_v1"], true] call ALS_fnc_dbLoading;
} else {
    ["ALSPMC: player name cache invalid; original key preserved, names shown as UID"] call ALS_fnc_log;
};
[["alspmc_companies_v1"]] call ALS_fnc_dbLoading;
private _migrate = isNil {["alspmc_companies_v1"] call ALS_fnc_dbGet};
private _saved = ["alspmc_companies_v1", [1, []]] call ALS_fnc_dbGet;
private _valid = _saved isEqualType [] && {count _saved == 2} && {(_saved select 0) isEqualTo 1} && {(_saved select 1) isEqualType []};
private _seen = [];
if (_valid) then {
    {
        private _good = _x isEqualType [] && {count _x == 2};
        if (_good) then {
            _x params ["_id", "_r"];
            _good = _id isEqualType "" && {_r isEqualType []} && {count _r == 9} && {!(_id in ALSPMC_companies)};
            if (_good) then {
                _r params ["_owner", "_pairs", "_balance", "_debt", "_reserve", "_seconds", "_ledger", "_receipts", "_revision"];
                _good = _owner isEqualType "" && {_owner != ""} && {_id == "pmc_" + _owner} && {_pairs isEqualType []} && {_pairs isNotEqualTo []} && {
                    ([_balance, _debt, _reserve, _seconds, _revision] findIf {!(_x isEqualType 0) || {!finite _x} || {_x < 0} || {_x > 1000000000}}) < 0
                } && {_balance <= 10000000 && {_balance == floor _balance}} && {_revision == floor _revision} && {
                    _ledger isEqualType [] && {count _ledger <= 100} && {_receipts isEqualType []}
                };
                private _members = createHashMap;
                if (_good) then {
                    {
                        if !(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""} && {(_x select 0) != ""} && {
                            !((_x select 0) in _seen) && {!((_x select 0) in _members)}
                        } && {(_x select 1) in ["owner", "manager", "member"]} && {
                            ((_x select 1) == "owner") isEqualTo ((_x select 0) == _owner)
                        }) then {_good = false} else {_members set [_x select 0, _x select 1]};
                    } forEach _pairs;
                    if !(_owner in _members) then {_good = false};
                    if ((_receipts findIf {!(_x isEqualType 0) || {!finite _x} || {_x <= 0} || {_x != floor _x}}) >= 0 || {
                        count (_receipts arrayIntersect _receipts) != count _receipts
                    }) then {_good = false};
                    if ((_ledger findIf {!(_x isEqualType []) || {count _x != 5} || {!((_x select 0) isEqualType [])} || {
                        !((_x select 1) isEqualType "") || {!((_x select 2) isEqualType 0)} || {!finite (_x select 2)} || {
                            !((_x select 3) isEqualType "") || {!((_x select 4) isEqualType "")}
                        }
                    }}) >= 0) then {_good = false};
                };
                if (_good) then {
                    _seen append (keys _members);
                    ALSPMC_companies set [_id, createHashMapFromArray [["id", _id], ["owner", _owner], ["members", _members],
                        ["balance", _balance], ["debt", _debt], ["reserve", _reserve], ["seconds", _seconds],
                        ["ledger", _ledger], ["receipts", _receipts], ["revision", _revision]]];
                };
            };
        };
        if (!_good) then {_valid = false};
    } forEach (_saved select 1);
};
if (!_valid) exitWith {
    ALSPMC_companies = createHashMap;
    ["ALSPMC: invalid company data; original key preserved, PMC economy disabled"] call ALS_fnc_log;
};
[["alspmc_companies_v1"], true] call ALS_fnc_dbLoading;
ALSPMC_companiesReady = true;
// Do not move personal balances or re-pay old quest receipts during migration.
private _founders = (values ALSPMC_bases) apply {_x select 0};
_founders append (keys ALSPMC_names);
_founders append (keys (missionNamespace getVariable ["ALSPMC_ratingXP", createHashMap]));
{_founders pushBack (_x select 0)} forEach (values (missionNamespace getVariable ["ALSPMC_questRecords", createHashMap]));
if (_migrate) then {{[_x] call ALSPMC_fnc_companyEnsure} forEach (_founders arrayIntersect _founders)};
ALSPMC_companyClockAt = diag_tickTime;
call ALSPMC_fnc_companySave;
call ALS_fnc_dbSave;
