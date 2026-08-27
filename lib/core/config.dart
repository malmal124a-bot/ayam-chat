class AppConfig {
  // Backend API (Railway)
  static const String backendUrl = 'https://backend-seven-brown-72.vercel.app';
  static const String apiBase = '$backendUrl/api';

  // Agency API
  static const String agencyApi = '$apiBase/agency';

  // Legacy
  static const String baseUrl = apiBase;
  static const String serverUrl = backendUrl;

  // API Endpoints
  static const String agenciesEndpoint = '$apiBase/agencies';
  static const String usersEndpoint = '$apiBase/users';
  static const String medalsEndpoint = '$apiBase/medals';
}
