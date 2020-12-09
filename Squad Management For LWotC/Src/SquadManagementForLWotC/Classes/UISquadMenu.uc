//----------------------------------------------------------------------------
//	FILE:		UISquadMenu.uc
//	AUTHOR:		Keith (kdm2k6)
//	PURPOSE:	A menu which lets you choose which squad to view within the Squad Select screen.
//----------------------------------------------------------------------------
class UISquadMenu extends UIScreen;

var localized string SquadManagementStr, TitleStr, OpenSquadMenuStr;

var int PanelH, PanelW;
var int BorderPadding;

var UIPanel MainPanel;
var UIBGBox ListBG;
var UIText ListTitle;
var UIX2PanelHeader LeftDiagonals, RightDiagonals;
var UIPanel DividerLine;
var UIList List;

var array<StateObjectReference> SquadRefs;

// KDM : If we are exiting the Squad Management screen and entering the Squad Menu, we want to maintain 
// selection consistency. To do this, save the cached squad within Squad Management screen's OnRemoved and 
// use it within Squad Menu's OnReceiveFocus.
var XComGameState_LWPersistentSquad CachedSquad;

simulated function OnInit()
{
	super.OnInit();

	MC.FunctionVoid("AnimateIn");
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int NextY;
	local string TitleHtmlStr;

	super.InitScreen(InitController, InitMovie, InitName);

	// KDM : Container which will hold our UI components : it's invisible.
	MainPanel = Spawn(class'UIPanel', self);
	MainPanel.bIsNavigable = false;
	MainPanel.InitPanel();
	MainPanel.SetPosition((Movie.UI_RES_X / 2) - (PanelW / 2), (Movie.UI_RES_Y / 2) - (PanelH / 2));

	// KDM : Background rectangle.
	ListBG = Spawn(class'UIBGBox', MainPanel);
	ListBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	ListBG.InitBG(, 0, 0, PanelW, PanelH);

	// KDM : Header text.
	ListTitle = Spawn(class'UIText', MainPanel);
	ListTitle.InitPanel();
	TitleHtmlStr = class'UIUtilities_Text'.static.GetColoredText(TitleStr, eUIState_Header, 32);
	ListTitle.SetHtmlText(TitleHtmlStr, TitleStrSizeRealized);
	ListTitle.SetPosition(BorderPadding, BorderPadding);
	
	// KDM : Diagonals to the left of the Header; makes use of a UIX2PanelHeader.
	LeftDiagonals = Spawn(class'UIX2PanelHeader', MainPanel);
	LeftDiagonals.bIsNavigable = false;
	LeftDiagonals.InitPanelHeader(, "Temporary Setup Text");
	LeftDiagonals.SetText("");
	
	// KDM : Diagonals to the right of the Header; makes use of a UIX2PanelHeader.
	RightDiagonals = Spawn(class'UIX2PanelHeader', MainPanel);
	RightDiagonals.bIsNavigable = false;
	RightDiagonals.InitPanelHeader(, "Temporary Setup Text");
	RightDiagonals.SetText("");

	NextY = ListTitle.Y + 45;

	// KDM : Thin dividing line.
	DividerLine = Spawn(class'UIPanel', MainPanel);
	DividerLine.bIsNavigable = false;
	DividerLine.LibID = class'UIUtilities_Controls'.const.MC_GenericPixel;
	DividerLine.InitPanel();
	DividerLine.SetPosition(BorderPadding, NextY);
	DividerLine.SetWidth(PanelW - (BorderPadding * 2));
	DividerLine.SetAlpha(30);

	NextY += 10;

	// KDM : List which will hold rows of UISquadMenu_ListItems.
	List = Spawn(class'UIList', MainPanel);
	List.bAnimateOnInit = false;
	List.bIsNavigable = true;
	List.bStickyHighlight = false;
	List.ItemPadding = 6;
	List.InitList(, BorderPadding, NextY, PanelW - (BorderPadding * 2) - 20, PanelH - NextY - BorderPadding);
	
	RefreshData();
	UpdateSelection(false);
	
	UpdateNavHelp();
}

simulated function RefreshData()
{
	UpdateData();
	UpdateList();
}

// KDM : This code is based on the LW function : UISquad_DropDown.UpdateData().
simulated function UpdateData()
{
	local int i;
	local XComGameState_LWPersistentSquad Squad;
	local XComGameState_LWSquadManager SquadManager;
	
	SquadManager = `LWSQUADMGR;

	SquadRefs.Length = 0;

	// KDM : Fill the SquadRefs array.
	for (i = 0; i < SquadManager.Squads.Length; i++)
	{
		Squad = SquadManager.GetSquad(i);

		if ((!Squad.bOnMission) && (Squad.CurrentMission.ObjectID == 0))
		{
			SquadRefs.AddItem(Squad.GetReference());
		}
	}
}

simulated function UpdateList()
{
	List.ClearItems();
	PopulateList();
}

simulated function UpdateSelection(optional bool UseCachedSquad = false)
{
	local StateObjectReference SquadRef;
	
	Navigator.SetSelected(List);

	// KDM : Get the last squad viewed in the Squad Management screen, before it was closed.
	if (UseCachedSquad && CachedSquad != none)
	{
		SquadRef = CachedSquad.GetReference();
	}
	// KDM : Get the squad currently visible in the Squad Select screen.
	else
	{
		SquadRef = `LWSQUADMGR.LaunchingMissionSquad;
	}
	
	// KDM : Select the list item corresponding to the squad we retrieved above.
	class'Utilities_ForControllers'.static.SetSelectedIndexWithScroll(List,
		class'Utilities_ForControllers'.static.ListIndexFromSquadReference(List, SquadRef), 
		true);
}

