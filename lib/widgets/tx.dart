import 'package:flutter/material.dart';

import '../l10n/app_language.dart';

/// Drop-in replacement for `Text('English')` that shows the Hindi translation
/// when the app language is Hindi. Works inside `const` trees.
class Tx extends StatelessWidget {
  const Tx(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguage.instance,
      builder: (context, _) => Text(
        tr(text),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
