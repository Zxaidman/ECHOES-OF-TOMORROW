# Knowledge and Invention System

**Document version:** 0.1.0

## 1. Core principle

The protagonist's knowledge unlocks possible approaches; it does not conjure materials, skilled labor, tools or functioning products.

The system should make the gap between knowing and doing visible and playable.

## 2. Invention definition

Each invention definition should include:
- Stable ID and schema version.
- Name, description and category.
- Knowledge prerequisite.
- Required materials and quantities.
- Required facilities and tool capabilities.
- Required skills and minimum proficiency.
- Production process or recipe.
- Prototype criteria.
- Validation tests and reliability thresholds.
- Industrialization requirements.
- Adoption constraints.
- Risks, by-products and maintenance.
- Unlocks and downstream dependencies.

Quantities must use explicit units. Do not mix abstract points with physical quantities without clear conversion rules.

## 3. Seven implementation stages

1. Knowledge: protagonist can explain the principle and relevant design.
2. Resources: required inputs are obtainable.
3. Manufacturing: tools, facilities and skills are sufficient.
4. Prototype: a test article can be made.
5. Validation: it meets defined performance and safety criteria.
6. Industrialization: repeatable production and quality control are possible.
7. Adoption: institutions, users and maintenance practices support use.

Stage progress must be based on requirements and evidence, not a single generic research meter.

## 4. First-slice candidates

### Improved waterwheel
Gameplay impact: mechanical power for milling or workshop processes.
Dependencies to validate: suitable stream/flow, timber, stone or masonry, joinery, bearings/axle, local craft skill and maintenance.

### Improved irrigation
Gameplay impact: improved water distribution and crop resilience.
Dependencies: terrain survey, water source, channels, labor coordination, land access and maintenance agreements.

### Sanitation practices
Gameplay impact: lower disease pressure and improved settlement health.
Dependencies: water-source protection, waste separation, drainage, public cooperation and sustained maintenance.

The game should avoid implying that a single modern idea instantly solves complex historical problems.

## 5. Failure and iteration

Prototype attempts may fail for understandable reasons:
- Material quality.
- Inadequate precision.
- Skill gap.
- Design assumptions.
- Environmental constraints.
- Poor maintenance.

Failures should provide actionable information and preserve reusable learning where appropriate.

## 6. UI requirements

The invention screen must answer:
- What does this invention improve?
- What does the protagonist know?
- Which stage is active?
- What prerequisites are satisfied?
- What is missing?
- Who can contribute?
- What is the cost and risk?
- What will be unlocked?
- Why did the last attempt fail?

## 7. Validation

Use content validation to detect missing IDs, circular prerequisites, impossible recipes, missing units, invalid quantities and unreachable stage graphs.
