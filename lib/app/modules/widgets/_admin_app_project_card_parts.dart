import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';
import 'package:raspucat/app/modules/widgets/_admin_app_project_email_section.dart';

// ─── Body ─────────────────────────────────────────────────────────────────────

class AdminAppProjectCardBody extends StatelessWidget {
  const AdminAppProjectCardBody({super.key, required this.project});

  final AppProject project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.description != null) ...[
            Text(
              project.description!,
              style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: ESizes.sm),
          ],
          if (project.aliasEmail != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.alternate_email,
                  size: ESizes.iconXs,
                  color: EColors.textSecondary,
                ),
                const SizedBox(width: ESizes.xs),
                Text(
                  project.aliasEmail!,
                  style: const TextStyle(
                    color: EColors.textSecondary,
                    fontSize: ESizes.fontSizeLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESizes.xs),
          ],
          if (project.webUrl != null) ...[
            GestureDetector(
              onTap: () =>
                  launchUrl(Uri.parse(project.webUrl!), mode: LaunchMode.externalApplication),
              child: Row(
                children: [
                  const Icon(Icons.language, size: ESizes.iconXs, color: EColors.primary),
                  const SizedBox(width: ESizes.xs),
                  Flexible(
                    child: Text(
                      project.webUrl!,
                      style: const TextStyle(
                        color: EColors.primary,
                        fontSize: ESizes.fontSizeLabel,
                        decoration: TextDecoration.underline,
                        decorationColor: EColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ESizes.xs),
          ],
          if (project.techStack.isNotEmpty) ...[
            const SizedBox(height: ESizes.xs),
            Wrap(
              spacing: ESizes.xs,
              runSpacing: ESizes.xs,
              children: project.techStack.map((t) => AppProjectTechChip(label: t)).toList(),
            ),
            const SizedBox(height: ESizes.sm),
          ],
          const SizedBox(height: ESizes.xs),
          AdminAppProjectLinkRow(project: project),
          const SizedBox(height: ESizes.sm),
          AdminAppProjectEmailSection(project: project),
        ],
      ),
    );
  }
}

// ─── Link icon row ────────────────────────────────────────────────────────────

class AdminAppProjectLinkRow extends StatelessWidget {
  const AdminAppProjectLinkRow({super.key, required this.project});

  final AppProject project;

  @override
  Widget build(BuildContext context) {
    final links = <({IconData icon, String url, String tooltip})>[
      if (project.supabaseUrl != null)
        (icon: Icons.storage, url: project.supabaseUrl!, tooltip: 'Supabase'),
      if (project.stripeDashboardUrl != null)
        (icon: Icons.credit_card, url: project.stripeDashboardUrl!, tooltip: 'Stripe'),
      if (project.crashReportUrl != null)
        (icon: Icons.bug_report_outlined, url: project.crashReportUrl!, tooltip: 'Crash Reports'),
      if (project.repoUrl != null) (icon: Icons.code, url: project.repoUrl!, tooltip: 'Repo'),
      if (project.appStoreUrl != null)
        (icon: Icons.phone_iphone, url: project.appStoreUrl!, tooltip: 'App Store'),
      if (project.playStoreUrl != null)
        (icon: Icons.android, url: project.playStoreUrl!, tooltip: 'Play Store'),
    ];

    if (links.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: ESizes.xs,
      children: links.map((l) {
        return Tooltip(
          message: l.tooltip,
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(l.url), mode: LaunchMode.externalApplication),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
            child: Padding(
              padding: const EdgeInsets.all(ESizes.xs),
              child: Icon(
                l.icon,
                size: ESizes.iconSm,
                color: EColors.primary.withValues(alpha: 0.8),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Status primitives ────────────────────────────────────────────────────────

class AppProjectStatusDot extends StatelessWidget {
  const AppProjectStatusDot({super.key, required this.status});

  final String status;

  static Color colorFor(String status) => switch (status) {
    'planning' => EColors.gold,
    'development' => EColors.primary,
    'beta' => EColors.accent,
    'live' => EColors.green,
    'paused' => EColors.softGrey,
    _ => EColors.softGrey,
  };

  @override
  Widget build(BuildContext context) {
    final c = colorFor(status);
    return Container(
      width: ESizes.xs + 2,
      height: ESizes.xs + 2,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1)],
      ),
    );
  }
}

class AppProjectStatusBadge extends StatelessWidget {
  const AppProjectStatusBadge({super.key, required this.status});

  final String status;

  static String labelFor(String status) => switch (status) {
    'planning' => 'Planning',
    'development' => 'Dev',
    'beta' => 'Beta',
    'live' => 'Live',
    'paused' => 'Paused',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    final c = AppProjectStatusDot.colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.xs, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        border: Border.all(color: c.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
      ),
      child: Text(
        labelFor(status),
        style: TextStyle(color: c, fontSize: ESizes.fontSizeLabel, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class AppProjectTechChip extends StatelessWidget {
  const AppProjectTechChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.xs, vertical: 2),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
      ),
      child: Text(
        label,
        style: const TextStyle(color: EColors.primary, fontSize: ESizes.fontSizeLabel),
      ),
    );
  }
}
