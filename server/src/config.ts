export interface Config {
  host: string;
  port: number;
  /** HMAC key for all tokens. Changing it logs out every app; they re-register on their own. */
  jwtSecret: Uint8Array;
  apple: {
    teamId: string;
    bundleId: string;
    /** "development" for Xcode/debug builds, "production" for TestFlight and App Store. */
    environment: 'development' | 'production';
  };
  android: {
    packageName: string;
    serviceAccountFile?: string;
    /** Accept builds not installed from Google Play (sideloaded test builds). Never in production. */
    acceptUnrecognizedApp: boolean;
    /**
     * SHA-256 of the signing certificates of our own debug builds (hex with colons,
     * as keytool prints them). Such a build passes although it is not from Google
     * Play: only its developer has the private key to sign it.
     */
    debugCertificates: string[];
  };
  /** Shared secret for simulators/emulators, which cannot attest. Leave unset in production. */
  debugAttestationToken?: string;
  /** The places file built by tools/build_pois.py; the server answers 503 while it is missing. */
  placesDatabase: string;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const secret = required(env, 'JWT_SECRET');
  if (secret.length < 32) throw new Error('JWT_SECRET must have at least 32 characters');

  const environment = env.APP_ATTEST_ENV ?? 'production';
  if (environment !== 'development' && environment !== 'production') {
    throw new Error(`APP_ATTEST_ENV must be "development" or "production", not "${environment}"`);
  }

  return {
    host: env.HOST ?? '127.0.0.1',
    port: Number(env.PORT ?? 8080),
    jwtSecret: new TextEncoder().encode(secret),
    apple: {
      teamId: env.APPLE_TEAM_ID ?? 'U74C75726B',
      bundleId: env.APPLE_BUNDLE_ID ?? 'de.freegroup.candle',
      environment,
    },
    android: {
      packageName: env.ANDROID_PACKAGE ?? 'de.freegroup.candle.app',
      serviceAccountFile: env.GOOGLE_SERVICE_ACCOUNT_FILE || undefined,
      acceptUnrecognizedApp: env.PLAY_ACCEPT_UNRECOGNIZED === 'true',
      debugCertificates: (env.PLAY_DEBUG_CERTIFICATES ?? '')
        .split(',')
        .map((certificate) => certificate.trim())
        .filter((certificate) => certificate.length > 0),
    },
    debugAttestationToken: env.DEBUG_ATTESTATION_TOKEN || undefined,
    placesDatabase: env.PLACES_DATABASE ?? '/home/candle/data/places.sqlite',
  };
}

function required(env: NodeJS.ProcessEnv, name: string): string {
  const value = env[name];
  if (!value) throw new Error(`Environment variable ${name} is missing`);
  return value;
}
