// postInit, server: persistent storages, settlement on disconnect, periodic save.
if (!isServer) exitWith {};
call PMCA_fnc_serverLoad;
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
addMissionEventHandler ["MPEnded", {if (PMCA_dirty) then {call PMCA_fnc_save}}];
[] spawn {
    while {true} do {
        sleep 30;
        if (PMCA_dirty) then {call PMCA_fnc_save};
    };
};
