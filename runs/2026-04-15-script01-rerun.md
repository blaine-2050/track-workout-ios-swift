# Run: 01-single-set-bench-press (re-run after fix) — 2026-04-15T09:45 PDT

**Platform:** track-workout-ios-swift @ HEAD (uncommitted Stop-summary fix)
**Harness:** iOS Simulator, iPhone 12, iOS 26.2, via Maestro 2.4.0
**Script:** https://github.com/blaine-2050/track-workout-core/blob/main/WORKOUT_SCRIPTS/01-single-set-bench-press.md
**Flow:** `runs/flows/script01-single-set-bench-press.yaml` (now includes Step 7 assertions + Step 8 dismiss)

## Result: 🟢 All 8 steps PASS

```
Launch app → PASS
assertVisible Select Exercise, Log → PASS
Tap Select Exercise → picker opens → PASS
Tap Bench Press → selected → PASS
Tap 1, 3, 5 → Weight=135 → PASS
Tap Reps → switch field → PASS
Tap 1, 0 → Reps=10 → PASS
Tap Log → entry in history → PASS
Tap Stop → summary sheet appears → PASS
  assertVisible "Workout Complete" → PASS
  assertVisible "1 set" → PASS
  assertVisible "1,350 lbs moved" → PASS
Tap Done → sheet dismisses → PASS
```

## Fix summary

Added `WorkoutCompletedSheet` + `WorkoutSummaryData` in `ContentView.swift`. `stopWorkout()` now:
1. Captures `endTime` locally.
2. Sets `workout.endTime`, stamps `endedAt` on the final entry.
3. Builds a `WorkoutSummaryData` (endTime, duration, setCount, totalsByUnit).
4. Saves context.
5. Clears `currentWorkout` and `selectedMove`.
6. Sets `completedSummary`, which triggers the sheet via `.sheet(item:)`.

Sheet shows: **Workout Complete**, Ended (formatted date), Duration (human-readable), Sets count, Total by unit ("1,350 lbs moved"), and a **Done** button. Medium presentation detent so user can see prior UI.

Screenshot: [step7-stopped.png](screens/2026-04-15-script01-step7-stopped.png).

## Observations

- **Primary bug (no summary on Stop) is fixed.** Script 01 pass criteria now fully met.
- **Script 03 should also now pass** (same summary surface), modulo one caveat below.
- **Secondary bug surfaced:** the in-history per-workout summary (the private `WorkoutSummaryView` in `EventHistory.swift` that shows "Workout ended at …" + duration/sets/total below a completed workout) still does not render after Stop. Visible in [step8-dismissed.png](screens/2026-04-15-script01-step8-dismissed.png): history still shows green `Elapsed: 0:04` timer for the just-stopped workout. Likely cause: `@FetchRequest<Workout>` in `ContentView` does not propagate an in-place attribute change (endTime) to the child `EventHistory` view's rendering. The Workout record is saved (modal reads its duration correctly), but SwiftUI isn't re-evaluating the history bucket with the updated endTime.
- **Stale-timer bug (from Step 0 and first run)** is the same class of bug — both relate to the in-history view reading stale workout state.

## Next actions

- [ ] **Fix in-history summary refresh.** Two options:
  1. Force EventHistory to observe the current workout's endTime explicitly (pass it as a binding).
  2. Refetch workouts after `stopWorkout()` via `viewContext.refreshAllObjects()` or an explicit `viewContext.processPendingChanges()` + a state bump to trigger view rebuild.
- [ ] **Then re-run script 01 once more** to verify green timer is gone post-Stop.
- [ ] **Write script 02 (sticky inputs)** and **script 03 (stop summary)** flows.
- [ ] **Tackle stale-timer bug** (elapsed calc should clamp to workout-active time).
