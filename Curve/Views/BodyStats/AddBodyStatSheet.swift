import SwiftUI
import SwiftData

struct AddBodyStatSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var date = Date()
    @State private var weightText = ""
    @State private var bodyFatText = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)

                Section("Measurements") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("lb", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Body Fat")
                        Spacer()
                        TextField("%", text: $bodyFatText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Add Body Stat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(weightText.isEmpty && bodyFatText.isEmpty)
                }
            }
        }
    }

    private func save() {
        let entry = BodyStatEntry(
            date: date,
            weight: Double(weightText),
            bodyFatPercentage: Double(bodyFatText),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(entry)
        dismiss()
    }
}

#Preview {
    AddBodyStatSheet()
        .modelContainer(PreviewData.container)
}
