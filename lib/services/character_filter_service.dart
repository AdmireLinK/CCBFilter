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
      // 性别筛选
      if (gender != null && char.gender != gender) {
        return false;
      }

      // 热度筛选: 精确值±10%, 最小*0.8, 最大*1.2
      if (popularityExact != null) {
        if (popularityFuzzy) {
          final fuzzyRange = (popularityExact * 0.1).round();
          if (char.popularity < popularityExact - fuzzyRange ||
              char.popularity > popularityExact + fuzzyRange) {
            return false;
          }
        } else {
          if (char.popularity != popularityExact) return false;
        }
      } else {
        if (popularityMin != null) {
          final fuzzyMin = popularityFuzzy
              ? (popularityMin * 0.8).round()
              : popularityMin;
          if (char.popularity < fuzzyMin) {
            return false;
          }
        }
        if (popularityMax != null) {
          final fuzzyMax = popularityFuzzy
              ? (popularityMax * 1.2).round()
              : popularityMax;
          if (char.popularity > fuzzyMax) {
            return false;
          }
        }
      }

      // 作品数筛选: 精确值无模糊, 最小-2, 最大+2
      if (workCountExact != null) {
        if (char.workCount != workCountExact) {
          return false;
        }
      } else {
        if (workCountMin != null) {
          final fuzzyMin = workCountFuzzy ? workCountMin - 2 : workCountMin;
          if (char.workCount < fuzzyMin) {
            return false;
          }
        }
        if (workCountMax != null) {
          final fuzzyMax = workCountFuzzy ? workCountMax + 2 : workCountMax;
          if (char.workCount > fuzzyMax) {
            return false;
          }
        }
      }

      // 最高评分筛选: 精确值±0.6, 最小-1, 最大+1
      if (ratingExact != null) {
        if (ratingFuzzy) {
          const fuzzyRange = 0.6;
          if (char.highestRating < ratingExact - fuzzyRange ||
              char.highestRating > ratingExact + fuzzyRange) {
            return false;
          }
        } else {
          if (char.highestRating != ratingExact) return false;
        }
      } else {
        if (ratingMin != null) {
          final fuzzyMin = ratingFuzzy ? ratingMin - 1.0 : ratingMin;
          if (char.highestRating < fuzzyMin) {
            return false;
          }
        }
        if (ratingMax != null) {
          final fuzzyMax = ratingFuzzy ? ratingMax + 1.0 : ratingMax;
          if (char.highestRating > fuzzyMax) {
            return false;
          }
        }
      }

      // 最早登场年份筛选: 精确值无模糊, 最小+2, 最大-2
      if (earliestYearExact != null) {
        if (char.earliestAppearance != earliestYearExact) {
          return false;
        }
      } else {
        if (earliestYearMin != null) {
          final fuzzyMin = earliestYearFuzzy
              ? earliestYearMin + 2
              : earliestYearMin;
          if (char.earliestAppearance < fuzzyMin) {
            return false;
          }
        }
        if (earliestYearMax != null) {
          final fuzzyMax = earliestYearFuzzy
              ? earliestYearMax - 2
              : earliestYearMax;
          if (char.earliestAppearance > fuzzyMax) {
            return false;
          }
        }
      }

      // 最晚登场年份筛选: 精确值无模糊, 最小-2, 最大+2
      if (latestYearExact != null) {
        if (char.latestAppearance != latestYearExact) {
          return false;
        }
      } else {
        if (latestYearMin != null) {
          final fuzzyMin = latestYearFuzzy ? latestYearMin - 2 : latestYearMin;
          if (char.latestAppearance < fuzzyMin) {
            return false;
          }
        }
        if (latestYearMax != null) {
          final fuzzyMax = latestYearFuzzy ? latestYearMax + 2 : latestYearMax;
          if (char.latestAppearance > fuzzyMax) {
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
