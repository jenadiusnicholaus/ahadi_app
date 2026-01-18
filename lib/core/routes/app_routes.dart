import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/otp_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/events/views/dashboard_page.dart';
import '../../features/events/views/create_event_screen.dart';
import '../../features/events/views/event_detail_screen.dart';
import '../../features/events/views/participants_screen.dart';
import '../../features/events/views/contributions_screen.dart';
import '../../features/events/views/invitations_screen.dart';
import '../../features/events/views/payment_checkout_screen.dart';
import '../../features/events/views/invitation_templates_screen.dart';
import '../../features/public_events/views/public_events_screen.dart';
import '../../features/public_events/views/public_contribution_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/bindings/profile_binding.dart';
import '../../features/chat/views/messages_tab_screen.dart';
import '../../features/subscription/views/subscription_plans_screen.dart';
import '../../features/payments/views/wallet_screen.dart';
import '../../features/payments/views/transaction_history_screen.dart';
import '../../features/payments/views/disbursement_screen.dart';
import '../../features/payments/views/payment_status_screen.dart';
import '../bindings/app_bindings.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // Main dashboard - single route for all dashboard content
  static const String dashboard = '/dashboard';

  // Create event (separate route - opens in modal/new screen)
  static const String createEvent = '/events/create';

  // Event details and related screens
  static const String eventDetail = '/events/detail';
  static const String participants = '/participants';
  static const String contributions = '/contributions';
  static const String invitations = '/invitations';
  static const String paymentCheckout = '/payment/checkout';

  // QR Scanner for joining events
  static const String qrScanner = '/events/scan';

  // Chat
  static const String chat = '/chat';

  // Subscriptions
  static const String subscriptions = '/subscriptions';

  // Wallet & Payments
  static const String wallet = '/wallet';
  static const String transactions = '/transactions';
  static const String disbursement = '/disbursement';
  static const String paymentStatus = '/payment/status';

  // Wedding Invitation Templates
  static const String invitationTemplates = '/invitation-templates';

  // Public (no auth)
  static const String publicEvents = '/public/events';
  static const String publicContribute = '/public/contribute';

  // Legacy routes
  static const String events = '/dashboard';
  static const String addContribution = '/dashboard';
}

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: EventsBinding(),
      transition: Transition.fadeIn,
    ),
    // Main dashboard - single entry point
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      binding: EventsBinding(),
      transition: Transition.fadeIn,
    ),
    // Create event - separate screen (modal)
    GetPage(
      name: AppRoutes.createEvent,
      page: () => const CreateEventScreen(),
      transition: Transition.downToUp,
    ),
    // Event detail screen
    GetPage(
      name: AppRoutes.eventDetail,
      page: () => const EventDetailScreen(),
      binding: EventsBinding(),
      transition: Transition.rightToLeft,
    ),
    // Participants screen
    GetPage(
      name: AppRoutes.participants,
      page: () => const ParticipantsScreen(),
      binding: EventsBinding(),
      transition: Transition.rightToLeft,
    ),
    // Contributions screen
    GetPage(
      name: AppRoutes.contributions,
      page: () => const ContributionsScreen(),
      binding: EventsBinding(),
      transition: Transition.rightToLeft,
    ),
    // Invitations screen
    GetPage(
      name: AppRoutes.invitations,
      page: () => const InvitationsScreen(),
      binding: EventsBinding(),
      transition: Transition.rightToLeft,
    ),
    // Payment checkout screen
    GetPage(
      name: AppRoutes.paymentCheckout,
      page: () => const PaymentCheckoutScreen(),
      binding: EventsBinding(),
      transition: Transition.downToUp,
    ),
    // QR Scanner - for joining events (coming soon)
    GetPage(
      name: AppRoutes.qrScanner,
      page: () => Scaffold(
        appBar: AppBar(title: const Text('Join Event')),
        body: const Center(child: Text('QR Scanner coming soon')),
      ),
      binding: EventsBinding(),
      transition: Transition.downToUp,
    ),
    // Chat
    GetPage(
      name: AppRoutes.chat,
      page: () => const MessagesTabScreen(),
      binding: EventsBinding(),
      transition: Transition.rightToLeft,
    ),
    // Profile routes
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    // Subscription plans
    GetPage(
      name: AppRoutes.subscriptions,
      page: () => const SubscriptionPlansScreen(),
      transition: Transition.rightToLeft,
    ),
    // Wallet
    GetPage(
      name: AppRoutes.wallet,
      page: () => const WalletScreen(),
      transition: Transition.rightToLeft,
    ),
    // Transaction history
    GetPage(
      name: AppRoutes.transactions,
      page: () => const TransactionHistoryScreen(),
      transition: Transition.rightToLeft,
    ),
    // Disbursement
    GetPage(
      name: AppRoutes.disbursement,
      page: () => const DisbursementScreen(),
      transition: Transition.rightToLeft,
    ),
    // Payment status
    GetPage(
      name: AppRoutes.paymentStatus,
      page: () => const PaymentStatusScreen(),
      transition: Transition.fadeIn,
    ),
    // Public routes (no auth required)
    GetPage(
      name: AppRoutes.publicEvents,
      page: () => const PublicEventsScreen(),
      transition: Transition.rightToLeft,
    ),
    // Public contribution (no login required)
    GetPage(
      name: AppRoutes.publicContribute,
      page: () => const PublicContributionScreen(),
      transition: Transition.rightToLeft,
    ),
    // Wedding Invitation Templates
    GetPage(
      name: AppRoutes.invitationTemplates,
      page: () => const InvitationTemplatesScreen(),
      binding: EventsBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
