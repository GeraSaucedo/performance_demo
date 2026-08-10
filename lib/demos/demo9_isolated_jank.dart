import 'package:flutter/material.dart';

/// Demo 9 — "Animated dashboard"  ·  FALSE POSITIVE (there is nothing to fix).
///
/// An animation spins smoothly (green frames, no jank). Pressing "Reload data"
/// runs ONE one-off computation that produces ONE red frame.
///
/// It looks like jank, but it is an ISOLATED spike caused by a one-off action
/// (like loading data when entering a screen). It is not sustained jank: the
/// animation stays smooth. A lone red frame is not worth chasing; only jank
/// that repeats during interaction matters (compare it with Demo 2, which
/// stuttered on EVERY keystroke). Nothing to optimize here.
class Demo9IsolatedJank extends StatefulWidget {
  const Demo9IsolatedJank({super.key});

  @override
  State<Demo9IsolatedJank> createState() => _Demo9IsolatedJankState();
}

class _Demo9IsolatedJankState extends State<Demo9IsolatedJank>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _reloads = 0;
  int _checksum = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose(); // clean: this demo does not leak
    super.dispose();
  }

  void _reload() {
    // One-off work (~one frame): sort a large list.
    final data = List.generate(500000, (i) => (i * 7919) % 500000);
    data.sort();
    setState(() {
      _reloads++;
      _checksum = data[data.length ~/ 2]; // use the result so it is not elided
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animated dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: const Icon(Icons.settings, size: 96, color: Colors.indigo),
            ),
            const SizedBox(height: 24),
            Text('Reloads: $_reloads  ·  checksum: $_checksum'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload data'),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'The animation runs smoothly. Reloading causes ONE isolated slow '
                'frame, not sustained jank.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
