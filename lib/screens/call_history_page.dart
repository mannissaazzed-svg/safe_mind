import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safemind/screens/Outgoing_Call_Page.dart';
import 'package:safemind/screens/call_record.dart';
import 'package:safemind/screens/Call_Service.dart';

enum _CallFilter { all, missed, incoming, outgoing }

class _DateHeader {
  final String label;
  const _DateHeader(this.label);
}

class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key});

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  final SupabaseClient supabase = Supabase.instance.client;

  String get _myId => supabase.auth.currentUser?.id ?? '';

  _CallFilter _filter = _CallFilter.all;

  static const Color _primary = Color(0xFF6C63FF);

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);

    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _filter = _CallFilter.values[_tabCtrl.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<CallRecord> _applyFilter(List<CallRecord> records) {
    switch (_filter) {
      case _CallFilter.all:
        return records;

      case _CallFilter.missed:
        return records.where((r) => r.status == 'missed').toList();

      case _CallFilter.incoming:
        return records.where((r) => r.receiverId == _myId).toList();

      case _CallFilter.outgoing:
        return records.where((r) => r.callerId == _myId).toList();
    }
  }

  Future<void> _callBack(CallRecord record) async {
    final receiverId =
        record.callerId == _myId ? record.receiverId : record.callerId;

    final receiverName = record.callerId == _myId
        ? (record.receiverName ?? 'Unknown')
        : (record.callerName ?? 'Unknown');

    final result = await _callService.startCall(
      receiverId: receiverId,
      channelId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: record.type,
    );

    if (!mounted) return;

    if (result.success && result.callId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OutgoingCallPage(
            callId: result.callId!,
            channelId: DateTime.now().millisecondsSinceEpoch.toString(),
            appId: 'feaef859a6c740ee9880322144128c96',
            type: record.type,
            receiverName: receiverName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Erreur inconnue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primary,
      title: const Text(
        'Historique des appels',
        style: TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: _primary,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: "Tous"),
          Tab(text: "Manqués"),
          Tab(text: "Entrants"),
          Tab(text: "Sortants"),
        ],
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<CallRecord>>(
      stream: _callService.listenCallHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = _applyFilter(snapshot.data!);

        if (records.isEmpty) {
          return const Center(child: Text("Aucun appel"));
        }

        final grouped = _group(records);

        return ListView.builder(
          itemCount: grouped.length,
          itemBuilder: (_, i) {
            final item = grouped[i];

            if (item is _DateHeader) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(item.label),
              );
            }

            return _buildTile(item as CallRecord);
          },
        );
      },
    );
  }

  List<dynamic> _group(List<CallRecord> list) {
    final result = <dynamic>[];
    String? last;

    for (final e in list) {
      final date = DateFormat('yyyy-MM-dd').format(e.createdAt);

      if (date != last) {
        result.add(_DateHeader(date));
        last = date;
      }

      result.add(e);
    }

    return result;
  }

  Widget _buildTile(CallRecord record) {
    final isOutgoing = record.callerId == _myId;

    final name = isOutgoing
        ? (record.receiverName ?? 'Unknown')
        : (record.callerName ?? 'Unknown');

    return ListTile(
      title: Text(name),
      subtitle: Text(record.status),
      trailing: IconButton(
        icon: const Icon(Icons.call),
        onPressed: () => _callBack(record),
      ),
    );
  }
}