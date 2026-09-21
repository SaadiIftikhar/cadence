import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';

class _Page {
  const _Page({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const _pages = <_Page>[
  _Page(
    icon: Symbols.checklist,
    title: 'One step, or a whole routine',
    body: 'Save a single thing to do, or build a routine of steps and work '
        'through them one at a time. Give any of them their own icon and a '
        'countdown.',
  ),
  _Page(
    icon: Symbols.lock,
    title: 'Everything stays on your phone',
    body: 'No account, no sync, no servers. This app has no internet access '
        'at all, so what you write here has nowhere else to go.',
  ),
  _Page(
    icon: Symbols.notifications_active,
    title: 'So it can actually remind you',
    body: 'Reminders arrive as notifications at the time you pick, or as a '
        'full-screen alarm when something really matters.',
  ),
];

/// First-run introduction.
///
/// The notification permission is asked for on the last page rather than at
/// launch: a request that arrives before the app has explained itself is
/// usually declined, and a declined notification permission is the one thing
/// this app cannot work around.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  /// Called once, saying whether the user agreed to be asked for the
  /// notification permission.
  final void Function({required bool allowNotifications}) onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) => _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: TextButton(
                  // Skip stays put rather than vanishing on the last page, so
                  // it never swaps places with something else under a thumb.
                  onPressed: _isLast
                      ? null
                      : () => widget.onFinished(allowNotifications: false),
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _PageView(page: _pages[i]),
              ),
            ),
            _Dots(
              count: _pages.length,
              index: _index,
              onTap: _goTo,
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _isLast
                      ? widget.onFinished(allowNotifications: true)
                      : _goTo(_index + 1),
                  child: Text(_isLast ? 'Allow notifications' : 'Continue'),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: _isLast
                  ? TextButton(
                      onPressed: () =>
                          widget.onFinished(allowNotifications: false),
                      child: const Text('Not now'),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
            child: Icon(page.icon, size: 72, color: AppColors.primary),
          ),
          const SizedBox(height: 44),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 27,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dots where the current one stretches into a pill, each tappable.
class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.onTap,
  });

  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            label: 'Page ${i + 1} of $count',
            selected: i == index,
            button: true,
            child: InkResponse(
              onTap: () => onTap(i),
              radius: 22,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: i == index ? 26 : 8,
                  decoration: BoxDecoration(
                    color: i == index
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
