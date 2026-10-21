if (!isServer || {!(missionNamespace getVariable ["ALSPMC_contractsReady", false])}) exitWith {};
{if !(_x in ALSPMC_questRecords) then {ALSPMC_contractMeta deleteAt _x}} forEach keys ALSPMC_contractMeta;
["alspmc_contracts_v1", [1,
    (keys ALSPMC_contractMeta) apply {[_x, +(ALSPMC_contractMeta get _x)]},
    (keys ALSPMC_ratingXP) apply {[_x, ALSPMC_ratingXP get _x]}
]] call ALS_fnc_dbSet;