simulated function PopulateList()
{
	local int i;
	local UISquadMenu_ListItem ListItem;
	
	for (i = 0; i < SquadRefs.Length; i++)
	{
		ListItem = Spawn(class'UISquadMenu_ListItem',List.itemContainer);
		ListItem.InitListItem(SquadRefs[i], false, self);
		ListItem.Update();
	}
}

function TitleStrSizeRealized()
{
	local int DiagonalsWidth;

	// KDM : Border padding is placed between the title and diagonals, as well as between the diagonals 
	// and panel edges.
	DiagonalsWidth = (PanelW - (4 * BorderPadding) - ListTitle.Width) / 2;

	// KDM : Center the title.
	ListTitle.SetX((PanelW / 2) - (ListTitle.Width / 2));

	// KDM : Position the left & right diagonals and set their widths. Unfortunately this requires a bit 
	// of hacking since the only way to get diagonals is to use empty UIX2PanelHeader's which : 
	// 1.] Don't expect to be empty 
	// 2.] Have ActionScript padding built into them 
	// 3.] Seem to display differently depending upon whether their 'supposed text' is to the left of 
	// the diagonals or right of the diagonals. 
	// 
	// Basically, we do the best we can, and that turns out to be pretty good !
	LeftDiagonals.SetPosition(BorderPadding, BorderPadding);
	LeftDiagonals.SetHeaderWidth(DiagonalsWidth + 10, true);
	RightDiagonals.SetPosition(ListTitle.X + ListTitle.Width + BorderPadding, BorderPadding);
	RightDiagonals.SetHeaderWidth(DiagonalsWidth + 10, true);
}

simulated function OnSquadSelected(StateObjectReference SelectedSquadRef)
{
	local robojumper_UISquadSelect SquadSelectScreen;
	local UISquadMenu_ListItem CurrentSquadIcon;
	
	SquadSelectScreen = class'Utilities_ForControllers'.static.GetRobojumpersSquadSelectFromStack();
	
	// KDM : Update the underlying LW squad data.
	class'Utilities_ForControllers'.static.SetSquad(SelectedSquadRef);

	// KDM : Update the current squad icon on the Squad Select screen.
	CurrentSquadIcon = UISquadMenu_ListItem(SquadSelectScreen.GetChildByName(
		'CurrentSquadIconForController', false));
	if (CurrentSquadIcon != none)
	{
		CurrentSquadIcon.SquadRef = SelectedSquadRef;
		CurrentSquadIcon.Update();
	}

	// KDM : Close the Squad Menu once a squad has been selected.
	CloseScreen();
}

simulated function OpenSquadManagement()
{
	local UIPersonnel_SquadBarracks_ForControllers SquadManagementScreen;
	
	SquadManagementScreen = `HQPRES.Spawn(class'UIPersonnel_SquadBarracks_ForControllers', `HQPRES);
	`HQPRES.ScreenStack.Push(SquadManagementScreen);
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	NavHelp =`HQPRES.m_kAvengerHUD.NavHelp;
	
	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = true;
	NavHelp.AddBackButton();
	NavHelp.AddSelectNavHelp();
	NavHelp.AddLeftHelp(SquadManagementStr, class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
	NavHelp.Show();
}

simulated function CloseScreen()
{
	local robojumper_UISquadSelect SquadSelectScreen;
	
	SquadSelectScreen = class'Utilities_ForControllers'.static.GetRobojumpersSquadSelectFromStack();
	
	if (SquadSelectScreen != none)
	{
		// KDM : Update the Squad Select screen data since we might have entered the Squad Management screen, 
		// via the Squad Menu, and made any number of squad modifications. If we don't do this, we may end 
		// up with a 'dirty' Squad Select screen.
		SquadSelectScreen.UpdateData();
	}

	super.CloseScreen();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	// KDM : Update the Squad Menu list since we might have entered the Squad Management screen and made 
	// any number of squad modifications. If we don't do this, we may end up with a 'dirty' Squad Menu.
	RefreshData();
	UpdateSelection(true);

	UpdateNavHelp();
}

simulated function OnLoseFocus()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();

	super.OnLoseFocus();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	bHandled = true;

	// KDM : Let the list handle the input first.
	if (List.OnUnrealCommand(cmd, arg))
	{
		return true;
	}

	switch (cmd)
	{
		// KDM : B button closes the screen.
		case class'UIUtilities_Input'.static.GetBackButtonInputCode() :
			// KDM : Even though no squad was selected, the current squad could have been modified via the 
			// Squad Management screen. Therefore, call OnSquadSelected to guarantee we don't end up with a 
			// 'dirty' Squad Select screen.
			OnSquadSelected(`LWSQUADMGR.LaunchingMissionSquad);
			break;

		// KDM : Left stick click opens the Squad Management screen.
		case class'UIUtilities_Input'.const.FXS_BUTTON_L3:
			OpenSquadManagement();
			break;
		
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	// KDM : Attach a black overlay, mouse guard, by setting bConsumeMouseEvents to true.
	bConsumeMouseEvents = true;
	InputState = eInputState_Consume;

	BorderPadding = 10;

	PanelW = 400;
	PanelH = 450;
}
