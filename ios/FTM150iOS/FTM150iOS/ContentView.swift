import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: RadioViewModel
    @ObservedObject var settings: AppSettings

    @State private var showingSettings = false
    @State private var microphoneExpanded = false

    private let functionButtons: [FunctionSpec] = [
        .init(command: "sdx", title: "S-DX", subtitle: nil),
        .init(command: "band", title: "BAND", subtitle: "SCOPE"),
        .init(command: "pmg", title: "PMG", subtitle: "PW"),
        .init(command: "vm", title: "V/M", subtitle: "MW"),
        .init(command: "f", title: "F", subtitle: "BACK"),
        .init(command: "power", title: "⏻", subtitle: nil, isPower: true)
    ]

    private let knobSections: [KnobSpec] = [
        .init(label: "L VOL/SQL", leftCommand: "ul_left", pressCommand: "ul_press", rightCommand: "ul_right"),
        .init(label: "R VOL/SQL", leftCommand: "ur_left", pressCommand: "ur_press", rightCommand: "ur_right"),
        .init(label: "L DIAL", leftCommand: "bl_left", pressCommand: "bl_press", rightCommand: "bl_right"),
        .init(label: "R DIAL", leftCommand: "br_left", pressCommand: "br_press", rightCommand: "br_right", dialMode: true)
    ]

    private let microphoneButtons: [MicButtonSpec] = [
        .init(command: "mic_a", label: "A"),
        .init(command: "mic_b", label: "B"),
        .init(command: "mic_c", label: "C"),
        .init(command: "mic_d", label: "D"),
        .init(command: "mic_1", label: "1"),
        .init(command: "mic_2", label: "2"),
        .init(command: "mic_3", label: "3"),
        .init(command: "mic_p1", label: "P1"),
        .init(command: "mic_4", label: "4"),
        .init(command: "mic_5", label: "5"),
        .init(command: "mic_6", label: "6"),
        .init(command: "mic_p2", label: "P2"),
        .init(command: "mic_7", label: "7"),
        .init(command: "mic_8", label: "8"),
        .init(command: "mic_9", label: "9"),
        .init(command: "mic_p3", label: "P3"),
        .init(command: "mic_star", label: "*"),
        .init(command: "mic_0", label: "0"),
        .init(command: "mic_hash", label: "#"),
        .init(command: "mic_p4", label: "P4"),
        .init(command: "mic_up", label: "UP"),
        .init(command: "mic_down", label: "DOWN"),
        .init(command: "mic_mute", label: "MUTE")
    ]

    private var controlsEnabled: Bool {
        guard let state = viewModel.radioState else { return true }
        return state.radioPowered || state.poweringOn
    }

    private var radioReceiving: Bool {
        viewModel.radioState?.left.rxActive == true || viewModel.radioState?.right.rxActive == true
    }

    var body: some View {
        ZStack {
            AppTheme.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {
                RadioPanelView(
                    state: viewModel.radioState,
                    enabled: controlsEnabled,
                    viewModel: viewModel
                )
                .padding(.horizontal, 12)
                .padding(.top, 10)

                functionBar
                    .padding(.horizontal, 12)

                Spacer(minLength: 0)
            }
        }
        .task {
            viewModel.startIfNeeded()
        }
        .safeAreaInset(edge: .bottom) {
            bottomDock
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(settings: settings, viewModel: viewModel) {
                    viewModel.reconnect()
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var functionBar: some View {
        HStack(spacing: 8) {
            ForEach(functionButtons) { spec in
                PressDurationButton(
                    title: spec.title,
                    subtitle: spec.subtitle,
                    accent: spec.isPower ? AppTheme.tx : AppTheme.orangeBright,
                    enabled: spec.isPower ? true : controlsEnabled,
                    compact: true,
                    minHeight: 50
                ) { isLong in
                    if spec.isPower {
                        viewModel.powerButton(long: isLong)
                    } else {
                        viewModel.topButton(spec.command, long: isLong)
                    }
                }
            }
        }
        .padding(10)
        .background(AppTheme.sectionFill)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.sectionStroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.34), radius: 18, y: 10)
    }

    private var bottomDock: some View {
        VStack(spacing: 10) {
            if microphoneExpanded {
                microphonePad
                    .padding(.horizontal, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 20) {
                SmallDockButton(systemName: microphoneExpanded ? "chevron.down.circle.fill" : "square.grid.2x2.fill") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        microphoneExpanded.toggle()
                    }
                }

                Spacer(minLength: 0)

                Button {
                    viewModel.toggleTXAudio()
                } label: {
                    PushToTalkMicButton(
                        isListening: radioReceiving && !viewModel.isTXAudioRunning,
                        isTransmitting: viewModel.isTXAudioRunning,
                        isPressed: viewModel.isTXAudioRunning
                    )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                SmallDockButton(systemName: "gearshape.fill") {
                    showingSettings = true
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.sectionFill)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(AppTheme.sectionStroke, lineWidth: 1))
                    .shadow(color: .black.opacity(0.42), radius: 20, y: 10)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: microphoneExpanded)
        .background(.clear)
    }

    private var microphonePad: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Microphone")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.labelPrimary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        microphoneExpanded = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.labelSecondary)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(microphoneButtons) { spec in
                    Button {
                        viewModel.microphoneKey(spec.command)
                    } label: {
                        Text(spec.label)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(MicrophoneKeyButtonStyle())
                    .disabled(!controlsEnabled)
                }
            }
        }
        .padding(14)
        .background(AppTheme.sectionFill)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.sectionStroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.34), radius: 18, y: 10)
    }
}

