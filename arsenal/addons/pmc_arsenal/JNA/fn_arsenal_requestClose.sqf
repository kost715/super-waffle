/*
	Author: Jeroen Notenbomer; server-side sessions: LifeSim PMC project

	Description:
	Server. The client closed the arsenal; settle its session with the state it
	closed with (loadout, or the container's 27-tab list).

	Parameter(s):
	[claim]
*/
if (!isServer || {isNil "PMCA_sessions"}) exitWith {};
params [["_claim", [], [[]]]];
private _owner = call PMCA_fnc_requestOwner;
private _session = PMCA_sessions getOrDefault [_owner, createHashMap];
if (count _session == 0 || {_session getOrDefault ["closing", false]}) exitWith {};
_session set ["closing", true];
[_owner, _claim] spawn PMCA_fnc_commit;
