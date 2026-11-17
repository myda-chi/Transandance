# Group challenges and individual invitations

- **Status:** Accepted

## Context

The original game model treated a challenge as a single invitation by storing
one `opponent_id` and one response status on the challenge. That shape cannot
represent a multiplayer challenge with multiple invitees or track each
invitee's decision independently. The multiplayer module needs that
capability as part of the initial game data model.

## Decision

Represent a challenge as one group-level record in `game.challenges`, with its
challenger, level, overall status, creation time, and invitation expiry time.
Represent each invited friend with a separate `game.challenge_invites` record
containing the invitee, individual status, invitation time, and response time.
Keep the challenge's overall lifecycle status separate from each invitee's
decision. A match remains associated with the group challenge, and its
participants and scores are recorded in the existing match/session model.

## Consequences

- One challenge can invite any number of friends without duplicating the
  challenge itself.
- Invitations can be accepted or declined independently and retain their own
  response timestamps.
- The architecture and initial Game schema should include both tables before
  multiplayer is implemented, avoiding a later migration just to split a
  single-opponent challenge into a group and per-invite records.
- Challenge-wide lifecycle transitions and the minimum participation rule
  remain Game rules; they are not inferred from an individual invitation's
  status.
- This decision changes the documented target model only. Any already-applied
  schema changes still require normal versioned migrations.
