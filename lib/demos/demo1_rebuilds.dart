import 'dart:async';

import 'package:flutter/material.dart';

/// Demo 1 — "Counter panel".
///
/// A value updates every 500 ms. The `setState` lives at the root of the
/// screen, so on every tick the entire tree below is rebuilt, including a
/// grid of cards that do not depend on the value.
class Demo1Rebuilds extends StatefulWidget {
  const Demo1Rebuilds({super.key});

  @override
  State<Demo1Rebuilds> createState() => _Demo1RebuildsState();
}

class _Demo1RebuildsState extends State<Demo1Rebuilds> {
  Timer? _timer;
  // The changing value lives in its own ValueNotifier so only the widget that
  // depends on it rebuilds — not the whole screen (no setState at the root).
  final _value = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _value.value++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter panel')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            // Only this builder reacts to the ticker; the rest of the tree is
            // left untouched on each tick.
            child: ValueListenableBuilder<int>(
              valueListenable: _value,
              builder: (context, value, child) => Text(
                'Value: $value',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            // The grid no longer rebuilds on every tick: there is no setState at
            // the root, so Flutter never revisits this subtree.
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(8),
              children: List.generate(300, (i) => MetricCard(index: i)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card with a bit of layout work. Non-const ON PURPOSE.
class MetricCard extends StatelessWidget {
  // Non-const ON PURPOSE for the rebuild demo (part of the fix is making it
  // `const` so Flutter can skip it during rebuilds).
  // ignore: prefer_const_constructors_in_immutables
  MetricCard({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, color: Colors.indigo.shade300),
            const SizedBox(height: 4),
            Text('Metric $index'),
          ],
        ),
      ),
    );
  }
}
