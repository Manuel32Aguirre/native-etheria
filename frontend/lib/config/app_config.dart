/// Central place to configure how the app reaches the deployed Spring Boot backend.
///
/// The backend currently runs on the Lightsail static IPv4 address.
class AppConfig {
  AppConfig._();

  /// Lightsail static IPv4 address for the Native backend.
  static const String lanHost = '3.21.152.118';

  /// Port configured in application.yml (server.port).
  static const int port = 8080;

  static String get baseUrl => 'http://$lanHost:$port/api';
}
