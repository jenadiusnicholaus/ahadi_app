# 🗺️ AHADI Flutter App - Development Roadmap

> **Event Contribution, Invitation & Communication Platform**  
> Complete feature implementation guide from Authentication to Messaging

---

## 📊 Overview

| Phase | Focus Area | Duration | Status |
|-------|-----------|----------|--------|
| Phase 1 | Authentication & Core Setup | Week 1-2 | ✅ Complete |
| Phase 2 | Event Management | Week 3-4 | ✅ Complete |
| Phase 3 | Contributions & Payments | Week 5-6 | ✅ ~90% Complete |
| Phase 4 | Participants & Invitations | Week 7-8 | 🔲 Not Started |
| Phase 5 | Real-time Chat & Messaging | Week 9-10 | 🔲 Not Started |
| Phase 6 | Notifications & Reminders | Week 11 | 🔲 Not Started |
| Phase 7 | Reports & Analytics | Week 12 | 🔲 Not Started |
| Phase 8 | Polish & Launch | Week 13-14 | 🔲 Not Started |

---

## 🔐 PHASE 1: Authentication & Core Setup
**Status: ✅ In Progress**

### 1.1 Authentication (DONE ✅)
- [x] Google Sign-In integration
- [x] Facebook Sign-In integration
- [x] Phone OTP authentication
- [x] Token management (JWT access/refresh)
- [x] Secure storage for credentials
- [x] Auth state management (GetX)
- [x] Login/OTP screens UI

### 1.2 Core Infrastructure (TODO)
- [ ] API service with interceptors
- [ ] Error handling & retry logic
- [ ] Offline mode detection
- [ ] App-wide loading states
- [ ] Splash screen with auth check
- [ ] Onboarding screens (first launch)

### 1.3 User Profile
- [ ] Profile screen UI
- [ ] Edit profile (name, email, photo)
- [ ] Phone number linking (for social auth users)
- [ ] Account settings
- [ ] Logout functionality

**Deliverables:**
- Complete auth flow (social + OTP)
- User profile management
- Smooth onboarding experience

---

## 📅 PHASE 2: Event Management
**Status: ✅ In Progress**
**Duration: 2 weeks**

### 2.1 Event Listing
```
lib/features/events/
├── controllers/
│   └── events_controller.dart ✅
├── models/
│   ├── event_model.dart ✅
│   ├── event_type_model.dart ✅
│   └── participant_model.dart ✅
├── services/
│   └── event_service.dart ✅
│   └── event_draft_service.dart ✅
└── views/
    ├── events_screen.dart ✅
    ├── event_detail_screen.dart ✅
    ├── create_event_screen.dart ✅
    ├── qr_scanner_screen.dart ✅
    └── widgets/
        ├── event_card.dart ✅
        ├── empty_events_widget.dart ✅
        ├── event_filter_sheet.dart ✅
        └── event_qr_code.dart ✅
```

- [x] Home screen with event tabs (My Events, Invited, Public)
- [x] Event card widget (cover, title, date, progress)
- [x] Pull-to-refresh & pagination
- [x] Search events
- [x] Filter by event type
- [x] Empty states

### 2.2 Event Creation
- [x] Multi-step event creation wizard
- [x] Event type selection (Wedding, Fundraiser, Church, etc.)
- [x] Basic info (title, description)
- [x] Date & location picker
- [x] Cover image upload
- [x] Contribution target setting
- [x] Visibility settings (Public/Private/Invite Only)
- [x] Draft saving (auto-save, restore on return)

### 2.3 Event Details & Settings
- [x] Event detail screen
- [x] Progress indicator (target vs collected)
- [x] Quick actions (share, invite, contribute)
- [x] Event settings/edit
- [x] Auto-disbursement configuration
- [x] Join link/code management
- [x] Delete/archive event
- [x] QR code generation for sharing

