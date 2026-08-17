public enum GuardEligibility: Equatable {
    case start
    case stop
}

public enum RunningGuardAction: Equatable {
    case monitor(summon: Bool)
    case stop
}

public enum GuardReconciliation {
    public static func eligibility(
        isTrusted: Bool,
        hasPinnedDisplay: Bool
    ) -> GuardEligibility {
        guard isTrusted, hasPinnedDisplay else { return .stop }
        return .start
    }

    public static func afterStart(
        wasRunning: Bool,
        startSucceeded: Bool,
        summonRequested: Bool
    ) -> RunningGuardAction {
        guard startSucceeded else { return .stop }
        return .monitor(summon: summonRequested || !wasRunning)
    }
}
