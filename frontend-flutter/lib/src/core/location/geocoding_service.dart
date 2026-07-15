import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceSearchResult {
  const PlaceSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;
}

abstract class GeocodingService {
  Future<List<PlaceSearchResult>> searchPlaces({
    required String query,
    required String languageCode,
  });

  Future<PlaceSearchResult?> reverseGeocode({
    required double latitude,
    required double longitude,
    required String languageCode,
  });
}

enum GeocodingErrorKind {
  invalidRequest,
  requestFailed,
  timeout,
  unexpectedStatus,
  invalidResponse,
}

class GeocodingException implements Exception {
  const GeocodingException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.cause,
  });

  final GeocodingErrorKind kind;
  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'GeocodingException($kind): $message';
}

class NominatimGeocodingService implements GeocodingService {
  NominatimGeocodingService({
    http.Client? client,
    Uri? baseUri,
    this.requestTimeout = const Duration(seconds: 4),
    this.searchLimit = 5,
    this.userAgent = 'SmartCityReportSystem/1.0 (contact: admin@smartcity.com)',
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? Uri.parse('https://nominatim.openstreetmap.org');

  final http.Client _client;
  final Uri _baseUri;
  final Duration requestTimeout;
  final int searchLimit;
  final String userAgent;

  @override
  Future<List<PlaceSearchResult>> searchPlaces({
    required String query,
    required String languageCode,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const <PlaceSearchResult>[];
    }

    final languagePreference = _languagePreference(languageCode);
    final uri = _endpointUri('search', <String, String>{
      'q': trimmedQuery,
      'format': 'jsonv2',
      'limit': searchLimit.toString(),
      'accept-language': languagePreference,
    });
    final response = await _get(uri, languagePreference);
    _validateStatus(response);

    final decoded = _decodeJson(response);
    if (decoded is! List<dynamic>) {
      throw const GeocodingException(
        kind: GeocodingErrorKind.invalidResponse,
        message: 'Place search response must be a JSON list.',
      );
    }

    return decoded
        .map((item) => _parsePlace(item, operation: 'Place search'))
        .toList(growable: false);
  }

  @override
  Future<PlaceSearchResult?> reverseGeocode({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async {
    _validateCoordinates(latitude, longitude);

    final languagePreference = _languagePreference(languageCode);
    final uri = _endpointUri('reverse', <String, String>{
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'jsonv2',
      'accept-language': languagePreference,
    });
    final response = await _get(uri, languagePreference);
    if (response.statusCode == 404) {
      return null;
    }
    _validateStatus(response);

    final decoded = _decodeJson(response);
    return _parsePlace(decoded, operation: 'Reverse geocoding');
  }

  Uri _endpointUri(String endpoint, Map<String, String> queryParameters) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';
    return _baseUri.replace(
      path: '$basePath$endpoint',
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> _get(Uri uri, String languagePreference) async {
    try {
      return await _client
          .get(
            uri,
            headers: <String, String>{
              'User-Agent': userAgent,
              'Accept-Language': languagePreference,
            },
          )
          .timeout(requestTimeout);
    } on TimeoutException catch (error) {
      throw GeocodingException(
        kind: GeocodingErrorKind.timeout,
        message: 'The geocoding request timed out.',
        cause: error,
      );
    } on GeocodingException {
      rethrow;
    } on Object catch (error) {
      throw GeocodingException(
        kind: GeocodingErrorKind.requestFailed,
        message: 'The geocoding request failed.',
        cause: error,
      );
    }
  }

  void _validateStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeocodingException(
        kind: GeocodingErrorKind.unexpectedStatus,
        message: 'Geocoding returned HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
  }

  dynamic _decodeJson(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on Object catch (error) {
      throw GeocodingException(
        kind: GeocodingErrorKind.invalidResponse,
        message: 'Geocoding returned invalid JSON.',
        cause: error,
      );
    }
  }

  PlaceSearchResult _parsePlace(dynamic value, {required String operation}) {
    if (value is! Map<String, dynamic>) {
      throw GeocodingException(
        kind: GeocodingErrorKind.invalidResponse,
        message: '$operation result must be a JSON object.',
      );
    }

    final displayNameValue = value['display_name'];
    final displayName = displayNameValue is String
        ? displayNameValue.trim()
        : '';
    final latitude = _parseCoordinate(value['lat']);
    final longitude = _parseCoordinate(value['lon']);

    if (displayName.isEmpty ||
        latitude == null ||
        longitude == null ||
        !_coordinatesAreValid(latitude, longitude)) {
      throw GeocodingException(
        kind: GeocodingErrorKind.invalidResponse,
        message: '$operation result contains invalid place data.',
      );
    }

    return PlaceSearchResult(
      displayName: displayName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  double? _parseCoordinate(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  void _validateCoordinates(double latitude, double longitude) {
    if (!_coordinatesAreValid(latitude, longitude)) {
      throw const GeocodingException(
        kind: GeocodingErrorKind.invalidRequest,
        message: 'Coordinates are outside the valid latitude/longitude range.',
      );
    }
  }

  bool _coordinatesAreValid(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  String _languagePreference(String languageCode) {
    final normalizedLanguageCode = languageCode
        .trim()
        .toLowerCase()
        .split(RegExp('[-_]'))
        .first;
    return normalizedLanguageCode == 'vi' ? 'vi,en' : 'en,vi';
  }
}
