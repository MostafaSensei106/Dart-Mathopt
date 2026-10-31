import 'package:flutter/material.dart';

import '../feature_demos.dart';

/// Live demonstrations of the shipped changelog features.
class FeatureDemosScreen extends StatefulWidget {
  const FeatureDemosScreen({super.key});

  @override
  State<FeatureDemosScreen> createState() => _FeatureDemosScreenState();
}

class _FeatureDemosScreenState extends State<FeatureDemosScreen> {
  final _demos = buildFeatureDemos();
  final _output = <int, String>{};
  int? _running;

  Future<void> _run(int index) async {
    setState(() => _running = index);
    try {
      final output = await _demos[index].run();
      if (mounted) setState(() => _output[index] = output);
    } catch (error) {
      if (mounted) setState(() => _output[index] = 'Run failed: $error');
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Engine & API demos')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Live examples of the shipped features. Native builds include '
          'HiGHS, Clarabel and MicroLP; web includes Clarabel and MicroLP. '
          'Auto selects Clarabel for LP and HiGHS for native MILP.',
        ),
        for (var i = 0; i < _demos.length; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _demos[i].title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(_demos[i].description),
                  ElevatedButton(
                    onPressed: _running == null ? () => _run(i) : null,
                    child: Text(_running == i ? 'Running…' : 'Run example'),
                  ),
                  if (_output[i] != null) SelectableText(_output[i]!),
                ],
              ),
            ),
          ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Roadmap — not runnable yet\n'
              'QP and SOCP need compiler/DTO support. Clarabel duals, '
              'implication/indicator helpers, and SOS1/SOS2 are also '
              'planned, not exposed by the current API. '
              'Web MILP has no supported backend.',
            ),
          ),
        ),
      ],
    ),
  );
}
