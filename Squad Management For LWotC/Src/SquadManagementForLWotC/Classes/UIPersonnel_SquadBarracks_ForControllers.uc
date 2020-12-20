//----------------------------------------------------------------------------
//	FILE:		UIPersonnel_SquadBarracks_ForControllers.uc
//	AUTHOR:		Keith (kdm2k6)
//	PURPOSE:	A custom, controller-capable Squad Management screen designed 
//				nearly from scratch.
//----------------------------------------------------------------------------
class UIPersonnel_SquadBarracks_ForControllers extends UIPersonnel_SquadBarracks config(SquadSettings);

// KDM NEW NOTE : I don't use UIPersonnel_SquadBarracks's bSelectSquad.
// KDM NEW NOTE : SquadImagePaths is needed for the Squad Icon Selector.

// KDM : Allows us to restore the current 'mission squad' after 'viewing' its soldiers.
var StateObjectReference CachedSquadBeforeViewing;
var bool RestoreCachedSquadAfterViewing;

var localized string TitleStr, NoSquadsStr, DashesStr, StatusStr, MissionsStr, BiographyStr, SquadSoldiersStr, AvailableSoldiersStr;
var localized string FocusUISquadStr, FocusUISoldiersStr, CreateSquadStr, DeleteSquadStr, PrevSquadStr, NextSquadStr, ChangeSquadIconStr,
	RenameSquadStr, EditSquadBioStr, ScrollSquadBioStr, ViewSquadStr, ViewSquadSoldiersStr, ViewAvailableSoldierStr, TransferToSquadStr,
	RemoveFromSquadStr;

// KDM : Determines whether the squad UI, located at the top, or the soldier UI, located at the bottom, 
// is focused.
var bool SoldierUIFocused;

// KDM : Determines whether the soldier UI list is displaying 'available soldiers', or the current 
// squad's soldiers.
var bool DisplayingAvailableSoldiers;

var int CurrentSquadIndex;

var int PanelW, PanelH;

var int BorderPadding; 
var int SquadIconBorderSize, SquadIconSize;

var UIPanel MainPanel;
var UIBGBox SquadBG;
var UIX2PanelHeader SquadHeader;
var UIPanel DividerLine;
var UIPanel SquadIconBG1, SquadIconBG2;
var UIImage CurrentSquadIcon;
var UIScrollingText CurrentSquadStatus, CurrentSquadMissions;
var UITextContainer CurrentSquadBio;
var UIList SoldierIconList;
var UIButton SquadSoldiersTab, AvailableSoldiersTab;

// KDM : Apparently UE3 hates boolean arrays, so we'll go with an int array instead.
var int CachedNavHelp[7];

// KDM : These functions are overridden in UIPersonnel_SquadBarracks; however, my code was created
// with the intention that their base version would be called. Make it so !
simulated function CloseScreen() { super(UIPersonnel).CloseScreen(); }
simulated function CreateSortHeaders() { super(UIPersonnel).CreateSortHeaders(); }
simulated function UpdateData() { super(UIPersonnel).UpdateData(); }

