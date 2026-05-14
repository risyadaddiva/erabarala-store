import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/printer_service.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final connected = await PrinterService.instance.isConnected();
    setState(() => _isConnected = connected);
  }

  Future<void> _scanDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await PrinterService.instance.getBondedDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    setState(() => _isLoading = true);
    try {
      await PrinterService.instance.connect(device);
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terhubung ke ${device.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghubungkan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await PrinterService.instance.disconnect();
    setState(() {
      _connectedDevice = null;
      _isConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                      size: 40,
                      color: _isConnected ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected
                                ? 'Terhubung'
                                : 'Tidak Terhubung',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  _isConnected ? Colors.blue : Colors.grey,
                            ),
                          ),
                          if (_connectedDevice != null)
                            Text(
                              _connectedDevice!.name ?? 'Unknown',
                              style: const TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    if (_isConnected)
                      FilledButton(
                        onPressed: _disconnect,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Putus'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _scanDevices,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                    _isLoading ? 'Mencari...' : 'Cari Perangkat Bluetooth'),
              ),
            ),
            const SizedBox(height: 16),
            if (_devices.isNotEmpty) ...[
              const Text(
                'Perangkat Ditemukan:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(device.name ?? 'Unknown'),
                        subtitle: Text(device.address ?? ''),
                        trailing: FilledButton(
                          onPressed: () => _connectDevice(device),
                          child: const Text('Hubungkan'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (!_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_searching,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Tekan tombol di atas untuk\nmencari printer Bluetooth',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
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
