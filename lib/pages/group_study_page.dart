import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/group_provider.dart';
import '../models/group_member_model.dart';
import '../theme/app_colors.dart';
import '../widgets/surface_card.dart';
import '../widgets/page_transition.dart';

class GroupStudyPage extends ConsumerWidget {
  const GroupStudyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider);

    return FadeSlideIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GroupHeader(),
              const SizedBox(height: 24),
              if (!group.hasCredentials)
                const _CredentialsSetupCard()
              else if (!group.isInGroup)
                const _JoinOrCreateCard()
              else
                const _GroupLeaderboard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Study',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Compare progress with friends in real time',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _CredentialsSetupCard extends ConsumerStatefulWidget {
  const _CredentialsSetupCard();

  @override
  ConsumerState<_CredentialsSetupCard> createState() =>
      _CredentialsSetupCardState();
}

class _CredentialsSetupCardState
    extends ConsumerState<_CredentialsSetupCard> {
  final _projectIdCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _projectIdCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final projectId = _projectIdCtrl.text.trim();
    final apiKey = _apiKeyCtrl.text.trim();
    if (projectId.isEmpty || apiKey.isEmpty) return;

    setState(() => _saving = true);
    await ref.read(groupProvider.notifier).saveCredentials(projectId, apiKey);
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'One-time setup required',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Group Study needs a free Firebase project to sync between '
            'devices. This is a one-time setup — create a free project at '
            'console.firebase.google.com, enable "Firestore Database" in '
            'production mode, set its rules to allow read/write, then copy '
            'your Project ID and Web API Key here.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _projectIdCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Firebase Project ID',
              hintText: 'e.g. momentum-study-12345',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _apiKeyCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Web API Key',
              hintText: 'e.g. AIzaSyD...',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save & Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinOrCreateCard extends ConsumerStatefulWidget {
  const _JoinOrCreateCard();

  @override
  ConsumerState<_JoinOrCreateCard> createState() => _JoinOrCreateCardState();
}

class _JoinOrCreateCardState extends ConsumerState<_JoinOrCreateCard> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = ref.read(groupProvider).displayName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureName() async {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      await ref.read(groupProvider.notifier).setDisplayName(name);
    }
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    await _ensureName();
    await ref.read(groupProvider.notifier).createGroup();
    setState(() => _busy = false);
  }

  Future<void> _join() async {
    if (_nameCtrl.text.trim().isEmpty || _codeCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    await _ensureName();
    await ref.read(groupProvider.notifier).joinGroup(_codeCtrl.text);
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Name',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'How friends will see you',
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 20),
          const Text(
            'Start a New Group',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Creates a 6-character code you can share with friends.",
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _create,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Create Group'),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 20),
          const Text(
            'Join an Existing Group',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'ABC123',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _busy ? null : _join,
                child: const Text('Join'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupLeaderboard extends ConsumerWidget {
  const _GroupLeaderboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Group Code',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      group.groupCode ?? '',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    color: AppColors.textMuted, size: 18),
                tooltip: 'Copy code',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: group.groupCode ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group code copied')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textMuted, size: 18),
                tooltip: 'Refresh now',
                onPressed: () => ref.read(groupProvider.notifier).refreshMembers(),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.red, size: 18),
                tooltip: 'Leave group',
                onPressed: () => _confirmLeave(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'TODAY',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (group.members.isEmpty)
          SurfaceCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Text('👋', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  Text(
                    group.isLoading
                        ? 'Loading group...'
                        : 'No one here yet — share your code!',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ...group.members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MemberCard(member: m),
              )),
      ],
    );
  }

  void _confirmLeave(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
            'You can rejoin anytime using the same or a different code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(groupProvider.notifier).leaveGroup();
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final GroupMemberModel member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final isLive = member.isLive;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderColor: isLive ? AppColors.green.withOpacity(0.3) : null,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isLive ? AppColors.green : AppColors.textMuted,
              shape: BoxShape.circle,
              boxShadow: isLive
                  ? [
                      BoxShadow(
                        color: AppColors.green.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.currentSubject != null
                      ? '${member.statusLabel} · ${member.currentSubject}'
                      : member.statusLabel,
                  style: TextStyle(
                    color: isLive ? AppColors.green : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            member.formattedHoursToday,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
