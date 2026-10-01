// The reaction itself: a borderless, rounded card at the bottom centre of the
// screen that fades in, holds, and fades out. Clicks pass through it.
// Run with: osascript -l JavaScript popup.js <image> <seconds-to-hold>
// Animated GIFs play.
function run(argv) {
  ObjC.import('Cocoa');
  ObjC.import('QuartzCore');
  const app = $.NSApplication.sharedApplication;
  app.setActivationPolicy($.NSApplicationActivationPolicyAccessory);   // no Dock icon

  const img = $.NSImage.alloc.initWithContentsOfFile(argv[0]);
  if (!img || img.isNil()) return;
  const hold = Number(argv[1]) || 2;
  const side = 240;
  const area = $.NSScreen.mainScreen.visibleFrame;                       // above the Dock
  const rect = $.NSMakeRect(area.origin.x + (area.size.width - side) / 2,
                            area.origin.y + 48, side, side);

  const win = $.NSWindow.alloc.initWithContentRectStyleMaskBackingDefer(
    rect, $.NSWindowStyleMaskBorderless, $.NSBackingStoreBuffered, false);
  win.level = $.NSStatusWindowLevel;
  win.opaque = false;
  win.backgroundColor = $.NSColor.clearColor;
  win.hasShadow = true;
  win.ignoresMouseEvents = true;
  win.alphaValue = 0;

  const view = $.NSImageView.alloc.initWithFrame($.NSMakeRect(0, 0, side, side));
  view.image = img;
  view.imageScaling = $.NSImageScaleProportionallyUpOrDown;
  view.animates = true;
  view.wantsLayer = true;
  view.layer.cornerRadius = 20;
  view.layer.masksToBounds = true;
  win.contentView = view;
  win.orderFrontRegardless;

  const loop = $.NSRunLoop.currentRunLoop;
  const wait = (s) => loop.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(s));
  const fade = (from, to, secs) => {
    const steps = Math.round(secs * 60);
    for (let i = 1; i <= steps; i++) {
      const t = i / steps;
      win.alphaValue = from + (to - from) * t * t * (3 - 2 * t);       // smoothstep
      wait(1 / 60);
    }
  };
  fade(0, 1, 0.35);
  wait(hold);
  fade(1, 0, 0.6);
  win.orderOut(null);
}
