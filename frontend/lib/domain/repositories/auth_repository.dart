import '../entities/user.dart';

abstract class AuthRepository {
  Future<String> loginAsGuest(String? username);
  Future<User> updateNickname(String username);
  Future<User> getMe();
  Future<void> logout();
  Future<bool> checkAuthStatus();
}
