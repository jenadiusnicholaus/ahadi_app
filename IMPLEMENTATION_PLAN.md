# 📋 AHADI - Implementation Plan
> **Next Development Phase: Revenue & Growth Features**  
> Last Updated: January 2026

---

## 🧹 Code Cleanup Summary (Completed)

### ✅ Cleaned Items
- [x] Removed unused imports (`app_config.dart`, `dio.dart`, `status.dart`)
- [x] Removed unused `_templateService` field
- [x] Removed unused `_buildMobileHeader` method
- [x] Removed unused `_buildMobileEventsList` duplicate method
- [x] Compact event card design (horizontal layout)
- [x] Reduced card height by ~60%

### ⚠️ Remaining Warnings (Low Priority)
These are helper methods that may be used in future features:
- `_buildUserMenu`, `_buildNavItem` in dashboard_layout.dart
- `_buildStatBadge`, `_buildFilterChip` in contributions_screen.dart
- Various sidebar helper methods

---

## 🎯 Current Status

### ✅ Completed Features
- [x] Authentication (Google, Facebook, Phone OTP)
- [x] Event Management (CRUD, Types, Join by Code/QR)
- [x] Contribution Tracking (Cash, Mobile Money, Items)
- [x] Mobile Money Payments (M-Pesa, Airtel, Tigo, Halopesa)
- [x] Event Wallet & Transaction History
- [x] Withdrawal/Disbursement to Event Organizers
- [x] Real-time Event Group Chat
- [x] Digital Invitation Cards & Templates
- [x] Participant Management
- [x] Direct Messaging (Inbox)

### 💰 Revenue Infrastructure Status
| Component | Status | Notes |
|-----------|--------|-------|
| Payment Collection | ✅ Done | AzamPay integration |
| Transaction Fees | ✅ Done | Deducted on withdrawal |
| Disbursement | ✅ Done | Mobile money payout |
| Event Wallet UI | ✅ Done | Shows balance, history |
| Subscription Plans | 🔲 TODO | Backend ready, needs UI |

---

## 🔴 PHASE 1: Subscription & Revenue (Week 1-2)
**Goal:** Enable subscription upgrades to generate recurring revenue

### 1.1 Subscription Plans Screen
**File:** `lib/features/subscriptions/views/subscription_plans_screen.dart`

```
Features:
- Display 4 plans: Free, Basic, Premium, VIP
- Show fee % for each plan
- Monthly price display
- "Current Plan" indicator
- "Upgrade" button for each plan
- Savings calculator (how much user saves at their volume)
```

**API Endpoints Needed:**
```
GET  /api/v1/subscriptions/plans/           # List all plans
GET  /api/v1/users/me/subscription/         # Get user's current plan
POST /api/v1/subscriptions/subscribe/       # Subscribe to plan
POST /api/v1/subscriptions/cancel/          # Cancel subscription
```

### 1.2 Fee Preview in Withdrawal
**File:** `lib/features/payments/views/withdraw_request_screen.dart`

```
Update to show:
- Gross amount available
- Fee percentage (based on user's plan)
- Fee amount (calculated)
- Net amount to receive
- "Upgrade to reduce fees" CTA for free users
```

### 1.3 Subscription Status in Profile
**File:** `lib/features/profile/views/profile_screen.dart`

```
Add section:
- Current plan name & badge
- Fee percentage
- Subscription expiry date
- "Manage Subscription" button
```

### 1.4 Fee Display in Event Wallet
**File:** `lib/features/payments/views/event_wallet_screen.dart`

```
Update to show:
- Current fee tier (e.g., "Free Plan - 5% fee")
- Banner: "Upgrade to Premium for 3% fees"
```

---

## 🟡 PHASE 2: User Experience Polish (Week 3-4)
**Goal:** Improve payment experience and engagement

### 2.1 Payment Receipt Generation
**File:** `lib/features/payments/views/payment_receipt_screen.dart`

```
Features:
- Receipt with transaction details
- Event name, date, amount
- Contributor name
- QR code for verification
- Share via WhatsApp
- Download as PDF
```

### 2.2 Push Notifications
**Files:**
- `lib/core/services/push_notification_service.dart`
- `lib/features/notifications/views/notifications_screen.dart`

```
Notification Types:
- New contribution received (for organizers)
- Payment completed (for contributors)
- Event reminder
- Chat message
- Withdrawal processed
```

### 2.3 Contribution Success Animation
**File:** `lib/features/payments/widgets/payment_success_animation.dart`

```
Features:
- Confetti animation
- Amount display with celebration
- "Share your contribution" button
- Return to event button
```

### 2.4 Event Analytics Dashboard
**File:** `lib/features/analytics/views/event_analytics_screen.dart`

```
Features:
- Total collected chart (line graph)
- Daily contributions (bar chart)
- Top contributors list
- Payment method breakdown (pie chart)
- Progress to target
```

---

## 🟢 PHASE 3: Growth Features (Week 5-6)
**Goal:** Viral growth and engagement tools

### 3.1 SMS Reminders
**Files:**
- `lib/features/reminders/views/create_reminder_screen.dart`
- `lib/features/reminders/services/reminder_service.dart`

```
Features:
- Schedule reminder for participants
- Custom message
- Select recipients (all or specific)
- SMS credit system (pay-per-SMS)
- Reminder history
```

**API Endpoints:**
```
POST /api/v1/events/{id}/reminders/          # Create reminder
GET  /api/v1/events/{id}/reminders/          # List reminders
DELETE /api/v1/reminders/{id}/               # Cancel reminder
GET  /api/v1/users/me/sms-credits/           # Get SMS balance
POST /api/v1/users/me/sms-credits/purchase/  # Buy credits
```

