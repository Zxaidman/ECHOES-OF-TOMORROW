# Simulation and Time Model

**Document version:** 0.3.0

## Canonical time
Simulation time is an integer count of in-game minutes from the campaign epoch. The render loop never advances authoritative time. Only explicit simulation commands may advance the clock.

## Event ordering
Every scheduled event has a stable ID, scheduled minute, integer priority (lower values execute first), monotonically increasing sequence ID, event type, structured payload and optional repeat interval in minutes. The total ordering key is (scheduled_minute, priority, sequence_id). Duplicate pending IDs are rejected. Events at the requested target minute are processed inclusively. Repeating events retain their logical ID but receive a new sequence ID when rescheduled.

## Advancement contract
SettlementSimulation.advance_time(minutes):
1. Rejects negative or overflowing advances without mutating the clock.
2. Computes a fixed target minute.
3. Processes every event due at or before that target.
4. Moves the clock to each event minute before resolving it.
5. Reschedules recurring events.
6. Moves the clock to the requested target after due events are processed.

Resource events apply integer deltas through the ledger. Failed transactions are recorded as failed outcomes and do not partially mutate resources.

## Resource transactions
The resource ledger stores integer quantities keyed by stable resource IDs. Multi-resource transactions are atomic. Unknown resources, fractional values, negative balances and overflow are rejected.

## Randomness
World, economy and NPC systems use independent RandomNumberGenerator streams derived from a master seed. Each stream's state is persisted. Systems must not share a global RNG.

## Persistence
Campaign save state includes resource balances, pending scheduled events, next event sequence ID, all RNG stream states and simulation minute. Restore validates the complete candidate state before replacing the live aggregate.

## Acceptance tests
- Same seed, initial state and ordered commands produce equal results.
- Same-minute events resolve by priority then insertion sequence.
- One 120-minute advance matches two 60-minute advances when no player command intervenes.
- Events at the target minute execute inclusively.
- Invalid resource transactions are atomic.
- Save/restore preserves balances, pending event order, sequence IDs and RNG continuation.
- UI frame rate does not affect simulation state.
