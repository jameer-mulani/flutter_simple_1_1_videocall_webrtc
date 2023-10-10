import 'package:socket_io_client/socket_io_client.dart';

class SignalingService{
  //socket instance
  Socket? socket;

  SignalingService._();
  static final instance = SignalingService._();

  init({required String webSocketUrl, required String selfCallerId}){
    //lets initialize socket
    socket = io(webSocketUrl, {
      'transports' : ['websocket'],
      'query' : {'callerId' : selfCallerId}
    });


    socket!.onConnect((data) => {
      print('socket connected')
    });

    socket!.onConnectError((data) => {
      print('socket connect error $data')
    });

    socket!.connect();

  }

}