// postInit, server: this mission's market, cleanup on disconnect, frequent save.
if (!isServer) exitWith {};
call PMCS_fnc_serverLoad;
addMissionEventHandler ["PlayerDisconnected", {
    params ["", "", "", "", "_owner"];
    PMCS_viewers deleteAt _owner;
}];
addMissionEventHandler ["MPEnded", {if (PMCS_dirty) then {call PMCS_fnc_save}}];
[] spawn {
    while {true} do {
        sleep 10;
        if (PMCS_dirty) then {call PMCS_fnc_save};
    };
};
