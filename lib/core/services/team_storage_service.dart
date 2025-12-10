import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamStorageService {
  static const String _teamsKey = 'saved_teams';
  static const String _disabledTeamsKey = 'disabled_teams';

  /// Save active teams to local storage
  static Future<void> saveTeams(List<Map<String, String>> teams) async {
    try {
      debugPrint('TeamStorageService: Saving ${teams.length} teams...');
      debugPrint('TeamStorageService: Teams = $teams');
      final prefs = await SharedPreferences.getInstance();
      final teamsJson = jsonEncode(teams);
      final success = await prefs.setString(_teamsKey, teamsJson);
      debugPrint('TeamStorageService: Teams saved successfully = $success');
      
      // Verify the save worked
      final verify = prefs.getString(_teamsKey);
      debugPrint('TeamStorageService: Verification read = $verify');
    } catch (e) {
      debugPrint('Error saving teams: $e');
    }
  }

  /// Save disabled teams to local storage
  static Future<void> saveDisabledTeams(List<Map<String, String>> teams) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamsJson = jsonEncode(teams);
      await prefs.setString(_disabledTeamsKey, teamsJson);
    } catch (e) {
      debugPrint('Error saving disabled teams: $e');
    }
  }

  /// Load active teams from local storage
  static Future<List<Map<String, String>>> loadTeams() async {
    try {
      debugPrint('TeamStorageService: Loading teams...');
      final prefs = await SharedPreferences.getInstance();
      final teamsJson = prefs.getString(_teamsKey);
      debugPrint('TeamStorageService: teamsJson = $teamsJson');
      if (teamsJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(teamsJson);
      final result = decoded.map((item) => Map<String, String>.from(item)).toList();
      debugPrint('TeamStorageService: Loaded ${result.length} teams');
      return result;
    } catch (e) {
      debugPrint('Error loading teams: $e');
      return [];
    }
  }

  /// Load disabled teams from local storage
  static Future<List<Map<String, String>>> loadDisabledTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamsJson = prefs.getString(_disabledTeamsKey);
      if (teamsJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(teamsJson);
      return decoded.map((item) => Map<String, String>.from(item)).toList();
    } catch (e) {
      debugPrint('Error loading disabled teams: $e');
      return [];
    }
  }

  /// Check if there are any saved teams
  static Future<bool> hasTeams() async {
    try {
      final teams = await loadTeams();
      final disabledTeams = await loadDisabledTeams();
      return teams.isNotEmpty || disabledTeams.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking teams: $e');
      return false;
    }
  }

  /// Clear all saved teams
  static Future<void> clearTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_teamsKey);
      await prefs.remove(_disabledTeamsKey);
    } catch (e) {
      debugPrint('Error clearing teams: $e');
    }
  }
}
