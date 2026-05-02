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
    final selectedLabel = items
        .firstWhereOrNull((item) => item.id == value)
        ?.label;

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
          FormField<String>(
            key: ValueKey(value),
            initialValue: value,
            validator: validator,
            builder: (field) => _PickerField(
              fieldKey: ValueKey('request-picker-$label'),
              text: selectedLabel,
              hintText: hintText,
              errorText: field.errorText,
              onTap: () async {
                final selected = await _showOptionPicker<RequestLookupOption>(
                  context: context,
                  title: label,
                  items: items,
                  itemLabel: (item) => item.label,
                  selectedId: value,
                  itemId: (item) => item.id,
                );
                if (selected == null) return;
                field.didChange(selected.id);
                onChanged(selected.id);
              },
            ),
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
          FormField<String>(
            key: ValueKey(value),
            initialValue: value,
            validator: (selected) =>
                selected == null ? 'This field is required' : null,
            builder: (field) => _PickerField(
              fieldKey: ValueKey('request-picker-$label'),
              text: value,
              hintText: hintText,
              errorText: field.errorText,
              onTap: () async {
                final selected = await _showOptionPicker<String>(
                  context: context,
                  title: label,
                  items: items,
                  itemLabel: (item) => item,
                  selectedId: value,
                  itemId: (item) => item,
                );
                if (selected == null) return;
                field.didChange(selected);
                onChanged(selected);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.text,
    required this.hintText,
    required this.errorText,
    required this.onTap,
    this.fieldKey,
  });

  final Key? fieldKey;
  final String? text;
  final String hintText;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = text != null && text!.trim().isNotEmpty;

    return GestureDetector(
      key: fieldKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: InputDecorator(
        decoration: inputDecoration(hintText).copyWith(
          errorText: errorText,
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: requestMuted,
          ),
        ),
        child: Text(
          hasValue ? text! : hintText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: requestTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasValue ? requestText : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

Future<T?> _showOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) itemLabel,
  required String Function(T item) itemId,
  required String? selectedId,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OptionPickerSheet<T>(
      title: title,
      items: items,
      itemLabel: itemLabel,
      itemId: itemId,
      selectedId: selectedId,
    ),
  );
}

class _OptionPickerSheet<T> extends StatefulWidget {
  const _OptionPickerSheet({
    required this.title,
    required this.items,
    required this.itemLabel,
    required this.itemId,
    required this.selectedId,
  });

  final String title;
  final List<T> items;
  final String Function(T item) itemLabel;
  final String Function(T item) itemId;
  final String? selectedId;

  @override
  State<_OptionPickerSheet<T>> createState() => _OptionPickerSheetState<T>();
}

class _OptionPickerSheetState<T> extends State<_OptionPickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? widget.items
        : widget.items
              .where(
                (item) => widget
                    .itemLabel(item)
                    .toLowerCase()
                    .contains(normalizedQuery),
              )
              .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DEE8),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: requestTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    style: requestTextStyle(fontSize: 14),
                    decoration: inputDecoration('Search ${widget.title}'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No options found',
                        style: requestTextStyle(
                          fontSize: 13,
                          color: requestMuted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final id = widget.itemId(item);
                        final selected = id == widget.selectedId;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          title: Text(
                            widget.itemLabel(item),
                            style: requestTextStyle(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selected ? requestBlue : requestText,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: requestBlue,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemCount: filtered.length,
                    ),
            ),
          ],
        ),
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
          color: hasFile ? requestBlue.withValues(alpha: 0.35) : requestBorder,
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