private struct RadioPanelView: View {
    let state: RadioState?
    let enabled: Bool
    @ObservedObject var viewModel: RadioViewModel

    private let leftKnobs: [KnobSpec] = [
        .init(label: "L VOL/SQL", leftCommand: "ul_left", pressCommand: "ul_press", rightCommand: "ul_right"),
        .init(label: "L DIAL", leftCommand: "bl_left", pressCommand: "bl_press", rightCommand: "bl_right")
    ]

    private let rightKnobs: [KnobSpec] = [
        .init(label: "R VOL/SQL", leftCommand: "ur_left", pressCommand: "ur_press", rightCommand: "ur_right"),
        .init(label: "R DIAL", leftCommand: "br_left", pressCommand: "br_press", rightCommand: "br_right", dialMode: true)
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("DUAL BAND TRANSCEIVER FTM-150")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.brandOrange)
                .tracking(2.4)

            VStack(spacing: 10) {
                RadioSideDisplayCard(side: state?.left, fallbackSide: "L")
                InlineKnobStrip(specs: leftKnobs, enabled: enabled, viewModel: viewModel)
                RadioSideDisplayCard(side: state?.right, fallbackSide: "R")
                InlineKnobStrip(specs: rightKnobs, enabled: enabled, viewModel: viewModel)
                if hasFooterContent {
                    DisplayFooterPanel(state: state)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.lcdFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.lcdFrameStroke, lineWidth: 2)
                    )
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.radioBody)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(AppTheme.radioStroke, lineWidth: 1))
                .shadow(color: .black.opacity(0.48), radius: 26, y: 14)
        )
    }

    private var hasFooterContent: Bool {
        (state?.overlay?.active == true) || (state?.menu?.visible == true)
    }
}

private struct RadioSideDisplayCard: View {
    let side: RadioSideState?
    let fallbackSide: String

    private var source: String {
        let raw = side?.source.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if raw.hasPrefix("MEM") {
            let group = side?.memGroup.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return group.isEmpty ? "MEM" : group
        }
        if raw.hasPrefix("VFO") { return "VFO" }
        if raw.hasPrefix("HOME") { return "HOME" }
        return raw.isEmpty ? "VFO" : raw
    }

    private var shift: String? {
        normalizedTag(side?.shift)
    }

    private var tone: String? {
        normalizedTag(side?.tone)
    }

    private var memoryLine: String {
        let memNo = side?.memNo.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = side?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let group = side?.memGroup.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let parts = [group, memNo, name].filter { !$0.isEmpty }
        return parts.isEmpty ? " " : parts.joined(separator: " · ")
    }

