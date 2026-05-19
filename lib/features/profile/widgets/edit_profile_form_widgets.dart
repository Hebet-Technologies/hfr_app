import 'package:flutter/material.dart';

class EditProfileFormCard extends StatelessWidget {
  const EditProfileFormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        children:
            children
                .expand((child) => [child, const SizedBox(height: 12)])
                .toList()
              ..removeLast(),
      ),
    );
  }
}

class EditProfileInputField extends StatelessWidget {
  const EditProfileInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF101828),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _border(const Color(0xFFE4E7EC)),
        enabledBorder: _border(const Color(0xFFE4E7EC)),
        focusedBorder: _border(const Color(0xFF1F6BFF)),
        errorBorder: _border(const Color(0xFFF04438)),
        focusedErrorBorder: _border(const Color(0xFFF04438)),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }
}

class EditProfileDropdownField extends StatelessWidget {
  const EditProfileDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label::$value'),
      initialValue: value,
      isExpanded: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _border(const Color(0xFFE4E7EC)),
        enabledBorder: _border(const Color(0xFFE4E7EC)),
        focusedBorder: _border(const Color(0xFF1F6BFF)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14, color: Color(0xFF101828)),
              ),
            ),
          )
          .toList(),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }
}
