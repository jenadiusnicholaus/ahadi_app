import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../../core/services/api_service.dart';
import '../../events/models/event_model.dart';
import '../../events/models/event_type_model.dart';
import '../services/public_event_service.dart';

class PublicEventsController extends GetxController {
  late final PublicEventService _publicEventService;

  // Paging controller for infinite scroll
  final PagingController<int, EventModel> pagingController = PagingController(
    firstPageKey: 1,
  );

  // Observable states
  final isLoading = false.obs;
  final isJoining = false.obs;
  final isSearching = false.obs;
  final event = Rxn<EventModel>();
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final joinCode = ''.obs;

  // Browse events
  final eventTypes = <EventTypeModel>[].obs;
  final selectedEventTypeId = Rxn<int>();
  final searchQuery = ''.obs;

  // App info
  final appInfo = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _publicEventService = PublicEventService(Get.find<ApiService>());

    // Set up paging controller listener
    pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    loadInitialData();
  }

  @override
  void onReady() {
    super.onReady();
    // Ensure data is loaded when screen is ready
    if (eventTypes.isEmpty && !isLoading.value) {
      loadInitialData();
    }
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final response = await _publicEventService.getPublicEvents(
        page: pageKey,
        eventTypeId: selectedEventTypeId.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      final isLastPage = !response.hasMore;

      if (isLastPage) {
        pagingController.appendLastPage(response.items);
      } else {
        pagingController.appendPage(response.items, response.nextPage);
      }
    } catch (error) {
      print('Error fetching page $pageKey: $error');
      pagingController.error = error;
    }
  }

  Future<void> loadInitialData() async {
    try {
      await Future.wait([loadAppInfo(), loadEventTypes()]);
    } catch (e) {
      print('Error loading initial data: $e');
      // Continue even if initial data fails
    }
  }

  Future<void> loadAppInfo() async {
    final result = await _publicEventService.getAppInfo();
    if (result['success'] == true) {
      appInfo.value = result['data'];
    }
  }

  Future<void> loadEventTypes() async {
    final result = await _publicEventService.getEventTypes();
    if (result['success'] == true) {
      eventTypes.value = result['eventTypes'];
    }
  }

  /// Refresh the events list
  Future<void> refreshEvents() async {
    pagingController.refresh();
  }

  void filterByEventType(int? eventTypeId) {
    selectedEventTypeId.value = eventTypeId;
    pagingController.refresh();
  }

  void search(String query) {
    searchQuery.value = query;
    pagingController.refresh();
  }

  void clearFilters() {
    selectedEventTypeId.value = null;
    searchQuery.value = '';
    pagingController.refresh();
  }

  Future<void> selectEvent(EventModel selectedEvent) async {
    event.value = selectedEvent;
    joinCode.value = selectedEvent.joinCode;
  }

  Future<void> searchEventByCode(String code) async {
    if (code.isEmpty) {
      errorMessage.value = 'Please enter a join code';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    event.value = null;

    try {
      final result = await _publicEventService.getEventByJoinCode(code);
      if (result['success'] == true) {
        event.value = result['event'];
        joinCode.value = code.toUpperCase();
      } else {
        errorMessage.value = result['message'] ?? 'Event not found';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> joinEvent({
    required String name,
    required String phone,
    String? email,
  }) async {
    if (joinCode.value.isEmpty) {
      errorMessage.value = 'No event selected';
      return false;
    }

    isJoining.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final result = await _publicEventService.joinEventPublic(
        joinCode: joinCode.value,
        name: name,
        phone: phone,
        email: email,
      );

      if (result['success'] == true) {
        if (result['alreadyJoined'] == true) {
          successMessage.value = 'You have already joined this event';
        } else {
          successMessage.value = result['message'] ?? 'Successfully joined!';
        }
        return true;
      } else {
        errorMessage.value = result['message'] ?? 'Failed to join event';
        return false;
      }
    } finally {
      isJoining.value = false;
    }
  }

  void clearEvent() {
    event.value = null;
    joinCode.value = '';
    errorMessage.value = '';
    successMessage.value = '';
  }

  /// Join event using authenticated user's info
  Future<bool> joinEventAsUser({
    required String name,
    required String phone,
    String? email,
  }) async {
    if (event.value == null) {
      errorMessage.value = 'No event selected';
      return false;
    }

    joinCode.value = event.value!.joinCode;
    return joinEvent(name: name, phone: phone, email: email);
  }

  /// Search and join event by code for authenticated user
  Future<bool> searchAndJoinByCode(
    String code,
    String name,
    String phone, {
    String? email,
  }) async {
    if (code.isEmpty) {
      errorMessage.value = 'Please enter a join code';
      return false;
    }

    isJoining.value = true;
    errorMessage.value = '';

    try {
      // First search for the event
      final result = await _publicEventService.getEventByJoinCode(code);
      if (result['success'] != true) {
        errorMessage.value = result['message'] ?? 'Event not found';
        return false;
      }

      event.value = result['event'];
      joinCode.value = code.toUpperCase();

      // Now join the event
      return await joinEvent(name: name, phone: phone, email: email);
    } finally {
      isJoining.value = false;
    }
  }
}
