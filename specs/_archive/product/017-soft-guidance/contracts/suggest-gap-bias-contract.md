# Contract: Suggest-Sets Gap Bias

**Feature**: 017-soft-guidance

## Behavior

`suggestSets` keeps existing tag/element/synergy-type scoring and **adds** an equal-weight bonus when a candidate set would match one or more **currently unmatched** evidence links for designated synergies that are `missing` or `weak`.

- Fashion sets excluded from gap scoring  
- Reasons SHOULD include a gap-close string when bonus applies  
- Does not replace LLM goal re-rank when present; bias applies to base scores  

## Non-goals

Hard-forcing a single set; soft-stat-driven ranking (slice 5).
