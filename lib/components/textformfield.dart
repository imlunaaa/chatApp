import 'package:flutter/material.dart';

InputDecoration textInputDecoration({
  required String label,
  IconData? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
}) {
  return InputDecoration(
    errorText: errorText,
    filled: true,
    labelText: label,

    prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
    suffixIcon: suffixIcon,
  );
}
