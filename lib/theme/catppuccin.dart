import 'package:flutter/material.dart';
// Reference: https://catppuccin.com/palette

class CatppuccinPalette {
  final String name;
  final Brightness brightness;

  // base colors
  final Color crust;
  final Color mantle;
  final Color base;

  // surface layers
  final Color surface0;
  final Color surface1;
  final Color surface2;

  // overlay layers
  final Color overlay0;
  final Color overlay1;
  final Color overlay2;

  // text
  final Color text;
  final Color subtext1;
  final Color subtext0;

  // accent colors
  final Color rosewater;
  final Color flamingo;
  final Color pink;
  final Color mauve;
  final Color red;
  final Color maroon;
  final Color peach;
  final Color yellow;
  final Color green;
  final Color teal;
  final Color sky;
  final Color sapphire;
  final Color blue;
  final Color lavender;

  const CatppuccinPalette({
    required this.name,
    required this.brightness,
    required this.crust,
    required this.mantle,
    required this.base,
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.overlay0,
    required this.overlay1,
    required this.overlay2,
    required this.text,
    required this.subtext1,
    required this.subtext0,
    required this.rosewater,
    required this.flamingo,
    required this.pink,
    required this.mauve,
    required this.red,
    required this.maroon,
    required this.peach,
    required this.yellow,
    required this.green,
    required this.teal,
    required this.sky,
    required this.sapphire,
    required this.blue,
    required this.lavender,
  });

  // Latte (Light)
  static const latte = CatppuccinPalette(
    name: 'Latte',
    brightness: Brightness.light,
    rosewater: Color(0xFFdc8a78),
    flamingo: Color(0xFFdd7878),
    pink: Color(0xFFea76cb),
    mauve: Color(0xFF8839ef),
    red: Color(0xFFd20f39),
    maroon: Color(0xFFe64553),
    peach: Color(0xFFfe640b),
    yellow: Color(0xFFdf8e1d),
    green: Color(0xFF40a02b),
    teal: Color(0xFF179299),
    sky: Color(0xFF04a5e5),
    sapphire: Color(0xFF209fb5),
    blue: Color(0xFF1e66f5),
    lavender: Color(0xFF7287fd),
    text: Color(0xFF4c4f69),
    subtext1: Color(0xFF5c5f77),
    subtext0: Color(0xFF6c6f85),
    overlay2: Color(0xFF7c7f93),
    overlay1: Color(0xFF8c8fa1),
    overlay0: Color(0xFF9ca0b0),
    surface2: Color(0xFFacb0be),
    surface1: Color(0xFFbcc0cc),
    surface0: Color(0xFFccd0da),
    base: Color(0xFFeff1f5),
    mantle: Color(0xFFe6e9ef),
    crust: Color(0xFFdce0e8),
  );

  // Frappe (Medium Dark)
  static const frappe = CatppuccinPalette(
    name: 'Frappe',
    brightness: Brightness.dark,
    rosewater: Color(0xFFf2d5cf),
    flamingo: Color(0xFFeebebe),
    pink: Color(0xFFf4b8e4),
    mauve: Color(0xFFca9ee6),
    red: Color(0xFFe78284),
    maroon: Color(0xFFea999c),
    peach: Color(0xFFef9f76),
    yellow: Color(0xFFe5c890),
    green: Color(0xFFa6d189),
    teal: Color(0xFF81c8be),
    sky: Color(0xFF99d1db),
    sapphire: Color(0xFF85c1dc),
    blue: Color(0xFF8caaee),
    lavender: Color(0xFFbabbf1),
    text: Color(0xFFc6d0f5),
    subtext1: Color(0xFFb5bfe2),
    subtext0: Color(0xFFa5adce),
    overlay2: Color(0xFF949cbb),
    overlay1: Color(0xFF838ba7),
    overlay0: Color(0xFF737994),
    surface2: Color(0xFF626880),
    surface1: Color(0xFF51576d),
    surface0: Color(0xFF414559),
    base: Color(0xFF303446),
    mantle: Color(0xFF292c3c),
    crust: Color(0xFF232634),
  );

