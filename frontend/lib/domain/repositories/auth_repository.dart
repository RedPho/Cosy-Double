import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> register(String email, String password, String username);
  Future<String> login(String email, String password);
  Future<String> loginWithGoogle(String idToken);
  Future<User> getMe();
  Future<void> logout();
  Future<bool> checkAuthStatus();
  Future<void> deleteAccount();
}
