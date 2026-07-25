import '../bungie_http_client.dart';
import 'inventory_parse.dart';
import 'profile_types.dart';

/// Components for full inventory import (product INVENTORY_COMPONENTS).
const String kInventoryProfileComponents = '102,201,205,300,304,305,310';

/// Bungie profile operations used by inventory sync (DART-024).
///
/// Abstract so tests inject fakes without HTTP.
abstract class BungieProfileClient {
  Future<List<DestinyMembership>> getMemberships(String accessToken);

  Future<List<RawInventoryItem>> getFullInventory(
    String accessToken,
    DestinyMembership membership,
  );

  Future<FullInventoryParseResult> getFullInventoryWithDiagnostics(
    String accessToken,
    DestinyMembership membership,
  );
}

/// HTTP implementation over [BungieHttpClient].
class HttpBungieProfileClient implements BungieProfileClient {
  HttpBungieProfileClient({required this.http});

  final BungieHttpClient http;

  @override
  Future<List<DestinyMembership>> getMemberships(String accessToken) async {
    final response = await http.getJson(
      '/User/GetMembershipsForCurrentUser/',
      accessToken: accessToken,
    );
    return parseMembershipsResponse(response);
  }

  @override
  Future<List<RawInventoryItem>> getFullInventory(
    String accessToken,
    DestinyMembership membership,
  ) async {
    final result =
        await getFullInventoryWithDiagnostics(accessToken, membership);
    return result.items;
  }

  @override
  Future<FullInventoryParseResult> getFullInventoryWithDiagnostics(
    String accessToken,
    DestinyMembership membership,
  ) async {
    final path =
        '/Destiny2/${membership.membershipType}/Profile/${membership.membershipId}/';
    final response = await http.getJson(
      path,
      accessToken: accessToken,
      queryParameters: {'components': kInventoryProfileComponents},
    );
    return parseFullInventoryResponse(response, membership);
  }
}
