import 'dart:async';

import 'package:flutter/material.dart';

import '../global_bus.dart';

/// Demo 5 — "Live notifications".
///
/// [LiveNotifications] subscribes to the global stream `GlobalBus.instance.events`
/// in `initState`, but never cancels the subscription in `dispose`. The global
/// `StreamController` keeps the callback (and with it, the entire `State`),
/// so each instance stays retained forever.
class Demo5StreamLeak extends StatefulWidget {
  const Demo5StreamLeak({super.key});

  @override
  State<Demo5StreamLeak> createState() => _Demo5StreamLeakState();
}

class _Demo5StreamLeakState extends State<Demo5StreamLeak> {
  int _recycled = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    GlobalBus.instance.ensureStarted();
  }

  Future<void> _recycle() async {
    setState(() => _busy = true);
    final overlay = Overlay.of(context);
    for (var i = 0; i < 20; i++) {
      final entry = OverlayEntry(builder: (_) => const LiveNotifications());
      overlay.insert(entry);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      entry.remove(); // Unmounts -> dispose(), but the subscription stays alive.
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
      appBar: AppBar(title: const Text('Live notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LiveNotifications(showLabel: true),
            const SizedBox(height: 32),
            Text('Subscribers created and discarded: $_recycled'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _recycle,
              icon: const Icon(Icons.refresh),
              label: const Text('Recycle 20 subscribers'),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveNotifications extends StatefulWidget {
  const LiveNotifications({super.key, this.showLabel = false});

  final bool showLabel;

  @override
  State<LiveNotifications> createState() => _LiveNotificationsState();
}

class _LiveNotificationsState extends State<LiveNotifications> {
  int _lastEvent = 0;
  // Store the subscription (not the stream) so it can be cancelled.
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    // .listen(...) returns the StreamSubscription: that is what gets cancelled.
    _sub = GlobalBus.instance.events.stream.listen((value) {
      if (mounted) setState(() => _lastEvent = value);
    });
  }

  @override
  void dispose() {
    // Cancelling the subscription disconnects the callback from the global
    // StreamController, breaking the retention chain to this State.
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showLabel) return const SizedBox.shrink();
    return Text(
      '🔔  event $_lastEvent',
      style: Theme.of(context).textTheme.displaySmall,
    );
  }
}
