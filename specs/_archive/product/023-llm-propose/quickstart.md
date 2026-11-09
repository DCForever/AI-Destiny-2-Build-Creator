# Quickstart: LLM Propose

## V1 Start
POST `/api/llm/propose-pass` with descriptions (or mock) → proposals + passId.

## V2 Confirm one
POST confirm with one acceptedId → synergy exists; skipped absent.

## V3 Debug
`/debug/llm-propose` → Start → Confirm/Skip → list synergies.
