# performance_demo — Flutter DevTools Playground

A practice ground for learning **Flutter DevTools** (Performance, CPU Profiler,
and Memory). The app is a menu of screens; each one trains a distinct
performance- or memory-diagnosis skill.

There are **two kinds** of cases:

- **Real problems** (Demos 1–6): each hides a performance defect or a memory
  leak. The goal is to **detect it with DevTools and fix it**. The answers live
  in [SOLUTIONS.md](SOLUTIONS.md) (spoilers) and the applied fixes live on the
  `solutions` branch.
- **False positives** (Demos 7–9): they *look* suspicious in DevTools but are
  **healthy by design**. Here the goal is the opposite: **investigate and
  conclude that there is nothing to fix**. They are fully documented below.

> Being able to tell a real problem from a false positive — and knowing **when
> NOT to optimize** — is as valuable a skill as knowing how to fix things.

---

## How to run

You need the **Flutter** extension (with Dart) in your IDE. There are three
configurations in [.vscode/launch.json](.vscode/launch.json):

```bash
flutter run --debug      # inspection (rebuilds, inspector)
flutter run --profile    # real-time measurement (jank, CPU) and memory
flutter run --release    # release build (no tooling)
```

When it runs, the console prints a **DevTools** URL; open it (or use your IDE's
button).

### Which mode for what

| You want to measure… | Mode | Why |
|---|---|---|
| Rebuilds, widget tree, repaints | **Debug** | The rebuild counter and the Inspector only exist in debug |
| Jank, CPU, ms per frame | **Profile** | In debug the timings LIE (unoptimized) |
| Memory / leaks | **Debug or Profile** | Leaks are representative in both |
| Raster / GPU | **Profile + real device** | On an emulator GPU times are garbage |

> Rule: **Debug to inspect · Profile to measure · Release to ship.**

---

## Diagnosis methodology

The cycle that repeats in every real case:

1. **Detect** the symptom (red bar, memory that keeps growing).
2. **Locate** the source with the right tool (see the table below).
3. **Fix** it.
4. **Validate** that the symptom is gone.

| Problem type | Symptom | Right tool |
|---|---|---|
| Excessive rebuilds | `build()` runs when it doesn't need to | **Track widget rebuilds** (Performance) |
| Heavy compute (UI/CPU) | high **Build** phase, jank on the UI thread | **CPU Profiler** (Bottom Up / Total Time) |
| Compositing/painting (GPU) | high **Raster** phase, UI thread ~0 | **Frame Analysis** + **Highlight Repaints** |
| Memory leak | memory grows and never drops | **Memory → Diff Snapshots** + retaining path |

**Demos 1–6** exercise this cycle. Their answers: [SOLUTIONS.md](SOLUTIONS.md).

---

## False positives (Demos 7–9)

These are NOT fixed. The goal is to **reproduce the symptom in DevTools and
recognize it as benign**. For each: what it looks like, how to reproduce it, and
what to expect.

### Demo 7 — "Tabbed reports"  ·  keepAlive

**File:** [lib/demos/demo7_keepalive_tabs.dart](lib/demos/demo7_keepalive_tabs.dart)

**What it looks like:** a memory leak — the tab `State`s pile up and are not
released when you switch tabs.

**How to reproduce it in DevTools:**
1. Open Demo 7. Go to **Memory → Diff Snapshots**.
2. **GC → Snapshot A** (while on the first tab).
3. Visit **all** tabs (Sales, Costs, Shipping, Returns); on some of them tap the
   Add button.
4. Return to the first tab → **GC → Snapshot B → Diff**.
5. Look for **`_ReportTabState`**.

**What you'll see:** up to **4 live instances** of `_ReportTabState` at once,
even though only one tab is visible. And they are **not released** by GC.

**Why it is NOT a leak:** each tab uses `AutomaticKeepAliveClientMixin`
(`wantKeepAlive => true`) **on purpose**, to preserve its state (the counter,
the scroll position) when you switch tabs. Keeping them alive is the desired
behavior. Also, the number is **bounded** (4 tabs, it doesn't grow without
limit) — a real leak would grow indefinitely as you repeat the action.

**How to confirm it:** switch tabs, add on one, come back: **the counter was
preserved**. That's the proof keepAlive is doing its job. If you removed the
mixin you'd see only 1 live instance… but you'd lose the state.

---

