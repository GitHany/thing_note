import 'package:flutter/material.dart';

class NoteInput extends StatelessWidget {
  final TextEditingController controller;

  const NoteInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 5,
      minLines: 3,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        labelText: '备注',
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
