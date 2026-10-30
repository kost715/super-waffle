// [unit, class] -> how many of the item or magazine the unit carries; the class name is
// matched without regard to case (== on strings), as CBA settings are typed in by hand.
params ["_unit", "_class"];
{_x == _class} count ((items _unit) + (magazines _unit))
