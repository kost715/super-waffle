// postInit, server: bank data, cleanup on disconnect, frequent save.
if (!isServer) exitWith {};
call PMCB_fnc_serverLoad;
addMissionEventHandler ["PlayerDisconnected", {
    params ["", "", "", "", "_owner"];
    PMCB_viewers deleteAt _owner;
    PMCB_pending deleteAt _owner;
}];
addMissionEventHandler ["MPEnded", {if (PMCB_dirty) then {call PMCB_fnc_save}}];
[] spawn {
    while {true} do {
        sleep 10;
        if (PMCB_dirty) then {call PMCB_fnc_save};
    };
};
