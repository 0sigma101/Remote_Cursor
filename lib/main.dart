import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remote_cursor/socket_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mouse in Phone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: const GridOverlayScreen(),
      home: const ConnectionSetupScreen(),
    );
  }
}

class ConnectionSetupScreen extends StatefulWidget {
  const ConnectionSetupScreen({super.key});

  @override
  _ConnectionSetupScreenState createState() => _ConnectionSetupScreenState();
}

class _ConnectionSetupScreenState extends State<ConnectionSetupScreen> {
  TextEditingController ipController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'Enter Server IP with port in format ip:port',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                // Show loading indicator while connecting
                setState(() {
                  isLoading = true;
                });

                // Attempt to connect to the server
                bool isConnected =
                await SocketService.connectToSocket(ipController.text);

                if (kDebugMode) {
                  print(SocketService.isConnected);
                }
                // Navigate to the main interface if connected
                if (SocketService.isConnected) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GridOverlayScreen(),
                    ),
                  );
                } else {
                  // Show an error message if connection fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to connect. Please try again.'),
                    ),
                  );
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}

class GridOverlayScreen extends StatefulWidget {
  const GridOverlayScreen({super.key});

  @override
  _GridOverlayScreenState createState() => _GridOverlayScreenState();
}

class _GridOverlayScreenState extends State<GridOverlayScreen> {
  Offset? touchPosition;
  String positionText = '0, 0'; // Default position text

  IO.Socket? socket;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();

    // Initialize socket connection
    if (SocketService.isConnected) {
      setState(() {
        isConnected = true;
        socket = SocketService.socket; // Assign the socket from SocketService
      });

      // Start sending continuous position updates
      sendContinuousUpdates();
    }
  }

  void sendContinuousUpdates() {
    // Send continuous position updates when connected
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (touchPosition != null) {
          // Send touch position data to the laptop via socket
          socket!.emit('move_mouse', [
            {'x': touchPosition!.dx, 'y': touchPosition!.dy}
          ]);
        }
      });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Remote Cursor'),
        backgroundColor: Colors.black,
        elevation: 0.0, // No shadow
        titleTextStyle: const TextStyle(color: Colors.white),
        centerTitle: true,
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            touchPosition = details.localPosition;
            positionText = '${touchPosition!.dx.toInt()}, ${touchPosition!.dy.toInt()}';
            if (kDebugMode) {
              print(isConnected);
            }
            if (SocketService.isConnected) {
              // Send touch position data to the laptop via socket
              socket!.emit('move_mouse', [
                {'x': touchPosition!.dx, 'y': touchPosition!.dy}
              ]);
            }
          });
        },
        onPanEnd: (_) {
          setState(() {
            touchPosition = null;
            positionText = '0, 0'; // Reset position text
          });
        },
        child: Stack(
          children: [
            Container(
              color: Colors.black,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 24,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (touchPosition != null)
              CustomPaint(
                painter: RedDotPainter(touchPosition!),
              ),
            if (touchPosition != null)
              Positioned(
                left: touchPosition!.dx - 40,
                top: touchPosition!.dy - 40,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.black54,
                  child: Text(
                    'Coordinates: $positionText',
                    style: const TextStyle(color: Colors.red), // Change text color to red
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 30.0),
                        backgroundColor: Colors.black87,
                      ),
                      onPressed: () {
                        socket!.emit('left');
                      },
                      child: const Text(
                        'Left',
                        style: TextStyle(color: Colors.white, fontSize: 40.0),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 30.0),
                          backgroundColor: Colors.black87
                      ),
                      onPressed: () {
                        socket!.emit('right');
                      },
                      child: const Text(
                        'Right',
                        style: TextStyle(color: Colors.white, fontSize: 40.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RedDotPainter extends CustomPainter {
  final Offset position;

  RedDotPainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.cyan;
    canvas.drawCircle(position, 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
