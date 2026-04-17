import * as admin from 'firebase-admin';

/**
 * Check Firestore cache for a cached result.
 * Returns null if not found or expired.
 */
export async function checkCache(key: string): Promise<any | null> {
  try {
    const cacheRef = admin.firestore().collection('cache').doc(key);
    const doc = await cacheRef.get();

    if (!doc.exists) return null;

    const data = doc.data();
    if (!data) return null;

    const expiresAt = data.expiresAt?.toDate();
    if (expiresAt && expiresAt < new Date()) {
      // Expired — delete and return null
      await cacheRef.delete();
      return null;
    }

    return data.value;
  } catch (error) {
    console.error('Cache read error:', error);
    return null;
  }
}

/**
 * Save a result to Firestore cache with a TTL.
 * @param key - Cache key (used as Firestore document ID)
 * @param value - The data to cache
 * @param ttlSeconds - Time-to-live in seconds (default: 86400 = 24 hours)
 */
export async function saveToCache(
  key: string,
  value: any,
  ttlSeconds: number = 86400
): Promise<void> {
  try {
    const expiresAt = new Date(Date.now() + ttlSeconds * 1000);

    await admin.firestore().collection('cache').doc(key).set({
      value,
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('Cache write error:', error);
    // Don't throw — caching failures shouldn't break the main flow
  }
}

/**
 * Generate a short hash string from input for use as cache keys.
 */
export function hashCode(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash |= 0; // Convert to 32-bit integer
  }
  return Math.abs(hash).toString(36);
}
