/// A fake `package:http` client emulating the Supabase HTTP surface (GoTrue,
/// PostgREST, Storage) for hermetic data-source tests.
///
/// [SupabaseClient] accepts the fake through its `httpClient` constructor
/// argument, so auth/rest/storage requests all flow through [send] and no
/// network is touched.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';

/// An injected failure: HTTP [status] with a JSON error [body].
class ApiError {
  const ApiError(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;
}

/// One captured request.
class RecordedRequest {
  RecordedRequest(
    this.method,
    this.url,
    this.headers,
    this.bodyBytes,
    this.json,
  );

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Uint8List bodyBytes;

  /// Decoded JSON body when it is a map; multipart/binary bodies stay null.
  final Map<String, dynamic>? json;

  String get bodyText => utf8.decode(bodyBytes, allowMalformed: true);
}

/// Canned GoTrue session payload matching the real GoTrue response shape.
Map<String, dynamic> fakeSessionJson({
  String userId = 'user-1',
  String email = 'budi@example.com',
  String phone = '+6281234567890',
  String role = 'customer',
}) {
  return <String, dynamic>{
    'access_token': 'fake-access-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'fake-refresh-token',
    'user': fakeUserJson(
      userId: userId,
      email: email,
      phone: phone,
      role: role,
    ),
  };
}

/// Canned GoTrue user payload (top-level shape used by `/user` and by
/// signup responses that carry no session).
Map<String, dynamic> fakeUserJson({
  String userId = 'user-1',
  String email = 'budi@example.com',
  String phone = '+6281234567890',
  String role = 'customer',
}) {
  return <String, dynamic>{
    'id': userId,
    'aud': 'authenticated',
    'email': email,
    'phone': phone,
    'created_at': '2026-08-01T00:00:00.000Z',
    'app_metadata': <String, dynamic>{'provider': 'email', 'role': role},
    'user_metadata': <String, dynamic>{'role': role},
    'role': 'authenticated',
  };
}

class FakeSupabaseHttp extends BaseClient {
  FakeSupabaseHttp({this.baseUrl = 'https://fake.supabase.co'});

  final String baseUrl;

  /// Captured requests, in order.
  final recorded = <RecordedRequest>[];

  /// Failures keyed by `'METHOD /path'`, e.g. `'POST /auth/v1/token'`.
  final errors = <String, ApiError>{};

  /// Session JSON returned by session-establishing endpoints. When null they
  /// return a standalone user payload instead (signup pending confirmation).
  Map<String, dynamic>? sessionJson = fakeSessionJson();

  // --- PostgREST canned rows -------------------------------------------------
  List<Map<String, dynamic>> profileRows = const [];
  Map<String, dynamic>? profilePatchRow;
  List<Map<String, dynamic>> rpcRows = const [];
  List<Map<String, dynamic>> restaurantRows = const [];
  Map<String, dynamic>? restaurantWriteRow;
  List<Map<String, dynamic>> categoryRows = const [];
  Map<String, dynamic>? categoryWriteRow;
  List<Map<String, dynamic>> itemRows = const [];
  Map<String, dynamic>? itemWriteRow;

  /// The last recorded request.
  RecordedRequest get last => recorded.last;

  /// Recorded requests whose path contains [fragment].
  List<RecordedRequest> requestsFor(String fragment) =>
      recorded.where((r) => r.url.path.contains(fragment)).toList();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final bodyBytes = request is Request
        ? Uint8List.fromList(request.bodyBytes)
        : await request.finalize().toBytes();
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } on FormatException {
      // Multipart/binary upload bodies are not JSON.
    }
    recorded.add(
      RecordedRequest(
        request.method,
        request.url,
        Map.of(request.headers),
        bodyBytes,
        json,
      ),
    );
    return _route(request);
  }

  StreamedResponse _route(BaseRequest request) {
    final route = '${request.method} ${request.url.path}';

    final error = errors[route];
    if (error != null) {
      return _jsonResponse(request, error.status, error.body);
    }

    return switch (route) {
      // --- GoTrue ---
      'POST /auth/v1/token' ||
      'POST /auth/v1/signup' ||
      'POST /auth/v1/verify' => _sessionResponse(request),
      'POST /auth/v1/otp' => _jsonResponse(request, 200, const {}),
      'POST /auth/v1/resend' => _jsonResponse(request, 200, const {
        'message_id': 'message-1',
      }),
      'POST /auth/v1/recover' => _jsonResponse(request, 200, const {}),
      'POST /auth/v1/logout' => _jsonResponse(request, 204, null),
      'PUT /auth/v1/user' => _jsonResponse(request, 200, _updatedUser(request)),
      // --- PostgREST ---
      'GET /rest/v1/profiles' => _jsonResponse(request, 200, profileRows),
      'PATCH /rest/v1/profiles' =>
        profilePatchRow == null
            ? _jsonResponse(request, 200, null)
            : _jsonResponse(request, 200, profilePatchRow),
      'POST /rest/v1/rpc/nearby_restaurants' => _jsonResponse(
        request,
        200,
        rpcRows,
      ),
      'GET /rest/v1/restaurants' => _jsonResponse(request, 200, restaurantRows),
      'POST /rest/v1/restaurants' || 'PATCH /rest/v1/restaurants' =>
        _jsonResponse(request, 201, restaurantWriteRow ?? const {}),
      'POST /rest/v1/restaurant_hours' => _jsonResponse(request, 201, null),
      'GET /rest/v1/menu_categories' => _jsonResponse(
        request,
        200,
        categoryRows,
      ),
      'POST /rest/v1/menu_categories' || 'PATCH /rest/v1/menu_categories' =>
        _jsonResponse(request, 201, categoryWriteRow ?? const {}),
      'DELETE /rest/v1/menu_categories' => _jsonResponse(request, 200, null),
      'GET /rest/v1/menu_items' => _jsonResponse(request, 200, itemRows),
      'POST /rest/v1/menu_items' || 'PATCH /rest/v1/menu_items' =>
        _jsonResponse(request, 201, itemWriteRow ?? const {}),
      'DELETE /rest/v1/menu_items' => _jsonResponse(request, 200, null),
      'POST /rest/v1/merchant_documents' => _jsonResponse(request, 201, null),
      // --- Storage ---
      final r when r.startsWith('POST /storage/v1/object/') => _jsonResponse(
        request,
        200,
        {'Key': request.url.path.substring('/storage/v1/object/'.length)},
      ),
      _ => _jsonResponse(request, 404, {'message': 'No fake route for $route'}),
    };
  }

  /// `/token`, `/signup` and `/verify` share the session-or-user shape.
  StreamedResponse _sessionResponse(BaseRequest request) {
    final session = sessionJson;
    if (session == null) {
      return _jsonResponse(request, 200, fakeUserJson());
    }
    return _jsonResponse(request, 200, session);
  }

  /// `/user` echoes the current user with the requested phone applied.
  Map<String, dynamic> _updatedUser(BaseRequest request) {
    final user = fakeUserJson();
    final requestedPhone = recorded.last.json?['phone'];
    if (requestedPhone is String) {
      user['phone'] = requestedPhone;
    }
    return user;
  }

  StreamedResponse _jsonResponse(
    BaseRequest request,
    int status,
    Object? body,
  ) {
    final bytes = body == null
        ? Uint8List(0)
        : Uint8List.fromList(utf8.encode(jsonEncode(body)));
    return StreamedResponse(
      ByteStream.fromBytes(bytes),
      status,
      request: request,
      headers: const {'content-type': 'application/json'},
    );
  }
}
