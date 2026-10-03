using HarmonyLib;

namespace LastEpoch_Hud.Scripts.Mods.Login
{
    public class Login_AutoLoginOffline
    {
        static Il2CppLE.UI.Login.UnityUI.LandingZonePanel pending_panel;

        public static bool CanRun()
        {
            bool r = false;
            if (!Save_Manager.instance.IsNullOrDestroyed())
            {
                if (!Save_Manager.instance.data.IsNullOrDestroyed())
                {
                    r = Save_Manager.instance.data.Login.Enable_AutoLoginOffline;
                }
            }

            return r;
        }

        // 1.5.1: OnEnable runs while ClientStateManager is still leaving SystemLoading.
        // AdvancePlayerToCharacterSelect throws until the state is Login.
        public static void Tick()
        {
            if (!CanRun()) { pending_panel = null; return; }
            if (pending_panel.IsNullOrDestroyed()) { pending_panel = null; return; }
            if (!ShellIsLogin()) { return; }
            Il2CppLE.UI.Login.UnityUI.LandingZonePanel panel = pending_panel;
            pending_panel = null;
            try { panel.OnPlayOfflineClicked(); }
            catch (System.Exception ex) { LastEpoch_Hud.Main.logger_instance?.Error("AutoLoginOffline: " + ex.Message); }
        }

        static bool ShellIsLogin()
        {
            try { return Il2CppClientAppState.ClientStateManager.CurrentClientAppStateType == Il2CppClientAppState.ClientAppStateType.Login; }
            catch { return false; }
        }

        [HarmonyPatch(typeof(Il2CppLE.UI.Login.UnityUI.LandingZonePanel), "OnOnEnable")]
        public class LandingZonePanel_OnOnEnable
        {
            [HarmonyPostfix]
            static void Postfix(ref Il2CppLE.UI.Login.UnityUI.LandingZonePanel __instance)
            {
                if (!CanRun()) { return; }
                if (ShellIsLogin())
                {
                    __instance.OnPlayOfflineClicked();
                    return;
                }
                pending_panel = __instance;
            }
        }

        [HarmonyPatch(typeof(Il2CppLE.UI.Login.UnityUI.LandingZonePanel), "OnPlayOnlineClicked")]
        public class LandingZonePanel_BlockOnline
        {
            [HarmonyPrefix]
            static bool Prefix() => !CanRun();
        }

        [HarmonyPatch(typeof(Il2Cpp.CharacterSelect), "SwitchOnlineOffline")]
        public class CharacterSelect_BlockSwitch
        {
            [HarmonyPrefix]
            static bool Prefix() => !CanRun();
        }
    }
}
