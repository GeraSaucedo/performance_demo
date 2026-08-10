import 'package:flutter/material.dart';

import '../global_bus.dart';

/// Demo 6 — "Animated card".
///
/// [PulsingCard] creates an `AnimationController` with `vsync` and also
/// registers a listener on the global `ValueNotifier` `GlobalBus.instance.ticker`.
/// In `dispose` it frees neither: the controller stays tied to the vsync
/// ticker and the listener stays in the global notifier's list.
class Demo6AnimationLeak extends StatefulWidget {
  const Demo6AnimationLeak({super.key});

  @override
  State<Demo6AnimationLeak> createState() => _Demo6AnimationLeakState();
}

class _Demo6AnimationLeakState extends State<Demo6AnimationLeak> {
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
      final entry = OverlayEntry(builder: (_) => const PulsingCard());
      overlay.insert(entry);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      entry.remove(); // Unmounts -> dispose(), without freeing controller/listener.
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
      appBar: AppBar(title: const Text('Animated card')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PulsingCard(showLabel: true),
            const SizedBox(height: 32),
            Text('Cards created and discarded: $_recycled'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _recycle,
              icon: const Icon(Icons.refresh),
              label: const Text('Recycle 20 cards'),
            ),
          ],
        ),
      ),
    );
  }
}

class PulsingCard extends StatefulWidget {
  const PulsingCard({super.key, this.showLabel = false});

  final bool showLabel;

  @override
  State<PulsingCard> createState() => _PulsingCardState();
}

class _PulsingCardState extends State<PulsingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Listener on a global notifier: never removed.
    GlobalBus.instance.ticker.addListener(_onTick);
  }

  void _onTick() {
    // Does nothing visible, but keeps a reference to this State.
  }

  // Default dispose(): does NOT call _controller.dispose() nor removeListener.

  @override
  Widget build(BuildContext context) {
    if (!widget.showLabel) return const SizedBox.shrink();
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.2).animate(_controller),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.indigo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 48),
      ),
    );
  }
}
