import 'package:flutter/material.dart';

/// Demo 3 — "Activity feed".
///
/// Builds a list of 5000 items all at once with `ListView(children: ...)`
/// instead of `ListView.builder`. Every child is instantiated even if it is
/// not visible, and each one uses `Opacity` (which forces an extra layer when painting).
class Demo3ListViewNoBuilder extends StatelessWidget {
  const Demo3ListViewNoBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity feed')),
      // ListView.builder lazily builds only the rows that are visible.
      body: ListView.builder(
        itemCount: 5000,
        itemBuilder: (context, index) => FeedRow(index: index),
      ),
    );
  }
}

class FeedRow extends StatelessWidget {
  const FeedRow({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    // No Opacity: the GPU no longer creates a compositing layer per row.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text('${index % 100}')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event #$index',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Activity logged in the system · id $index'),
              ],
            ),
          ),
          const Icon(Icons.more_vert),
        ],
      ),
    );
  }
}
