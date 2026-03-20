import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_detail_content.dart';

class AdminQuoteDetailDrawer extends StatefulWidget {
  const AdminQuoteDetailDrawer({
    super.key,
    required this.ctrl,
    required this.quoteId,
  });

  final AdminController ctrl;
  final String quoteId;

  static void show(BuildContext context, AdminController ctrl, String quoteId) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    if (isWide) {
      showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 420,
              height: double.infinity,
              child: AdminQuoteDetailDrawer(ctrl: ctrl, quoteId: quoteId),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, __) => AdminQuoteDetailDrawer(
            ctrl: ctrl,
            quoteId: quoteId,
          ),
        ),
      );
    }
  }

  @override
  State<AdminQuoteDetailDrawer> createState() => _AdminQuoteDetailDrawerState();
}

class _AdminQuoteDetailDrawerState extends State<AdminQuoteDetailDrawer> {
  @override
  void initState() {
    super.initState();
    // Always refetch to get fresh Stripe billing data (period end, scheduled changes).
    widget.ctrl.fetchQuoteDetail(widget.quoteId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EColors.backgroundDark,
        border: Border(
          left: BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
        ),
      ),
      child: Obx(() {
        final isLoading =
            widget.ctrl.loadingDetail.contains(widget.quoteId);
        final detail = widget.ctrl.quoteDetail[widget.quoteId];

        if (isLoading && detail == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: EColors.primary,
              strokeWidth: 2,
            ),
          );
        }

        if (detail == null) {
          return Center(
            child: Text(
              'Failed to load details.',
              style: TextStyle(color: EColors.textSecondary),
            ),
          );
        }

        return AdminDetailContent(
          ctrl: widget.ctrl,
          quoteId: widget.quoteId,
          detail: detail,
        );
      }),
    );
  }
}
