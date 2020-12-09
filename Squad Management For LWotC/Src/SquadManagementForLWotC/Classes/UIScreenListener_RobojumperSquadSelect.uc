//----------------------------------------------------------------------------
//	FILE:		UIScreenListener_RobojumperSquadSelect.uc
//	AUTHOR:		Keith (kdm2k6)
//	PURPOSE:	A screen listener which places an icon on the Squad Select screen denoting the current squad.
//				It also allows you to open the Squad Menu with left stick click.
//----------------------------------------------------------------------------
class UIScreenListener_RobojumperSquadSelect extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UISquadMenu_ListItem CurrentSquadIcon;
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPRES;

	HQPres.ScreenStack.SubscribeToOnInputForScreen(Screen, OnRobojumperSquadSelectClick);

	// KDM : Icon, on the Squad Select screen, showing the currently selected squad.
	CurrentSquadIcon = Screen.Spawn(class'UISquadMenu_ListItem', Screen);
	CurrentSquadIcon.MCName = 'CurrentSquadIconForController';
	CurrentSquadIcon.SquadRef = `LWSQUADMGR.LaunchingMissionSquad;
	CurrentSquadIcon.bAnimateOnInit = false;
	CurrentSquadIcon.bIsNavigable = false;
	// LW : Create on a timer to avoid creation issues that arise when no pawn loading has occurred.
	CurrentSquadIcon.DelayedInit(0.75f);
}

simulated function bool OnRobojumperSquadSelectClick(UIScreen Screen, int cmd, int arg)
{
	if (!Screen.CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	// KDM : If we are viewing the Squad Select screen through : Squad Management screen --> View current squad, 
	// we only want the user to be able to 1.] Select soldiers with the DPad 2.] Close the screen with the B buton.
	if (class'Utilities_ForControllers'.static.StackHasSquadBarracksForControllers())
	{
		switch(cmd)
		{
			case class'UIUtilities_Input'.static.GetBackButtonInputCode():
			case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
			case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
			case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
				// KDM : Allow DPad and B button inputs through.
				return false;
				break;

			default:
				// KDM : Make sure all other inputs are not allowed through.
				return true;
				break;
		}
	}
	// KDM : If we are viewing the Squad Select screen normally, allow the user to open the Squad Menu 
	// with left stick click.
	else
	{
		// KDM : Left stick click opens up the Squad Menu.
		if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_L3)
		{
			OpenSquadMenu(Screen);
			return true;
		}
	}
	
	return false;
}

simulated function OpenSquadMenu(UIScreen Screen)
{
	local robojumper_UISquadSelect SquadSelectScreen;
	local UISquadMenu SquadMenu;
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPRES;
	SquadSelectScreen = robojumper_UISquadSelect(Screen);

	if (SquadSelectScreen == none)
	{
		`log("*** KDM ERROR : UIScreenListener_RobojumperSquadSelect.OpenSquadMenu : SquadSelectScreen == none ***");
		return;
	}

	SquadMenu = HQPres.Spawn(class'UISquadMenu', HQPres);

	// KDM : If Robojumper's Squad Select has the option "Skip Intro" turned on, bInstantLineupUI = true.
	if (!SquadSelectScreen.bInstantLineupUI)
	{
		// KDM : Finish the intro 'walk-in' cinematic since we are opening up the Squad Menu.
		SquadSelectScreen.FinishIntroCinematic();
	}

	HQPres.ScreenStack.Push(SquadMenu);

	if (!SquadSelectScreen.bInstantLineupUI)
	{
		// KDM : Very strange problem that exists even with Robojumper's Squad Select and a normal game.
		// robojumper_UISquadSelect.OnLoseFocus sets bDirty to true; however, UISquadSelect.Cinematic_PawnsIdling.BeginState
		// only calls SnapCamera if bDirty is false. Without this call to SnapCamera, the camera suddenly zooms into the
		// squad's waist upon entering the idle state. Since I am only bringing up a menu, and the menu buttons update data 
		// whenever they need to, setting bDirty to false seems fairly safe.
		SquadSelectScreen.bDirty = false;
	}
}

event OnRemoved(UIScreen Screen)
{
	`HQPRES.ScreenStack.UnsubscribeFromOnInputForScreen(Screen, OnRobojumperSquadSelectClick);
}

defaultproperties
{
	ScreenClass = class'robojumper_UISquadSelect';
}
