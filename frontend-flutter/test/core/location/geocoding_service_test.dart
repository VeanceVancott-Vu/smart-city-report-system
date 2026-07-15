import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_city_report_frontend/src/core/location/geocoding_service.dart';

void main() {
  group('NominatimGeocodingService.searchPlaces', () {
    test(
      'requests jsonv2 in Vietnamese-first order and parses results',
      () async {
        late http.Request capturedRequest;
        final service = NominatimGeocodingService(
          client: MockClient((request) async {
            capturedRequest = request;
            return http.Response(
              jsonEncode(<Map<String, String>>[
                <String, String>{
                  'display_name': 'Chợ Bến Thành, Thành phố Hồ Chí Minh',
                  'lat': '10.77252',
                  'lon': '106.69802',
                },
              ]),
              200,
              headers: const <String, String>{
                'content-type': 'application/json; charset=utf-8',
              },
            );
          }),
        );

        final results = await service.searchPlaces(
          query: '  Chợ Bến Thành  ',
          languageCode: 'vi-VN',
        );

        expect(results, hasLength(1));
        expect(
          results.single.displayName,
          'Chợ Bến Thành, Thành phố Hồ Chí Minh',
        );
        expect(results.single.latitude, 10.77252);
        expect(results.single.longitude, 106.69802);
        expect(capturedRequest.url.path, '/search');
        expect(capturedRequest.url.queryParameters['q'], 'Chợ Bến Thành');
        expect(capturedRequest.url.queryParameters['format'], 'jsonv2');
        expect(capturedRequest.url.queryParameters['limit'], '5');
        expect(capturedRequest.url.queryParameters['accept-language'], 'vi,en');
        expect(capturedRequest.headers['Accept-Language'], 'vi,en');
      },
    );

    test('returns an empty list without requesting an empty query', () async {
      var requestCount = 0;
      final service = NominatimGeocodingService(
        client: MockClient((request) async {
          requestCount++;
          return http.Response('[]', 200);
        }),
      );

      final results = await service.searchPlaces(
        query: '   ',
        languageCode: 'en',
      );

      expect(results, isEmpty);
      expect(requestCount, 0);
    });

    test('throws a typed exception for a non-success status', () async {
      final service = NominatimGeocodingService(
        client: MockClient(
          (request) async => http.Response('Unavailable', 503),
        ),
      );

      await expectLater(
        service.searchPlaces(query: 'market', languageCode: 'en'),
        throwsA(
          isA<GeocodingException>()
              .having(
                (error) => error.kind,
                'kind',
                GeocodingErrorKind.unexpectedStatus,
              )
              .having((error) => error.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('throws a typed exception for malformed JSON', () async {
      final service = NominatimGeocodingService(
        client: MockClient((request) async => http.Response('{broken', 200)),
      );

      await expectLater(
        service.searchPlaces(query: 'market', languageCode: 'en'),
        throwsA(
          isA<GeocodingException>().having(
            (error) => error.kind,
            'kind',
            GeocodingErrorKind.invalidResponse,
          ),
        ),
      );
    });

    test('rejects result coordinates outside valid ranges', () async {
      final service = NominatimGeocodingService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(<Map<String, String>>[
              <String, String>{
                'display_name': 'Invalid place',
                'lat': '91',
                'lon': '106.7',
              },
            ]),
            200,
          ),
        ),
      );

      await expectLater(
        service.searchPlaces(query: 'invalid', languageCode: 'en'),
        throwsA(
          isA<GeocodingException>().having(
            (error) => error.kind,
            'kind',
            GeocodingErrorKind.invalidResponse,
          ),
        ),
      );
    });
  });

  group('NominatimGeocodingService.reverseGeocode', () {
    test('uses English-first order and parses a place', () async {
      late http.Request capturedRequest;
      final service = NominatimGeocodingService(
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode(<String, String>{
              'display_name': 'Ben Thanh Market, Ho Chi Minh City',
              'lat': '10.77252',
              'lon': '106.69802',
            }),
            200,
          );
        }),
      );

      final result = await service.reverseGeocode(
        latitude: 10.77252,
        longitude: 106.69802,
        languageCode: 'en-US',
      );

      expect(result, isNotNull);
      expect(result!.displayName, 'Ben Thanh Market, Ho Chi Minh City');
      expect(capturedRequest.url.path, '/reverse');
      expect(capturedRequest.url.queryParameters['lat'], '10.77252');
      expect(capturedRequest.url.queryParameters['lon'], '106.69802');
      expect(capturedRequest.url.queryParameters['format'], 'jsonv2');
      expect(capturedRequest.url.queryParameters['accept-language'], 'en,vi');
      expect(capturedRequest.headers['Accept-Language'], 'en,vi');
    });

    test('returns null when no reverse-geocoding result exists', () async {
      final service = NominatimGeocodingService(
        client: MockClient((request) async => http.Response('Not found', 404)),
      );

      final result = await service.reverseGeocode(
        latitude: 10.77252,
        longitude: 106.69802,
        languageCode: 'en',
      );

      expect(result, isNull);
    });

    test(
      'rejects invalid input coordinates without making a request',
      () async {
        var requestCount = 0;
        final service = NominatimGeocodingService(
          client: MockClient((request) async {
            requestCount++;
            return http.Response('{}', 200);
          }),
        );

        await expectLater(
          service.reverseGeocode(
            latitude: double.nan,
            longitude: 106.7,
            languageCode: 'en',
          ),
          throwsA(
            isA<GeocodingException>().having(
              (error) => error.kind,
              'kind',
              GeocodingErrorKind.invalidRequest,
            ),
          ),
        );
        expect(requestCount, 0);
      },
    );
  });
}
