import 'package:flutter/material.dart';

/// Demo 2 — "Product search".
///
/// Every keystroke in the search box recomputes the filtered catalog with a
/// deliberately expensive algorithm, and that computation happens inside
/// `build()`, on the UI thread. Each keystroke blocks the thread and drops frames.
class Demo2HeavyBuild extends StatefulWidget {
  const Demo2HeavyBuild({super.key});

  @override
  State<Demo2HeavyBuild> createState() => _Demo2HeavyBuildState();
}

class _Demo2HeavyBuildState extends State<Demo2HeavyBuild> {
  final TextEditingController _search = TextEditingController();

  // "Large" base catalog.
  final List<String> _catalog = List.generate(
    4000,
    (i) => 'Product ${(i * 7919) % 4000} batch ${i % 97}',
  );

  // The score does NOT depend on the query, so it is computed a single time.
  late final List<int> _scores;

  // Already-filtered result. build() only READS this; it never computes it.
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _scores = _computeScores(); // O(n²) once, not on every keystroke.
    _filtered = _filter('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Precomputes the score of every product. Runs a single time.
  List<int> _computeScores() {
    return [
      for (final item in _catalog)
        _catalog
            .where((o) => o.codeUnitAt(0) == item.codeUnitAt(0))
            .fold(0, (sum, o) => sum + o.length),
    ];
  }

  /// Cheap filter: walks the catalog once (O(n)) using the precomputed scores.
  /// This can safely run on every keystroke without blocking the UI.
  List<String> _filter(String query) {
    final q = query.toLowerCase();
    final result = <String>[];
    for (var i = 0; i < _catalog.length; i++) {
      final item = _catalog[i];
      if (q.isEmpty || item.toLowerCase().contains(q)) {
        result.add('$item  ·  score ${_scores[i]}');
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // No heavy work here: build only reads the already-filtered list.
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Product search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Type to filter…',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _filtered = _filter(value)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) => ListTile(
                dense: true,
                title: Text(filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
