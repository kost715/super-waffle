// Client -> server: the ATM screen was closed; no more updates for it.
if (!isServer || {isNil "PMCB_viewers"}) exitWith {};
PMCB_viewers deleteAt (call PMCB_fnc_requestOwner);
