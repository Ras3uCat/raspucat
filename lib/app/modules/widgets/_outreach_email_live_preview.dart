part of 'admin_outreach_widget.dart';

String _toHtml(String plainText) {
  final lines = plainText.split('\n');
  final buffer = StringBuffer();
  final bulletLines = <String>[];

  void flushBullets() {
    if (bulletLines.isEmpty) return;
    buffer.write('<ul>');
    for (final b in bulletLines) {
      buffer.write('<li>${b.trim()}</li>');
    }
    buffer.write('</ul>');
    bulletLines.clear();
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      flushBullets();
      continue;
    }
    if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
      bulletLines.add(trimmed.substring(2));
    } else {
      flushBullets();
      buffer.write('<p>$trimmed</p>');
    }
  }
  flushBullets();
  return buffer.toString();
}

/// Renders plain email text (blank-line-separated paragraphs, `- ` bullets)
/// as Flutter widgets. Used both in the live edit preview and as the iframe fallback.
class _EmailBodyLivePreview extends StatelessWidget {
  const _EmailBodyLivePreview({required this.text});
  final String text;

  static const _bodyStyle = TextStyle(
    color: Color(0xFFCDD8E3),
    fontSize: ESizes.fontSizeSm,
    height: 1.65,
  );

  @override
  Widget build(BuildContext context) {
    final blocks = text.trim().split(RegExp(r'\n\n+'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks)
          if (block.trim().isNotEmpty) _buildBlock(block.trim()),
      ],
    );
  }

  Widget _buildBlock(String block) {
    final lines = block.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    final isBulletList = lines.every((l) => l.startsWith('- ') || l.startsWith('• '));

    if (isBulletList) {
      return Padding(
        padding: const EdgeInsets.only(bottom: ESizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: _bodyStyle),
                    Expanded(child: Text(line.substring(2), style: _bodyStyle)),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.md),
      child: Text(block, style: _bodyStyle),
    );
  }
}
