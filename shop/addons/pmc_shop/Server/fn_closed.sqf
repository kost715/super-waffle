// [] -> nothing. Client -> server when the laptop is closed: no more market updates.
if (!isServer) exitWith {};
call PMCS_fnc_serverLoad;
PMCS_viewers deleteAt (call PMCS_fnc_requestOwner);
