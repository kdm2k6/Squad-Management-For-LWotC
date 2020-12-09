//----------------------------------------------------------------------------
//	FILE:		UISquadClassItem_ForControllers.uc
//	AUTHOR:		Amineri with a modification by KDM
//	PURPOSE:	UISquadClassItem, with a slight modification to make the icon larger.
//				This icon represents a soldier in a particular squad.
//----------------------------------------------------------------------------
class UISquadClassItem_ForControllers extends UIPanel;

var UIImage ClassIcon;
var UIImage TempIcon;

var UIList List;

var string TempIconImagePath;

simulated function UISquadClassItem_ForControllers InitSquadClassItem()
{
	InitPanel(); 

	// KDM : Increase the size.
	SetSize(48, 48);

	List = UIList(GetParent(class'UIList'));

	ClassIcon = Spawn(class'UIImage', self);
	ClassIcon.bAnimateOnInit = false;
	ClassIcon.InitImage();
	// KDM : Increase the icon size.
	ClassIcon.SetSize(48, 48);

	TempIcon = Spawn(class'UIImage', self);
	TempIcon.bAnimateOnInit = false;
	TempIcon.InitImage();
	// KDM : Increase the icon size
	TempIcon.SetSize(21, 21);
	TempIcon.SetPosition(28, 28);
	TempIcon.LoadImage(default.TempIconImagePath);
	TempIcon.Hide();

	return self;
}

simulated function ShowTempIcon(bool Show)
{
	if (Show)
	{
		TempIcon.Show();
	}
	else
	{
		TempIcon.Hide();
	}
}

simulated function UIImage LoadClassImage(string NewPath)
{
	return ClassIcon.LoadImage(NewPath);
}

defaultProperties
{
	TempIconImagePath="img:///gfxComponents.attention_icon"
}
