import 'package:flutter/material.dart';

class NoteInput extends StatelessWidget {
  final TextEditingController controller;

  const NoteInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isWideScreen = screenWidth > 600;

    // Responsive sizing
    final minLines = isSmallScreen ? 2 : 3;
    final maxLines = isSmallScreen ? 4 : 5;
    final contentPadding = isSmallScreen ? 10.0 : (isWideScreen ? 16.0 : 12.0);
    final fontSize = isSmallScreen ? 13.0 : 14.0;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      textInputAction: TextInputAction.newline,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        labelText: '备注',
        alignLabelWithHint: true,
        contentPadding: EdgeInsets.fromLTRB(contentPadding, contentPadding, contentPadding, 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
