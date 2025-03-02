import 'dart:convert';
import 'package:dart_webrtc/dart_webrtc.dart';

class WebRTCClient {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  Function(Map<String, dynamic>) onDataReceived;

  WebRTCClient({required this.onDataReceived});

  Future<void> initWebRTC() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]
    });

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _sendSignal({'candidate': candidate.toMap()});
    };

    _peerConnection!.onDataChannel = (RTCDataChannel channel) {
      _dataChannel = channel;
      channel.onMessage = (RTCDataChannelMessage message) {
        onDataReceived(jsonDecode(message.text)); // Receive Map
      };
    };
  }

  Future<void> createOffer() async {
    _dataChannel = await _peerConnection!.createDataChannel("data", RTCDataChannelInit());
    _dataChannel!.onMessage = (message) => onDataReceived(jsonDecode(message.text));

    var offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _sendSignal({'sdp': offer.sdp, 'type': 'offer'});
  }

  Future<void> createAnswer(Map<String, dynamic> remoteOffer) async {
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(remoteOffer['sdp'], remoteOffer['type']));
    var answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    _sendSignal({'sdp': answer.sdp, 'type': 'answer'});
  }

  Future<void> addCandidate(Map<String, dynamic> candidate) async {
    await _peerConnection!.addCandidate(RTCIceCandidate(candidate['candidate'], candidate['sdpMid'], candidate['sdpMLineIndex']));
  }

  Future<void> sendData(Map<String, dynamic> data) async {
    _dataChannel?.send(RTCDataChannelMessage(jsonEncode(data)));
  }

  Future<void> _sendSignal(Map<String, dynamic> signal) async {
    // Replace this with a signaling server (WebSockets, HTTP, etc.)
    print("Send Signal: $signal");
  }
}