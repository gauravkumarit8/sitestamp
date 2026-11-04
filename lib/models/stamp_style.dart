enum StampPosition { bottom, top }

enum StampSize { small, medium, large }

/// What the stamp prints for the location.
/// addressFirst: place name; GPS coordinates only if no name is available.
enum StampLocationMode { addressFirst, both, coordinatesOnly }

extension StampSizeScale on StampSize {
  /// Font size as a fraction of image width.
  double get fontFactor {
    switch (this) {
      case StampSize.small:
        return 0.028;
      case StampSize.medium:
        return 0.034;
      case StampSize.large:
        return 0.042;
    }
  }
}

/// Colour themes for the stamp panel (stored as ARGB ints to keep this file
/// free of Flutter imports).
enum StampTheme { classic, bright, light }

extension StampThemeColors on StampTheme {
  int get textArgb {
    switch (this) {
      case StampTheme.classic:
        return 0xFFFFFFFF;
      case StampTheme.bright:
        return 0xFFFFEB3B;
      case StampTheme.light:
        return 0xFF111111;
    }
  }

  int get panelArgb {
    switch (this) {
      case StampTheme.classic:
        return 0x99000000;
      case StampTheme.bright:
        return 0xB3000000;
      case StampTheme.light:
        return 0xCCFFFFFF;
    }
  }

  String get label {
    switch (this) {
      case StampTheme.classic:
        return 'Classic';
      case StampTheme.bright:
        return 'Bright';
      case StampTheme.light:
        return 'Light';
    }
  }
}

class StampStyle {
  const StampStyle({
    this.position = StampPosition.bottom,
    this.size = StampSize.medium,
    this.theme = StampTheme.classic,
  });

  final StampPosition position;
  final StampSize size;
  final StampTheme theme;

  StampStyle copyWith({
    StampPosition? position,
    StampSize? size,
    StampTheme? theme,
  }) =>
      StampStyle(
        position: position ?? this.position,
        size: size ?? this.size,
        theme: theme ?? this.theme,
      );
}


enum TimeFormat { h24, h12 }

enum CoordFormat { decimal, dms }

enum AltitudeUnit { meters, feet }

/// How time, coordinates and altitude are written on the stamp.
class StampFormat {
  const StampFormat({
    this.time = TimeFormat.h24,
    this.coords = CoordFormat.decimal,
    this.altitude = AltitudeUnit.meters,
  });

  final TimeFormat time;
  final CoordFormat coords;
  final AltitudeUnit altitude;

  StampFormat copyWith({
    TimeFormat? time,
    CoordFormat? coords,
    AltitudeUnit? altitude,
  }) =>
      StampFormat(
        time: time ?? this.time,
        coords: coords ?? this.coords,
        altitude: altitude ?? this.altitude,
      );
}

/// Longest side of the saved photo. Large needs Pro (uses more memory/storage).
enum PhotoSize { small, standard, large }

extension PhotoSizePixels on PhotoSize {
  int get maxSide {
    switch (this) {
      case PhotoSize.small:
        return 1280;
      case PhotoSize.standard:
        return 1920;
      case PhotoSize.large:
        return 2400;
    }
  }
}
