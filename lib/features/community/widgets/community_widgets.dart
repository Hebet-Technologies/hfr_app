part of '../views/community_screen.dart';

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _peerBorder),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}

class _QuestionHeaderIconButton extends StatelessWidget {
  const _QuestionHeaderIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: const SizedBox(
        width: 38,
        height: 38,
        child: Icon(Icons.chevron_left_rounded, color: _peerText, size: 28),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _peerPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          minimumSize: const Size(88, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: _textStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _QuestionSearchSuffix extends StatelessWidget {
  const _QuestionSearchSuffix({required this.showClear, required this.onClear});

  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showClear) ...[
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: _peerMuted,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.keyboard_command_key_rounded,
                  size: 12,
                  color: _peerMuted,
                ),
                const SizedBox(width: 2),
                Text(
                  '1',
                  style: _textStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _peerMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewShortcutCard extends StatelessWidget {
  const _OverviewShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _peerBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: _textStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: _textStyle(fontSize: 12, color: _peerMuted)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: _textStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: _textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _peerPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: _textStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _textStyle(fontSize: 12, color: _peerMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _textStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _QuestionInfoColumn extends StatelessWidget {
  const _QuestionInfoColumn({
    required this.label,
    required this.child,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: _textStyle(fontSize: 12, color: _peerMuted)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: _peerSoftBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: _textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _peerPrimary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: _peerPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberPreviewRow extends StatelessWidget {
  const _MemberPreviewRow({required this.members});

  final List<PeerMember> members;

  @override
  Widget build(BuildContext context) {
    final preview = members.take(4).toList();
    return Row(
      children: [
        SizedBox(
          width: preview.length * 22 + 24,
          height: 28,
          child: Stack(
            children: [
              for (var index = 0; index < preview.length; index++)
                Positioned(
                  left: index * 22,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: _peerSoftBlue,
                      child: Text(
                        _initials(preview[index].fullName),
                        style: _textStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _peerPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            members.length > 4
                ? '${members.length} people in this group'
                : preview.map((member) => member.fullName).join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(fontSize: 12, color: _peerMuted),
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _peerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _textStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: _textStyle(fontSize: 13, color: _peerMuted, height: 1.5),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: _peerPrimary,
                side: const BorderSide(color: _peerPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              child: Text(
                actionLabel!,
                style: _textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _peerPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomSheetCard extends StatelessWidget {
  const _BottomSheetCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: child,
        ),
      ),
    );
  }
}

class _BottomSheetTitle extends StatelessWidget {
  const _BottomSheetTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _textStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: _textStyle(fontSize: 13, color: _peerMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: _textStyle(
                      fontSize: 13,
                      color: _peerMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _peerMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _textStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: _textStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: _textStyle(fontSize: 13, color: const Color(0xFF98A2B3)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _AudiencePickerField extends StatelessWidget {
  const _AudiencePickerField({
    required this.label,
    required this.selectedLabels,
    required this.onTap,
  });

  final String label;
  final List<String> selectedLabels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewLabels = selectedLabels.take(3).toList();
    final extraCount = selectedLabels.length - previewLabels.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _textStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _peerBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabels.isEmpty
                        ? 'All staff'
                        : '${selectedLabels.length} selected',
                    style: _textStyle(
                      fontSize: 13,
                      color: selectedLabels.isEmpty ? _peerMuted : _peerText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _peerMuted,
                ),
              ],
            ),
          ),
        ),
        if (previewLabels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...previewLabels.map(
                (label) => _MetaChip(
                  label: label,
                  color: _peerSoftBlue,
                  textColor: _peerPrimary,
                ),
              ),
              if (extraCount > 0)
                _MetaChip(
                  label: '+$extraCount more',
                  color: const Color(0xFFF3F4F6),
                  textColor: _peerMuted,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _textStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          key: ValueKey('$label::$value'),
          // ignore: deprecated_member_use
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _peerPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap, this.isBusy = false});

  final String label;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _peerPrimary,
          disabledBackgroundColor: const Color(0xFF9EC0FF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: _textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard(this.comment);

  final PeerComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _peerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _peerSoftBlue,
            child: Text(
              _initials(comment.author?.fullName ?? 'U'),
              style: _textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _peerPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.author?.fullName ?? 'Community member',
                        style: _textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      _formatRelative(comment.createdAt),
                      style: _textStyle(fontSize: 12, color: _peerMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment.comment,
                  style: _textStyle(
                    fontSize: 13,
                    color: _peerText.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                if (comment.attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: comment.attachments
                        .map(
                          (attachment) => ActionChip(
                            avatar: const Icon(
                              Icons.attach_file_rounded,
                              size: 16,
                              color: _peerPrimary,
                            ),
                            backgroundColor: _peerSoftOrange,
                            label: Text(
                              attachment.originalFileName.isEmpty
                                  ? 'Attachment'
                                  : attachment.originalFileName,
                              style: _textStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB95817),
                              ),
                            ),
                            onPressed: () => _openPeerAttachment(attachment),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.senderName,
  });

  final PeerMessage message;
  final bool isMine;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final background = isMine ? _peerPrimary : Colors.white;
    final textColor = isMine ? Colors.white : _peerText;
    final resolvedSenderName = (senderName ?? message.sender?.fullName ?? '')
        .trim();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isMine ? _peerPrimary : _peerBorder),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine && resolvedSenderName.isNotEmpty) ...[
              Text(
                resolvedSenderName,
                style: _textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isMine ? Colors.white : _peerPrimary,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message.preview,
              style: _textStyle(fontSize: 13, color: textColor, height: 1.45),
            ),
            if (message.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.attachments
                    .map(
                      (attachment) => ActionChip(
                        avatar: Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: isMine ? Colors.white : _peerPrimary,
                        ),
                        backgroundColor: isMine
                            ? Colors.white.withValues(alpha: 0.12)
                            : _peerSoftBlue,
                        label: Text(
                          attachment.originalFileName.isEmpty
                              ? 'Attachment'
                              : attachment.originalFileName,
                          style: _textStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isMine ? Colors.white : _peerPrimary,
                          ),
                        ),
                        onPressed: () => _openPeerAttachment(attachment),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatTime(message.sentAt ?? message.createdAt),
              style: _textStyle(
                fontSize: 11,
                color: isMine
                    ? Colors.white.withValues(alpha: 0.82)
                    : _peerMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.hintText,
    required this.isPosting,
    required this.onSend,
    this.onPickAttachments,
    this.attachments = const [],
    this.onRemoveAttachment,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isPosting;
  final VoidCallback onSend;
  final VoidCallback? onPickAttachments;
  final List<PlatformFile> attachments;
  final void Function(PlatformFile file)? onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _peerBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attachments.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: attachments
                  .map(
                    (file) => _AttachmentChip(
                      fileName: file.name,
                      fileSize: file.size,
                      onRemove: onRemoveAttachment == null || isPosting
                          ? null
                          : () => onRemoveAttachment!(file),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (onPickAttachments != null) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isPosting ? null : onPickAttachments,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _peerBorder),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.attach_file_rounded,
                      color: _peerMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  style: _textStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: _textStyle(
                      fontSize: 13,
                      color: const Color(0xFF98A2B3),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _peerBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _peerBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _peerPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isPosting ? null : onSend,
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: isPosting ? const Color(0xFF9EC0FF) : _peerPrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: isPosting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.fileName,
    required this.fileSize,
    this.onRemove,
  });

  final String fileName;
  final int fileSize;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final sizeLabel = fileSize <= 0 ? '' : _formatBytes(fileSize);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _peerSoftBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E7FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 16,
            color: _peerPrimary,
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _peerPrimary,
                  ),
                ),
                if (sizeLabel.isNotEmpty)
                  Text(
                    sizeLabel,
                    style: _textStyle(fontSize: 10, color: _peerMuted),
                  ),
              ],
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRemove,
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: _peerMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

AppBar _buildDetailAppBar(String title) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleSpacing: 0,
    leadingWidth: 44,
    leading: Builder(
      builder: (context) {
        return IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const AppSvgIcon(
            assetName: 'assets/icons/back_arrow.svg',
            color: _peerText,
            size: 20,
          ),
        );
      },
    ),
    title: Text(
      title,
      style: _textStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );
}

TextStyle _textStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = _peerText,
  double? height,
}) {
  return GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

String _initials(String value) {
  final parts = value
      .split(' ')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'PE';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _formatRelative(DateTime? dateTime) {
  if (dateTime == null) return 'No update';

  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';

  return _formatDate(dateTime);
}

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) return 'Unknown date';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]} ${dateTime.year}';
}

String _formatDateChip(DateTime dateTime) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
}

String _formatTime(DateTime? dateTime) {
  if (dateTime == null) return 'Now';
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

Future<List<PlatformFile>> _pickPeerFiles(
  BuildContext context, {
  List<PlatformFile> existing = const [],
}) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: false,
  );
  if (!context.mounted) {
    return existing;
  }
  if (result == null || result.files.isEmpty) {
    return existing;
  }

  final nextFiles = <PlatformFile>[...existing];
  for (final file in result.files) {
    final alreadyAdded = nextFiles.any(
      (existingFile) =>
          existingFile.path == file.path && existingFile.name == file.name,
    );
    if (alreadyAdded) {
      continue;
    }
    if (file.size > 4 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.name} is larger than 4MB.'),
          backgroundColor: const Color(0xFFD92D20),
        ),
      );
      continue;
    }
    nextFiles.add(file);
  }

  return nextFiles;
}

Future<List<MultipartFile>> _platformFilesToMultipart(
  List<PlatformFile> files,
) async {
  final attachments = <MultipartFile>[];
  for (final file in files) {
    final path = file.path?.trim() ?? '';
    if (path.isEmpty) {
      continue;
    }
    attachments.add(await MultipartFile.fromFile(path, filename: file.name));
  }
  return attachments;
}

String _resolvePeerAttachmentUrl(String filePath) {
  return resolveApiFileUrl(filePath);
}

Future<void> _openPeerAttachment(PeerAttachment attachment) async {
  final resolvedUrl = _resolvePeerAttachmentUrl(attachment.filePath);
  if (resolvedUrl.isEmpty) {
    return;
  }

  final uri = Uri.tryParse(resolvedUrl);
  if (uri == null) {
    return;
  }

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
