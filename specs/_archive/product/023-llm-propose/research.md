# Research: LLM Propose-for-Confirm

**R1 — Ephemeral store**: In-memory `Map<passId, Pass>` with TTL; no DB for unconfirmed proposals.  
**R2 — Persist path**: Confirmed synergy proposals → `createUserSynergy`. Keywords → map to synergy `subType` or skip (no personal-keyword table in v1).  
**R3 — Mock**: Injected `LlmClient` + optional fixture when `LLM_PROPOSE_MOCK=1`.  
**R4 — No builds**: Confirm never PATCHes builds/variants.  
**R5 — Debug**: New `/debug/llm-propose` page; link from debug nav.
