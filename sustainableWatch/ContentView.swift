import SwiftUI
import CoreBluetooth
import EventKit

#if os(macOS)
import AppKit
#endif

struct Checkbox: View {
    @State var isChecked: Bool
    var onChanged: ((Bool) -> Void)? = nil

    var body: some View {
        Button(action: {
            isChecked.toggle()
            onChanged?(isChecked)
        }) {
            HStack {
                Image(systemName: isChecked ? "checkmark.square" : "square")
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var bluetoothManager = BluetoothManager()
    @ObservedObject var calendarManager = CalendarManager()

    @State private var currentDate: Date = Date()
    @State private var selectedEvents = Set<UUID>()

    var body: some View {
        NavigationView {
            VStack {
                if bluetoothManager.isConnected {
                    Text("Connected to Bluetooth device")
                } else {
                    Text("Not connected to Bluetooth device")
                    Button("Connect to Bluetooth device") {
                        // Code to connect to the Bluetooth device
                    }
                }
            }
            .padding()
//            .navigationBarTitle("Bluetooth Connection")
            .background(NavigationLink("", destination: configurationView, isActive: $bluetoothManager.isConnected))
        }
    }

    var configurationView: some View {
        
        VStack {
            batteryIcon
            DatePicker("Enter time", selection: $currentDate, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

            Button("Set time") {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                let timeString = formatter.string(from: currentDate)
                bluetoothManager.setTime(timeString)
            }

            List {
                ForEach(calendarManager.upcomingEvents, id: \.id) { event in
                    HStack {
                        Text(event.startTime)
                        Text(event.title)
                        Spacer()
                        Checkbox(isChecked: selectedEvents.contains(event.id)) { isChecked in
                            if isChecked {
                                selectedEvents.insert(event.id)
                            } else {
                                selectedEvents.remove(event.id)
                            }
                        }
                    }
                }
            }

            Button("Send selected events") {
                // Code to send the selected events
            }
        }
        .padding()
//        .navigationBarTitle("Time and Events")
    }

    var batteryIcon: some View {
        Group {
            if bluetoothManager.batteryLevel >= 80 {
                Image(systemName: "battery.100")
            } else if bluetoothManager.batteryLevel >= 60 {
                Image(systemName: "battery.75")
            } else if bluetoothManager.batteryLevel >= 40 {
                Image(systemName: "battery.50")
            } else if bluetoothManager.batteryLevel >= 20 {
                Image(systemName: "battery.25")
            } else {
                Image(systemName: "battery.0")
            }
        }
//        .resizable()
//        .aspectRatio(contentMode: .fit)
        .frame(width: 50, height: 30)
        .padding()
    }
}
