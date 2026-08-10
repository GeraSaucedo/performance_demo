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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Artificially heavy filter: for each product it walks the whole catalog
  /// again (O(n²)) and does string work. Runs on the UI thread.
  List<String> _expensiveFilter(String query) {
    final result = <String>[];
    for (final item in _catalog) {
      var score = 0;
      for (final other in _catalog) {
        if (other.codeUnitAt(0) == item.codeUnitAt(0)) {
          score += other.length;
        }
      }
      if (query.isEmpty ||
          item.toLowerCase().contains(query.toLowerCase())) {
        result.add('$item  ·  score $score');
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // The expensive computation happens here, on every rebuild (every keystroke).
    final filtered = _expensiveFilter(_search.text);

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
              onChanged: (_) => setState(() {}),
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
