import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({maxInstances: 10});

export const helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

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
 * Memos API endpoint.
 */
export const memos = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "GET, POST, PUT");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.status(204).send("");
    return;
  }

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
        await userMemosRef.doc(id).set(memoData);
        res.status(201).json({id, ...memoData});
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

      await docRef.update({
        title,
        content: content || "",
        updatedAt: now,
        isDeleted: isDeleted !== undefined ? isDeleted : false,
      });
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
 */
export const users = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.status(204).send("");
    return;
  }

  const pathParts = req.path.split("/").filter((p) => p !== "");
  const firstPath = pathParts.length > 0 ? pathParts[0] : null;

  try {
    if (firstPath === "me") {
      const uid = await getUidFromRequest(req);
      if (!uid) {
        res.status(401).send("Unauthorized");
        return;
      }

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
        const {name, displayName, phone} = req.body;
        await docRef.set({
          name: name || "",
          displayName: displayName || "",
          phone: phone || "",
          email: req.body.email || "",
        }, {merge: true});
        res.status(200).send("OK");
      } else {
        res.status(405).send("Method Not Allowed");
      }
      return;
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
    } else if (req.method === "PUT") {
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

      await docRef.update({
        name: req.body.name || "",
        email: req.body.email || "",
        phone: req.body.phone || "",
        website: req.body.website || "",
        address: req.body.address || {},
      });
      res.status(200).send("OK");
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