### Demo 8 — "Live monitor"  ·  sawtooth / transient memory

**File:** [lib/demos/demo8_sawtooth.dart](lib/demos/demo8_sawtooth.dart)

**What it looks like:** a leak — memory keeps climbing while the monitor runs.

**How to reproduce it in DevTools:**
1. Open Demo 8. Go to **Memory** (watch the **live graph** at the top).
2. Tap **"Start monitor"**. Every 400 ms a large temporary list is generated.
3. Watch the memory graph for ~20 seconds.

**What you'll see:** a **sawtooth** pattern — the line rises as the list is
allocated and **drops sharply** when the GC collects it, over and over. The
**baseline** (the valleys) **stays flat**.

**Why it is NOT a leak:** the list is **temporary** — it's created, used, and
goes out of scope on each tick. The GC collects it without trouble; that's why
the graph drops. A real leak would have a baseline that **steps up and never
comes back**. Here the baseline is flat → nothing accumulates.

**How to confirm it:** **GC → Snapshot A** (monitor running) → wait → **GC →
Snapshot B → Diff**: no class is growing. Stop the monitor and memory
stabilizes. (The timer is cancelled in `dispose`, so the screen itself doesn't
leak either.)

> Key difference: **sawtooth = healthy GC. A step that only goes up = leak.**

---

### Demo 9 — "Animated dashboard"  ·  isolated jank spike

**File:** [lib/demos/demo9_isolated_jank.dart](lib/demos/demo9_isolated_jank.dart)

**What it looks like:** jank — on reload a red frame appears in the frames graph.

**How to reproduce it in DevTools:**
1. Run in **profile mode**. Open Demo 9. Go to **Performance**.
2. Watch the spinning animation: the frames graph should be **green/blue**
   (smooth).
3. Tap **"Reload data"** once. Watch the graph.

**What you'll see:** **one** isolated red frame (the one-off compute of the
reload), surrounded by nothing but healthy frames. The animation **does not
stutter** before or after.

**Why it is NOT a problem:** a **one-off** red frame, caused by a one-time
action (loading data, entering a screen), is not jank. The jank that matters is
the **sustained** kind during interaction. Compare it with **Demo 2**, which
stuttered on **every** keystroke — that *was* a problem. Chasing an isolated
spike is wasted time.

**How to confirm it:** look at the **average FPS**: it stays near 60 (or 120).
The animation stays smooth. A lone red frame among dozens of green ones =
healthy.

> Rule: **sustained jank (many red frames in a row while you interact) =
> problem. Isolated spike = ignore it.**

---

## Key lessons

1. **Pick the tool by the type of problem** (see the methodology table). High
   UI/CPU = your Dart code. High Raster = compositing/GPU.
2. **Debug vs Profile vs Release** — inspect / measure / ship. Don't judge
   performance in debug, and don't hunt rebuilds in profile.
3. **The CPU Profiler measures TOTALS, not per-frame.** Its milliseconds are the
   sum over the whole recording; don't compare them to the 16 ms budget (which
   is per frame). Use **%** to find the culprit. *High Total + low Self* → keep
   drilling down; *high Self* → the time is spent right there.
4. **Sustained jank vs isolated spike.** A lone red frame (GC, first frame,
   fling) isn't a problem. Health signal: average FPS near the target rate.
5. **Raster is measured on a real device.** On an emulator GPU times are garbage
   (5–10× slower). And **know when to stop**: if you've already removed the
   code-level causes and it won't drop further, you've hit the environment's
   floor.
6. **Rebuild ≠ Repaint.** Rebuild = `build()` runs (fix it with `const` or by
   isolating state). Repaint = pixels are redrawn (fix it with
   `RepaintBoundary`). A child rebuilds only if its parent rebuilds AND passes it
   a new instance; a `const` widget is the same instance → it's skipped.
7. **GC ≠ dispose.** `dispose` is called by Flutter when the widget is removed
   (not by the GC); it always runs — the leak is missing the cleanup inside it.
   The GC only removes **unreachable** objects: if something long-lived
   references your `State`, the GC respects it → leak. Signature in the diff:
   `Released: 0`, `Delta: +N`.
