import 'package:flutter/material.dart';
import 'package:fs1/services/signaling_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallScreen extends StatefulWidget {
  const CallScreen(
      {super.key, required this.callerId, required this.calleeId, this.offer});

  final String callerId;
  final String calleeId;
  final dynamic offer;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _socket = SignalingService.instance.socket;

  //local video renderer
  final _localRTCVideoRenderer = RTCVideoRenderer();

  //remote video renderer
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  //mediastream for local peer
  MediaStream? _localStream;

  //RTC peer connection
  RTCPeerConnection? _rtcPeerConnection;

  //list of rtc candidates to be sent over websockets
  List<RTCIceCandidate> _rtcIceCandidates = [];

  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = false;

  @override
  void initState() {
    //initialise renderes
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();

    //set up peerconnection
    _setupPeerConnection();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  RTCVideoView(
                    _remoteRTCVideoRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: SizedBox(
                      height: 150,
                      width: 120,
                      child: RTCVideoView(
                        _localRTCVideoRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                      onPressed: _toggleMic,
                      icon: isAudioOn
                          ? const Icon(Icons.mic)
                          : const Icon(Icons.mic_off)),
                  IconButton(
                      onPressed: _toggleCamera,
                      icon: isVideoOn
                          ? const Icon(Icons.videocam)
                          : const Icon(Icons.videocam_off)),
                  IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.switch_camera)),
                  IconButton(
                      onPressed: _leaveCall,
                      icon: const Icon(
                        Icons.call_end,
                        size: 30,
                      ))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _setupPeerConnection() async {
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
        {
          'url': 'turn:192.158.29.39:3478?transport=udp',
          'credential': 'JZEOEt2V3Qb0y27GRntt2u2PAYA=',
          'username': '28224511:1379330808'
        },
        {
          'url': 'turn:192.158.29.39:3478?transport=tcp',
          'credential': 'JZEOEt2V3Qb0y27GRntt2u2PAYA=',
          'username': '28224511:1379330808'
        }
      ]
    });

    //listen for remote media track event
    _rtcPeerConnection!.onTrack = (event) {
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    //get local stream for cam stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });


    // final mediaConstraints = <String, dynamic>{'audio': true, 'video': true};
    // _localStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);

    //add mediatrack to peerconnection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    //set local video source
    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    //for incoming call
    if (widget.offer != null) {
      //listen for remotecandidate
      _socket!.on("IceCandidate", (data) {
        String candidate = data["iceCandidate"]["candidate"];
        String sdpMid = data["iceCandidate"]["id"];
        int sdpMLineIndex = data["iceCandidate"]["label"];
        _rtcPeerConnection!
            .addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex));
      });

      //set sdp offer as remoteDescription
      await _rtcPeerConnection!.setRemoteDescription(
          RTCSessionDescription(widget.offer['sdp'], widget.offer['type']));

      //create SDP answer
      RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();
      //set SDP answer as local description
      _rtcPeerConnection!.setLocalDescription(answer);

      //send sdp answer to remote peer over socket
      _socket!.emit("answerCall",
          {'callerId': widget.callerId, 'sdpAnswer': answer.toMap()});
    }
    //for outgoing call
    else {
      //listen for local candidate and set it to rtcPeerConnection
      _rtcPeerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        _rtcIceCandidates.add(candidate);
      };
      //when call is accepted by remote peer
      _socket!.on("callAnswered", (data) async {
        //set sdp answer as remoteDescription for remotePeerConnection
        await _rtcPeerConnection!.setRemoteDescription(
          RTCSessionDescription(
              data["sdpAnswer"]["sdp"], data["sdpAnswer"]["type"]),
        );

        //send ice candidate generated to remote peer over signalling
        for (RTCIceCandidate candidate in _rtcIceCandidates) {
          _socket!.emit("IceCandidate", {
            "calleeId": widget.calleeId,
            "iceCandidate": {
              "id": candidate.sdpMid,
              "label": candidate.sdpMLineIndex,
              "candidate": candidate.candidate
            }
          });
        }
      });

      //create SDP offer
      RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();

      await _rtcPeerConnection!.setLocalDescription(offer);

      //make a call over socket to remote peer
      _socket!.emit(
          "makeCall", {"calleeId": widget.calleeId, "sdpOffer": offer.toMap()});


    }
  }

  _leaveCall() {
    Navigator.pop(context);
  }

  _toggleMic() {
    isAudioOn = !isAudioOn;
    _localStream?.getAudioTracks().forEach((element) {
      element.enabled = isAudioOn;
    });
    setState(() {});
  }

  _toggleCamera() {
    isVideoOn = !isVideoOn;
    _localStream?.getAudioTracks().forEach((element) {
      element.enabled = isVideoOn;
    });
    setState(() {});
  }

  _switchCamera() {
    isFrontCameraSelected = !isFrontCameraSelected;
    _localStream?.getVideoTracks().forEach((element) {
      element.switchCamera();
    });
    setState(() {});
  }
}
