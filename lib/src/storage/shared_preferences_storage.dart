import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc_storage.dart';

/// SharedPreferences implementation of [BlocStorage].
///
/// This is the default storage implementation that uses
/// SharedPreferences for persisting state data.
class SharedPreferencesStorage implements BlocStorage {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> write(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await _instance;
      final jsonString = json.encode(data);
      await prefs.setString(key, jsonString);
    } catch (e) {}
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final prefs = await _instance;
      final jsonString = prefs.getString(key);

      if (jsonString == null) return null;

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? readSync(String key) {
    try {
      // Only works if prefs already initialized
      if (_prefs == null) return null;

      final jsonString = _prefs!.getString(key);
      if (jsonString == null) return null;

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final prefs = await _instance;
      await prefs.remove(key);
    } catch (e) {}
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await _instance;
      await prefs.clear();
    } catch (e) {}
  }
}
