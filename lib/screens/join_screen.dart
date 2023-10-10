import 'package:flutter/material.dart';
import 'package:fs1/screens/call_screen.dart';
import 'package:fs1/services/signaling_service.dart';

class JoinScreen extends StatefulWidget {
  final String selfCalledId;

  const JoinScreen({super.key, required this.selfCalledId});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  dynamic incomingSDPOffer;
  final remoteCalledIdTextEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SignalingService.instance.socket!.on(
        "newCall",
        (data) => {
              if (mounted)
                {
                  setState(
                    () => incomingSDPOffer = data,
                  )
                }
            });
  }

  @override
  void dispose(){
    remoteCalledIdTextEditingController.dispose();
  }


  void _joinCall(
      {required String callerId, required String calleeId, dynamic offer}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return CallScreen(callerId: callerId, calleeId: calleeId, offer: offer,);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('P2P call'),
      ),
      body: SafeArea(
          child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    readOnly: true,
                    controller:
                        TextEditingController(text: widget.selfCalledId),
                    textAlign: TextAlign.center,
                    enableInteractiveSelection: false,
                    decoration: InputDecoration(
                        labelText: 'Your Called Id',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  TextField(
                    controller: remoteCalledIdTextEditingController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                        labelText: 'Remote Called Id',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _joinCall(
                          callerId: widget.selfCalledId,
                          calleeId: remoteCalledIdTextEditingController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                    ),
                    child: Text(
                      'Invite',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onBackground),
                    ),
                  ),
                  if (incomingSDPOffer != null)
                    Positioned(
                        child: ListTile(
                      title: Text(
                          'Incoming call from ${incomingSDPOffer["callerId"]}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                incomingSDPOffer = null;
                              });
                            },
                            icon: const Icon(Icons.call_end),
                            color: Colors.redAccent,
                          ),
                          IconButton(
                            onPressed: () {
                              _joinCall(
                                  callerId: incomingSDPOffer["callerId"],
                                  calleeId: widget.selfCalledId,
                                  offer: incomingSDPOffer['sdpOffer']);
                            },
                            icon: const Icon(
                              Icons.call,
                              color: Colors.greenAccent,
                            ),
                          )
                        ],
                      ),
                    ))
                ],
              ),
            ),
          )
        ],
      )),
    );
  }
}
