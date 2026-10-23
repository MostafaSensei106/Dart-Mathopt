/// Sector catalog + window cut-list generators (data-driven).
///
/// No hard-coded sector math: every formula reads its deductions from a
/// [UPVCProfile] the user picks (and edits) in the UI. Sectors are plain
/// data and can be serialized to JSON later without touching the generator.
///
/// A standard double window expands to ~32 cut pieces (frame + sashes +
/// glass beads + fly screen + sill + meeting rails) so the 1D cutting
/// optimizer has a real factory order to chew on instead of a toy list.
library;

/// A single demanded cut: a label for the worker + length in millimeters.
class CutPiece {
  const CutPiece(this.label, this.lengthMm, {this.source = ''});

  /// e.g. "Frame Top", "Sash Side", "Bead Sash", "Screen Rail".
  final String label;

  /// Cutting length in mm (welding allowance already included).
  final double lengthMm;

  /// Order line that demanded it ("W1", "C2", …). Empty when untracked.
  final String source;
}

/// Deduction rule-set for one sector/brand.
///
/// All values in millimeters. The generator adds [weldingAllowance] to
/// every structural cut (0 for screw-joint aluminum) and subtracts the
/// sash/bead/screen deductions when deriving inner parts from the outer
/// opening size.
class UPVCProfile {
  const UPVCProfile({
    required this.name,
    required this.nameAr,
    required this.frameDeduction,
    required this.sashDeduction,
    required this.beadDeduction,
    required this.screenDeduction,
    required this.weldingAllowance,
  });

  /// e.g. "Bowin".
  final String name;

  /// Arabic display name, e.g. "بولوين".
  final String nameAr;

  /// Reserved for frame overlap corrections (informational for now).
  final double frameDeduction;

  /// Subtracted from the opening to get sash sizes.
  final double sashDeduction;

  /// Subtracted to get glass-bead (باكيت الزجاج) sizes.
  final double beadDeduction;

  /// Subtracted to get fly-screen (سلك) frame sizes.
  final double screenDeduction;

  /// Added to every cut (UPVC weld clearance ~6mm, aluminum screws = 0).
  final double weldingAllowance;

  UPVCProfile copyWith({
    String? name,
    String? nameAr,
    double? frameDeduction,
    double? sashDeduction,
    double? beadDeduction,
    double? screenDeduction,
    double? weldingAllowance,
  }) =>
      UPVCProfile(
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        frameDeduction: frameDeduction ?? this.frameDeduction,
        sashDeduction: sashDeduction ?? this.sashDeduction,
        beadDeduction: beadDeduction ?? this.beadDeduction,
        screenDeduction: screenDeduction ?? this.screenDeduction,
        weldingAllowance: weldingAllowance ?? this.weldingAllowance,
      );

  Map<String, Object?> toJson() => {
        'name': name,
        'nameAr': nameAr,
        'frameDeduction': frameDeduction,
        'sashDeduction': sashDeduction,
        'beadDeduction': beadDeduction,
        'screenDeduction': screenDeduction,
        'weldingAllowance': weldingAllowance,
      };

  static UPVCProfile fromJson(Map<String, Object?> json) => UPVCProfile(
        name: json['name']! as String,
        nameAr: (json['nameAr'] ?? '') as String,
        frameDeduction: (json['frameDeduction']! as num).toDouble(),
        sashDeduction: (json['sashDeduction']! as num).toDouble(),
        beadDeduction: (json['beadDeduction'] as num?)?.toDouble() ?? 30,
        screenDeduction: (json['screenDeduction'] as num?)?.toDouble() ?? 40,
        weldingAllowance: (json['weldingAllowance']! as num).toDouble(),
      );
}

/// Ready-made sectors. "Generic Custom" is fully editable.
const availableProfiles = [
  UPVCProfile(
    name: 'Bowin',
    nameAr: 'بولوين',
    frameDeduction: 90,
    sashDeduction: 42,
    beadDeduction: 30,
    screenDeduction: 40,
    weldingAllowance: 6,
  ),
  UPVCProfile(
    name: 'Kimet',
    nameAr: 'كيمت',
    frameDeduction: 84,
    sashDeduction: 40,
    beadDeduction: 30,
    screenDeduction: 40,
    weldingAllowance: 6,
  ),
  UPVCProfile(
    name: 'Regular Aluminum',
    nameAr: 'ألومنيوم عادي',
    frameDeduction: 70,
    sashDeduction: 50,
    beadDeduction: 20,
    screenDeduction: 30,
    weldingAllowance: 0,
  ),
  UPVCProfile(
    name: 'Generic Custom',
    nameAr: 'قطاع مخصص',
    frameDeduction: 0,
    sashDeduction: 0,
    beadDeduction: 0,
    screenDeduction: 0,
    weldingAllowance: 6,
  ),
];

