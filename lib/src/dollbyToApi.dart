import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MillicastService {
  List<String> iceServersList = [
    'stun:stun.services.mozilla.com',
    'stun:stun.l.google.com:19302',
  ];

  RTCPeerConnection? peerConnection;
  bool isBroadcasting = false;

  void stopStreaming() {
    peerConnection?.close();
  }

  void startStreaming(
    MediaStream hostStream,
  ) async {
    try {
      String? streamingUrl = 'https://director.millicast.com/api/whip/lhg90ac3';
      String? publishToken =
          '9bf5af2f3a6f74df01d90cf3e34c0dc2a8a6ba3315e2f09078b05a75318a9e28';

      // Publish stream to Millicast
      var httpClient = HttpClient();
      var request = await httpClient.postUrl(Uri.parse(streamingUrl));
      request.headers.set('Authorization', 'Bearer $publishToken');
      request.headers.set('Content-Type', 'application/json');

      var response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Failed to start streaming: ${response.statusCode}');
      }

      var responseBody = await response.transform(utf8.decoder).join();
      var responseJson = json.decode(responseBody);

      // Connect to server
      String url = responseJson['data']['urls'][0];
      String jwt = responseJson['data']['jwt'];

      // Create peer connection object
      final configuration = <String, dynamic>{'iceServers': iceServersList};
      final constraints = <String, dynamic>{
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true}
        ]
      };

      peerConnection = await createPeerConnection(configuration, constraints);

      // Add tracks to peer connection object
      hostStream.getTracks().forEach((track) {
        peerConnection?.addTrack(track, hostStream);
      });

      // Start streaming
      var offer = await peerConnection?.createOffer({});
      await peerConnection
          ?.setLocalDescription(RTCSessionDescription(offer?.sdp, offer?.type));
      var sdp = json.encode({'sdp': offer?.sdp, 'type': offer?.type});
      var data = json.encode({'jwt': jwt, 'sdp': sdp});
      var response2 = await httpClient.postUrl(Uri.parse(url));
      response2.headers.set('Content-Type', 'application/json');
      response2.write(data);
      await response2.close();
    } catch (e) {
      log(e.toString());
    }
  }

  void _startStreaming(MediaStream stream) async {
    debugPrint('Call Broadcasting...');
    peerConnection = await createPeerConnection({
      'iceServers': iceServersList,
    }, <String, dynamic>{});
    stream
        .getTracks()
        .forEach((track) => peerConnection!.addTrack(track, stream));
    peerConnection!.onIceCandidate = (candidate) {
      debugPrint('Ice Candidate $candidate');
      if (candidate != null) {
        // Send candidate data to server
      }
    };
    var offer = await peerConnection!.createOffer({});
    await peerConnection!.setLocalDescription(offer);
    // Send offer to server
  }
}