    private var lowerState: RadioLowerState? {
        side?.lower
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                HStack(spacing: 6) {
                    DisplayTag(text: source)

                    if let shift {
                        DisplayTag(text: shift, compact: true)
                    }

                    if let tone {
                        DisplayTag(text: tone, compact: true)
                    }
                }

                Spacer(minLength: 8)

                StatusLamp(isRX: side?.rxActive == true, isTX: side?.txActive == true)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(side?.freq ?? "---.---")
                    .font(.system(size: 40, weight: .black, design: .monospaced))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.lcdText)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(side?.mode.isEmpty == false ? side?.mode ?? "" : "--")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText.opacity(0.88))
            }

            Text(memoryLine)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.lcdText.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            HStack(spacing: 10) {
                Text(lowerState?.label.isEmpty == false ? lowerState?.label ?? "" : "S")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText)
                    .frame(width: 42, alignment: .leading)

                MeterBar(activeSegments: meterSegments(lowerState), accent: AppTheme.lcdText)

                Text(side?.modeRaw.isEmpty == false ? side?.modeRaw ?? "" : "FM")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText.opacity(0.85))
                    .frame(minWidth: 44, alignment: .trailing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .opacity(side?.isMain == true ? 1 : 0.66)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(side?.isMain == true ? AppTheme.sideCardFillActive : AppTheme.sideCardFillInactive)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(side?.isMain == true ? AppTheme.orangeDark : AppTheme.sideCardStroke, lineWidth: side?.isMain == true ? 2 : 1))
        )
        .shadow(color: side?.isMain == true ? AppTheme.orangeDark.opacity(0.18) : .clear, radius: 10, y: 4)
    }

    private func normalizedTag(_ raw: String?) -> String? {
        let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty, text != "-", text != "OFF" else { return nil }
        return text
    }

    private func meterSegments(_ lower: RadioLowerState?) -> Int {
        guard let side else { return 0 }
        if side.txActive {
            return normalizeToSegments(side.sMeterRaw ?? 0, maxRaw: 10)
        }
        if side.rxActive {
            return normalizeToSegments(side.sMeterRaw ?? 0, maxRaw: 10)
        }
        guard let lower else { return 0 }
        if lower.label.uppercased() == "VOL" {
            return normalizeToSegments(firstNumber(lower.volRaw, lower.barRaw, lower.valueRaw, lower.sideValueRaw, 0), maxRaw: 127)
        }
        if lower.label.uppercased() == "SQL" {
            return normalizeToSegments(firstNumber(lower.sqlRaw, lower.barRaw, lower.valueRaw, lower.sideValueRaw, 0), maxRaw: 32)
        }
        return 0
    }

    private func firstNumber(_ values: Int?...) -> Int {
        for value in values {
            if let value {
                return value
            }
        }
        return 0
    }

    private func normalizeToSegments(_ raw: Int, maxRaw: Int) -> Int {
        let safeMax = max(maxRaw, 1)
        guard raw > 0 else { return 0 }
        let clipped = min(max(raw, 0), safeMax)
        return max(1, min(16, Int(round((Double(clipped) / Double(safeMax)) * 16.0))))
    }
}

private struct DisplayFooterPanel: View {
    let state: RadioState?

    var body: some View {
        Group {
            if let overlay = state?.overlay, overlay.active {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.footerFill)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.footerStroke, lineWidth: 1))
                    DisplayOverlayView(overlay: overlay)
                        .padding(10)
                }
            } else if let menu = state?.menu, menu.visible {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.footerFill)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.footerStroke, lineWidth: 1))
                    DisplayMenuView(menu: menu)
                        .padding(10)
                }
            } else {
                EmptyView()
            }
        }
        .frame(height: hasVisibleContent ? 108 : 0)
        .clipped()
    }

    private var hasVisibleContent: Bool {
        (state?.overlay?.active == true) || (state?.menu?.visible == true)
    }
}

private struct DisplayOverlayView: View {
    let overlay: RadioOverlayState

    var body: some View {
        VStack(spacing: 8) {
            if let title = firstNonEmpty([overlay.title, overlay.kind == "text" ? nil : overlay.kind]) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            if let message = firstNonEmpty([overlay.message, overlay.text]) {
                Text(message)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.orangeBright)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            if let options = overlay.options, !options.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                        Text(option.text)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(option.selected ? .white : AppTheme.labelSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(option.selected ? AppTheme.orangeDark.opacity(0.76) : Color.white.opacity(0.08))
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }
}

private struct DisplayMenuView: View {
    let menu: RadioMenuState

    private var previewRows: [RadioMenuRow] {
        let rows = menu.rows ?? []
        guard !rows.isEmpty else { return [] }
        let selected = rows.firstIndex(where: { row in
            if let rowIndex = row.row, rowIndex == menu.selectedRow { return true }
            if let selectedNum = menu.selectedNum, row.num == String(selectedNum) { return true }
            if let selectedIndex = menu.selectedIndex, row.row == selectedIndex { return true }
            return false
        }) ?? 0
        let start = max(0, min(selected, max(rows.count - 4, 0)))
        let end = min(rows.count, start + 4)
        return Array(rows[start ..< end])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(menu.title?.isEmpty == false ? menu.title ?? "" : "Menu")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.orangeBright)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if let footer = menu.footer, !footer.isEmpty {
                    Text(footer)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.labelSecondary)
                }
            }

