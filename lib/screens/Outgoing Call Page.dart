// OutgoingCallPage.dart
import 'package:flutter/material.dart';
import 'package:safemind/screens/call_service.dart';
import 'package:safemind/screens/video_call_page.dart';

class OutgoingCallPage extends StatelessWidget {
  final String callId;
  final String channelId;
  final String appId;

  const OutgoingCallPage({super.key, required this.callId, required this.channelId, required this.appId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<String?>(
        stream: CallService().listenCallStatus(callId),
        builder: (context, snapshot) {
          if (snapshot.data == 'accepted') {
            // الانتقال التلقائي لصفحة المكالمة عند الرد
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => VideoCallPage(channelId: channelId, appId: appId, callId: callId),
              ));
            });
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const Text("Appel en cours..."),
                TextButton(
                  onPressed: () async {
                    await CallService().rejectCall(callId);
                    Navigator.pop(context);
                  },
                  child: const Text("Annuler"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}