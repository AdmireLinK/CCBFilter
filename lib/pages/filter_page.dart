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

  bool _isLoading = true;
  bool _useAnimeOnly = true; // true=Anime.json(番剧), false=All.json(番剧+游戏)
  static const int _maxResults = 10;

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

  final TextEditingController _tagSearchController = TextEditingController();
  final TextEditingController _appearanceSearchController =
      TextEditingController();

  final List<String> _selectedTags = [];
  String? _selectedAppearance;

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
      _filteredCharacters = List.from(_allCharacters.take(_maxResults));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          // 清空筛选按钮
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('清空筛选'),
          ),
          const SizedBox(width: 16),
          // 模式切换
          const Text('番剧', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Switch(
            value: !_useAnimeOnly, // false=番剧, true=番剧+游戏
            onChanged: (value) => _toggleDataSource(),
            activeThumbColor: Colors.green,
          ),
          const SizedBox(width: 8),
          const Text('番剧+游戏', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 16),
        ],
      ),
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
                '筛选条件',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 性别筛选组
          _buildFilterGroup(child: _buildGenderFilter()),
          const SizedBox(height: 12),
          // 数值筛选组
          _buildFilterGroup(
            child: Column(
              children: [
                // 第一行: 热度 + 作品数
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactRangeFilter(
                        label: '热度',
                        minController: _popularityMinController,
                        maxController: _popularityMaxController,
                        exactController: _popularityExactController,
                        fuzzy: _popularityFuzzy,
                        onFuzzyChanged: (v) =>
                            setState(() => _popularityFuzzy = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCompactRangeFilter(
                        label: '作品数',
                        minController: _workCountMinController,
                        maxController: _workCountMaxController,
                        exactController: _workCountExactController,
                        fuzzy: _workCountFuzzy,
                        onFuzzyChanged: (v) =>
                            setState(() => _workCountFuzzy = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 第二行: 评分
                _buildCompactRangeFilter(
                  label: '评分',
                  minController: _ratingMinController,
                  maxController: _ratingMaxController,
                  exactController: _ratingExactController,
                  fuzzy: _ratingFuzzy,
                  onFuzzyChanged: (v) => setState(() => _ratingFuzzy = v!),
                  isDecimal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 年份筛选组
          _buildFilterGroup(
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactRangeFilter(
                    label: '最早',
                    minController: _earliestYearMinController,
                    maxController: _earliestYearMaxController,
                    exactController: _earliestYearExactController,
                    fuzzy: _earliestYearFuzzy,
                    onFuzzyChanged: (v) =>
                        setState(() => _earliestYearFuzzy = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactRangeFilter(
                    label: '最晚',
                    minController: _latestYearMinController,
                    maxController: _latestYearMaxController,
                    exactController: _latestYearExactController,
                    fuzzy: _latestYearFuzzy,
                    onFuzzyChanged: (v) =>
                        setState(() => _latestYearFuzzy = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 标签和作品筛选组
          _buildFilterGroup(
            child: Row(
              children: [
                Expanded(child: _buildTagFilter()),
                const SizedBox(width: 16),
                Expanded(child: _buildAppearanceFilter()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 筛选条件组容器(带圆角边框)
  Widget _buildFilterGroup({required Widget child}) {
    return Container(
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

  Widget _buildGenderFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '性别',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildGenderButton('全', null),
            const SizedBox(width: 4),
            _buildGenderButton('男', '男'),
            const SizedBox(width: 4),
            _buildGenderButton('女', '女'),
            const SizedBox(width: 4),
            _buildGenderButton('非', '其它'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderButton(String label, String? value) {
    final isSelected = _selectedGender == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
        _applyFilters();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
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
      ),
    );
  }

  Widget _buildCompactRangeFilter({
    required String label,
    required TextEditingController minController,
    required TextEditingController maxController,
    required TextEditingController exactController,
    required bool fuzzy,
    required ValueChanged<bool?> onFuzzyChanged,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => onFuzzyChanged(!fuzzy),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '模糊',
                style: TextStyle(
                  fontSize: 12,
                  color: fuzzy ? Colors.green : Colors.grey,
                  fontWeight: fuzzy ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
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
            Expanded(
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
            Expanded(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '标签',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _filterService.searchTags(_allTags, textEditingValue.text);
          },
          onSelected: (String selection) {
            if (!_selectedTags.contains(selection)) {
              setState(() {
                _selectedTags.add(selection);
                _tagSearchController.clear();
              });
              _applyFilters();
            }
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                return TextField(
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
                    suffixIcon: _selectedTags.isNotEmpty
                        ? PopupMenuButton<String>(
                            icon: const Icon(Icons.list, size: 18),
                            itemBuilder: (context) => _selectedTags
                                .map(
                                  (tag) => PopupMenuItem<String>(
                                    value: tag,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              _selectedTags.remove(tag);
                                            });
                                            _applyFilters();
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          )
                        : null,
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
                    maxWidth: 200,
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
        // 已选标签展示
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedTags.remove(tag);
                  });
                  _applyFilters();
                },
                backgroundColor: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAppearanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '作品',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Autocomplete<String>(
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
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: _selectedAppearance ?? '搜索...',
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
                    maxWidth: 200,
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
    _tagSearchController.dispose();
    _appearanceSearchController.dispose();
    super.dispose();
  }
}
