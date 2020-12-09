// ===================================================
// =============== General Mod Notes =================
// ===================================================
It is best to turn off 'autofill squds' within Robojumper's Squad Select or else empty LW squads become filled with 
soldiers who are not actually part of the squad.




// ===================================================
// =========== Integration with LWotC 1 ==============
// ===================================================
For proper integration with LWotC, I need to look for any situation in which 'UIPersonnel_SquadBarracks' is dealt with.
In particular, I need to be concerned with screen stack checks for 'UIPersonnel_SquadBarracks'.
 
// ======================= 1 =========================
FILE : UIPersonnel_SquadBarracks
FUNCTION : OnSquadIconClicked()
DESCRIPTION : BelowScreen is set to a screen of type 'UIPersonnel_SquadBarracks'.
SOLUTION : My custom class, 'UIPersonnel_SquadBarracks_ForControllers' sets BelowScreen to itself, within EditSquadIcon().
STATUS : SOLVED

// ======================= 2 =========================
FILE : UIScreenListener_LivingQuarters
SOLUTION : This class is deprecated and no longer used.
STATUS : SOLVED

// ======================= 3 =========================
FILE : UIScreenListener_LWOfficerPack
FUNCTION : CheckOfficerMissionStatus()
DESCRIPTION : The event OverrideGetPersonnelStatusSeparate calls CheckOfficerMissionStatus() which returns ELR_NoInterrupt if :
	1.] You are not in the Squad Select screen 2.] 'UIPersonnel_SquadBarracks' is not on the screen stack.
SOLUTION : I now also make sure :
	1.] 'UIPersonnel_SquadBarracks_ForControllers' is not on the screen stack, if a controller is active.
NOTE : Although I solved this problem, this particular event is never actually triggered.
STATUS : SOLVED

// ======================= 4 =========================
FILE : UIScreenListener_SquadSelect_LW
FUNCTION : OnInit()
DESCRIPTION : Sets bInSquadEdit to true if 'UIPersonnel_SquadBarracks' is on the screen stack, and false otherwise.
SOLUTION: Also sets bInSquadEdit to true if a controller is active, and 'UIPersonnel_SquadBarracks_ForControllers' is on the screen stack.
STATUS : SOLVED

// ======================= 5 =========================
FILE : UIScreenListener_SquadSelect_LW
FUNCTION : OnSquadManagerClicked()
DESCRIPTION : Spawns a 'UIPersonnel_SquadBarracks' screen if 'UIPersonnel_SquadBarracks' is not on the screen stack.
SOLUTION : Spawning a 'UIPersonnel_SquadBarracks' also requires 'UIPersonnel_SquadBarracks_ForControllers' not be on the screen stack.
NOTE : This function is never called.
STATUS : SOLVED

// ======================= 6 =========================
FILE : UIScreenListener_SquadSelect_LW
FUNCTION : OnSaveSquad()
SOLUTION : This functionality has been disabled, and the function is no longer called when a controller is active.
STATUS : SOLVED

// ======================= 7 =========================
FILE : UISquadContainer
FUNCTION : OnSquadManagerClicked()
SOLUTION : UISquadContainers are no longer spawned when a controller is active; therefore, this function will never be called.
STATUS : SOLVED

// ======================= 8 =========================
FILE : UISquadIconSelectionScreen
DESCRIPTION : BelowScreen is a screen of type 'UIPersonnel_SquadBarracks'.
SOLUTION : My custom class, 'UISquadIconSelectionScreen_ForControllers' solves this issue; BelowScreen is now a screen of type 'UIPersonnel_SquadBarracks_ForControllers'.
STATUS : SOLVED