### 3.2 WhatsApp Deep Sharing
**File:** `lib/features/events/widgets/share_event_sheet.dart`

```
Features:
- Pre-formatted WhatsApp message
- Include event link
- Include contribution link
- "Share to Status" option
```

### 3.3 Bulk Import Participants
**File:** `lib/features/participants/views/import_participants_screen.dart`

```
Features:
- CSV file upload
- Excel file upload
- Column mapping
- Preview before import
- Error handling
- Progress indicator
```

### 3.4 Event Templates
**File:** `lib/features/events/views/event_templates_screen.dart`

```
Templates:
- Wedding (Harusi)
- Fundraiser (Changia)
- Church Event (Kanisa)
- Graduation (Mahafali)
- Birthday (Siku ya Kuzaliwa)
- Community Event (Jamii)

Each template includes:
- Pre-filled title format
- Suggested cover image
- Default contribution target
- Relevant fields
```

---

## 🔵 PHASE 4: Premium & Enterprise (Month 2)
**Goal:** Enterprise features for institutions

### 4.1 Custom Invitation Designer
**File:** `lib/features/invitations/views/invitation_designer_screen.dart`

```
Features:
- Drag-drop editor
- Text customization
- Image upload
- Template backgrounds
- Font selection
- Color picker
- Save as template
```

### 4.2 Export Reports
**File:** `lib/features/reports/views/export_report_screen.dart`

```
Export Formats:
- PDF summary report
- Excel detailed transactions
- CSV participant list

Report Sections:
- Event summary
- Contribution list
- Participant list
- Financial breakdown
```

### 4.3 Multi-Admin per Event
**Files:**
- `lib/features/events/views/event_admins_screen.dart`
- `lib/features/events/models/event_admin_model.dart`

```
Roles:
- Owner (full access)
- Admin (manage except delete)
- Moderator (chat, announcements)
- Viewer (read-only)
```

### 4.4 Organization Dashboard
**File:** `lib/features/organization/views/organization_dashboard_screen.dart`

```
Features:
- Multiple events overview
- Combined analytics
- Team management
- Branding settings
- Bulk operations
```

---

## 📁 New Folder Structure

```
lib/features/
├── subscriptions/
│   ├── controllers/
│   │   └── subscription_controller.dart
│   ├── models/
│   │   └── subscription_model.dart
│   ├── services/
│   │   └── subscription_service.dart
│   └── views/
│       ├── subscription_plans_screen.dart
│       └── manage_subscription_screen.dart
├── analytics/
│   ├── controllers/
│   │   └── analytics_controller.dart
│   ├── models/
│   │   └── analytics_model.dart
│   └── views/
│       ├── event_analytics_screen.dart
│       └── widgets/
│           ├── contribution_chart.dart
│           └── stats_card.dart
├── reminders/
│   ├── controllers/
│   │   └── reminder_controller.dart
│   ├── models/
│   │   └── reminder_model.dart
│   ├── services/
│   │   └── reminder_service.dart
│   └── views/
│       └── create_reminder_screen.dart
├── reports/
│   ├── services/
│   │   └── report_service.dart
│   └── views/
│       └── export_report_screen.dart
└── organization/
    ├── controllers/
    │   └── organization_controller.dart
    ├── models/
    │   └── organization_model.dart
    └── views/
        └── organization_dashboard_screen.dart
```

---

## 🗓️ Sprint Schedule

### Sprint 1 (Week 1-2): Subscriptions
| Day | Task | Deliverable |
|-----|------|-------------|
| 1 | Backend: Subscription API | Endpoints ready |
| 2-3 | Subscription Plans Screen | UI complete |
| 4 | Subscribe/Upgrade Flow | Payment integration |
| 5 | Fee display in Wallet | Show tier & upgrade CTA |
| 6-7 | Testing & Polish | Bug fixes |

### Sprint 2 (Week 3-4): UX Polish
| Day | Task | Deliverable |
|-----|------|-------------|
| 1-2 | Payment Receipt PDF | Shareable receipt |
| 3 | Fee preview in withdraw | Before/after amounts |
| 4-5 | Push Notifications | FCM setup |
| 6-7 | Success animations | Celebration UI |

### Sprint 3 (Week 5-6): Growth
| Day | Task | Deliverable |
|-----|------|-------------|
| 1-2 | SMS Reminders | Create & send |
| 3 | WhatsApp sharing | Deep links |
| 4-5 | Event Analytics | Charts |
| 6-7 | Testing & Launch prep | QA |

---

## 🎯 Success Metrics

| Metric | Target (Month 1) | Target (Month 3) |
|--------|------------------|------------------|
| Active Events | 100 | 500 |
| Total Contributions | TZS 50M | TZS 200M |
| Paid Subscribers | 10 | 50 |
| Subscription Revenue | TZS 500K | TZS 2.5M |
| Transaction Fee Revenue | TZS 2M | TZS 8M |

---

## 📝 Notes

### Backend Dependencies
- Subscription models & APIs (check if exists)
- SMS gateway integration (for reminders)
- PDF generation service (for receipts/reports)

### Third-Party Services
- **AzamPay** - Payments (already integrated)
- **Firebase** - Push notifications, analytics
- **SMS Gateway** - TBD (Africa's Talking, Twilio, etc.)

### Testing Checklist
- [ ] Subscription upgrade flow
- [ ] Payment with different plans
- [ ] Fee calculation accuracy
- [ ] Notification delivery
- [ ] PDF generation
- [ ] SMS sending

---

*This document should be updated as features are completed.*
