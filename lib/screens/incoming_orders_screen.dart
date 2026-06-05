import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/insta_theme.dart';

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _setupSubscription();
  }

  Future<void> _fetchOrders() async {
    final response = await _supabase
        .from('incoming_orders')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    setState(() => _orders = response);
  }

  void _setupSubscription() {
    _channel = _supabase
        .channel('public:incoming_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'incoming_orders',
          callback: (payload) {
            _fetchOrders(); // Refresh list on new order
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _updateStatus(int id, String status) async {
    await _supabase.from('incoming_orders').update({'status': status}).eq('id', id);
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstaPalette.background,
      appBar: AppBar(
        title: const Text('Incoming Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: InstaPalette.background,
        elevation: 0.5,
      ),
      body: _orders.isEmpty
          ? const Center(child: Text('No new orders from WhatsApp.'))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: InstaPalette.border)),
                  child: ListTile(
                    title: Text('${order['quantity']} x ${order['product_name']}'),
                    subtitle: Text('Customer: ${order['customer_phone']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _updateStatus(order['id'], 'confirmed')),
                        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _updateStatus(order['id'], 'rejected')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
