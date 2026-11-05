// [unit] -> [personal balance, group balance, is a treasurer] from PMC Bank. Server.
params [["_unit", objNull, [objNull]]];
call PMCB_fnc_serverLoad;
private _uid = [_unit] call PMCB_fnc_ensure;
[(PMCB_accounts getOrDefault [_uid, [0, ""]]) select 0, PMCB_group, _uid in PMCB_treasurers]
