// ignore_for_file: avoid_print
/// 1D Cutting Stock solver: exact MILP (HiGHS) with BFD upper bound,
///
/// symmetry breaking, and automatic BFD fallback for factory-size batches.
///
/// Math model (assignment formulation):
/// * y[j] = 1 when bar j is used.
/// * x[i][j] = 1 when piece i is cut from bar j.
/// * minimize Σ y[j]
/// * every piece placed exactly once: Σ_j x[i][j] = 1
/// * capacity per bar: Σ_i (len[i]+kerf)·x[i][j] − barLen·y[j] ≤ 0
///   (written with a numeric RHS because the DSL only accepts `<= num`).
/// * linking: x[i][j] − y[j] ≤ 0
/// * symmetry breaking: y[j] − y[j+1] ≥ 0 (use bars in order).
library;

import 'package:dart_mathopt/dart_mathopt.dart';

import '../data/upvc_catalog.dart';

/// One demanded piece after order expansion (keeps its label for the plan).
class DemandedPiece {
  const DemandedPiece(this.label, this.lengthMm, {this.source = ''});

  final String label;
  final double lengthMm;

  /// Which order line it came from: "W1" (window line 1), "C1" (custom 1).
  /// Lets the plan say which bar serves which window.
  final String source;
}

/// A single bar in the final plan.
class BarPlan {
  const BarPlan({
    required this.pieces,
    required this.usedMm,
    required this.wasteMm,
    required this.kerfTotalMm,
  });

  /// Pieces cut from this bar (labels + lengths).
  final List<CutPiece> pieces;

  /// Σ piece lengths (without kerf).
  final double usedMm;

  /// Leftover scrap: barLen − usedMm − kerfTotalMm.
  final double wasteMm;

  /// Saw loss inside this bar.
  final double kerfTotalMm;

  /// Order lines served by this bar, e.g. {"W1", "W3"}.
  Set<String> get sources =>
      {for (final p in pieces) if (p.source.isNotEmpty) p.source};
}

/// Whole cutting plan returned to the UI / console.
class CuttingPlan {
  const CuttingPlan({
    required this.bars,
    required this.barLengthMm,
    required this.kerfMm,
    required this.isOptimal,
    required this.solveTimeUs,
    required this.reusableThresholdMm,
  });

  final List<BarPlan> bars;
  final double barLengthMm;
  final double kerfMm;

  /// Leftover ≥ this length counts as reusable stock, not scrap.
  final double reusableThresholdMm;

  /// `true` when HiGHS proved optimality, `false` for FFD fallback/incumbent.
  final bool isOptimal;

  /// Engine-reported microseconds (`0` for pure-heuristic plans).
  final int solveTimeUs;

  int get barsUsed => bars.length;

  double get totalDemandMm =>
      bars.fold(0, (s, b) => s + b.usedMm);

  double get totalWasteMm => bars.fold(0, (s, b) => s + b.wasteMm);

  double get wastePct {
    final total = barsUsed * barLengthMm;
    if (total <= 0) return 0;
    return 100 * totalWasteMm / total;
  }

  /// True scrap: leftovers too short to reuse.
  double get scrapMm => bars.fold(
      0,
      (s, b) =>
          s + (b.wasteMm < reusableThresholdMm ? b.wasteMm : 0));

  /// Reusable offcuts: leftovers that go back to stock.
  double get reusableMm => bars.fold(
      0,
      (s, b) =>
          s + (b.wasteMm >= reusableThresholdMm ? b.wasteMm : 0));

  /// The number the factory owner cares about.
  double get scrapPct {
    final total = barsUsed * barLengthMm;
    if (total <= 0) return 0;
    return 100 * scrapMm / total;
  }

  /// Pieces demanded per order line, e.g. {"W1": 32, "W2": 22}.
  Map<String, int> get piecesPerSource {
    final counts = <String, int>{};
    for (final bar in bars) {
      for (final p in bar.pieces) {
        if (p.source.isEmpty) continue;
        counts[p.source] = (counts[p.source] ?? 0) + 1;
      }
    }
    return counts;
  }
}

/// Settings the factory worker controls from the screen / console.
class CuttingSettings {
  const CuttingSettings({
    this.barLengthMm = 5000,
    this.kerfMm = 3,
    this.timeLimitSec = 5,
    this.maxMilpPieces = 40,
    this.maxMilpBars = 12,
    this.reusableOffcutMm = 400,
  });

  final double barLengthMm;
  final double kerfMm;
  final double timeLimitSec;

  /// Above this piece count we skip MILP and use FFD directly.
  final int maxMilpPieces;

