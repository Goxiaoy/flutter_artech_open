import 'dart:async';

import 'package:artemis/client.dart' show ArtemisClient;
import 'package:flutter/material.dart';
import 'package:gql_http_link/gql_http_link.dart' as gql_http_link;
import 'package:gql_link/gql_link.dart' as gql_link;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;

Future<String> _alwaysNull() async {
  return null;
}

class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient({this.getTokenFromStorage = _alwaysNull}) : super();
  final http.Client _inner = http.Client();

  final Future<String> Function() getTokenFromStorage;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await getTokenFromStorage();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }
}

String uuidFromObject(Object object) {
  if (object is Map<String, Object>) {
    final String typeName = object['__typename'] as String;
    final String id = object['id']?.toString();
    if (typeName != null && id != null) {
      return <String>[typeName, id].join('/');
    }
  }
  return null;
}

GraphQLClient clientFor(String url,
    {Future<String> Function() getTokenFromStorage = _alwaysNull,
    String subscriptionUri}) {
  final Link httpLink = HttpLink(url);
  final authLink = _MyAuthLink(
    getToken: () async {
      final token = await getTokenFromStorage();
      final ret = token == null ? null : 'Bearer $token';
      return ret;
    },
  );
  var link = authLink.concat(httpLink);
  if (subscriptionUri != null) {
    final WebSocketLink websocketLink = WebSocketLink(
      subscriptionUri,
    );
    link = link.concat(websocketLink);
  }
  return GraphQLClient(
      cache: GraphQLCache(store: HiveStore()),
      link: link,
      defaultPolicies: DefaultPolicies(
          query: Policies(fetch: FetchPolicy.cacheAndNetwork),
          watchQuery: Policies(fetch: FetchPolicy.cacheAndNetwork)));
}

ArtemisClient artemisClientFor(String url,
    {Future<String> Function() getTokenFromStorage = _alwaysNull}) {
  final link = gql_link.Link.from([
    // SomeLink(),
    gql_http_link.HttpLink(url,
        httpClient:
            AuthenticatedClient(getTokenFromStorage: getTokenFromStorage)),
  ]);
  return ArtemisClient.fromLink(link);
}

typedef _RequestTransformer = FutureOr<Request> Function(Request request);

class _MyAuthLink extends AuthLink {
  _MyAuthLink(
      {@required FutureOr<String> Function() getToken,
      String headerKey = 'Authorization'})
      : super(getToken: getToken, headerKey: headerKey);

  @override
  Stream<Response> request(
    Request request, [
    NextLink forward,
  ]) async* {
    final req = await transform(headerKey, getToken)(request);
    yield* forward(req);
  }

  static _RequestTransformer transform(
    String headerKey,
    FutureOr<String> Function() getToken,
  ) =>
      (Request request) async {
        final token = await getToken();
        if (token != null) {
          return request.updateContextEntry<HttpLinkHeaders>(
            (headers) => HttpLinkHeaders(
              headers: <String, String>{
                ...headers?.headers ?? <String, String>{},
                headerKey: token,
              },
            ),
          );
        } else {
          return request.updateContextEntry<HttpLinkHeaders>(
            (headers) => HttpLinkHeaders(
              headers: <String, String>{
                ...headers?.headers ?? <String, String>{},
              },
            ),
          );
        }
      };
}
