import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../services/app_settings.dart';
import '../widgets/tx.dart';

/// Three short welcome screens, shown once on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.settings,
    required this.onDone,
  });

  final AppSettings settings;
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  const _Page(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const List<_Page> _pages = [
  _Page(
    Icons.verified_outlined,
    'Proof on every photo',
    'SiteStamp prints the date, time, place name and GPS on each photo, so '
        'you can show where and when the work was done.',
  ),
  _Page(
    Icons.folder_special_outlined,
    'Keep every job in order',
    'With Pro, projects, photo checklists and job-site checks keep photos '
        'organised and flag photos taken away from the site.',
  ),
  _Page(
    Icons.ios_share,
    'Share and report',
    'Send photos to WhatsApp with a map link, or export PDF and CSV reports '
        'of your work.',
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      widget.onDone();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: AppLanguage.instance,
                      builder: (context, _) => SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('English')),
                          ButtonSegment(value: 'hi', label: Text('हिन्दी')),
                        ],
                        selected: {AppLanguage.instance.code},
                        onSelectionChanged: (s) =>
                            widget.settings.setLanguage(s.first),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.icon, size: 96, color: const Color(0xFFFF8F00)),
                        const SizedBox(height: 28),
                        Tx(
                          p.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 14),
                        Tx(p.body, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Container(
                    margin: const EdgeInsets.all(4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? const Color(0xFFFF8F00)
                          : const Color(0x55FFFFFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  if (!last)
                    TextButton(
                      onPressed: widget.onDone,
                      child: const Tx('Skip'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Tx(last ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
