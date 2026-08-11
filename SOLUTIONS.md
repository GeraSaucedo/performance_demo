# Solutions — Flutter DevTools Playground

> ⚠️ **Spoilers.** This file reveals the problem in each demo. Use it only if you
> get stuck: first try to spot the cause yourself with DevTools.

> **Scope:** this file covers **Demos 1–6**, the real defects. Demos 7–9 are the
> deliberate **false positives** — they look broken in DevTools and are healthy by
> design, so there is no fix to document. They're explained in
> [README.md](README.md#false-positives-demos-79).

## How to open DevTools

1. Run the app. For memory, **profile mode** is preferable:
   ```bash
   flutter run --profile        # or --debug to test rebuilds/UI
   ```
2. The console prints a **DevTools** URL; open it (or use your IDE's button).
3. Views we'll use:
   - **Performance** → frame timeline, plus the **Rebuild Stats** tab with
     **Count widget builds** ticked.
   - **CPU Profiler** → where CPU time is spent.
   - **Memory** → heap snapshots, *diff*, and instance counts.

> Note: **Count widget builds**, the Inspector, **Highlight Repaints** and
> **Render Opacity layers** only exist in **debug** — the framework compiles those
> flags out of profile builds. Time profiling (jank/CPU) and raster times are only
> trustworthy in **profile**. So a raster investigation is two passes: profile for
> *how much*, debug for *which widget*.

---

## Demo 1 — "Counter panel"  ·  *Excessive rebuilds*

**File:** [lib/demos/demo1_rebuilds.dart](lib/demos/demo1_rebuilds.dart)

**Symptom:** on entry, the value rises every 500 ms and the whole grid flickers
with work even though nothing in it changes.

**How to detect it:**
- Performance → **Rebuild Stats** tab → tick **Count widget builds**. `MetricCard`
  (and its `Card`, `Icon`, `Text`) climb on every tick, while the widgets that
  don't depend on the counter sit at 1.
- Don't expect 300. `GridView` is lazy: only the cards currently on screen get a
  `build()` call, so the count is a couple of dozen and depends on your viewport.
  What *does* happen 300 times per tick is `List.generate` allocating 300 fresh
  `MetricCard` objects — only the visible ones are built.
- Don't confuse **Count widget builds** with **Trace widget builds** in the
  *Enhance Tracing* dropdown: the first gives you the counts table, the second
  adds per-widget `Build` events to the timeline. Both are debug-only.

**Cause:** the `setState` is in `_Demo1RebuildsState`, the root of the screen,
so Flutter rebuilds the entire subtree — including the `GridView` — even though
only the counter text changed. On top of that, `List.generate` hands the grid a
brand-new set of `MetricCard` instances on every build, so Flutter can't
short-circuit any of them.

**Fix:**
- Isolate the state that changes: move the counter into its own small widget, or
  use a `ValueNotifier<int>` + `ValueListenableBuilder` that wraps only the
  `Text`. This stops the parent from rebuilding at all.
- Reuse the card instances so Flutter can skip them when a rebuild does happen.
  Be precise about `const` here, because it's the usual wrong turn: giving
  `MetricCard` a **const constructor** compiles fine and costs nothing, but it
  buys you nothing either, because the **call site** can't be const —
  `const MetricCard(index: i)` inside `List.generate` is an *"Invalid constant
  value"* error, since `i` only exists at runtime. Hoist the list into a field
  instead:
  `late final List<Widget> _cards = List.generate(300, (i) => MetricCard(index: i));`
  and pass `_cards` to the grid. (`const` is the special case of this same idea,
  for when every argument *is* constant — see the `const Divider` and the
  `const Text` in the AppBar, which already sit at 0 rebuilds per tick.)

---

## Demo 2 — "Product search"  ·  *Heavy work on the UI thread*

**File:** [lib/demos/demo2_heavy_build.dart](lib/demos/demo2_heavy_build.dart)

**Symptom:** typing in the search box feels laggy; the cursor and the list
stutter.

**How to detect it:**
- Performance → you'll see **UI thread** frames well above 16 ms (jank) with
  every keystroke.
- CPU Profiler → record while typing: `_expensiveFilter` dominates the time.

**Cause:** `_expensiveFilter` is O(n²) over 4000 items and runs **inside
`build()`**, on the UI thread, on every rebuild (every keystroke).

**Fix:**
- Don't compute in `build()`. Precompute/memoize the result and recompute it
  only when the query changes (e.g. in `onChanged`, storing the list in state).
- Remove the O(n²): the `score` doesn't depend on the query; compute it once.
- If the work is still heavy, move it off the UI thread with `compute()` / an
  `Isolate`, or debounce the search.

---

## Demo 3 — "Activity feed"  ·  *List without `.builder` + `Opacity`*

**File:** [lib/demos/demo3_listview_no_builder.dart](lib/demos/demo3_listview_no_builder.dart)

**Symptom:** on open there's an initial stutter and scrolling isn't quite
smooth.

**How to detect it:**
- Performance → a very long initial frame while building the screen (all 5000
  children are created at once).
- The **raster thread** suffers from the `Opacity`/shadow layers.

**Cause:** `ListView(children: List.generate(5000, ...))` instantiates all 5000
`FeedRow`s even though they aren't visible. In addition, each row uses
`Opacity`, which forces an extra compositing layer when painting.

**Fix:**
- Use `ListView.builder` (or `.separated`): it builds only what's visible,
  lazily.
- Remove the unnecessary `Opacity` (opacity 0.99 adds nothing). If you need
  constant transparency, use a color with alpha instead of wrapping in
  `Opacity`.

---

## Demo 4 — "Session clock"  ·  *`Timer.periodic` never cancelled*

**File:** [lib/demos/demo4_timer_leak.dart](lib/demos/demo4_timer_leak.dart)

**Reproduce:** tap **"Recycle 20 clocks"** several times (it creates and discards
`LeakyClock`s in an overlay).

**How to detect it:**
- Memory → take a **snapshot**, recycle, force **GC** and take another snapshot.
  Do a **diff**: the number of `_LeakyClockState` instances grows and **doesn't
  drop** even though none are mounted anymore.
- Memory usage steps up with each batch and doesn't recover.

**Cause:** in `_LeakyClockState.initState` a `Timer.periodic` is created that is
never cancelled. The timer's closure references the `State`, so the GC can't
collect it. Each recycled clock leaves a live timer forever.

**Fix:**
```dart
Timer? _timer;
@override void initState() { super.initState();
  _timer = Timer.periodic(const Duration(seconds: 1), (_) { ... });
}
@override void dispose() { _timer?.cancel(); super.dispose(); }
```

---

## Demo 5 — "Live notifications"  ·  *`StreamSubscription` never cancelled*

**File:** [lib/demos/demo5_stream_leak.dart](lib/demos/demo5_stream_leak.dart)

**Reproduce:** tap **"Recycle 20 subscribers"** several times.

**How to detect it:**
- Memory → same procedure: snapshot → recycle → GC → snapshot → diff. The
  `_LiveNotificationsState` instances pile up and are not released.
- Hint about the cause: the retainer is the global `StreamController` (look at
  the retaining path / "inbound references" of the object in the snapshot).

**Cause:** `_LiveNotificationsState.initState` calls
`GlobalBus.instance.events.stream.listen(...)` without storing or cancelling the
subscription. The global (long-lived) `StreamController` keeps the callback and,
with it, the whole `State`.

**Fix:**
```dart
StreamSubscription<int>? _sub;
@override void initState() { super.initState();
  _sub = GlobalBus.instance.events.stream.listen((v) { ... });
}
@override void dispose() { _sub?.cancel(); super.dispose(); }
```

---

## Demo 6 — "Animated card"  ·  *`AnimationController` / listener never released*

**File:** [lib/demos/demo6_animation_leak.dart](lib/demos/demo6_animation_leak.dart)

**Reproduce:** tap **"Recycle 20 cards"** several times.

**How to detect it:**
- Memory → snapshot → recycle → GC → snapshot → diff: `_PulsingCardState` (and
  its `AnimationController`s) pile up.
- In **debug** this leak is not silent: `SingleTickerProviderStateMixin.dispose()`
  asserts that its `Ticker` is no longer active and throws
  *"…was disposed with an active Ticker"* when it is. The check lives inside an
  `assert`, so it is compiled out of profile and release builds — which is why the
  same run is loud in debug and quiet in profile.

**Cause:** two leaks in `_PulsingCardState.initState`:
1. It creates an `AnimationController` (with `vsync: this` and `repeat`) that is
   never released with `dispose()`.
2. It registers `GlobalBus.instance.ticker.addListener(_onTick)` and never
   removes it; the global notifier retains the `State`.

**Fix:**
```dart
@override void dispose() {
  GlobalBus.instance.ticker.removeListener(_onTick);
  _controller.dispose();
  super.dispose();
}
```

---

## General routine for hunting memory leaks in DevTools

1. Open the screen and go to **Memory**.
2. Take a baseline **snapshot**.
3. Run the trigger (the "Recycle 20…" button) once or twice.
4. Tap **GC** (force collection).
5. Take another snapshot and use **Diff** between the two.
6. Sort by class (`_LeakyClockState`, `_LiveNotificationsState`,
   `_PulsingCardState`): if they grow and never drop back, there's a leak.
7. Select an instance and inspect the **retaining path** (who keeps it alive):
   there you'll find the guilty timer, stream, or notifier.
