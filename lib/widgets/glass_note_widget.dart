import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/note_provider.dart';
import '../theme/app_colors.dart';

/// A deliberately transparent "liquid glass" note the person can click into
/// and write a quick line for the day — an intention, a quote, a reminder.
/// This is the one place in the whole app that uses a frosted-glass effect;
/// everywhere else in the Calm Ivory theme avoids glassmorphism on purpose.
class GlassNoteWidget extends ConsumerStatefulWidget {
  const GlassNoteWidget({super.key});

  @override
  ConsumerState<GlassNoteWidget> createState() => _GlassNoteWidgetState();
}

class _GlassNoteWidgetState extends ConsumerState<GlassNoteWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(personalNoteProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: TextField(
            controller: _controller,
            maxLines: null,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintText: "Write a quick note or intention for today…",
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              ref.read(personalNoteProvider.notifier).setNote(value);
            },
          ),
        ),
      ),
    );
  }
}
