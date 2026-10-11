import 'package:flutter/material.dart';

import '../problems/catalog.dart';
import '../problems/demo_problem.dart';
import 'problem_detail_screen.dart';

/// Home screen: cards for all 6 everyday optimization problems.
class ProblemListScreen extends StatelessWidget {
  const ProblemListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final problems = buildCatalog();
    return Scaffold(
      appBar: AppBar(title: const Text('Dart-Mathopt'), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: problems.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Six everyday problems, solved natively with HiGHS & Clarabel. '
                'Tap one to see the story, the model, and the live result.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            );
          }
          return _ProblemCard(problem: problems[index - 1]);
        },
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final DemoProblem problem;

  const _ProblemCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProblemDetailScreen(problem: problem),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      problem.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    problem.difficulty.stars,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(problem.tagline),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Chip(label: problem.difficulty.label),
                  const SizedBox(width: 8),
                  _Chip(label: problem.technique),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
