# Character kit (video-style avatars, drawn in code)

Draws the game's character avatars in the *video's* cartoon style (thick dark outline, big
expressive eyes, cel shading, Gulf-Arab headwear) with Dart `Canvas` code, renders them offscreen
to PNG and exports `app/assets/avatars/<id>.webp` (and rig layers). Nothing here is shipped in the
app (`tool/` is not under `lib/`), `flutter analyze` covers it.

```
app/tool/chars/
  kit.dart                 one import for a character file:  import '../kit.dart';
  spec.dart                CharSpec (a character as data), Expr (expression presets), HeadSpec, HairSpec, CharLayer
  scene.dart               paintChar / paintLayer / layerNames  (the compositor)
  core/pen.dart            Style constants, svg() path parser, spline(), Tones, Pen (outline + cel shading)
  core/head.dart           Head: the 3D-lite head model (yaw / pitch / roll) + FaceShape
  core/palette.dart        Skin, HairColor, Cloth, BgStyle palettes (sampled from the video)
  parts/                   eyes, brows, nose, mouth, face_base (ears/neck/skin), beard, glasses,
                           headwear (ghutra, hijab, turban, cap, face veil), body (thobe, garment), hand
  characters/ref.dart      the six reference characters (youth, rose, jasmine, falcon, masked, sheikh)
  characters/pack1..8.dart one empty pack per worker -> add your CharSpec entries to YOUR pack only
  registry.dart            collects ref + packs into allChars (do not edit when adding characters)
  render_test.dart         flutter test target: renders PNGs
  export_webp.py           PNG -> 512 webp (and rig layers -> 600 webp)
  contact_sheet.py         contact sheets (8 per row at 128px by default)
```

## 1. Render, export, review

```bash
export PATH="/d/flutter-sdk/bin:$PATH" FLUTTER_SUPPRESS_ANALYTICS=true CI=true
cd app

# 1) render to PNG (1024px). CHAR_IDS empty = every registered character
CHAR_OUT=/tmp/charout CHAR_IDS=youth,rose flutter test tool/chars/render_test.dart
#    CHAR_PX=1024   composite size            CHAR_LAYERS=1  also render rig layers (1200px each)

# 2) contact sheet for quick review (8 per row, 128px; --size 512 --cols 3 for a close look)
python -I tool/chars/contact_sheet.py --src /tmp/charout --out /tmp/sheet.png
python -I tool/chars/contact_sheet.py --assets --out /tmp/shipped.png      # what is in assets/avatars now

# 3) export to the game assets: 512x512 RGBA webp (quality 92, method 6) -> app/assets/avatars/<id>.webp
python -I tool/chars/export_webp.py --src /tmp/charout --ids youth,rose
#    rig layers (600x600 webp) -> app/assets/avatars/anim/<id>/<layer>.webp
python -I tool/chars/export_webp.py --src /tmp/charout --layers --ids tycoon
```

Always view the PNG (Read tool / image viewer) and a 64px/128px downscale before exporting. Compare
with a crop of the video frame (`grab.py` in the brief) at the same size. Iterate: 5-10 rounds per
face is normal. `flutter analyze` and `flutter test test` must stay clean.

## 2. Coordinates and conventions

* Composite canvas = **200x200 units**, background circle centre (100,100) r=100; the PNG is
  rendered at 1024px (scale 5.12). Outside the circle the image is transparent (the renderer clips
  to the circle). Set `cutout: true` in the spec for ids whose old art is a cut-out bust without
  background (camel, assassin, ghost, champ1-3, lv20-50, s1a-c, wolf, queen... check the old webp).
