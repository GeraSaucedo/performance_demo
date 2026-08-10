import 'package:flutter/material.dart';

/// Demo 7 — "Tabbed reports"  ·  FALSE POSITIVE (there is nothing to fix).
///
/// Each tab uses `AutomaticKeepAliveClientMixin` (`wantKeepAlive => true`) to
/// preserve its state when switching tabs. Side effect: the tabs' `State`
/// objects are NOT destroyed when you leave them, so a memory snapshot shows
/// all 4 alive at once even though only one is visible.
///
/// It looks like a leak ("they pile up and are never freed"), but it is
/// INTENTIONAL: this is how each tab's counter (or scroll position) is
/// preserved. Nothing is fixed here.
class Demo7KeepAliveTabs extends StatelessWidget {
  const Demo7KeepAliveTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tabbed reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sales'),
              Tab(text: 'Costs'),
              Tab(text: 'Shipping'),
              Tab(text: 'Returns'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ReportTab(label: 'Sales'),
            ReportTab(label: 'Costs'),
            ReportTab(label: 'Shipping'),
            ReportTab(label: 'Returns'),
          ],
        ),
      ),
    );
  }
}

class ReportTab extends StatefulWidget {
  const ReportTab({super.key, required this.label});

  final String label;

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab>
    with AutomaticKeepAliveClientMixin {
  int _counter = 0;

  // Keep the State alive when switching tabs (to preserve the state).
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Report for ${widget.label}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text('Counter: $_counter'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => setState(() => _counter++),
            child: const Text('Add'),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Switch to another tab and come back: the counter is preserved. '
              'That is the purpose of keepAlive.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
