import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/events/services/event_service.dart';
import '../../features/events/services/invitation_template_service.dart';
import '../../features/events/controllers/events_controller.dart';
import '../../features/payments/services/payment_service.dart';
import '../../features/inbox/controllers/inbox_controller.dart';
import '../../features/inbox/services/inbox_notification_service.dart';
import '../../features/chat/services/websocket_service.dart';
import '../../features/chat/services/group_notification_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Core Services - use putIfAbsent to avoid duplicates
    if (!Get.isRegistered<StorageService>()) {
      Get.put<StorageService>(StorageService());
    }
    Get.put<ApiService>(ApiService());

    // Auth
    Get.put<AuthService>(
      AuthService(
        apiService: Get.find<ApiService>(),
        storageService: Get.find<StorageService>(),
      ),
    );

    Get.put<AuthController>(
      AuthController(authService: Get.find<AuthService>()),
    );

    // Events
    Get.put<EventService>(EventService());
    Get.put<InvitationTemplateService>(InvitationTemplateService());
    
    // Payments
    Get.put<PaymentService>(PaymentService());
    
    // Inbox - singleton for real-time updates across screens
    Get.put<InboxController>(InboxController(), permanent: true);
    
    // Inbox Notification WebSocket - for real-time DM notifications
    Get.put<InboxNotificationService>(InboxNotificationService(), permanent: true);
    
    // WebSocket service for group chat - singleton
    Get.put<WebSocketService>(WebSocketService(), permanent: true);
    
    // Group Notification WebSocket - for real-time group chat notifications
    Get.put<GroupNotificationService>(GroupNotificationService(), permanent: true);
  }
}

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(authService: Get.find<AuthService>()),
      );
    }
  }
}

class EventsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EventService>()) {
      Get.put<EventService>(EventService());
    }
    if (!Get.isRegistered<InvitationTemplateService>()) {
      Get.put<InvitationTemplateService>(InvitationTemplateService());
    }
    if (!Get.isRegistered<EventsController>()) {
      Get.put<EventsController>(EventsController());
    }
  }
}
