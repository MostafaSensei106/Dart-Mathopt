import 'package:dart_mathopt/dart_mathopt.dart';
import 'package:dart_mathopt_example/data/upvc_catalog.dart';
import 'package:dart_mathopt_example/problems/cutting_stock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cutting-stock solver tests (native HiGHS, small orders stay exact).
void main() {
  setUpAll(() async => DartMathOpt.init());
  tearDownAll(() async => DartMathOpt.dispose());

  test('FFD upper bound matches known packing', () {
    expect(ffdUpperBound([4000, 4000, 1000], 5000, 3), 3);
    expect(ffdUpperBound([2000, 2000, 2000], 5000, 0), 2);
  });

  test('sliding window generator emits 32 pieces per window', () {
    const profile = UPVCProfile(
      name: 't',
      nameAr: 'ت',
      frameDeduction: 0,
      sashDeduction: 40,
      beadDeduction: 30,
      screenDeduction: 40,
      weldingAllowance: 6,
    );
    const order = WindowOrder(
      type: WindowType.sliding,
      widthMm: 1500,
      heightMm: 1500,
      qty: 1,
    );
    final pieces = WindowGenerator.generate(order, profile);
    expect(pieces.length, 32);
    expect(pieces.where((p) => p.label.startsWith('Frame')).length, 4);
    expect(pieces.any((p) => p.label.startsWith('Bead')), isTrue);
    expect(pieces.any((p) => p.label.startsWith('Screen')), isTrue);
  });

  test('every window type generates a positive cut list', () {
    const profile = UPVCProfile(
      name: 't',
      nameAr: 'ت',
      frameDeduction: 0,
      sashDeduction: 40,
      beadDeduction: 30,
      screenDeduction: 40,
      weldingAllowance: 6,
    );
    for (final type in WindowType.values) {
      final pieces = WindowGenerator.generate(
        WindowOrder(
            type: type, widthMm: 1500, heightMm: 1500, qty: 1),
        profile,
      );
      expect(pieces, isNotEmpty, reason: type.name);
      expect(
        pieces.every((p) => p.lengthMm > 0),
        isTrue,
        reason: type.name,
      );
    }
  });

  test('MILP uses no more bars than FFD and covers every piece',
      () async {
    final demand = [
      const DemandedPiece('a', 2100),
      const DemandedPiece('b', 1500),
      const DemandedPiece('c', 1200),
      const DemandedPiece('d', 850),
      const DemandedPiece('e', 900),
    ];
    const settings = CuttingSettings();
    final ffdBars = ffdUpperBound(
      [for (final d in demand) d.lengthMm],
      settings.barLengthMm,
      settings.kerfMm,
    );
    final plan = await solveCuttingStock(demand, settings);
    expect(plan.barsUsed, lessThanOrEqualTo(ffdBars));
    final placed = plan.bars.fold<double>(0, (s, b) => s + b.usedMm);
    final wanted = demand.fold<double>(0, (s, d) => s + d.lengthMm);
    expect(placed, moreOrLessEquals(wanted, epsilon: 1e-6));
    for (final bar in plan.bars) {
      expect(bar.wasteMm, greaterThanOrEqualTo(-1e-6));
      expect(
        bar.usedMm + bar.kerfTotalMm + bar.wasteMm,
        moreOrLessEquals(settings.barLengthMm, epsilon: 1e-6),
      );
    }
  });

  test('BFD bound never exceeds FFD bound', () {
    final runs = <List<double>>[
      [4000.0, 4000, 1000],
      [2000.0, 2000, 2000],
      [2100.0, 1500, 1200, 850, 900, 1400, 700, 1100],
    ];
    for (final lengths in runs) {
      expect(
        bfdUpperBound(lengths, 5000, 3),
        lessThanOrEqualTo(ffdUpperBound(lengths, 5000, 3)),
      );
    }
  });

  test('BFD batch plan keeps order sources per bar', () {
    final demand = [
      const DemandedPiece('frame', 1500, source: 'W1'),
      const DemandedPiece('sash', 1400, source: 'W1'),
      const DemandedPiece('frame', 1200, source: 'W2'),
      const DemandedPiece('bead', 900, source: 'W2'),
    ];
    const settings = CuttingSettings();
    final plan = buildBFDPlan(demand, settings);
    expect(plan.piecesPerSource, {'W1': 2, 'W2': 2});
    for (final bar in plan.bars) {
      expect(bar.sources.every((s) => s == 'W1' || s == 'W2'), isTrue);
    }
  });

  test('factory batch lands true scrap under 1%', () async {
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
    final demand = [
      for (var w = 0; w < orders.length; w++)
        for (final p in WindowGenerator.generate(orders[w], profile))
          DemandedPiece(p.label, p.lengthMm, source: 'W${w + 1}'),
    ];
    const settings = CuttingSettings(timeLimitSec: 8);
    final best =
        await solveBestLength(demand, settings, [5000, 5800, 6000]);
    expect(best.barLengthMm, 5800);
    expect(best.plan.scrapPct, lessThan(1.0));
    expect(best.plan.piecesPerSource['W1'], 64);
    expect(best.plan.piecesPerSource['W2'], 22);
  });

  test('oversize piece is rejected with a clear error', () async {
    const settings = CuttingSettings();
    expect(
      () => solveCuttingStock(
        [const DemandedPiece('too long', 6000)],
        settings,
      ),
      throwsArgumentError,
    );
  });
}