  /// Above this FFD bar count we skip MILP and use FFD directly.
  final int maxMilpBars;

  /// Leftover ≥ this length is reusable stock, not scrap.
  final double reusableOffcutMm;
}

/// First-Fit-Decreasing upper bound: sort descending, pack greedily.
/// Returns the number of bars the heuristic needs (= `maxBars` for MILP).
int ffdUpperBound(List<double> lengths, double barLength, double kerf) {
  final sorted = [...lengths]..sort((a, b) => b.compareTo(a));
  final bins = <double>[];
  for (final p in sorted) {
    var placed = false;
    for (var i = 0; i < bins.length; i++) {
      if (bins[i] + p + kerf <= barLength + 1e-9) {
        bins[i] += p + kerf;
        placed = true;
        break;
      }
    }
    if (!placed) bins.add(p + kerf);
  }
  return bins.length;
}

/// Best-Fit-Decreasing upper bound: sort descending, put each piece in
/// the fullest bar that still fits. Packs tighter than first-fit, so the
/// MILP gets a smaller `maxBars` and big batches waste less.
int bfdUpperBound(List<double> lengths, double barLength, double kerf) {
  final sorted = [...lengths]..sort((a, b) => b.compareTo(a));
  final bins = <double>[];
  for (final p in sorted) {
    var best = -1;
    var bestFree = double.infinity;
    for (var i = 0; i < bins.length; i++) {
      final free = barLength - bins[i] - p - kerf;
      if (free >= -1e-9 && free < bestFree) {
        best = i;
        bestFree = free;
      }
    }
    if (best >= 0) {
      bins[best] += p + kerf;
    } else {
      bins.add(p + kerf);
    }
  }
  return bins.length;
}

/// Best-fit-decreasing plan builder shared by the bound and the fallback.
List<List<DemandedPiece>> _bfdBins(
    List<DemandedPiece> demand, CuttingSettings s) {
  final order = [...demand]
    ..sort((a, b) => b.lengthMm.compareTo(a.lengthMm));
  final bins = <List<DemandedPiece>>[];
  final load = <double>[];
  for (final p in order) {
    var best = -1;
    var bestFree = double.infinity;
    for (var i = 0; i < bins.length; i++) {
      final free = s.barLengthMm - load[i] - p.lengthMm - s.kerfMm;
      if (free >= -1e-9 && free < bestFree) {
        best = i;
        bestFree = free;
      }
    }
    if (best >= 0) {
      bins[best].add(p);
      load[best] += p.lengthMm + s.kerfMm;
    } else {
      bins.add([p]);
      load.add(p.lengthMm + s.kerfMm);
    }
  }
  return bins;
}

CuttingPlan _planFromBins(
    List<List<DemandedPiece>> bins, CuttingSettings s) {
  // Last kerf in each bar cuts no material after it: reclaim it.
  final bars = <BarPlan>[];
  for (final pieces in bins) {
    final used = pieces.fold(0.0, (t, p) => t + p.lengthMm);
    final kerfTotal = pieces.isEmpty ? 0.0 : s.kerfMm * (pieces.length - 1);
    bars.add(
      BarPlan(
        pieces: [
          for (final p in pieces)
            CutPiece(p.label, p.lengthMm, source: p.source),
        ],
        usedMm: used,
        wasteMm: s.barLengthMm - used - kerfTotal,
        kerfTotalMm: kerfTotal,
      ),
    );
  }
  return CuttingPlan(
    bars: bars,
    barLengthMm: s.barLengthMm,
    kerfMm: s.kerfMm,
    isOptimal: false,
    solveTimeUs: 0,
    reusableThresholdMm: s.reusableOffcutMm,
  );
}

/// Pure-heuristic plan (also the MILP fallback). Deterministic.
CuttingPlan buildFFDPlan(List<DemandedPiece> demand, CuttingSettings s) =>
    _planFromBins(_ffdBins(demand, s), s);

/// Tighter heuristic: best-fit fills each bar with the most pieces that
/// leave the least leftover. Used for factory-size batches.
CuttingPlan buildBFDPlan(List<DemandedPiece> demand, CuttingSettings s) =>
    _planFromBins(_bfdBins(demand, s), s);

List<List<DemandedPiece>> _ffdBins(
    List<DemandedPiece> demand, CuttingSettings s) {
  final order = [...demand]
    ..sort((a, b) => b.lengthMm.compareTo(a.lengthMm));
  final bins = <List<DemandedPiece>>[];
  final load = <double>[];
  for (final p in order) {
    var placed = false;
    for (var i = 0; i < bins.length; i++) {
      if (load[i] + p.lengthMm + s.kerfMm <= s.barLengthMm + 1e-9) {
        bins[i].add(p);
        load[i] += p.lengthMm + s.kerfMm;
        placed = true;
        break;
      }
    }
    if (!placed) {
      bins.add([p]);
      load.add(p.lengthMm + s.kerfMm);
    }
  }
  return bins;
}

