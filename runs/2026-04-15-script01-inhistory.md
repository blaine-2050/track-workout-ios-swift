# Run: 01-single-set-bench-press (in-history summary fix) — 2026-04-15T10:16 PDT

**Platform:** track-workout-ios-swift @ HEAD (uncommitted in-history refresh fix)
**Harness:** iOS Simulator, iPhone 12, iOS 26.2, via Maestro 2.4.0
**Script:** https://github.com/blaine-2050/track-workout-core/blob/main/WORKOUT_SCRIPTS/01-single-set-bench-press.md

## Result: 🟢 All 12 assertions PASS

```
Launch → Select Exercise → Bench Press → 135 → Reps → 10 → Log → Stop
  ✓ Modal: Workout Complete / 1 set / 1,350 lbs moved
Done → waitForAnimationToEnd
  ✓ In-history summary visible: "Workout ended at …"
  ✓ "Duration: 1 sec"
  ✓ "Sets: 1"
  ✓ In-progress green "Elapsed: …" timer NOT visible
```

## What the fix does

`ContentView.swift` now computes a `workoutsVersion` hash combining each fetched workout's `id` + `endTime`, and applies `.id(workoutsVersion)` to the `EventHistory` view.

When `stopWorkout()` updates `workout.endTime` and saves, the hash changes on the next body evaluation. SwiftUI treats the EventHistory as a different identity and rebuilds it from scratch, so `groupByWorkout` re-runs with the fresh endTime and the private in-history `WorkoutSummaryView` renders.

Without this, SwiftUI was reusing the old EventHistory because the `workouts` array contained the same `NSManagedObject` references (mutated in place) — a known SwiftUI + Core Data gotcha where `@FetchRequest` doesn't always republish on non-sort-key attribute changes in a way the child view recognizes.

## Maestro flow improvements along the way

- Assertions use regex (`"Workout ended at.*"`) — Maestro does **full-string** regex match, not substring.
- `waitForAnimationToEnd` after `tapOn: "Done"` — accessibility hierarchy isn't stable during sheet-dismissal animation.
- Added `assertNotVisible: "Elapsed:.*"` to prove the green in-progress timer is gone post-Stop.

## Next actions

- [x] In-history summary refresh
- [ ] **Script 02 (sticky inputs):** multi-set entry verifying weight/reps persist after Log and replace on first keypress.
- [ ] **Script 03 (stop summary):** should auto-pass now given the fix; worth writing to confirm.
- [ ] **Stale-timer bug** (elapsed calc includes walltime gaps when app was closed). Separate from this fix — that's about individual entry `startedAt → endedAt` spans that were never bounded properly when the workout was abandoned.
- [ ] **Dev-loop ergonomics:** wrap the `terminate → uninstall → install → maestro test` cycle in a single script (`scripts/test-flow.sh <flow>`) so re-runs are one command.
