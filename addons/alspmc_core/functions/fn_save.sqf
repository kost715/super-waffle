if (!isServer) exitWith {};
["alspmc_bases_v1", (keys ALSPMC_bases) apply {[_x, +(ALSPMC_bases get _x)]}] call ALS_fnc_dbSet;
ALSPMC_basesPublic = (keys ALSPMC_bases) apply {[_x, +(ALSPMC_bases get _x)]};
call ALSPMC_fnc_applyValues;
// Re-publish native property values, so the phone and rents agree with the
// test purchase price. A base bought for 1 euro cannot be sold for thousands.
call ALS_fnc_housePublish;
publicVariable "ALSPMC_basesPublic";
