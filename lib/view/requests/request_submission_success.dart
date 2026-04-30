import 'package:flutter/material.dart';

import '../../model/staff_request_models.dart';
import 'request_form_widgets.dart';

class RequestSubmissionSuccessScreen extends StatelessWidget {
  const RequestSubmissionSuccessScreen({super.key, required this.request});

  final StaffRequestRecord request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF5),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: requestBlue,
                  size: 54,
                ),
                const SizedBox(height: 14),
                Text(
                  '${request.type.label} Request Submitted',
                  textAlign: TextAlign.center,
                  style: requestTextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Request submitted successfully.\nReference Number ${request.referenceNumber ?? 'Pending'}',
                  textAlign: TextAlign.center,
                  style: requestTextStyle(
                    fontSize: 13,
                    color: requestMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: filledButtonStyle(),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Back to Requests'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
