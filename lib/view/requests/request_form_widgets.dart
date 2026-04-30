import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/staff_request_models.dart';

const requestBlue = Color(0xFF1F6BFF);
const requestSurface = Color(0xFFF5F7FB);
const requestCard = Colors.white;
const requestBorder = Color(0xFFE8EEF6);
const requestText = Color(0xFF111827);
const requestMuted = Color(0xFF6B7280);

TextStyle requestTextStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = requestText,
  double? height,
}) {
  return GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

InputDecoration inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: requestTextStyle(fontSize: 13, color: const Color(0xFF9CA3AF)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: requestBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: requestBlue),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD14343)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD14343)),
    ),
  );
}

ButtonStyle filledButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: requestBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: requestTextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );
}

Future<DateTime?> pickDate(BuildContext context, {DateTime? initial}) async {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
  );
}

String formatInputDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')} / ${value.month.toString().padLeft(2, '0')} / ${value.year.toString().padLeft(4, '0')}';
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: requestTextStyle(fontSize: 12, color: requestMuted),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator:
                validator ??
                (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
            style: requestTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: inputDecoration(hintText),
          ),
        ],
      ),
    );
  }
}

class AppDropdownField extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String? value;
  final String hintText;
  final List<RequestLookupOption> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: requestTextStyle(fontSize: 12, color: requestMuted),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: inputDecoration(hintText),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      item.label,
                      style: requestTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }
}

class SimpleDropdownField extends StatelessWidget {
  const SimpleDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: requestTextStyle(fontSize: 12, color: requestMuted),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: inputDecoration(hintText),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: requestTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: (selected) =>
                selected == null ? 'This field is required' : null,
          ),
        ],
      ),
    );
  }
}

class DateInputField extends StatelessWidget {
  const DateInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: requestTextStyle(fontSize: 12, color: requestMuted),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: inputDecoration('DD / MM / YYYY').copyWith(
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: requestMuted,
                ),
              ),
              child: Text(
                value == null ? 'DD / MM / YYYY' : formatInputDate(value!),
                style: requestTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value == null ? const Color(0xFF9CA3AF) : requestText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FileUploadField extends StatelessWidget {
  const FileUploadField({
    super.key,
    required this.fileName,
    required this.onBrowse,
    this.title = 'Upload File',
    this.description = 'PDF format.',
  });

  final String? fileName;
  final VoidCallback onBrowse;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName?.trim().isNotEmpty == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasFile
              ? requestBlue.withValues(alpha: 0.35)
              : requestBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasFile
                ? Icons.check_circle_outline_rounded
                : Icons.cloud_upload_outlined,
            color: hasFile ? requestBlue : requestMuted,
          ),
          const SizedBox(height: 10),
          Text(
            hasFile ? fileName! : title,
            textAlign: TextAlign.center,
            style: requestTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: requestTextStyle(fontSize: 11, color: requestMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onBrowse,
            style: OutlinedButton.styleFrom(
              foregroundColor: hasFile ? requestBlue : requestMuted,
              side: BorderSide(color: hasFile ? requestBlue : requestBorder),
            ),
            child: Text(hasFile ? 'Change File' : 'Browse File'),
          ),
        ],
      ),
    );
  }
}

class InlineErrorText extends StatelessWidget {
  const InlineErrorText({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: requestTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFD14343),
        ),
      ),
    );
  }
}

class ParticipantsSelector extends StatelessWidget {
  const ParticipantsSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: requestTextStyle(fontSize: 12, color: requestMuted),
            ),
            const SizedBox(height: 8),
            ParticipantOption(
              label: 'Individual Activity',
              selected: value == 'Individual Activity',
              onTap: () => onChanged('Individual Activity'),
            ),
            const SizedBox(height: 8),
            ParticipantOption(
              label: 'Group Activity',
              selected: value == 'Group Activity',
              onTap: () => onChanged('Group Activity'),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticipantOption extends StatelessWidget {
  const ParticipantOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? requestBlue : requestMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: requestTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadPlaceholder extends StatelessWidget {
  const UploadPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: requestBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: requestMuted),
          const SizedBox(height: 10),
          Text(
            'Upload Documents',
            style: requestTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '.JPEG, PNG, PDF and MP4 formats, up to 50 MB.',
            textAlign: TextAlign.center,
            style: requestTextStyle(fontSize: 11, color: requestMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: requestMuted,
              side: const BorderSide(color: requestBorder),
            ),
            child: const Text('Browse File'),
          ),
        ],
      ),
    );
  }
}

class LoanTerm {
  const LoanTerm({required this.duration, required this.period});

  final int duration;
  final String period;
}

LoanTerm loanTermFromLabel(String label) {
  final numberMatch = RegExp(r'\d+').firstMatch(label);
  final duration = int.tryParse(numberMatch?.group(0) ?? '') ?? 1;
  final normalized = label.toLowerCase();
  final period = normalized.contains('year')
      ? 'YEAR'
      : normalized.contains('week')
      ? 'WEEK'
      : normalized.contains('day')
      ? 'DAY'
      : 'MONTH';
  return LoanTerm(duration: duration, period: period);
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
