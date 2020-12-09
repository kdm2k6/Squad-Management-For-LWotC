//----------------------------------------------------------------------------
//	FILE:		Utilities_ForControllers.uc
//	AUTHOR:		Keith (kdm2k6)
//	PURPOSE:	Miscellaneous helper utilities. 
//----------------------------------------------------------------------------
class Utilities_ForControllers extends object;

static function bool StackHasRobojumpersSquadSelect()
{
	return (`HQPRES.ScreenStack.GetFirstInstanceOf(class'robojumper_UISquadSelect') == none) ? false : true;
}

static function robojumper_UISquadSelect GetRobojumpersSquadSelectFromStack()
{
	return robojumper_UISquadSelect(`HQPRES.ScreenStack.GetFirstInstanceOf(class'robojumper_UISquadSelect'));
}

static function bool StackHasSquadBarracksForControllers()
{
	return (`HQPRES.ScreenStack.GetFirstInstanceOf(class'UIPersonnel_SquadBarracks_ForControllers') == none) ? false : true;
}

static function UIPersonnel_SquadBarracks_ForControllers GetSquadBarracksForControllersFromStack()
{
	return UIPersonnel_SquadBarracks_ForControllers(`HQPRES.ScreenStack.GetFirstInstanceOf(class'UIPersonnel_SquadBarracks_ForControllers'));
}

static function bool StackHasUISquadMenu()
{
	return (`HQPRES.ScreenStack.GetFirstInstanceOf(class'UISquadMenu') == none) ? false : true;
}

static function UISquadMenu GetUISquadMenuFromStack()
{
	return UISquadMenu(`HQPRES.ScreenStack.GetFirstInstanceOf(class'UISquadMenu'));
}

// KDM : Iterates through a list containing UISquadMenu_ListItem's
static function int ListIndexFromSquadReference(UIList TheList, StateObjectReference SquadRef)
{
	local int i, ListSize;
	local UISquadMenu_ListItem ListItem;

	ListSize = TheList.ItemCount;

	for (i = 0; i < ListSize ; i++)
	{
		ListItem = UISquadMenu_ListItem(TheList.GetItem(i));
		if (ListItem != none && ListItem.SquadRef == SquadRef)
		{
			return i;
		}
	}

	return -1;
}

// KDM : Iterates through XComGameState_LWSquadManager.Squads
static function int SquadsIndexWithSquadReference(StateObjectReference SquadRef)
{
	local int i;
	local XComGameState_LWSquadManager SquadManager;

	SquadManager = class'XComGameState_LWSquadManager'.static.GetSquadManager(true);
	if (SquadManager == none)
	{
		return -1;
	}

	for (i = 0; i < SquadManager.Squads.Length; i++)
	{
		if (SquadManager.Squads[i] == SquadRef)
		{
			return i;
		}
	}
	
	return -1;
}

static function SetSelectedIndexWithScroll(UIList TheList, int Index, optional bool Force)
{
	local int ListSize;

	ListSize = TheList.ItemCount;

	// KDM : If the index was invalid, but the list is not empty, then just select the first list item.
	if (Index == -1 && ListSize > 0)
	{
		TheList.SetSelectedIndex(0, Force);
	}
	else
	{
		TheList.SetSelectedIndex(Index, Force);
	}

	if (TheList.Scrollbar != none)
	{
		TheList.Scrollbar.SetThumbAtPercent(float(Index) / float(ListSize - 1));
	}
}

// KDM : Sets underlying squad data; this is LW2 code from UISquadContainer.
static function SetSquad(optional StateObjectReference NewSquadRef)
{
	local StateObjectReference CurrentSquadRef;
	local XComGameState UpdateState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWPersistentSquad SquadState;
	local XComGameState_LWSquadManager SquadManager, UpdatedSquadManager;
	
	XComHQ = `XCOMHQ;
	SquadManager = `LWSQUADMGR;

	if (NewSquadRef.ObjectID > 0)
	{
		CurrentSquadRef = NewSquadRef;
	}
	else
	{
		CurrentSquadRef = SquadManager.LaunchingMissionSquad;
	}

	if (CurrentSquadRef.ObjectID > 0)
	{
		SquadState = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(CurrentSquadRef.ObjectID));
	}
	else
	{
		SquadState = SquadManager.AddSquad(, XComHQ.MissionRef);
	}

	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Launching Mission Squad");
	UpdatedSquadManager = XComGameState_LWSquadManager(UpdateState.CreateStateObject(SquadManager.Class, SquadManager.ObjectID));
	UpdateState.AddStateObject(UpdatedSquadManager);
	UpdatedSquadManager.LaunchingMissionSquad = SquadState.GetReference();
	UpdateState.AddStateObject(XComHQ);
	`GAMERULES.SubmitGameState(UpdateState);

	SquadState.SetSquadCrew(, false , false);
}
