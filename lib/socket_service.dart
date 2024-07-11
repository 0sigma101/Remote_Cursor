import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;
  static bool _isConnecting = false; // Track whether the connection is in progress

  static Future<bool> connectToSocket(String ipAddress) async {
    if (kDebugMode) {
      print('http://$ipAddress');
    }

    if (_socket == null || (!_isConnected && !_isConnecting)) {
      _isConnecting = true;

      _socket = IO.io(
        'http://' + ipAddress,
        IO.OptionBuilder().setTransports(['websocket']).build(),
      );

      // Define socket event listeners
      _socket!.onConnect((data) {
        _isConnected = true;
        _isConnecting = false; // Connection is established
      });

      _socket!.onDisconnect((data) {
        _isConnected = false;
        _isConnecting = false; // Connection attempt failed
      });

      // Connect to socket
      _socket!.connect();
    }

    // Return true if the connection is successful, false otherwise
    return _isConnected;
  }

  static IO.Socket? get socket => _socket;
  static bool get isConnected => _isConnected;

  static void disconnectSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      _isConnecting = false; // Reset connection status when disconnected
    }
  }
}
