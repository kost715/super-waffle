if (!isServer || {!(missionNamespace getVariable ["ALSPMC_questsReady", false])}) exitWith {};
// Keep twenty recent records per founder, including every active contract.
private _ids = keys ALSPMC_questRecords;
_ids sort false;
private _counts = createHashMap;
{
    private _row = ALSPMC_questRecords get _x;
    private _founder = _row select 0;
    private _n = _counts getOrDefault [_founder, 0];
    if (_n < 20 || {(_row select 1) == "active"}) then {_counts set [_founder, _n + 1]} else {
        ALSPMC_questRecords deleteAt _x;
    };
} forEach _ids;
["alspmc_quests_v1", [1, ALSPMC_questSequence, (keys ALSPMC_questRecords) apply {[_x, +(ALSPMC_questRecords get _x)]}]] call ALS_fnc_dbSet;
private _links = missionNamespace getVariable ["ALSPMC_questCompanies", createHashMap];
{if !(_x in ALSPMC_questRecords) then {_links deleteAt _x}} forEach keys _links;
["alspmc_quest_companies_v1", [1, (keys _links) apply {[_x, _links get _x]}]] call ALS_fnc_dbSet;
if (missionNamespace getVariable ["ALSPMC_contractsReady", false]) then {call ALSPMC_fnc_contractSave};
