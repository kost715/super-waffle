// Trusted controller supplies validated companies. No direct RPC registration.
params [["_a", "", [""]], ["_b", "", [""]], ["_relation", "", [""]]];
if (!isServer || {!(_a in PMCS_companies)} || {!(_b in PMCS_companies)} || {_a == _b} || {
    !(_relation in ["neutral", "hostile"])
}) exitWith {false};
PMCS_relations set [[_a, _b] call PMCS_fnc_pairKey, _relation];
true
