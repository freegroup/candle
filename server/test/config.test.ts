import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.ts';

const base = { JWT_SECRET: 'a-test-secret-with-at-least-32-characters' };

describe('loadConfig', () => {
  it('accepts App Attest production by default', () => {
    expect(loadConfig(base).apple.environments).toEqual(['production']);
  });

  it('reads several App Attest environments', () => {
    expect(loadConfig({ ...base, APP_ATTEST_ENV: 'development, production' }).apple.environments).toEqual([
      'development',
      'production',
    ]);
  });

  it('rejects an unknown App Attest environment', () => {
    expect(() => loadConfig({ ...base, APP_ATTEST_ENV: 'development,staging' })).toThrow('staging');
  });

  it('reads the debug certificates of Android builds', () => {
    const config = loadConfig({ ...base, PLAY_DEBUG_CERTIFICATES: ' AA:BB , CC:DD ' });
    expect(config.android.debugCertificates).toEqual(['AA:BB', 'CC:DD']);
  });
});
