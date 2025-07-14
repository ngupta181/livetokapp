enum LivestreamType {
  normal,
  pk_battle,
  livestream,
  battle,
}

extension LivestreamTypeExtension on LivestreamType {
  String get value {
    switch (this) {
      case LivestreamType.normal:
        return 'normal';
      case LivestreamType.pk_battle:
        return 'pk_battle';
      case LivestreamType.livestream:
        return 'livestream';
      case LivestreamType.battle:
        return 'battle';
    }
  }

  static LivestreamType fromString(String value) {
    switch (value) {
      case 'normal':
        return LivestreamType.normal;
      case 'pk_battle':
        return LivestreamType.pk_battle;
      case 'livestream':
        return LivestreamType.livestream;
      case 'battle':
        return LivestreamType.battle;
      default:
        return LivestreamType.normal;
    }
  }
}


