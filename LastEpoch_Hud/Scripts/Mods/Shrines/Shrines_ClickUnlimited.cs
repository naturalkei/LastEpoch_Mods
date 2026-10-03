using HarmonyLib;
using Il2Cpp;
using UnityEngine;

namespace LastEpoch_Hud.Scripts.Mods.Shrines
{
    public class Shrines_ClickUnlimited
    {
        public static bool CanRun()
        {
            if (!Save_Manager.instance.IsNullOrDestroyed())
            {
                if (!Save_Manager.instance.data.IsNullOrDestroyed()) { return Save_Manager.instance.data.modsNotInHud.Shrines_Unlimited; }
                else { return false; }
            }
            else { return false; }
        }

        [HarmonyPatch(typeof(WorldObjectClickListener), "ObjectClick")]
        public class WorldObjectClickListener_ObjectClick
        {
            static bool logged_missing_place = false;

            [HarmonyPostfix]
            static void Postfix(ref WorldObjectClickListener __instance, UnityEngine.GameObject __0, bool __1)
            {
                if (!CanRun()) { return; }
                if ((!__instance.gameObject.name.ToLower().Contains(" shrine")) || (__1 != true)) { return; }
                if (logged_missing_place) { return; }
                logged_missing_place = true;
                ShrinesManager manager = GameObject.FindObjectOfType<ShrinesManager>();
                if (manager.IsNullOrDestroyed()) { Main.logger_instance?.Error("ShrinesManager not Found"); }
                else { Main.logger_instance?.Error("Shrines_ClickUnlimited: PlaceNewShrine(GameObject, Vector3) is not in this build"); }
            }
        }
    }
}
