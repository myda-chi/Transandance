# Multiple-choice question format

- **Status:** Accepted

## Context

The architecture's seed format and content data model need to define how
question formats are represented. The product will support multiple-choice
questions only.

## Decision

All questions use multiple-choice options. Do not include a question `type`
field in seed JSON or a `type` column in the `questions` table.

## Consequences

- Seed data represents a question with its prompt and answer options, without
  redundant type metadata.
- A new question format would require revisiting this decision and updating the
  data model and seed format.
