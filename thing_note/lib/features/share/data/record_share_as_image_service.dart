import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

/// 记录分享为图片服务
class RecordShareAsImageService {
  /// 将记录转换为分享图片
  static Future<File> recordToImage(
    EpisodeRecord record, {
    String? thingName,
    List<String>? tagNames,
    double width = 1080,
    double height = 1920,
  }) async {
    // 创建画布
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;

    // 绘制背景
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // 绘制顶部装饰
    _drawTopDecoration(canvas, width);

    // 绘制日期
    _drawDate(canvas, record.occurredAt, width);

    // 绘制标题
    _drawTitle(canvas, thingName ?? 'Record', width);

    // 绘制笔记内容
    if (record.note.isNotEmpty) {
      _drawNote(canvas, record.note, width);
    }

    // 绘制元信息
    _drawMetaInfo(canvas, record, width);

    // 绘制媒体指示器
    _drawMediaIndicators(canvas, record, width, height);

    // 绘制底部
    _drawFooter(canvas, width, height);

    // 完成绘制
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to generate image');
    }

    // 保存文件
    final dir = await getTemporaryDirectory();
    final fileName = 'thing_note_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file;
  }

  /// 分享记录图片
  static Future<void> shareRecordImage(
    EpisodeRecord record, {
    String? thingName,
    List<String>? tagNames,
  }) async {
    final imageFile = await recordToImage(
      record,
      thingName: thingName,
      tagNames: tagNames,
    );

    await Share.shareXFiles(
      [XFile(imageFile.path)],
      text: 'Thing Note Record',
    );
  }

  /// 创建多记录分享图片
  static Future<File> multipleRecordsToImage(
    List<EpisodeRecord> records, {
    String title = 'My Thing Note Records',
    double width = 1080,
  }) async {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    // 计算高度
    const itemHeight = 200.0;
    const headerHeight = 300.0;
    const footerHeight = 150.0;
    final totalHeight = headerHeight + (records.length * itemHeight) + footerHeight;

    // 创建画布
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;

    // 绘制背景
    canvas.drawRect(Rect.fromLTWH(0, 0, width, totalHeight), paint);

    // 绘制渐变背景
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ).createShader(Rect.fromLTWH(0, 0, width, headerHeight));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, headerHeight), gradientPaint);

    // 绘制标题
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: width - 80);
    titlePainter.paint(canvas, const Offset(40, 60));

    // 绘制统计信息
    final statsPainter = TextPainter(
      text: TextSpan(
        text: '${records.length} records',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 24,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    statsPainter.layout();
    statsPainter.paint(canvas, const Offset(40, 130));

    // 绘制记录列表
    var yOffset = headerHeight + 20;
    for (var i = 0; i < records.length; i++) {
      final record = records[i];

      // 绘制分隔线
      if (i > 0) {
        canvas.drawLine(
          Offset(40, yOffset),
          Offset(width - 40, yOffset),
          Paint()..color = Colors.grey.withOpacity(0.3),
        );
      }
      yOffset += 20;

      // 绘制日期
      final dateText = dateFormat.format(record.occurredAt);
      final datePainter = TextPainter(
        text: TextSpan(
          text: dateText,
          style: const TextStyle(
            color: Color(0xFF667eea),
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      datePainter.layout();
      datePainter.paint(canvas, Offset(40, yOffset));
      yOffset += 50;

      // 绘制时间
      final timeText = timeFormat.format(record.occurredAt);
      final timePainter = TextPainter(
        text: TextSpan(
          text: timeText,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 20,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      timePainter.layout();
      timePainter.paint(canvas, Offset(40, yOffset));
      yOffset += 40;

      // 绘制笔记摘要
      if (record.note.isNotEmpty) {
        final noteText = record.note.length > 80
            ? '${record.note.substring(0, 80)}...'
            : record.note;
        final notePainter = TextPainter(
          text: TextSpan(
            text: noteText,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 22,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
          maxLines: 2,
        );
        notePainter.layout(maxWidth: width - 80);
        notePainter.paint(canvas, Offset(40, yOffset));
        yOffset += 70;
      }

      // 绘制媒体指示器
      var xOffset = 40.0;
      if (record.photoPaths.isNotEmpty) {
        _drawMediaChip(canvas, Offset(xOffset, yOffset), Icons.photo, record.photoPaths.length);
        xOffset += 100;
      }
      if (record.audioPaths.isNotEmpty) {
        _drawMediaChip(canvas, Offset(xOffset, yOffset), Icons.mic, record.audioPaths.length);
        xOffset += 100;
      }
      if (record.videoPaths.isNotEmpty) {
        _drawMediaChip(canvas, Offset(xOffset, yOffset), Icons.videocam, record.videoPaths.length);
        xOffset += 100;
      }

      yOffset += 80;
    }

    // 绘制底部
    canvas.drawRect(
      Rect.fromLTWH(0, totalHeight - footerHeight, width, footerHeight),
      Paint()..color = const Color(0xFFF8F9FA),
    );

    final footerPainter = TextPainter(
      text: const TextSpan(
        text: 'Created with Thing Note',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 18,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    footerPainter.layout();
    footerPainter.paint(
      canvas,
      Offset((width - footerPainter.width) / 2, totalHeight - footerHeight + 60),
    );

    // 完成绘制
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), totalHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to generate image');
    }

    // 保存文件
    final dir = await getTemporaryDirectory();
    final fileName = 'thing_note_summary_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file;
  }

  static void _drawTopDecoration(Canvas canvas, double width) {
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ).createShader(Rect.fromLTWH(0, 0, width, 400));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, 400), gradientPaint);
  }

  static void _drawDate(Canvas canvas, DateTime date, double width) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    final datePainter = TextPainter(
      text: TextSpan(
        text: dateFormat.format(date),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    datePainter.layout();
    datePainter.paint(canvas, const Offset(40, 80));

    final timePainter = TextPainter(
      text: TextSpan(
        text: timeFormat.format(date),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 22,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    timePainter.layout();
    timePainter.paint(canvas, const Offset(40, 120));
  }

  static void _drawTitle(Canvas canvas, String title, double width) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: width - 80);
    titlePainter.paint(canvas, const Offset(40, 200));
  }

  static void _drawNote(Canvas canvas, String note, double width) {
    final notePainter = TextPainter(
      text: TextSpan(
        text: note,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 28,
          height: 1.5,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 10,
    );
    notePainter.layout(maxWidth: width - 80);
    notePainter.paint(canvas, const Offset(40, 450));
  }

  static void _drawMetaInfo(Canvas canvas, EpisodeRecord record, double width) {
    var yOffset = 750.0;

    if (record.durationSec > 0) {
      _drawInfoRow(canvas, Icons.timer, 'Duration: ${_formatDuration(record.durationSec)}', yOffset, width);
      yOffset += 60;
    }

    if (record.address != null && record.address!.isNotEmpty) {
      _drawInfoRow(canvas, Icons.location_on, record.address!, yOffset, width);
      yOffset += 60;
    }

    if (record.isFavorite) {
      _drawInfoRow(canvas, Icons.star, 'Favorite', yOffset, width);
      yOffset += 60;
    }

    if (record.hasReminder) {
      _drawInfoRow(canvas, Icons.notifications, 'Has Reminder', yOffset, width);
      yOffset += 60;
    }
  }

  static void _drawInfoRow(Canvas canvas, IconData icon, String text, double yOffset, double width) {
    // 绘制图标
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontFamily != icon.codePoint.toString() ? 'cupertino_icons' : null,
          color: const Color(0xFF667eea),
          fontSize: 28,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(40, yOffset));

    // 绘制文本
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 24,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width - 120);
    textPainter.paint(canvas, Offset(90, yOffset + 2));
  }

  static void _drawMediaIndicators(Canvas canvas, EpisodeRecord record, double width, double height) {
    final yOffset = height - 300;
    var xOffset = 40.0;

    if (record.photoPaths.isNotEmpty) {
      _drawMediaChip(canvas, Offset(xOffset, yOffset), Icons.photo, record.photoPaths.length);
      xOffset += 150;
    }
    if (record.audioPaths.isNotEmpty) {
      _drawMediaChip(canvas, Offset(xOffset, yOffset), Icons.mic, record.audioPaths.length);
      xOffset += 150;
    }
    if (record.videoPaths.isNotEmpty) {
      _drawMediaChip(canvas, Offset(xOffset, yOffset), Icons.videocam, record.videoPaths.length);
      xOffset += 150;
    }
    if (record.documentPaths.isNotEmpty) {
      _drawMediaChip(canvas, Offset(xOffset, yOffset), Icons.insert_drive_file, record.documentPaths.length);
    }
  }

  static void _drawMediaChip(Canvas canvas, Offset offset, IconData icon, int count) {
    // 绘制背景
    final bgPaint = Paint()..color = const Color(0xFFF0F4FF);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offset.dx, offset.dy, 130, 50),
      const Radius.circular(25),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 绘制图标
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontFamily != icon.codePoint.toString() ? 'cupertino_icons' : null,
          color: const Color(0xFF667eea),
          fontSize: 24,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(offset.dx + 15, offset.dy + 13));

    // 绘制数量
    final countPainter = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(
          color: Color(0xFF667eea),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    countPainter.layout();
    countPainter.paint(canvas, Offset(offset.dx + 55, offset.dy + 12));
  }

  static void _drawFooter(Canvas canvas, double width, double height) {
    // 绘制底部背景
    canvas.drawRect(
      Rect.fromLTWH(0, height - 120, width, 120),
      Paint()..color = const Color(0xFFF8F9FA),
    );

    // 绘制应用名称
    final footerPainter = TextPainter(
      text: const TextSpan(
        text: 'Thing Note',
        style: TextStyle(
          color: Color(0xFF667eea),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    footerPainter.layout();
    footerPainter.paint(
      canvas,
      Offset((width - footerPainter.width) / 2, height - 80),
    );
  }

  static String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '${mins}m ${secs}s';
    }
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }
}