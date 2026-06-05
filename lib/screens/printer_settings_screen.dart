import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as thermal;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import '../services/bluetooth_printer_service.dart';
import '../theme/insta_theme.dart';
import '../providers/providers.dart';
import '../models/receipt_settings.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  List<thermal.BluetoothDevice> _bondedDevices = [];
  bool _isConnected = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    await _getBondedDevices();
    final settingsAsync = ref.read(receiptSettingsProvider);
    if (settingsAsync is AsyncData<ReceiptSettings>) {
      final settings = settingsAsync.value;
      final address = settings.rememberedPrinterAddress;
      if (address != null && _bondedDevices.isNotEmpty) {
        final device = _bondedDevices.firstWhere(
          (d) => d.address == address, 
          orElse: () => _bondedDevices.first
        );
        if (device.address == address) {
          debugPrint('Found remembered printer: $address. Attempting auto-connect...');
          await _connect(device);
        }
      }
    }
  }

  Future<void> _getBondedDevices() async {
    List<thermal.BluetoothDevice> devices = await _printerService.getDevices();
    setState(() {
      _bondedDevices = devices;
    });
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    
    try {
      await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await ble.FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Scan error: $e');
    }
    
    setState(() => _isScanning = false);
    _getBondedDevices();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan complete. Please pair in device settings if not visible.')),
    );
  }

  Future<void> _connect(thermal.BluetoothDevice device) async {
    await _printerService.connect(device);
    bool isConnected = await _printerService.bluetooth.isConnected ?? false;
    
    if (isConnected) {
      ref.read(selectedPrinterProvider.notifier).state = device;
      
      // Remember this printer
      final settingsAsync = ref.read(receiptSettingsProvider);
      if (settingsAsync is AsyncData<ReceiptSettings>) {
        final updated = settingsAsync.value.copyWith(rememberedPrinterAddress: device.address);
        await ref.read(receiptSettingsProvider.notifier).updateSettings(updated);
      }
    }

    setState(() {
      _isConnected = isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = ref.watch(selectedPrinterProvider);

    return Scaffold(
      backgroundColor: InstaPalette.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PAIRED PRINTERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: InstaPalette.textSecondary)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _bondedDevices.length,
                itemBuilder: (context, index) {
                  final device = _bondedDevices[index];
                  final isSelected = selectedDevice?.address == device.address;

                  return Card(
                    color: InstaPalette.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? InstaPalette.accent : InstaPalette.border),
                    ),
                    child: ListTile(
                      title: Text(device.name ?? 'Unknown Device', style: const TextStyle(color: InstaPalette.textPrimary)),
                      subtitle: Text(device.address ?? '', style: const TextStyle(color: InstaPalette.textSecondary)),
                      trailing: isSelected && _isConnected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.bluetooth),
                      onTap: () => _connect(device),
                    ),
                  );
                },
              ),
            ),
            if (_isConnected)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _printerService.printReceipt("Test Print Successful!\nZayi Enterprise\n");
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test receipt printed')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to print: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('PRINT TEST RECEIPT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: InstaPalette.textPrimary,
                      foregroundColor: InstaPalette.background,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: InstaPalette.accent,
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
