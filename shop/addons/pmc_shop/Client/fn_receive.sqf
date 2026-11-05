// [packed market, [personal balance, group balance, treasurer], event] -> nothing.
// Server -> client while a laptop's browser is open. "bought": the cart has been paid;
// "upgraded": an upgrade at the gunsmith is finished (done or refunded).
params [["_packed", [], [[]]], ["_bank", [0, 0, false], [[]]], ["_event", "", [""]]];
if (isNil "PMCS_ui") exitWith {};
private _market = [_packed] call PMCS_fnc_marketUnpack;
if (isNil "_market") exitWith {};
PMCS_ui set ["market", _market];
PMCS_ui set ["bank", _bank];
if (_event == "upgraded") then {PMCS_ui set ["techBusy", false]};
if (_event == "bought") then {
    PMCS_ui set ["cart", []];
    PMCS_ui set ["cartOpen", false];
};
["receive"] call PMCS_fnc_ui;
