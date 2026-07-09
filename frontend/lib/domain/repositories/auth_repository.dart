import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> register(String email, String password);
  Future<String> login(String email, String password);
  Future<User> getMe();
  Future<void> logout();
  Future<bool> checkAuthStatus();
  Future<void> deleteAccount();
}
