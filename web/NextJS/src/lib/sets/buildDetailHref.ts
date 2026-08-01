/** Query keys must stay in sync with BuildPage deep-link handling. */
export const BUILD_QUERY_BUILD = "build";
export const BUILD_QUERY_VARIANT = "variant";

/**
 * Deep link from Sets “Used by builds” (or elsewhere) into the Build workspace.
 * When exactly one variant name is known, it is selected after load.
 */
export function buildDetailHref(
  buildId: string,
  variantNames: string[] = [],
): string {
  const params = new URLSearchParams();
  params.set(BUILD_QUERY_BUILD, buildId);
  if (variantNames.length === 1 && variantNames[0]) {
    params.set(BUILD_QUERY_VARIANT, variantNames[0]);
  }
  return `/build?${params.toString()}`;
}
