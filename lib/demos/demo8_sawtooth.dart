import 'dart:async';

import 'package:flutter/material.dart';

/// Demo 8 — "Live monitor"  ·  FALSE POSITIVE (there is nothing to fix).
///
/// While the monitor runs, every 400 ms it generates a large TEMPORARY list
/// that is discarded right away. In the live memory chart you will see a
/// "sawtooth" pattern: memory rises on allocation and falls when the GC cleans up.
///
/// It looks like "a memory leak" because it keeps rising, but the BASE line
/// stays flat: it is transient garbage the GC collects without any trouble.
/// The timer is cancelled in dispose, so this demo has NO leak at all.
class Demo8Sawtooth extends StatefulWidget {
  const Demo8Sawtooth({super.key});

  @override
  State<Demo8Sawtooth> createState() => _Demo8SawtoothState();
}

class _Demo8SawtoothState extends State<Demo8Sawtooth> {
  Timer? _timer;
  bool _running = false;
  int _ticks = 0;
  int _lastSize = 0;

  void _toggle() {
    setState(() {
      _running = !_running;
      if (_running) {
        _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
          // TEMPORARY garbage: created, used trivially, and goes out of scope.
          final temp = List.generate(
            300000,
            (i) => 'sample $i · batch $_ticks',
          );
          _lastSize = temp.length;
          setState(() => _ticks++);
          // `temp` dies here → the GC will collect it → sawtooth.
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // clean: this demo does not leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live monitor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _running ? Icons.monitor_heart : Icons.monitor_heart_outlined,
              size: 64,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            Text('Updates: $_ticks'),
            Text('Last batch: $_lastSize samples'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _toggle,
              icon: Icon(_running ? Icons.stop : Icons.play_arrow),
              label: Text(_running ? 'Stop monitor' : 'Start monitor'),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'With the monitor active, watch the memory chart: it rises and '
                'falls in a sawtooth, but the baseline does not grow.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
