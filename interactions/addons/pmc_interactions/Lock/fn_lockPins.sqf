// [lock difficulty 0-2] -> how many picks a classic lock takes at once: two from the
// difficulty set in CBA (PMCI_lockpickTwo: 1 normal, 2 hard, 3 never), otherwise one.
params ["_level"];
[1, 2] select (_level >= (missionNamespace getVariable ["PMCI_lockpickTwo", 2]))
