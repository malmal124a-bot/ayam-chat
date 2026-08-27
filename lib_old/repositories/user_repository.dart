import '../models/user_model.dart';

abstract class UserRepository {
  Future<UserModel?> getUser(String id);
  Future<void> updateUser(UserModel user);
  Future<bool> login(String username, String password);
}
