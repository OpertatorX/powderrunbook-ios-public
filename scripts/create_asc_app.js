const fs = require('fs');
const path = require('path');

const EAS = process.env.EAS_CLI_BUILD ||
  'C:\\Users\\lucbi\\AppData\\Roaming\\npm\\node_modules\\eas-cli\\build';

const { authenticateAsync } = require(path.join(
  EAS, 'credentials', 'ios', 'appstore', 'authenticate.js'
));
const {
  ensureBundleIdExistsWithNameAsync,
  ensureAppExistsAsync,
} = require(path.join(
  EAS, 'credentials', 'ios', 'appstore', 'ensureAppExists.js'
));

const APPLE_ID = process.env.EXPO_APPLE_ID;
const TEAM_ID = process.env.EXPO_APPLE_TEAM_ID || '67ZL6VYTQ8';
const BUNDLE_ID = 'com.operatorx.powderrunbook';
const APP_NAME = 'PowderRunbook';
const SKU = 'POWDERRUNBOOK-IOS-2026';

async function main() {
  if (!APPLE_ID) throw new Error('EXPO_APPLE_ID is required.');

  console.log('PowderRunbook App Store Connect bootstrap');
  console.log(`Apple ID: ${APPLE_ID}`);
  console.log(`Team: ${TEAM_ID}`);
  console.log(`Bundle: ${BUNDLE_ID}`);
  console.log('Credentials/2FA stay in this local terminal.');
  console.log('');

  const auth = await authenticateAsync({ appleId: APPLE_ID, teamId: TEAM_ID });

  await ensureBundleIdExistsWithNameAsync(auth, {
    name: APP_NAME,
    bundleIdentifier: BUNDLE_ID,
  });

  const app = await ensureAppExistsAsync(auth, {
    name: APP_NAME,
    language: 'en-US',
    bundleIdentifier: BUNDLE_ID,
    sku: SKU,
  });

  const result = { ascAppId: app.id, bundleId: BUNDLE_ID, appName: APP_NAME };
  const out = path.join(process.cwd(), '.powderrunbook-asc.json');
  fs.writeFileSync(out, JSON.stringify(result, null, 2));
  console.log('');
  console.log(`SUCCESS: App Store Connect app ready (${app.id})`);
  console.log(`Wrote ${out}`);
}

main().catch((error) => {
  console.error('');
  console.error(error?.stack || error);
  process.exit(1);
});