            if !previewRows.isEmpty {
                VStack(spacing: 6) {
                    ForEach(previewRows) { row in
                        let isSelected = isRowSelected(row)
                        HStack(spacing: 8) {
                            Text(row.num ?? "")
                                .frame(width: 40, alignment: .leading)
                            Text(row.label ?? row.text ?? "")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.value ?? "")
                                .frame(maxWidth: 110, alignment: .trailing)
                        }
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(isSelected ? AppTheme.orangeBright : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(isSelected ? AppTheme.menuSelectedFill : AppTheme.menuRowFill)
                        )
                    }
                }
            } else if let value = menu.value, !value.isEmpty {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Text("Menu active")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.labelSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func isRowSelected(_ row: RadioMenuRow) -> Bool {
        if let rowIndex = row.row, rowIndex == menu.selectedRow { return true }
        if let selectedIndex = menu.selectedIndex, row.row == selectedIndex { return true }
        if let selectedNum = menu.selectedNum, row.num == String(selectedNum) { return true }
        return false
    }
}

private struct InlineKnobStrip: View {
    let specs: [KnobSpec]
    let enabled: Bool
    @ObservedObject var viewModel: RadioViewModel

    var body: some View {
        HStack(spacing: 0) {
            if let first = specs.first {
                InlineKnobControl(spec: first, enabled: enabled, viewModel: viewModel)
            }
            Spacer(minLength: 0)
            if specs.count > 1 {
                InlineKnobControl(spec: specs[1], enabled: enabled, viewModel: viewModel)
            }
        }
    }
}

private struct InlineKnobControl: View {
    let spec: KnobSpec
    let enabled: Bool
    @ObservedObject var viewModel: RadioViewModel

    var body: some View {
        HStack(spacing: 6) {
            KnobArrowButton(label: "◀", enabled: enabled) {
                if spec.dialMode {
                    viewModel.dial(spec.leftCommand)
                } else {
                    viewModel.sendPulse(spec.leftCommand, duration: "5ms")
                }
            }

            MiniHoldButton(enabled: enabled) { isLong in
                viewModel.knobPress(spec.pressCommand, long: isLong)
            }

            KnobArrowButton(label: "▶", enabled: enabled) {
                if spec.dialMode {
                    viewModel.dial(spec.rightCommand)
                } else {
                    viewModel.sendPulse(spec.rightCommand, duration: "5ms")
                }
            }
        }
    }
}

private struct PressDurationButton: View {
    let title: String
    let subtitle: String?
    let accent: Color
    let enabled: Bool
    var compact: Bool = false
    var minHeight: CGFloat? = nil
    let action: (Bool) -> Void

    @State private var didTriggerLong = false

    private let longThreshold: Double = 0.45

    var body: some View {
        Button {
            guard enabled else { return }
            if didTriggerLong {
                didTriggerLong = false
            } else {
                action(false)
            }
        }
        label: {
            VStack(spacing: compact ? 2 : 4) {
                Text(title)
                    .font(.system(size: compact ? 12 : 16, weight: .black, design: .rounded))
                    .foregroundStyle(titleColor)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: compact ? 8 : 11, weight: .bold, design: .rounded))
                        .foregroundStyle(subtitleColor)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: minHeight ?? (compact ? 54 : 66))
            .padding(.horizontal, compact ? 3 : 6)
        }
        .buttonStyle(PressDurationButtonStyle(accent: accent, compact: compact))
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.42)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: longThreshold, maximumDistance: 18)
                .onEnded { _ in
                    guard enabled else { return }
                    didTriggerLong = true
                    action(true)
                }
        )
    }

    private var titleColor: Color {
        title == "⏻" ? accent : .white
    }

    private var subtitleColor: Color {
        title == "⏻" ? accent.opacity(0.82) : AppTheme.buttonSubtitle
    }
}

private struct KnobArrowButton: View {
    let label: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .frame(width: 42, height: 34)
        }
        .buttonStyle(DarkCapsuleButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.42)
    }
}

private struct MiniHoldButton: View {
    let enabled: Bool
    let action: (Bool) -> Void

    @State private var didTriggerLong = false

