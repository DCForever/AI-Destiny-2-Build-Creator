import { z } from "zod";

const bucketSchema = z.enum([
  "Kinetic",
  "Energy",
  "Power",
  "Helmet",
  "Gauntlets",
  "Chest",
  "Legs",
  "ClassItem",
]);

export const instanceKindSchema = z.enum(["weapons", "armor"]);

export const instanceFilterQuerySchema = z.object({
  itemHash: z.coerce.number().int().positive().optional(),
  bucket: bucketSchema.optional(),
  kind: instanceKindSchema.optional(),
  q: z.string().trim().min(1).optional(),
});

export type InstanceFilterQuery = z.infer<typeof instanceFilterQuerySchema>;
