namespace LastEpoch_Hud.Scripts.Mods.Fixs
{
    public class Fix_PlayerLoopHelper
    {
        // 1.5.1: do not skip PlayerLoopHelper.AddAction.
        // GameLoader.InitializeAsync schedules UniTask continuations during splash,
        // before Hud_Manager exists. Dropping those actions leaves the loader waiting
        // and the game stays on the loading screen.
    }
}