    var body: some View {
        Button {
            guard enabled else { return }
            if didTriggerLong {
                didTriggerLong = false
            } else {
                action(false)
            }
        } label: {
            Circle()
                .fill(LinearGradient(colors: [AppTheme.buttonTop, AppTheme.buttonBottom], startPoint: .top, endPoint: .bottom))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(AppTheme.buttonStroke, lineWidth: 1))
                .overlay(
                    Circle()
                        .fill(Color.black.opacity(0.75))
                        .frame(width: 10, height: 10)
                )
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.42)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45, maximumDistance: 18)
                .onEnded { _ in
                    guard enabled else { return }
                    didTriggerLong = true
                    action(true)
                }
        )
    }
}

private struct PushToTalkMicButton: View {
    let isListening: Bool
    let isTransmitting: Bool
    let isPressed: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isTransmitting
                            ? [AppTheme.tx.opacity(0.94), AppTheme.txDark]
                            : [AppTheme.micTop, AppTheme.micBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 84, height: 84)
                .overlay(
                    Circle()
                        .stroke(
                            isTransmitting ? AppTheme.tx.opacity(0.95) : (isListening ? AppTheme.rx.opacity(0.9) : AppTheme.orangeDark.opacity(0.7)),
                            lineWidth: 4
                        )
                )
                .shadow(color: (isTransmitting ? AppTheme.tx : (isListening ? AppTheme.rx : AppTheme.orangeDark)).opacity(0.42), radius: isPressed ? 10 : 18)

            Image(systemName: "mic.fill")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white)
        }
        .scaleEffect(isPressed ? 0.96 : 1)
        .accessibilityLabel("Toggle PTT")
    }
}

private struct SmallDockButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(LinearGradient(colors: [AppTheme.buttonTop, AppTheme.buttonBottom], startPoint: .top, endPoint: .bottom))
                )
                .overlay(Circle().stroke(AppTheme.buttonStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct DisplayTag: View {
    let text: String
    var compact: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: compact ? 12 : 13, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.orangeBright)
            .padding(.horizontal, compact ? 8 : 10)
            .frame(minHeight: compact ? 24 : 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.tagFill)
            )
    }
}

private struct DisplayIndicator: View {
    let text: String
    let accent: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(accent)
            )
    }
}

private struct StatusLamp: View {
    let isRX: Bool
    let isTX: Bool

    var body: some View {
        Capsule(style: .continuous)
            .fill(AppTheme.tagFill)
            .frame(width: 54, height: 18)
            .overlay(
                Capsule(style: .continuous)
                    .fill(lampColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
            )
    }

    private var lampColor: LinearGradient {
        if isTX {
            return LinearGradient(colors: [AppTheme.tx.opacity(0.95), AppTheme.txDark], startPoint: .leading, endPoint: .trailing)
        }
        if isRX {
            return LinearGradient(colors: [AppTheme.rx.opacity(0.95), AppTheme.rxDark], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(colors: [AppTheme.lampOff, AppTheme.lampOffDark], startPoint: .leading, endPoint: .trailing)
    }
}

private struct MeterBar: View {
    let activeSegments: Int
    let accent: Color

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 16, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(index < activeSegments ? accent.opacity(0.92) : Color.black.opacity(0.16))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 16)
    }
}

private struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var viewModel: RadioViewModel

    let onReconnect: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Server URL", text: $settings.serverURLString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                TextField("Username", text: $settings.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $settings.password)

                Toggle("Auto connect", isOn: $settings.autoConnect)
            }

            Section("Runtime") {
                runtimeRow(label: "Transport", value: viewModel.backendStatus.label)
                runtimeRow(label: "RX audio", value: viewModel.isRXAudioRunning ? "running" : "idle")
                runtimeRow(label: "TX audio", value: viewModel.isTXAudioRunning ? "running" : "idle")
                runtimeRow(label: "PTT", value: viewModel.radioState?.pttLatched == true ? "latched" : "momentary")
            }

            Section("Actions") {
                Button("Reconnect") {
                    onReconnect()
                }

                Button("Refresh state") {
                    viewModel.refreshState()
                }

                Button("Clear diagnostics log", role: .destructive) {
                    viewModel.clearDiagnosticsLog()
                }
            }

            Section("Diagnostics") {
                if viewModel.diagnosticsLog.isEmpty {
                    Text("No log entries")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(viewModel.diagnosticsLog.enumerated().reversed()), id: \.offset) { _, entry in
                        Text(entry)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private func runtimeRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct DarkCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [AppTheme.buttonPressedTop, AppTheme.buttonPressedBottom]
                                : [AppTheme.buttonTop, AppTheme.buttonBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.buttonStroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.18 : 0.32), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 4)
    }
}

