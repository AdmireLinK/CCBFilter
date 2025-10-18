import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/character.dart';
import '../services/character_filter_service.dart';

/// 主页,提供角色筛选功能
class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage>
    with SingleTickerProviderStateMixin {
  final CharacterFilterService _filterService = CharacterFilterService();

  List<CharacterInfo> _allCharacters = [];
  List<CharacterInfo> _filteredCharacters = [];
  Set<String> _allTags = {};
  Set<String> _allAppearances = {};
  final GlobalKey _numericGroupKey = GlobalKey();
  final GlobalKey _yearGroupKey = GlobalKey();
  double? _genderGroupMinHeight;

  bool _isLoading = true;
  bool _useAnimeOnly = true; // true=Anime.json(番剧), false=All.json(番剧+游戏)
  static const int _maxResults = 10;
  static const double _kFilterInputWidth = 65;
  static const double _kTagInputWidth = 100;
  static const double _kGenderColumnSpacing = 4;
  static const double _kGenderColumnWidth =
      80 + _kGenderColumnSpacing * 2;
  static const double _kGenderButtonPreferredSize =
      (_kGenderColumnWidth - _kGenderColumnSpacing) / 2;
  static const double _kGenderButtonMinSize = 40;
  static const double _kGenderTopBottomPadding = 32;
  static const double _kGenderHeaderHeightEstimate = 30;
  static const double _kGenderChromeHeight =
      _kGenderTopBottomPadding +
      _kGenderHeaderHeightEstimate +
      _kGenderColumnSpacing;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 筛选条件
  String? _selectedGender;

  // 热度
  final TextEditingController _popularityMinController =
      TextEditingController();
  final TextEditingController _popularityMaxController =
      TextEditingController();
  final TextEditingController _popularityExactController =
      TextEditingController();
  bool _popularityFuzzy = true;

  // 作品数
  final TextEditingController _workCountMinController = TextEditingController();
  final TextEditingController _workCountMaxController = TextEditingController();
  final TextEditingController _workCountExactController =
      TextEditingController();
  bool _workCountFuzzy = true;

  // 评分
  final TextEditingController _ratingMinController = TextEditingController();
  final TextEditingController _ratingMaxController = TextEditingController();
  final TextEditingController _ratingExactController = TextEditingController();
  bool _ratingFuzzy = true;

  // 最早登场
  final TextEditingController _earliestYearMinController =
      TextEditingController();
  final TextEditingController _earliestYearMaxController =
      TextEditingController();
  final TextEditingController _earliestYearExactController =
      TextEditingController();
  bool _earliestYearFuzzy = true;

  // 最晚登场
  final TextEditingController _latestYearMinController =
      TextEditingController();
  final TextEditingController _latestYearMaxController =
      TextEditingController();
  final TextEditingController _latestYearExactController =
      TextEditingController();
  bool _latestYearFuzzy = true;

  TextEditingController? _tagFieldController;
  final TextEditingController _appearanceSearchController =
      TextEditingController();

  final List<String> _selectedTags = [];
  String? _selectedAppearance;
  String? _hoveredSelectedTag;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadData();
    _setupListeners();
  }

  void _setupListeners() {
    // 为所有输入框添加监听器以实现实时筛选
    _popularityMinController.addListener(_applyFilters);
    _popularityMaxController.addListener(_applyFilters);
    _popularityExactController.addListener(_applyFilters);
    _workCountMinController.addListener(_applyFilters);
    _workCountMaxController.addListener(_applyFilters);
    _workCountExactController.addListener(_applyFilters);
    _ratingMinController.addListener(_applyFilters);
    _ratingMaxController.addListener(_applyFilters);
    _ratingExactController.addListener(_applyFilters);
    _earliestYearMinController.addListener(_applyFilters);
    _earliestYearMaxController.addListener(_applyFilters);
    _earliestYearExactController.addListener(_applyFilters);
    _latestYearMinController.addListener(_applyFilters);
    _latestYearMaxController.addListener(_applyFilters);
    _latestYearExactController.addListener(_applyFilters);
  }

  void _scheduleGenderGroupHeightUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final numericHeight =
          _numericGroupKey.currentContext?.size?.height;
      final yearHeight = _yearGroupKey.currentContext?.size?.height;
      final targetHeight = _maxDouble(numericHeight, yearHeight);

      if (targetHeight != null &&
          (_genderGroupMinHeight == null ||
              (targetHeight - _genderGroupMinHeight!).abs() > 0.5)) {
        setState(() {
          _genderGroupMinHeight = targetHeight;
        });
      }
    });
  }

  double? _maxDouble(double? a, double? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  double _computeGenderButtonSize() {
    final double? targetHeight = _genderGroupMinHeight;
    final double? available = targetHeight != null
        ? (targetHeight - _kGenderChromeHeight - _kGenderColumnSpacing) / 2
        : null;

    double size = _kGenderButtonPreferredSize;

    if (available != null && available.isFinite && available > 0) {
      size = available;
    }

    if (size < _kGenderButtonMinSize) {
      size = _kGenderButtonMinSize;
    } else if (size > _kGenderButtonPreferredSize) {
      size = _kGenderButtonPreferredSize;
    }

    return size;
  }

  double _computeGenderGroupHeight(double buttonSize) {
    return _kGenderChromeHeight + buttonSize * 2 + _kGenderColumnSpacing;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final characters = await _filterService.getAllCharacters(_useAnimeOnly);
      setState(() {
        _allCharacters = characters;
        _filteredCharacters = List.from(characters.take(_maxResults));
        _allTags = _filterService.getAllTags(characters);
        _allAppearances = _filterService.getAllAppearances(characters);
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    if (_isLoading) return;

    final filtered = _filterService.filterCharacters(
      characters: _allCharacters,
      gender: _selectedGender,
      popularityMin: int.tryParse(_popularityMinController.text),
      popularityMax: int.tryParse(_popularityMaxController.text),
      popularityExact: int.tryParse(_popularityExactController.text),
      popularityFuzzy: _popularityFuzzy,
      workCountMin: int.tryParse(_workCountMinController.text),
      workCountMax: int.tryParse(_workCountMaxController.text),
      workCountExact: int.tryParse(_workCountExactController.text),
      workCountFuzzy: _workCountFuzzy,
      ratingMin: double.tryParse(_ratingMinController.text),
      ratingMax: double.tryParse(_ratingMaxController.text),
      ratingExact: double.tryParse(_ratingExactController.text),
      ratingFuzzy: _ratingFuzzy,
      earliestYearMin: int.tryParse(_earliestYearMinController.text),
      earliestYearMax: int.tryParse(_earliestYearMaxController.text),
      earliestYearExact: int.tryParse(_earliestYearExactController.text),
      earliestYearFuzzy: _earliestYearFuzzy,
      latestYearMin: int.tryParse(_latestYearMinController.text),
      latestYearMax: int.tryParse(_latestYearMaxController.text),
      latestYearExact: int.tryParse(_latestYearExactController.text),
      latestYearFuzzy: _latestYearFuzzy,
      tags: _selectedTags.isEmpty ? null : _selectedTags,
      appearance: _selectedAppearance,
    );

    setState(() {
      _filteredCharacters = filtered.take(_maxResults).toList();
    });
  }

  void _toggleDataSource() async {
    setState(() {
      _useAnimeOnly = !_useAnimeOnly;
    });
    await _loadData();
    _applyFilters();
  }

  void _clearFilters() {
    setState(() {
      _selectedGender = null;
      _popularityMinController.clear();
      _popularityMaxController.clear();
      _popularityExactController.clear();
      _workCountMinController.clear();
      _workCountMaxController.clear();
      _workCountExactController.clear();
      _ratingMinController.clear();
      _ratingMaxController.clear();
      _ratingExactController.clear();
      _earliestYearMinController.clear();
      _earliestYearMaxController.clear();
      _earliestYearExactController.clear();
      _latestYearMinController.clear();
      _latestYearMaxController.clear();
      _latestYearExactController.clear();
      _selectedTags.clear();
      _selectedAppearance = null;
      _appearanceSearchController.clear();
      _tagFieldController?.clear();
      _filteredCharacters = List.from(_allCharacters.take(_maxResults));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _scheduleGenderGroupHeightUpdate();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildFilterSection(),
          const Divider(height: 1),
          _buildResultsHeader(),
          const Divider(height: 1),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildResultsCards(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '猜猜呗笑传之查查吧',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Text('番剧', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Switch(
                value: !_useAnimeOnly,
                onChanged: (_) => _toggleDataSource(),
                activeThumbColor: Colors.green,
              ),
              const SizedBox(width: 8),
              const Text('番剧+游戏', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 使用IntrinsicWidth包裹第一、二行，使宽度与第一行内容对齐
          IntrinsicWidth(
            child: Builder(
              builder: (_) {
                final double genderButtonSize = _computeGenderButtonSize();
                final double genderGroupHeight =
                    _computeGenderGroupHeight(genderButtonSize);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 第一行：数值筛选组 + 年份筛选组 + 性别组
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterGroup(
                          containerKey: _numericGroupKey,
                          child: _buildNumericFilterGrid(),
                        ),
                        const SizedBox(width: 16),
                        _buildFilterGroup(
                          containerKey: _yearGroupKey,
                          child: _buildYearFilterColumn(),
                        ),
                        const SizedBox(width: 16),
                        _buildFilterGroup(
                          child: _buildGenderFilter(genderButtonSize),
                          minHeight: genderGroupHeight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 第二行：标签筛选（自动占满第一行的宽度）
                    _buildFilterGroup(child: _buildTagFilter()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 筛选条件组容器(带圆角边框)
  Widget _buildFilterGroup({
    required Widget child,
    Key? containerKey,
    double? minHeight,
  }) {
    final constraints = minHeight != null
        ? BoxConstraints(minHeight: minHeight, maxHeight: minHeight)
        : null;
    return Container(
      key: containerKey,
      constraints: constraints,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// 筛选条件标题Chip(点击切换模糊状态, hover效果)
  Widget _buildFilterTitleChipWithHover(
    String text, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return _HoverableChip(text: text, isActive: isActive, onTap: onTap);
  }

  /// 普通标题Chip(无交互, 透明圆角矩形)
  Widget _buildFilterTitleChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildGenderFilter(double buttonSize) {
    const double columnWidth = _kGenderColumnWidth;
    final double gridHeight = buttonSize * 2 + _kGenderColumnSpacing;

    return SizedBox(
      width: columnWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterTitleChip('性别'),
          const SizedBox(height: _kGenderColumnSpacing),
          SizedBox(
            height: gridHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGenderButton('全', null, fixedSize: buttonSize),
                    const SizedBox(height: _kGenderColumnSpacing),
                    _buildGenderButton('非', '其它', fixedSize: buttonSize),
                  ],
                ),
                const SizedBox(width: _kGenderColumnSpacing),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGenderButton('女', '女', fixedSize: buttonSize),
                    const SizedBox(height: _kGenderColumnSpacing),
                    _buildGenderButton('男', '男', fixedSize: buttonSize),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(
    String label,
    String? value, {
    double? fixedSize,
  }) {
    final isSelected = _selectedGender == value;

    Widget buildCircle(double size) {
      return Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    Widget buildInkWell(Widget child) {
      return InkWell(
        onTap: () {
          setState(() {
            _selectedGender = value;
          });
          _applyFilters();
        },
        child: child,
      );
    }

    if (fixedSize != null) {
      return buildInkWell(
        SizedBox(
          width: fixedSize,
          height: fixedSize,
          child: buildCircle(fixedSize),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.biggest.width;
        final double height = constraints.biggest.height;

        double size;
        if (width.isFinite && height.isFinite && width > 0 && height > 0) {
          size = width < height ? width : height;
        } else if (width.isFinite && width > 0) {
          size = width;
        } else if (height.isFinite && height > 0) {
          size = height;
        } else {
          size = _kGenderButtonPreferredSize;
        }

        size = size.clamp(32.0, double.infinity);

        return buildInkWell(
          Center(
            child: SizedBox(
              width: size,
              height: size,
              child: buildCircle(size),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumericFilterGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactRangeFilter(
              label: '热度',
              minController: _popularityMinController,
              maxController: _popularityMaxController,
              exactController: _popularityExactController,
              fuzzy: _popularityFuzzy,
              onFuzzyChanged: (v) => setState(() => _popularityFuzzy = v),
            ),
            const SizedBox(width: 12),
            _buildCompactRangeFilter(
              label: '作品数',
              minController: _workCountMinController,
              maxController: _workCountMaxController,
              exactController: _workCountExactController,
              fuzzy: _workCountFuzzy,
              onFuzzyChanged: (v) => setState(() => _workCountFuzzy = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactRangeFilter(
              label: '评分',
              minController: _ratingMinController,
              maxController: _ratingMaxController,
              exactController: _ratingExactController,
              fuzzy: _ratingFuzzy,
              onFuzzyChanged: (v) => setState(() => _ratingFuzzy = v),
              isDecimal: true,
            ),
            const SizedBox(width: 12),
            _buildAppearanceFilter(),
          ],
        ),
      ],
    );
  }

  Widget _buildYearFilterColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactRangeFilter(
          label: '最早',
          minController: _earliestYearMinController,
          maxController: _earliestYearMaxController,
          exactController: _earliestYearExactController,
          fuzzy: _earliestYearFuzzy,
          onFuzzyChanged: (v) => setState(() => _earliestYearFuzzy = v),
        ),
        const SizedBox(height: 12),
        _buildCompactRangeFilter(
          label: '最晚',
          minController: _latestYearMinController,
          maxController: _latestYearMaxController,
          exactController: _latestYearExactController,
          fuzzy: _latestYearFuzzy,
          onFuzzyChanged: (v) => setState(() => _latestYearFuzzy = v),
        ),
      ],
    );
  }

  Widget _buildCompactRangeFilter({
    required String label,
    required TextEditingController minController,
    required TextEditingController maxController,
    required TextEditingController exactController,
    required bool fuzzy,
    required ValueChanged<bool> onFuzzyChanged,
    bool isDecimal = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitleChipWithHover(
          label,
          isActive: fuzzy,
          onTap: () => onFuzzyChanged(!fuzzy),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: _kFilterInputWidth,
              child: TextField(
                controller: minController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '↓',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.numberWithOptions(
                  decimal: isDecimal,
                ),
                inputFormatters: isDecimal
                    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                    : [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: _kFilterInputWidth,
              child: TextField(
                controller: exactController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '-',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.numberWithOptions(
                  decimal: isDecimal,
                ),
                inputFormatters: isDecimal
                    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                    : [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: _kFilterInputWidth,
              child: TextField(
                controller: maxController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '↑',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.numberWithOptions(
                  decimal: isDecimal,
                ),
                inputFormatters: isDecimal
                    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                    : [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagFilter() {
    // 使用Expanded自动占满可用宽度，与第一行对齐
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildFilterTitleChip('标签'),
            const SizedBox(width: 8),
            SizedBox(
              width: _kTagInputWidth,
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _filterService.searchTags(
                    _allTags,
                    textEditingValue.text,
                  );
                },
                onSelected: (String selection) {
                  if (!_selectedTags.contains(selection)) {
                    setState(() {
                      _selectedTags.add(selection);
                      _tagFieldController?.clear();
                    });
                    _applyFilters();
                  }
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                      _tagFieldController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          hintText: '搜索...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        onEditingComplete: onEditingComplete,
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                          maxWidth: _kTagInputWidth,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              final isHovered = _hoveredSelectedTag == tag;
              final backgroundColor = isHovered
                  ? Colors.grey[300]!
                  : Colors.grey[200]!;
              return MouseRegion(
                onEnter: (_) => setState(() {
                  _hoveredSelectedTag = tag;
                }),
                onExit: (_) => setState(() {
                  if (_hoveredSelectedTag == tag) {
                    _hoveredSelectedTag = null;
                  }
                }),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTags.remove(tag);
                      if (_hoveredSelectedTag == tag) {
                        _hoveredSelectedTag = null;
                      }
                    });
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAppearanceFilter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitleChip('作品'),
        const SizedBox(height: 4),
        SizedBox(
          width: _kFilterInputWidth * 3 + 8,
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return _allAppearances
                  .where(
                    (a) => a.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  )
                  .take(20);
            },
            onSelected: (String selection) {
              setState(() {
                _selectedAppearance = selection;
                _appearanceSearchController.text = selection;
              });
              _applyFilters();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
                  _appearanceSearchController.text = controller.text;
                  return SizedBox(
                    width: _kFilterInputWidth * 3 + 8,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: '搜索...',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        isDense: true,
                        suffixIcon: _selectedAppearance != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _selectedAppearance = null;
                                    _appearanceSearchController.clear();
                                    controller.clear();
                                  });
                                  _applyFilters();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onEditingComplete: onEditingComplete,
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: _kFilterInputWidth * 3 + 8,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.shade300,
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildResultsCards() {
    if (_filteredCharacters.isEmpty) {
      return const Center(
        child: Text(
          '暂无符合条件的角色',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCharacters.length,
      itemBuilder: (context, index) {
        final char = _filteredCharacters[index];
        return _buildCharacterCard(char, index);
      },
    );
  }

  Widget _buildCharacterCard(CharacterInfo char, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final name = char.nameCn.isNotEmpty ? char.nameCn : char.name;
            Clipboard.setData(ClipboardData(text: char.name));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已复制: $name'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 名字
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  char.nameCn.isNotEmpty
                                      ? char.nameCn
                                      : char.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 性别紧跟名字
                              _buildMatchBadge(
                                char.gender,
                                _matchesGender(char.gender),
                              ),
                            ],
                          ),
                          if (char.nameCn.isNotEmpty)
                            Text(
                              char.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 排名置于最右
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index < 3 ? Colors.amber : Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: index < 3 ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      '热度',
                      '${char.popularity}',
                      _matchesPopularity(char.popularity),
                    ),
                    _buildInfoChip(
                      '作品',
                      '${char.workCount}',
                      _matchesWorkCount(char.workCount),
                    ),
                    _buildInfoChip(
                      '评分',
                      char.highestRating.toStringAsFixed(1),
                      _matchesRating(char.highestRating),
                    ),
                    _buildInfoChip(
                      '最早',
                      '${char.earliestAppearance}',
                      _matchesEarliestYear(char.earliestAppearance),
                    ),
                    _buildInfoChip(
                      '最晚',
                      '${char.latestAppearance}',
                      _matchesLatestYear(char.latestAppearance),
                    ),
                  ],
                ),
                if (char.metaTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _buildTagChips(char.metaTags),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBadge(String text, bool matches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: matches ? const Color(0xFF81C784) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: matches ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, bool matches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: matches ? const Color(0xFF81C784) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: matches ? const Color(0xFF66BB6A) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: matches ? Colors.white : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: matches ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签列表(最多10个,匹配的标签置前并标绿)
  List<Widget> _buildTagChips(List<String> tags) {
    // 分离匹配和未匹配的标签
    final matchedTags = <String>[];
    final unmatchedTags = <String>[];

    for (final tag in tags) {
      if (_selectedTags.contains(tag)) {
        matchedTags.add(tag);
      } else {
        unmatchedTags.add(tag);
      }
    }

    // 合并:匹配的在前,取前10个
    final displayTags = [...matchedTags, ...unmatchedTags].take(10);

    return displayTags.map((tag) {
      final isMatched = matchedTags.contains(tag);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isMatched ? const Color(0xFF81C784) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 11,
            color: isMatched ? Colors.white : Colors.black87,
          ),
        ),
      );
    }).toList();
  }

  // 匹配检测方法
  bool _matchesGender(String value) {
    return _selectedGender != null && _selectedGender == value;
  }

  bool _matchesPopularity(int value) {
    if (_popularityExactController.text.isNotEmpty) {
      final exact = int.tryParse(_popularityExactController.text);
      if (exact != null) {
        if (_popularityFuzzy) {
          final fuzzyRange = (exact * 0.1).round();
          return value >= exact - fuzzyRange && value <= exact + fuzzyRange;
        }
        return value == exact;
      }
    }

    final min = int.tryParse(_popularityMinController.text);
    final max = int.tryParse(_popularityMaxController.text);

    if (min != null || max != null) {
      if (_popularityFuzzy) {
        final fuzzyMin = min != null ? (min * 0.8).round() : null;
        final fuzzyMax = max != null ? (max * 1.2).round() : null;

        if (fuzzyMin != null && value < fuzzyMin) return false;
        if (fuzzyMax != null && value > fuzzyMax) return false;
      } else {
        if (min != null && value < min) return false;
        if (max != null && value > max) return false;
      }

      return true;
    }

    return false;
  }

  bool _matchesWorkCount(int value) {
    if (_workCountExactController.text.isNotEmpty) {
      final exact = int.tryParse(_workCountExactController.text);
      return exact != null && value == exact;
    }

    final min = int.tryParse(_workCountMinController.text);
    final max = int.tryParse(_workCountMaxController.text);

    if (min != null || max != null) {
      if (_workCountFuzzy) {
        final fuzzyMin = min != null ? min - 2 : null;
        final fuzzyMax = max != null ? max + 2 : null;

        if (fuzzyMin != null && value < fuzzyMin) return false;
        if (fuzzyMax != null && value > fuzzyMax) return false;
      } else {
        if (min != null && value < min) return false;
        if (max != null && value > max) return false;
      }

      return true;
    }

    return false;
  }

  bool _matchesRating(double value) {
    if (_ratingExactController.text.isNotEmpty) {
      final exact = double.tryParse(_ratingExactController.text);
      if (exact != null) {
        if (_ratingFuzzy) {
          return value >= exact - 0.6 && value <= exact + 0.6;
        }
        return value == exact;
      }
    }

    final min = double.tryParse(_ratingMinController.text);
    final max = double.tryParse(_ratingMaxController.text);

    if (min != null || max != null) {
      if (_ratingFuzzy) {
        final fuzzyMin = min != null ? min - 1.0 : null;
        final fuzzyMax = max != null ? max + 1.0 : null;

        if (fuzzyMin != null && value < fuzzyMin) return false;
        if (fuzzyMax != null && value > fuzzyMax) return false;
      } else {
        if (min != null && value < min) return false;
        if (max != null && value > max) return false;
      }

      return true;
    }

    return false;
  }

  bool _matchesEarliestYear(int value) {
    if (_earliestYearExactController.text.isNotEmpty) {
      final exact = int.tryParse(_earliestYearExactController.text);
      return exact != null && value == exact;
    }

    final min = int.tryParse(_earliestYearMinController.text);
    final max = int.tryParse(_earliestYearMaxController.text);

    if (min != null || max != null) {
      if (_earliestYearFuzzy) {
        final fuzzyMin = min != null ? min + 2 : null;
        final fuzzyMax = max != null ? max - 2 : null;

        if (fuzzyMin != null && value < fuzzyMin) return false;
        if (fuzzyMax != null && value > fuzzyMax) return false;
      } else {
        if (min != null && value < min) return false;
        if (max != null && value > max) return false;
      }

      return true;
    }

    return false;
  }

  bool _matchesLatestYear(int value) {
    if (_latestYearExactController.text.isNotEmpty) {
      final exact = int.tryParse(_latestYearExactController.text);
      return exact != null && value == exact;
    }

    final min = int.tryParse(_latestYearMinController.text);
    final max = int.tryParse(_latestYearMaxController.text);

    if (min != null || max != null) {
      if (_latestYearFuzzy) {
        final fuzzyMin = min != null ? min - 2 : null;
        final fuzzyMax = max != null ? max + 2 : null;

        if (fuzzyMin != null && value < fuzzyMin) return false;
        if (fuzzyMax != null && value > fuzzyMax) return false;
      } else {
        if (min != null && value < min) return false;
        if (max != null && value > max) return false;
      }

      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _popularityMinController.dispose();
    _popularityMaxController.dispose();
    _popularityExactController.dispose();
    _workCountMinController.dispose();
    _workCountMaxController.dispose();
    _workCountExactController.dispose();
    _ratingMinController.dispose();
    _ratingMaxController.dispose();
    _ratingExactController.dispose();
    _earliestYearMinController.dispose();
    _earliestYearMaxController.dispose();
    _earliestYearExactController.dispose();
    _latestYearMinController.dispose();
    _latestYearMaxController.dispose();
    _latestYearExactController.dispose();
    _appearanceSearchController.dispose();
    super.dispose();
  }
}

/// 可hover的Chip组件
class _HoverableChip extends StatefulWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _HoverableChip({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_HoverableChip> createState() => _HoverableChipState();
}

class _HoverableChipState extends State<_HoverableChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isActive
                ? (_isHovered
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFF81C784))
                : (_isHovered ? Colors.grey[300] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: widget.isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
