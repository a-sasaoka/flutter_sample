import {setGlobalOptions} from "firebase-functions/v2";
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {GoogleAuth} from "google-auth-library";
import axios, {isAxiosError} from "axios";

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({maxInstances: 10});

/**
 * Express request helper to extract and verify ID token.
 * @param {object} req Express request with authorization header
 * @return {Promise<string | null>} Verified UID or null
 */
async function getUidFromRequest(
  req: { headers: { authorization?: string } }
): Promise<string | null> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return null;
  }
  const idToken = authHeader.split("Bearer ")[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken.uid;
  } catch (error) {
    logger.error("Token verification failed: ", error);
    return null;
  }
}

/**
 * Helper to check if the request is made by an admin.
 * @param {object} req Express request with authorization header
 * @return {Promise<boolean>} True if the user has admin claims
 */
async function isAdminRequest(
  req: { headers: { authorization?: string } }
): Promise<boolean> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return false;
  }
  const idToken = authHeader.split("Bearer ")[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken.admin === true;
  } catch (error) {
    return false;
  }
}

/**
 * Memos API endpoint.
 * @param {object} req Express request object
 * @param {object} res Express response object
 * @return {Promise<void>}
 */
export const memos = onRequest(async (req, res) => {
  const uid = await getUidFromRequest(req);
  if (!uid) {
    res.status(401).send("Unauthorized");
    return;
  }

  const pathParts = req.path.split("/").filter((p) => p !== "");
  const memoId = pathParts.length > 0 ? pathParts[0] : null;

  const userMemosRef = db.collection("users").doc(uid).collection("memos");

  try {
    if (req.method === "GET") {
      if (memoId) {
        const doc = await userMemosRef.doc(memoId).get();
        if (!doc.exists) {
          res.status(404).send("Not Found");
          return;
        }
        res.status(200).json({id: doc.id, ...doc.data()});
      } else {
        const snapshot = await userMemosRef.orderBy("createdAt", "desc").get();
        const list = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
        res.status(200).json(list);
      }
    } else if (req.method === "POST") {
      const {title, content} = req.body;
      if (typeof title !== "string" || typeof content !== "string") {
        res.status(400).send("Bad Request: title and content must be strings");
        return;
      }
      const now = new Date().toISOString();
      const memoData = {
        title,
        content: content || "",
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      };

      const id = req.body.id;
      if (id) {
        if (typeof id !== "string") {
          res.status(400).send("Bad Request: id must be a string");
          return;
        }
        const docRef = userMemosRef.doc(id);
        try {
          await docRef.create(memoData);
          res.status(201).json({id, ...memoData});
        } catch (error) {
          const err = error as { code?: number };
          if (err.code === 6) {
            res.status(409).send("Conflict: Memo with this ID already exists");
            return;
          }
          throw error;
        }
      } else {
        const docRef = await userMemosRef.add(memoData);
        res.status(201).json({id: docRef.id, ...memoData});
      }
    } else if (req.method === "PUT") {
      if (!memoId) {
        res.status(400).send("ID is required");
        return;
      }
      const {title, content, isDeleted} = req.body;
      if (typeof title !== "string" || typeof content !== "string") {
        res.status(400).send("Bad Request: title and content must be strings");
        return;
      }
      if (isDeleted !== undefined && typeof isDeleted !== "boolean") {
        res.status(400).send("Bad Request: isDeleted must be a boolean");
        return;
      }
      const now = new Date().toISOString();

      const docRef = userMemosRef.doc(memoId);
      const doc = await docRef.get();
      if (!doc.exists) {
        res.status(404).send("Not Found");
        return;
      }

      const updateData: Record<string, unknown> = {
        title,
        content: content || "",
        updatedAt: now,
      };
      if (isDeleted !== undefined) {
        updateData.isDeleted = isDeleted;
      }

      await docRef.update(updateData);
      res.status(200).send("OK");
    } else {
      res.status(405).send("Method Not Allowed");
    }
  } catch (error) {
    logger.error("Error handling memos API: ", error);
    res.status(500).send("Internal Server Error");
  }
});

