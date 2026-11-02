// [state, mission time] -> [acting, metabolite now, end time]. Meldonium's metabolite is
// eliminated at first order with a half-life of half the set duration (CBA, 90 min: 45 min).
// A dose adds 1 to what is left; the effect is on (one strength, no build-up) while the
// metabolite is above 0.25, so one dose lasts exactly the set duration. The end time is
// worked out when a dose goes in (PMCD_fnc_takeMeld), from what was left at that moment:
// a second dose right away gives 1.5 x the duration, one at the end of the first adds a
// little over one duration.
params ["_state", "_now"];
(_state getOrDefault ["meld", [0, 0, -1]]) params ["_amount", "_time", "_end"];
private _half = 30 * (missionNamespace getVariable ["PMCD_meldDuration", 90]);
[_now < _end, _amount * 0.5 ^ ((_now - _time) / (_half max 1)), _end]
