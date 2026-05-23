import 'package:intl/intl.dart';
import 'package:thing_note/app/theme/date_format_provider.dart';

class DateFormatter {
  static String _datePattern(DateFormatOption option) {
    switch (option) {
      case DateFormatOption.ymd:
        return 'yyyy-MM-dd';
      case DateFormatOption.mdy:
        return 'MM/dd/yyyy';
      case DateFormatOption.dmy:
        return 'dd/MM/yyyy';
    }
  }

  static String _timePattern(bool use24Hour) {
    return use24Hour ? 'HH:mm' : 'hh:mm a';
  }

  static String formatDateTime(
    DateTime dateTime, {
    DateFormatOption dateFormat = DateFormatOption.ymd,
    bool use24Hour = true,
  }) {
    return DateFormat('${_datePattern(dateFormat)} ${_timePattern(use24Hour)}')
        .format(dateTime);
  }

  static String formatDate(
    DateTime dateTime, {
    DateFormatOption dateFormat = DateFormatOption.ymd,
  }) {
    return DateFormat(_datePattern(dateFormat)).format(dateTime);
  }

  static String formatRelative(
    DateTime dateTime, {
    String justNow = '刚刚',
    String minutesAgo = '分钟前',
    String hoursAgo = '小时前',
    String yesterday = '昨天',
    String daysAgo = '天前',
  }) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return justNow;
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}$minutesAgo';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}$hoursAgo';
    } else if (diff.inDays < 2) {
      return yesterday;
    } else {
      return '${diff.inDays}$daysAgo';
    }
  }

  static String formatDateFull(DateTime dateTime, {
    DateFormatOption dateFormat = DateFormatOption.ymd,
  }) {
    return DateFormat(_datePattern(dateFormat)).format(dateTime);
  }
}
