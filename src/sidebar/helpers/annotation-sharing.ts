import type { SidebarSettings } from '../../types/config';
import { serviceConfig } from '../config/service-config';

/**
 * Generate a URI for sharing the annotations in a specific group (groupId) on
 * a specific document (documentURI).
 *
 * This is a link to the document itself with an `#annotations:group:<groupId>`
 * fragment, which the client reads on load to focus that group. It doesn't go
 * through a bouncer (hyp.is), which would send the document URL and group ID
 * to a third party. If the `documentURI` provided is not a web-accessible URL,
 * no link is generated.
 */
export function pageSharingLink(
  documentURI: string,
  groupId: string,
): string | null {
  if (!isShareableURI(documentURI)) {
    return null;
  }
  // The client only recognizes the fragment at the end of the URL, so replace
  // any fragment the document URI already has.
  const [uriWithoutFragment] = documentURI.split('#');
  return `${uriWithoutFragment}#annotations:group:${groupId}`;
}

/**
 * Are annotations made against `uri` meaningfully shareable? The
 * target URI needs to be available on the web, which here is determined by
 * a protocol of `http` or `https`.
 */
export function isShareableURI(uri: string): boolean {
  return /^http(s?):/i.test(uri);
}

/**
 * Return true if annotation sharing is globally enabled in the client's
 * configuration.
 *
 * Sharing is enabled by default but can be disabled when a third party
 * authority is being used.
 */
export function sharingEnabled(settings: SidebarSettings): boolean {
  const service = serviceConfig(settings);
  return service?.enableShareLinks !== false;
}
