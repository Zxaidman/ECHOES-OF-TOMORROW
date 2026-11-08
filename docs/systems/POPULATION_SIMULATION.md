# Population and NPC Simulation — 0.4.0

Five named NPCs are individually simulated; twenty background residents are aggregated. Named NPC state contains stable identity, age, role, skills, health, hunger/rest/social needs, current activity and deterministic goal.

The population updates only on integer-hour boundaries. Schedules are fixed: sleep 22:00–05:59, meals at 06:00/12:00/18:00, work 07:00–16:59, social activity 19:00–21:59, and rest otherwise. Need changes and goal selection use bounded integer rules and never depend on frame rate or wall-clock time.

At 09:00 each game day, the settlement consumes one food per two residents, rounded up. The resource transaction is atomic. A shortfall consumes no partial food and applies a deterministic health penalty to named NPCs.

Relationships are directional. Trust, cooperation and conflict are independent integer values in [0,100]; changing A's view of B never changes B's view of A.

Population state is stored as plain JSON-compatible data and validated before restore. No LLM, pathfinding or autonomous external action is part of this milestone.
