// Spring Cron 表达式解析与最近执行时间计算。
// 支持 Spring Boot @Scheduled 常用的 6 段格式：秒 分 时 日 月 周。

class CronValidationResult {
  final bool isValid;
  final String? error;

  const CronValidationResult.valid()
      : isValid = true,
        error = null;

  const CronValidationResult.invalid(this.error) : isValid = false;
}

class CronExpression {
  static const Map<String, int> _monthNames = {
    'JAN': 1,
    'FEB': 2,
    'MAR': 3,
    'APR': 4,
    'MAY': 5,
    'JUN': 6,
    'JUL': 7,
    'AUG': 8,
    'SEP': 9,
    'OCT': 10,
    'NOV': 11,
    'DEC': 12,
  };

  static const Map<String, int> _weekNames = {
    'MON': 1,
    'TUE': 2,
    'WED': 3,
    'THU': 4,
    'FRI': 5,
    'SAT': 6,
    'SUN': 7,
  };

  final String source;
  final _CronField _seconds;
  final _CronField _minutes;
  final _CronField _hours;
  final _CronField _daysOfMonth;
  final _CronField _months;
  final _CronField _daysOfWeek;

  CronExpression._({
    required this.source,
    required _CronField seconds,
    required _CronField minutes,
    required _CronField hours,
    required _CronField daysOfMonth,
    required _CronField months,
    required _CronField daysOfWeek,
  })  : _seconds = seconds,
        _minutes = minutes,
        _hours = hours,
        _daysOfMonth = daysOfMonth,
        _months = months,
        _daysOfWeek = daysOfWeek;

  factory CronExpression.parse(String input) {
    final normalized = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      throw const FormatException('请输入 cron 表达式');
    }

    final fields = normalized.split(' ');
    if (fields.length != 6) {
      throw FormatException(
        'Spring Boot cron 需要 6 段：秒 分 时 日 月 周，当前为 ${fields.length} 段',
      );
    }

