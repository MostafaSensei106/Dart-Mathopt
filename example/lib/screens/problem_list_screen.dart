import 'package:flutter/material.dart';

import '../problems/catalog.dart';
import '../problems/demo_problem.dart';
import 'cutting_stock_screen.dart';
import 'feature_demos_screen.dart';
import 'problem_detail_screen.dart';

/// Home screen: live API demos and everyday optimization problems.
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Twelve everyday problems with HiGHS, Clarabel and MicroLP. '
                    'Tap one to see the story, the model, and the live result.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Engine & API demos'),
                    subtitle: const Text(
                      'Compare engines, auto routing, cache and validation',
                    ),
                    trailing: const Icon(Icons.science_outlined),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FeatureDemosScreen(),
                      ),
                    ),
                  ),
                ),
                Card(
                  elevation: 0,
                  color: Colors.purple.shade50,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CuttingStockScreen(),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'FACTORY MVP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'UPVC Cutting Stock',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Text(
                                '★★★',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 16,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Order windows (Sliding / Tilt / Casement), set the bar & kerf, get the optimal cutting plan. For the workshop, not the classroom.',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Interactive • MILP + FFD • HiGHS',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Academy examples',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }
          return _ProblemCard(problem: problems[index - 1]);
        },
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({required this.problem});
  final DemoProblem problem;

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
  const _Chip({required this.label});
  final String label;

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
