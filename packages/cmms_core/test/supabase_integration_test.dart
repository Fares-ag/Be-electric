import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final baseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  final anonKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
  final hasConfig = baseUrl.isNotEmpty && anonKey.isNotEmpty;
  final restUrl = hasConfig ? baseUrl + '/rest/v1' : '';

  group('Supabase integration (REST)', () {
    test('Supabase config is provided', () {
      expect(hasConfig, true, reason: 'Set SUPABASE_URL and SUPABASE_ANON_KEY');
    }, skip: !hasConfig);

    test('can select from companies', () async {
      if (!hasConfig) return;
      final res = await http.get(Uri.parse(restUrl + '/companies?limit=5'), headers: {'apikey': anonKey, 'Authorization': 'Bearer ' + anonKey, 'Content-Type': 'application/json'});
      expect(res.statusCode, 200);
      expect(jsonDecode(res.body), isA<List>());
    }, skip: !hasConfig);

    test('can select from users', () async {
      if (!hasConfig) return;
      final res = await http.get(Uri.parse(restUrl + '/users?limit=5'), headers: {'apikey': anonKey, 'Authorization': 'Bearer ' + anonKey, 'Content-Type': 'application/json'});
      expect(res.statusCode, 200);
      expect(jsonDecode(res.body), isA<List>());
    }, skip: !hasConfig);

    test('can select from work_orders', () async {
      if (!hasConfig) return;
      final res = await http.get(Uri.parse(restUrl + '/work_orders?limit=5'), headers: {'apikey': anonKey, 'Authorization': 'Bearer ' + anonKey, 'Content-Type': 'application/json'});
      expect(res.statusCode, 200);
      expect(jsonDecode(res.body), isA<List>());
    }, skip: !hasConfig);

    test('can select from assets', () async {
      if (!hasConfig) return;
      final res = await http.get(Uri.parse(restUrl + '/assets?limit=5'), headers: {'apikey': anonKey, 'Authorization': 'Bearer ' + anonKey, 'Content-Type': 'application/json'});
      expect(res.statusCode, 200);
      expect(jsonDecode(res.body), isA<List>());
    }, skip: !hasConfig);

    test('work_orders has requestorId and status', () async {
      if (!hasConfig) return;
      final res = await http.get(Uri.parse(restUrl + '/work_orders?select=id,requestorId,status&limit=1'), headers: {'apikey': anonKey, 'Authorization': 'Bearer ' + anonKey, 'Content-Type': 'application/json'});
      expect(res.statusCode, 200);
      final list = jsonDecode(res.body) as List;
      if (list.isNotEmpty) { final row = list.first as Map<String, dynamic>; expect(row, contains('requestorId')); expect(row, contains('status')); }
    }, skip: !hasConfig);

    test('users table has role', () async {
      if (!hasConfig) return;
      final res = await http.get(Uri.parse(restUrl + '/users?select=id,email,name,role&limit=5'), headers: {'apikey': anonKey, 'Authorization': 'Bearer ' + anonKey, 'Content-Type': 'application/json'});
      expect(res.statusCode, 200);
      for (final item in jsonDecode(res.body) as List) { expect((item as Map<String, dynamic>), contains('role')); }
    }, skip: !hasConfig);
  });
}
