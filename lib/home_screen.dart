import 'package:flutter/material.dart';

import 'demos/demo1_rebuilds.dart';
import 'demos/demo2_heavy_build.dart';
import 'demos/demo3_listview_no_builder.dart';
import 'demos/demo4_timer_leak.dart';
import 'demos/demo5_stream_leak.dart';
import 'demos/demo6_animation_leak.dart';
import 'demos/demo7_keepalive_tabs.dart';
import 'demos/demo8_sawtooth.dart';
import 'demos/demo9_isolated_jank.dart';

/// Description of each demo in the menu. The title is intentionally neutral:
/// it does not reveal the performance or memory problem it hides.
class _DemoEntry {
  const _DemoEntry({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final int number;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

final List<_DemoEntry> _demos = [
  _DemoEntry(
    number: 1,
    title: 'Counter panel',
    subtitle: 'Updates a live value',
    builder: (_) => const Demo1Rebuilds(),
  ),
  _DemoEntry(
    number: 2,
    title: 'Product search',
    subtitle: 'Filters a large catalog',
    builder: (_) => const Demo2HeavyBuild(),
  ),
  _DemoEntry(
    number: 3,
    title: 'Activity feed',
    subtitle: 'Long scrollable list',
    builder: (_) => const Demo3ListViewNoBuilder(),
  ),
  _DemoEntry(
    number: 4,
    title: 'Session clock',
    subtitle: 'Stopwatch running in the background',
    builder: (_) => const Demo4TimerLeak(),
  ),
  _DemoEntry(
    number: 5,
    title: 'Live notifications',
    subtitle: 'Subscribes to system events',
    builder: (_) => const Demo5StreamLeak(),
  ),
  _DemoEntry(
    number: 6,
    title: 'Animated card',
    subtitle: 'Looping animation',
    builder: (_) => const Demo6AnimationLeak(),
  ),
  _DemoEntry(
    number: 7,
    title: 'Tabbed reports',
    subtitle: 'Several sections with their own state',
    builder: (_) => const Demo7KeepAliveTabs(),
  ),
  _DemoEntry(
    number: 8,
    title: 'Live monitor',
    subtitle: 'Constantly updates data',
    builder: (_) => const Demo8Sawtooth(),
  ),
  _DemoEntry(
    number: 9,
    title: 'Animated dashboard',
    subtitle: 'Animation with manual reload',
    builder: (_) => const Demo9IsolatedJank(),
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Playground'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _demos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final demo = _demos[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${demo.number}')),
            title: Text(demo.title),
            subtitle: Text(demo.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: demo.builder),
              );
            },
          );
        },
      ),
    );
  }
}