/// Validates that no single piece exceeds the bar.
void validateDemand(List<DemandedPiece> demand, CuttingSettings s) {
  for (final p in demand) {
    if (p.lengthMm > s.barLengthMm) {
      throw ArgumentError(
        '"${p.label}" ${p.lengthMm}mm does not fit in a ${s.barLengthMm}mm bar.',
      );
    }
    if (p.lengthMm <= 0) {
      throw ArgumentError('Piece lengths must be positive.');
    }
  }
  if (demand.isEmpty) throw ArgumentError('Order is empty: add a window or a piece.');
}

/// Exact solve with HiGHS, falling back to BFD on timeout / large orders.
///
/// Small orders (one window) prove optimality; factory-size multi-order
/// batches use best-fit-decreasing, which fills every bar with the most
/// pieces that leave the least leftover.
Future<CuttingPlan> solveCuttingStock(
  List<DemandedPiece> demand,
  CuttingSettings settings,
) async {
  validateDemand(demand, settings);
  final s = settings;
  final n = demand.length;
  final maxBars = bfdUpperBound(
    [for (final d in demand) d.lengthMm],
    s.barLengthMm,
    s.kerfMm,
  );

  // Large orders: heuristic only (assignment MILP would explode).
  if (n > s.maxMilpPieces || maxBars > s.maxMilpBars) {
    print(
      'CuttingStock: $n pieces / $maxBars bars — above MILP budget, using BFD.',
    );
    return buildBFDPlan(demand, s);
  }

  final model = MathOptModel(name: 'UPVC_Cutting_Stock');
  final y = [for (var j = 0; j < maxBars; j++) model.binary('use_bar_$j')];
  final x = [
    for (var i = 0; i < n; i++)
      [for (var j = 0; j < maxBars; j++) model.binary('x_${i}_$j')],
  ];

  ExpressionNode total = const ConstantNode(0);
  for (final v in y) {
    total += v.asExpr;
  }
  model.minimize(total);

  // 1. Each piece placed exactly once.
  for (var i = 0; i < n; i++) {
    ExpressionNode row = const ConstantNode(0);
    for (var j = 0; j < maxBars; j++) {
      row += x[i][j].asExpr;
    }
    model.add(row.eq(1));
  }

  // 2. Bar capacity: Σ (len+kerf)·x − barLen·y ≤ 0.
  for (var j = 0; j < maxBars; j++) {
    ExpressionNode cap = const ConstantNode(0);
    for (var i = 0; i < n; i++) {
      cap += x[i][j].asExpr * (demand[i].lengthMm + s.kerfMm);
    }
    cap -= y[j].asExpr * s.barLengthMm;
    // Reclaim trailing kerf: a used bar holds k pieces but only k−1 cuts.
    // Linear relaxation-safe trick: allow one kerf back when bar is used:
    // cap − kerf·y ≤ −kerf  ⟺  Σ(len+kerf)x − bar·y − kerf·y ≤ −kerf
    // Simpler exact form: keep constraint as-is (slightly conservative),
    // the parser below recomputes true waste with k−1 kerfs.
    model.add((cap <= 0).named('capacity_$j'));
  }

  // 3. Linking: x[i][j] − y[j] ≤ 0.
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < maxBars; j++) {
      model.add((x[i][j].asExpr - y[j].asExpr <= 0).named('link_${i}_$j'));
    }
  }

  // 4. Symmetry breaking: y[j] − y[j+1] ≥ 0.
  for (var j = 0; j < maxBars - 1; j++) {
    model.add((y[j].asExpr - y[j + 1].asExpr >= 0).named('sym_$j'));
  }

  try {
    final result = await model.solve(
      options: SolveOptions(
        solver: SolverPreference.highs,
        timeLimitSec: s.timeLimitSec,
      ),
    );
    if (!result.hasSolution) {
      print('CuttingStock: MILP has no solution (${result.status.name}), BFD fallback.');
      return buildBFDPlan(demand, s);
    }
    final bars = <BarPlan>[];
    for (var j = 0; j < maxBars; j++) {
      if (result.valueOf(y[j]) < 0.5) continue;
      final inBar = <CutPiece>[];
      for (var i = 0; i < n; i++) {
        if (result.valueOf(x[i][j]) > 0.5) {
          inBar.add(CutPiece(demand[i].label, demand[i].lengthMm,
              source: demand[i].source));
        }
      }
      if (inBar.isEmpty) continue;
      inBar.sort((a, b) => b.lengthMm.compareTo(a.lengthMm));
      final used = inBar.fold(0.0, (t, p) => t + p.lengthMm);
      final kerfTotal = s.kerfMm * (inBar.length - 1);
      bars.add(
        BarPlan(
          pieces: inBar,
          usedMm: used,
          wasteMm: s.barLengthMm - used - kerfTotal,
          kerfTotalMm: kerfTotal,
        ),
      );
    }
    return CuttingPlan(
      bars: bars,
      barLengthMm: s.barLengthMm,
      kerfMm: s.kerfMm,
      isOptimal: result.isOptimal,
      solveTimeUs: result.statistics.solveTimeUs,
      reusableThresholdMm: s.reusableOffcutMm,
    );
  } on SolverTimeoutException {
    print('CuttingStock: time limit hit, BFD fallback.');
    return buildBFDPlan(demand, s);
  }
}

