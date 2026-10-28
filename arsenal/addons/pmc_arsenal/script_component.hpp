// Stand-ins for the Antistasi core macros used by the arsenal sources.
#define PMCA_QUOTE(var) #var
#define QPATHTOFOLDER(var) PMCA_QUOTE(\pmc_arsenal\var)
#define FIX_LINE_NUMBERS()
#define Info(msg) diag_log text format ["[PMCA] %1", msg]
#define Info_1(msg,arg1) diag_log text format ["[PMCA] %1 %2", msg, arg1]
#define Error(msg) diag_log text format ["[PMCA] ERROR: %1", msg]
#define Verbose(msg)
// Optional mods, detected by their config instead of Antistasi globals.
#define PMCA_HAS_TFAR (isClass (configFile >> "CfgPatches" >> "tfar_core") || {isClass (configFile >> "CfgPatches" >> "task_force_radio")})
#define PMCA_HAS_ACE (isClass (configFile >> "CfgPatches" >> "ace_main"))
#define PMCA_HAS_ACE_MEDICAL (isClass (configFile >> "CfgPatches" >> "ace_medical"))