8. **initState ↔ dispose symmetry.** Whatever you turn on, turn off. Keep what
   "turning on" returns:

   | You turn on | Returns | You turn off in `dispose` |
   |---|---|---|
   | `Timer.periodic(...)` | `Timer` | `timer.cancel()` |
   | `stream.listen(...)` | `StreamSubscription` (not the Stream!) | `sub.cancel()` |
   | `notifier.addListener(fn)` | — | `notifier.removeListener(fn)` |
   | `AnimationController(...)` | the controller | `controller.dispose()` |

   - **Stream vs StreamSubscription:** a `Stream` isn't cancelled; you cancel the
     *subscription* returned by `.listen()`.
   - **Ownership:** if YOU created it → `dispose()`. If it belongs to someone else
     (a global) and you only listen to it → `removeListener`/`cancel`, never close
     it.
   - **`removeListener` needs the SAME function reference** → use a named method,
     not an anonymous lambda (impossible to remove).
   - **Every reference counts:** if there are two retainers, turning off only one
     doesn't close the leak.

---

## Special cases (what you may run into)

### Other memory leaks (same pattern, different object)
`ScrollController`, `TextEditingController`, `PageController`, `TabController`,
`FocusNode` → `.dispose()`. `ChangeNotifier`/`ValueNotifier` that YOU created →
`.dispose()`. `WidgetsBindingObserver` → `removeObserver()`. Unclosed
`Provider`/`Bloc`. The most treacherous: an **anonymous lambda** passed to a
global object (impossible to remove).

### Other false positives you'll see
- **Navigation stack:** screens stacked with `push` without `pop` are still
  alive legitimately (they're on the stack). Going "back" releases them.
- **ImageCache:** Flutter caches images on purpose; memory rises but it's bounded
  and released under pressure.
- **Not-yet-collected objects:** if you didn't force GC before the snapshot,
  you're counting transient garbage.

### Performance — hidden sources of cost
- **Expensive `saveLayer`** is triggered by: `Opacity` (animated), `ShaderMask`,
  `ColorFilter`, `BackdropFilter` (blur), antialiased clips, blurred shadows.
  Cheap alternatives: `FadeTransition`/`AnimatedOpacity`, `Container(color:)`.
- **Huge images:** a 4000×4000 JPG shown at 56 px decodes at full resolution →
  memory and raster blow up. Fix: `cacheWidth`/`cacheHeight` or `ResizeImage`.
  DevTools: **"Highlight Oversized Images"**.
- **Wide rebuilds via `InheritedWidget`:** depending on `MediaQuery.of` or
  `Theme.of` makes your widget rebuild when that changes (e.g. opening the
  keyboard rebuilds half the app).
- **Jank from allocations (GC churn):** creating thousands of objects per frame
  triggers the GC → pauses → periodic jank. Tool: allocation profiler.
- **Shader compilation jank:** the first time an animation runs its shader is
  compiled → an initial stutter. Impeller mitigates this.

### Traps in the tools themselves
- The **first frame** is always slow (route transition). Ignore it.
- **Hot Reload doesn't clear** leaks from the previous session → use **Hot
  Restart** to measure memory.
- In **profile** rebuild source names are missing (it needs
  `track-widget-creation`, debug only).
- **Release obfuscates symbols** → the profiler shows less detail.
- **Isolates** have separate heaps; the memory of a background `compute()`/isolate
  doesn't appear in the main heap.
- The Performance **timeline buffer** expires: inspect frames shortly after
  generating them. Memory **snapshots**, in contrast, persist.

---

## Leak detection at the flow level

To hunt leaks across a long session (not just with the "Recycle" button):

1. Return to a baseline state (e.g. Home) → **GC → Snapshot A**.
2. Repeat the suspicious flow N times (enter/leave a feature 10–20 times).
3. Return to the **same** baseline state → **GC → Snapshot B → Diff**.
4. If a class has a large positive `Delta` → leak confirmed.

Keys: **take both snapshots in the same state** (otherwise legitimate objects
from another screen look like a leak) and **force GC before each snapshot**. The
**live graph** is ideal for spotting the trend (a rising baseline = leak).
Flutter also ships `leak_tracker`, which detects leaks automatically.

---

## References

- [Flutter Performance & Optimization](https://docs.flutter.dev/perf)
- [Using the Performance view](https://docs.flutter.dev/tools/devtools/performance)
- [Using the Memory view](https://docs.flutter.dev/tools/devtools/memory)
- [Using the CPU Profiler](https://docs.flutter.dev/tools/devtools/cpu-profiler)