/**
 * Users API endpoint.
 * @param {object} req Express request object
 * @param {object} res Express response object
 * @return {Promise<void>}
 */
export const users = onRequest(async (req, res) => {
  const uid = await getUidFromRequest(req);
  if (!uid) {
    res.status(401).send("Unauthorized");
    return;
  }

  const pathParts = req.path.split("/").filter((p) => p !== "");
  const firstPath = pathParts.length > 0 ? pathParts[0] : null;

  try {
    if (firstPath === "me") {
      const docRef = db.collection("users").doc(uid);

      if (req.method === "GET") {
        const doc = await docRef.get();
        if (!doc.exists) {
          const userRecord = await admin.auth().getUser(uid);
          const initialProfile = {
            name: userRecord.displayName || "テストユーザー",
            email: userRecord.email || "",
            displayName: userRecord.displayName || "テスト",
            phone: userRecord.phoneNumber || "",
          };
          await docRef.set(initialProfile);
          res.status(200).json(initialProfile);
        } else {
          res.status(200).json(doc.data());
        }
      } else if (req.method === "PUT") {
        const {name, displayName, phone, email} = req.body;
        if (
          (name !== undefined && typeof name !== "string") ||
          (displayName !== undefined && typeof displayName !== "string") ||
          (phone !== undefined && typeof phone !== "string") ||
          (email !== undefined && typeof email !== "string")
        ) {
          res.status(400).send("Bad Request: Profile fields must be strings");
          return;
        }

        const updatedProfile = {
          name: name || "",
          displayName: displayName || "",
          phone: phone || "",
          email: email || "",
        };
        await docRef.set(updatedProfile, {merge: true});
        res.status(200).json(updatedProfile);
      } else {
        res.status(405).send("Method Not Allowed");
      }
      return;
    }

    if (
      req.method === "POST" ||
      req.method === "PUT" ||
      req.method === "PATCH" ||
      req.method === "DELETE"
    ) {
      const isAdmin = await isAdminRequest(req);
      if (!isAdmin) {
        res.status(403).send("Forbidden: Admin privilege required");
        return;
      }
    }

    if (req.method === "GET") {
      if (firstPath) {
        const doc = await db.collection("users_list").doc(firstPath).get();
        if (!doc.exists) {
          res.status(404).send("Not Found");
          return;
        }
        res.status(200).json({id: doc.id, ...doc.data()});
      } else {
        const snapshot = await db.collection("users_list").get();
        const list = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
        res.status(200).json(list);
      }
    } else if (req.method === "POST") {
      const userData = {
        name: req.body.name || "",
        email: req.body.email || "",
        phone: req.body.phone || "",
        website: req.body.website || "",
        address: req.body.address || {},
      };

      const id = req.body.id;
      if (id) {
        await db.collection("users_list").doc(id.toString()).set(userData);
        res.status(201).json({id, ...userData});
      } else {
        const docRef = await db.collection("users_list").add(userData);
        res.status(201).json({id: docRef.id, ...userData});
      }
    } else if (req.method === "PUT" || req.method === "PATCH") {
      if (!firstPath) {
        res.status(400).send("ID is required");
        return;
      }
      const docRef = db.collection("users_list").doc(firstPath);
      const doc = await docRef.get();
      if (!doc.exists) {
        res.status(404).send("Not Found");
        return;
      }

      const {name, email, phone, website, address} = req.body;
      if (
        (name !== undefined && typeof name !== "string") ||
        (email !== undefined && typeof email !== "string") ||
        (phone !== undefined && typeof phone !== "string") ||
        (website !== undefined && typeof website !== "string") ||
        (address !== undefined && (
          typeof address !== "object" ||
          address === null ||
          Array.isArray(address)
        ))
      ) {
        res.status(400).send("Bad Request: Invalid field types");
        return;
      }

      let updatedData: Record<string, unknown> = {};
      if (req.method === "PUT") {
        updatedData = {
          name: name || "",
          email: email || "",
          phone: phone || "",
          website: website || "",
          address: address || {},
        };
      } else {
        // PATCH: 指定されたフィールドのみを部分更新
        if (name !== undefined) updatedData.name = name;
        if (email !== undefined) updatedData.email = email;
        if (phone !== undefined) updatedData.phone = phone;
        if (website !== undefined) updatedData.website = website;
        if (address !== undefined) updatedData.address = address;

        // PATCH時、更新する項目が1つもない場合は400エラーにする
        if (Object.keys(updatedData).length === 0) {
          res.status(400).send("Bad Request: No fields specified for update");
          return;
        }
      }

      if (req.method === "PUT") {
        // PUT: ドキュメント全体を完全置換（存在確認と同一トランザクション内で実行）
        try {
          await db.runTransaction(async (transaction) => {
            const transactionDoc = await transaction.get(docRef);
            if (!transactionDoc.exists) {
              throw new Error("NOT_FOUND");
            }
            transaction.set(docRef, updatedData);
          });
          res.status(200).json({
            id: firstPath,
            ...updatedData,
          });
        } catch (error) {
          const err = error as Error;
          if (err.message === "NOT_FOUND") {
            res.status(404).send("Not Found");
            return;
          }
          throw error;
        }
      } else {
        // PATCH: 部分更新し、既存データとマージした結果を返す
        await docRef.update(updatedData);
        res.status(200).json({
          id: firstPath,
          ...doc.data(),
          ...updatedData,
        });
      }
    } else if (req.method === "DELETE") {
      if (!firstPath) {
        res.status(400).send("ID is required");
        return;
      }
      await db.collection("users_list").doc(firstPath).delete();
      res.status(200).send("OK");
    } else {
      res.status(405).send("Method Not Allowed");
    }
  } catch (error) {
    logger.error("Error handling users API: ", error);
    res.status(500).send("Internal Server Error");
  }
});

