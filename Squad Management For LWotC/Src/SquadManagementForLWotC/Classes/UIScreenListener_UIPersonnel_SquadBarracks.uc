//----------------------------------------------------------------------------
//	FILE:		UIScreenListener_UIPersonnel_SquadBarracks.uc
//	AUTHOR:		Keith (kdm2k6)
//	PURPOSE:	A screen listener which replaces the conventional Squad Management screen with a custom, 
//				controller-capable one.
//----------------------------------------------------------------------------
class UIScreenListener_UIPersonnel_SquadBarracks extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIPersonnel_SquadBarracks SquadBarracks;
	local UIPersonnel_SquadBarracks_ForControllers SquadBarracksForControllers;
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPRES;
	SquadBarracks = UIPersonnel_SquadBarracks(Screen);

	SquadBarracksForControllers = HQPres.Spawn(class'UIPersonnel_SquadBarracks_ForControllers', HQPres);
	HQPres.ScreenStack.Pop(SquadBarracks);
	HQPres.ScreenStack.Push(SquadBarracksForControllers);
}

defaultproperties
{
	ScreenClass = class'UIPersonnel_SquadBarracks';
}
