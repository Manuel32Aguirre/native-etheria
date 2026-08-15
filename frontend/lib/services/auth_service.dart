import 'api_client.dart';

class AuthService {
  final ApiClient client;

  AuthService(this.client);

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final result = await client.post(
      '/auth/register',
      body: {'username': username, 'email': email, 'password': password},
    );
    final token = result['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await client.saveSession(token, result['userId'] as int);
    }
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final result = await client.post(
      '/auth/login',
      body: {'username': username, 'password': password},
    );
    await client.saveSession(
      result['token'] as String,
      result['userId'] as int,
    );
    return result as Map<String, dynamic>;
  }

  Future<void> logout() => client.clearSession();

  Future<bool> isLoggedIn() async => (await client.token) != null;
}
