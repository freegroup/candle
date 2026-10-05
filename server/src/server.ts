import { buildApp } from './app.ts';
import { AppAttestVerifier } from './auth/apple.ts';
import { ChallengeStore } from './auth/challenges.ts';
import { googleIntegrityDecoder, PlayIntegrityVerifier } from './auth/google.ts';
import { TokenService } from './auth/tokens.ts';
import { loadConfig } from './config.ts';
import { PlacesDatabase } from './places/places_database.ts';

const config = loadConfig();
const { android } = config;

const app = await buildApp(
  {
    tokens: new TokenService(config.jwtSecret),
    challenges: new ChallengeStore(),
    appAttest: new AppAttestVerifier(config.apple),
    playIntegrity: android.serviceAccountFile
      ? new PlayIntegrityVerifier({
          packageName: android.packageName,
          acceptUnrecognizedApp: android.acceptUnrecognizedApp,
          debugCertificates: android.debugCertificates,
          decode: googleIntegrityDecoder(android.packageName, android.serviceAccountFile),
        })
      : undefined,
    debugAttestationToken: config.debugAttestationToken,
    places: new PlacesDatabase(config.placesDatabase),
  },
  // behind nginx: take the client address from X-Forwarded-For
  { logger: true, trustProxy: true },
);

if (!android.serviceAccountFile) app.log.warn('GOOGLE_SERVICE_ACCOUNT_FILE not set: Android cannot register');
if (config.debugAttestationToken) app.log.warn('Debug attestation is enabled - never do this in production');

await app.listen({ host: config.host, port: config.port });
