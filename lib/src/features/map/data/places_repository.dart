import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'places_repository.g.dart';

/// 🗺️ Google Places API 検索リポジトリのインターフェース
// ignore: one_member_abstracts, リポジトリ層の単一責務インターフェースのため
abstract interface class PlacesRepository {
  /// キーワード文字列から複数施設・スポットの候補地リストを検索する
  Future<List<LocationCandidate>> searchPlaces(
    String textQuery, {
    String? languageCode,
    int maxResultCount = 10,
  });
}

/// Google Places API (Text Search) プロキシサーバーと通信する実装クラス
class PlacesRepositoryImpl implements PlacesRepository {
  /// コンストラクタ
  const PlacesRepositoryImpl({
    required Dio dio,
    required String placesApiUrl,
  }) : _dio = dio,
       _placesApiUrl = placesApiUrl;

  final Dio _dio;
  final String _placesApiUrl;

  @override
  Future<List<LocationCandidate>> searchPlaces(
    String textQuery, {
    String? languageCode,
    int maxResultCount = 10,
  }) async {
    final trimmedQuery = textQuery.trim();
    if (trimmedQuery.isEmpty) {
      return const <LocationCandidate>[];
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _placesApiUrl,
        data: {
          'textQuery': trimmedQuery,
          'languageCode': languageCode ?? 'ja',
          'maxResultCount': maxResultCount,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const PlacesApiException('Places response data is empty.');
      }

      final rawPlaces = data['places'] as List<dynamic>?;
      if (rawPlaces == null || rawPlaces.isEmpty) {
        return const <LocationCandidate>[];
      }

      final candidates = <LocationCandidate>[];
      for (final raw in rawPlaces) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }

        final id = raw['id'] as String?;
        final displayNameMap = raw['displayName'] as Map<String, dynamic>?;
        final name = displayNameMap?['text'] as String? ?? trimmedQuery;
        final address = raw['formattedAddress'] as String?;
        final locationMap = raw['location'] as Map<String, dynamic>?;

        final lat = (locationMap?['latitude'] as num?)?.toDouble();
        final lng = (locationMap?['longitude'] as num?)?.toDouble();

        if (lat == null || lng == null) {
          continue;
        }

        final primaryType = raw['primaryType'] as String?;
        final rating = (raw['rating'] as num?)?.toDouble();

        candidates.add(
          LocationCandidate(
            latitude: lat,
            longitude: lng,
            name: name,
            address: address,
            placeId: id,
            primaryType: primaryType,
            rating: rating,
          ),
        );
      }

      return candidates;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      final errorMessage = responseData is Map<String, dynamic>
          ? responseData['error']?.toString()
          : null;

      if (statusCode == 401) {
        throw PlacesApiException(
          errorMessage ?? 'Unauthorized: ログインが必要です。',
          statusCode: 401,
        );
      } else if (statusCode == 429) {
        throw PlacesApiException(
          errorMessage ?? 'Too Many Requests: リクエスト上限を超過しました。',
          statusCode: 429,
        );
      }

      throw PlacesApiException(
        errorMessage ?? e.message ?? 'Places API error occurred.',
        statusCode: statusCode,
      );
    } catch (e) {
      if (e is PlacesApiException) {
        rethrow;
      }
      throw PlacesApiException('Failed to search places: $e');
    }
  }
}

/// テスト・オフライン用のモックリポジトリ
class MockPlacesRepositoryImpl implements PlacesRepository {
  /// コンストラクタ
  const MockPlacesRepositoryImpl({
    this.mockCandidates = const <LocationCandidate>[],
    this.delay = Duration.zero,
    this.shouldThrow = false,
  });

  /// 返却するモック候補地リスト
  final List<LocationCandidate> mockCandidates;

  /// 擬似的な通信遅延
  final Duration delay;

  /// 例外を発生させるかどうか
  final bool shouldThrow;

  @override
  Future<List<LocationCandidate>> searchPlaces(
    String textQuery, {
    String? languageCode,
    int maxResultCount = 10,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldThrow) {
      throw const PlacesApiException('Mock Places API error.');
    }
    if (mockCandidates.isNotEmpty) {
      return mockCandidates.take(maxResultCount).toList();
    }

    // デフォルトのダミー候補を生成
    return [
      LocationCandidate(
        latitude: 35.6895,
        longitude: 139.6917,
        name: '$textQuery (東京都庁付近)',
        address: '東京都新宿区西新宿２丁目８−１',
        placeId: 'mock_place_1',
        primaryType: 'city_hall',
        rating: 4.5,
      ),
      LocationCandidate(
        latitude: 35.6909,
        longitude: 139.7005,
        name: '$textQuery (新宿駅東口)',
        address: '東京都新宿区新宿３丁目３８−１',
        placeId: 'mock_place_2',
        primaryType: 'train_station',
        rating: 4.2,
      ),
    ].take(maxResultCount).toList();
  }
}

/// Places API 呼び出し時の例外クラス
class PlacesApiException implements Exception {
  /// コンストラクタ
  const PlacesApiException(this.message, {this.statusCode});

  /// エラーメッセージ
  final String message;

  /// HTTPステータスコード（存在する場合）
  final int? statusCode;

  @override
  String toString() => message;
}

/// PlacesRepository を提供する Riverpod プロバイダー
@Riverpod(keepAlive: true)
PlacesRepository placesRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  final envConfig = ref.watch(envConfigProvider);
  return PlacesRepositoryImpl(
    dio: dio,
    placesApiUrl: '${envConfig.baseUrl}/placesSearchProxy',
  );
}
