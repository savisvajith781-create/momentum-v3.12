import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// A small live clock — 24-hour format, no seconds — meant to sit in the
/// dashboard header next to the date. Updates once a minute (not every
/// second) since seconds aren't displayed, so there's no unnecessary
/// rebuilding.
class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    // Align the first tick to the start of the next minute, then tick
    // every 60 seconds after that -- keeps the displayed time accurate
    // without a full per-second timer.
    final secondsUntilNextMinute = 60 - _now.second;
    _timer = Timer(Duration(seconds: secondsUntilNextMinute), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('HH:mm').format(_now),
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
