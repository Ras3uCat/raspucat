part of 'admin_outreach_widget.dart';

class _OutreachSettingsPanel extends StatefulWidget {
  const _OutreachSettingsPanel({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  State<_OutreachSettingsPanel> createState() => _OutreachSettingsPanelState();
}

class _OutreachSettingsPanelState extends State<_OutreachSettingsPanel> {
  late final TextEditingController _emailsPerRunCtrl;
  late final TextEditingController _runsPerWeekCtrl;
  late final TextEditingController _followUpDaysCtrl;
  late final TextEditingController _maxFollowUpsCtrl;
  late final TextEditingController _discoveryRunsCtrl;
  late final TextEditingController _cityInputCtrl;

  late List<String> _industries;
  late List<String> _cities;

  @override
  void initState() {
    super.initState();
    final s = widget.ctrl.settings.value;
    _emailsPerRunCtrl = TextEditingController(text: '${s.emailsPerRun}');
    _runsPerWeekCtrl = TextEditingController(text: '${s.runsPerWeek}');
    _followUpDaysCtrl = TextEditingController(text: '${s.followUpDays}');
    _maxFollowUpsCtrl = TextEditingController(text: '${s.maxFollowUps}');
    _discoveryRunsCtrl = TextEditingController(text: '${s.discoveryRunsPerWeek}');
    _cityInputCtrl = TextEditingController();
    _industries = List.from(s.targetIndustries);
    _cities = List.from(s.targetCities);
  }

  @override
  void dispose() {
    _emailsPerRunCtrl.dispose();
    _runsPerWeekCtrl.dispose();
    _followUpDaysCtrl.dispose();
    _maxFollowUpsCtrl.dispose();
    _discoveryRunsCtrl.dispose();
    _cityInputCtrl.dispose();
    super.dispose();
  }

  void _save() {
    // Flush any pending city text that hasn't been confirmed with Enter
    final pendingCity = _cityInputCtrl.text.trim();
    if (pendingCity.isNotEmpty && !_cities.contains(pendingCity)) {
      setState(() => _cities.add(pendingCity));
      _cityInputCtrl.clear();
    }

    final current = widget.ctrl.settings.value;
    final updated = OutreachSettings(
      id: current.id,
      emailsPerRun: int.tryParse(_emailsPerRunCtrl.text) ?? 3,
      runsPerWeek: int.tryParse(_runsPerWeekCtrl.text) ?? 2,
      followUpDays: int.tryParse(_followUpDaysCtrl.text) ?? 3,
      maxFollowUps: int.tryParse(_maxFollowUpsCtrl.text) ?? 2,
      targetIndustries: _industries,
      targetCities: _cities,
      discoveryRunsPerWeek: int.tryParse(_discoveryRunsCtrl.text) ?? 2,
      lastDiscoveryCount: current.lastDiscoveryCount,
      nextDiscoveryRunAt: current.nextDiscoveryRunAt,
      lastDiscoveryAt: current.lastDiscoveryAt,
    );
    widget.ctrl.saveSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '// SETTINGS',
            style: TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: ESizes.lg),
          Row(
            children: [
              Expanded(
                child: _SettingsNumberField(
                  label: 'Emails per run',
                  ctrl: _emailsPerRunCtrl,
                  min: 1,
                  max: 10,
                ),
              ),
              const SizedBox(width: ESizes.md),
              Expanded(
                child: _SettingsNumberField(
                  label: 'Runs per week',
                  ctrl: _runsPerWeekCtrl,
                  min: 1,
                  max: 7,
                ),
              ),
              const SizedBox(width: ESizes.md),
              Expanded(
                child: _SettingsNumberField(
                  label: 'Follow-up days',
                  ctrl: _followUpDaysCtrl,
                  min: 1,
                  max: 14,
                ),
              ),
              const SizedBox(width: ESizes.md),
              Expanded(
                child: _SettingsNumberField(
                  label: 'Max follow-ups',
                  ctrl: _maxFollowUpsCtrl,
                  min: 1,
                  max: 5,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESizes.lg),
          _IndustryPillSelector(
            selected: _industries,
            ctrl: widget.ctrl,
            onToggle: (name) => setState(() {
              _industries.contains(name) ? _industries.remove(name) : _industries.add(name);
            }),
          ),
          const SizedBox(height: ESizes.md),
          _ChipMultiInput(
            label: 'Target Cities',
            chips: _cities,
            inputCtrl: _cityInputCtrl,
            onAdd: (v) => setState(() => _cities.add(v)),
            onRemove: (v) => setState(() => _cities.remove(v)),
          ),
          const SizedBox(height: ESizes.lg),
          _DiscoverySection(ctrl: widget.ctrl, discoveryRunsCtrl: _discoveryRunsCtrl),
          const SizedBox(height: ESizes.xl),
          Obx(
            () => GestureDetector(
              onTap: widget.ctrl.isLoading.value ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.sm),
                decoration: BoxDecoration(
                  color: EColors.primary.withAlpha(20),
                  border: Border.all(color: EColors.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: widget.ctrl.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 1.5),
                      )
                    : const Text(
                        'Save Settings',
                        style: TextStyle(
                          color: EColors.primary,
                          fontSize: ESizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
