enum BattleType {
  initiate,
  waiting,
  running,
  ended,
  end,
}

extension BattleTypeExtension on BattleType {
  String get value {
    switch (this) {
      case BattleType.initiate:
        return 'initiate';
      case BattleType.waiting:
        return 'waiting';
      case BattleType.running:
        return 'running';
      case BattleType.ended:
        return 'ended';
      case BattleType.end:
        return 'end';
    }
  }

  static BattleType fromString(String value) {
    switch (value) {
      case 'initiate':
        return BattleType.initiate;
      case 'waiting':
        return BattleType.waiting;
      case 'running':
        return BattleType.running;
      case 'ended':
        return BattleType.ended;
      case 'end':
        return BattleType.end;
      default:
        return BattleType.initiate;
    }
  }
}



enum LivestreamUserType {
  host,
  co_host,
  audience,
}

extension LivestreamUserTypeExtension on LivestreamUserType {
  String get value {
    switch (this) {
      case LivestreamUserType.host:
        return 'host';
      case LivestreamUserType.co_host:
        return 'co_host';
      case LivestreamUserType.audience:
        return 'audience';
    }
  }

  static LivestreamUserType fromString(String value) {
    switch (value) {
      case 'host':
        return LivestreamUserType.host;
      case 'co_host':
        return LivestreamUserType.co_host;
      case 'audience':
        return LivestreamUserType.audience;
      default:
        return LivestreamUserType.audience;
    }
  }
}

enum BattleView {
  red,
  blue,
}

extension BattleViewExtension on BattleView {
  String get value {
    switch (this) {
      case BattleView.red:
        return 'red';
      case BattleView.blue:
        return 'blue';
    }
  }
}