/// UPVC Cutting Stock MVP screen — the factory-owner page.
///
/// Separate section from the 12 academic demos: a real order form.
/// Data entry lives in modal bottom sheets (window presets / custom
/// pieces / profile editor); this page owns the order state and the
/// cutting plan output with per-bar visualization.
library;

import 'package:flutter/material.dart';

import '../data/upvc_catalog.dart';
import '../problems/cutting_stock.dart';
import '../solve_time.dart';

class CuttingStockScreen extends StatefulWidget {
  const CuttingStockScreen({super.key});

  @override
  State<CuttingStockScreen> createState() => _CuttingStockScreenState();
}

class _CuttingStockScreenState extends State<CuttingStockScreen> {
  UPVCProfile _profile = availableProfiles.first;
  double _barLength = 5800;
  double _kerf = 3;
  double _timeLimit = 8;
  bool _withBeads = true;
  bool _withScreen = true;
  bool _autoLength = true;
  double _reuseMin = 400;

  final List<WindowOrder> _windows = [
    const WindowOrder(
      type: WindowType.sliding,
      widthMm: 1500,
      heightMm: 1500,
      qty: 1,
    ),
  ];
  final List<_CustomRow> _custom = [
    _CustomRow(label: 'Extra frame', lengthMm: 900, qty: 2),
  ];

  bool _solving = false;
  CuttingPlan? _plan;
  String? _error;
  String? _stats;

  List<DemandedPiece> get _demand {
    final out = <DemandedPiece>[];
    for (var w = 0; w < _windows.length; w++) {
      for (final p in WindowGenerator.generate(
        _windows[w],
        _profile,
        beads: _withBeads,
        screen: _withScreen,
      )) {
        out.add(DemandedPiece(p.label, p.lengthMm, source: 'W${w + 1}'));
      }
    }
    for (var c = 0; c < _custom.length; c++) {
      for (var i = 0; i < _custom[c].qty; i++) {
        out.add(DemandedPiece(_custom[c].label, _custom[c].lengthMm,
            source: 'C${c + 1}'));
      }
    }
    return out;
  }