* **Head-local coordinates** (what all face-part numbers use, front view, units = 200-space units at
  head scale 1): origin = between the eyes on the eye line; +x right, +y down. Eye line 0, brows ~-15,
  hairline ~-36, skull top ~-70, nose tip ~+23, mouth ~+41, chin +68, ears -4..+26, neck base +90.
  `HeadSpec(x, y, scale)` says where that origin lands in the 200-space (default (100,92); the
  video's heads are big: eyes ~y 90-100, chin ~y 160, headwear top ~y 15-25).
* Light comes from the upper-left; shadows fall on the right/bottom (`Style.light`).

### Style rules extracted from the video (what "same artist" means)

| Element | Rule |
|---|---|
| Outline | one dark aubergine-brown (`Style.ink` `#2A1520`, never black), **2.7 units (1.35% of the diameter)** on silhouettes, 1.7 thin / 1.1 fine on inner lines, round caps/joins. Eyes are outlined as thick as the face. |
| Eyes | big, nearly round, **mostly white**, small dark iris+pupil looking in a direction (sideways!), 1-2 small highlights, thick upper lid, no separate lower lid. Characters look sideways / up, never blank at the viewer. |
| Brows | thick tapered dark shapes, high arched or heavily angled; they carry the emotion (angry = inner down, worried = inner up, smug = one cocked). |
| Nose | long, round tip ball, outlined on the lead side only + nostril wing; shaded on the other side. Sticks out of the silhouette when the head turns. |
| Mouth | small and expressive: smirk with a cheek dimple, clenched bared teeth, worried "o", grin with teeth. |
| Shading | 2-3 tones (base, cool shade, light rim) + one hard-edged shadow side, small highlights; whites are lilac-grey in shade. Taper-stroked fold lines, never uniform hairlines. No gradients/noise inside figures. |
| Beards | outlined mass, 2 tones, strand lines, cheek line low, thick mustache. |
| Ghutra | white (or pink-white) cloth over the head, hem across the forehead, **black double agal** wrapping the crown, drapes flaring over the shoulders; shade where the cloth meets the face. |
| Hijab | rounded wrapped dome, wide soft folds, dark band where the cloth rolls around the face, scarf end across the chest, optional white under-cap. |
| Background | coloured circle, radial gradient (light centre/top, darker edge) + soft vignette; the figure is cropped by the circle at the shoulders. |

## 3. Kit API (summary)

Every character file only needs `import '../kit.dart';`.

### A character is data: `CharSpec`

```dart
CharSpec(
  id: 'youth',                                  // = file name <id>.webp
  bg: BgStyle.orange,                           // gradient preset, or cutout: true
  skin: Skin.tan,                               // Skin.fair / light / tan / brown / deepTone
  head: HeadSpec(x: 100, y: 100, scale: 1.0,    // placement, size
      yaw: -1.0,                                // -1..1 : turn to viewer's left(-) / right(+)
      pitch: 0, roll: 0.06,                     // look down(+); head tilt in radians
      shape: FaceShape.pointed),                // oval / square / round / pointed / lean
  expr: Expr.smug(lookX: -0.7, side: 1),        // expression preset, or Expr(eyes:, brows:, mouth:)
  nose: NoseSpec(len: 28, proj: 19, bulb: 1.05),
  beard: BeardSpec(style: BeardStyle.short, color: HairColor.inkBlack),   // optional
  hair: HairSpec(sideburn: 20),                 // optional visible hair (sideburn / cap)
  glasses: GlassesSpec(kind: GlassesKind.round),                          // optional
  headwear: Ghutra(cloth: Cloth.pinkWhite, swept: true),                  // optional
  body: Thobe(color: Cloth.sand),               // Thobe / Garment (any shoulders) / your own Body
  behind: (pen, head) { ... },                  // custom painting behind the figure
  front:  (pen, head) { ... },                  // custom painting on top (props, hands)
)
```

Defaults make a plain character in 10 lines; a typical new character is 20-30 lines.

### Expressions (`Expr`)

Presets: `Expr.neutral / happy / angry / worried / smug / surprised / sleepy / thinking`, each with
`lookX` (-1..1, viewer's left..right) and `lookY` (-1 up .. 1 down). Build custom ones:

```dart
Expr(
  eyes: EyeSpec(ew: 14, eh: 12.6, gap: 21.5, lookX: -0.95, irisR: 0.42, pupilR: 0.7,
                lidTop: 0.0, lidSlant: 0.0, lidBottom: 0.0, lashes: false, crease: false,
                iris: Color(0xFF3A2416), left: EyeSpec(...), right: EyeSpec(...)),   // per-eye overrides
  brows: BrowSpec(lift: 6, inner: -1.5, outer: 0.5, arch: 3.6, thick: 7.6, left: BrowSpec(...)),
  mouth: MouthSpec(kind: MouthKind.smirk, side: 1, w: 16, y: 45, amount: 1),
)
```
`lidSlant` > 0 = angry (inner corner down), < 0 = worried; `inner`/`outer` of a brow move its ends
(negative = up). Mouth kinds: neutral, smile, smirk, grin, clenched, open, frown, pout, oh, laugh.
Eye size guide: friendly/girls `ew 12-14, eh 11-12.6, irisR .5-.55`; angry `ew 10.5, eh 9.4`.

### Face parts

* `FaceShape` + `HeadSpec.yaw` build the skin silhouette from a tiny 3D head ellipsoid. **Every part
  is authored once in front-view local coordinates and projected through the head** (`Head.pt`,
  `Head.path`, `Head.sp`), so frontal and 3/4 heads share the same code. Use `Head.side` (+1/-1/0),
  `Head.absYaw`, `Head.surfaceZ(x, y)`, `Head.depthOf(...)` to adapt.
* `EarSpec`, `NoseSpec`, `BeardSpec` (stubble, mustache, goatee, short, full, long, soulPatch),
  `GlassesSpec` (round, sun, aviator, square), `HairSpec`.
* Headwear (`HeadwearStack([...])` combines pieces): `Ghutra` (`check:` red shemagh, `swept: true`
  for turned heads, `agalRings`, `agalTilt`, `dropY`), `Hijab` (`underCap`, `flap`, `width`, `length`),
  `Turban` (`jewel`), `Cap`, `FaceVeil` (niqab / shemagh mask, put it BEFORE the ghutra/turban in a stack).
* Bodies: `Thobe`, `Bisht` (dark cloak + gold trim over a thobe), `FurCoat` (fur lapels + tunic, the hero), `Garment` (any colour + custom SVG shoulder path + neckline trim) or subclass `Body`
  (`draw` = clothes before the neck, `drawFront` = collar after the neck). Paths are relative to the neck
  base; see `rel(head, 'M..')`.
* Hands: `drawChinHand(pen, head, skin, at:, rot:, mirror:, sleeve:)` (thinking pose). More hands: copy
  `parts/hand.dart` (hand frame + `_tx`).
* Palettes: `Skin`, `HairColor` (`inkBlack` = the video's black), `Cloth.*`, `BgStyle.*`, `Tones.auto(color)`
  (derives shade + highlight), `shadeOf / lightOf / mix / withA`.

### Drawing primitives (`Pen`, for props, animals, accessories)

```dart
front: (pen, h) {
  final p = svg('M10 10 C30 0 60 20 80 10 L80 60 Z');       // author with SVG path strings
  pen.solid(p, Tones.auto(const Color(0xFFC9A227)));          // fill + shadow crescent + light rim + outline
  pen.shape(circle(100, 100, 8), const Color(0xFFFFFFFF));   // flat fill + outline
  pen.inside(p, (q) => q.taper(svg('M20 12 C30 30 30 40 24 56'),   // tapered fold / strand line
      w0: 2.4, w1: 0.2, color: withA(Style.ink, .6)));
  pen.glow(const Offset(60, 40), 8, 6, const Color(0xFFFFFFFF));    // soft blob (blush, shine)
  pen.line(p, w: Style.lineThin);  pen.fill(p, color);  pen.crescent(p, shade);  pen.rim(p, light);
}
```
Helpers: `spline(points, closed:)`, `poly`, `ellipse`, `circle`, `mirrorX`, `scaledAbout`,
`rotatedAbout`, `xform`, `taperedStroke`, `ring3D(head, y, r, thick)` (band around the head, follows yaw),
`regionAbove/regionBelow`, `paintCloth`, `checkPattern` (shemagh).
Use `Path.combine` for cut-outs. Outline widths scale with `head.scale`; for free props use `Style.line`.

### Fully custom figures (animals, mascots, ghosts, helmets)

```dart
CharSpec(
  id: 'wolf', bg: BgStyle.slate, cutout: false,
  custom: (pen, head) { /* draw the whole figure with the Pen */ },
  extraLayers: {'ear_l': (pen, head) {...}, 'howl': (pen, head) {...}},   // rig layers by name
)
```
`custom` replaces the human body/head. The Pen/Tones/svg helpers give the same outline + cel-shading
look; reuse `parts/eyes.dart` etc. if the character has a human-like face.

## 4. Adding a character (recipe)

1. Look at the old `app/assets/avatars/<id>.webp` (identity, colours, props) and the video frames.
2. Pick a head pose, an expression and a distinct eye direction. Write the spec in **your pack file**
   (`characters/packN.dart`): `final List<CharSpec> packN = [ CharSpec(...), ... ];`
3. `CHAR_IDS=<id> flutter test tool/chars/render_test.dart`, view the PNG at 1024, 128 and 64px.
4. Tune the numbers (below), repeat. Compare with the closest reference character in `ref.dart`.
5. Export (section 1). Commit the pack file + changed webp files.

Quick tuning map: face too wide/long -> `FaceShape` / `HeadSpec.scale`; eyes dull -> bigger `ew/eh`, smaller
`irisR`, a `lookX`; headwear hides brows -> raise `hem` (more negative); cloth too wide on a turned
head -> check `yaw`/`swept`; drape too long -> `dropY`; beard too heavy -> `cheek` (negative lowers the cheek line),
`mouthH`; nose weak -> `len/proj/bulb`.

## 5. Rig layers (animated avatars)

`app/lib/widgets/anim_rigs.dart` stacks `assets/avatars/anim/<id>/*.webp`, each **600x600 webp covering
-20..220 units** (240 units, i.e. 20% bigger than the circle) and transparent; the rig moves/rotates
them. Layer names used by the human rig (`_human`): `body`, `head`, `blink`, `mouth` (+ extras such
as `wink`, `necklace`, `goggles`, `pop_*` which are not clipped). The kit renders exactly that:

| Layer | Content |
|---|---|
| `body` | shoulders/clothes (+ the `behind` painter) |
| `head` | headwear back + neck + collar + face + features + beard + glasses + headwear front (rotated around the neck by the rig) |
| `blink` | closed eyelids only (laid over `head`, same coordinates) |
| `mouth` | open-mouth overlay (`CharSpec.mouthOpen`, default a laugh) |
| `props` | the `front` painter (hand/prop) |
| any extra | `extraLayers['name']` painters |

Produce them with `CHAR_LAYERS=1 ... render_test.dart` (PNG, 1200px) and
`export_webp.py --layers --ids <id>`; `render_test` writes `layers/<id>/<layer>.png`. The composite
`<id>.webp` and the layers come from the same spec, so they always match. Notes:

* The rig rotates `head` around `(100,150)` (`_neck` in anim_rigs.dart) but the kit's heads are bigger
  than the old ones: neck base is `Head.neckBase` (about y 180-190). A rotation of a few degrees still
  looks fine, but sparkles/glows the rig draws at fixed coordinates (crown jewels, crystal ball, wings)
  must be re-checked in `anim_rigs.dart` - that file is out of scope for the character workers.
* Layers draw on a transparent canvas, never clipped to the circle; keep `body` extending below y=200.
* Stills of animated ids (`<id>.webp`) = the composite render (same as non-animated ids).

## 6. Pitfalls

* Always put the SAME numbers in `Expr.eyes` and `BeardSpec.mouthY/W/H` as the mouth (`MouthSpec.y/w`):
  the beard cuts a hole at the mouth position.
* Headwear `back` is drawn BEFORE the neck/collar (cloth behind the neck), `front` after the face. A custom
  `front` painter is on top of everything (hands, props): it can hide the mouth/beard.
* `Path.combine` results are not self-intersection safe: when you union/difference shapes drawn with strokes,
  stroke the original paths, not the combined result, or edges can double.
* `Head.path` flattens a path into a polyline (fine for fills and strokes). With `yaw = pitch = roll = 0`
  it is an exact affine transform instead.
* Tuning for yaw: |yaw| 1 is about 19 degrees of turn (`maxYaw` in `Head`), enough for the youth-style
  3/4 look. Eyes/brows near the far limb get foreshortened automatically; very large |yaw| > 1.2 is not supported.
* Use `Tones.auto(base)` for new cloth colours; whites should use `Cloth.white` (lilac shade like the video).
* Text-based SVG `d` strings are parsed by `svg()` (M L H V C S Q T Z, absolute and relative; **no arcs**).
* Do not add colours outside the palette without reason: the app themes avatars on dark wood; saturated mid-tone
  backgrounds (`BgStyle.*`) with a darker edge read best in the gold ring.

## 7. Reference characters (`characters/ref.dart`)

| id | video source | notes |
|---|---|---|
| `youth` | the smug youth (بدر), orange | 3/4 left, swept ghutra, smirk, sideburn, thobe |
| `rose` | purple hijab girl (جود) | worried, sideways eyes, hijab with scarf end |
| `jasmine` | round glasses + teal hijab (لولوة) | white under-cap, thick round glasses |
| `falcon` | bearded man in white ghutra, hand on chin (فيصل) | 3/4 right, thinking hand, trimmed beard |
| `masked` | masked turbaned fighter (تركي) | `FaceVeil` + check ghutra, fierce eyes |
| `sheikh` | old wise man | white beard, warm smile, crease lines |

Known limits: bodies are mostly cropped by the circle (thobe, bisht, fur coat, garment exist; armour, jackets
with collars, abayas with trim need new `Body` subclasses; `FurCoat` lapels are a first version), turbans are basic, no full-body or profile views, hands have one pose.
