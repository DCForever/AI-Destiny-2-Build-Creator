export function buildInstancesHref(itemHash: number): string {
  return `/api/user/inventory/instances?itemHash=${itemHash}`;
}