private struct PressDurationButtonStyle: ButtonStyle {
    let accent: Color
    let compact: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: compact ? 16 : 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [AppTheme.buttonPressedTop, AppTheme.buttonPressedBottom]
                                : [AppTheme.buttonTop, AppTheme.buttonBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: compact ? 16 : 14, style: .continuous)
                            .stroke(configuration.isPressed ? accent.opacity(0.95) : AppTheme.buttonStroke, lineWidth: configuration.isPressed ? 1.6 : 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.18 : 0.34), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 5)
    }
}

private struct MicrophoneKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [AppTheme.buttonPressedTop, AppTheme.buttonPressedBottom]
                                : [AppTheme.buttonTop, AppTheme.buttonBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.buttonStroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct FunctionSpec: Identifiable {
    let command: String
    let title: String
    let subtitle: String?
    var isPower: Bool = false

    var id: String { command }
}

private struct KnobSpec: Identifiable {
    let label: String
    let leftCommand: String
    let pressCommand: String
    let rightCommand: String
    var dialMode: Bool = false

    var id: String { label }
}

private struct MicButtonSpec: Identifiable {
    let command: String
    let label: String

    var id: String { command }
}

private enum AppTheme {
    static let orangeBright = Color(hex: 0xE9752B)
    static let orangeDark = Color(hex: 0xD75A20)
    static let orangeBottom = Color(hex: 0xC94C18)
    static let brandOrange = Color(hex: 0xD54316)
    static let lcdText = Color(hex: 0x24211D)
    static let rx = Color(hex: 0x35D65A)
    static let rxDark = Color(hex: 0x26B943)
    static let tx = Color(hex: 0xFF2438)
    static let txDark = Color(hex: 0xD30018)
    static let micTop = Color(hex: 0x2A2A2A)
    static let micBottom = Color(hex: 0x080808)
    static let radioStroke = Color(hex: 0x333333)
    static let sectionStroke = Color.white.opacity(0.08)
    static let buttonStroke = Color.white.opacity(0.10)
    static let buttonSubtitle = Color.white.opacity(0.72)
    static let labelPrimary = Color.white.opacity(0.92)
    static let labelSecondary = Color.white.opacity(0.56)
    static let tagFill = Color.black.opacity(0.72)
    static let footerFill = Color.black.opacity(0.62)
    static let footerStroke = Color(hex: 0x2B2B2B)
    static let menuSelectedFill = Color(hex: 0x2B241E)
    static let menuRowFill = Color.black.opacity(0.18)
    static let valueBadgeFill = Color(hex: 0x2B241E)
    static let lampOff = Color(hex: 0x2B241E)
    static let lampOffDark = Color(hex: 0x221D18)
    static let sideCardStroke = Color(hex: 0x5E321A, opacity: 0.38)
    static let sideCardFill = Color.white.opacity(0.04)
    static let sideCardFillActive = Color.white.opacity(0.14)
    static let sideCardFillInactive = Color.black.opacity(0.12)
    static let knobCardFill = Color.black.opacity(0.20)
    static let sectionFill = LinearGradient(colors: [Color(hex: 0x1A1A1A), Color(hex: 0x0D0D0D), Color(hex: 0x050505)], startPoint: .top, endPoint: .bottom)
    static let radioBody = LinearGradient(colors: [Color(hex: 0x1A1A1A), Color(hex: 0x0D0D0D), Color(hex: 0x050505)], startPoint: .top, endPoint: .bottom)
    static let lcdFill = LinearGradient(colors: [orangeBright, orangeDark, orangeBottom], startPoint: .top, endPoint: .bottom)
    static let lcdFrameStroke = Color(hex: 0x34190B, opacity: 0.36)
    static let buttonTop = Color(hex: 0x2A2A2A)
    static let buttonBottom = Color(hex: 0x080808)
    static let buttonPressedTop = Color(hex: 0x1B1B1B)
    static let buttonPressedBottom = Color(hex: 0x050505)

    static let screenBackground = RadialGradient(
        colors: [Color(hex: 0x333333), Color(hex: 0x171717), Color(hex: 0x050505)],
        center: .top,
        startRadius: 20,
        endRadius: 680
    )
}

private extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0,
            opacity: opacity
        )
    }
}
