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

class StampStyle {
  const StampStyle({
    this.position = StampPosition.bottom,
    this.size = StampSize.medium,
  });

  final StampPosition position;
  final StampSize size;

  StampStyle copyWith({StampPosition? position, StampSize? size}) =>
      StampStyle(position: position ?? this.position, size: size ?? this.size);
}
