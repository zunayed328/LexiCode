import * as admin from 'firebase-admin';

/**
 * Daily rate limits per action type.
 */
const RATE_LIMITS: Record<string, { max: number; windowSeconds: number }> = {
  code_review:       { max: 50,  windowSeconds: 86400 }, // 50 per day
  lesson_generation: { max: 100, windowSeconds: 86400 }, // 100 per day
  pronunciation:     { max: 200, windowSeconds: 86400 }, // 200 per day
  chat:              { max: 500, windowSeconds: 86400 }, // 500 per day
};

export interface RateLimitResult {
  allowed: boolean;
  remaining?: number;
  resetIn?: number;
}

/**
 * Check if a user has exceeded their daily rate limit for a given action.
 * Increments the counter if allowed.
 */
export async function checkRateLimit(
  userId: string,
  action: string
): Promise<RateLimitResult> {
  const limit = RATE_LIMITS[action];
  if (!limit) {
    // Unknown action — allow by default
    return { allowed: true };
  }

  const now = Date.now();
  const windowStart = now - (limit.windowSeconds * 1000);

  const usageRef = admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('rate_limits')
    .doc(action);

  try {
    const doc = await usageRef.get();

    if (!doc.exists) {
      // First request in this window
      await usageRef.set({
        count: 1,
        windowStart: admin.firestore.Timestamp.fromMillis(now),
      });
      return { allowed: true, remaining: limit.max - 1 };
    }

    const data = doc.data()!;
    const count = data.count || 0;
    const storedWindowStart = data.windowStart?.toMillis() || 0;

    if (storedWindowStart < windowStart) {
      // Window has expired — reset counter
      await usageRef.set({
        count: 1,
        windowStart: admin.firestore.Timestamp.fromMillis(now),
      });
      return { allowed: true, remaining: limit.max - 1 };
    }

    if (count >= limit.max) {
      // Rate limit exceeded
      const resetIn = Math.ceil(
        (storedWindowStart + (limit.windowSeconds * 1000) - now) / 1000
      );
      return { allowed: false, remaining: 0, resetIn };
    }

    // Increment counter
    await usageRef.update({
      count: admin.firestore.FieldValue.increment(1),
    });

    return { allowed: true, remaining: limit.max - count - 1 };
  } catch (error) {
    console.error('Rate limit check error:', error);
    // On error, allow the request (fail-open)
    return { allowed: true };
  }
}