  Future<void> _solve() async {
    setState(() {
      _solving = true;
      _error = null;
      _plan = null;
      _stats = null;
    });
    try {
      final demand = _demand;
      final settings = CuttingSettings(
        barLengthMm: _barLength,
        kerfMm: _kerf,
        timeLimitSec: _timeLimit,
        reusableOffcutMm: _reuseMin,
      );
      final sw = Stopwatch()..start();
      final CuttingPlan plan;
      if (_autoLength) {
        final best = await solveBestLength(demand, settings, [5000, 5800, 6000]);
        plan = best.plan;
        if (mounted) setState(() => _barLength = best.barLengthMm);
      } else {
        plan = await solveCuttingStock(demand, settings);
      }
      sw.stop();
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _stats =
            '${demand.length} pieces • ${plan.barsUsed} × ${plan.barLengthMm.toStringAsFixed(0)}mm bars • '
            '${plan.isOptimal ? 'OPTIMAL' : 'heuristic'} • '
            'scrap ${plan.scrapPct.toStringAsFixed(2)}% • '
            'wall ${formatMicroseconds(sw.elapsedMicroseconds)} • '
            'engine ${formatMicroseconds(plan.solveTimeUs)}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _solving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demand = _demand;
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPVC Cutting Stock (MVP)'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              title: '1. Sector profile (قطاع)',
              child: Column(
                children: [
                  DropdownButtonFormField<UPVCProfile>(
                    initialValue: _profile,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Profile / القطاع',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in availableProfiles)
                        DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} — ${p.nameAr}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _profile = v ?? _profile),
                  ),
                  const SizedBox(height: 8),
                  // 2×2 grid: 4 narrow fields never fit one phone row.
                  Row(
                    children: [
                      Expanded(
                        child: _NumField(
                          label: 'Sash ded.',
                          value: _profile.sashDeduction,
                          onChanged: (v) => setState(
                            () => _profile = _profile.copyWith(
                              sashDeduction: v,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NumField(
                          label: 'Bead ded.',
                          value: _profile.beadDeduction,
                          onChanged: (v) => setState(
                            () => _profile = _profile.copyWith(
                              beadDeduction: v,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _NumField(
                          label: 'Screen ded.',
                          value: _profile.screenDeduction,
                          onChanged: (v) => setState(
                            () => _profile = _profile.copyWith(
                              screenDeduction: v,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NumField(
                          label: 'Weld allow.',
                          value: _profile.weldingAllowance,
                          onChanged: (v) => setState(
                            () => _profile = _profile.copyWith(
                              weldingAllowance: v,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _NumField(
                          label: 'Bar (mm)',
                          value: _barLength,
                          onChanged: (v) =>
                              setState(() => _barLength = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NumField(
                          label: 'Kerf (mm)',
                          value: _kerf,
                          onChanged: (v) => setState(() => _kerf = v),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Glass beads (باكيت)',
                        style: TextStyle(fontSize: 14)),
                    value: _withBeads,
                    onChanged: (v) =>
                        setState(() => _withBeads = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fly screen (سلك)',
                        style: TextStyle(fontSize: 14)),
                    value: _withScreen,
                    onChanged: (v) =>
                        setState(() => _withScreen = v),
                  ),
                ],
              ),
            ),
            _Section(
              title: '2. Windows (${_windows.length} lines)',
              actionLabel: 'Add window',
              onAction: _openWindowSheet,
              child: _windows.isEmpty
                  ? const Text('No windows yet — add one.',
                      style: TextStyle(color: Colors.black54))
                  : Column(
                      children: [
                        for (var i = 0; i < _windows.length; i++)
                          _OrderTile(
                            tag: 'W${i + 1}',
                            title:
                                '${_windows[i].type.labelEn} ${_windows[i].widthMm.toStringAsFixed(0)}×${_windows[i].heightMm.toStringAsFixed(0)} ×${_windows[i].qty}',
                            subtitle:
                                '${WindowGenerator.generate(_windows[i], _profile, beads: _withBeads, screen: _withScreen).length} pieces',
                            onDelete: () =>
                                setState(() => _windows.removeAt(i)),
                          ),
                      ],
                    ),
            ),
            _Section(
              title: '3. Custom pieces (${_custom.length} lines)',
              actionLabel: 'Add piece',
              onAction: _openPieceSheet,
              child: _custom.isEmpty
                  ? const Text('No custom pieces.',
                      style: TextStyle(color: Colors.black54))
                  : Column(
                      children: [
                        for (var i = 0; i < _custom.length; i++)
                          _OrderTile(
                            tag: 'C${i + 1}',
                            title:
                                '${_custom[i].label} ${_custom[i].lengthMm.toStringAsFixed(0)}mm ×${_custom[i].qty}',
                            subtitle: 'custom',
                            onDelete: () =>
                                setState(() => _custom.removeAt(i)),
                          ),
                      ],
                    ),
            ),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Batch total: ${demand.length} pieces',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: _NumField(
                            label: 'Time (s)',
                            value: _timeLimit,
                            onChanged: (v) =>
                                setState(() => _timeLimit = v),
                          ),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Auto stock: try 5000 / 5800 / 6000, keep cheapest',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _autoLength,
                      onChanged: (v) =>
                          setState(() => _autoLength = v ?? true),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _NumField(
                            label: 'Bar (mm)',
                            value: _barLength,
                            onChanged: (v) =>
                                setState(() => _barLength = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NumField(
                            label: 'Reusable ≥ (mm)',
                            value: _reuseMin,
                            onChanged: (v) =>
                                setState(() => _reuseMin = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              key: const ValueKey('cutting_solve_button'),
              onPressed: _solving ? null : _solve,
              icon: _solving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.content_cut),
              label: Text(
                _solving
                    ? 'Optimizing…'
                    : 'Compute cutting plan (${demand.length} pcs)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!),
                ),
              ),
            ],
            if (_plan != null) ...[
              const SizedBox(height: 12),
              _ResultHeader(plan: _plan!, stats: _stats),
              const SizedBox(height: 8),
              for (var b = 0; b < _plan!.bars.length; b++)
                _BarCard(
                  index: b,
                  bar: _plan!.bars[b],
                  barLength: _plan!.barLengthMm,
                  kerf: _plan!.kerfMm,
                  reusableAt: _plan!.reusableThresholdMm,
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _openWindowSheet() async {
    var type = WindowType.sliding;
    var w = 1500.0;
    var h = 1500.0;
    var qty = 1;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add window / إضافة شباك',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<WindowType>(
                initialValue: type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Type / النوع',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final t in WindowType.values)
                    DropdownMenuItem(
                      value: t,
                      child: Text(
                        '${t.labelEn} — ${t.labelAr}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setSheet(() => type = v ?? type),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _NumField(
                      label: 'Width (mm)',
                      value: w,
                      onChanged: (v) => setSheet(() => w = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumField(
                      label: 'Height (mm)',
                      value: h,
                      onChanged: (v) => setSheet(() => h = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumField(
                      label: 'Qty',
                      value: qty.toDouble(),
                      onChanged: (v) =>
                          setSheet(() => qty = v.round().clamp(1, 999)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _windows.add(
                        WindowOrder(
                          type: type,
                          widthMm: w,
                          heightMm: h,
                          qty: qty,
                        ),
                      ));
                  Navigator.of(ctx).pop();
                },
                child: const Text('Add to order'),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPieceSheet() async {
    var label = 'Custom';
    var len = 1000.0;
    var qty = 1;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add custom piece / قطعة حرة',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: label,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => label = v.isEmpty ? 'Custom' : v,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _NumField(
                      label: 'Length (mm)',
                      value: len,
                      onChanged: (v) => setSheet(() => len = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumField(
                      label: 'Qty',
                      value: qty.toDouble(),
                      onChanged: (v) =>
                          setSheet(() => qty = v.round().clamp(1, 999)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _custom.add(
                        _CustomRow(
                          label: label,
                          lengthMm: len,
                          qty: qty,
                        ),
                      ));
                  Navigator.of(ctx).pop();
                },
                child: const Text('Add to order'),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomRow {
  _CustomRow({
    required this.label,
    required this.lengthMm,
    required this.qty,
  });
  String label;
  double lengthMm;
  int qty;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (actionLabel != null)
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(actionLabel!),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.onDelete,
  });
  final String tag;
  final String title;
  final String subtitle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        child: Text(tag, style: const TextStyle(fontSize: 12)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: onDelete,
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (t) {
        final v = double.tryParse(t);
        if (v != null && v > 0) onChanged(v);
      },
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.plan, required this.stats});
  final CuttingPlan plan;
  final String? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('solve_output'),
      color: Colors.green.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.isOptimal ? 'Optimal plan' : 'Heuristic plan',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: plan.isOptimal
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.isOptimal ? 'OPTIMAL' : 'HEURISTIC',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bars: ${plan.barsUsed} × ${plan.barLengthMm.toStringAsFixed(0)}mm • '
              'True scrap: ${plan.scrapPct.toStringAsFixed(2)}% '
              '(${plan.scrapMm.toStringAsFixed(0)}mm)',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reusable offcuts: ${plan.reusableMm.toStringAsFixed(0)}mm • '
              'Kerf: ${plan.kerfMm}mm • '
              '${plan.piecesPerSource.entries.map((e) => '${e.key}:${e.value}pcs').join(' ')}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            if (stats != null) ...[
              const SizedBox(height: 4),
              Text(stats!,
                  key: const ValueKey('solve_stats'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}

/// One bar rendered proportionally: blue pieces + red kerf ticks + grey scrap.
class _BarCard extends StatelessWidget {
  const _BarCard({
    required this.index,
    required this.bar,
    required this.barLength,
    required this.kerf,
    required this.reusableAt,
  });
  final int index;
  final BarPlan bar;
  final double barLength;
  final double kerf;
  final double reusableAt;

  static const _palette = [
    Colors.blue,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
    Colors.lightBlue,
  ];

  @override
  Widget build(BuildContext context) {
    final reusable = bar.wasteMm >= reusableAt;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bar ${index + 1} — leftover ${bar.wasteMm.toStringAsFixed(0)}mm',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            // Wraps on narrow phones instead of overflowing the title row.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in bar.sources)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (reusable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '♻ stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final total = constraints.maxWidth;
                double frac(double mm) =>
                    (mm / barLength * total).clamp(2.0, total);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 34,
                    child: Row(
                      children: [
                        for (var i = 0; i < bar.pieces.length; i++) ...[
                          Builder(
                            builder: (_) {
                              final wPx = frac(bar.pieces[i].lengthMm);
                              return Container(
                                width: wPx,
                                color: _palette[i % _palette.length]
                                    .shade500,
                                alignment: Alignment.center,
                                // Tiny slivers stay color-only so the
                                // label never squeezes on phones.
                                child: wPx >= 40
                                    ? Text(
                                        bar.pieces[i].lengthMm
                                            .toStringAsFixed(0),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.clip,
                                      )
                                    : null,
                              );
                            },
                          ),
                          if (i < bar.pieces.length - 1)
                            Container(
                              width: frac(kerf).clamp(2.0, 8.0),
                              color: Colors.red.shade700,
                            ),
                        ],
                        Expanded(
                          child: Container(
                            color: reusable
                                ? Colors.green.shade100
                                : Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: bar.wasteMm > 1
                                ? Text(
                                    reusable
                                        ? '${bar.wasteMm.toStringAsFixed(0)} reusable'
                                        : '${bar.wasteMm.toStringAsFixed(0)} scrap',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: reusable
                                          ? Colors.green.shade800
                                          : Colors.grey.shade700,
                                    ),
                                    overflow: TextOverflow.clip,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              bar.pieces
                  .map((p) =>
                      '${p.lengthMm.toStringAsFixed(0)}${p.source.isEmpty ? '' : '[${p.source}]'} (${p.label})')
                  .join(' + '),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
