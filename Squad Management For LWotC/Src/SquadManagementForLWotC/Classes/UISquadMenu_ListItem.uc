//----------------------------------------------------------------------------
//	FILE:		UISquadMenu_ListItem.uc
//	AUTHOR:		Keith (kdm2k6)
//	PURPOSE:	A Squad Menu list item, consisting of a background button, squad icon, and squad name. 
//----------------------------------------------------------------------------
class UISquadMenu_ListItem extends UIPanel;

// KDM : Reference to an XComGameState_LWPersistentSquad.
var StateObjectReference SquadRef; 

var UIList OwningList;
var UISquadMenu OwningMenu;

var UIButton ButtonBG;
var UIImage SquadImage;
var UIScrollingText SquadNameText;

var int BorderPadding, TextSize;
var string SquadName;

function DelayedInit(float Delay)
{
	SetTimer(Delay, false, nameof(StartDelayedInit));
}

function StartDelayedInit()
{
	InitListItem(, true);
	Update();
	SetPosition(1150, 15);
}

simulated function InitListItem(optional StateObjectReference _SquadRef, optional bool IgnoreSquadRef = false, optional UISquadMenu _OwningMenu)
{
	local int ImageSize, TextX, TextWidth;

	// KDM : When used as a separate UI element, to show the current squad, we need to set the squad 
	// reference before calling InitListItem on a delay. In that case, we don't want to overwrite the 
	// squad reference.
	if (!IgnoreSquadRef) 
	{
		SquadRef = _SquadRef;
	}
	OwningMenu = _OwningMenu;

	InitPanel(); 

	OwningList = UIList(GetParent(class'UIList'));

	// KDM : If this is a list item, use the list's width; if this is a separate UI element, set the 
	// width manually.
	if (OwningList != none)
	{
		SetWidth(OwningList.Width);
	}
	else
	{
		SetWidth(300);
	}

	// KDM : Background button.
	ButtonBG = Spawn(class'UIButton', self);
	ButtonBG.bAnimateOnInit = false;
	ButtonBG.bIsNavigable = false;
	ButtonBG.InitButton(, , , eUIButtonStyle_NONE);
	ButtonBG.SetSize(Width, Height);

	// KDM : Squad icon.
	SquadImage = Spawn(class'UIImage', self);
	SquadImage.bAnimateOnInit = false;
	SquadImage.InitImage();
	ImageSize = Height - (BorderPadding * 2);
	SquadImage.SetSize(ImageSize, ImageSize);
	SquadImage.SetPosition(BorderPadding, BorderPadding);

	// KDM : Squad name.
	SquadNameText = Spawn(class'UIScrollingText', self);
	SquadNameText.bAnimateOnInit = false;
	TextX = BorderPadding + ImageSize + BorderPadding;
	TextWidth = Width - (TextX + BorderPadding);
	SquadNameText.InitScrollingText(, "Setup Text", TextWidth, TextX, 2);
}

simulated function Update()
{
	local XComGameState_LWPersistentSquad SquadState;

	SquadState = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(SquadRef.ObjectID));
	if (SquadState == none)
	{
		return;
	}

	SquadImage.LoadImage(SquadState.GetSquadImagePath());
	SquadName = SquadState.sSquadName;
	UpdateSquadNameText(true);
}

simulated function UpdateSquadNameText(optional bool ForceUpdate)
{
	local int ColourState;
	local string SquadNameHTML;

	ColourState = bIsFocused ? -1 : eUIState_Normal;
	SquadNameHTML = class'UIUtilities_Text'.static.GetColoredText(SquadName, ColourState, TextSize);

	SquadNameText.SetHTMLText(SquadNameHTML, ForceUpdate);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	ButtonBG.MC.FunctionVoid("mouseIn");
	UpdateSquadNameText(true);
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();

	ButtonBG.MC.FunctionVoid("mouseOut");
	UpdateSquadNameText(true);
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
		// KDM : A button selects the squad.
		case class'UIUtilities_Input'.static.GetAdvanceButtonInputCode():
			if (OwningMenu != none)
			{
				OwningMenu.OnSquadSelected(SquadRef);
			}
			break;

		default:
			bHandled = false;
			break;
	}

	return (bHandled || super.OnUnrealCommand(cmd, arg));
}

defaultproperties
{
	Height = 40;

	BorderPadding = 4;
	TextSize = 28;
}
