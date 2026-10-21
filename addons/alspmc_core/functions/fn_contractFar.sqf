// The exclusion circle is never smaller than the requested 2 km.
// Margin reserves room for scattered enemies/vehicles around a mission centre.
params ["_base", "_pos", ["_margin", 0]];
if (count _base < 2 || {count _pos < 2}) exitWith {false};
private _minimum = (getNumber (configFile >> "ALSPMC_Settings" >> "contractMinBaseDistance")) max 2000;
(_base distance2D _pos) >= _minimum + (_margin max 0)
