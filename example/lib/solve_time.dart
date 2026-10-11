/// Exact, adaptive duration formatting for solve timings.
///
/// Picks the unit from the magnitude and prints the exact value — no
/// rounding, so a 320 µs solve never shows as `0 ms`:
/// microseconds below 1 ms, milliseconds below 1 s, seconds above.
/// Dart numbers print in shortest round-trip form, so 15312 µs renders
/// as `15.312 ms` with no precision lost.
library;

String formatMicroseconds(int microseconds) {
  if (microseconds < 0) return '0 µs';
  if (microseconds < 1000) return '$microseconds µs';
  if (microseconds < 1000000) return '${microseconds / 1000} ms';
  return '${microseconds / 1000000} s';
}
