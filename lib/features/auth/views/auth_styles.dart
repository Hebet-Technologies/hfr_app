import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const authPrimary = Color(0xFF1463F3);
const authTextPrimary = Color(0xFF2F2F2F);
const authTextSecondary = Color(0xFF7C7C7C);
const authBorder = Color(0xFFE7E7E7);
const authDivider = Color(0xFFF1F1F1);
const authIconColor = Color(0xFFB3B3B3);

TextStyle authTextStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = authTextPrimary,
  double? height,
}) {
  return GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

Widget authBrandImage({double width = 112}) {
  return Image.asset(
    'assets/images/logo.png',
    width: width,
    fit: BoxFit.contain,
  );
}

Widget authHeaderSection({
  required String title,
  required String subtitle,
  bool showDivider = true,
}) {
  return Column(
    children: [
      Center(child: authBrandImage()),
      const SizedBox(height: 22),
      Text(
        title,
        textAlign: TextAlign.center,
        style: authTextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: authTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: authTextSecondary,
        ),
      ),
      if (showDivider) ...[
        const SizedBox(height: 24),
        const Divider(height: 1, color: authDivider),
      ],
    ],
  );
}

Widget authLabeledField({
  required String label,
  required Widget child,
  EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 16),
}) {
  return Padding(
    padding: margin,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: authTextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

InputDecoration authInputDecoration({
  required String hintText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: authTextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: authTextSecondary,
    ),
    prefixIcon: Icon(prefixIcon, color: authIconColor, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: authBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: authPrimary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE53935)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.4),
    ),
  );
}

ButtonStyle authPrimaryButtonStyle({Color backgroundColor = authPrimary}) {
  return ElevatedButton.styleFrom(
    backgroundColor: backgroundColor,
    disabledBackgroundColor: backgroundColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: authTextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  );
}

TextStyle authUnderlineLinkStyle({Color color = authTextSecondary}) {
  return authTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color,
  ).copyWith(decoration: TextDecoration.underline, decorationColor: color);
}

AppBar authAppBar({required BuildContext context, required String title}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: authTextPrimary),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: authTextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    ),
  );
}
