// [unit, game] -> true when this unit's action becomes a hands-on game: the unit is
// this machine's player, the game is enabled, and the player is not acting from Zeus.
params ["_unit", "_game"];
hasInterface && {_unit isEqualTo player} && {missionNamespace getVariable ["PMCI_enable_" + _game, true]} && {isNull findDisplay 312}
