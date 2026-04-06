import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_detail_activity.dart';
import 'package:raspucat/app/modules/widgets/admin_detail_cancel.dart';
import 'package:raspucat/app/modules/widgets/admin_add_module_modal.dart';
import 'package:raspucat/app/modules/widgets/admin_client_json_dialog.dart';
import 'package:raspucat/app/modules/widgets/admin_messages_section.dart';
import 'package:raspucat/app/modules/widgets/admin_files_section.dart';
import 'package:raspucat/app/modules/widgets/admin_delivery_section.dart';
import 'package:raspucat/app/modules/widgets/admin_site_health_section.dart';
import 'package:raspucat/app/modules/widgets/admin_discovery_tab.dart';
import 'package:raspucat/app/modules/widgets/admin_provision_email_section.dart';
import '_admin_asset_upload_section.dart';

class AdminDetailContent extends StatefulWidget {
  const AdminDetailContent({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.detail,
  });

  final AdminController ctrl;
  final String quoteId;
  final Map<String, dynamic> detail;

  @override
  State<AdminDetailContent> createState() => _AdminDetailContentState();
}

enum _Tab { details, discovery, delivery, files, messages }

class _AdminDetailContentState extends State<AdminDetailContent> {
  _Tab _activeTab = _Tab.details;

  AdminController get ctrl => widget.ctrl;
  String get quoteId => widget.quoteId;
  Map<String, dynamic> get detail => widget.detail;

  static String _fmtSub(Map<String, dynamic> d) {
    final cents = d['subscription_amount_cents'] as int?;
    final cycle = d['billing_cycle'] as String?;
    if (cents == null || cents == 0 || cycle == 'onetime') return '—';
    final dollars = (cents / 100).round();
    final suffix = cycle == 'annual' ? '/yr' : '/mo';
    return '\$$dollars$suffix';
  }

