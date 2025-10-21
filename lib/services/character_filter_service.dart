import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/character.dart';
import '../utils/logger.dart';

/// 角色筛选服务,负责加载和筛选角色数据
class CharacterFilterService {
  List<CharacterInfo>? _allCharacters;
  List<CharacterInfo>? _animeCharacters;
  bool _isLoading = false;

  /// 获取所有角色数据(懒加载)
  Future<List<CharacterInfo>> getAllCharacters([bool animeOnly = false]) async {
    final targetList = animeOnly ? _animeCharacters : _allCharacters;

    if (targetList != null) {
      return targetList;
    }

    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return animeOnly ? (_animeCharacters ?? []) : (_allCharacters ?? []);
    }

    _isLoading = true;
    try {
      final projectRoot = Directory.current.path;
      final dataDir = path.join(projectRoot, 'data');
      final fileName = animeOnly ? 'Anime.json' : 'All.json';
      final dataFile = File(path.join(dataDir, fileName));

      if (!dataFile.existsSync()) {
        Logger.warning(
          '数据文件不存在: ${dataFile.path}',
          tag: 'CharacterFilterService',
        );
        if (animeOnly) {
          _animeCharacters = [];
        } else {
          _allCharacters = [];
        }
        return [];
      }

      final content = await dataFile.readAsString();
      final List<dynamic> jsonData = json.decode(content);

      final characters = jsonData
          .map((json) => CharacterInfo.fromJson(json as Map<String, dynamic>))
          .toList();

      if (animeOnly) {
        _animeCharacters = characters;
      } else {
        _allCharacters = characters;
      }

      Logger.info(
        '加载角色数据完成: ${characters.length} 条 ($fileName)',
        tag: 'CharacterFilterService',
      );
      return characters;
    } catch (e, stackTrace) {
      Logger.error(
        '加载角色数据失败',
        tag: 'CharacterFilterService',
        error: e,
        stackTrace: stackTrace,
      );
      if (animeOnly) {
        _animeCharacters = [];
      } else {
        _allCharacters = [];
      }
      return [];
    } finally {
      _isLoading = false;
    }
  }

  /// 获取所有作品名
  Set<String> getAllAppearances(List<CharacterInfo> characters) {
    final appearances = <String>{};
    for (final char in characters) {
      appearances.addAll(char.appearances);
    }
    return appearances;
  }

  /// 筛选角色
  List<CharacterInfo> filterCharacters({
    required List<CharacterInfo> characters,
    String? gender,
    int? popularityMin,
    int? popularityMax,
    int? popularityExact,
    bool popularityFuzzy = true,
    int? workCountMin,
    int? workCountMax,
    int? workCountExact,
    bool workCountFuzzy = true,
    double? ratingMin,
    double? ratingMax,
    double? ratingExact,
    bool ratingFuzzy = true,
    int? earliestYearMin,
    int? earliestYearMax,
    int? earliestYearExact,
    bool earliestYearFuzzy = true,
    int? latestYearMin,
    int? latestYearMax,
    int? latestYearExact,
    bool latestYearFuzzy = true,
    List<String>? tags,
    String? appearance,
  }) {
    return characters.where((char) {
      if (gender != null && char.gender != gender) {
        return false;
      }

      final double popularityValue = char.popularity.toDouble();
      final int workCountValue = char.workCount;
      final double ratingValue = char.highestRating;
      final int earliestValue = char.earliestAppearance;
      final int latestValue = char.latestAppearance;

      if (popularityExact != null) {
        final double exactCenter = popularityExact.toDouble();
        final double tolerance = exactCenter * 0.053;
        if (popularityValue < exactCenter - tolerance ||
            popularityValue > exactCenter + tolerance) {
          return false;
        }
      }
      if (popularityMin != null) {
        final double minInput = popularityMin.toDouble();
        if (popularityFuzzy) {
          final double upper = minInput * 1.25;
          if (popularityValue <= minInput || popularityValue >= upper) {
            return false;
          }
        } else {
          final double threshold = minInput * 1.25;
          if (popularityValue < threshold) {
            return false;
          }
        }
      }
      if (popularityMax != null) {
        final double maxInput = popularityMax.toDouble();
        if (popularityFuzzy) {
          final double lower = maxInput * 0.8;
          if (popularityValue >= maxInput || popularityValue <= lower) {
            return false;
          }
        } else {
          final double threshold = maxInput * 0.8;
          if (popularityValue > threshold) {
            return false;
          }
        }
      }

      if (workCountExact != null && workCountValue != workCountExact) {
        return false;
      }
      if (workCountMin != null) {
        if (workCountFuzzy) {
          final int upper = workCountMin + 2;
          if (workCountValue <= workCountMin || workCountValue >= upper) {
            return false;
          }
        } else {
          final int threshold = workCountMin + 2;
          if (workCountValue < threshold) {
            return false;
          }
        }
      }
      if (workCountMax != null) {
        if (workCountFuzzy) {
          final int lower = workCountMax - 2;
          if (workCountValue >= workCountMax || workCountValue <= lower) {
            return false;
          }
        } else {
          final int threshold = workCountMax - 2;
          if (workCountValue > threshold) {
            return false;
          }
        }
      }

      if (ratingExact != null) {
        const double tolerance = 0.6;
        if (ratingValue < ratingExact - tolerance ||
            ratingValue > ratingExact + tolerance) {
          return false;
        }
      }
      if (ratingMin != null) {
        if (ratingFuzzy) {
          final double upper = ratingMin + 1.0;
          if (ratingValue <= ratingMin || ratingValue >= upper) {
            return false;
          }
        } else {
          final double threshold = ratingMin + 1.0;
          if (ratingValue < threshold) {
            return false;
          }
        }
      }
      if (ratingMax != null) {
        if (ratingFuzzy) {
          final double lower = ratingMax - 1.0;
          if (ratingValue >= ratingMax || ratingValue <= lower) {
            return false;
          }
        } else {
          final double threshold = ratingMax - 1.0;
          if (ratingValue > threshold) {
            return false;
          }
        }
      }

      if (earliestYearExact != null && earliestValue != earliestYearExact) {
        return false;
      }
      if (earliestYearMin != null) {
        if (earliestYearFuzzy) {
          final int upper = earliestYearMin + 2;
          if (earliestValue <= earliestYearMin || earliestValue >= upper) {
            return false;
          }
        } else {
          final int threshold = earliestYearMin + 2;
          if (earliestValue < threshold) {
            return false;
          }
        }
      }
      if (earliestYearMax != null) {
        if (earliestYearFuzzy) {
          final int lower = earliestYearMax - 2;
          if (earliestValue >= earliestYearMax || earliestValue <= lower) {
            return false;
          }
        } else {
          final int threshold = earliestYearMax - 2;
          if (earliestValue > threshold) {
            return false;
          }
        }
      }

      if (latestYearExact != null && latestValue != latestYearExact) {
        return false;
      }
      if (latestYearMin != null) {
        if (latestYearFuzzy) {
          final int upper = latestYearMin + 2;
          if (latestValue <= latestYearMin || latestValue >= upper) {
            return false;
          }
        } else {
          final int threshold = latestYearMin + 2;
          if (latestValue < threshold) {
            return false;
          }
        }
      }
      if (latestYearMax != null) {
        if (latestYearFuzzy) {
          final int lower = latestYearMax - 2;
          if (latestValue >= latestYearMax || latestValue <= lower) {
            return false;
          }
        } else {
          final int threshold = latestYearMax - 2;
          if (latestValue > threshold) {
            return false;
          }
        }
      }

      // 标签筛选(所有选中标签都要匹配)
      if (tags != null && tags.isNotEmpty) {
        final charTags = char.metaTags.map((t) => t.toLowerCase()).toSet();
        for (final tag in tags) {
          if (!charTags.contains(tag.toLowerCase())) {
            return false;
          }
        }
      }

      // 作品名筛选(至少匹配一个)
      if (appearance != null && appearance.isNotEmpty) {
        bool hasMatch = char.appearances.any(
          (a) => a.toLowerCase().contains(appearance.toLowerCase()),
        );
        if (!hasMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// 获取所有标签(用于标签搜索)
  Set<String> getAllTags(List<CharacterInfo> characters) {
    final tags = <String>{};
    for (final char in characters) {
      tags.addAll(char.metaTags);
    }
    return tags;
  }

  /// 搜索标签
  List<String> searchTags(Set<String> allTags, String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return allTags
        .where((tag) => tag.toLowerCase().contains(lowerQuery))
        .toList()
      ..sort();
  }

  /// 重新加载数据
  Future<void> reload() async {
    _allCharacters = null;
    _animeCharacters = null;
    await Future.wait([getAllCharacters(false), getAllCharacters(true)]);
  }
}
