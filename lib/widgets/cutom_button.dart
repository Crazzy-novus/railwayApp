import 'package:flutter/material.dart';
import '../constants/global_variables.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final double radius;
  final Color? color;
  final VoidCallback onTap;
  const CustomButton({super.key, required this.text, required this.onTap, this.radius = 50, this.color});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: color ?? GlobalVariables.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: Text(text, style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color == null ? Colors.white : Colors.black),
        )
    );
  }
}
