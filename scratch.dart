import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://gegwqywgbgzahnftppda.supabase.co/rest/v1/rpc/get_public_stats');
  final response = await http.post(
    url,
    headers: {
      'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlZ3dxeXdnYmd6YWhuZnRwcGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MDIyMDQsImV4cCI6MjA4OTI3ODIwNH0.2DgzGgFAMzb5jxULTDthYs0SPH7zmM8rvkMSOQlY2Og',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlZ3dxeXdnYmd6YWhuZnRwcGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MDIyMDQsImV4cCI6MjA4OTI3ODIwNH0.2DgzGgFAMzb5jxULTDthYs0SPH7zmM8rvkMSOQlY2Og',
    },
  );
  print(response.statusCode);
  print(response.body);
}
