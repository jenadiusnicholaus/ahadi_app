# Social Authentication API Documentation

This document describes the Social Authentication endpoints for the Ahadi platform. These endpoints allow mobile apps to authenticate users via Google, Facebook, and Apple Sign-In.

## Base URL

```
https://your-domain.com/api/v1/auth/social/
```

---

## Endpoints Overview

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/google/` | POST | Google Sign-In |
| `/facebook/` | POST | Facebook Sign-In |
| `/apple/` | POST | Apple Sign-In |

---

## 1. Google Sign-In

Authenticate users with Google OAuth tokens.

### Endpoint

```
POST /api/v1/auth/social/google/
```

### Request Headers

| Header | Value | Required |
|--------|-------|----------|
| `Content-Type` | `application/json` | ✅ |

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id_token` | string | ✅ (or `access_token`) | Google ID token from mobile SDK |
| `access_token` | string | ✅ (or `id_token`) | Google OAuth access token |

> **Note:** Provide either `id_token` OR `access_token`, not both.

### Example Request (with ID Token)

```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Example Request (with Access Token)

```json
{
  "access_token": "ya29.a0AfH6SMBx..."
}
```

### Success Response

**Status Code:** `200 OK`

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "phone": "+255712345678",
      "email": "user@gmail.com",
      "full_name": "John Doe",
      "is_new": false
    },
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "requires_phone_link": false
  }
}
```

### Error Responses

**Status Code:** `400 Bad Request`

```json
{
  "error": "id_token or access_token required"
}
```

```json
{
  "error": "Invalid ID token"
}
```

```json
{
  "error": "Token was not issued for this application"
}
```

---

## 2. Facebook Sign-In

Authenticate users with Facebook OAuth access token.

### Endpoint

```
POST /api/v1/auth/social/facebook/
```

### Request Headers

| Header | Value | Required |
|--------|-------|----------|
| `Content-Type` | `application/json` | ✅ |

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `access_token` | string | ✅ | Facebook access token from mobile SDK |

### Example Request

```json
{
  "access_token": "EAAGm0PX4ZCpsBAO..."
}
```

### Success Response

**Status Code:** `200 OK`

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "phone": "+255712345678",
      "email": "user@facebook.com",
      "full_name": "John Doe",
      "is_new": true
    },
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "requires_phone_link": true
  }
}
```

### Error Responses

**Status Code:** `400 Bad Request`

```json
{
  "success": false,
  "message": "access_token required"
}
```

```json
{
  "success": false,
  "message": "Invalid Facebook access token"
}
```

---

## 3. Apple Sign-In

Authenticate users with Apple Sign-In ID token.

### Endpoint

```
POST /api/v1/auth/social/apple/
```

### Request Headers

| Header | Value | Required |
|--------|-------|----------|
| `Content-Type` | `application/json` | ✅ |

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id_token` | string | ✅ | Apple ID token from Sign In with Apple |
| `authorization_code` | string | ❌ | Apple authorization code (alternative to id_token) |
| `user` | object | ❌ | User info object (Apple provides only on first sign-in) |

### User Object Structure (first sign-in only)

```json
{
  "user": {
    "name": {
      "firstName": "John",
      "lastName": "Doe"
    },
    "email": "user@privaterelay.appleid.com"
  }
}
```

### Example Request (First Sign-In)

```json
{
  "id_token": "eyJraWQiOiJXNldjT0tCIiwiYWxnIjoiUlMyNTYifQ...",
  "user": {
    "name": {
      "firstName": "John",
      "lastName": "Doe"
    }
  }
}
```

### Example Request (Returning User)

```json
{
  "id_token": "eyJraWQiOiJXNldjT0tCIiwiYWxnIjoiUlMyNTYifQ..."
}
```

### Success Response

