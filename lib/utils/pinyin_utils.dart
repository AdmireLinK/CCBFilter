import 'package:lpinyin/lpinyin.dart';

/// 提供基于拼音的模糊匹配排序工具, 支持汉字与拼音的双向搜索。
class PinyinSearch {
  const PinyinSearch._();

  /// 按照查询字符串对候选项进行排序，返回匹配度从高到低的结果列表。
  static List<String> rank(Iterable<String> source, String query) {
    if (query.isEmpty) {
      return const <String>[];
    }

    final lowerQuery = query.toLowerCase();
    final matches = <_PinyinMatch>[];

    for (final value in source) {
      final match = _scoreCandidate(value, lowerQuery);
      if (match != null) {
        matches.add(match);
      }
    }

    matches.sort();
    return matches.map((m) => m.original).toList(growable: false);
  }

  static _PinyinMatch? _scoreCandidate(String value, String lowerQuery) {
    final variants = <_Variant>[];
    final lowerValue = value.toLowerCase();
    variants.add(_Variant(lowerValue, isPinyin: false, isShort: false));

    final fullPinyin = PinyinHelper.getPinyinE(
      value,
      separator: '',
      format: PinyinFormat.WITHOUT_TONE,
    ).toLowerCase();
    if (fullPinyin.isNotEmpty && fullPinyin != lowerValue) {
      variants.add(_Variant(fullPinyin, isPinyin: true, isShort: false));
    }

    final shortPinyin = PinyinHelper.getShortPinyin(value).toLowerCase();
    if (shortPinyin.isNotEmpty) {
      variants.add(_Variant(shortPinyin, isPinyin: true, isShort: true));
    }

    _VariantMatch? best;

    for (final variant in variants) {
      final position = variant.text.indexOf(lowerQuery);
      if (position == -1) {
        continue;
      }

      final isExact = position == 0 && variant.text.length == lowerQuery.length;
      final isPrefix = position == 0;
      final score = _scoreFor(
        variant.isPinyin,
        variant.isShort,
        isExact,
        isPrefix,
      );
      final candidate = _VariantMatch(
        score: score,
        position: position,
        length: variant.text.length,
      );

      if (best == null) {
        best = candidate;
      } else if (candidate.compareTo(best) < 0) {
        best = candidate;
      }
    }

    final resolvedBest = best;
    if (resolvedBest == null) {
      return null;
    }

    return _PinyinMatch(original: value, match: resolvedBest);
  }

  static int _scoreFor(
    bool isPinyin,
    bool isShort,
    bool isExact,
    bool isPrefix,
  ) {
    if (!isPinyin) {
      if (isExact) return 0;
      if (isPrefix) return 1;
      return 2;
    }

    final base = isShort ? 3 : 3;
    if (isExact) return base;
    if (isPrefix) return base + 1;
    return base + 2;
  }
}

class _Variant {
  const _Variant(this.text, {required this.isPinyin, required this.isShort});

  final String text;
  final bool isPinyin;
  final bool isShort;
}

class _VariantMatch implements Comparable<_VariantMatch> {
  const _VariantMatch({
    required this.score,
    required this.position,
    required this.length,
  });

  final int score;
  final int position;
  final int length;

  @override
  int compareTo(_VariantMatch other) {
    if (score != other.score) {
      return score.compareTo(other.score);
    }
    if (position != other.position) {
      return position.compareTo(other.position);
    }
    if (length != other.length) {
      return length.compareTo(other.length);
    }
    return 0;
  }
}

class _PinyinMatch implements Comparable<_PinyinMatch> {
  const _PinyinMatch({required this.original, required this.match});

  final String original;
  final _VariantMatch match;

  @override
  int compareTo(_PinyinMatch other) {
    final result = match.compareTo(other.match);
    if (result != 0) {
      return result;
    }
    return original.compareTo(other.original);
  }
}