    return CronExpression._(
      source: normalized,
      seconds: _CronField.parse(fields[0], min: 0, max: 59, label: '秒'),
      minutes: _CronField.parse(fields[1], min: 0, max: 59, label: '分钟'),
      hours: _CronField.parse(fields[2], min: 0, max: 23, label: '小时'),
      daysOfMonth: _CronField.parse(
        fields[3],
        min: 1,
        max: 31,
        label: '日期',
        allowQuestion: true,
      ),
      months: _CronField.parse(
        fields[4],
        min: 1,
        max: 12,
        label: '月份',
        names: _monthNames,
      ),
      daysOfWeek: _CronField.parse(
        fields[5],
        min: 1,
        max: 7,
        label: '星期',
        names: _weekNames,
        allowQuestion: true,
        mapZeroToSeven: true,
      ),
    );
  }

  static CronValidationResult validate(String input) {
    try {
      CronExpression.parse(input);
      return const CronValidationResult.valid();
    } on FormatException catch (e) {
      return CronValidationResult.invalid(e.message);
    } catch (e) {
      return CronValidationResult.invalid(e.toString());
    }
  }

  List<DateTime> nextTimes(DateTime from, {int count = 5}) {
    final result = <DateTime>[];
    var cursor = from;
    for (var i = 0; i < count; i++) {
      final next = nextAfter(cursor);
      if (next == null) break;
      result.add(next);
      cursor = next;
    }
    return result;
  }

  DateTime? nextAfter(DateTime from) {
    final start = _floorToSecond(from).add(const Duration(seconds: 1));
    var day = DateTime(start.year, start.month, start.day);

    // 核心计算按“天”推进，单日内再枚举时/分/秒，避免逐秒扫描导致年度任务卡顿。
    for (var offset = 0; offset < 366 * 8; offset++) {
      final isStartDay = _isSameDay(day, start);
      if (_months.contains(day.month) && _matchesDay(day)) {
        final candidate = _firstTimeOnDay(day, isStartDay ? start : null);
        if (candidate != null) return candidate;
      }
      day = day.add(const Duration(days: 1));
    }

    return null;
  }

  bool _matchesDay(DateTime day) {
    final domRestricted = _daysOfMonth.isRestricted;
    final dowRestricted = _daysOfWeek.isRestricted;
    final domMatches = !domRestricted || _daysOfMonth.contains(day.day);
    final dowMatches = !dowRestricted || _daysOfWeek.contains(day.weekday);

    // Spring cron 中 ? 表示“不指定”。当日期和星期都指定时，按 cron 惯例满足任一条件即可。
    if (domRestricted && dowRestricted) return domMatches || dowMatches;
    return domMatches && dowMatches;
  }

  DateTime? _firstTimeOnDay(DateTime day, DateTime? lowerBound) {
    for (final hour in _hours.sortedValues) {
      if (lowerBound != null && hour < lowerBound.hour) continue;
      for (final minute in _minutes.sortedValues) {
        if (lowerBound != null &&
            hour == lowerBound.hour &&
            minute < lowerBound.minute) {
          continue;
        }
        for (final second in _seconds.sortedValues) {
          if (lowerBound != null &&
              hour == lowerBound.hour &&
              minute == lowerBound.minute &&
              second < lowerBound.second) {
            continue;
          }
          return DateTime(day.year, day.month, day.day, hour, minute, second);
        }
      }
    }
    return null;
  }

  static DateTime _floorToSecond(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CronField {
  final String raw;
  final int min;
  final int max;
  final String label;
  final bool noSpecific;
  final Set<int> values;

  _CronField._({
    required this.raw,
    required this.min,
    required this.max,
    required this.label,
    required this.noSpecific,
    required this.values,
  });

  bool get isRestricted => !noSpecific && values.length != max - min + 1;

  List<int> get sortedValues {
    final sorted = values.toList()..sort();
    return sorted;
  }

  bool contains(int value) => values.contains(value);

  static _CronField parse(
    String raw, {
    required int min,
    required int max,
    required String label,
    Map<String, int> names = const {},
    bool allowQuestion = false,
    bool mapZeroToSeven = false,
  }) {
    final text = raw.trim().toUpperCase();
    if (text.isEmpty) throw FormatException('$label 字段不能为空');
    if (RegExp(r'[LW#]').hasMatch(text)) {
      throw FormatException('$label 字段暂不支持 L、W、# 等 Quartz 高级语法');
    }
    if (text == '?') {
      if (!allowQuestion) throw FormatException('$label 字段不能使用 ?');
      return _CronField._(
        raw: text,
        min: min,
        max: max,
        label: label,
        noSpecific: true,
        values: _range(min, max),
      );
    }

    final values = <int>{};
    for (final part in text.split(',')) {
      if (part.isEmpty) throw FormatException('$label 字段列表语法不完整');
      values.addAll(_parsePart(
        part,
        min: min,
        max: max,
        label: label,
        names: names,
        mapZeroToSeven: mapZeroToSeven,
      ));
    }

    return _CronField._(
      raw: text,
      min: min,
      max: max,
      label: label,
      noSpecific: false,
      values: values,
    );
  }

  static Set<int> _parsePart(
    String part, {
    required int min,
    required int max,
    required String label,
    required Map<String, int> names,
    required bool mapZeroToSeven,
  }) {
    final stepPieces = part.split('/');
    if (stepPieces.length > 2) throw FormatException('$label 字段步进语法不正确');

    final base = stepPieces.first;
    final step = stepPieces.length == 2 ? int.tryParse(stepPieces.last) : 1;
    if (step == null || step <= 0) throw FormatException('$label 字段步进必须为正整数');
    if (base == '?') throw FormatException('$label 字段 ? 不能搭配步进');

    final bounds = _parseBounds(
      base,
      min: min,
      max: max,
      label: label,
      names: names,
      mapZeroToSeven: mapZeroToSeven,
    );
    final values = <int>{};
    for (var value = bounds.start; value <= bounds.end; value += step) {
      values.add(value);
    }
    return values;
  }

  static _Bounds _parseBounds(
    String base, {
    required int min,
    required int max,
    required String label,
    required Map<String, int> names,
    required bool mapZeroToSeven,
  }) {
    if (base == '*') return _Bounds(min, max);
    if (base.contains('-')) {
      final pieces = base.split('-');
      if (pieces.length != 2 || pieces.first.isEmpty || pieces.last.isEmpty) {
        throw FormatException('$label 字段范围语法不正确');
      }
      final start = _parseValue(
        pieces.first,
        min: min,
        max: max,
        label: label,
        names: names,
        mapZeroToSeven: mapZeroToSeven,
      );
      final end = _parseValue(
        pieces.last,
        min: min,
        max: max,
        label: label,
        names: names,
        mapZeroToSeven: mapZeroToSeven,
      );
      if (start > end) throw FormatException('$label 字段范围起点不能大于终点');
      return _Bounds(start, end);
    }

    final value = _parseValue(
      base,
      min: min,
      max: max,
      label: label,
      names: names,
      mapZeroToSeven: mapZeroToSeven,
    );
    return _Bounds(value, value);
  }

  static int _parseValue(
    String text, {
    required int min,
    required int max,
    required String label,
    required Map<String, int> names,
    required bool mapZeroToSeven,
  }) {
    final named = names[text];
    final value = named ?? int.tryParse(text);
    if (value == null) throw FormatException('$label 字段包含无法识别的值：$text');

    final normalized = mapZeroToSeven && value == 0 ? 7 : value;
    if (normalized < min || normalized > max) {
      throw FormatException('$label 字段值 $text 超出允许范围 $min-$max');
    }
    return normalized;
  }

  static Set<int> _range(int start, int end) {
    return {for (var value = start; value <= end; value++) value};
  }
}

class _Bounds {
  final int start;
  final int end;

  const _Bounds(this.start, this.end);
}
