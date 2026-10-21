// Persistent PMC membership is independent of native commercial companies/crews.
params ["_uid"];
private _companies = missionNamespace getVariable ["ALSPMC_companies", createHashMap];
private _id = (keys _companies) findIf {_uid in ((_companies get _x) get "members")};
if (_id < 0) exitWith {createHashMap};
_companies get ((keys _companies) select _id)
