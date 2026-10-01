// Draw the two default reaction cards, media/approve.png and media/fail.png,
// with AppKit, so there's nothing to install. Run from the repo root:
//   osascript -l JavaScript scripts/make-cards.js
function run() {
  ObjC.import('Cocoa');
  const cwd = $.NSFileManager.defaultManager.currentDirectoryPath.js;
  const card = (name, hex, symbol, label) => {
    const S = 480;
    const rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(
      null, S, S, 8, 4, true, false, $.NSDeviceRGBColorSpace, 0, 0);
    $.NSGraphicsContext.saveGraphicsState;
    $.NSGraphicsContext.setCurrentContext($.NSGraphicsContext.graphicsContextWithBitmapImageRep(rep));
    const c = (i) => parseInt(hex.substr(i, 2), 16) / 255;
    $.NSColor.colorWithRedGreenBlueAlpha(c(1), c(3), c(5), 1).setFill;
    $.NSRectFill($.NSMakeRect(0, 0, S, S));
    // Each line centred by hand: measure it, then draw at (S - width) / 2.
    const draw = (text, size, topY) => {
      const attrs = $.NSMutableDictionary.alloc.init;
      attrs.setObjectForKey($.NSFont.systemFontOfSizeWeight(size, $.NSFontWeightHeavy), 'NSFont');
      attrs.setObjectForKey($.NSColor.whiteColor, 'NSColor');
      text.split('\n').forEach((line, i) => {
        const str = $(line);
        const sz = str.sizeWithAttributes(attrs);
        str.drawAtPointWithAttributes($.NSMakePoint((S - sz.width) / 2, topY - i * sz.height * 0.95), attrs);
      });
    };
    draw(symbol, 210, 200);
    draw(label, 54, label.includes('\n') ? 110 : 80);
    $.NSGraphicsContext.restoreGraphicsState;
    const png = rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $.NSDictionary.dictionary);
    png.writeToFileAtomically(`${cwd}/media/${name}.png`, true);
  };
  card('approve', '#15803d', '✓', 'APPROVED');
  card('fail', '#b91c1c', '✕', 'CHANGES\nREQUESTED');
  return 'wrote media/approve.png and media/fail.png';
}