**Status Code:** `200 OK`

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "phone": null,
      "email": "user@privaterelay.appleid.com",
      "full_name": "John Doe",
      "is_new": true
    },
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "requires_phone_link": true
  }
}
```

### Error Responses

**Status Code:** `400 Bad Request`

```json
{
  "error": "id_token or authorization_code required"
}
```

```json
{
  "error": "Invalid ID token"
}
```

```json
{
  "error": "Token was not issued for this application"
}
```

---

## Response Fields Explained

### User Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique user ID in the system |
| `phone` | string | User's phone number (may be null or placeholder) |
| `email` | string | User's email from social provider |
| `full_name` | string | User's full name from social provider |
| `is_new` | boolean | `true` if this is a newly created account |

### Token Fields

| Field | Type | Description |
|-------|------|-------------|
| `access` | string | JWT access token for API authentication (short-lived) |
| `refresh` | string | JWT refresh token for obtaining new access tokens (long-lived) |
| `requires_phone_link` | boolean | `true` if user needs to add/verify phone number |

---

## Using the Tokens

### Authenticated Requests

Include the access token in the Authorization header:

```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Refreshing Tokens

When the access token expires, use the refresh token:

```
POST /api/v1/auth/token/refresh/
```

```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

---

## Phone Linking Flow

When `requires_phone_link` is `true`, the user should be prompted to add their phone number.

### Link Phone Endpoint

```
POST /api/v1/auth/link-phone/
```

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "phone": "+255712345678"
}
```

---

## Mobile SDK Integration

### Google Sign-In

**Android (Kotlin):**
```kotlin
val signInClient = Identity.getSignInClient(activity)
val signInRequest = GetSignInIntentRequest.builder()
    .setServerClientId("YOUR_GOOGLE_CLIENT_ID")
    .build()

// After sign-in, get the ID token
val idToken = credential.googleIdToken
// Send to backend
api.googleLogin(mapOf("id_token" to idToken))
```

**iOS (Swift):**
```swift
GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
    guard let user = result?.user,
          let idToken = user.idToken?.tokenString else { return }
    // Send to backend
    api.googleLogin(["id_token": idToken])
}
```

### Facebook Sign-In

**Android (Kotlin):**
```kotlin
LoginManager.getInstance().logInWithReadPermissions(this, listOf("email", "public_profile"))

override fun onSuccess(result: LoginResult) {
    val accessToken = result.accessToken.token
    api.facebookLogin(mapOf("access_token" to accessToken))
}
```

**iOS (Swift):**
```swift
let loginManager = LoginManager()
loginManager.logIn(permissions: ["email", "public_profile"], from: self) { result, error in
    if let token = AccessToken.current?.tokenString {
        api.facebookLogin(["access_token": token])
    }
}
```

### Apple Sign-In

**iOS (Swift):**
```swift
let appleIDProvider = ASAuthorizationAppleIDProvider()
let request = appleIDProvider.createRequest()
request.requestedScopes = [.fullName, .email]

// In delegate
func authorizationController(controller: ASAuthorizationController, 
                            didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
       let identityToken = appleIDCredential.identityToken,
       let idTokenString = String(data: identityToken, encoding: .utf8) {
        
        var payload: [String: Any] = ["id_token": idTokenString]
        
        // Include user info on first sign-in
        if let fullName = appleIDCredential.fullName {
            payload["user"] = [
                "name": [
                    "firstName": fullName.givenName ?? "",
                    "lastName": fullName.familyName ?? ""
                ]
            ]
        }
        
        api.appleLogin(payload)
    }
}
```

---

## Environment Configuration

### Required Environment Variables

```bash
# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_IOS_CLIENT_ID=your-ios-client-id  # Optional
GOOGLE_ANDROID_CLIENT_ID=your-android-client-id  # Optional

# Facebook OAuth
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret

# Apple Sign-In
APPLE_CLIENT_ID=com.yourapp.service
APPLE_CLIENT_SECRET=your-apple-client-secret
APPLE_KEY_ID=your-key-id
APPLE_PRIVATE_KEY=your-private-key
```

---

## Error Handling Best Practices

1. **Invalid Token**: Re-initiate the social sign-in flow
2. **Network Errors**: Retry with exponential backoff
3. **Phone Required**: Redirect user to phone linking screen
4. **Account Exists**: User may already have account with different provider

---

## Security Notes

1. **Token Validation**: All tokens are validated on the server side
2. **Client ID Verification**: Tokens must be issued for your application
3. **HTTPS Required**: All requests must use HTTPS in production
4. **Token Storage**: Store tokens securely (Keychain on iOS, EncryptedSharedPreferences on Android)

---

## Rate Limiting

| Endpoint | Rate Limit |
|----------|------------|
| All social auth | 10 requests per minute per IP |

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-29 | Initial documentation |
