import { z } from "zod";

import { CREATABLE_SYNERGY_TYPES, synergyLinkSchema } from "@/lib/synergies/schemas";

export const proposalKindSchema = z.enum(["synergy", "keyword", "evidence"]);

export const synergyProposalPayloadSchema = z.object({
  name: z.string().trim().min(1).max(120).optional(),
  type: z.enum(CREATABLE_SYNERGY_TYPES),
  subType: z.string().trim().min(1).nullable().optional(),
  description: z.string().max(2000).optional(),
  links: z.array(synergyLinkSchema).default([]),
});

export const keywordProposalPayloadSchema = z.object({
  term: z.string().trim().min(1).max(80),
  facet: z.string().trim().min(1).optional(),
  isNew: z.boolean().default(true),
});

export const evidenceProposalPayloadSchema = synergyLinkSchema.extend({
  note: z.string().max(500).optional(),
});

export const proposalSchema = z.object({
  id: z.string().min(1),
  kind: proposalKindSchema,
  rationale: z.string().max(1000).optional(),
  synergy: synergyProposalPayloadSchema.optional(),
  keyword: keywordProposalPayloadSchema.optional(),
  evidence: evidenceProposalPayloadSchema.optional(),
});

export const proposePassLlmOutputSchema = z.object({
  proposals: z.array(
    z.object({
      kind: proposalKindSchema,
      rationale: z.string().max(1000).optional(),
      synergy: synergyProposalPayloadSchema.optional(),
      keyword: keywordProposalPayloadSchema.optional(),
      evidence: evidenceProposalPayloadSchema.optional(),
    }),
  ),
});

export const proposePassRequestSchema = z.object({
  descriptions: z.string().trim().min(1).max(20_000),
  useMock: z.boolean().optional(),
});

export const confirmPassRequestSchema = z.object({
  acceptedIds: z.array(z.string()).default([]),
  skippedIds: z.array(z.string()).default([]),
  /**
   * Optional client copy of the pass proposals. Used when the in-memory pass
   * was lost (dev HMR, process restart) so confirm can still create synergies.
   */
  proposals: z.array(proposalSchema).optional(),
});

export type Proposal = z.infer<typeof proposalSchema>;
export type ProposePassRequest = z.infer<typeof proposePassRequestSchema>;
export type ConfirmPassRequest = z.infer<typeof confirmPassRequestSchema>;
export type ProposePassLlmOutput = z.infer<typeof proposePassLlmOutputSchema>;