  // Macchiato (Dark)
  static const macchiato = CatppuccinPalette(
    name: 'Macchiato',
    brightness: Brightness.dark,
    rosewater: Color(0xFFf4dbd6),
    flamingo: Color(0xFFf0c6c6),
    pink: Color(0xFFf5bde6),
    mauve: Color(0xFFc6a0f6),
    red: Color(0xFFed8796),
    maroon: Color(0xFFee99a0),
    peach: Color(0xFFf5a97f),
    yellow: Color(0xFFeed49f),
    green: Color(0xFFa6da95),
    teal: Color(0xFF8bd5ca),
    sky: Color(0xFF91d7e3),
    sapphire: Color(0xFF7dc4e4),
    blue: Color(0xFF8aadf4),
    lavender: Color(0xFFb7bdf8),
    text: Color(0xFFcad3f5),
    subtext1: Color(0xFFb8c0e0),
    subtext0: Color(0xFFa5adcb),
    overlay2: Color(0xFF939ab7),
    overlay1: Color(0xFF8087a2),
    overlay0: Color(0xFF6e738d),
    surface2: Color(0xFF5b6078),
    surface1: Color(0xFF494d64),
    surface0: Color(0xFF363a4f),
    base: Color(0xFF24273a),
    mantle: Color(0xFF1e2030),
    crust: Color(0xFF181926),
  );

  // Mocha (Darkest)
  static const mocha = CatppuccinPalette(
    name: 'Mocha',
    brightness: Brightness.dark,
    rosewater: Color(0xFFf5e0dc),
    flamingo: Color(0xFFf2cdcd),
    pink: Color(0xFFf5c2e7),
    mauve: Color(0xFFcba6f7),
    red: Color(0xFFf38ba8),
    maroon: Color(0xFFeba0ac),
    peach: Color(0xFFfab387),
    yellow: Color(0xFFf9e2af),
    green: Color(0xFFa6e3a1),
    teal: Color(0xFF94e2d5),
    sky: Color(0xFF89dceb),
    sapphire: Color(0xFF74c7ec),
    blue: Color(0xFF89b4fa),
    lavender: Color(0xFFb4befe),
    text: Color(0xFFcdd6f4),
    subtext1: Color(0xFFbac2de),
    subtext0: Color(0xFFa6adc8),
    overlay2: Color(0xFF9399b2),
    overlay1: Color(0xFF7f849c),
    overlay0: Color(0xFF6c7086),
    surface2: Color(0xFF585b70),
    surface1: Color(0xFF45475a),
    surface0: Color(0xFF313244),
    base: Color(0xFF1e1e2e),
    mantle: Color(0xFF181825),
    crust: Color(0xFF11111b),
  );

  static const List<CatppuccinPalette> all = [latte, frappe, macchiato, mocha];

  Color getColorByName(String name) {
    switch (name.toLowerCase()) {
      case 'rosewater':
        return rosewater;
      case 'flamingo':
        return flamingo;
      case 'pink':
        return pink;
      case 'mauve':
        return mauve;
      case 'red':
        return red;
      case 'maroon':
        return maroon;
      case 'peach':
        return peach;
      case 'yellow':
        return yellow;
      case 'green':
        return green;
      case 'teal':
        return teal;
      case 'sky':
        return sky;
      case 'sapphire':
        return sapphire;
      case 'blue':
        return blue;
      case 'lavender':
        return lavender;
      default:
        return mauve;
    }
  }

  static const List<String> accentNames = [
    'Mauve',
    'Blue',
    'Lavender',
    'Sapphire',
    'Sky',
    'Teal',
    'Green',
    'Yellow',
    'Peach',
    'Maroon',
    'Red',
    'Pink',
    'Flamingo',
    'Rosewater',
  ];
}
