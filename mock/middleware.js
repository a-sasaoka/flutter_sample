const fs = require('fs');
const path = require('path');

/**
 * Google Encoded Polyline Algorithm で座標リストを文字列にエンコードするヘルパー
 * @param {Array<[number, number]>} points [latitude, longitude] の配列
 * @returns {string} エンコードされたポリライン文字列
 */
function encodePolyline(points) {
  let result = '';
  let prevLat = 0;
  let prevLng = 0;

  for (const [lat, lng] of points) {
    const latE5 = Math.round(lat * 1e5);
    const lngE5 = Math.round(lng * 1e5);

    const dLat = latE5 - prevLat;
    const dLng = lngE5 - prevLng;

    prevLat = latE5;
    prevLng = lngE5;

    for (let val of [dLat, dLng]) {
      let v = val < 0 ? ~(val << 1) : val << 1;
      while (v >= 0x20) {
        result += String.fromCharCode((0x20 | (v & 0x1f)) + 63);
        v >>= 5;
      }
      result += String.fromCharCode(v + 63);
    }
  }
  return result;
}

/**
 * 2点間の直線補間座標リスト（5点）を生成するヘルパー
 */
function interpolatePoints(startLat, startLng, endLat, endLng, count = 5) {
  const points = [];
  for (let i = 0; i < count; i++) {
    const fraction = i / (count - 1);
    const lat = startLat + (endLat - startLat) * fraction;
    const lng = startLng + (endLng - startLng) * fraction;
    points.push([lat, lng]);
  }
  return points;
}

/**
 * 2地点間の概算距離（メートル）を計算するヘルパー（簡易計算）
 */
function approximateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // 地球の半径 (メートル)
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c);
}

/**
 * モック用の定番スポットデータベース
 */
const MOCK_PLACES_DATABASE = [
  {
    id: 'mock_place_tokyo_station',
    displayName: { text: '東京駅' },
    formattedAddress: '東京都千代田区丸の内１丁目',
    location: { latitude: 35.681236, longitude: 139.767125 },
    primaryType: 'train_station',
    rating: 4.4,
  },
  {
    id: 'mock_place_tokyo_tower',
    displayName: { text: '東京タワー' },
    formattedAddress: '東京都港区芝公園４丁目２−８',
    location: { latitude: 35.6585805, longitude: 139.7454329 },
    primaryType: 'tourist_attraction',
    rating: 4.6,
  },
  {
    id: 'mock_place_skytree',
    displayName: { text: '東京スカイツリー' },
    formattedAddress: '東京都墨田区押上１丁目１−２',
    location: { latitude: 35.710063, longitude: 139.8107 },
    primaryType: 'tourist_attraction',
    rating: 4.6,
  },
  {
    id: 'mock_place_shinjuku_gyoen',
    displayName: { text: '新宿御苑' },
    formattedAddress: '東京都新宿区内藤町１１',
    location: { latitude: 35.685176, longitude: 139.710052 },
    primaryType: 'park',
    rating: 4.5,
  },
  {
    id: 'mock_place_shibuya_scramble',
    displayName: { text: '渋谷スクランブル交差点' },
    formattedAddress: '東京都渋谷区道玄坂２丁目２−１',
    location: { latitude: 35.659482, longitude: 139.700553 },
    primaryType: 'tourist_attraction',
    rating: 4.5,
  },
  {
    id: 'mock_place_asakusa_sensoji',
    displayName: { text: '浅草寺' },
    formattedAddress: '東京都台東区浅草２丁目３−１',
    location: { latitude: 35.714765, longitude: 139.796655 },
    primaryType: 'place_of_worship',
    rating: 4.6,
  },
  {
    id: 'mock_place_osaka_castle',
    displayName: { text: '大阪城' },
    formattedAddress: '大阪府大阪市中央区大阪城１−１',
    location: { latitude: 34.687315, longitude: 135.526201 },
    primaryType: 'tourist_attraction',
    rating: 4.5,
  },
  {
    id: 'mock_place_kyoto_tower',
    displayName: { text: '京都タワー' },
    formattedAddress: '京都府京都市下京区烏丸通七条下る東塩小路町７２１−１',
    location: { latitude: 34.987519, longitude: 135.759239 },
    primaryType: 'tourist_attraction',
    rating: 4.2,
  },
];

/**
 * json-server用の拡張ミドルウェア
 */