/// Window families the factory produces, including combos where one leaf
/// slides and the other leaf tilts (or opens casement-style).
enum WindowType {
  sliding('Sliding', 'جرار'),
  tilt('Tilt', 'قلاب'),
  casement('Casement', 'مفصلي'),
  fixed('Fixed', 'ثابت'),
  comboSlidingTilt('Sliding + Tilt combo', 'كومبو جرار + قلاب'),
  comboSlidingCasement('Sliding + Casement combo', 'كومبو جرار + مفصلي');

  const WindowType(this.labelEn, this.labelAr);
  final String labelEn;
  final String labelAr;
}

/// One line in the factory order: N identical windows of one family.
class WindowOrder {
  const WindowOrder({
    required this.type,
    required this.widthMm,
    required this.heightMm,
    required this.qty,
  });

  final WindowType type;
  final double widthMm;
  final double heightMm;
  final int qty;
}

/// Full cut-list generator (~32 pieces for a standard double window:
/// frame + sash frames + glass beads + screen + sill + meeting rails).
///
/// Set [beads]/[screen] to false when those parts are cut from separate
/// stock in the workshop and must not join this bar optimization.
class WindowGenerator {
  static List<CutPiece> generate(
    WindowOrder order,
    UPVCProfile profile, {
    bool beads = true,
    bool screen = true,
  }) {
    final out = <CutPiece>[];
    for (var k = 0; k < order.qty; k++) {
      switch (order.type) {
        case WindowType.sliding:
          _slidingDouble(out, order, profile,
              beads: beads, screen: screen);
        case WindowType.tilt:
          _tiltSingle(out, order, profile,
              beads: beads, screen: screen);
        case WindowType.casement:
          _casementDouble(out, order, profile,
              beads: beads, screen: screen);
        case WindowType.fixed:
          _fixed(out, order, profile, beads: beads);
        case WindowType.comboSlidingTilt:
          _combo(out, order, profile, secondLeafTilt: true,
              beads: beads, screen: screen);
        case WindowType.comboSlidingCasement:
          _combo(out, order, profile, secondLeafTilt: false,
              beads: beads, screen: screen);
      }
    }
    return out;
  }

  static void _add(List<CutPiece> out, String label, double len) {
    if (len > 0) out.add(CutPiece(label, len));
  }

  static void _frame(
      List<CutPiece> out, double wMm, double hMm, double weld) {
    _add(out, 'Frame Top/Bot', wMm + weld);
    _add(out, 'Frame Top/Bot', wMm + weld);
    _add(out, 'Frame Side', hMm + weld);
    _add(out, 'Frame Side', hMm + weld);
  }

  static void _sash(
      List<CutPiece> out, double sashW, double sashH, String prefix) {
    _add(out, '$prefix Rail', sashW);
    _add(out, '$prefix Rail', sashW);
    _add(out, '$prefix Stile', sashH);
    _add(out, '$prefix Stile', sashH);
  }

  static void _beadsFor(
      List<CutPiece> out, double boxW, double boxH, double ded, String tag) {
    _add(out, 'Bead $tag', boxW - ded);
    _add(out, 'Bead $tag', boxW - ded);
    _add(out, 'Bead $tag', boxH - ded);
    _add(out, 'Bead $tag', boxH - ded);
  }

  static void _screenFor(List<CutPiece> out, double scrW, double scrH) {
    _add(out, 'Screen Rail', scrW);
    _add(out, 'Screen Rail', scrW);
    _add(out, 'Screen Stile', scrH);
    _add(out, 'Screen Stile', scrH);
  }

  /// Sliding double: 4 frame + 8 sash + 12 beads + 4 screen + 2 sill +
  /// 2 meeting rails = 32 pieces.
  static void _slidingDouble(List<CutPiece> out, WindowOrder order,
      UPVCProfile profile,
      {required bool beads, required bool screen}) {
    final w = profile.weldingAllowance;
    _frame(out, order.widthMm, order.heightMm, w);
    final sashW = order.widthMm / 2 - profile.sashDeduction + w;
    final sashH = order.heightMm - profile.sashDeduction + w;
    _sash(out, sashW, sashH, 'Sash');
    _sash(out, sashW, sashH, 'Sash');
    if (beads) {
      _beadsFor(out, order.widthMm + w, order.heightMm + w,
          profile.beadDeduction, 'Frame');
      _beadsFor(out, sashW, sashH, profile.beadDeduction, 'Sash');
      _beadsFor(out, sashW, sashH, profile.beadDeduction, 'Sash');
    }
    if (screen) {
      _screenFor(out, order.widthMm / 2 - profile.screenDeduction + w,
          order.heightMm - profile.screenDeduction + w);
    }
    _add(out, 'Sill/Track', order.widthMm + w);
    _add(out, 'Sill/Track', order.widthMm + w);
    _add(out, 'Meeting Rail', sashH);
    _add(out, 'Meeting Rail', sashH);
  }

