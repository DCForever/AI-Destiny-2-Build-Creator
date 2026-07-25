import '../bungie_http_client.dart';
import 'character_parse.dart';
import 'inventory_parse.dart';
import 'profile_types.dart';

/// Components for full inventory import (product INVENTORY_COMPONENTS).
const String kInventoryProfileComponents = '102,201,205,300,304,305,310';

/// Profile characters component (equip character pick — DART-038).
const String kCharactersProfileComponents = '200';

/// Bungie profile operations used by inventory sync (DART-024) + characters
/// (DART-038).
///
/// Abstract so tests inject fakes without HTTP.
abstract class BungieProfileClient {
  Future<List<DestinyMembership>> getMemberships(String accessToken);

  /// Destiny characters for the membership (class / light / id).
  Future<List<CharacterSummary>> getCharacters(
    String accessToken,
    DestinyMembership membership,
  );

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
  Future<List<CharacterSummary>> getCharacters(
    String accessToken,
    DestinyMembership membership,
  ) async {
    final path =
        '/Destiny2/${membership.membershipType}/Profile/${membership.membershipId}/';
    final response = await http.getJson(
      path,
      accessToken: accessToken,
      queryParameters: {'components': kCharactersProfileComponents},
    );
    return parseCharactersResponse(response);
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
