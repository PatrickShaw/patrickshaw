// illumination_toggle is ignored on Apple Silicon, so use CoreBrightness instead.
// It's a private API; recheck this after major macOS upgrades.
// https://github.com/pqrs-org/Karabiner-Elements/issues/2951
ObjC.import('Foundation');

const DEFAULT_ON_BRIGHTNESS = 0.5;
const PREFERENCES_DOMAIN = 'local.keyboard-backlight-toggle';

function requireBrightness(value) {
  if (!Number.isFinite(value) || value < 0 || value > 1) {
    throw new Error(`Invalid keyboard brightness: ${value}`);
  }
  return value;
}

function toggleBacklight(client, keyboardID, preferences) {
  const current = requireBrightness(client.brightnessForKeyboard(keyboardID));
  const savedKey = `brightness-${keyboardID}`;
  const saved = requireBrightness(preferences.doubleForKey(savedKey));
  const next = current > 0 ? 0 : saved || DEFAULT_ON_BRIGHTNESS;

  // Read the real level rather than a toggle flag, which drifts out of sync
  // when macOS adjusts brightness or the slider is used.
  if (current > 0) {
    preferences.setDoubleForKey(current, savedKey);
  }
  if (!client.setBrightnessForKeyboard(next, keyboardID)) {
    throw new Error('macOS rejected the keyboard brightness change');
  }

  // Don't call enableAutoBrightness:forKeyboard:. Manual brightness and the
  // ambient-light preference are independent; leave the preference alone.
  return next;
}

function run(args) {
  const command = args.length === 0 ? 'toggle' : args[0];
  if (args.length > 1 || !['toggle', 'status'].includes(command)) {
    throw new Error('Usage: osascript -l JavaScript keyboard-backlight.js [toggle|status]');
  }

  const framework = $.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/CoreBrightness.framework');
  if (!framework.load) {
    throw new Error('Cannot load the macOS CoreBrightness framework');
  }
  const client = $.NSClassFromString('KeyboardBrightnessClient').alloc.init;
  const keyboardID = ObjC.deepUnwrap(client.copyKeyboardBacklightIDs)
    .find(id => client.isKeyboardBuiltIn(id));
  if (keyboardID === undefined) {
    throw new Error('No backlit built-in keyboard found');
  }

  if (command === 'toggle') {
    const preferences = $.NSUserDefaults.alloc.initWithSuiteName(PREFERENCES_DOMAIN);
    toggleBacklight(client, keyboardID, preferences);
  }

  return JSON.stringify({
    keyboardID,
    brightness: requireBrightness(client.brightnessForKeyboard(keyboardID)),
    autoBrightness: client.isAutoBrightnessEnabledForKeyboard(keyboardID)
  });
}
