import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:millicast_flutter_sdk/millicast_flutter_sdk.dart';

var _logger = getLogger('MillicastPublishUserMedia');

const connectOptions = {
  'bandwidth': 0,
  'disableVideo': false,
  'disableAudio': false,
};

const String sourceId = String.fromEnvironment('sourceId');

class MillicastPublishUserMedia extends Publish {
  MillicastPublishUserMedia(options, tokenGenerator, autoReconnect)
      : super(
            streamName: options['streamName'],
            tokenGenerator: tokenGenerator,
            autoReconnect: autoReconnect) {
    mediaManager = MillicastMedia(options);
  }
  MillicastMedia? mediaManager;
  List<String>? supportedCodecs;

  static Future<MillicastPublishUserMedia> build(
      options, tokenGenerator, autoReconnect) async {
    var instance =
        MillicastPublishUserMedia(options, tokenGenerator, autoReconnect);

    await instance.getMediaStream();
    return instance;
  }

  Future getMediaStream() async {
    try {
      return await mediaManager?.getMedia();
    } catch (e) {
      rethrow;
    }
  }

  void muteMedia(type, boo) {
    if (type == 'audio') {
      mediaManager?.muteAudio(boolean: boo);
    } else if (type == 'video') {
      mediaManager?.muteVideo(boolean: boo);
    }
  }

  void migrate() {
    signaling?.emit('migrate');
  }

  @override
  connect({Map<String, dynamic> options = connectOptions}) async {
    if (mediaManager == null) {
      throw Exception('mediaManager not initialized correctly');
    }
    await super.connect(
      options: {...options, 'mediaStream': mediaManager?.mediaStream},
    );
  }

  Future<bool> hangUp(bool connected) async {
    if (connected) {
      _logger.w('Disconnecting');
      await stop();
    }
    return connected;
  }

  void updateBandwidth(num bitrate) async {
    await webRTCPeer.updateBitrate(bitrate: bitrate);
  }

  void close() async {
    await webRTCPeer.closeRTCPeer();
  }
}

class MillicastMedia {
  MillicastMedia(Map<String, dynamic>? options) {
    constraints = {
      'audio': {
        'echoCancellation': true,
        'channelCount': {'ideal': 2},
      },
      'video': {
        'height': 1080,
        'width': 1920,
      },
    };

    if (options != null && options['constraints'] != null) {
      constraints.addAll(options['constraints']);
    }
  }
  MediaStream? mediaStream;
  late Map<String, dynamic> constraints;

  Future<MediaStream?>? getMedia() async {
    /// gets user cam and mic

    try {
      mediaStream = await navigator.mediaDevices.getUserMedia(constraints);

      // Adding this check check so we don't lose web support
      if (!kIsWeb) {
        if (Platform.isIOS) {
          mediaStream?.getAudioTracks()[0].enableSpeakerphone(true);
        }
      }
      return mediaStream;
    } catch (e) {
      throw Error();
    }
  }

  /// [boolean] - true if you want to mute the audio, false for mute it.
  /// Returns [bool] - returns true if it was changed, otherwise returns false.
  bool muteAudio({boolean = true}) {
    var changed = false;
    if (mediaStream != null) {
      mediaStream?.getAudioTracks()[0].enabled = !boolean;
      changed = true;
    } else {
      _logger.e('There is no media stream object.');
    }
    return changed;
  }

  bool switchCamera({boolean = true}) {
    var changed = false;
    if (mediaStream != null) {
      var mediaStreamTrack = mediaStream?.getVideoTracks()[0];
      Helper.switchCamera(mediaStreamTrack!);
      changed = true;
    } else {
      _logger.e('There is no media stream object.');
    }
    return changed;
  }

  ///
  /// [bool] boolean - true if you want to mute the video, false for mute it.
  /// Returns [bool] - returns true if it was changed, otherwise returns false.
  ///
  bool muteVideo({boolean = true}) {
    var changed = false;
    if (mediaStream != null) {
      mediaStream?.getVideoTracks()[0].enabled = !boolean;
      changed = true;
    } else {
      _logger.e('There is no media stream object.');
    }
    return changed;
  }
}
