import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';
import 'package:raspucat/app/data/repositories/app_project_repository.dart';
import 'package:raspucat/app/modules/screens/_app_project_landing_panel.dart';
import 'package:raspucat/routes/routes.dart';
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
    _load();
  }

  Future<void> _load() async {
    final slug = Get.parameters['slug'] ?? '';
    final project = await AppProjectRepository().fetchBySlug(slug);
    if (!mounted) return;
    if (project == null) {
      Get.offAllNamed(ERoutes.home);
      return;
    }
    setState(() {
      _project = project;
      _loading = false;
    });
  }

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
          : LaunchingPanel(project: _project!),
    );
  }
}
