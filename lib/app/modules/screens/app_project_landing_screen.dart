import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';
import 'package:raspucat/app/data/repositories/app_project_repository.dart';
import 'package:raspucat/app/modules/screens/_app_project_landing_panel.dart';
import 'package:raspucat/app/modules/screens/_app_project_live_panel.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';

class AppProjectLandingScreen extends StatefulWidget {
  const AppProjectLandingScreen({super.key});

  @override
  State<AppProjectLandingScreen> createState() => _AppProjectLandingScreenState();
}

class _AppProjectLandingScreenState extends State<AppProjectLandingScreen> {
  AppProject? _project;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Post-frame so the navigator is fully settled before any async work.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final slug = Get.parameters['slug'] ?? '';

    AppProject? project;
    try {
      if (slug.isNotEmpty) {
        project = await AppProjectRepository().fetchBySlug(slug);
        debugPrint('[landing] slug=$slug project=${project?.name} status=${project?.status}');
      }
    } catch (e) {
      debugPrint('[landing] fetchBySlug error: $e');
    }

    if (!mounted) return;
    setState(() {
      // Use DB project if found; otherwise build a minimal fallback from the slug
      // so the page always renders instead of redirecting or staying on a spinner.
      _project = project ?? _fallback(slug);
      _loading = false;
    });
  }

  /// Formats "woowedsmite" → "Woo Wed Smite" is not recoverable from a slug,
  /// so we just title-case the raw slug as a best-effort display name.
  AppProject _fallback(String slug) => AppProject(
    id: '',
    name: slug.isEmpty ? 'Coming Soon' : slug,
    status: 'development',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: _loading
          ? const Center(
              child: SizedBox(
                width: ESizes.loadingIndiatorSize,
                height: ESizes.loadingIndiatorSize,
                child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 1.5),
              ),
            )
          : _project!.status == 'live'
          ? LiveAppPanel(project: _project!)
          : LaunchingPanel(project: _project!),
    );
  }
}
