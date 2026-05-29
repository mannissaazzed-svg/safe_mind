import 'dart:convert';

class CallRecord {
  final String id;
  final String callerId;
  final String receiverId;
  final String channelId;

  final String type;
  final String status;

  final String? callerName;
  final String? receiverName;

  final DateTime createdAt;
  final DateTime? endedAt;

  final int durationSeconds;

  CallRecord({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.channelId,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.durationSeconds,
    this.callerName,
    this.receiverName,
    this.endedAt,
  });

  factory CallRecord.fromMap(Map<String, dynamic> map) {
    return CallRecord(
      id: map['id'] ?? '',
      callerId: map['caller_id'] ?? '',
      receiverId: map['receiver_id'] ?? '',
      channelId: map['channel_id'] ?? '',

      type: map['type'] ?? 'audio',
      status: map['status'] ?? 'ringing',

      callerName: map['caller_name'],
      receiverName: map['receiver_name'],

      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),

      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'])
          : null,

      durationSeconds: map['duration_seconds'] ?? 0,
    );
  }

  // 💡 إضافة هذه الدالة تضمن حل مشكلة الاستدعاء بـ fromJson في أي مكان بالبرنامج
  factory CallRecord.fromJson(Map<String, dynamic> json) => CallRecord.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'channel_id': channelId,

      'type': type,
      'status': status,

      'caller_name': callerName,
      'receiver_name': receiverName,

      'created_at': createdAt.toIso8601String(),

      'ended_at': endedAt?.toIso8601String(),

      'duration_seconds': durationSeconds,
    };
  }

  // 💡 إضافة هذه الدالة أيضاً للاحتياط
  Map<String, dynamic> toJson() => toMap();

  String get durationFormatted {
    final duration = Duration(seconds: durationSeconds);

    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  bool get isMissed => status == 'missed';

  bool get isRejected => status == 'rejected';

  bool get isEnded => status == 'ended';

  bool get isVideo => type == 'video';

  bool get isAudio => type == 'audio';
}