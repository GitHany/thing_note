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
      decoration: const InputDecoration(
        labelText: '备注',
        alignLabelWithHint: true,
      ),
    );
  }
}
