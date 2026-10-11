import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:flutter/material.dart';

import 'screens/problem_list_screen.dart';

/// Showcase app: 12 everyday optimization problems, each with its story,
/// difficulty, modeling notes, and a live native solve.
///
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DartMathOpt.init();
  runApp(const MathOptShowcaseApp());
}

class MathOptShowcaseApp extends StatelessWidget {
  const MathOptShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dart-Mathopt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const ProblemListScreen(),
    );
  }
}