### 2.4 Join Event (Public Link)
- [x] Deep link handling (ahadi://join/CODE)
- [x] Join by code screen
- [x] QR code scanner
- [x] Join confirmation dialog

**API Endpoints:**
```
GET    /events/                  # List events
POST   /events/                  # Create event
GET    /events/{id}/             # Event detail
PUT    /events/{id}/             # Update event
DELETE /events/{id}/             # Delete event
GET    /events/types/            # Event types
POST   /events/join/{code}/      # Join by code
```

---

## 💰 PHASE 3: Contributions & Payments
**Duration: 2 weeks**

### 3.1 Contribution Models
```
lib/features/contributions/
├── controllers/
│   └── contribution_controller.dart
├── models/
│   ├── contribution_model.dart
│   └── transaction_model.dart
├── services/
│   └── payment_service.dart
└── views/
    ├── contributions_screen.dart
    ├── contribute_screen.dart
    └── payment_status_screen.dart
```

### 3.2 View Contributions
- [ ] Contribution list per event
- [ ] Filter by type (Cash, Mobile Money, Items, Services)
- [ ] Contribution detail modal
- [ ] Export/share contribution list

### 3.3 Make Contribution (Mobile Money)
- [ ] Contribution flow wizard
- [ ] Amount input with presets
- [ ] Provider selection (M-Pesa, Airtel, Tigo, Halopesa)
- [ ] Phone number input
- [ ] Payment initiation
- [ ] USSD push handling
- [ ] Payment status polling
- [ ] Success/failure screens
- [ ] Receipt generation

### 3.4 Manual Contribution Recording
- [ ] Cash contribution form
- [ ] Item/service contribution
- [ ] Estimated value input
- [ ] Note/description
- [ ] Photo attachment (for items)

### 3.5 Contribution Summary
- [ ] Total collected amount
- [ ] By payment method breakdown
- [ ] By contributor breakdown
- [ ] Progress to target visualization

**Payment Providers:**
- M-Pesa (Vodacom)
- Airtel Money
- Tigo Pesa
- Halopesa

**API Endpoints:**
```
GET    /events/{id}/contributions/        # List contributions
POST   /events/{id}/contributions/        # Record contribution
POST   /payments/initiate/                # Start mobile money payment
GET    /payments/{ref}/status/            # Check payment status
POST   /payments/callback/                # Payment callback (backend)
```

---

## 👥 PHASE 4: Participants & Invitations
**Duration: 2 weeks**

### 4.1 Participant Management
```
lib/features/participants/
├── controllers/
│   └── participants_controller.dart
├── models/
│   └── participant_model.dart
├── services/
│   └── participant_service.dart
└── views/
    ├── participants_screen.dart
    ├── add_participant_screen.dart
    └── participant_detail_screen.dart
```

- [ ] Participant list with search
- [ ] Add participant manually
- [ ] Import from contacts
- [ ] Bulk import (CSV)
- [ ] Participant status (Invited, Confirmed, Attended)
- [ ] Edit/remove participant
- [ ] Participant contribution history

### 4.2 Digital Invitations
```
lib/features/invitations/
├── controllers/
│   └── invitation_controller.dart
├── models/
│   └── invitation_model.dart
└── views/
    ├── invitations_screen.dart
    ├── invitation_preview.dart
    └── invitation_templates.dart
```

- [ ] Invitation template selection
- [ ] Personalized message editor
- [ ] Preview invitation
- [ ] Generate PDF invitation
- [ ] Share via WhatsApp (direct)
- [ ] Share via SMS
- [ ] Copy share link
- [ ] Track invitation status (Sent, Viewed, Responded)
- [ ] Bulk send invitations

### 4.3 RSVP Management
- [ ] RSVP response tracking
- [ ] Confirmation count
- [ ] Decline reasons
- [ ] Dietary/special requirements

**API Endpoints:**
```
GET    /events/{id}/participants/         # List participants
POST   /events/{id}/participants/         # Add participant
PUT    /participants/{id}/                # Update participant
DELETE /participants/{id}/                # Remove participant
POST   /events/{id}/invitations/send/     # Send invitations
GET    /invitations/{code}/               # View invitation (public)
POST   /invitations/{code}/rsvp/          # RSVP response
```

---

## 💬 PHASE 5: Real-time Chat & Messaging
**Duration: 2 weeks**

### 5.1 WebSocket Integration
```
lib/features/chat/
├── controllers/
│   └── chat_controller.dart
├── models/
│   └── message_model.dart
├── services/
│   └── websocket_service.dart
└── views/
    ├── chat_screen.dart
    └── widgets/
        ├── message_bubble.dart
        ├── chat_input.dart
        └── typing_indicator.dart
```

- [ ] WebSocket connection management
- [ ] Auto-reconnect logic
- [ ] Connection state indicator
- [ ] Message queue for offline

### 5.2 Event Group Chat
- [ ] Chat screen per event
- [ ] Message list with pagination
- [ ] Send text messages
- [ ] Send images
- [ ] Message timestamps
- [ ] Read receipts (optional)
- [ ] Typing indicators
- [ ] Scroll to bottom FAB
- [ ] Reply to message
- [ ] Delete own message

### 5.3 Announcements
- [ ] Announcement list
- [ ] Create announcement (organizers)
- [ ] Pin announcements
- [ ] Announcement notifications
- [ ] Rich text support

### 5.4 Push to Chat
- [ ] Local notifications for new messages
- [ ] Badge count
- [ ] Notification tap → open chat

**WebSocket Events:**
```
# Connect
ws://server/ws/chat/event_{id}/

# Events
- message.new
- message.delete
- typing.start
- typing.stop
- user.join
- user.leave
- announcement.new
```

---

## 🔔 PHASE 6: Notifications & Reminders
**Duration: 1 week**

### 6.1 Push Notifications
```
lib/features/notifications/
├── controllers/
│   └── notification_controller.dart
├── models/
│   └── notification_model.dart
├── services/
│   └── push_notification_service.dart
└── views/
    └── notifications_screen.dart
```

- [ ] Firebase Cloud Messaging setup
- [ ] Device token registration
- [ ] Notification permissions handling
- [ ] Foreground notification display
- [ ] Background notification handling
- [ ] Notification tap routing
- [ ] Notification history screen

### 6.2 Event Reminders
- [ ] Create reminder UI
- [ ] Schedule reminder (date/time)
- [ ] Reminder channel (SMS, WhatsApp, Push)
- [ ] Target selection (all or specific)
- [ ] Edit/cancel reminder
- [ ] Reminder history

### 6.3 Automated Notifications
- [ ] New contribution alert
- [ ] New participant joined
- [ ] Event starting soon
- [ ] Target reached celebration
- [ ] New chat message

**API Endpoints:**
```
POST   /devices/register/                 # Register device token
GET    /notifications/                    # List notifications
POST   /events/{id}/reminders/            # Create reminder
GET    /events/{id}/reminders/            # List reminders
DELETE /reminders/{id}/                   # Cancel reminder
```

---

## 📊 PHASE 7: Reports & Analytics
**Duration: 1 week**

### 7.1 Event Dashboard
```
lib/features/analytics/
├── controllers/
│   └── analytics_controller.dart
├── models/
│   └── analytics_model.dart
└── views/
    ├── dashboard_screen.dart
    └── widgets/
        ├── contribution_chart.dart
        ├── participant_stats.dart
        └── progress_card.dart
```

- [ ] Event summary cards
- [ ] Contribution progress chart
- [ ] Daily/weekly contribution graph
- [ ] Top contributors list
- [ ] Participant statistics
- [ ] Payment method breakdown

### 7.2 Export & Sharing
- [ ] Export to PDF report
- [ ] Export to Excel/CSV
- [ ] Share report via WhatsApp
- [ ] Print-friendly view

### 7.3 Organizer Insights
- [ ] All events summary
- [ ] Total raised across events
- [ ] Average contribution size
- [ ] Repeat contributor tracking

**API Endpoints:**
```
GET    /events/{id}/analytics/            # Event analytics
GET    /events/{id}/report/               # Generate report
GET    /user/analytics/                   # User dashboard
```

---

## ✨ PHASE 8: Polish & Launch
**Duration: 2 weeks**

### 8.1 UI/UX Polish
- [ ] Consistent theming across all screens
- [ ] Event-type based color accents
- [ ] Loading skeletons (Shimmer)
- [ ] Empty states with illustrations
- [ ] Error states with retry
- [ ] Pull-to-refresh everywhere
- [ ] Smooth animations & transitions
- [ ] Haptic feedback

### 8.2 Performance
- [ ] Image caching & optimization
- [ ] Lazy loading for lists
- [ ] Memory optimization
- [ ] API response caching
- [ ] Reduce app size

### 8.3 Testing
- [ ] Unit tests for services
- [ ] Widget tests for key components
- [ ] Integration tests for critical flows
- [ ] Manual QA on devices

### 8.4 Pre-Launch
- [ ] App icons & splash screen
- [ ] Store screenshots
- [ ] Privacy policy & terms
- [ ] App Store / Play Store listings
- [ ] Beta testing (TestFlight / Internal)

### 8.5 Launch Checklist
- [ ] Production API endpoint
- [ ] Firebase production project
- [ ] Crashlytics/Analytics setup
- [ ] Rate limiting & security review
- [ ] Load testing
- [ ] Launch! 🚀

---

## 📁 Final Folder Structure

```
lib/
├── main.dart
├── core/
│   ├── bindings/
│   │   └── app_bindings.dart
│   ├── config/
│   │   └── app_config.dart
│   ├── routes/
│   │   └── app_routes.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── storage_service.dart
│   │   └── websocket_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   └── helpers.dart
│   └── widgets/
│       ├── loading_widget.dart
│       ├── error_widget.dart
│       └── empty_state.dart
├── features/
│   ├── auth/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── views/
│   ├── events/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── views/
│   ├── contributions/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── views/
│   ├── participants/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── views/
│   ├── invitations/
│   │   ├── controllers/
│   │   ├── models/
│   │   └── views/
│   ├── chat/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── views/
│   ├── notifications/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── views/
│   └── analytics/
│       ├── controllers/
│       ├── models/
│       └── views/
└── assets/
    ├── images/
    ├── icons/
    └── fonts/
```

---

## 🎯 Key Milestones

| Milestone | Target Date | Deliverable |
|-----------|-------------|-------------|
| M1 | Week 2 | Auth complete, users can sign in |
| M2 | Week 4 | Events CRUD, join by link |
| M3 | Week 6 | Mobile money payments working |
| M4 | Week 8 | Invitations & participant management |
| M5 | Week 10 | Real-time chat functional |
| M6 | Week 12 | Full feature complete |
| M7 | Week 14 | App Store / Play Store submission |

---

## 📝 Notes

### State Management: GetX
- Controllers for each feature
- Reactive state with `.obs`
- Dependency injection via bindings
- Route management

### API Architecture
- RESTful endpoints
- JWT authentication
- WebSocket for real-time
- Azampay for payments

### Offline Support (Future)
- SQLite/Hive for local cache
- Queue pending actions
- Sync when online

---

*Last Updated: January 2026*
