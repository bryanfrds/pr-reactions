// The reaction itself: a borderless, rounded card at the bottom centre of the
// screen that fades in, holds, and fades out. Clicks pass through it.
// Run with: osascript -l JavaScript popup.js <image|video> <seconds-to-hold> [video volume 0-1]
// Animated GIFs play. A video (.mov/.mp4/.m4v) plays to its end with its own sound;
// one with a see-through background (HEVC with alpha) shows only its subject.
function run(argv) {
  ObjC.import('Cocoa');
  ObjC.import('QuartzCore');
  const app = $.NSApplication.sharedApplication;
  app.setActivationPolicy($.NSApplicationActivationPolicyAccessory);   // no Dock icon

  const path = argv[0];
  const isVideo = /\.(mov|mp4|m4v)$/i.test(path);
  const hold = Number(argv[1]) || 2;
  let img = null, player = null, w = 240, h = 240;
  if (isVideo) {
    // JXA doesn't bridge AVFoundation's classes by name, so load it and look them up.
    $.NSBundle.bundleWithPath('/System/Library/Frameworks/AVFoundation.framework').load;
    const AV = (name) => $.NSClassFromString(name);
    const item = AV('AVPlayerItem').playerItemWithURL($.NSURL.fileURLWithPath(path));
    player = AV('AVPlayer').playerWithPlayerItem(item);
    const vol = parseFloat(argv[2]);
    player.volume = Number.isFinite(vol) ? Math.min(1, Math.max(0, vol)) : 0.3;
    const track = item.asset.tracksWithMediaType('vide').firstObject;   // 'vide' = AVMediaTypeVideo
    if (!track || track.isNil()) return;
    const size = track.naturalSize;
    h = 320; w = Math.round(h * size.width / size.height);
    if (!Number.isFinite(w) || w <= 0) w = 222;
  } else {
    img = $.NSImage.alloc.initWithContentsOfFile(path);
    if (!img || img.isNil()) return;
  }
  const area = $.NSScreen.mainScreen.visibleFrame;                       // above the Dock
  const rect = $.NSMakeRect(area.origin.x + (area.size.width - w) / 2,
                            area.origin.y + 48, w, h);

  const win = $.NSWindow.alloc.initWithContentRectStyleMaskBackingDefer(
    rect, $.NSWindowStyleMaskBorderless, $.NSBackingStoreBuffered, false);
  win.level = $.NSStatusWindowLevel;
  win.opaque = false;
  win.backgroundColor = $.NSColor.clearColor;
  win.hasShadow = !isVideo;                    // a shadow would outline a see-through clip's box
  win.ignoresMouseEvents = true;
  win.alphaValue = 0;

  let view;
  if (isVideo) {
    view = $.NSView.alloc.initWithFrame($.NSMakeRect(0, 0, w, h));
    view.wantsLayer = true;
    const layer = $.NSClassFromString('AVPlayerLayer').playerLayerWithPlayer(player);
    layer.frame = $.NSMakeRect(0, 0, w, h);
    layer.videoGravity = 'AVLayerVideoGravityResizeAspect';
    view.layer.addSublayer(layer);   // (setting its backgroundColor crashes osascript; it's clear anyway)
  } else {
    view = $.NSImageView.alloc.initWithFrame($.NSMakeRect(0, 0, w, h));
    view.image = img;
    view.imageScaling = $.NSImageScaleProportionallyUpOrDown;
    view.animates = true;
    view.wantsLayer = true;
  }
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
  if (player) player.play;
  fade(0, 1, 0.35);
  if (player) {
    // The player stops itself at the end; 30s caps a clip that never plays.
    for (let t = 0; t < 30 && !(t > 0.5 && player.rate === 0); t += 0.1) wait(0.1);
  } else {
    wait(hold);
  }
  fade(1, 0, 0.6);
  win.orderOut(null);
}
