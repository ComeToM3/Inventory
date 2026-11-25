import 'package:flutter/material.dart';

import '../domain/inventory_models.dart';
import 'inventory_icon_catalog.dart';
import 'inventory_icon_dictionary.dart';
import 'inventory_icon_entry.dart';

/// Offline name → icon resolution with deterministic priorities.
abstract final class InventoryIconResolver {
  static Map<String, List<InventoryIconEntry>>? _byNormalized;
  static List<(String, InventoryIconEntry)>? _phrases;

  static void _ensureIndex() {
    if (_byNormalized != null) return;
    final by = <String, List<InventoryIconEntry>>{};
    final phrases = <(String, InventoryIconEntry)>[];
    for (final entry in InventoryIconDictionary.entries) {
      final norm = normalize(entry.term);
      if (norm.isEmpty) continue;
      by.putIfAbsent(norm, () => <InventoryIconEntry>[]).add(entry);
      if (norm.contains(' ')) {
        phrases.add((norm, entry));
      }
    }
    phrases.sort((a, b) {
      final words = b.$1.split(' ').length.compareTo(a.$1.split(' ').length);
      if (words != 0) return words;
      return b.$2.priority.compareTo(a.$2.priority);
    });
    _byNormalized = by;
    _phrases = phrases;
  }

  /// Lowercase, strip accents, collapse punctuation/spaces, light plural trim.
  static String normalize(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return '';
    const pairs = <String, String>{
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a',
      'æ': 'ae', 'ç': 'c', 'ć': 'c', 'č': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i', 'ī': 'i', 'į': 'i', 'ì': 'i',
      'ł': 'l', 'ñ': 'n', 'ń': 'n',
      'ô': 'o', 'ö': 'o', 'ò': 'o', 'ó': 'o', 'õ': 'o', 'ø': 'o', 'ō': 'o',
      'œ': 'oe',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u',
      'ý': 'y', 'ÿ': 'y', 'ž': 'z', 'ź': 'z', 'ż': 'z',
    };
    final buf = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      buf.write(pairs[ch] ?? ch);
    }
    s = buf.toString();
    s = s.replaceAll(RegExp(r"[’'`´]"), ' ');
    s = s.replaceAll(RegExp(r'[^a-z0-9\s\-]+'), ' ');
    s = s.replaceAll(RegExp(r'[\-]+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static List<String> _tokens(String normalized) {
    if (normalized.isEmpty) return const [];
    final out = <String>[];
    for (final part in normalized.split(' ')) {
      if (part.isEmpty) continue;
      out.add(_singularize(part));
    }
    return out;
  }

  static String _singularize(String token) {
    if (token.length <= 3) return token;
    if (token.endsWith('aux') && token.length > 4) {
      return '${token.substring(0, token.length - 3)}al';
    }
    if (token.endsWith('ies') && token.length > 4) {
      return '${token.substring(0, token.length - 3)}y';
    }
    if (token.endsWith('eaux')) return token.substring(0, token.length - 1);
    // Keep invariant endings: souris, bois, avis, bus, etc.
    if (RegExp(r'(is|us|as|os|ès|és)$').hasMatch(token)) return token;
    if (token.endsWith('s') && !token.endsWith('ss')) {
      return token.substring(0, token.length - 1);
    }
    if (token.endsWith('x') && token.length > 4) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  static bool _containsPhrase(String haystack, String phrase) {
    if (haystack == phrase) return true;
    if (!haystack.contains(phrase)) return false;
    final re = RegExp('(?:^|\\s)${RegExp.escape(phrase)}(?:\\s|\$)');
    return re.hasMatch(haystack);
  }

  static String? resolveKey({
    required String name,
    required NodeType type,
    String? manualKey,
  }) {
    if (manualKey != null &&
        manualKey.isNotEmpty &&
        InventoryIconCatalog.isKnown(manualKey)) {
      return manualKey;
    }
    _ensureIndex();
    final norm = normalize(name);
    if (norm.isEmpty) return null;

    InventoryIconEntry? best;
    var bestScore = -1;
    void consider(InventoryIconEntry entry, {required bool phraseMatch}) {
      final words = normalize(entry.term).split(' ').length;
      final score = entry.priority +
          (entry.preferredType == type ? 40 : 0) +
          // Prefer specific multi-word expressions over generic tokens.
          (phraseMatch || words > 1 ? 60 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }

    for (final (phrase, entry) in _phrases!) {
      if (_containsPhrase(norm, phrase)) {
        consider(entry, phraseMatch: true);
      }
    }

    final tokens = _tokens(norm);
    final by = _byNormalized!;
    for (final token in tokens) {
      final list = by[token];
      if (list == null) continue;
      for (final entry in list) {
        // Skip multi-word dictionary terms when matching single tokens.
        if (normalize(entry.term).contains(' ')) continue;
        consider(entry, phraseMatch: false);
      }
    }

    return best?.iconKey;
  }

  static IconData resolve({
    required String name,
    required NodeType type,
    String? manualKey,
  }) {
    final key = resolveKey(name: name, type: type, manualKey: manualKey);
    return InventoryIconCatalog.byKey(key) ??
        InventoryIconCatalog.genericFor(type);
  }

  static IconData iconForNode(InventoryNode node) => resolve(
    name: node.name,
    type: node.type,
    manualKey: node.iconKey,
  );
}
