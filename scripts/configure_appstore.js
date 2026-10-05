const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const npmRoot = cp.execSync('npm root -g').toString().trim();
const AU = require(path.join(npmRoot, 'eas-cli', 'node_modules', '@expo', 'apple-utils'));
const ROOT = path.resolve(__dirname, '..');
const STORE = JSON.parse(fs.readFileSync(path.join(ROOT, 'store.config.json'), 'utf8'));
const KEY_ID = process.env.ASC_KEY_ID;
const ISSUER_ID = process.env.ASC_ISSUER_ID;
const KEY_P8 = process.env.ASC_KEY_P8;
const BUNDLE = 'com.operatorx.powderrunbook';
const VERSION = STORE.apple.version;

if (!KEY_ID || !ISSUER_ID || !KEY_P8) {
  throw new Error('ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_P8 are required');
}

const context = { token: new AU.Token({ key: KEY_P8, issuerId: ISSUER_ID, keyId: KEY_ID, duration: 1200 }) };

async function ensureAppInfoLocalization(appInfo, locale, cfg) {
  let loc = (await appInfo.getLocalizationsAsync()).find(x => x.attributes.locale === locale);
  if (!loc) loc = await appInfo.createLocalizationAsync({ locale });
  return loc.updateAsync({ name: cfg.title, subtitle: cfg.subtitle, privacyPolicyUrl: cfg.privacyPolicyUrl });
}

async function ensureVersionLocalization(version, locale, cfg) {
  let loc = (await version.getLocalizationsAsync()).find(x => x.attributes.locale === locale);
  if (!loc) loc = await version.createLocalizationAsync({ locale });
  return loc.updateAsync({
    description: cfg.description,
    keywords: cfg.keywords.join(','),
    marketingUrl: cfg.marketingUrl,
    promotionalText: cfg.promoText,
    supportUrl: cfg.supportUrl,
  });
}

async function configurePrivacy(app) {
  const usages = await app.getAppDataUsagesAsync();
  if (usages.length === 0) {
    await app.createAppDataUsageAsync({ appDataUsageProtection: AU.AppDataUsageDataProtectionId.DATA_NOT_COLLECTED });
  }
  const states = await app.getAppDataUsagesPublishStateAsync();
  for (const state of states) if (!state.attributes.published) await state.updateAsync({ published: true });
}

async function configurePrice(app) {
  const fra = await app.getAppPricePointsAsync({ query: { filter: { territory: 'FRA' } } });
  const usa = await app.getAppPricePointsAsync({ query: { filter: { territory: 'USA' } } });
  const fr = fra.find(p => p.attributes.customerPrice === '9.99');
  const us = usa.find(p => p.attributes.customerPrice === '9.99');
  if (!fr || !us) throw new Error('9.99 price points not found for FRA/USA');
  await app.createPriceScheduleAsync({
    baseTerritoryId: 'FRA',
    manualPrices: [{ appPricePointId: fr.id }, { appPricePointId: us.id }],
  });
}

async function main() {
  const app = await AU.App.findAsync(context, { bundleId: BUNDLE });
  if (!app) throw new Error(`App Store record missing for ${BUNDLE}`);

  await AU.App.updateAsync(context, {
    id: app.id,
    attributes: {
      contentRightsDeclaration: AU.ContentRightsDeclaration.DOES_NOT_USE_THIRD_PARTY_CONTENT,
    },
  });

  await app.ensureVersionAsync(VERSION, AU.Platform.IOS);
  const version = await app.getEditAppStoreVersionAsync({ platform: AU.Platform.IOS });
  if (!version) throw new Error('Editable App Store version missing');
  await version.updateAsync({
    versionString: VERSION,
    releaseType: AU.ReleaseType.MANUAL,
    copyright: STORE.apple.copyright,
    reviewType: AU.ReviewType.APP_STORE,
  });

  const infos = await app.getAppInfoAsync();
  const appInfo = (await app.getEditAppInfoAsync()) || infos[0];
  if (!appInfo) throw new Error('App info missing');
  await appInfo.updateCategoriesAsync({
    primaryCategory: AU.AppCategoryId.BUSINESS,
    secondaryCategory: AU.AppCategoryId.PRODUCTIVITY,
  });

  for (const locale of ['en-US', 'fr-FR']) {
    const cfg = STORE.apple.info[locale];
    await ensureAppInfoLocalization(appInfo, locale, cfg);
    await ensureVersionLocalization(version, locale, cfg);
  }

  const rating = await appInfo.getAgeRatingDeclarationAsync();
  if (rating) await rating.updateAsync(STORE.apple.advisory);

  const r = STORE.apple.review;
  const reviewAttrs = {
    contactFirstName: r.firstName,
    contactLastName: r.lastName,
    contactPhone: r.phone,
    contactEmail: r.email,
    demoAccountRequired: false,
    notes: r.notes,
  };
  const review = await version.getAppStoreReviewDetailAsync();
  if (review) await review.updateAsync(reviewAttrs);
  else await version.createReviewDetailAsync(reviewAttrs);

  await configurePrivacy(app);
  await configurePrice(app);

  const territories = await AU.Territory.getAsync(context);
  if (territories.length) await app.updateAsync({ territories: territories.map(t => t.id) });

  fs.writeFileSync(path.join(ROOT, '.powderrunbook-asc.json'), JSON.stringify({ ascAppId: app.id, bundleId: BUNDLE, versionId: version.id }, null, 2));
  console.log(JSON.stringify({
    status: 'CONFIGURED',
    appId: app.id,
    versionId: version.id,
    version: version.attributes.versionString,
    locales: ['en-US', 'fr-FR'],
    price: '9.99 EUR / 9.99 USD',
    privacy: 'DATA_NOT_COLLECTED',
    territories: territories.length,
  }, null, 2));
}

main().catch(error => {
  console.error(error?.stack || error);
  if (error?.response?.data) console.error(JSON.stringify(error.response.data, null, 2));
  process.exit(1);
});
