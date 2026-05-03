# Mobile App Integration Guide

## Flutter API Client Configuration

The Flutter mobile app should connect to the same Trail Quest API. Update the following:

### 1. API Client Setup (`lib/core/api/api_client.dart`)

```dart
const String API_BASE_URL = 'http://localhost:4000'; // Change for production
const String API_TIMEOUT = Duration(seconds: 30);

class ApiClient {
  late Dio dio;
  late String? accessToken;
  late String? refreshToken;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: API_BASE_URL,
      connectTimeout: API_TIMEOUT,
      receiveTimeout: API_TIMEOUT,
      contentType: 'application/json',
    ));

    // Request interceptor - add auth token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          return handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired - try refresh
            try {
              final newTokens = await _refreshToken();
              accessToken = newTokens['access_token'];
              refreshToken = newTokens['refresh_token'];
              // Retry original request
              return handler.resolve(await _retry(error.requestOptions));
            } catch (e) {
              // Refresh failed - redirect to login
              navigateToLogin();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, String>> _refreshToken() async {
    final response = await dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    return response.data;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
```

### 2. Authentication Flow

**Register / Login:**
```dart
// POST /auth/register
{
  "email": "explorer@example.com",
  "username": "adventurer",
  "password": "SecurePassword123"
}

// Response:
{
  "access_token": "eyJhbGc...",
  "refresh_token": "4a7f...",
  "user": {
    "id": "uuid",
    "email": "explorer@example.com",
    "username": "adventurer",
    "roles": ["USER"]
  }
}
```

### 3. Key Endpoints for Mobile

#### Authentication
- `POST /auth/register` - Create account
- `POST /auth/login` - Sign in with email/password
- `POST /auth/refresh` - Refresh access token

#### User Profile
- `GET /users/me` - Get current user info
- `PUT /users/me` - Update profile
- `GET /users/:id/stats` - Get user statistics

#### Destinations (Map Display)
- `GET /destinations` - List all (paginated)
  - Query params: `page`, `limit`, `category`, `region`
  - Response includes: id, name, latitude, longitude, category, imageUrl
- `GET /destinations/:id` - Get details with nearby quests

#### Quests
- `GET /quests` - List active quests (paginated)
  - Query params: `page`, `limit`, `destinationId`, `difficulty`
- `GET /quests/:id` - Get quest details including checkpoints
- `GET /quests/:id/checkpoints` - Get ordered checkpoints with clues

#### Check-ins (Core Feature)
- `POST /checkpoints/checkin` - Record visit
  ```json
  {
    "checkpointId": "uuid",
    "questId": "uuid",
    "photoUrl": "https://...",
    "timestamp": "2024-05-02T10:30:00Z"
  }
  ```
- `POST /checkpoints/verify-qr` - Verify QR code
  ```json
  {
    "qrCode": "generated_qr_value",
    "checkpointId": "uuid"
  }
  ```

#### Progression
- `GET /passports/me` - Get current user passport
  - Response: totalXp, level, stampsCollected, badges
- `GET /passports/:id/badges` - Get user badges
- `POST /rewards/redeem` - Redeem earned reward
  ```json
  {
    "rewardId": "uuid",
    "quantity": 1
  }
  ```

#### Leaderboards
- `GET /leaderboards/weekly` - Top explorers this week
- `GET /leaderboards/monthly` - Top explorers this month
- `GET /leaderboards/all-time` - All-time top explorers
- Response: array of {userId, username, totalXp, level, rank, questsCompleted}

### 4. Data Models for Flutter

```dart
// User
class User {
  final String id;
  final String email;
  final String username;
  final List<String> roles;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  User.fromJson(Map<String, dynamic> json) : /* ... */;
}

// Destination
class Destination {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String category;
  final String? imageUrl;
  final bool isPublished;
  
  Destination.fromJson(Map<String, dynamic> json) : /* ... */;
}

// Quest
class Quest {
  final String id;
  final String title;
  final String description;
  final String destinationId;
  final int checkpointCount;
  final String difficulty;
  final int xpReward;
  
  Quest.fromJson(Map<String, dynamic> json) : /* ... */;
}

// Checkpoint
class Checkpoint {
  final String id;
  final String questId;
  final int sequence;
  final double latitude;
  final double longitude;
  final String name;
  final String? clueText;
  final String qrCode;
  final int baseXp;
  
  Checkpoint.fromJson(Map<String, dynamic> json) : /* ... */;
}

// Passport
class Passport {
  final String id;
  final String userId;
  final int totalXp;
  final int level;
  final int stampsCollected;
  final List<Badge> badges;
  
  Passport.fromJson(Map<String, dynamic> json) : /* ... */;
}

// Badge
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime? unlockedAt;
  
  Badge.fromJson(Map<String, dynamic> json) : /* ... */;
}
```

### 5. Feature Implementation Checklist

- [ ] Update `lib/core/api/api_client.dart` with real API URL
- [ ] Implement authentication flows in `lib/features/auth/`
- [ ] Create API service classes for each module
- [ ] Implement state management (Riverpod/Provider/Bloc)
- [ ] Update map screen to fetch and display destinations
- [ ] Implement quest listing and details
- [ ] Add checkpoint check-in flow with camera/photos
- [ ] Implement QR code scanning for verification
- [ ] Add passport/progression display
- [ ] Implement leaderboard display
- [ ] Add reward redemption flow
- [ ] Handle JWT token refresh automatically
- [ ] Add error handling and logging

### 6. Testing API Integration

Use Postman or cURL to test endpoints first:

```bash
# Register
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mobile@example.com",
    "username": "mobileuser",
    "password": "SecurePass123"
  }'

# Login and get token
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mobile@example.com",
    "password": "SecurePass123"
  }'

# Get destinations with token
curl -X GET http://localhost:4000/destinations \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 7. Environment Configuration

Create `lib/config.dart`:

```dart
const String getApiUrl() {
  const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'development');
  switch (flavor) {
    case 'production':
      return 'https://api.trailquest.com';
    case 'staging':
      return 'https://staging-api.trailquest.com';
    default:
      return 'http://localhost:4000';
  }
}
```

Run with flavor: `flutter run -t lib/main.dart --dart-define=FLAVOR=production`

---

For more detailed integration information, see [INTEGRATION.md](../INTEGRATION.md)
