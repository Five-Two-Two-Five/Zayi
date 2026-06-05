import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class BluetoothPrinterService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getDevices() async {
    return await bluetooth.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    bool isConnected = await bluetooth.isConnected ?? false;
    if (!isConnected) {
      await bluetooth.connect(device);
    }
  }

  Future<void> printReceipt(String text) async {
    bool isConnected = await bluetooth.isConnected ?? false;
    if (isConnected) {
      bluetooth.printCustom(text, 1, 1);
      bluetooth.printNewLine();
    }
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
  }
}
