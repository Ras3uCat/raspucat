import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/utils/constants/exports.dart';

/// Protects portal routes. Unauthenticated users are redirected to
/// [ERoutes.portalLogin]. The session expiry soft-prompt is handled
/// by [PortalLoginScreen] when `?expired=true` is appended.
class PortalAuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const RouteSettings(name: ERoutes.portalLogin);
    }
    return null;
  }
}
