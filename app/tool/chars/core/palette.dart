// Colour palettes sampled from the video frames: skin tones, hair/beard, cloth,
// and background gradients.
import 'dart:ui';

import 'pen.dart';

/// A skin tone with its shading companions.
class Skin {
  const Skin({
    required this.base,
    required this.shade,
    required this.hi,
    required this.blush,
    required this.lip,
    required this.deep,
  });

  final Color base;

  /// Shadow side (cheek, under brow, neck under chin).
  final Color shade;

  /// Light rim / forehead and nose highlight.
  final Color hi;
  final Color blush;
  final Color lip;

  /// Darkest skin tone (inside ear, nostril, under the chin).
  final Color deep;

  Tones get tones => Tones(base, shade, hi);

  static const fair = Skin(
    base: Color(0xFFEDB88F),
    shade: Color(0xFFD08C69),
    hi: Color(0xFFF8CFAE),
    blush: Color(0xFFE5806E),
    lip: Color(0xFFC96F63),
    deep: Color(0xFFA9614E),
  );

  /// Wheatish (video's girls, Faisal).
  static const light = Skin(
    base: Color(0xFFE2A478),
    shade: Color(0xFFBF7C5A),
    hi: Color(0xFFF0BF98),
    blush: Color(0xFFE07562),
    lip: Color(0xFFBF6458),
    deep: Color(0xFF9A5645),
  );

  /// The smug youth / Majid warm tan.
  static const tan = Skin(
    base: Color(0xFFD39A6C),
    shade: Color(0xFFA96E4D),
    hi: Color(0xFFE6B488),
    blush: Color(0xFFD27158),
    lip: Color(0xFFB45F51),
    deep: Color(0xFF874A3A),
  );

  /// Hero's brown.
  static const brown = Skin(
    base: Color(0xFFBF7F58),
    shade: Color(0xFF8F5237),
    hi: Color(0xFFD79870),
    blush: Color(0xFFC96A52),
    lip: Color(0xFF9E5045),
    deep: Color(0xFF6E3829),
  );

  static const deepTone = Skin(
    base: Color(0xFF946042),
    shade: Color(0xFF69402D),
    hi: Color(0xFFAD7A57),
    blush: Color(0xFFA9553F),
    lip: Color(0xFF7E3E37),
    deep: Color(0xFF4E2A20),
  );
}

/// Hair / beard / brow colours.
class HairColor {
  const HairColor(this.base, this.shade, this.hi);

  final Color base;
  final Color shade;
  final Color hi;

  Tones get tones => Tones(base, shade, hi);

  static const black = HairColor(Color(0xFF2C2326), Color(0xFF1A1114), Color(0xFF5B4B50));
  static const darkBrown = HairColor(Color(0xFF4A3226), Color(0xFF30201A), Color(0xFF7A5A48));
  static const brown = HairColor(Color(0xFF6B4630), Color(0xFF472D20), Color(0xFF98705A));
  /// The video's "black" hair/beard: a cool blue-black.
  static const inkBlack = HairColor(Color(0xFF3A3743), Color(0xFF24212C), Color(0xFF6B6577));
  static const grey = HairColor(Color(0xFFA9A4A8), Color(0xFF7C7780), Color(0xFFD8D4D8));
  static const white = HairColor(Color(0xFFF1EEF2), Color(0xFFC3BFD0), Color(0xFFFFFFFF));
  static const saltPepper = HairColor(Color(0xFF6E6A70), Color(0xFF45414B), Color(0xFFB9B5BB));
}

/// Cloth colours (each with a cool-lilac shade for whites like the video).
abstract final class Cloth {
  static const white = Tones(Color(0xFFFAF7F6), Color(0xFFC9C7DA), Color(0xFFFFFFFF));
  static const cream = Tones(Color(0xFFEFE2D0), Color(0xFFC5B3AC), Color(0xFFFBF3E8));

  /// Slightly pink ghutra (the youth).
  static const pinkWhite = Tones(Color(0xFFEBD3D0), Color(0xFFB99EA9), Color(0xFFF8E9E6));
  static const agal = Tones(Color(0xFF3A2E32), Color(0xFF211820), Color(0xFF6A5A5F));
  static const sand = Tones(Color(0xFFD2B27A), Color(0xFFA58452), Color(0xFFE6CC98));
  static const charcoal = Tones(Color(0xFF3C3A47), Color(0xFF25232F), Color(0xFF605E70));
  static const black = Tones(Color(0xFF2A2630), Color(0xFF17131C), Color(0xFF4D4858));
}

/// Background circle style: a radial gradient + soft vignette.
class BgStyle {
  const BgStyle(this.inner, this.outer, {this.glow = const Color(0x00FFFFFF), this.vignette = 0.28});

  final Color inner;
  final Color outer;

  /// Optional soft light blob behind the head.
  final Color glow;
  final double vignette;

  static const orange = BgStyle(Color(0xFFD9740F), Color(0xFF9E4305), glow: Color(0x44FFC060));
  static const purple = BgStyle(Color(0xFF9B34AB), Color(0xFF63207A), glow: Color(0x44E59BFF));
  static const green = BgStyle(Color(0xFF3FA25B), Color(0xFF1C5D2E), glow: Color(0x4466F0A0));
  static const blue = BgStyle(Color(0xFF3F6FD6), Color(0xFF1A3585), glow: Color(0x4470A8FF));
  static const gold = BgStyle(Color(0xFFD9A93E), Color(0xFF86590F), glow: Color(0x55FFE08A));
  static const cyan = BgStyle(Color(0xFF3AA9C7), Color(0xFF14667E), glow: Color(0x4460E0F0));
  static const magenta = BgStyle(Color(0xFFD03A86), Color(0xFF7A1650), glow: Color(0x44FF8EC8));
  static const red = BgStyle(Color(0xFFC8392E), Color(0xFF7A1812), glow: Color(0x44FF9A80));
  static const slate = BgStyle(Color(0xFF59606C), Color(0xFF22252C), glow: Color(0x33A0B0C8));
  static const teal = BgStyle(Color(0xFF20A58E), Color(0xFF0B5648), glow: Color(0x4460F0D0));
  static const indigo = BgStyle(Color(0xFF5A48C8), Color(0xFF2A1E78), glow: Color(0x449A8CFF));
  static const night = BgStyle(Color(0xFF3A3A5E), Color(0xFF14142A), glow: Color(0x338080FF));
}
