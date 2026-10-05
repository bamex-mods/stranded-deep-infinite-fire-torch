using System;
using System.Reflection;
using BepInEx;
using BepInEx.Configuration;
using HarmonyLib;
using Bamex.StrandedDeep.ModSettings;

namespace BamEx.StrandedDeep.InfiniteFireTorch
{
    [BepInPlugin(
        PluginGuid,
        PluginName,
        PluginVersion
    )]
    [BepInDependency(
        ModSettingsGuid,
        BepInDependency.DependencyFlags.SoftDependency
    )]
    public sealed class Plugin : BaseUnityPlugin
    {
        public const string PluginGuid =
            "bamex.strandeddeep.infinitefiretorch";

        public const string PluginName =
            "BamEx Infinite Fire Torch";

        public const string PluginVersion =
            "1.1.1";

        private const string ModSettingsGuid =
            "com.bamex.strandeddeep.modsettings";

        private const string FireTorchTypeName =
            "Beam.Crafting.Interactive_FIRE_TORCH";

        private const string ModSettingsId =
            "infinitefiretorch";

        private static ConfigEntry<bool> _infiniteFuel;

        private Harmony _harmony;

        private void Awake()
        {
            Logger.LogInfo(
                PluginName + " v" + PluginVersion + " loading"
            );

            _infiniteFuel = Config.Bind(
                "General",
                "InfiniteFuel",
                true,
                "If enabled, Fire Torch fuel is not consumed."
            );

            RegisterModSettings();

            Type fireTorchType =
                AccessTools.TypeByName(FireTorchTypeName);

            if (fireTorchType == null)
            {
                Logger.LogError(
                    "Could not find game type: " +
                    FireTorchTypeName
                );
                return;
            }

            MethodInfo burnManual =
                AccessTools.Method(
                    fireTorchType,
                    "BurnManual"
                );

            MethodInfo removeFuel =
                AccessTools.Method(
                    fireTorchType,
                    "RemoveFuel"
                );

            MethodInfo prefix =
                AccessTools.Method(
                    typeof(Plugin),
                    "FuelConsumptionPrefix"
                );

            if (prefix == null)
            {
                Logger.LogError(
                    "Could not find Harmony prefix method."
                );
                return;
            }

            _harmony =
                new Harmony(PluginGuid);

            int patchedMethods = 0;

            if (burnManual != null)
            {
                _harmony.Patch(
                    burnManual,
                    prefix: new HarmonyMethod(prefix)
                );

                patchedMethods++;

                Logger.LogInfo(
                    "Patched " +
                    "Interactive_FIRE_TORCH.BurnManual"
                );
            }
            else
            {
                Logger.LogError(
                    "Could not find " +
                    "Interactive_FIRE_TORCH.BurnManual"
                );
            }

            if (removeFuel != null)
            {
                _harmony.Patch(
                    removeFuel,
                    prefix: new HarmonyMethod(prefix)
                );

                patchedMethods++;

                Logger.LogInfo(
                    "Patched " +
                    "Interactive_FIRE_TORCH.RemoveFuel"
                );
            }
            else
            {
                Logger.LogError(
                    "Could not find " +
                    "Interactive_FIRE_TORCH.RemoveFuel"
                );
            }

            if (patchedMethods == 2)
            {
                Logger.LogInfo(
                    PluginName +
                    " loaded. Infinite fuel: " +
                    (_infiniteFuel.Value
                        ? "ON"
                        : "OFF")
                );
            }
            else
            {
                Logger.LogWarning(
                    PluginName +
                    " loaded with only " +
                    patchedMethods +
                    " of 2 fuel-consumption methods patched."
                );
            }
        }

        private void RegisterModSettings()
        {
            bool modRegistered =
                ModSettingsClient.RegisterModLocalized(
                    ModSettingsId,
                    "ФАКЕЛ",
                    "FIRE TORCH",
                    600
                );

            if (!modRegistered)
            {
                Logger.LogInfo(
                    "Mod Settings host not available; " +
                    "using BepInEx config only."
                );

                return;
            }

            bool toggleRegistered =
                ModSettingsClient.AddToggleLocalized(
                    ModSettingsId,
                    "infiniteFuel",
                    "Бесконечное топливо",
                    "Infinite Fuel",
                    100,
                    "Вкл.",
                    "On",
                    "Выкл.",
                    "Off",
                    GetInfiniteFuel,
                    SetInfiniteFuel
                );

            if (toggleRegistered)
            {
                Logger.LogInfo(
                    "Registered Mod Settings toggle: " +
                    "ФАКЕЛ / Бесконечное топливо"
                );
            }
            else
            {
                Logger.LogWarning(
                    "Could not register Infinite Fire Torch " +
                    "toggle in Mod Settings."
                );
            }
        }

        private static bool GetInfiniteFuel()
        {
            return
                _infiniteFuel != null &&
                _infiniteFuel.Value;
        }

        private static void SetInfiniteFuel(
            bool value)
        {
            if (_infiniteFuel == null)
                return;

            _infiniteFuel.Value = value;
        }

        private static bool FuelConsumptionPrefix()
        {
            // Harmony Prefix:
            // true  -> run vanilla BurnManual / RemoveFuel
            // false -> suppress vanilla fuel consumption.
            //
            // If config is unexpectedly unavailable, fail safe by
            // allowing the original game method.
            return
                _infiniteFuel == null ||
                !_infiniteFuel.Value;
        }

        private void OnDestroy()
        {
            if (_harmony != null)
            {
                _harmony.UnpatchSelf();
            }

            ModSettingsClient.RemoveMod(
                ModSettingsId
            );
        }
    }
}