simulated function OnInit()
{
	super(UIPersonnel).OnInit();

	// KDM : Hide pre-built UI elements we won't be using via Flash; the alternative is to : 
	// 1.] Spawn them 2.] Init them with the appropriate MC name 3.] Hide them.
	MC.ChildFunctionVoid("SoldierListBG", "Hide");
	MC.ChildFunctionVoid("deceasedSort", "Hide");
	MC.ChildFunctionVoid("personnelSort", "Hide");
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int AvailableW, XLoc, YLoc, HeightVal, WidthVal;

	super(UIScreen).InitScreen(InitController, InitMovie, InitName);

	// KDM : Fill in the sort type array since its original setup function, UIPersonnel.SwitchTab, is no 
	// longer called.
	m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Rank);
	m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Name);
	m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Class);
	m_aSortTypeOrder.AddItem(ePersonnelSoldierSortType_Status);

	// KDM : Container which will hold our UI components; it's invisible.
	MainPanel = Spawn(class'UIPanel', self);
	MainPanel.bIsNavigable = false;
	MainPanel.InitPanel();
	MainPanel.SetPosition((Movie.UI_RES_X / 2) - (PanelW / 2), (Movie.UI_RES_Y / 2) - (PanelH / 2));

	// KDM : Background rectangle.
	SquadBG = Spawn(class'UIBGBox', MainPanel);
	SquadBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	SquadBG.InitBG(, 0, 0, PanelW, PanelH);

	// KDM : Header which displays the current squad's name.
	XLoc = BorderPadding;
	YLoc = BorderPadding;
	WidthVal = PanelW - (BorderPadding * 2);
	SquadHeader = Spawn(class'UIX2PanelHeader', MainPanel);
	SquadHeader.bIsNavigable = false;
	SquadHeader.InitPanelHeader(, "Current Squad Name");
	SquadHeader.SetPosition(XLoc, YLoc);
	SquadHeader.SetHeaderWidth(WidthVal);
	
	// KDM : Thin dividing line.
	XLoc = BorderPadding;
	YLoc = SquadHeader.Y + 45;
	WidthVal = PanelW - (BorderPadding * 2);
	DividerLine = Spawn(class'UIPanel', MainPanel);
	DividerLine.bIsNavigable = false;
	DividerLine.LibID = class'UIUtilities_Controls'.const.MC_GenericPixel;
	DividerLine.InitPanel();
	DividerLine.SetPosition(XLoc, YLoc);
	DividerLine.SetWidth(WidthVal);
	DividerLine.SetAlpha(30);
	
	// KDM : Current squad icon's 'background 1'; this is located behind 'background 2'.
	XLoc = BorderPadding;
	YLoc = DividerLine.Y + 10;
	WidthVal = SquadIconBorderSize + SquadIconSize + SquadIconBorderSize;
	HeightVal = SquadIconBorderSize + SquadIconSize + SquadIconBorderSize;
	SquadIconBG1 = Spawn(class'UIPanel', MainPanel);
	SquadIconBG1.bIsNavigable = false;
	SquadIconBG1.LibID = class'UIUtilities_Controls'.const.MC_GenericPixel;
	SquadIconBG1.InitPanel();
	SquadIconBG1.SetPosition(XLoc, YLoc);
	SquadIconBG1.SetSize(WidthVal, HeightVal);
	SquadIconBG1.SetColor("0x333333");
	SquadIconBG1.SetAlpha(80);

	// KDM : Current squad icon's 'background 2'.
	XLoc = SquadIconBG1.X + SquadIconBorderSize;
	YLoc = SquadIconBG1.Y + SquadIconBorderSize;
	WidthVal = SquadIconSize;
	HeightVal = SquadIconSize;
	SquadIconBG2 = Spawn(class'UIPanel', MainPanel);
	SquadIconBG2.bIsNavigable = false;
	SquadIconBG2.LibID = class'UIUtilities_Controls'.const.MC_GenericPixel;
	SquadIconBG2.InitPanel();
	SquadIconBG2.SetPosition(XLoc, YLoc);
	SquadIconBG2.SetSize(WidthVal, HeightVal);
	SquadIconBG2.SetColor("0x000000");
	SquadIconBG2.SetAlpha(100);

	// KDM : Current squad's icon.
	XLoc = SquadIconBG2.X;
	YLoc = SquadIconBG2.Y;
	CurrentSquadIcon = Spawn(class'UIImage', MainPanel);
	CurrentSquadIcon.InitImage();
	CurrentSquadIcon.SetPosition(XLoc, YLoc);
	CurrentSquadIcon.SetSize(SquadIconSize, SquadIconSize);
	
	// KDM : Current squad's status.
	XLoc = SquadIconBG1.X + SquadIconBG1.Width + BorderPadding;
	YLoc = DividerLine.Y + 10;
	WidthVal = PanelW - SquadIconSize - (BorderPadding * 3);
	CurrentSquadStatus = Spawn(class'UIScrollingText', MainPanel);
	CurrentSquadStatus.InitScrollingText(, "Current Squad Status", WidthVal, XLoc, YLoc);

	// KDM : Current squad's mission count.
	XLoc = CurrentSquadStatus.X;
	YLoc = CurrentSquadStatus.Y;
	WidthVal = CurrentSquadStatus.Width;
	CurrentSquadMissions = Spawn(class'UIScrollingText', MainPanel);
	CurrentSquadMissions.InitScrollingText(, "Current Squad Missions", WidthVal, XLoc, YLoc);

	// KDM : List of icons representing soldiers in the squad.
	XLoc = CurrentSquadStatus.X;
	YLoc = CurrentSquadStatus.Y + 32;
	WidthVal = PanelW - SquadIconSize - (BorderPadding * 3);
	HeightVal = 48;
	SoldierIconList = Spawn(class'UIList', MainPanel);
	SoldierIconList.InitList(, XLoc, YLoc, WidthVal, HeightVal, true);

	// KDM : Current squad's biography.
	XLoc = CurrentSquadStatus.X;
	YLoc = SoldierIconList.Y + SoldierIconList.Height;
	WidthVal = PanelW - SquadIconSize - (BorderPadding * 3);
	HeightVal = 85;
	CurrentSquadBio = Spawn(class'UITextContainer', MainPanel);
	CurrentSquadBio.InitTextContainer(, "", XLoc, YLoc, WidthVal, HeightVal, false, , false);
	CurrentSquadBio.SetText("Current Squad Bio");
	
	AvailableW = PanelW - (BorderPadding * 3);

	// KDM : Current squad soldiers tab.
	XLoc = BorderPadding;
	YLoc = SquadIconBG1.Y + SquadIconBG1.Height + 14;
	WidthVal = int(float(AvailableW) * 0.5);
	SquadSoldiersTab = Spawn(class'UIButton', MainPanel);
	SquadSoldiersTab.ResizeToText = false;
	SquadSoldiersTab.InitButton(, SquadSoldiersStr, , eUIButtonStyle_NONE);
	SquadSoldiersTab.SetWarning(true);
	SquadSoldiersTab.SetPosition(XLoc, YLoc);
	SquadSoldiersTab.SetWidth(WidthVal);
	
	// KDM : Available soldiers tab.
	XLoc = SquadSoldiersTab.X + SquadSoldiersTab.Width + BorderPadding;
	YLoc = SquadSoldiersTab.Y;
	WidthVal = int(float(AvailableW) * 0.5);
	AvailableSoldiersTab = Spawn(class'UIButton', MainPanel);
	AvailableSoldiersTab.ResizeToText = false;
	AvailableSoldiersTab.InitButton(, AvailableSoldiersStr, , eUIButtonStyle_NONE);
	AvailableSoldiersTab.SetWarning(true);
	AvailableSoldiersTab.SetPosition(XLoc, YLoc);
	AvailableSoldiersTab.SetWidth(WidthVal);
	
	CreateSortableHeader();

	// KDM : Soldier list.
	XLoc = MainPanel.X + SquadSoldiersTab.X;
	YLoc = MainPanel.Y + SquadSoldiersTab.Y + 75;
	m_kList = Spawn(class'UIList', self);
	m_kList.bStickyHighlight = false;
	// KDM : I originally had the width equal to m_iMaskWidth - 20, so the list fit
	// perfectly within the background box; unfortunately, scrollbars would then overlap
	// pertinent information. Consequently, just use the same width that Long War used.
	m_kList.InitList('listAnchor', XLoc, YLoc, m_iMaskWidth, m_iMaskHeight);
	m_kList.MoveToHighestDepth();

	SetInitialCurrentSquadIndex();

	SetUIFocus(false, true);
	UpdateAll(true);

	InitializeCachedNav();
	UpdateNavHelp();
}

simulated function CreateSortableHeader()
{
	local int XLoc, YLoc;

	// KDM : Create the header container.
	XLoc = MainPanel.X + SquadSoldiersTab.X;
	YLoc = MainPanel.Y + SquadSoldiersTab.Y + 37;
	m_kSoldierSortHeader = Spawn(class'UIPanel', self);
	m_kSoldierSortHeader.bIsNavigable = false;
	m_kSoldierSortHeader.InitPanel('soldierSort', 'SoldierSortHeader');
	m_kSoldierSortheader.SetPosition(XLoc, YLoc);
	m_kSoldierSortHeader.MoveToHighestDepth();
	
	// KDM : Fill the header container with header buttons.
	Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton(
		"rankButton", ePersonnelSoldierSortType_Rank, m_strButtonLabels[ePersonnelSoldierSortType_Rank]);
	Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton(
		"nameButton", ePersonnelSoldierSortType_Name, m_strButtonLabels[ePersonnelSoldierSortType_Name]);
	Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton(
		"classButton", ePersonnelSoldierSortType_Class, m_strButtonLabels[ePersonnelSoldierSortType_Class]);
	Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton(
		"statusButton", ePersonnelSoldierSortType_Status, m_strButtonLabels[ePersonnelSoldierSortType_Status], m_strButtonValues[ePersonnelSoldierSortType_Status]);
}

simulated function UpdateAll(optional bool _ResetTabFocus = false, optional bool _ResetSortType = true)
{
	UpdateSquadUI();
	UpdateListUI(_ResetTabFocus, _ResetSortType);
}