/// Tries every stocked bar length and keeps the cheapest plan.
///
/// Comparison key: fewest bars first, then least true scrap. This is how a
/// factory gets under 1%: the right stock length for the order mix matters
/// more than squeezing one more millimeter out of a fixed 5000mm bar.
Future<({CuttingPlan plan, double barLengthMm})> solveBestLength(
  List<DemandedPiece> demand,
  CuttingSettings settings,
  List<double> lengths,
) async {
  CuttingPlan? best;
  var bestLen = lengths.first;
  for (final len in lengths) {
    final plan = await solveCuttingStock(
      demand,
      CuttingSettings(
        barLengthMm: len,
        kerfMm: settings.kerfMm,
        timeLimitSec: settings.timeLimitSec,
        maxMilpPieces: settings.maxMilpPieces,
        maxMilpBars: settings.maxMilpBars,
        reusableOffcutMm: settings.reusableOffcutMm,
      ),
    );
    if (best == null ||
        plan.barsUsed < best.barsUsed ||
        (plan.barsUsed == best.barsUsed && plan.scrapMm < best.scrapMm)) {
      best = plan;
      bestLen = len;
    }
  }
  return (plan: best!, barLengthMm: bestLen);
}
/// Factory-batch console demo (`dart run example/example.dart cutting`).
///
/// One mixed batch — 2 sliding + 1 tilt windows — solved against every
/// stocked bar length; the cheapest stock wins. Pieces carry their order
/// line (W1/W2/W3) so each bar says which windows it serves.
Future<void> runCuttingStockDemo() async {
  const profile = UPVCProfile(
    name: 'Bowin',
    nameAr: 'بولوين',
    frameDeduction: 90,
    sashDeduction: 42,
    beadDeduction: 30,
    screenDeduction: 40,
    weldingAllowance: 6,
  );
  const orders = [
    WindowOrder(
        type: WindowType.sliding, widthMm: 1500, heightMm: 1500, qty: 2),
    WindowOrder(type: WindowType.tilt, widthMm: 1200, heightMm: 1400, qty: 1),
  ];
  final demand = <DemandedPiece>[
    for (var w = 0; w < orders.length; w++)
      for (final p in WindowGenerator.generate(orders[w], profile))
        DemandedPiece(p.label, p.lengthMm, source: 'W${w + 1}'),
  ];
  const settings = CuttingSettings(timeLimitSec: 8);
  print(
    'UPVC batch demo: 2x sliding 1500x1500 (W1) + 1x tilt 1200x1400 (W2) '
    '(${demand.length} pieces, kerf ${settings.kerfMm}mm)',
  );
  final best =
      await solveBestLength(demand, settings, [5000, 5800, 6000]);
  final plan = best.plan;
  print(
    'Best stock: ${best.barLengthMm.toStringAsFixed(0)}mm bar × ${plan.barsUsed} '
    '(${plan.isOptimal ? 'OPTIMAL' : 'heuristic'}) • '
    'true scrap ${plan.scrapPct.toStringAsFixed(2)}% '
    '(${plan.scrapMm.toStringAsFixed(0)}mm) • '
    'reusable ${plan.reusableMm.toStringAsFixed(0)}mm • '
    'windows: ${plan.piecesPerSource}',
  );
  for (var b = 0; b < plan.bars.length; b++) {
    final bar = plan.bars[b];
    print(
      ' Bar ${b + 1} [${bar.sources.join(',')}]: '
      '${bar.pieces.map((p) => p.lengthMm.toStringAsFixed(0)).join(' + ')} '
      '| leftover ${bar.wasteMm.toStringAsFixed(0)}mm',
    );
  }
  print('');
}
