import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final RemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> register(String email, String password, String username) async {
    final data = await remoteDataSource.register(email, password, username);
    // Standard register returns User representation
    return User(
      id: data['id'],
      email: data['email'],
      username: data['username'],
      leavesBalance: data['leaves_balance'],
    );
  }

  @override
  Future<String> login(String email, String password) async {
    final data = await remoteDataSource.login(email, password);
    final token = data['access_token'];
    
    // Persist token in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    
    return token;
  }

  @override
  Future<String> loginWithGoogle(String idToken) async {
    final data = await remoteDataSource.loginWithGoogle(idToken);
    final token = data['access_token'];
    
    // Persist token in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    
    return token;
  }

  @override
  Future<User> getMe() async {
    return await remoteDataSource.getMe();
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  @override
  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  @override
  Future<void> deleteAccount() async {
    await remoteDataSource.deleteAccount();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
