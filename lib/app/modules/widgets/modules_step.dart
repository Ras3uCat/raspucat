import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/configurator_state.dart';
import 'package:raspucat/app/modules/widgets/module_toggle_tile.dart';

class ModulesStep extends StatelessWidget {
  const ModulesStep({
    super.key,
    required this.plan,
    required this.state,
    required this.modules,
  });

  final PlanModel plan;
  final ConfiguratorState state;
  final List<ModuleModel> modules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ESizes.lg,
            ESizes.md,
            ESizes.lg,
            ESizes.sm,
          ),
          child: Text(
            plan.isCustom
                ? 'Select your add-ons'
                : 'Included modules (locked) + optional add-ons',
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSizeSm,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final snap = Map<String, bool>.from(state.moduleSelections);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                ESizes.lg,
                0,
                ESizes.lg,
                ESizes.sm,
              ),
              itemCount: modules.length,
              itemBuilder: (_, i) {
                final m = modules[i];
                final locked = state.isLocked(m.id);
                final selected = snap[m.id] ?? false;
                final parentOk = m.upgradeOf == null
                    ? true
                    : snap[m.upgradeOf] ?? false;
                return ModuleToggleTile(
                  module: m,
                  isSelected: selected,
                  isLocked: locked,
                  isParentSelected: parentOk,
                  onToggle: (v) => state.toggleModule(m.id, v, modules),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
