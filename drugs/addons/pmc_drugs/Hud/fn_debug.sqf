// [on] -> nothing. Client, from the debug console: the debug panel with every value of the
// drugs, ACE Advanced Fatigue, ACE Medical and Field Rations, refreshed every second.
//   call PMCD_fnc_debug;          switches it on or off
//   [true] call PMCD_fnc_debug;   on;  [false] call PMCD_fnc_debug;  off
// The same switch is a per-player CBA setting (PMC Drugs -> Interface).
params [["_on", !(missionNamespace getVariable ["PMCD_debugOn", false])]];
PMCD_debugOn = _on;
call PMCD_fnc_hud;