// ユーザーごとのレート制限管理 (Cloud Firestore による全インスタンス共通制御: 1分あたり最大30回)
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const MAX_REQUESTS_PER_MINUTE = 30;

/**
 * Checks whether the specified UID exceeds the rate limit using Firestore.
 *
 * @param {string} uid User ID.
 * @return {Promise<boolean>} True if allowed, false if rate limited.
 */
async function checkRateLimit(uid: string): Promise<boolean> {
  const now = Date.now();
  const docRef = admin
    .firestore()
    .collection("rate_limits")
    .doc(`routes_${uid}`);

  try {
    return await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(docRef);
      if (!snap.exists) {
        tx.set(docRef, {
          count: 1,
          resetAt: now + RATE_LIMIT_WINDOW_MS,
        });
        return true;
      }

      const data = snap.data();
      const resetAt = data?.resetAt || 0;
      const count = data?.count || 0;

      if (now > resetAt) {
        tx.set(docRef, {
          count: 1,
          resetAt: now + RATE_LIMIT_WINDOW_MS,
        });
        return true;
      }

      if (count >= MAX_REQUESTS_PER_MINUTE) {
        return false;
      }

      tx.update(docRef, {
        count: count + 1,
      });
      return true;
    });
  } catch (error) {
    logger.error("Rate limit check failed in Firestore: ", error);
    // 障害時はユーザー操作をブロックしないようフェイルオープン
    return true;
  }
}

/**
 * Google Routes API proxy endpoint.
 * Verifies Firebase Auth ID token and forwards request
 * to Routes API with ADC / IAM token.
 */
