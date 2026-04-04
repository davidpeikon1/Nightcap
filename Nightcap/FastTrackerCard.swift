import SwiftUI

// MARK: - Reset Modal

struct ResetModal: View {
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss
    @State private var note: String = ""
    @State private var didConfirm = false

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            if didConfirm {
                resetConfirmationView
            } else {
                resetFormView
            }
        }
        .animation(.easeInOut(duration: 0.28), value: didConfirm)
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
    }

    private var resetFormView: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Starting fresh.")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Color("NCTextPrimary"))

                Text("Everyone resets. The fact that you're tracking it puts you ahead of most people.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What triggered it?")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(Color("NCTextTertiary"))

                TextField("e.g. chocolate after dinner", text: $note)
                    .font(.system(size: 15))
                    .foregroundStyle(Color("NCTextPrimary"))
                    .padding(14)
                    .background(Color("NCSurface"))
                    .cornerRadius(10)
                    .submitLabel(.done)
                    .onSubmit {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .onChange(of: note) { _, v in
                        if v.count > 120 { note = String(v.prefix(120)) }
                    }

                if note.count > 80 {
                    HStack {
                        Spacer()
                        Text("\(note.count) / 120")
                            .font(.system(size: 11))
                            .foregroundStyle(
                                note.count > 110 ? Color("NCWarning") : Color("NCTextTertiary")
                            )
                    }
                    .padding(.top, 2)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: note.count > 80)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    store.logSugar(note: note.isEmpty ? nil : note)
                    withAnimation { didConfirm = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        dismiss()
                    }
                } label: {
                    Text("Restart my fast")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color("NCAccent"))
                        .cornerRadius(12)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(24)
    }

    private var resetConfirmationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color("NCSuccess"))

            Text("Reset logged.")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))

            Text("Every reset is data. The clock starts now.")
                .font(.system(size: 14))
                .foregroundStyle(Color("NCTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
}

// MARK: - Edit Start Time Sheet

struct EditStartTimeSheet: View {
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedDate: Date = Date()

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit start time")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))

                    Text("When did you actually last have processed sugar?")
                        .font(.system(size: 15))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(4)
                }

                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(Color("NCAccent"))
                .labelsHidden()

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        store.setInitialDate(at: selectedDate)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color("NCBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("NCAccent"))
                            .cornerRadius(12)
                    }

                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.system(size: 14))
                            .foregroundStyle(Color("NCTextSecondary"))
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            // Pre-populate with the existing start time if editing, or default
            // to this morning (start of today) for a first-time setup so the
            // user has to consciously scroll forward rather than accidentally
            // saving "right now" as their last sugar time.
            selectedDate = store.lastSugarDate ?? Calendar.current.startOfDay(for: Date())
        }
    }
}