module.exports = (req, res, next) => {
  const failFilePath = path.join(__dirname, 'fail');

  // 1. エラースイッチの判定
  if (fs.existsSync(failFilePath)) {
    console.log('⚠️ [Mock Server] Error switch is ON. Returning 500 error.');
    return res.status(500).jsonp({
      error: 'サーバー内部でエラーが発生しました（ファイルスイッチによる擬似エラー）',
      method: req.method,
      path: req.url,
    });
  }

  // 2. POST /computeRoutesProxy（Google Routes API モック）
  if (req.method === 'POST' && (req.path === '/computeRoutesProxy' || req.url === '/computeRoutesProxy')) {
    console.log('📍 [Mock Server] POST /computeRoutesProxy received:', req.body);
    const body = req.body || {};
    if (typeof body !== 'object') {
      return res.status(400).json({ error: 'Bad Request: リクエストボディが無効です。' });
    }

    const { origin, destination, travelMode } = body;
    const originLat = origin?.location?.latLng?.latitude;
    const originLng = origin?.location?.latLng?.longitude;
    const destLat = destination?.location?.latLng?.latitude;
    const destLng = destination?.location?.latLng?.longitude;

    if (
      typeof originLat !== 'number' ||
      typeof originLng !== 'number' ||
      typeof destLat !== 'number' ||
      typeof destLng !== 'number'
    ) {
      return res.status(400).json({
        error: 'Bad Request: origin と destination の有効な座標(数値)が必要です。',
      });
    }

    // travelMode の許可値チェック & 安全な正規化
    const allowedTravelModes = new Set([
      'DRIVE',
      'WALK',
      'BICYCLE',
      'TWO_WHEELER',
      'TRANSIT',
    ]);
    const validTravelMode =
      typeof travelMode === 'string' && allowedTravelModes.has(travelMode.toUpperCase())
        ? travelMode.toUpperCase()
        : 'DRIVE';

    const distanceMeters = Math.max(approximateDistance(originLat, originLng, destLat, destLng), 500);

    // 移動手段ごとの概算速度（m/s）
    let speedMps = 10; // DRIVE: 約36km/h
    let warnings;
    if (validTravelMode === 'WALK') {
      speedMps = 1.3; // WALK: 約4.7km/h
      warnings = ['徒歩ルートには歩道が整備されていない区間が含まれる場合があります。'];
    } else if (validTravelMode === 'BICYCLE') {
      speedMps = 4.2; // BICYCLE: 約15km/h
      warnings = ['自転車ルートには自転車専用レーンがない道路が含まれる場合があります。'];
    } else if (validTravelMode === 'TRANSIT') {
      speedMps = 8.0; // TRANSIT: 約28km/h
    }

    const durationSeconds = Math.round(distanceMeters / speedMps);
    const points = interpolatePoints(originLat, originLng, destLat, destLng, 6);
    const encodedPolyline = encodePolyline(points);

    const mockResponse = {
      routes: [
        {
          polyline: {
            encodedPolyline,
          },
          distanceMeters,
          duration: `${durationSeconds}s`,
          ...(warnings ? { warnings } : {}),
        },
      ],
    };

    return res.status(200).json(mockResponse);
  }

  // 3. POST /placesSearchProxy（Google Places API モック）
  if (req.method === 'POST' && (req.path === '/placesSearchProxy' || req.url === '/placesSearchProxy')) {
    console.log('🔍 [Mock Server] POST /placesSearchProxy received:', req.body);
    const body = req.body || {};
    const { textQuery, maxResultCount } = body;

    // 本番プロキシと同一のバリデーション契約 (1〜100文字の文字列チェック)
    if (typeof textQuery !== 'string' || textQuery.trim().length === 0 || textQuery.length > 100) {
      return res.status(400).json({
        error: 'Bad Request: textQuery は 1〜100 文字の文字列である必要があります。',
      });
    }

    // 本番プロキシと同一の maxResultCount 正規化 (1〜20 は整数化、それ以外はデフォルト 10)
    const validPageSize =
      typeof maxResultCount === 'number' && maxResultCount >= 1 && maxResultCount <= 20
        ? Math.floor(maxResultCount)
        : 10;

    const trimmedQuery = textQuery.trim();
    const query = trimmedQuery.toLowerCase();

    // クエリに合致するスポットを検索
    let matches = MOCK_PLACES_DATABASE.filter(
      (p) =>
        p.displayName.text.toLowerCase().includes(query) ||
        p.formattedAddress.toLowerCase().includes(query) ||
        p.primaryType.toLowerCase().includes(query)
    );

    // 合致するものがない場合は、入力クエリに基づいた動的ダミー候補を生成
    if (matches.length === 0) {
      matches = [
        {
          id: `mock_place_${Date.now()}_1`,
          displayName: { text: `${trimmedQuery} 本店` },
          formattedAddress: `東京都千代田区1-1 (${trimmedQuery})`,
          location: { latitude: 35.681236 + 0.005, longitude: 139.767125 + 0.005 },
          primaryType: 'point_of_interest',
          rating: 4.3,
        },
        {
          id: `mock_place_${Date.now()}_2`,
          displayName: { text: `${trimmedQuery} 新宿店` },
          formattedAddress: `東京都新宿区3-3 (${trimmedQuery})`,
          location: { latitude: 35.689487, longitude: 139.691706 },
          primaryType: 'point_of_interest',
          rating: 4.1,
        },
        {
          id: `mock_place_${Date.now()}_3`,
          displayName: { text: `${trimmedQuery} 渋谷店` },
          formattedAddress: `東京都渋谷区2-2 (${trimmedQuery})`,
          location: { latitude: 35.659482, longitude: 139.700553 },
          primaryType: 'point_of_interest',
          rating: 4.5,
        },
      ];
    }

    return res.status(200).json({
      places: matches.slice(0, validPageSize),
    });
  }

  // 4. POST /auth/login モック（常にダミートークンを返却）
  if (req.method === 'POST' && (req.path === '/auth/login' || req.url === '/auth/login')) {
    console.log('🔑 [Mock Server] POST /auth/login received');
    return res.status(200).json({
      access_token: 'mock_local_access_token_123',
      refresh_token: 'mock_local_refresh_token_456',
    });
  }

  // 5. POST /auth/refresh モック（常に新しいダミートークンを返却）
  if (req.method === 'POST' && (req.path === '/auth/refresh' || req.url === '/auth/refresh')) {
    console.log('🔄 [Mock Server] POST /auth/refresh received');
    return res.status(200).json({
      access_token: 'mock_local_refreshed_access_token_789',
    });
  }

  // 6. それ以外は json-server の通常処理を続行
  next();
};
