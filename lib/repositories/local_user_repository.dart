import '../models/user_model.dart';
import 'user_repository.dart';

class LocalUserRepository implements UserRepository {
  UserModel? _cachedUser;

  @override
  Future<UserModel?> getUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Initializing with non-zero globalScore for realistic mock rank display in profile
    return _cachedUser ?? UserModel(
      id: id,
      numericId: '000000',
      name: 'Rssasa User',
      profilePic: 'assets/Asad/bg_vip_content.png',
      gender: 'Male',
      level: 1,
      vipLevel: 3,
      globalScore: 5240300,
    );
  }

  @override
  Future<void> updateUser(UserModel user) async {
    _cachedUser = user;
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
