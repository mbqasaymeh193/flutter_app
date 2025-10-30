import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.blue,
      duration: const Duration(seconds: 2),
    ),
  );
}
