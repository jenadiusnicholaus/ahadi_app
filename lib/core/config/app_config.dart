import 'package:ahadi/core/config/environment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Base URL - uses EnvironmentConfig to select per-environment value
  static String get apiBaseUrl => EnvironmentConfig.apiBaseUrl.isNotEmpty
      ? EnvironmentConfig.apiBaseUrl
      : 'https://ahadiapi.quantumvision-tech.com/api/v1';

  // WebSocket Base URL for real-time features
  static String get websocketBaseUrl =>
      EnvironmentConfig.websocketBaseUrl.isNotEmpty
          ? EnvironmentConfig.websocketBaseUrl
          : 'ws://162.0.233.47:8005';

  // Web App Base URL for sharing links
  static String get webAppBaseUrl => EnvironmentConfig.webAppBaseUrl.isNotEmpty
      ? EnvironmentConfig.webAppBaseUrl
      : 'https://ahadi.app';

  // Environment: sandbox or production
  static String get environment => dotenv.env['APP_ENVIRONMENT'] ?? 'sandbox';

  static bool get isSandbox => environment == 'sandbox';

  // Timeout Configuration (in seconds)
  // Default: 300 seconds (5 min) for sandbox, 60 seconds for production
  static int get connectTimeoutSeconds =>
      int.tryParse(dotenv.env['API_CONNECT_TIMEOUT'] ?? '') ??
      (isSandbox ? 300 : 60);

  static int get receiveTimeoutSeconds =>
      int.tryParse(dotenv.env['API_RECEIVE_TIMEOUT'] ?? '') ??
      (isSandbox ? 300 : 60);

  // API Prefixes from .env
  static String get authPrefix => dotenv.env['API_AUTH_PREFIX'] ?? '/auth';
  static String get eventsPrefix =>
      dotenv.env['API_EVENTS_PREFIX'] ?? '/events';
  static String get publicPrefix =>
      dotenv.env['API_PUBLIC_PREFIX'] ?? '/public';
  static String get paymentsPrefix =>
      dotenv.env['API_PAYMENTS_PREFIX'] ?? '/payments';

  // OAuth
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
  static String get facebookAppId => dotenv.env['FACEBOOK_APP_ID'] ?? '';
  static String get facebookClientToken =>
      dotenv.env['FACEBOOK_CLIENT_TOKEN'] ?? '';
}

class ApiEndpoints {
  // Authentication
  static String get googleLogin => '${AppConfig.authPrefix}/social/google/';
  static String get facebookLogin => '${AppConfig.authPrefix}/social/facebook/';
  static String get appleLogin => '${AppConfig.authPrefix}/social/apple/';
  static String get linkPhone => '${AppConfig.authPrefix}/social/link-phone/';
  static String get requestOtp => '${AppConfig.authPrefix}/request-otp/';
  static String get verifyOtp => '${AppConfig.authPrefix}/verify-otp/';
  static String get refreshToken => '${AppConfig.authPrefix}/token/refresh/';
  static String get logout => '${AppConfig.authPrefix}/logout/';
  static String get me => '${AppConfig.authPrefix}/me/';

  // Events - Note: events router is at root /api/v1/, not /api/v1/events/
  static String get events => '/events/';
  static String get myEvents => '/events/my_events/';
  static String get eventTypes => '/event-types/';
  static String get publicEvents => '/events/public_events/';
  static String get participants => '/participants/';
  static String get contributions =>
      '${AppConfig.paymentsPrefix}/contributions/manual/';
  static String get invitations => '/invitations/';
  static String get messages => '/messages/';
  static String get announcements => '/announcements/';
  static String get reminders => '/reminders/';

  // Public endpoints (no auth)
  static String get publicInfo => '/public/info/';
  static String get publicPlans => '/public/plans/';
  static String get publicConfig => '/public/config/';

  // Public event join
  static String eventJoinInfo(String joinCode) => '/events/join/$joinCode/';
  static String eventJoinRegister(String joinCode) =>
      '/events/join/$joinCode/register/';

  // Public contribution (no login, no join required)
  static String eventContributeInfo(String joinCode) =>
      '/events/contribute/$joinCode/';

  // Event detail
  static String eventDetail(int eventId) => '/events/$eventId/';

  // Event nested resources
  static String eventParticipants(int eventId) =>
      '/events/$eventId/participants/';
  static String eventContributions(int eventId) =>
      '/events/$eventId/contributions/';
  static String eventMessages(int eventId) => '/events/$eventId/messages/';
  static String markMessagesRead(int eventId) => '/chat/events/$eventId/read/';
  static String chatUnreadCount(int eventId) => '/chat/events/$eventId/unread/';
  static String eventAnnouncements(int eventId) =>
      '/events/$eventId/announcements/';
  static String eventInvitations(int eventId) =>
      '/events/$eventId/invitations/';
  static String eventReminders(int eventId) => '/events/$eventId/reminders/';
  static String eventAdmins(int eventId) => '/events/$eventId/admins/';
  static String eventReport(int eventId) => '/events/$eventId/report/';

  // Payments
  static String get paymentCheckoutMno =>
      '${AppConfig.paymentsPrefix}/checkout/mno/';
  static String get paymentCheckoutBank =>
      '${AppConfig.paymentsPrefix}/checkout/bank/';
  static String paymentEventContributions(int eventId) =>
      '${AppConfig.paymentsPrefix}/events/$eventId/contributions/';
  static String get paymentWallet => '${AppConfig.paymentsPrefix}/wallet/';
  static String paymentDisburse(int eventId) =>
      '${AppConfig.paymentsPrefix}/events/$eventId/disburse/';
  static String get paymentTransactions =>
      '${AppConfig.paymentsPrefix}/transactions/';
  static String paymentEventTransactions(int eventId) =>
      '${AppConfig.paymentsPrefix}/events/$eventId/transactions/';
  static String paymentEventPayout(int eventId) =>
      '${AppConfig.paymentsPrefix}/events/$eventId/payout/';
  static String paymentEventDisbursements(int eventId) =>
      '${AppConfig.paymentsPrefix}/events/$eventId/disbursements/';
  static String get paymentMyDisbursements =>
      '${AppConfig.paymentsPrefix}/disbursements/';

  // Wedding Invitation Templates
  static String get invitationTemplates => '/invitation-templates/';
  static String get invitationTemplateCategories =>
      '/invitation-templates/categories/';
  static String get invitationTemplatesByCategory =>
      '/invitation-templates/by_category/';
  static String get freeInvitationTemplates =>
      '/invitation-templates/free_templates/';
  static String get premiumInvitationTemplates =>
      '/invitation-templates/premium_templates/';
  static String invitationTemplateDetail(int templateId) =>
      '/invitation-templates/$templateId/';

  // Wedding Invitations
  static String get weddingInvitations => '/wedding-invitations/';
  static String weddingInvitationDetail(int invitationId) =>
      '/wedding-invitations/$invitationId/';
  static String weddingInvitationGenerateCard(int invitationId) =>
      '/wedding-invitations/$invitationId/generate_card/';
  static String get weddingInvitationsBulkCreate =>
      '/wedding-invitations/bulk_create/';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String user = 'user';
  static const String isFirstLaunch = 'is_first_launch';
  static const String themeMode = 'theme_mode';
}