  static String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      final m = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      return '${dt.year}-$m-$day';
    } catch (_) {
      return '—';
    }
  }

  static String _capitalize(String? s) {
    if (s == null || s.isEmpty) return '—';
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm + 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.12))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  detail['client_name'] as String? ?? '',
                  style: const TextStyle(
                    color: EColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: ESizes.fontSizeMd,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close, color: EColors.textSecondary, size: 20),
              ),
            ],
          ),
        ),
        // Tab strip
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              _TabChip(
                label: 'Details',
                isActive: _activeTab == _Tab.details,
                onTap: () => setState(() => _activeTab = _Tab.details),
              ),
              _TabChip(
                label: 'Discovery',
                isActive: _activeTab == _Tab.discovery,
                badge:
                    ctrl.quoteState[quoteId]?['discoverySeen'] != true &&
                        detail['discovery_submitted_at'] != null
                    ? 1
                    : 0,
                onTap: () {
                  ctrl.markDiscoverySeen(quoteId);
                  setState(() => _activeTab = _Tab.discovery);
                },
              ),
              _TabChip(
                label: 'Delivery',
                isActive: _activeTab == _Tab.delivery,
                onTap: () => setState(() => _activeTab = _Tab.delivery),
              ),
              Obx(
                () => _TabChip(
                  label: 'Files',
                  isActive: _activeTab == _Tab.files,
                  badge: ctrl.newFileCounts[quoteId] ?? 0,
                  onTap: () {
                    setState(() => _activeTab = _Tab.files);
                    ctrl.clearFileCount(quoteId);
                  },
                ),
              ),
              Obx(
                () => _TabChip(
                  label: 'Messages',
                  isActive: _activeTab == _Tab.messages,
                  badge: ctrl.unreadMessageCounts[quoteId] ?? 0,
                  onTap: () => setState(() => _activeTab = _Tab.messages),
                ),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: switch (_activeTab) {
            _Tab.details => _detailBody(),
            _Tab.discovery => AdminDiscoveryTab(
              ctrl: ctrl,
              quoteId: quoteId,
              discoveryData: (detail['discovery_data'] as Map<String, dynamic>?) ?? {},
              submittedAt: detail['discovery_submitted_at'] as String?,
            ),
            _Tab.delivery => AdminDeliverySection(
              ctrl: ctrl,
              quoteId: quoteId,
              moduleIds: (detail['module_ids'] as List<dynamic>? ?? []).cast<String>(),
            ),
            _Tab.files => AdminFilesSection(quoteId: quoteId),
            _Tab.messages => AdminMessagesSection(quoteId: quoteId),
          },
        ),
      ],
    );
  }

  Widget _detailBody() {
    final modules = (detail['modules'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final last4 = detail['payment_method_last4'] as String?;
    final brand = detail['payment_method_brand'] as String?;
    final cardLabel = last4 != null ? '${_capitalize(brand)} \u2022\u2022\u2022\u2022 $last4' : '—';

    final divider = Divider(color: EColors.primary.withValues(alpha: 0.1), height: ESizes.lg);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            label: 'Client',
            children: [
              _Row('Email', detail['client_email'] as String? ?? '—'),
              _Row('Business', detail['business_name'] as String? ?? '—'),
              const SizedBox(height: 8),
              const Text(
                'INFRA EMAIL',
                style: TextStyle(fontSize: 9, letterSpacing: 2, color: EColors.softGrey),
              ),
              const SizedBox(height: 4),
              AdminProvisionEmailSection(
                ctrl: widget.ctrl,
                quoteId: widget.quoteId,
                detail: detail,
              ),
            ],
          ),
          divider,
          _Section(
            label: 'Plan',
            children: [
              _Row('Plan ID', detail['plan_id'] as String? ?? '—'),
              if (modules.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: modules.map((m) => _ModuleChip(m)).toList(),
                  ),
                ),
              if (detail['status'] == 'fully_paid' || detail['subscription_started_at'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Builder(
                    builder: (ctx) => NeonButton(
                      onTap: () => AdminAddModuleModal.show(ctx, ctrl, quoteId),
                      neonColor: EColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.md,
                        vertical: ESizes.sm,
                      ),
                      child: const Text(
                        'Add Module',
                        style: TextStyle(
                          color: EColors.textWhite,
                          fontSize: ESizes.fontSizeLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              if (detail['status'] == 'deposit_paid' ||
                  detail['status'] == 'fully_paid' ||
                  detail['subscription_started_at'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: ESizes.sm),
                  child: Builder(
                    builder: (ctx) => NeonButton(
                      onTap: () => AdminClientJsonDialog.show(ctx, ctrl, quoteId),
                      neonColor: EColors.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.md,
                        vertical: ESizes.sm,
                      ),
                      child: const Text(
                        'Generate client.json',
                        style: TextStyle(
                          color: EColors.textWhite,
                          fontSize: ESizes.fontSizeLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          divider,
          _Section(
            label: 'Assets',
            children: [
              AdminAssetUploadSection(ctrl: widget.ctrl, quoteId: widget.quoteId, detail: detail),
            ],
          ),
          divider,
          _Section(
            label: 'Management',
            children: [
              _Row(
                'Option',
                '${detail['management_option_name'] ?? '—'}'
                    ' · ${detail['billing_cycle'] ?? '—'}',
              ),
              _Row('Subscription', _fmtSub(detail)),
            ],
          ),
          divider,
          _Section(
            label: 'Payment',
            children: [
              _Row('Card', cardLabel),
              if (detail['promo_code'] != null) ...[
                _Row('Promo code', detail['promo_code'] as String),
                _Row('Discount', () {
                  final amt = detail['discount_amount_cents'] as int? ?? 0;
                  final orig = detail['original_setup_total_cents'] as int?;
                  final dollars = (amt / 100).round();
                  if (orig != null && orig > 0) {
                    final pct = (amt / orig * 100).round();
                    return '-\$$dollars ($pct% off)';
                  }
                  return '-\$$dollars';
                }()),
              ],
            ],
          ),
          divider,
          _Section(
            label: 'Dates',
            children: [
              _Row('Created', _fmtDate(detail['created_at'] as String?)),
              if (detail['activated_at'] != null)
                _Row('Auto-activated', _fmtDate(detail['activated_at'] as String?)),
              _Row('Sub active since', _fmtDate(detail['subscription_started_at'] as String?)),
              if (detail['current_period_end'] != null)
                _Row('Next billing date', _fmtDate(detail['current_period_end'] as String?)),
              if (detail['pending_change_description'] != null)
                _Row(
                  'Scheduled change',
                  '${detail['pending_change_description']}'
                      '\n→ ${_fmtDate(detail['pending_change_date'] as String?)}',
                ),
              if (detail['template_version'] != null) ...[
                _Row('Template ver', detail['template_version'] as String),
                _Row('Last delivered', _fmtDate(detail['template_delivered_at'] as String?)),
              ],
            ],
          ),
          Obx(() {
            final current = ctrl.currentTemplateVersion.value;
            final installed = detail['template_version'] as String?;
            final behind =
                current.isNotEmpty &&
                installed != null &&
                installed.isNotEmpty &&
                installed != current;
            if (!behind) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: ESizes.sm),
              child: NeonButton(
                onTap: () => ctrl.markTemplateUpdated(quoteId),
                neonColor: const Color(0xFFFBBF24),
                padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
                child: Text(
                  'Mark Updated to $current',
                  style: const TextStyle(
                    color: EColors.textWhite,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
          divider,
          _SiteUrlInput(ctrl: ctrl, quoteId: quoteId, detail: detail),
          if ((detail['site_url'] as String?) != null) ...[
            divider,
            AdminSiteHealthSection(quote: detail, ctrl: ctrl),
          ],
          divider,
          _PortalStageSection(
            ctrl: ctrl,
            quoteId: quoteId,
            currentStage: detail['portal_stage'] as String? ?? 'transmitting',
          ),
          divider,
          _PendingModulesSection(
            ctrl: ctrl,
            quoteId: quoteId,
            pendingModules: (detail['pending_modules'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>(),
          ),
          divider,
          AdminDetailActivity(events: detail['events'] as List<dynamic>? ?? []),
          divider,
          AdminDetailCancel(ctrl: ctrl, quoteId: quoteId, detail: detail),
        ],
      ),
    );
  }
}

// ─── Tab widget ────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isActive ? EColors.primary : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? EColors.primary : EColors.textSecondary,
                fontSize: ESizes.fontSizeSm,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: EColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────────

class _ModuleChip extends StatelessWidget {
  const _ModuleChip(this.module);
  final Map<String, dynamic> module;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        module['name'] as String? ?? '',
        style: TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeLabel),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: TextStyle(
          color: EColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 6),
      ...children,
    ],
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeLabel),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Site URL Input
// ---------------------------------------------------------------------------

class _SiteUrlInput extends StatefulWidget {
  const _SiteUrlInput({required this.ctrl, required this.quoteId, required this.detail});
  final AdminController ctrl;
  final String quoteId;
  final Map<String, dynamic> detail;

  @override
  State<_SiteUrlInput> createState() => _SiteUrlInputState();
}

class _SiteUrlInputState extends State<_SiteUrlInput> {
  late final TextEditingController _tc;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final siteUrl = widget.detail['site_url'] as String? ?? '';
    final discoveryUrl =
        ((widget.detail['discovery_data'] as Map<String, dynamic>?)?['SITE_URL'] as String?) ?? '';
    _tc = TextEditingController(text: siteUrl.isNotEmpty ? siteUrl : discoveryUrl);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'Site URL',
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tc,
                style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeLabel),
                decoration: InputDecoration(
                  hintText: 'https://client-site.com',
                  hintStyle: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.5)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ESizes.sm,
                    vertical: ESizes.sm,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                    borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                    borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: ESizes.sm),
            Obx(() {
              final state = widget.ctrl.quoteState[widget.quoteId] ?? {};
              final saving = state['savingSiteUrl'] as bool? ?? false;
              final msg = state['siteUrlMsg'] as String?;
              if (saving) {
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                );
              }
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    final url = _tc.text.trim();
                    if (!url.startsWith('https://')) {
                      setState(() => _validationError = '❌ Must start with https://');
                      return;
                    }
                    setState(() => _validationError = null);
                    widget.ctrl.saveSiteUrl(widget.quoteId, url);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.sm),
                    decoration: BoxDecoration(
                      color: EColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                      border: Border.all(color: EColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      msg != null && msg.startsWith('✅') ? 'Saved' : 'Save',
                      style: const TextStyle(
                        color: EColors.primary,
                        fontSize: ESizes.fontSizeLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        if (_validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _validationError!,
              style: const TextStyle(color: Color(0xFFFF4D4D), fontSize: ESizes.fontSizeLabel),
            ),
          ),
        Obx(() {
          final msg = widget.ctrl.quoteState[widget.quoteId]?['siteUrlMsg'] as String?;
          if (msg == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              msg,
              style: TextStyle(
                color: msg.startsWith('✅') ? EColors.primary : const Color(0xFFFF4D4D),
                fontSize: ESizes.fontSizeLabel,
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Portal Stage Section
// ---------------------------------------------------------------------------

class _PortalStageSection extends StatelessWidget {
  const _PortalStageSection({
    required this.ctrl,
    required this.quoteId,
    required this.currentStage,
  });
  final AdminController ctrl;
  final String quoteId;
  final String currentStage;

  static const _stages = [
    ('transmitting', 'Transmitting'),
    ('compiling', 'Compiling'),
    ('deployed', 'Deployed'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'Portal Stage',
      children: [
        const SizedBox(height: 4),
        Wrap(
          spacing: ESizes.sm,
          children: _stages.map(((String id, String label) stage) {
            final isActive = currentStage == stage.$1;
            return GestureDetector(
              onTap: isActive ? null : () => ctrl.updatePortalStage(quoteId, stage.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
                decoration: BoxDecoration(
                  color: isActive ? EColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  border: Border.all(
                    color: isActive
                        ? EColors.primary.withValues(alpha: 0.5)
                        : EColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  stage.$2,
                  style: TextStyle(
                    color: isActive ? EColors.primary : EColors.textSecondary,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pending Modules Section
// ---------------------------------------------------------------------------

class _PendingModulesSection extends StatelessWidget {
  const _PendingModulesSection({
    required this.ctrl,
    required this.quoteId,
    required this.pendingModules,
  });
  final AdminController ctrl;
  final String quoteId;
  final List<Map<String, dynamic>> pendingModules;

  static String _fmtPrice(dynamic cents) {
    if (cents == null) return '';
    final dollars = ((cents as num) / 100).round();
    return ' · \$$dollars';
  }

  static String _fmtPurchasedAt(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        '',
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
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  void _confirmReject(BuildContext context, String pendingModuleId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          side: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
        ),
        title: const Text(
          'Reject Module Request',
          style: TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeMd),
        ),
        content: const Text(
          'Are you sure you want to reject this module request?',
          style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ctrl.rejectModule(pendingModuleId, quoteId);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pendingModules.isEmpty) return const SizedBox.shrink();

    return _Section(
      label: 'Pending Modules',
      children: [
        const SizedBox(height: 4),
        ...pendingModules.map((m) {
          final acknowledged = m['acknowledged_at'] != null;
          final inProgress = m['in_progress_at'] != null;
          final deployed = m['deployed_at'] != null;
          final name = m['module_name'] as String? ?? m['module_id'] as String? ?? '—';
          final moduleId = m['module_id'] as String? ?? '';
          final price = _fmtPrice(m['module_price']);
          final purchasedAt = _fmtPurchasedAt(m['purchased_at'] as String?);
          final deployedAt = deployed ? _fmtPurchasedAt(m['deployed_at'] as String?) : '';
          final pendingModuleId = m['id'] as String;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name$price',
                        style: const TextStyle(
                          color: EColors.textWhite,
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                      if (purchasedAt.isNotEmpty)
                        Text(
                          purchasedAt,
                          style: TextStyle(
                            color: EColors.textSecondary.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      if (deployed)
                        Text(
                          'Deployed $deployedAt',
                          style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 10),
                        )
                      else if (inProgress)
                        Text(
                          'In Progress — pending QA',
                          style: TextStyle(
                            color: EColors.primary.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        )
                      else if (acknowledged)
                        const Text(
                          'Acknowledged',
                          style: TextStyle(color: EColors.gold, fontSize: 10),
                        )
                      else
                        const Text(
                          'New Request',
                          style: TextStyle(color: Color(0xFFFF9800), fontSize: 10),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: ESizes.xs),
                // Reject button — always visible
                Tooltip(
                  message: 'Are you sure you want to reject this module request?',
                  child: GestureDetector(
                    onTap: () => _confirmReject(context, pendingModuleId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: ESizes.fontSizeLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ESizes.xs),
                // Acknowledge or Mark Live
                if (!acknowledged)
                  Tooltip(
                    message:
                        "Confirm you've received this request. Then run add-module.sh to deploy.",
                    child: GestureDetector(
                      onTap: () => ctrl.acknowledgeModule(pendingModuleId, quoteId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: EColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                          border: Border.all(color: EColors.gold.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Acknowledge',
                          style: TextStyle(
                            color: EColors.gold,
                            fontSize: ESizes.fontSizeLabel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (inProgress && !deployed)
                  Tooltip(
                    message: "QA complete — mark this module as live for the client.",
                    child: GestureDetector(
                      onTap: () => ctrl.markModuleLive(pendingModuleId, quoteId, moduleId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: EColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                          border: Border.all(color: EColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'Mark Live',
                          style: TextStyle(
                            color: EColors.primary,
                            fontSize: ESizes.fontSizeLabel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
