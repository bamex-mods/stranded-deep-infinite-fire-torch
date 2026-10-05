# BamEx Infinite Fire Torch v1.1.1

Обновление существующего `v1.0.0`.

## Что изменилось

### v1.1.1

- Added Russian/English localization for the Mod Settings section and toggle.
- Synced the vendored bridge with the authoritative bilingual SDK.
- Infinite-fire gameplay, ConfigEntry ownership and split-screen behavior are unchanged.
- Russian/English Mod Settings and torch gameplay were field-tested before publication.

### v1.1.0

Добавлена интеграция с общим Stranded Deep Mod Settings API.

В игре:

```text
НАСТРОЙКИ
→ МОДЫ
→ ФАКЕЛ
→ Бесконечное топливо     Вкл. / Выкл.
```

По умолчанию:

```text
Бесконечное топливо = Вкл.
```

Это сохраняет прежнее поведение v1.0.0.

## Поведение

Вкл.:
- Harmony patches остаются установленными;
- `Interactive_FIRE_TORCH.BurnManual` и `RemoveFuel`
  пропускаются;
- топливо Fire Torch не расходуется.

Выкл.:
- те же patches остаются установленными;
- Prefix разрешает выполнение оригинальных методов игры;
- Fire Torch снова расходует топливо ванильным способом.

Переключение применяется сразу, без перезапуска игры.

Мод не восстанавливает уже израсходованное топливо при включении.
Он только прекращает дальнейший расход.

## Config

Source of truth остаётся внутри самого мода:

```text
General / InfiniteFuel
```

BepInEx ConfigEntry<bool>, default `true`.

Если `StrandedDeepModSettings` отсутствует:
- плагин всё равно загружается;
- настройка всё равно работает через BepInEx config;
- просто нет пункта в игровом меню.

Никакой hard reference на `StrandedDeepModSettings.dll` нет.

## Installation

1. Install BepInEx for Stranded Deep.
2. Download `InfiniteFireTorch-1.1.1.zip` from the GitHub Release.
3. Extract the archive into the Stranded Deep game directory.
4. Allow the included `BepInEx` folder to merge with the existing `BepInEx` folder.
5. Verify that this file exists:

   `BepInEx\plugins\BamEx.InfiniteFireTorch\BamEx.InfiniteFireTorch.dll`

6. Fully restart Stranded Deep.

## Acceptance test

1. Открыть:
   `Настройки -> МОДЫ -> ФАКЕЛ`.
2. Убедиться:
   `Бесконечное топливо = Вкл.`
3. Зажечь Fire Torch и проверить отсутствие расхода.
4. Переключить `Выкл.` без restart.
5. Проверить, что топливо снова начинает расходоваться.
6. Переключить `Вкл.` и проверить прекращение расхода.
7. Полностью перезапустить игру.
8. Убедиться, что выбранное значение сохранилось.
9. Проверить Fire Torch у обоих игроков local split-screen.
