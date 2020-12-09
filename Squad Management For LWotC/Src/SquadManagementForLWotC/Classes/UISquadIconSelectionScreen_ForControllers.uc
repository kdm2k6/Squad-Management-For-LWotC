//----------------------------------------------------------------------------
//	FILE:		UISquadIconSelectionScreen_ForControllers.uc
//	AUTHOR:		Robojumper with a modification by KDM
//	PURPOSE:	A slight modification of Robojumper's Squad Icon Selector mod.
//----------------------------------------------------------------------------
class UISquadIconSelectionScreen_ForControllers extends UIScreen config(SquadSettings);

// KDM : Screen reference needed for callbacks.
var UIPersonnel_SquadBarracks_ForControllers BelowScreen;

var config int ScreenW, ScreenH;

var UIPanel MainPanel;
var UIX2PanelHeader ScreenHeader;
var UIBGBox ScreenBG;

var UIImageSelector_LW ImageSelector;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local float XLoc, YLoc;
	local float WidthVal, HeightVal;

	super.InitScreen(InitController, InitMovie, InitName);

	XLoc = (1920 - ScreenW) / 2;
	YLoc = (1080 - ScreenH) / 2;
	WidthVal = ScreenW;
	HeightVal = ScreenH;

	MainPanel = Spawn(class'UIPanel', self);
	MainPanel.InitPanel('');
	MainPanel.SetPosition(XLoc, YLoc);
	MainPanel.SetSize(WidthVal, HeightVal);

	ScreenBG = Spawn(class'UIBGBox', MainPanel);
	ScreenBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	ScreenBG.InitBG('', 0, 0, MainPanel.Width, MainPanel.Height);
	
	ScreenHeader = Spawn(class'UIX2PanelHeader', MainPanel);
	ScreenHeader.bIsNavigable = false;
	ScreenHeader.InitPanelHeader('', "Select Squad Image", "");
	ScreenHeader.SetHeaderWidth(MainPanel.width - 20);
	ScreenHeader.SetPosition(10, 20);

	ImageSelector = Spawn(class'UIImageSelector_LW', MainPanel);
	ImageSelector.InitImageSelector(, 0, 70, MainPanel.Width - 10, MainPanel.height - 80, 
		BelowScreen.SquadImagePaths, , SetSquadImage, 
		BelowScreen.SquadImagePaths.Find(BelowScreen.GetCurrentSquad().SquadImagePath));
}

function SetSquadImage(int ImageIndex)
{
	local XComGameState NewGameState;
	local XComGameState_LWPersistentSquad CurrentSquadState;

	CurrentSquadState = BelowScreen.GetCurrentSquad();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Change Squad ImagePath");
	CurrentSquadState = XComGameState_LWPersistentSquad(NewGameState.CreateStateObject(class'XComGameState_LWPersistentSquad', CurrentSquadState.ObjectID));
	CurrentSquadState.SquadImagePath = BelowScreen.SquadImagePaths[ImageIndex];
	NewGameState.AddStateObject(CurrentSquadState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	BelowScreen.UpdateSquadUI();
	
	OnCancel();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	bHandled = true;
	
	switch (cmd)
	{
		case class'UIUtilities_Input'.static.GetBackButtonInputCode():
			OnCancel();
			break;
		
		default:
			bHandled = false;
			break;
	}

	return (bHandled || super.OnUnrealCommand(cmd, arg));
}

simulated function OnCancel()
{
	BelowScreen.bHideOnLoseFocus = true;
	CloseScreen();
}

defaultproperties
{
	bConsumeMouseEvents = true
	InputState = eInputState_Consume;
}
