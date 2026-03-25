class ApiConfig {
  // static const String baseUrl =
  //     'meerana-ai.uaenorth.cloudapp.azure.com/skillyfy';
  static const String baseUrl = '10.196.175.222:5075';

  static const String httpProtocol = 'http';
  static const String wsProtocol = 'ws';

  static String get httpUrl => '$httpProtocol://$baseUrl';
  static String get wsUrl => '$wsProtocol://$baseUrl';

  static String get websocketChat => '$wsUrl/ws/chat';
}