  /// Tilt single sash: 4 frame + 4 sash + 8 beads + 4 screen + 2 sill = 22.
  static void _tiltSingle(List<CutPiece> out, WindowOrder order,
      UPVCProfile profile,
      {required bool beads, required bool screen}) {
    final w = profile.weldingAllowance;
    _frame(out, order.widthMm, order.heightMm, w);
    final sashW = order.widthMm - profile.sashDeduction + w;
    final sashH = order.heightMm - profile.sashDeduction + w;
    _sash(out, sashW, sashH, 'Sash');
    if (beads) {
      _beadsFor(out, order.widthMm + w, order.heightMm + w,
          profile.beadDeduction, 'Frame');
      _beadsFor(out, sashW, sashH, profile.beadDeduction, 'Sash');
    }
    if (screen) {
      _screenFor(out, order.widthMm - profile.screenDeduction + w,
          order.heightMm - profile.screenDeduction + w);
    }
    _add(out, 'Sill', order.widthMm + w);
    _add(out, 'Sill', order.widthMm + w);
  }

  /// Casement double: 4 frame + 1 mullion + 8 sash + 12 beads +
  /// 4 screen + 2 sill = 31 pieces.
  static void _casementDouble(List<CutPiece> out, WindowOrder order,
      UPVCProfile profile,
      {required bool beads, required bool screen}) {
    final w = profile.weldingAllowance;
    _frame(out, order.widthMm, order.heightMm, w);
    _add(out, 'Mullion', order.heightMm + w);
    final sashW = order.widthMm / 2 - profile.sashDeduction + w;
    final sashH = order.heightMm - profile.sashDeduction + w;
    _sash(out, sashW, sashH, 'Sash');
    _sash(out, sashW, sashH, 'Sash');
    if (beads) {
      _beadsFor(out, order.widthMm + w, order.heightMm + w,
          profile.beadDeduction, 'Frame');
      _beadsFor(out, sashW, sashH, profile.beadDeduction, 'Sash');
      _beadsFor(out, sashW, sashH, profile.beadDeduction, 'Sash');
    }
    if (screen) {
      _screenFor(out, order.widthMm / 2 - profile.screenDeduction + w,
          order.heightMm - profile.screenDeduction + w);
    }
    _add(out, 'Sill', order.widthMm + w);
    _add(out, 'Sill', order.widthMm + w);
  }

  /// Fixed glass: 4 frame + 4 beads + 2 sill = 10 pieces.
  static void _fixed(List<CutPiece> out, WindowOrder order,
      UPVCProfile profile,
      {required bool beads}) {
    final w = profile.weldingAllowance;
    _frame(out, order.widthMm, order.heightMm, w);
    if (beads) {
      _beadsFor(out, order.widthMm + w, order.heightMm + w,
          profile.beadDeduction, 'Frame');
    }
    _add(out, 'Sill', order.widthMm + w);
    _add(out, 'Sill', order.widthMm + w);
  }

  /// Combo: left leaf slides, right leaf tilts (or casement).
  /// 4 frame + 2 divider + 4 slide sash + 4 second sash + 12 beads +
  /// 4 screen + 2 sill = 32 pieces.
  static void _combo(List<CutPiece> out, WindowOrder order,
      UPVCProfile profile,
      {required bool secondLeafTilt,
      required bool beads,
      required bool screen}) {
    final w = profile.weldingAllowance;
    _frame(out, order.widthMm, order.heightMm, w);
    _add(out, 'Divider', order.heightMm + w);
    _add(out, 'Divider', order.heightMm + w);
    final leafW = order.widthMm / 2 - profile.sashDeduction + w;
    final leafH = order.heightMm - profile.sashDeduction + w;
    _sash(out, leafW, leafH, 'Slide Sash');
    _sash(out, leafW, leafH,
        secondLeafTilt ? 'Tilt Sash' : 'Casement Sash');
    if (beads) {
      _beadsFor(out, order.widthMm + w, order.heightMm + w,
          profile.beadDeduction, 'Frame');
      _beadsFor(out, leafW, leafH, profile.beadDeduction, 'Slide');
      _beadsFor(out, leafW, leafH, profile.beadDeduction,
          secondLeafTilt ? 'Tilt' : 'Casement');
    }
    if (screen) {
      _screenFor(out, order.widthMm / 2 - profile.screenDeduction + w,
          order.heightMm - profile.screenDeduction + w);
    }
    _add(out, 'Sill', order.widthMm + w);
    _add(out, 'Sill', order.widthMm + w);
  }
}
