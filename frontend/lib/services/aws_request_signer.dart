import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AwsRequestSigner {
  final String region;
  final AWSCredentials credentials;

  AwsRequestSigner(this.credentials) : region = AppConfig.awsRegion;

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().toBytes();
    final awsRequest = AWSHttpRequest(
      method: AWSHttpMethod.fromString(request.method),
      uri: request.url,
      headers: Map.from(request.headers),
      body: body,
    );

    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(credentials),
    );

    final signedRequest = await signer.sign(
      awsRequest,
      credentialScope: AWSCredentialScope(
        region: region,
        service: AWSService.apiGateway,
      ),
    );

    print('--- AWS V4 SIGNED REQUEST ---');
    print('Method: ${signedRequest.method.name}');
    print('URL: ${signedRequest.uri}');
    print('Headers:');
    signedRequest.headers.forEach((key, value) {
      print('  $key: $value');
    });
    print('--- END SIGNED REQUEST ---');

    final client = http.Client();
    final bodyBytes = await signedRequest.body.expand((i) => i).toList();
    final httpRequest =
        http.Request(signedRequest.method.name, signedRequest.uri)
          ..headers.addAll(signedRequest.headers)
          ..bodyBytes = bodyBytes;

    return client.send(httpRequest);
  }

  static Future<AwsRequestSigner?> fromAmplify() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: true),
      );
      if (session.isSignedIn) {
        final cognitoSession = session as CognitoAuthSession;
        final credentialsResult = await cognitoSession.credentialsResult;
        final credentials = credentialsResult.value;

        print('Successfully fetched AWS credentials from Amplify.');
        return AwsRequestSigner(credentials);
      } else {
        print('Error: User is not signed in.');
      }
      return null;
    } on Exception catch (e) {
      print('Error fetching AWS credentials: $e');
      return null;
    }
  }
}
