import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kUrl = 'https://czqinrgsbmubzqddlqkz.supabase.co';
const _kKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6cWlucmdzYm11YnpxZGRscWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwOTU0NjIsImV4cCI6MjA5MTY3MTQ2Mn0.PFbwcQUWUZNPCM2H-P4N0qCV9rcKy-j8j7jlrGxCX0o';

const _kPatientPrefKey = 'safemind_patient_id';

Future<void> initLocationService() async {
  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _bgEntry,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'safemind_gps',
      initialNotificationTitle: 'SafeMind',
      initialNotificationContent: 'Partage de position actif',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: _bgEntry,
      onBackground: _iosBg,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> _iosBg(ServiceInstance s) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _bgEntry(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('fg').listen((_) => service.setAsForegroundService());
    service.on('bg').listen((_) => service.setAsBackgroundService());
  }
  service.on('stop').listen((_) => service.stopSelf());

  // ── Resolve patient ID ──────────────────────────────────────────────────
  // Priority 1: value persisted from last session (works when app is closed)
  // Priority 2: live 'init' event sent by the UI when app is open
  String? patientId;

  try {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getString(_kPatientPrefKey);
    if (patientId != null) debugPrint('[BG] Loaded persisted id: $patientId');
  } catch (e) {
    debugPrint('[BG] Prefs read: $e');
  }

  // Listen for fresh ID from UI (also persists it)
  service.on('init').listen((data) async {
    final id = data?['patient_id'] as String?;
    if (id != null && id.isNotEmpty) {
      patientId = id;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kPatientPrefKey, id);
      } catch (_) {}
    }
  });

  // If still no ID, wait up to 10 s
  if (patientId == null || patientId!.isEmpty) {
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (patientId != null && patientId!.isNotEmpty) break;
    }
  }

  if (patientId == null || patientId!.isEmpty) {
    debugPrint('[BG] No patientId — stopping');
    service.stopSelf();
    return;
  }

  // ── Init Supabase ────────────────────────────────────────────────────────
  try {
    await Supabase.initialize(url: _kUrl, anonKey: _kKey);
  } catch (_) {}

  final db = Supabase.instance.client;

  // First push right away
  await _sendLocation(service, db, patientId!);

  // Then every 15 s forever (even when app is closed)
  Timer.periodic(const Duration(seconds: 15), (_) async {
    if (patientId != null && patientId!.isNotEmpty) {
      await _sendLocation(service, db, patientId!);
    }
  });
}

Future<void> _sendLocation(
  ServiceInstance service,
  SupabaseClient db,
  String patientId,
) async {
  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 8));

    await db.from('locations').upsert({
      'user_id':    patientId,
      'latitude':   pos.latitude,
      'longitude':  pos.longitude,
      'speed':      pos.speed >= 0 ? pos.speed : null,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');

    debugPrint('[BG] sent ${pos.latitude}, ${pos.longitude}');

    if (service is AndroidServiceInstance &&
        await service.isForegroundService()) {
      final now = DateTime.now();
      service.setForegroundNotificationInfo(
        title: 'SafeMind — Position active',
        content:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
    }

    service.invoke('pos', {
      'lat': pos.latitude,
      'lng': pos.longitude,
      'spd': pos.speed,
    });
  } catch (e) {
    debugPrint('[BG] error: $e');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

class LocationService {
  static final _svc = FlutterBackgroundService();

  static Future<void> start(String patientId) async {
    // Persist BEFORE starting so the BG isolate finds it immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPatientPrefKey, patientId);
    } catch (_) {}

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return;

    if (!await _svc.isRunning()) {
      await _svc.startService();
      await Future.delayed(const Duration(milliseconds: 800));
    }
    _svc.invoke('init', {'patient_id': patientId});
    debugPrint('[LocationService] started for $patientId');
  }

  static Future<void> stop() async {
    _svc.invoke('stop');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPatientPrefKey);
    } catch (_) {}
    debugPrint('[LocationService] stopped');
  }

  static Future<bool> get isRunning => _svc.isRunning();
  static Stream<Map<String, dynamic>?> get positionStream => _svc.on('pos');
}

/*import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


const _kUrl = 'https://czqinrgsbmubzqddlqkz.supabase.co';
const _kKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6cWlucmdzYm11YnpxZGRscWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwOTU0NjIsImV4cCI6MjA5MTY3MTQ2Mn0.PFbwcQUWUZNPCM2H-P4N0qCV9rcKy-j8j7jlrGxCX0o';


Future<void> initLocationService() async {
  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart:                    _bgEntry,
      autoStart:                  false,
      isForegroundMode:           true,
      notificationChannelId:      'safemind_gps',
      initialNotificationTitle:   'SafeMind',
      initialNotificationContent: 'Partage de position actif',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(
      autoStart:    false,
      onForeground: _bgEntry,
      onBackground: _iosBg,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> _iosBg(ServiceInstance s) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}


@pragma('vm:entry-point')
void _bgEntry(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  
  if (service is AndroidServiceInstance) {
    service.on('fg').listen((_) => service.setAsForegroundService());
    service.on('bg').listen((_) => service.setAsBackgroundService());
  }
  service.on('stop').listen((_) { service.stopSelf(); return; });

  
  final completer = Completer<String>();
  service.on('init').listen((data) {
    final id = data?['patient_id'] as String?;
    if (id != null && id.isNotEmpty && !completer.isCompleted) completer.complete(id);
  });

  String patientId;
  try {
    patientId = await completer.future.timeout(const Duration(seconds: 15));
  } catch (_) {
    service.stopSelf();
    return;
  }

  
  try { await Supabase.initialize(url: _kUrl, anonKey: _kKey); }
  catch (_) { /* déjà initialisé */ }

  final db = Supabase.instance.client;

  
  await _sendLocation(service, db, patientId);

  Timer.periodic(const Duration(seconds: 15), (_) async {
    await _sendLocation(service, db, patientId);
  });
}

Future<void> _sendLocation(ServiceInstance service, SupabaseClient db, String patientId) async {
  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 8));

    await db.from('locations').upsert({
      'user_id':    patientId,
      'latitude':   pos.latitude,
      'longitude':  pos.longitude,
      'speed':      pos.speed >= 0 ? pos.speed : null,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');

    debugPrint('[BG] ${pos.latitude}, ${pos.longitude}');

    
    if (service is AndroidServiceInstance && await service.isForegroundService()) {
      final now = DateTime.now();
      service.setForegroundNotificationInfo(
        title: 'SafeMind — Position active',
        content: '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
      );
    }

    
    service.invoke('pos', {
      'lat': pos.latitude,
      'lng': pos.longitude,
      'spd': pos.speed,
    });

  } catch (e) {
    debugPrint('[BG] $e');
  }
}


class LocationService {
  static final _svc = FlutterBackgroundService();

  
  static Future<void> start(String patientId) async {
    
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) return;

    if (!await _svc.isRunning()) {
      await _svc.startService();
      await Future.delayed(const Duration(milliseconds: 800));
    }
    
    _svc.invoke('init', {'patient_id': patientId});
    debugPrint('LocationService started — patient: $patientId');
  }

  static Future<void> stop() async {
    _svc.invoke('stop');
    debugPrint('LocationService stopped');
  }

  static Future<bool> get isRunning => _svc.isRunning();

  
  static Stream<Map<String, dynamic>?> get positionStream => _svc.on('pos');
}
*/