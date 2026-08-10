import 'dart:async';

import 'package:flutter/material.dart';

/// Demo 4 — "Session clock".
///
/// [LeakyClock] starts a `Timer.periodic` in `initState` but its `dispose`
/// does not cancel it. Every clock created keeps firing its timer forever, and
/// the timer's closure keeps the `State` alive even though the widget no longer exists.
///
/// The "Recycle" button creates and discards many clocks: in the Memory view
/// you can count how many `State` objects stay retained after a snapshot.
class Demo4TimerLeak extends StatefulWidget {
  const Demo4TimerLeak({super.key});

  @override
  State<Demo4TimerLeak> createState() => _Demo4TimerLeakState();
}

class _Demo4TimerLeakState extends State<Demo4TimerLeak> {
  int _recycled = 0;
  bool _busy = false;

  Future<void> _recycle() async {
    setState(() => _busy = true);
    final overlay = Overlay.of(context);
    for (var i = 0; i < 20; i++) {
      final entry = OverlayEntry(builder: (_) => const LeakyClock());
      overlay.insert(entry);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      entry.remove(); // Unmounts the LeakyClock -> calls its dispose().
    }
    if (!mounted) return;
    setState(() {
      _recycled += 20;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session clock')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LeakyClock(showLabel: true),
            const SizedBox(height: 32),
            Text('Clocks created and discarded: $_recycled'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _recycle,
              icon: const Icon(Icons.refresh),
              label: const Text('Recycle 20 clocks'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A clock that updates every second.
class LeakyClock extends StatefulWidget {
  const LeakyClock({super.key, this.showLabel = false});

  final bool showLabel;

  @override
  State<LeakyClock> createState() => _LeakyClockState();
}

class _LeakyClockState extends State<LeakyClock> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Keep the reference so it can be cancelled in dispose().
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    // Cancelling the timer breaks the retention chain: it leaves the internal
    // timer heap, the closure releases the State, and the GC can collect it.
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showLabel) {
      // The recycled copies are invisible; they only exist for the timer.
      return const SizedBox.shrink();
    }
    return Text(
      '⏱  $_seconds s',
      style: Theme.of(context).textTheme.displaySmall,
    );
  }
}
