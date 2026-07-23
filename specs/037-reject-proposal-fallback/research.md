# Research: 037 reject client proposal fallback

## Decision: Hard-fail missing passes

**Rationale**: Client replay of proposals bypasses server-side scan integrity (DBR-LLM-002).  
**Alternatives considered**: Signed server tokens for offline confirm — larger scope; deferred. Durable SQLite pass store — out of scope per improve prompt.

## Decision: Strip `proposals` from confirm schema

**Rationale**: Ignoring a still-accepted field leaves a footgun; removing it makes the contract honest.  
**Alternatives considered**: Keep optional field and ignore — weaker documentation signal.

## Decision: Bind pass to `userId`

**Rationale**: Improve prompt R4; small change at save/get sites already have auth user.  
**Alternatives considered**: Leave unbound — acceptable minimum but weaker multi-user isolation.
