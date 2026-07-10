# Implementation Plan: LLM Propose-for-Confirm

**Branch**: `023-llm-propose` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

## Summary

Manual LLM pass that returns **ephemeral proposals** (synergies / keywords / evidence). User confirms selected items into the library via `createUserSynergy`. No auto-apply to builds. Mockable `LlmClient` for gate.

## Technical Context

**Primary Dependencies**: `LlmClient`, `composeJsonWithRetry`, `createUserSynergy`  
**Storage**: In-memory pass store only (no new tables)  
**Testing**: vitest with scripted LLM client  
**Constraints**: Manual start; confirm before persist; FR-007 no build mutation

## Project Structure

```text
src/lib/llm/propose/*          # schemas, store, run, confirm
src/app/api/llm/propose-pass/
src/app/debug/llm-propose/
```

## Delivery Mapping

| Story | Artifacts |
|-------|-----------|
| US1 Manual start | POST propose-pass |
| US2 Proposals | runProposePass + mock |
| US3 Confirm | confirm route → createUserSynergy |
| US4 Debug | /debug/llm-propose |

## Constitution Check

PASS (test-first, co-located tests, injectable LLM)
