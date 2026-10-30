// [code] -> true for a lock code: 4 to 6 digits.
params [["_code", "", [""]]];
count _code >= 4 && {count _code <= 6} && {((toArray _code) findIf {_x < 48 || {_x > 57}}) < 0}
