// Candidate model for S1 only. CIVILIAN remains reserved for neutral actors.
params [["_count", 3, [0]]];
if !(_count in [1,2,3]) exitWith {[]};
private _rows = [["alpha", "Alpha", west], ["bravo", "Bravo", east], ["charlie", "Charlie", resistance]];
_rows select [0, _count]