export const computeRoutesProxy = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).json({error: "Method Not Allowed"});
      return;
    }

    // 1. ユーザーログイン認証チェック (Firebase Auth ID トークン)
    const uid = await getUidFromRequest(req);
    if (!uid) {
      res.status(401).json({error: "Unauthorized: ログインが必要です。"});
      return;
    }

    // 2. ユーザーごとのレート制限チェック (Cloud Firestore による全インスタンス共通制御)
    const isAllowed = await checkRateLimit(uid);
    if (!isAllowed) {
      res.status(429).json({
        error: "Too Many Requests: リクエストが多すぎます。しばらく待ってから再試行してください。",
      });
      return;
    }

    // 3. リクエストボディの厳格なスキーマ検証・ホワイトリスト抽出
    if (!req.body || typeof req.body !== "object") {
      res.status(400).json({error: "Bad Request: リクエストボディが無効です。"});
      return;
    }

    // 未許可・未知のトップレベルプロパティのチェック
    const allowedKeys = new Set(["origin", "destination", "travelMode"]);
    const bodyKeys = Object.keys(req.body);
    if (bodyKeys.some((key) => !allowedKeys.has(key))) {
      res.status(400).json({
        error: "Bad Request: 許可されていないパラメータが含まれています。",
      });
      return;
    }

    const {origin, destination, travelMode} = req.body;
    const originLat = origin?.location?.latLng?.latitude;
    const originLng = origin?.location?.latLng?.longitude;
    const destLat = destination?.location?.latLng?.latitude;
    const destLng = destination?.location?.latLng?.longitude;

    if (
      typeof originLat !== "number" ||
      typeof originLng !== "number" ||
      typeof destLat !== "number" ||
      typeof destLng !== "number"
    ) {
      res.status(400).json({
        error: "Bad Request: origin と destination の有効な座標(数値)が必要です。",
      });
      return;
    }

    // travelMode の許可値チェック
    const allowedTravelModes = new Set([
      "DRIVE",
      "WALK",
      "BICYCLE",
      "TWO_WHEELER",
      "TRANSIT",
    ]);
    const validTravelMode =
      typeof travelMode === "string" && allowedTravelModes.has(travelMode) ?
        travelMode :
        "DRIVE";

    // 安全に再構築したリクエストボディのみ中継
    const upstreamBody = {
      origin: {
        location: {
          latLng: {
            latitude: originLat,
            longitude: originLng,
          },
        },
      },
      destination: {
        location: {
          latLng: {
            latitude: destLat,
            longitude: destLng,
          },
        },
      },
      travelMode: validTravelMode,
    };

    // 4. Google IAM / ADC によるアクセストークンの取得 (APIキー不要)
    const auth = new GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/cloud-platform"],
    });
    const client = await auth.getClient();
    const tokenResponse = await client.getAccessToken();
    const accessToken = tokenResponse.token;

    // 5. 許可されたフィールドマスクのみ通過 (不正なヘッダー注入・課金増加の防止)
    const allowedFieldMasks = new Set([
      "routes.duration",
      "routes.distanceMeters",
      "routes.polyline.encodedPolyline",
      "routes.warnings",
    ]);
    const defaultFieldMask = Array.from(allowedFieldMasks).join(",");
    const rawFieldMask = Array.isArray(req.headers["x-goog-fieldmask"]) ?
      req.headers["x-goog-fieldmask"].join(",") :
      req.headers["x-goog-fieldmask"];

    let fieldMask = defaultFieldMask;
    if (typeof rawFieldMask === "string" && rawFieldMask.trim().length > 0) {
      const filtered = rawFieldMask
        .split(",")
        .map((f) => f.trim())
        .filter((f) => allowedFieldMasks.has(f));
      if (filtered.length > 0) {
        fieldMask = filtered.join(",");
      }
    }

    // 6. Authorization: Bearer ヘッダーと
    // X-Goog-User-Project で Google Routes API に中継
    const projectId =
      process.env.GCLOUD_PROJECT ||
      process.env.GOOGLE_CLOUD_PROJECT ||
      admin.app().options.projectId;

    const requestHeaders: Record<string, string> = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${accessToken}`,
      "X-Goog-FieldMask": fieldMask,
    };
    if (projectId) {
      requestHeaders["X-Goog-User-Project"] = projectId;
    }

    const googleResponse = await axios.post(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
      upstreamBody,
      {
        headers: requestHeaders,
        timeout: 10000,
      }
    );

    res.status(200).json(googleResponse.data);
  } catch (error: unknown) {
    if (isAxiosError(error) && error.response) {
      logger.error(
        "Routes API Error: status =",
        error.response.status,
        "data =",
        JSON.stringify(error.response.data)
      );
      res.status(error.response.status).json(error.response.data);
      return;
    }
    logger.error("Error in computeRoutesProxy: ", error);
    res.status(500).json({error: "Internal Server Error"});
  }
});


