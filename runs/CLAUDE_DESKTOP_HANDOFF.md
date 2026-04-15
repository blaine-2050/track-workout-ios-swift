# Handoff: Claude Desktop UI-Driving Protocol

Template for driving the Track Workout iOS app through workout scripts via Claude Desktop (macOS) computer use.

## Prerequisites (verify before starting)

- [ ] iOS Simulator is running with `com.athenia.TrackWorkout` installed and launched.
- [ ] App state is clean (fresh install — use handoff checklist below if not).
- [ ] Simulator window is visible on this Mac's screen.
- [ ] Repo is at `/Users/dev/Athenia/projects/track-workout-ios-swift`.

## Paste this into Claude Desktop to start a run

```
Drive the iOS Simulator on this Mac to execute workout script 01 for the Track Workout app.

Script: https://github.com/blaine-2050/track-workout-core/blob/main/WORKOUT_SCRIPTS/01-single-set-bench-press.md
Repo on disk: /Users/dev/Athenia/projects/track-workout-ios-swift
Bundle ID: com.athenia.TrackWorkout

For each step in the script:
1. Perform the UI action in the Simulator.
2. Take a screenshot to /Users/dev/Athenia/projects/track-workout-ios-swift/runs/screens/2026-04-14-script01-stepN-<slug>.png using:
   xcrun simctl io booted screenshot <path>.png
3. Observe whether the step's "should be visible" / "display reads" assertion holds. Note any divergence.

When done, write a run report at /Users/dev/Athenia/projects/track-workout-ios-swift/runs/2026-04-14-script01.md using this structure:

# Run: 01-single-set-bench-press — <ISO timestamp>
Platform: track-workout-ios-swift @ <git sha>
Harness: iOS Simulator, iPhone 12, iOS 26.2

## Steps
1. <step> — PASS/FAIL — runs/screens/<file>.png — <notes>
...

## Observations
- <any operational notes>

## Next actions
- [ ] <proposed fix or followup>

After writing the report, commit both the report and all screenshots with:
  git add runs/
  git commit -m "Run: script 01 single-set bench press"
  git push

Do not modify app code during this run — only drive and observe. If you need to make the app testable (e.g. accessibility IDs), note it in "Next actions" rather than editing.
```

## Reset-state checklist (run before each scripted test)

Clean state is a precondition for most scripts. From a terminal on this Mac:

```bash
xcrun simctl terminate booted com.athenia.TrackWorkout
xcrun simctl uninstall booted com.athenia.TrackWorkout
xcrun simctl install booted /Users/dev/Athenia/projects/track-workout-ios-swift/TrackWorkout/build/Build/Products/Debug-iphonesimulator/TrackWorkout.app
xcrun simctl launch booted com.athenia.TrackWorkout
```

If the build is stale, rebuild first:

```bash
cd /Users/dev/Athenia/projects/track-workout-ios-swift/TrackWorkout
xcodebuild -project TrackWorkout.xcodeproj -scheme TrackWorkout \
  -destination 'platform=iOS Simulator,name=iPhone 12' \
  -configuration Debug -derivedDataPath ./build build
```

## Why this handoff exists

Claude Code (the CLI tool used to set up this repo) cannot drive UI in the Simulator — `simctl` has no generic tap command. Claude Desktop, running on this Mac, has computer-use capability and can click buttons in the Simulator window directly. This doc is the bridge: Claude Code builds/launches; Claude Desktop drives; both commit to the same repo.

## Screenshot naming convention

`YYYY-MM-DD-script<NN>-step<N>-<slug>.png` — e.g. `2026-04-14-script01-step3-weight-135.png`.

Baseline (pre-run) screenshots: `YYYY-MM-DD-<descriptor>-baseline.png`.
