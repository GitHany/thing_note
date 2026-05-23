import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/tag/domain/tag.dart';

class PdfExporter {
  /// Export a record as PDF
  static Future<String?> exportRecordAsPdf(
    BuildContext context,
    EpisodeRecord record, {
    ThingName? thingName,
    List<Tag>? tags,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Use mounted check from context
      if (!context.mounted) return null;

      // Create a simple HTML file that can be converted to PDF
      final htmlContent = _generateHtmlContent(record, thingName, tags);
      final htmlFile = File('${appDir.path}/temp_$timestamp.html');
      await htmlFile.writeAsString(htmlContent);

      // For now, save as HTML that can be opened in browser
      // In production, you would use a PDF generation library
      return htmlFile.path;
    } catch (e) {
      return null;
    }
  }

  static String _generateHtmlContent(
    EpisodeRecord record,
    ThingName? thingName,
    List<Tag>? tags,
  ) {
    // Note: If context-dependent localization is needed, pass it as a parameter
    const l10n = null; // Placeholder - actual app should pass this in

    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="${l10n?.localeName ?? 'en'}">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<title>${thingName?.name ?? l10n?.recordDetail ?? "Record"}</title>');
    buffer.writeln('<style>');
    buffer.writeln('''
      body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 40px; max-width: 800px; margin: 0 auto; }
      h1 { color: #333; border-bottom: 2px solid #007AFF; padding-bottom: 10px; }
      .section { margin: 20px 0; padding: 15px; background: #f5f5f5; border-radius: 8px; }
      .label { font-weight: bold; color: #666; font-size: 14px; }
      .value { margin-top: 5px; font-size: 16px; }
      .tags { display: flex; gap: 8px; flex-wrap: wrap; }
      .tag { background: #e0e0e0; padding: 4px 12px; border-radius: 16px; font-size: 14px; }
      .note { white-space: pre-wrap; line-height: 1.6; }
      .photos { display: flex; gap: 10px; flex-wrap: wrap; }
      .photo { max-width: 200px; border-radius: 8px; }
      .footer { margin-top: 40px; color: #999; font-size: 12px; text-align: center; }
    ''');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<h1>${thingName?.name ?? l10n?.recordDetail ?? "Record Detail"}</h1>');

    // Basic info
    buffer.writeln('<div class="section">');
    buffer.writeln('<div class="label">${l10n?.occurredAt ?? "Occurred At"}</div>');
    buffer.writeln('<div class="value">${DateFormatter.formatDateTime(record.occurredAt)}</div>');
    buffer.writeln('</div>');

    if (record.durationSec > 0) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<div class="label">${l10n?.duration ?? "Duration"}</div>');
      buffer.writeln('<div class="value">${DurationFormatter.formatShort(record.duration)}</div>');
      buffer.writeln('</div>');
    }

    if (record.hasLocation) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<div class="label">${l10n?.location ?? "Location"}</div>');
      buffer.writeln('<div class="value">${record.address ?? "N/A"}</div>');
      buffer.writeln('</div>');
    }

    if (tags != null && tags.isNotEmpty) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<div class="label">${l10n?.tags ?? "Tags"}</div>');
      buffer.writeln('<div class="tags">');
      for (final tag in tags) {
        buffer.writeln('<span class="tag">${tag.name}</span>');
      }
      buffer.writeln('</div>');
      buffer.writeln('</div>');
    }

    if (record.note.isNotEmpty) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<div class="label">${l10n?.note ?? "Note"}</div>');
      buffer.writeln('<div class="value note">${record.note}</div>');
      buffer.writeln('</div>');
    }

    if (record.hasReminder) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<div class="label">${l10n?.reminder ?? "Reminder"}</div>');
      buffer.writeln('<div class="value">${l10n?.reminderSet ?? "Set"}</div>');
      buffer.writeln('</div>');
    }

    buffer.writeln('<div class="footer">');
    buffer.writeln('${l10n?.createdAt ?? "Created at"} ${DateFormatter.formatDateTime(record.createdAt)}<br>');
    buffer.writeln('ThingNote | ${DateFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('</div>');

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// Export statistics as image
  static Future<Uint8List?> captureWidgetAsImage(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
}