import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_form_body.dart';
import 'package:raspucat/app/controllers/admin_catalog_controller.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(AdminCatalogController());
  });

  tearDown(() => Get.reset());

  Widget _buildSubject({required RxBool isComped}) {
    return GetMaterialApp(
      home: Scaffold(
        body: AdminQuoteFormBody(
          ctrl: Get.find<AdminCatalogController>(),
          selectedPlanId: null,
          selectedModuleIds: const {},
          selectedMgmtId: null,
          selectedBillingCycle: null,
          isComped: isComped,
          onPlanSelected: (_) {},
          onModuleToggled: (_) {},
          onMgmtSelected: (_) {},
          onBillingSelected: (_) {},
        ),
      ),
    );
  }

  group('AdminQuoteFormBody comp toggle', () {
    testWidgets('comp toggle on — price summary is muted (opacity 0.35)', (tester) async {
      final isComped = true.obs;
      await tester.pumpWidget(_buildSubject(isComped: isComped));
      await tester.pump();

      // IgnorePointer with ignoring:true should be present
      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(of: find.byType(AdminQuoteFormBody), matching: find.byType(IgnorePointer)),
      );
      expect(ignorePointer.ignoring, isTrue);

      // Opacity should be 0.35
      final opacity = tester.widget<Opacity>(
        find.descendant(of: find.byType(AdminQuoteFormBody), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0.35);
    });

    testWidgets('comp toggle off — price summary is interactive (opacity 1.0)', (tester) async {
      final isComped = false.obs;
      await tester.pumpWidget(_buildSubject(isComped: isComped));
      await tester.pump();

      // IgnorePointer with ignoring:false
      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(of: find.byType(AdminQuoteFormBody), matching: find.byType(IgnorePointer)),
      );
      expect(ignorePointer.ignoring, isFalse);

      // Opacity should be 1.0
      final opacity = tester.widget<Opacity>(
        find.descendant(of: find.byType(AdminQuoteFormBody), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 1.0);
    });
  });
}