// KDM : Updates the UI elements near the top of the screen; those concerned with general 'squad' attributes.
simulated function UpdateSquadUI()
{
	local int TextState;
	local string SquadTitle, SquadStatus, SquadMissions, SquadBio;
	local XComGameState_LWPersistentSquad CurrentSquadState;
	local XGParamTag ParamTag;
	
	CurrentSquadState = GetCurrentSquad();

	// KDM : If no squads exist, empty the UI then exit.
	if (!SquadsExist())
	{
		SquadHeader.SetText(NoSquadsStr);
		SquadHeader.MC.FunctionVoid("realize");
		CurrentSquadIcon.Hide();
		CurrentSquadStatus.SetHTMLText("");
		CurrentSquadMissions.SetHTMLText("");
		SoldierIconList.Hide();
		CurrentSquadBio.SetText("");
		return;
	}

	// KDM : Squads exist, yet no squad is selected; this shouldn't happen, so just exit.
	if (CurrentSquadState == none)
	{
		`log("*** KDM ERROR : UIPersonnel_SquadBarracks_ForControllers.UpdateSquadUI : Squads exist, yet there is no selection. ***");
		return;
	}

	// KDM : Set the squad title, which is of the form 'SQUAD [1/4] : NAME_OF_SQUAD'.
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = CurrentSquadIndex + 1;
	ParamTag.IntValue1 = GetTotalSquads();
	ParamTag.StrValue0 = CurrentSquadState.sSquadName;
	SquadTitle = `XEXPAND.ExpandString(TitleStr);
	
	SquadHeader.SetText(SquadTitle);
	// KDM : There is an ActionScript bug in UIX2PanelHeader which causes it to update its text only after 
	// realize is called. Unfortunately, SetText doesn't call realize, so we have to do it ourself.
	SquadHeader.MC.FunctionVoid("realize");

	// KDM : Set the squad icon; it also needs to be shown since, if no squads exist, it is hidden.
	CurrentSquadIcon.LoadImage(CurrentSquadState.GetSquadImagePath());
	CurrentSquadIcon.Show();
	
	// KDM : Set the squad status; it will be either 'ON MISSION' or 'AVAILABLE'.
	SquadStatus = CurrentSquadState.IsDeployedOnMission() ? 
		class'UISquadListItem'.default.sSquadOnMission : class'UISquadListItem'.default.sSquadAvailable;
	TextState = CurrentSquadState.IsDeployedOnMission() ? eUIState_Warning : eUIState_Good;
	SquadStatus = class'UIUtilities_Text'.static.GetColoredText(SquadStatus, TextState); 
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = SquadStatus;
	SquadStatus = `XEXPAND.ExpandString(StatusStr);
	SquadStatus = class'UIUtilities_Text'.static.GetSizedText(SquadStatus, 24);
	CurrentSquadStatus.SetHTMLText(SquadStatus);
	
	// KDM : Set the squad's mission count, which is of the form 'Missions : 1'.
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = CurrentSquadState.iNumMissions;
	SquadMissions = `XEXPAND.ExpandString(MissionsStr);
	SquadMissions = class'UIUtilities_Text'.static.GetColoredText(SquadMissions, eUIState_Normal, 24, "RIGHT"); 
	CurrentSquadMissions.SetHTMLText(SquadMissions);
	
	// KDM : Update the soldier icon list; it also needs to be shown since, if no squads exist, it is hidden.
	UpdateSoldierClassIcons(CurrentSquadState);
	SoldierIconList.Show();

	// KDM : Set the squad's biography.
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = CurrentSquadState.sSquadBiography;
	SquadBio = `XEXPAND.ExpandString(BiographyStr);
	CurrentSquadBio.SetText(SquadBio);
	ResetBiographyScroll();
}

// KDM : Updates the UI elements near the bottom of the screen; those concerned with a squad's soldiers.
simulated function UpdateListUI(optional bool _ResetTabFocus = false, optional bool _ResetSortType = true)
{
	if (_ResetTabFocus)
	{
		ResetTabFocus();
	}
	if (_ResetSortType)
	{
		ResetSortType();
	}

	UpdateListData();
	SortListData();
	UpdateList();

	UpdateListSelection();
}

simulated function UpdateListData()
{
	local XComGameState_LWSquadManager SquadManager;

	SquadManager = `LWSQUADMGR;
	m_arrSoldiers.Length = 0;

	if (!CurrentSquadIsValid())
	{
		return;
	}

	m_arrSoldiers = DisplayingAvailableSoldiers ? 
		SquadManager.GetUnassignedSoldiers() : SquadManager.GetSquad(CurrentSquadIndex).GetSoldierRefs(true);
}

// KDM : This function is here as a simple 'name wrapper'.
simulated function SortListData()
{
	SortData();
}

simulated function UpdateList()
{
	local int i;
	local UIPersonnel_ListItem SoldierListItem;
	local XComGameState_LWPersistentSquad CurrentSquadState;
	
	super(UIPersonnel).UpdateList();

	CurrentSquadState = GetCurrentSquad();

	// LW : Determine whether each soldier can be transferred or not.
	for (i = 0; i < m_kList.itemCount; i++)
	{
		SoldierListItem = UIPersonnel_ListItem(m_kList.GetItem(i));

		// LW : If we are viewing a squad on a mission, mark units not on the mission with a lower alpha value.
		// KDM : I have added a check so that only 'squad soldiers' are affected; 'available soldiers' are now 
		// unaffected. I have also changed the alpha from 30 to 40 since this can combine with an unfocused 
		// soldier UI, and become difficult to see.
		if (!DisplayingAvailableSoldiers && CurrentSquadState != none && 
			CurrentSquadState.IsDeployedOnMission() && !CurrentSquadState.IsSoldierOnMission(SoldierListItem.UnitRef))
		{
			SoldierListItem.SetAlpha(40);
		}

		if (!CanTransferSoldier(SoldierListItem.UnitRef))
		{
			SoldierListItem.SetDisabled(true);
		}
	}
}

simulated function UpdateListSelection()
{
	// KDM : If the soldier UI has focus, select the first soldier in the soldier list.
	if (SoldierUIFocused)
	{
		if (m_kList.ItemCount > 0) 
		{
			m_kList.SetSelectedIndex(0, true);
		}
	}
	// KDM : If the squad UI has focus, remove all focus from the soldier list.
	else
	{
		m_kList.ClearSelection();
	}
}

// KDM : LW function.
simulated function int GetClassIconAlphaStatus(XComGameState_Unit SoldierState, XComGameState_LWPersistentSquad CurrentSquadState)
{
	local bool IsSquadDeployedOnMission, IsSoldierOnMission;
	
	IsSquadDeployedOnMission = CurrentSquadState.IsDeployedOnMission();
	IsSoldierOnMission = CurrentSquadState.IsSoldierOnMission(SoldierState.GetReference());

	// LW : If the squad is on a mission, but this squad's soldier isn't, dim the icon regardless of their actual status.
	if (IsSquadDeployedOnMission && !IsSoldierOnMission)
	{
		return 30;
	}

	switch (SoldierState.GetStatus())
	{
		case eStatus_Active:
			return (SquadIsOnMission(CurrentSquadState) && CurrentSquadState.IsSoldierTemporary(SoldierState.GetReference())) ? 50 : 100;

		case eStatus_OnMission:
			return `LWOUTPOSTMGR.IsUnitAHavenLiaison(SoldierState.GetReference()) ? 50 : 100;
		
		case eStatus_PsiTraining:
		case eStatus_PsiTesting:
		case eStatus_Training:
		case eStatus_Healing:
		case eStatus_Dead:
		default:
			return 50;
	}
}

// KDM : LW function.
simulated function UpdateSoldierClassIcons(XComGameState_LWPersistentSquad CurrentSquadState)
{
	local int i, StartIndex;
	local array<XComGameState_Unit> SoldierStates;
	local UISquadClassItem_ForControllers SoldierClassIcon;
	local XComGameState_Unit SoldierState;
	
	SoldierStates = CurrentSquadState.GetSoldiers();
	
	// LW : Add permanent soldier icons.
	for (i = 0; i < SoldierStates.Length; i++)
	{
		SoldierState = SoldierStates[i];
		SoldierClassIcon = UISquadClassItem_ForControllers(SoldierIconList.GetItem(i));
		
		if (SoldierClassIcon == none)
		{
			SoldierClassIcon = UISquadClassItem_ForControllers(SoldierIconList.CreateItem(class'UISquadClassItem_ForControllers'));
			SoldierClassIcon.InitSquadClassItem();
		}

		SoldierClassIcon.LoadClassImage(SoldierState.GetSoldierClassTemplate().IconImage);
		// LW : Dim unavailable soldiers.
		SoldierClassIcon.SetAlpha(GetClassIconAlphaStatus(SoldierState, CurrentSquadState));
		SoldierClassIcon.ShowTempIcon(false);
		SoldierClassIcon.Show();
	}
	
	StartIndex = i;
	SoldierStates = CurrentSquadState.GetTempSoldiers();
	
	// LW : Add temporary soldier icons.
	for (i = StartIndex; i < StartIndex + SoldierStates.Length; i++)
	{
		SoldierState = SoldierStates[i - StartIndex];
		SoldierClassIcon = UISquadClassItem_ForControllers(SoldierIconList.GetItem(i));
		
		if (SoldierClassIcon == none)
		{
			SoldierClassIcon = UISquadClassItem_ForControllers(SoldierIconList.CreateItem(class'UISquadClassItem_ForControllers'));
			SoldierClassIcon.InitSquadClassItem();
		}

		SoldierClassIcon.LoadClassImage(SoldierState.GetSoldierClassTemplate().IconImage);
		// LW : Dim unavailable soldiers
		SoldierClassIcon.SetAlpha(GetClassIconAlphaStatus(SoldierState, CurrentSquadState));
		SoldierClassIcon.ShowTempIcon(true);
		SoldierClassIcon.Show();
	}

	StartIndex = i;

	// LW : Hide additional icons.
	if (SoldierIconList.GetItemCount() > StartIndex)								
	{
		for (i = StartIndex; i < SoldierIconList.GetItemCount(); i++)
		{
			SoldierClassIcon = UISquadClassItem_ForControllers(SoldierIconList.GetItem(i));
			SoldierClassIcon.Hide();
		}
	}
}

simulated function NextSquad()
{
	if (!CurrentSquadIsValid())
	{
		return;
	}

	CurrentSquadIndex = (CurrentSquadIndex + 1 >=  GetTotalSquads()) ? 0 : CurrentSquadIndex + 1;
	UpdateAll(true);
}

simulated function PrevSquad()
{
	if (!CurrentSquadIsValid()) 
	{
		return;
	}

	CurrentSquadIndex = (CurrentSquadIndex - 1 < 0) ? GetTotalSquads() - 1 : CurrentSquadIndex - 1;
	UpdateAll(true);
}

simulated function CreateSquad()
{
	local int TotalSquads;
	
	TotalSquads = GetTotalSquads();
	
	// KDM : Don't store `LWSQUADMGR in a variable and access it after calling CreateEmptySquad(); 
	// the reference has become stale !
	`LWSQUADMGR.CreateEmptySquad();

	CurrentSquadIndex = TotalSquads;
	UpdateAll(true);

	// KDM : A squad has been added so LW's underlying squad data is messed up and needs to be refreshed.
	SetSelectedSquadRef();
}

simulated function DeleteSelectedSquad()
{
	local TDialogueBoxData DialogData;
	
	// KDM : Includes a check to see if the current squad is valid.
	if (!SelectedSquadIsDeletable())
	{
		return;
	}

	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = class'UIPersonnel_SquadBarracks'.default.strDeleteSquadConfirm;
	DialogData.strText = class'UIPersonnel_SquadBarracks'.default.strDeleteSquadConfirmDesc;
	DialogData.fnCallback = OnDeleteSelectedSquadCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function OnDeleteSelectedSquadCallback(Name eAction)
{
	local int TotalSquads;
	local StateObjectReference CurrentSquadRef;

	if (eAction == 'eUIAction_Accept')
	{
		CurrentSquadRef = `LWSQUADMGR.Squads[CurrentSquadIndex];

		// KDM : Don't store `LWSQUADMGR in a variable and access it after calling RemoveSquadByRef(); 
		// the reference has become stale !
		`LWSQUADMGR.RemoveSquadByRef(CurrentSquadRef);
		
		TotalSquads = GetTotalSquads();
		
		// KDM : There are 3 possible scenarios :
		// 1.] We deleted the last remaining squad, so no squads exist; in this case, set CurrentSquadIndex to -1.
		// 2.] We deleted the last squad in the list, but squads still exist; in this case, select the 'new' last squad.
		// 3.] Neither 1 nor 2 are true; therefore, select the squad which is adjacent, list-wise, to the deleted squad.
		//	   This is accomplished by leaving CurrentSquadIndex unmodified. 
		if (TotalSquads == 0)
		{
			CurrentSquadIndex = -1;
		}
		else if (CurrentSquadIndex >= TotalSquads)
		{
			CurrentSquadIndex = TotalSquads - 1;
		}
		
		UpdateAll(true);

		// KDM : A squad has been deleted so LW's underlying squad data is messed up and needs to be refreshed.
		SetSelectedSquadRef();
	}
}

simulated function RenameSquad()
{
	local TInputDialogData DialogData;

	if (!CurrentSquadIsValid())
	{
		return;
	}

	DialogData.strTitle = class'UIPersonnel_SquadBarracks'.default.strRenameSquad;
	DialogData.iMaxChars = 50;
	DialogData.strInputBoxText = GetCurrentSquad().sSquadName;
	DialogData.fnCallback = OnRenameInputBoxClosed;

	`HQPRES.UIInputDialog(DialogData);
}

function OnRenameInputBoxClosed(string NewSquadName)
{
	local XComGameState NewGameState;
	local XComGameState_LWPersistentSquad CurrentSquadState;

	if (NewSquadName != "")
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Renaming Squad");
		CurrentSquadState = GetCurrentSquad();
		CurrentSquadState = XComGameState_LWPersistentSquad(NewGameState.CreateStateObject(class'XComGameState_LWPersistentSquad', CurrentSquadState.ObjectID));
		CurrentSquadState.sSquadName = NewSquadName;
		CurrentSquadState.bTemporary = false;
		NewGameState.AddStateObject(CurrentSquadState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		UpdateSquadUI();
	}
}

function EditSquadBiography()
{
	local TInputDialogData DialogData;

	if (!CurrentSquadIsValid())
	{
		return;
	}

	DialogData.strTitle = class'UIPersonnel_SquadBarracks'.default.strEditBiography;
	DialogData.iMaxChars = 500;
	DialogData.strInputBoxText = GetCurrentSquad().sSquadBiography;
	DialogData.fnCallback = OnEditBiographyInputBoxClosed;
	DialogData.DialogType = eDialogType_MultiLine;

	Movie.Pres.UIInputDialog(DialogData);
}

function OnEditBiographyInputBoxClosed(string NewSquadBio)
{
	local XComGameState NewGameState;
	local XComGameState_LWPersistentSquad CurrentSquadState;

	if (NewSquadBio != "")
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Edit Squad Biography");
		CurrentSquadState = GetCurrentSquad();
		CurrentSquadState = XComGameState_LWPersistentSquad(NewGameState.CreateStateObject(class'XComGameState_LWPersistentSquad', CurrentSquadState.ObjectID));
		CurrentSquadState.sSquadBiography = NewSquadBio;
		NewGameState.AddStateObject(CurrentSquadState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		UpdateSquadUI();
	}
}

function EditSquadIcon()
{
	local UISquadIconSelectionScreen_ForControllers IconSelectionScreen;
	local XComPresentationLayerBase HQPres;
	
	if (!CurrentSquadIsValid() || CurrentSquadIcon == none)
	{
		return;
	}

	HQPres = `HQPRES;

	if (HQPres != none && HQPres.ScreenStack.IsNotInStack(class'UISquadIconSelectionScreen_ForControllers'))
	{
		IconSelectionScreen = HQPres.Spawn(class'UISquadIconSelectionScreen_ForControllers', HQPres);
		IconSelectionScreen.BelowScreen = self;
		IconSelectionScreen.BelowScreen.bHideOnLoseFocus = false;
		HQPres.ScreenStack.Push(IconSelectionScreen, HQPres.Get2DMovie());
	}
}

// KDM : If the squad UI has focus, fade the soldier UI. Likewise, if the soldier UI has focus, 
// fade the squad UI.
simulated function UpdateUIForFocus()
{
	local int FocusAlpha, UnfocusAlpha, TopUIAlpha, BottomUIAlpha;

	FocusAlpha = 100;
	UnfocusAlpha = 75;

	TopUIAlpha = (!SoldierUIFocused) ? FocusAlpha : UnfocusAlpha;
	BottomUIAlpha = SoldierUIFocused ? FocusAlpha : UnfocusAlpha;
	
	SquadHeader.SetAlpha(TopUIAlpha);
	CurrentSquadIcon.SetAlpha(TopUIAlpha);
	CurrentSquadStatus.SetAlpha(TopUIAlpha);
	CurrentSquadMissions.SetAlpha(TopUIAlpha);
	SoldierIconList.SetAlpha(TopUIAlpha);
	CurrentSquadBio.SetAlpha(TopUIAlpha);

	SquadSoldiersTab.SetAlpha(BottomUIAlpha);
	AvailableSoldiersTab.SetAlpha(BottomUIAlpha);
	m_kSoldierSortHeader.SetAlpha(BottomUIAlpha);
	m_kList.SetAlpha(BottomUIAlpha);

	// KDM : If the squad UI is no longer active, and the biography text container has a scrollbar, 
	// scroll the text container to the top.
	if (SoldierUIFocused)
	{
		ResetBiographyScroll();
	}
}

simulated function UpdateTabsForFocus()
{
	if (DisplayingAvailableSoldiers)
	{
		SquadSoldiersTab.SetSelected(false);
		AvailableSoldiersTab.SetSelected(true);
	}
	else
	{
		SquadSoldiersTab.SetSelected(true);
		AvailableSoldiersTab.SetSelected(false);
	}
}

simulated function bool CanViewCurrentSquad()
{
	local robojumper_UISquadSelect SquadSelectScreen;

	SquadSelectScreen = class'Utilities_ForControllers'.static.GetRobojumpersSquadSelectFromStack();
	
	if (!CurrentSquadIsValid())
	{
		return false;
	}
	// KDM : Don't allow squad viewing when coming through : Squad Select --> Squad Menu.
	if (SquadSelectScreen != none)
	{
		return false;
	}
	// KDM : LW logic doesn't allow squad viewing if the squad is on a mission; this is a 'very good' idea, 
	// as I don't want to make an on-mission squad temporarily active. 
	if (SquadIsOnMission(GetCurrentSquad()))
	{
		return false;
	}

	return true;
}

simulated function ViewCurrentSquad()
{
	if (!CanViewCurrentSquad())
	{
		return;
	}

	// KDM : Cache the mission squad so we can retrieve it later.
	CachedSquadBeforeViewing = `LWSQUADMGR.LaunchingMissionSquad;
	RestoreCachedSquadAfterViewing = true;

	// KDM : Set the current squad as the mission squad so we can temporarily view it.
	class'Utilities_ForControllers'.static.SetSquad(GetCurrentSquad().GetReference());
	
	`HQPRES.UISquadSelect();
}

simulated function OnReceiveFocus()
{
	// KDM : If we are coming back from viewing a squad, restore the mission squad.
	if (RestoreCachedSquadAfterViewing)
	{
		RestoreCachedSquadAfterViewing = false;
		class'Utilities_ForControllers'.static.SetSquad(CachedSquadBeforeViewing);
	}

	super(UIScreen).OnReceiveFocus();
	InitializeCachedNav();
	UpdateNavHelp();
}

simulated function OnLoseFocus()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	
	super(UIPersonnel).OnLoseFocus();
}

simulated function OnRemoved()
{
	local UISquadMenu SquadMenu;

	SquadMenu = class'Utilities_ForControllers'.static.GetUISquadMenuFromStack();
	
	// KDM : We are exiting the Squad Management screen and heading back to the Squad Menu.
	// Save the squad we were looking at, so it can be selected when the Squad Menu receives focus.
	if (SquadMenu != none)
	{
		SquadMenu.CachedSquad = GetCurrentSquad();
	}

	super(UIPersonnel).OnRemoved();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	bHandled = true;

	// KDM : Right stick click toggles focus between the squad UI, on top, and the soldier UI, on the bottom.
	if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_R3)
	{
		if (CurrentSquadIsValid())
		{
			ToggleUIFocus();
			UpdateListUI(true);
			UpdateNavHelp();
		}
	}
	// KDM : B button closes the screen.
	else if (cmd == class'UIUtilities_Input'.static.GetBackButtonInputCode())
	{
		CloseScreen();
	}
	// KDM : If the squad UI has focus.
	else if (!SoldierUIFocused)
	{
		switch(cmd)
		{
			// KDM : Y button creates a squad.
			case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
				CreateSquad();
				// KDM : The first squad may have been created, so update the navigation help system.
				UpdateNavHelp();
				break;

			// KDM : X button deletes the selected squad.
			case class'UIUtilities_Input'.const.FXS_BUTTON_X:
				DeleteSelectedSquad();
				// KDM : The last squad may have been deleted, so update the navigation help system.
				UpdateNavHelp();
				break;

			// KDM : Left bumper selects the previous squad.
			case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
				PrevSquad();
				// KDM : A squad on a mission may have been selected, so update the navigation help system.
				UpdateNavHelp();
				break;

			// KDM : Right bumper selects the next squad
			case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
				NextSquad();
				// KDM : A squad on a mission may have been selected, so update the navigation help system.
				UpdateNavHelp();
				break;

			// KDM : Left stick click changes the squad's icon.
			case class'UIUtilities_Input'.const.FXS_BUTTON_L3:
				EditSquadIcon();
				break;

			// KDM : Left trigger renames the squad.
			case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER:
				RenameSquad();
				break;
			
			// KDM : Right trigger edits the squad's biography.
			case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:
				EditSquadBiography();
				break;

			// KDM : Right stick up tells the squad biography to scroll up, if it is larger than its container size.
			case class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_UP:
				if (CurrentSquadIsValid())
				{
					CurrentSquadBio.OnChildMouseEvent(none, class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN);
				}
				break;

			// KDM : Right stick down tells the squad biography to scroll down, if it is larger than its container size.
			case class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_DOWN:
				if (CurrentSquadIsValid())
				{
					CurrentSquadBio.OnChildMouseEvent(none, class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP);
				}
				break;

			// KDM : Select button views the squad.
			case class'UIUtilities_Input'.const.FXS_BUTTON_SELECT:
				ViewCurrentSquad();
				break;

			default:
				bHandled = false;
				break;
		}
	}
	// KDM : If the soldier UI has focus.
	else if (SoldierUIFocused)
	{
		// KDM : Left bumper displays current 'squad's soldiers' while right bumper displays 'available soldiers'.
		if ((cmd == class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER && DisplayingAvailableSoldiers) ||
			(cmd == class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER && !DisplayingAvailableSoldiers))
		{
			ToggleTabFocus();
			UpdateListUI(false);
			UpdateNavHelp();
		}
		// KDM : DPad left changes list column selection; this is UIPersonnel code.
		else if (cmd == class'UIUtilities_Input'.const.FXS_DPAD_LEFT)
		{
			m_bFlipSort = false;
			m_iSortTypeOrderIndex--;
			if (m_iSortTypeOrderIndex < 0)
			{
				m_iSortTypeOrderIndex = m_aSortTypeOrder.Length - 1;
			}
			SetSortType(m_aSortTypeOrder[m_iSortTypeOrderIndex]);
			UpdateSortHeaders();
			PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
		}
		// KDM : DPad right changes list column selection; this is UIPersonnel code.
		else if (cmd == class'UIUtilities_Input'.const.FXS_DPAD_RIGHT)
		{
			m_bFlipSort = false;
			m_iSortTypeOrderIndex++;
			if (m_iSortTypeOrderIndex >= m_aSortTypeOrder.Length)
			{
				m_iSortTypeOrderIndex = 0;
			}
			SetSortType(m_aSortTypeOrder[m_iSortTypeOrderIndex]);
			UpdateSortHeaders();
			PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
		}
		// KDM : X button changes list sorting.
		else if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_X)
		{
			m_bFlipSort = !m_bFlipSort;
			UpdateListUI(false, false);
			// KDM : A new soldier could have been selected so update the navigation help system.
			UpdateNavHelp();
		}
		// KDM : A button transfers a soldier to/from a squad.
		else if (cmd == class'UIUtilities_Input'.static.GetAdvanceButtonInputCode())
		{
			OnSoldierSelected(m_kList, m_kList.selectedIndex);
			// KDM : A new soldier will have been selected so update the navigation help system.
			UpdateNavHelp();
		}
		else
		{
			bHandled = m_kList.OnUnrealCommand(cmd, arg);
			if (bHandled)
			{
				// KDM : The list handled the input so, in all likelihood, a new soldier was selected; 
				// therefore, update the navigation help system.
				UpdateNavHelp();
			}
		}
	}

	return bHandled; 
}

// ===================================================
// =========== Navigation Help Related ===============
// ===================================================

simulated function InitializeCachedNav()
{
	local int i;

	for (i = 0; i < 7; i++)
	{
		CachedNavHelp[i] = -1;
	}
}

simulated function bool NavHelpHasChanged()
{
	local bool NavHelpChanged, ValidSquadWithSquadUIFocused, ValidSquadWithSoldierUIFocused;
	local int i, FalseVal, TrueVal, CurrentNavHelp[7];
	local XComGameState_Unit DummySoldierState;

	FalseVal = 0;
	TrueVal = 1;

	NavHelpChanged = false;
	ValidSquadWithSquadUIFocused = (CurrentSquadIsValid() && !SoldierUIFocused) ? true : false;
	ValidSquadWithSoldierUIFocused = (CurrentSquadIsValid() && SoldierUIFocused) ? true : false;

	// KDM : 'Close screen' is automatically true and can be ignored.
	// KDM : 'Create squad' is active as long as the squad UI has focus.
	CurrentNavHelp[0] = (!SoldierUIFocused) ? TrueVal : FalseVal;
	// KDM : The following are active as long as the current squad is valid and the squad UI has focus :
	// 1.] Previous squad 2.] Next squad 3.] Rename squad 4.] Edit squad biography 
	// 5.] Edit squad icon 6.] Scroll biography text 7.] Focus soldier UI.
	CurrentNavHelp[1] = ValidSquadWithSquadUIFocused ? TrueVal : FalseVal;
	// KDM : The following are active as long as the current squad is valid and the soldier UI has focus :
	// 1.] Change sort column 2.] Toggle sort 3.] Focus squad UI.
	CurrentNavHelp[2] = ValidSquadWithSoldierUIFocused ? TrueVal : FalseVal;
	// KDM : 'Squad soldiers' and 'Available soldiers' tabs are potentially active as long as the 
	// current squad is valid and the soldier UI has focus. If DisplayingAvailableSoldiers is true, the 
	// 'Available soldiers' tab is active, else the 'Squad soldiers' tab is active.
	CurrentNavHelp[3] = (ValidSquadWithSoldierUIFocused && DisplayingAvailableSoldiers) ? TrueVal : FalseVal;
	// KDM : 'View squad' is active as long as : 
	// 1.] The current squad is valid 2.] The squad UI has focus 3.] You aren't coming through the Squad Menu 
	// 4.] The squad isn't on a mission.
	CurrentNavHelp[4] = (CanViewCurrentSquad() && !SoldierUIFocused) ? TrueVal : FalseVal;
	// KDM : 'Delete squad' is active as long as :
	// 1.] The current squad is valid 2.] The squad UI has focus 3.] The squad isn't on a mission.
	CurrentNavHelp[5] = (SelectedSquadIsDeletable() && !SoldierUIFocused) ? TrueVal : FalseVal;
	// KDM : 'Transfer soldiers' is active as long as :
	// 1.] The current squad is valid 2.] The selected list item is valid 3.] The soldier is not disabled 
	// 4.] The soldier is transferable 5.] The soldier UI has focus.
	// If DisplayingAvailableSoldiers is true, you can 'Transfer to squad', else you can 'Remove from squad'.
	CurrentNavHelp[6] = (SelectedSoldierIsMoveable(m_kList, m_kList.selectedIndex, DummySoldierState) && SoldierUIFocused && 
		DisplayingAvailableSoldiers) ? TrueVal : FalseVal;

	for (i = 0; i < 7; i++)
	{
		if (CachedNavHelp[i] != CurrentNavHelp[i])
		{
			// KDM : Don't break once we have found a change, since we want to update CachedNavHelp with 
			// all changes.
			CachedNavHelp[i] = CurrentNavHelp[i];
			NavHelpChanged = true;
		}
	}

	return NavHelpChanged;
}

simulated function UpdateNavHelp()
{
	local string NavString;
	local UINavigationHelp NavHelp;
	local XComGameState_Unit DummySoldierState;

	NavHelp =`HQPRES.m_kAvengerHUD.NavHelp;
	
	// KDM : If the navigation help has not changed since last time return; this prevents unnecessary 
	// navigation help flicker.
	if (!NavHelpHasChanged()) return;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = true;
	NavHelp.AddBackButton();

	if (!CurrentSquadIsValid())
	{
		if (!SoldierUIFocused)
		{
			NavHelp.AddLeftHelp(CreateSquadStr, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
		}
	}
	else
	{
		// KDM : If the squad UI has focus.
		if (!SoldierUIFocused)
		{
			NavHelp.AddLeftHelp(ScrollSquadBioStr, class'UIUtilities_Input'.const.ICON_RSTICK);
			NavHelp.AddLeftHelp(ChangeSquadIconStr, class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
			NavHelp.AddLeftHelp(EditSquadBioStr, class'UIUtilities_Input'.const.ICON_RT_R2);
			NavHelp.AddLeftHelp(RenameSquadStr, class'UIUtilities_Input'.const.ICON_LT_L2);
			if (SelectedSquadIsDeletable())
			{
				NavHelp.AddLeftHelp(DeleteSquadStr, class'UIUtilities_Input'.const.ICON_X_SQUARE);
			}
			NavHelp.AddLeftHelp(CreateSquadStr, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
			NavHelp.AddLeftHelp(FocusUISoldiersStr, class'UIUtilities_Input'.const.ICON_RSCLICK_R3);

			NavHelp.AddCenterHelp(PrevSquadStr, class'UIUtilities_Input'.const.ICON_LB_L1);
			NavHelp.AddCenterHelp(NextSquadStr, class'UIUtilities_Input'.const.ICON_RB_R1);

			if (CanViewCurrentSquad())
			{
				// KDM : For some reason, bIsVerticalHelp has to be false for the right container, else the 
				// help falls off the side of the screen.
				NavHelp.bIsVerticalHelp = false;
				NavHelp.AddRightHelp(ViewSquadStr, class'UIUtilities_Input'.const.ICON_BACK_SELECT);
			}
		}
		// KDM : If the soldier UI has focus.
		else
		{
			if (SelectedSoldierIsMoveable(m_kList, m_kList.selectedIndex, DummySoldierState))
			{
				NavString = DisplayingAvailableSoldiers ? TransferToSquadStr : RemoveFromSquadStr;
				NavHelp.AddLeftHelp(NavString, class'UIUtilities_Input'.const.ICON_A_X);
			}
			NavHelp.AddLeftHelp(FocusUISquadStr, class'UIUtilities_Input'.const.ICON_RSCLICK_R3);
			
			NavHelp.AddCenterHelp(ViewSquadSoldiersStr, class'UIUtilities_Input'.const.ICON_LB_L1);
			NavHelp.AddCenterHelp(ViewAvailableSoldierStr, class'UIUtilities_Input'.const.ICON_RB_R1);
			NavHelp.AddCenterHelp(m_strToggleSort, class'UIUtilities_Input'.const.ICON_X_SQUARE);
			NavHelp.AddCenterHelp(m_strChangeColumn, class'UIUtilities_Input'.const.ICON_DPAD_HORIZONTAL);
		}
	}	

	NavHelp.Show();
}

// ===================================================
// =========== General Helper Functions ==============
// ===================================================

simulated function XComGameState_LWPersistentSquad GetCurrentSquad()
{
	local StateObjectReference CurrentSquadRef;
	
	if (CurrentSquadIndex < 0  || CurrentSquadIndex >= `LWSQUADMGR.Squads.Length)
	{
		return none;
	}

	CurrentSquadRef = `LWSQUADMGR.Squads[CurrentSquadIndex];
	return XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(CurrentSquadRef.ObjectID));
}

simulated function bool SquadsExist()
{
	return (GetTotalSquads() == 0) ? false : true;
}

simulated function bool CurrentSquadIsValid()
{
	return (SquadsExist() && CurrentSquadIndex >= 0 && CurrentSquadIndex < GetTotalSquads());
}

simulated function int GetTotalSquads()
{
	return `LWSQUADMGR.Squads.Length;
}

simulated function SetInitialCurrentSquadIndex()
{
	local UISquadMenu SquadMenu;
	local UISquadMenu_ListItem SelectedListItem;

	SquadMenu = class'Utilities_ForControllers'.static.GetUISquadMenuFromStack();

	if (SquadsExist())
	{
		// KDM : We are entering the Squad Management screen through : Squad Select --> Squad Menu.
		// Therefore, select the squad which was last highlighted in the Squad Menu.	
		if (SquadMenu != none)
		{
			SelectedListItem = UISquadMenu_ListItem(SquadMenu.List.GetSelectedItem());
			CurrentSquadIndex = class'Utilities_ForControllers'.static.SquadsIndexWithSquadReference(
				SelectedListItem.SquadRef);
		}
		// KDM : We are entering the Squad Management screen through the 'Squad Management' Avenger tab.
		// Therefore, select the first squad.
		else
		{
			CurrentSquadIndex = 0;
		}
	}
	// KDM : No squads exist so simply set the index to -1.
	else
	{
		CurrentSquadIndex = -1;
	}
}

simulated function ResetTabFocus()
{
	// KDM : By default, the squad's soldiers tab has focus.
	SetTabFocus(false, true);
}

simulated function ResetSortType()
{
	// KDM : By default, sort the list in rank-descending order.
	m_iSortTypeOrderIndex = 0;
	m_eSortType = ePersonnelSoldierSortType_Rank;
	m_bFlipSort = false;
}

// KDM : Gets the first squad which is not on a mission; if no such squad exists, returns none.
function XComGameState_LWPersistentSquad GetFirstIdleSquad()
{
	local int i;
	local XComGameState_LWPersistentSquad SquadState;
	
	for (i = 0; i < `LWSQUADMGR.Squads.length; i++)
	{
		SquadState = `LWSQUADMGR.GetSquad(i);
		// KDM : If we have found a squad which isn't on a mission then return it.
		if (!SquadIsOnMission(SquadState))
		{
			return SquadState;
		}
	}
	
	return none;
}

function bool SquadIsOnMission(XComGameState_LWPersistentSquad SquadState)
{
	return (SquadState.bOnMission || SquadState.CurrentMission.ObjectID > 0);
}

simulated function bool SelectedSquadIsDeletable()
{
	local XComGameState_LWPersistentSquad CurrentSquadState;
	
	if (!CurrentSquadIsValid())
	{
		return false;
	}
	
	CurrentSquadState = GetCurrentSquad();
	// LW : Don't delete a squad if it is on a mission.
	if (SquadIsOnMission(CurrentSquadState))
	{
		return false;
	}

	return true;
}

simulated function SetSelectedSquadRef(optional StateObjectReference SquadRef)
{
	local XComGameState_LWPersistentSquad SquadState;

	// KDM : We have been given a valid squad reference, so select that squad.
	if (SquadRef.ObjectID > 0)
	{
		class'Utilities_ForControllers'.static.SetSquad(SquadRef);
	}
	// KDM : We were not given a valid squad reference, yet squads exist, so select the first squad which 
	// isn't on a mission. If no such squad exists then exit; it is very important we 'do not' make an 
	// on-mission squad active.
	else if (`LWSQUADMGR.Squads.Length > 0)
	{
		SquadState = GetFirstIdleSquad();
		if (SquadState != none)
		{
			class'Utilities_ForControllers'.static.SetSquad(SquadState.GetReference());
		}
	}
}

simulated function ToggleUIFocus()
{
	SetUIFocus(!SoldierUIFocused);
}

simulated function SetUIFocus(bool NewUIFocus, optional bool ForceUpdate = false)
{
	if (ForceUpdate || SoldierUIFocused != NewUIFocus)
	{
		SoldierUIFocused = NewUIFocus;
		UpdateUIForFocus();
	}
}

simulated function ResetUIFocus()
{
	// KDM : By default, the squad UI has focus.
	SetUIFocus(false, true);
}

simulated function ToggleTabFocus()
{
	SetTabFocus(!DisplayingAvailableSoldiers);
}

simulated function SetTabFocus(bool NewTabFocus, optional bool ForceUpdate = false)
{
	if (ForceUpdate || DisplayingAvailableSoldiers != NewTabFocus)
	{
		DisplayingAvailableSoldiers = NewTabFocus;
		UpdateTabsForFocus();
	}
}

simulated function ResetBiographyScroll()
{
	local UIScrollbar Scrollbar;

	Scrollbar = CurrentSquadBio.scrollbar;
	if (Scrollbar != none)
	{
		Scrollbar.SetThumbAtPercent(0.0);
	}
}

simulated function bool SelectedSoldierIsMoveable(UIList SquadList, int SelectedIndex, out XComGameState_Unit CurrentSoldierState)
{
	local UIPersonnel_ListItem SoldierListItem;
	local XComGameState_LWPersistentSquad CurrentSquadState;

	if (!CurrentSquadIsValid())
	{
		return false;
	}
	if (SelectedIndex < 0 || SelectedIndex >= SquadList.ItemCount)
	{
		return false;
	}
	if (UIPersonnel_ListItem(SquadList.GetItem(SelectedIndex)).IsDisabled)
	{
		return false;
	}

	CurrentSquadState = GetCurrentSquad();
	SoldierListItem = UIPersonnel_ListItem(SquadList.GetItem(SelectedIndex));
	CurrentSoldierState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SoldierListItem.UnitRef.ObjectID));
	
	if (!CanTransferSoldier(CurrentSoldierState.GetReference(), CurrentSquadState))
	{
		return false;
	}

	return true;
}

// KDM : LW function
simulated function bool CanTransferSoldier(StateObjectReference SoldierRef, optional XComGameState_LWPersistentSquad CurrentSquadState)
{
	local int CurrentSquadSize, MaxSquadSize;
	local array<XComGameState_Unit> CurrentSquadSoldiers;
	local XComGameState_Unit CurrentSoldierState;
	
	CurrentSoldierState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SoldierRef.ObjectID));

	// LW : You can't move soldiers on a mission; this does not include haven liaisons.
	if (class'LWDLCHelpers'.static.IsUnitOnMission(CurrentSoldierState) && (!`LWOUTPOSTMGR.IsUnitAHavenLiaison(CurrentSoldierState.GetReference())))
	{
		return false;
	}

	if (CurrentSquadState == none)
	{
		CurrentSquadState = GetCurrentSquad();
	}

	if (CurrentSquadState != none)
	{
		// LW : You can't add soldiers to squads that are on a mission.
		if (SquadIsOnMission(CurrentSquadState))
		{
			if (DisplayingAvailableSoldiers)
			{
				return false;
			}
		}

		// LW : You can't add soldiers to a max size squad.
		CurrentSquadSoldiers = CurrentSquadState.GetSoldiers();
		CurrentSquadSize = CurrentSquadSoldiers.Length;
		MaxSquadSize = class'XComGameState_LWSquadManager'.default.MAX_SQUAD_SIZE;
		if (CurrentSquadSize >= MaxSquadSize)
		{
			if (DisplayingAvailableSoldiers)
			{
				return false;
			}
		}
	}

	return true;
}

simulated function OnSoldierSelected(UIList SquadList, int SelectedIndex)
{
	local int SquadListSize;
	local XComGameState NewGameState;
	local XComGameState_LWPersistentSquad CurrentSquadState;
	local XComGameState_Unit CurrentSoldierState;

	// KDM : CurrentSoldierState is passed by reference since it is needed below.
	if (!SelectedSoldierIsMoveable(SquadList, SelectedIndex, CurrentSoldierState))
	{
		return;
	}

	CurrentSquadState = GetCurrentSquad();
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Transferring Soldier");
	CurrentSquadState = XComGameState_LWPersistentSquad(NewGameState.CreateStateObject(class'XComGameState_LWPersistentSquad', CurrentSquadState.ObjectID));
	NewGameState.AddStateObject(CurrentSquadState);

	// KDM : If we are viewing 'available soldiers', add the soldier to the squad.
	if (DisplayingAvailableSoldiers)
	{
		CurrentSquadState.AddSoldier(CurrentSoldierState.GetReference());
	}
	// KDM : If we are viewing the 'squad's soldiers', remove the soldier from the squad.
	else
	{
		CurrentSquadState.RemoveSoldier(CurrentSoldierState.GetReference());
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// KDM : Normally I would just update the list UI; however, the squad's soldier icon list also needs 
	// to be updated.
	UpdateAll(false);
	
	// KDM : Attempt to keep the same item index selected for continuity.
	SquadListSize = SquadList.ItemCount;
	if (SquadListSize > 0 && SquadList.SelectedIndex != SelectedIndex)
	{
		if (SelectedIndex >= SquadListSize)
		{
			SelectedIndex = SquadListSize - 1;
		}
		SquadList.SetSelectedIndex(SelectedIndex);

		if (SquadList.Scrollbar != none)
		{
			SquadList.Scrollbar.SetThumbAtPercent(float(SelectedIndex) / float(SquadListSize - 1));
		}
	}
}

// ===================================================
// ============== Default Properties =================
// ===================================================

defaultproperties
{
	// KDM : The panel width was initially set to 985 so everything fit perfectly
	// together with virtually no empty space; unfortunately, this could result in
	// the list's scrollbar overlapping information. Consequently, the list's width 
	// needed to be increased by 20 pixels, and so to did the panel's width.
	PanelW = 1005;
	PanelH = 985;

	BorderPadding = 10;
	
	SquadIconSize = 144;
	SquadIconBorderSize = 3;

	// KDM : Some of UIPersonnel's functions rely upon m_eListType and m_eCurrentTab being set; 
	// therefore, set them here.
	m_eListType = eUIPersonnel_Soldiers;
	m_eCurrentTab = eUIPersonnel_Soldiers;

	m_eSortType = ePersonnelSoldierSortType_Rank;
	
	m_iMaskWidth = 961;
	m_iMaskHeight = 670;

	CurrentSquadIndex = -1;

	SoldierUIFocused = false;
	DisplayingAvailableSoldiers = false;

	RestoreCachedSquadAfterViewing = false;
}
