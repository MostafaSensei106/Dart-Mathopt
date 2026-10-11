import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter/material.dart';

import '../problems/demo_problem.dart';

/// Detail screen: story, difficulty, modeling notes, live native solve.
class ProblemDetailScreen extends StatefulWidget {
  final DemoProblem problem;

  const ProblemDetailScreen({super.key, required this.problem});

  @override
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  bool _isSolving = false;
  String? _output;
  String? _stats;
  String? _errorText;

  Future<void> _solve() async {
    setState(() {
      _isSolving = true;
      _output = null;
      _stats = null;
      _errorText = null;
    });
    try {
      // Built fresh on every tap; runs on the Rust thread pool, so the
      // progress indicator below keeps animating at 60 fps.
      final model = widget.problem.createModel();
      final result = await model.solve(
        options: widget.problem.preferredOptions,
      );
      if (!mounted) return;
      setState(() {
        if (result.status == SolveStatus.optimal) {
          _output = widget.problem.describeResult(result);
          _stats =
              'solved in ${result.statistics.solveTimeMs} ms • '
              '${result.statistics.iterations} iterations • '
              'status: ${result.status.name}';
        } else {
          _errorText = 'Solver finished with status: ${result.status.name}';
        }
      });
    } on MathOptException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isSolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.problem;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(p.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(title: 'The problem ${p.difficulty.stars}', body: p.story),
            _Section(
              title: 'Why "${p.difficulty.label}"?',
              body: p.difficultyReason,
            ),
            _SectionList(title: 'How it becomes math', items: p.modelingNotes),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isSolving ? null : _solve,
              icon: _isSolving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isSolving ? 'Solving natively…' : 'Solve now'),
            ),
            if (_output != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.green.shade50,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Result',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _output!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                      if (_stats != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _stats!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_errorText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  final String title;
  final List<String> items;

  const _SectionList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
