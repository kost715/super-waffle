// postInit, server: persistent storages, settlement on disconnect, periodic save.
if (!isServer) exitWith {};
call PMCA_fnc_serverLoad;
// Mission objects and their Eden inventories are set up now: restore saved inventories.
PMCA_ready = true;
{[_x] call PMCA_fnc_boxLoad} forEach (PMCA_storageObjects select {!isNull _x});
// An edited stock file replaces the stock of the storages it lists.
call PMCA_fnc_stockFile;
// The leaving unit still holds its gear here: settle what it took or returned.
addMissionEventHandler ["HandleDisconnect", {
    params ["_unit"];
    {
        if ((_y get "unit") isEqualTo _unit) exitWith {[_x, nil, (_y get "kind") != "arsenal"] call PMCA_fnc_commit};
    } forEach +PMCA_sessions;
    false
}];
// Anything still open (unit already gone): settle nothing, refill an emptied container.
addMissionEventHandler ["PlayerDisconnected", {
    params ["", "", "", "", "_owner"];
    if (_owner in PMCA_sessions) then {[_owner, nil, true] call PMCA_fnc_commit};
}];
addMissionEventHandler ["MPEnded", {
    // The final stock goes to the RPT, ready to copy into the stock file.
    [false] call PMCA_fnc_exportStock;
    private _boxes = call PMCA_fnc_boxScan;
    if (_boxes || {PMCA_dirty}) then {call PMCA_fnc_save};
}];
[] spawn {
    while {true} do {
        sleep 30;
        private _boxes = call PMCA_fnc_boxScan;
        if (_boxes || {PMCA_dirty}) then {call PMCA_fnc_save};
    };
};
