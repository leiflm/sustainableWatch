import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?

    private let targetServiceUUID = CBUUID(string: "67e40001-5c68-d803-bf31-f83f2b6585fa")
    private let timeCharacteristicUUID = CBUUID(string: "67e40002-5c68-d803-bf31-f83f2b6585fa")
    private let batteryLevelCharacteristicUUID = CBUUID(string: "67E4000D-5C68-D803-BF31-F83F2B6585FA")

    @Published var batteryLevel: Int = 0
    private var batteryLevelCharacteristic: CBCharacteristic?

    @Published var isConnected = false
    private var timeCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [targetServiceUUID], options: nil)
        } else {
            print("Central Manager is not powered on.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices([targetServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        if let error = error {
            print("Failed to connect to peripheral: \(error.localizedDescription)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        if let error = error {
            print("Disconnected from peripheral: \(error.localizedDescription)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }

        if let services = peripheral.services {
            for service in services {
                if service.uuid == targetServiceUUID {
                    peripheral.discoverCharacteristics([timeCharacteristicUUID], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == timeCharacteristicUUID {
                    timeCharacteristic = characteristic
                } else if characteristic.uuid == batteryLevelCharacteristicUUID, let value = characteristic.value {
                    let batteryLevelValue = value[0]
                    batteryLevel = Int(batteryLevelValue)
                }
            }
        }
    }

    func setTime(_ time: String) {
        guard let timeCharacteristic = timeCharacteristic, let data = time.data(using: .utf8) else { return }
        peripheral?.writeValue(data, for: timeCharacteristic, type: .withResponse)
    }
}
