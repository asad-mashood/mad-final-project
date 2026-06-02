// utils/profile_manager.dart
import '../models/player_profile.dart';
import 'database_helper.dart';

class ProfileManager {
  static final ProfileManager instance = ProfileManager._init();
  PlayerProfile? profile;

  ProfileManager._init();

  bool get hasProfile => profile != null;

  Future<void> loadProfile() async {
    profile = await DatabaseHelper.instance.getPlayerProfile();
  }

  Future<void> saveProfile(PlayerProfile updatedProfile) async {
    await DatabaseHelper.instance.savePlayerProfile(updatedProfile);
    profile = updatedProfile;
  }
}
