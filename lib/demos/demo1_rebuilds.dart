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
  int _value = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => _value++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            child: Text(
              'Value: $_value',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            // This grid does not depend on `_value`, but it is rebuilt in full
            // on every tick because the setState is at the root of the screen.
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
  // Non-const ON PURPOSE for the rebuild demo. Be precise about what `const`
  // can and can't do here: a `const` CONSTRUCTOR on this class compiles fine
  // (that's what prefer_const_constructors_in_immutables asks for), but it buys
  // nothing, because the call site can't be const — `const MetricCard(index: i)`
  // is an "Invalid constant value" error since `i` only exists at runtime. What
  // actually skips the subtree is handing back the SAME instances on every
  // build: build the list once into a field. See SOLUTIONS.md, Demo 1.
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