// ======================= 9 =========================
FILE : X2EventListener_Soldiers
FUNCTION : OnOverridePersonnelStatus()
DESCRIPTION : Enters an else-if statement if 'UIPersonnel_SquadBarracks' is not on the screen stack.
SOLUTION : Entering the else-if statement also requires 'UIPersonnel_SquadBarracks_ForControllers' not be on the screen stack.
NOTE : The event, OverridePersonnelStatus, which calls OnOverridePersonnelStatus() is never triggered.
STATUS : SOLVED

// ======================= 10 =========================
FILE : XComGameState_LWSquadManager
FUNCTION : GoToSquadManagement()
DESCRIPTION : Spawns a 'UIPersonnel_SquadBarracks' screen if 'UIPersonnel_SquadBarracks' is not on the screen stack.
SOLUTION : Spawning a 'UIPersonnel_SquadBarracks' also requires 'UIPersonnel_SquadBarracks_ForControllers' not be on the screen stack.
NOTE : This is called when the Squad Management Avenger menu button is clicked.
STATUS : SOLVED

// ======================= 11 =========================
FILE : XComGameState_LWSquadManager
FUNCTION : SetDisabledSquadListItems()
DESCRIPTION : Sets bInSquadEdit to true if 'UIPersonnel_SquadBarracks' is on the screen stack, and false otherwise.
SOLUTION: Also sets bInSquadEdit to true if a controller is active, and 'UIPersonnel_SquadBarracks_ForControllers' is on the screen stack.
NOTE : The event OnSoldierListItemUpdateDisabled(), which is called in UIScreenListener_PersonnelSquadSelect.FireEvents(), calls SetDisabledSquadListItems(). 
STATUS : SOLVED

// ======================= 12 =========================
FILE : XComGameState_LWSquadManager
FUNCTION : ConfigureSquadOnEnterSquadSelect()
DESCRIPTION : Sets bInSquadEdit to true if 'UIPersonnel_SquadBarracks' is on the screen stack, and false otherwise.
SOLUTION: Also sets bInSquadEdit to true if a controller is active, and 'UIPersonnel_SquadBarracks_ForControllers' is on the screen stack.
NOTE : The event OnUpdateSquadSelectSoldiers calls ConfigureSquadOnEnterSquadSelect(); however, this event is never triggered.
STATUS : SOLVED

// ===================================================
// =========== Integration with LWotC 2 ==============
// ===================================================
Go through the variables at the top of UIPersonnel_SquadBarracks and make sure they aren't referenced in other files. 
If they are, make sure everything syncs up.

VARIABLE : bHideSelect
DESCRIPTION : It is never set anywhere; therefore it is always false and can be ignored.
STATUS : SOLVED

VARIABLE : bSelectSquad
DESCRIPTION : I no longer make use of this variable; however, it is referenced elsewhere so I have left it in 'UIPersonnel_SquadBarracks_ForControllers'.
STATUS : SOLVED

VARIABLE : ExternalSelectedSquadRef
DESCRIPTION : It is never set anywhere; therefore it is always false and can be ignored.
STATUS : SOLVED

VARIABLE : CachedSquad
DESCRIPTION : It is dealt with in UIPersonnel_SquadBarracks : OnReceiveFocus(), and OnEditOrSelectClicked(). I now make use of it for my own purposes and
have renamed it CachedSquadBeforeViewing.
STATUS : SOLVED

VARIABLE : bRestoreCachedSquad
DESCRIPTION : It is dealt with in UIPersonnel_SquadBarracks : OnReceiveFocus(), and OnEditOrSelectClicked(). I now make use of my own variable, RestoreCachedSquadAfterViewing.
STATUS : SOLVED

VARIABLE : CurrentSquadSelection
DESCRIPTION : In addition to normal usage in 'UIPersonnel_SquadBarracks', it is dealt with in UIScreenListener_SquadSelect_LW.OnSaveSquad().
I now make use of my own variable, CurrentSquadIndex, within 'UIPersonnel_SquadBarracks_ForControllers'; furthermore, OnSaveSquad is never called when a controller is active.
STATUS : SOLVED
