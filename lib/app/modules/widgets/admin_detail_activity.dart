import 'package:raspucat/utils/constants/exports.dart';

class AdminDetailActivity extends StatelessWidget {
  const AdminDetailActivity({super.key, required this.events});
  final List<dynamic> events;

  static String _eventLabel(String type) {
    return switch (type) {
      'quote_created'          => 'Quote created',
      'deposit_paid'           => 'Deposit paid',
      'balance_charged'        => 'Balance charged',
      'subscription_started'   => 'Subscription started',
      'subscription_cancelled' => 'Subscription cancelled',
      'module_added'           => 'Module added (admin)',
      'addon_purchased'        => 'Add-on purchased (client)',
      'module_activated'       => 'Add-on activated',
      _ => type.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' '),
    };
  }

  static String? _eventDetail(Map<String, dynamic> event) {
    final meta = event['metadata'] as Map<String, dynamic>?;
    if (meta == null) return null;
    final type = event['event_type'] as String? ?? '';
    if (type == 'module_added' || type == 'addon_purchased' || type == 'module_activated') {
      final name = meta['module_name'] as String? ?? meta['module_id'] as String?;
      final cents = meta['amount_cents'] as int?;
      if (name != null && cents != null) return '$name · \$${(cents / 100).round()}';
      if (name != null) return name;
    }
    return null;
  }

  static String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '${dt.year}-$m-$d';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVITY',
          style: TextStyle(
            color: EColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        if (events.isEmpty)
          Text(
            'No events recorded yet.',
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSizeLabel,
            ),
          )
        else
          ...events.map((e) {
            final event = e as Map<String, dynamic>;
            final label = _eventLabel(event['event_type'] as String? ?? '');
            final detail = _eventDetail(event);
            final date = _fmtDate(event['created_at'] as String?);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 10),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: EColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(
                          color: EColors.textWhite,
                          fontSize: ESizes.fontSizeLabel,
                        )),
                        if (detail != null)
                          Text(detail, style: TextStyle(
                            color: EColors.primary,
                            fontSize: ESizes.fontSizeLabel,
                          )),
                        Text(date, style: TextStyle(
                          color: EColors.textSecondary,
                          fontSize: ESizes.fontSizeLabel,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
