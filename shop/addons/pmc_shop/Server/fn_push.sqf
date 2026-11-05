// [network ID, unit, mode, event] -> nothing. Server. Sends a laptop the market (with the
// journal for the management laptop), the player's PMC Bank balances and an optional
// event for the client ("bought": the cart is paid).
params ["_owner", "_unit", "_mode", ["_event", ""]];
[[PMCS_market, _mode == "admin"] call PMCS_fnc_marketPack, [_unit] call PMCS_fnc_bankState, _event] remoteExecCall ["PMCS_fnc_receive", _owner];
