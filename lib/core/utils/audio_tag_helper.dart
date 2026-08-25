import 'package:flutter/material.dart';

class AudioTagHelper {
  static bool isDub(String? urlOrName, {bool? override}) {
    if (override != null) return override;
    if (urlOrName == null || urlOrName.isEmpty) return false;
    final decoded = Uri.decodeFull(urlOrName).toLowerCase();

    // reject subs
    if (RegExp(
      r'\b(eng|english)\s*sub(s|bed)?\b',
      caseSensitive: false,
    ).hasMatch(decoded)) {
      return false;
    }

    if (RegExp(
      r'\b(dual[\s\-_]*audio|multi[\s\-_]*audio|dualaudio)\b|[\(\[\{]dual[\)\]\}]|\b(eng\s*[\+\&]\s*jap|jap\s*[\+\&]\s*eng)\b',
      caseSensitive: false,
    ).hasMatch(decoded)) {
      return true;
    }

    if (RegExp(
      r'\b(engdub|eng-dub|english-dub|english\s*dub(bed)?|eng\s*dub(bed)?|dubbed|dubs)\b|[\(\[\{\s\._\-]dub[\)\]\}\s\._\-]|\b(eng|english)[\s\-_]*audio\b',
      caseSensitive: false,
    ).hasMatch(decoded)) {
      return true;
    }

    return false;
  }
}

class DubBadge extends StatelessWidget {
  final String label;
  const DubBadge({super.key, this.label = 'DUB'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
