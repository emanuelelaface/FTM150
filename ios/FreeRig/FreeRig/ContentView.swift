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
            Text("DUAL BAND TRANSCEIVER Free RIG")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.brandOrange)
                .tracking(2.4)

            normalDisplaySurface(includeFooter: !menuPresentationActive && hasFooterContent)
                .opacity(menuPresentationActive ? 0 : 1)
                .allowsHitTesting(!menuPresentationActive)
                .overlay(alignment: .top) {
                if menuPresentationActive {
                    MenuFocusedRadioDisplay(
                        state: state,
                        enabled: enabled,
                        leftKnob: leftKnobs[1],
                        rightKnob: rightKnobs[1],
                        viewModel: viewModel
                    )
                }
                }
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

    private var menuPresentationActive: Bool {
        hasFooterContent
    }

    private var displayContentVisible: Bool {
        state?.radioPowered == true && state?.poweringOn != true
    }

    private var powerOverlayText: String? {
        if state?.poweringOn == true {
            return "POWERING ON"
        }
        if state?.radioPowered == false {
            return "POWER OFF"
        }
        return nil
    }

    @ViewBuilder
    private func normalDisplaySurface(includeFooter: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(displayContentVisible ? AnyShapeStyle(AppTheme.lcdFill) : AnyShapeStyle(AppTheme.lcdOffFill))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(displayContentVisible ? AppTheme.lcdFrameStroke : AppTheme.lcdOffFrameStroke, lineWidth: 2)
                )

            VStack(spacing: 10) {
                RadioSideDisplayCard(side: state?.left, fallbackSide: "L")
                InlineKnobStrip(specs: leftKnobs, enabled: enabled, viewModel: viewModel)
                RadioSideDisplayCard(side: state?.right, fallbackSide: "R")
                InlineKnobStrip(specs: rightKnobs, enabled: enabled, viewModel: viewModel)
                if includeFooter {
                    DisplayFooterPanel(state: state)
                }
            }
            .padding(12)
            .opacity(displayContentVisible ? 1 : 0)

            if let powerOverlayText {
                PowerStateOverlayLabel(text: powerOverlayText)
            }
        }
    }
}

private struct MenuFocusedRadioDisplay: View {
    let state: RadioState?
    let enabled: Bool
    let leftKnob: KnobSpec
    let rightKnob: KnobSpec
    @ObservedObject var viewModel: RadioViewModel

    private var activeMenu: RadioMenuState? {
        guard let menu = state?.menu, menu.visible else { return nil }
        return menu
    }

    private var displayContentVisible: Bool {
        state?.radioPowered == true && state?.poweringOn != true
    }

    private var displayHeight: CGFloat {
        activeMenu?.isMemoryMenu == true ? 312 : 236
    }

    private var memoryMenuExpanded: Bool {
        activeMenu?.isMemoryMenu == true
    }

    private var stackSpacing: CGFloat {
        activeMenu?.isMemoryMenu == true ? 8 : 14
    }

    private var powerOverlayText: String? {
        if state?.poweringOn == true {
            return "POWERING ON"
        }
        if state?.radioPowered == false {
            return "POWER OFF"
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: memoryMenuExpanded ? 0 : stackSpacing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(displayContentVisible ? AnyShapeStyle(AppTheme.lcdFill) : AnyShapeStyle(AppTheme.lcdOffFill))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(displayContentVisible ? AppTheme.lcdFrameStroke : AppTheme.lcdOffFrameStroke, lineWidth: 2)
                        )

                    Group {
                        if let overlay = state?.overlay, overlay.active {
                            DisplayOverlayScreenView(overlay: overlay)
                                .padding(.top, 12)
                                .padding(.horizontal, 12)
                                .padding(.bottom, memoryMenuExpanded ? 54 : 12)
                        } else if let menu = state?.menu, menu.visible {
                            DisplayMenuScreenView(menu: menu)
                                .padding(.top, 12)
                                .padding(.horizontal, 12)
                                .padding(.bottom, memoryMenuExpanded ? 54 : 12)
                        } else {
                            Text("Menu")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(AppTheme.lcdText.opacity(0.8))
                        }
                    }
                    .opacity(displayContentVisible ? 1 : 0)

                    if memoryMenuExpanded {
                        knobControls
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }

                    if let powerOverlayText {
                        PowerStateOverlayLabel(text: powerOverlayText)
                    }
                }
                .frame(height: memoryMenuExpanded ? geometry.size.height : displayHeight)
                .clipped()

                if !memoryMenuExpanded {
                    knobControls
                        .padding(.horizontal, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var knobControls: some View {
        HStack(spacing: 0) {
            InlineKnobControl(spec: leftKnob, enabled: enabled, viewModel: viewModel)
            Spacer(minLength: 0)
            InlineKnobControl(spec: rightKnob, enabled: enabled, viewModel: viewModel)
        }
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
        normalizedTag(side?.shift) ?? inferredShift(from: side?.modeRaw)
    }

    private var tone: String? {
        normalizedTag(side?.tone)
    }

    private var memoryLine: String {
        let memNo = side?.memNo.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = side?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let parts = [memNo, name].filter { !$0.isEmpty }
        return parts.isEmpty ? " " : parts.joined(separator: " · ")
    }

    private var lowerState: RadioLowerState? {
        side?.lower
    }

    private var meterLabel: String {
        compact(lowerState?.label) ?? "S"
    }

    private var displayMode: String {
        normalizedMode(side?.mode) ?? normalizedMode(side?.modeRaw) ?? "FM"
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
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .tracking(-1.1)
                    .foregroundStyle(AppTheme.lcdText)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(memoryLine)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.lcdText.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            HStack(spacing: 10) {
                LCDStatusBadge(text: meterLabel, minWidth: 58)

                MeterBar(activeSegments: meterSegments(lowerState), accent: AppTheme.lcdText)

                LCDStatusBadge(text: displayMode, minWidth: 50)
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

    private func normalizedMode(_ raw: String?) -> String? {
        let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        guard !text.isEmpty else { return nil }
        if text.contains("AM") { return "AM" }
        if text.contains("FM") { return "FM" }
        return nil
    }

    private func inferredShift(from raw: String?) -> String? {
        let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        guard !text.isEmpty else { return nil }
        if text.contains("+/-") { return "+/-" }
        if text.contains("+-") { return "+/-" }
        if text == "+" || text.hasSuffix("+") || text.contains(" +") { return "+" }
        if text == "-" || text.hasSuffix("-") || text.contains(" -") { return "-" }
        return nil
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

private struct DisplayOverlayScreenView: View {
    let overlay: RadioOverlayState

    var body: some View {
        VStack(spacing: 14) {
            if let title = firstNonEmpty([overlay.title, overlay.kind == "text" ? nil : overlay.kind]) {
                Text(title.uppercased())
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText.opacity(0.88))
                    .tracking(1.1)
            }

            Spacer(minLength: 0)

            if let message = firstNonEmpty([overlay.message, overlay.text]) {
                Text(message)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.55)
            }

            if let options = overlay.options, !options.isEmpty {
                HStack(spacing: 10) {
                    ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                        Text(option.text)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(option.selected ? AppTheme.orangeBright : AppTheme.lcdText.opacity(0.82))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(option.selected ? AppTheme.tagFill : Color.black.opacity(0.10))
                            )
                    }
                }
            }

            Spacer(minLength: 0)
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

private struct DisplayMenuScreenView: View {
    let menu: RadioMenuState

    private var hasActiveKeypad: Bool {
        if let type = compact(menu.type), type != "quick" {
            return false
        }
        let hasCells = (menu.cells ?? []).contains { compact($0.text) != nil }
        return hasCells && (
            menu.type == "quick" ||
                menu.valueSelected == true ||
                menu.editing == true ||
                menu.selectedIndex != nil ||
                menu.footerSelected == true
        )
    }

    var body: some View {
        Group {
            if hasActiveKeypad {
                QuickMenuScreenView(menu: menu)
            } else {
                switch menu.type {
                case "pmg":
                    PMGMenuScreenView(menu: menu)
                case "scope":
                    ScopeMenuScreenView(menu: menu)
                case "memory_list":
                    MemoryListMenuScreenView(menu: menu)
                case "memory_select":
                    MemorySelectMenuScreenView(menu: menu)
                case "memory_edit":
                    MemoryEditMenuScreenView(menu: menu)
                case "memory_freq_keypad":
                    MemoryFreqKeypadScreenView(menu: menu)
                case "memory_tag_keypad":
                    MemoryTagKeypadScreenView(menu: menu)
                case "menu1_keypad":
                    Menu1KeypadScreenView(menu: menu)
                case "dtmf_edit":
                    DTMFEditMenuScreenView(menu: menu)
                case "quick":
                    QuickMenuScreenView(menu: menu)
                case "full":
                    FullMenuScreenView(menu: menu)
                case "submenu":
                    SubmenuMenuScreenView(menu: menu)
                default:
                    GenericMenuScreenView(menu: menu)
                }
            }
        }
    }
}

private struct MemoryListMenuScreenView: View {
    let menu: RadioMenuState

    private var rows: [VisibleMemoryRow] {
        visibleMemoryRows(menu.rows ?? [], selectedRow: menu.selectedRow)
    }

    var body: some View {
        VStack(spacing: 6) {
            MemoryMenuHeader(parentNum: menu.parentNum, title: compact(menu.title) ?? "MEMORY LIST")
            ForEach(rows) { item in
                MemoryRowView(
                    num: compact(item.row.num) ?? "",
                    primary: compact(item.row.freq) ?? compact(item.row.value) ?? "",
                    secondary: compact(item.row.name) ?? compact(item.row.text) ?? "",
                    selected: item.index == (menu.selectedRow ?? 0)
                )
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct MemorySelectMenuScreenView: View {
    let menu: RadioMenuState

    private var rows: [VisibleMemoryRow] {
        visibleMemoryRows(menu.memoryRows ?? [], selectedRow: menu.selectedMemoryRow, pageSize: 3)
    }

    private var actions: [VisibleMemoryRow] {
        visibleMemoryRows(menu.rows ?? [], selectedRow: menu.selectedRow, pageSize: 5)
    }

    var body: some View {
        VStack(spacing: 6) {
            MemoryMenuHeader(parentNum: menu.parentNum, title: "MEMORY LIST")

            if !rows.isEmpty {
                ForEach(rows) { item in
                    MemoryRowView(
                        num: compact(item.row.num) ?? "",
                        primary: compact(item.row.freq) ?? compact(item.row.value) ?? "",
                        secondary: compact(item.row.name) ?? compact(item.row.text) ?? "",
                        selected: item.index == (menu.selectedMemoryRow ?? 0)
                    )
                }
            }

            if !actions.isEmpty {
                VStack(spacing: 4) {
                    if let memorySummary = memorySummary {
                        Text(memorySummary)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.lcdText)
                            .lineLimit(1)
                    }

                    ForEach(actions) { item in
                        HStack(spacing: 8) {
                            Text(compact(item.row.label) ?? compact(item.row.text) ?? "")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            Text("›")
                                .frame(width: 12, alignment: .trailing)
                        }
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.lcdText)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 0, style: .continuous)
                                .fill(item.index == (menu.selectedRow ?? 0) ? Color.black.opacity(0.24) : Color.black.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 0, style: .continuous)
                                .stroke(AppTheme.menuBorder.opacity(0.82), lineWidth: 2)
                        )
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var memorySummary: String? {
        let num = menu.memoryNum.map { String(format: "%03d", $0) } ?? ""
        let parts = [num, compact(menu.memoryFreq) ?? "", compact(menu.memoryName) ?? ""].filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

private struct MemoryEditMenuScreenView: View {
    let menu: RadioMenuState

    private var rows: [VisibleMemoryRow] {
        visibleMemoryRows(menu.rows ?? [], selectedRow: menu.selectedRow)
    }

    var body: some View {
        VStack(spacing: 6) {
            MemoryMenuHeader(parentNum: menu.parentNum, title: compact(menu.title) ?? "MEMORY EDIT")
            ForEach(rows) { item in
                HStack(spacing: 10) {
                    Text(compact(item.row.label) ?? compact(item.row.text) ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    Text(compact(item.row.value) ?? "")
                        .frame(maxWidth: 96, alignment: .trailing)
                        .lineLimit(1)
                    Text("›")
                        .frame(width: 12, alignment: .trailing)
                }
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.lcdText)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .fill((item.index == (menu.selectedRow ?? 0) || item.row.editing == true) ? Color.black.opacity(0.24) : Color.black.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .stroke(AppTheme.menuBorder.opacity(0.82), lineWidth: 2)
                )
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct MemoryFreqKeypadScreenView: View {
    let menu: RadioMenuState

    private var rows: [VisibleMemoryRow] {
        visibleMemoryRows(menu.rows ?? [], selectedRow: menu.selectedRow, pageSize: 4)
    }

    private var labels: [String] {
        let source = menu.keypad ?? ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "DEL"]
        return Array(source.prefix(11))
    }

    private var selectedKey: Int {
        Int(menu.selectedKey ?? "") ?? -1
    }

    private var inputCells: [RadioMenuCell] {
        if let cells = menu.inputCells, !cells.isEmpty {
            return cells
        }
        let chars = Array((menu.inputValue ?? menu.currentValue ?? "").map(String.init))
        return chars.enumerated().map { idx, text in
            RadioMenuCell(index: idx, text: text, cursor: idx == (menu.inputCursorPos ?? 0))
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            MemoryMenuHeader(parentNum: menu.parentNum, title: compact(menu.title) ?? "MEMORY")

            ForEach(rows) { item in
                MemoryEditRowView(
                    label: compact(item.row.label) ?? compact(item.row.text) ?? "",
                    value: compact(item.row.value) ?? "",
                    selected: item.index == (menu.selectedRow ?? 0) || item.row.editing == true
                )
            }

            VStack(spacing: 7) {
                Text(compact(menu.targetLabel) ?? "FREQ")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                HStack(spacing: 2) {
                    ForEach(Array(inputCells.enumerated()), id: \.offset) { _, cell in
                        MemoryFreqValueCell(
                            text: compact(cell.text) ?? "",
                            cursor: cell.cursor == true
                        )
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 42)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .stroke(AppTheme.menuBorder, lineWidth: 3)
                )

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 5), spacing: 7) {
                    ForEach(Array(labels.prefix(5).enumerated()), id: \.offset) { idx, label in
                        MemoryPadKeyButton(label: label, selected: idx == selectedKey)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 5), spacing: 7) {
                    ForEach(Array(labels.dropFirst(5).prefix(5).enumerated()), id: \.offset) { idx, label in
                        MemoryPadKeyButton(label: label, selected: idx + 5 == selectedKey)
                    }
                }

                HStack(spacing: 7) {
                    ForEach(0 ..< 4, id: \.self) { _ in
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 34)
                    }
                    MemoryPadKeyButton(label: labels.count > 10 ? labels[10] : "DEL", selected: selectedKey == 10)
                }
            }
            .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct MemoryTagKeypadScreenView: View {
    let menu: RadioMenuState

    private var rows: [VisibleMemoryRow] {
        visibleMemoryRows(menu.rows ?? [], selectedRow: menu.selectedRow, pageSize: 4)
    }

    private var labels: [String] {
        let fallbackAlphabetTop = Array("ABCDEFGHIJKLM").map { String($0) }
        let fallbackAlphabetBottom = Array("NOPQRSTUVWXYZ").map { String($0) }
        let fallback = fallbackAlphabetTop + fallbackAlphabetBottom + ["abc", "123", "#%^", "<-", "SPACE", "->", "DEL"]
        let source = menu.keypad ?? fallback
        return Array(source.prefix(33))
    }

    private var selectedKey: Int {
        Int(menu.selectedKey ?? "") ?? -1
    }

    private var inputCells: [RadioMenuCell] {
        if let cells = menu.inputCells, !cells.isEmpty {
            return cells
        }
        let chars = Array((menu.inputValue ?? menu.currentValue ?? "").map(String.init))
        return chars.enumerated().map { idx, text in
            RadioMenuCell(index: idx, text: text, cursor: idx == (menu.inputCursorPos ?? 0))
        }
    }

    private var keypadRows: [RadioMenuKeypadRow] {
        if let rows = menu.keypadRows, !rows.isEmpty {
            return rows
        }
        return [
            RadioMenuKeypadRow(cls: "row13", idx: Array(0 ... 12)),
            RadioMenuKeypadRow(cls: "row13", idx: Array(13 ... 25)),
            RadioMenuKeypadRow(cls: "row7", idx: Array(26 ... 32)),
        ]
    }

    var body: some View {
        VStack(spacing: 6) {
            MemoryMenuHeader(parentNum: menu.parentNum, title: compact(menu.title) ?? "MEMORY")

            ForEach(rows) { item in
                MemoryEditRowView(
                    label: compact(item.row.label) ?? compact(item.row.text) ?? "",
                    value: compact(item.row.value) ?? "",
                    selected: item.index == (menu.selectedRow ?? 0) || item.row.editing == true
                )
            }

            VStack(spacing: 7) {
                Text(compact(menu.targetLabel) ?? "TAG")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                HStack(spacing: 2) {
                    ForEach(Array(inputCells.enumerated()), id: \.offset) { _, cell in
                        MemoryTagValueCell(
                            text: compact(cell.text) ?? "",
                            cursor: cell.cursor == true
                        )
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 40)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .stroke(AppTheme.menuBorder, lineWidth: 3)
                )

                VStack(spacing: 7) {
                    ForEach(Array(keypadRows.enumerated()), id: \.offset) { _, row in
                        MemoryTagKeyRow(
                            labels: labels,
                            selectedKey: selectedKey,
                            row: row
                        )
                    }
                }
            }
            .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct PMGMenuScreenView: View {
    let menu: RadioMenuState

    private var channels: [RadioPMGChannel] {
        var values = menu.channels ?? []
        while values.count < 5 {
            values.append(
                RadioPMGChannel(
                    index: values.count + 1,
                    label: "P\(values.count + 1)",
                    registered: false,
                    bar: 0,
                    shadow: 0,
                    recent: false,
                    receiving: false
                )
            )
        }
        return Array(values.prefix(5))
    }

    private var selected: Int {
        let value = menu.selected ?? 1
        return max(1, min(5, value))
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                HStack(spacing: 4) {
                    LCDMenuBadge(text: "PMG")
                    if let source = compact(menu.source) {
                        LCDMenuBadge(text: source)
                    }
                    if let mode = compact(menu.rxMode) {
                        LCDMenuBadge(text: mode)
                    }
                    if let shift = compact(menu.shift) {
                        LCDMenuBadge(text: shift)
                    }
                    if let tone = compact(menu.tone) {
                        LCDMenuBadge(text: tone)
                    }
                }

                Spacer(minLength: 8)

                LCDLargeFrequencyView(freq: menu.freq ?? "---.---", size: 42)
            }

            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(channels) { channel in
                        PMGChannelColumn(
                            channel: channel,
                            selected: channel.index == selected,
                            autoMode: menu.auto == true
                        )
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }
}

private struct ScopeMenuScreenView: View {
    let menu: RadioMenuState

    private var bars: [Int] {
        let values = menu.bars ?? []
        if !values.isEmpty { return values }
        let count = max(1, menu.channelCount ?? 23)
        return Array(repeating: 0, count: count)
    }

    private var markerIndex: Int {
        max(0, min(bars.count - 1, menu.markerIndex ?? bars.count / 2))
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                HStack(spacing: 4) {
                    if let source = compact(menu.source) {
                        LCDMenuBadge(text: source)
                    }
                    if let mode = compact(menu.mode) {
                        LCDMenuBadge(text: mode)
                    }
                    if let shift = compact(menu.shift) {
                        LCDMenuBadge(text: shift)
                    }
                    if let tone = compact(menu.tone) {
                        LCDMenuBadge(text: tone)
                    }
                    if let interval = compact(menu.interval) {
                        LCDMenuBadge(text: interval)
                    }
                }

                Spacer(minLength: 8)

                LCDLargeFrequencyView(freq: menu.freq ?? "---.---", size: 42)
            }

            VStack(spacing: 3) {
                GeometryReader { geometry in
                    let count = max(1, bars.count)
                    let markerX = ((CGFloat(markerIndex) + 0.5) / CGFloat(count)) * geometry.size.width

                    ZStack(alignment: .bottomLeading) {
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(Array(bars.enumerated()), id: \.offset) { idx, raw in
                                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                    .fill(scopeBarColor(index: idx, raw: raw))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: max(2, min(110, CGFloat(raw) * 10)))
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.horizontal, 6)
                        .padding(.top, 12)

                        Rectangle()
                            .fill(AppTheme.menuBorder.opacity(0.92))
                            .frame(width: 3)
                            .padding(.top, 6)
                            .padding(.bottom, 8)
                            .offset(x: markerX - 1.5)

                        Triangle()
                            .fill(AppTheme.menuBorder.opacity(0.96))
                            .frame(width: 12, height: 10)
                            .offset(x: markerX - 6, y: -geometry.size.height + 2)
                    }
                }
                .frame(height: 108)

                HStack(spacing: 2) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { idx, _ in
                        Circle()
                            .fill(idx == markerIndex ? AppTheme.menuBorder.opacity(0.98) : AppTheme.menuBorder.opacity(0.62))
                            .frame(width: idx == markerIndex ? 6 : 4, height: idx == markerIndex ? 6 : 4)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 6)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
            .background(
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(AppTheme.menuBorder.opacity(0.96))
                        .frame(height: 4)
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }

    private func scopeBarColor(index: Int, raw: Int) -> Color {
        if index == markerIndex {
            return AppTheme.menuBorder.opacity(0.98)
        }
        if raw >= 7 {
            return AppTheme.menuBorder.opacity(0.94)
        }
        return AppTheme.menuBorder.opacity(0.84)
    }
}

private struct FullMenuScreenView: View {
    let menu: RadioMenuState

    private var rows: [RadioMenuRow] {
        Array((menu.rows ?? []).prefix(3))
    }

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                let rowNumRaw = Int(row.num ?? "")
                let inert = menu.noActionItems?.contains(where: { $0 == rowNumRaw }) == true
                let selected = idx == (menu.selectedRow ?? 0)
                let editing = row.editing == true

                HStack(spacing: 0) {
                    Text(formattedMenuNum(row.num))
                        .frame(width: 60, alignment: .leading)
                    Text(row.text ?? row.label ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    Text(inert ? "" : "›")
                        .frame(width: 18, alignment: .trailing)
                }
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.lcdText)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .fill((selected || editing) ? Color.black.opacity(0.28) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .stroke(AppTheme.menuBorder, lineWidth: 3)
                )
                .opacity(inert ? 0.72 : 1)
            }

            Spacer(minLength: 0)

            if let value = compact(menu.value) {
                VStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: menu.valueSource == "unknown" ? 22 : 26, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.lcdText)
                        .multilineTextAlignment(.center)
                        .lineLimit(menu.valueSource == "unknown" ? 2 : 1)
                    if menu.valueSource == "unknown", let raw = compact(menu.rawValue) {
                        Text(raw)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.lcdText.opacity(0.74))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .fill((menu.valueSelected == true || menu.editing == true) ? Color.black.opacity(0.28) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .stroke(AppTheme.menuBorder, lineWidth: 3)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct SubmenuMenuScreenView: View {
    let menu: RadioMenuState

    private var rows: [RadioMenuRow] {
        Array((menu.rows ?? []).prefix(3))
    }

    private var readOnly: Bool {
        menu.readOnly == true
    }

    private var titleNum: String {
        guard let parentNum = menu.parentNum else { return "" }
        return String(format: "%02d", parentNum)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                Text(titleNum)
                    .frame(width: 60, alignment: .leading)
                Text(compact(menu.title) ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                Text("")
                    .frame(width: 18, alignment: .trailing)
            }
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.lcdText)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .stroke(AppTheme.menuBorder, lineWidth: 3)
            )
            .opacity(0.95)

            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                let isSelected = !readOnly && menu.selectedRow == idx
                let valueFocused = !readOnly && menu.editing == true && ((row.editing == true) || isSelected)
                let keyFocused = isSelected && !valueFocused

                SubmenuMenuRowView(
                    keyText: compact(row.num) ?? "",
                    valueText: compact(row.text) ?? compact(row.value) ?? "",
                    keyFocused: keyFocused,
                    valueFocused: valueFocused
                )
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct Menu1KeypadScreenView: View {
    let menu: RadioMenuState

    private var labels: [String] {
        let source = menu.keypad ?? ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "MEM CH", "MEM LIST", "DEL"]
        return Array(source.prefix(13))
    }

    private var selectedKey: Int {
        max(-1, Int(menu.selectedKey ?? "") ?? -1)
    }

    private var titleText: String {
        compact(menu.modeTitle) ?? compact(menu.title) ?? "FREQUENCY"
    }

    private var mode: String {
        compact(menu.mode) ?? "frequency"
    }

    private var maxLen: Int {
        max(1, menu.inputMaxLen ?? (mode == "memory" ? 3 : 8))
    }

    private var inputDigits: [String] {
        let value = (menu.inputValue ?? "").filter(\.isNumber)
        return Array(value.prefix(maxLen)).map(String.init)
    }

    private var cursorIndex: Int {
        let fallback = min(inputDigits.count, max(0, maxLen - 1))
        return max(0, min(menu.inputCursorPos ?? fallback, maxLen - 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleText)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.lcdText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 2) {
                ForEach(Array((0 ..< maxLen).enumerated()), id: \.offset) { _, idx in
                    Menu1InputCell(
                        text: idx < inputDigits.count ? inputDigits[idx] : "",
                        cursor: idx == cursorIndex && inputDigits.count < maxLen,
                        groupAfter: mode != "memory" && idx == 2
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .stroke(AppTheme.menuBorder, lineWidth: 3)
            )

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(Array(labels.prefix(10).enumerated()), id: \.offset) { idx, label in
                    Menu1KeyButton(label: label, selected: idx == selectedKey)
                }
            }

            GeometryReader { proxy in
                let totalWidth = max(proxy.size.width - 16, 0)
                let unit = totalWidth / 4.2
                let widths = [unit * 1.45, unit * 1.7, unit * 1.05]

                HStack(spacing: 8) {
                    ForEach(Array(labels.dropFirst(10).prefix(3).enumerated()), id: \.offset) { offset, label in
                        Menu1KeyButton(label: label, selected: selectedKey == offset + 10, compactStyle: true)
                            .frame(width: widths[offset])
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(height: 38)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct DTMFEditMenuScreenView: View {
    let menu: RadioMenuState

    private var entryCells: [String] {
        var values = (menu.cells ?? []).map { compact($0.text) ?? "" }
        if values.count > 16 {
            values = Array(values.prefix(16))
        }
        while values.count < 16 {
            values.append("")
        }
        return values
    }

    private var selectedKey: Int {
        if let selected = Int(menu.selectedKey ?? "") {
            return selected
        }
        return menu.cursorPos ?? -1
    }

    private var editCursorPos: Int {
        menu.editCursorPos ?? -1
    }

    private var labels: [String] {
        let source = menu.keypad ?? ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "A", "B", "C", "D", "*", "#", "◀", "SP", "▶", "DEL"]
        var values = Array(source.prefix(20))
        while values.count < 20 {
            values.append("")
        }
        return values
    }

    var body: some View {
        VStack(spacing: 9) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 16), spacing: 2) {
                ForEach(Array(entryCells.enumerated()), id: \.offset) { idx, text in
                    DTMFEntryCell(
                        text: text,
                        cursor: idx == editCursorPos,
                        cursorAfter: editCursorPos >= 16 && idx == 15
                    )
                }
            }
            .padding(.horizontal, 10)

            VStack(spacing: 5) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
                    ForEach(Array(labels.prefix(5).enumerated()), id: \.offset) { idx, label in
                        DTMFKeyButton(label: label, selected: idx == selectedKey)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
                    ForEach(Array(labels.dropFirst(5).prefix(5).enumerated()), id: \.offset) { idx, label in
                        DTMFKeyButton(label: label, selected: idx + 5 == selectedKey)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                    ForEach(Array(labels.dropFirst(10).prefix(10).enumerated()), id: \.offset) { idx, label in
                        DTMFKeyButton(label: label, selected: idx + 10 == selectedKey, tool: idx + 10 >= 16)
                    }
                }
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 0)
        }
        .padding(.top, 5)
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct QuickMenuScreenView: View {
    let menu: RadioMenuState

    private var cells: [RadioMenuCell] {
        let source = Array((menu.cells ?? []).prefix(targetCellCount))
        var values = source
        while values.count < targetCellCount {
            values.append(RadioMenuCell(index: values.count, text: ""))
        }
        return values
    }

    private var targetCellCount: Int {
        let count = menu.cells?.count ?? 0
        return count > 9 ? 12 : max(9, count)
    }

    private var columnCount: Int {
        targetCellCount > 9 ? 4 : 3
    }

    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columnCount), spacing: 4) {
                ForEach(Array(cells.enumerated()), id: \.offset) { idx, cell in
                    let text = compact(cell.text) ?? ""
                    let isSelected = idx == (menu.selectedIndex ?? 0) && menu.footerSelected != true
                    Text(text)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.lcdText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 0, style: .continuous)
                                .fill(isSelected ? Color.black.opacity(0.28) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 0, style: .continuous)
                                .stroke(AppTheme.menuBorder, lineWidth: 3)
                        )
                        .opacity(text.isEmpty ? 0.44 : 1)
                }
            }

            if let footer = compact(menu.footer) {
                Text(footer)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(menu.footerSelected == true ? Color.black.opacity(0.28) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(menu.footerSelected == true ? AppTheme.orangeBright.opacity(0.9) : AppTheme.menuBorder, lineWidth: menu.footerSelected == true ? 2 : 1.5)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct GenericMenuScreenView: View {
    let menu: RadioMenuState

    private var selectedIndex: Int? {
        let rows = menu.rows ?? []
        return rows.firstIndex(where: isRowSelected)
    }

    private var visibleRows: [VisibleMenuRow] {
        visibleMenuRows(menu.rows ?? [], selectedRow: selectedIndex, pageSize: 7)
    }

    private var visibleCells: [RadioMenuCell] {
        Array((menu.cells ?? []).prefix(12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let channels = menu.channels, !channels.isEmpty {
                VStack(spacing: 8) {
                    ForEach(channels) { channel in
                        HStack(spacing: 10) {
                            Text(channel.label)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(AppTheme.lcdText)
                                .frame(width: 46, alignment: .leading)

                            MeterBar(activeSegments: max(0, min(16, channel.bar ?? 0)), accent: AppTheme.lcdText)

                            if channel.receiving == true {
                                Text("RX")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(AppTheme.rxDark)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.black.opacity(channel.recent == true ? 0.20 : 0.10))
                        )
                    }
                }
            } else if !visibleRows.isEmpty {
                VStack(spacing: 6) {
                    ForEach(visibleRows) { item in
                        let row = item.row
                        let selected = isRowSelected(row)
                        let editing = row.editing == true
                        let primary = rowPrimaryText(row)
                        let secondary = rowSecondaryText(row)
                        let trailingValue = menuRowTrailingValue(row, primaryText: primary, secondaryText: secondary)
                        GenericMenuRowView(
                            rowNum: compact(row.num) ?? "",
                            primary: primary,
                            secondary: secondary,
                            trailingValue: trailingValue,
                            selected: selected,
                            editing: editing
                        )
                    }
                }
            } else if !visibleCells.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(visibleCells) { cell in
                        Text(compact(cell.text) ?? "")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.lcdText)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.black.opacity(0.10))
                            )
                    }
                }
            } else if let value = compact(menu.value) {
                Spacer(minLength: 0)
                Text(value)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                Text("Menu active")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func isRowSelected(_ row: RadioMenuRow) -> Bool {
        if let rowIndex = row.row, rowIndex == menu.selectedRow { return true }
        if let selectedIndex = menu.selectedIndex, row.row == selectedIndex { return true }
        if let selectedNum = menu.selectedNum, row.num == String(selectedNum) { return true }
        return false
    }
}

private struct SubmenuMenuRowView: View {
    let keyText: String
    let valueText: String
    let keyFocused: Bool
    let valueFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(keyText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 8)
            .frame(width: 176, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .leading)
            .background(keyFocused ? Color.black.opacity(0.28) : Color.clear)

            HStack(spacing: 0) {
                Text(valueText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(valueFocused ? Color.black.opacity(0.28) : Color.clear)
        }
        .font(.system(size: 19, weight: .black, design: .rounded))
        .foregroundStyle(AppTheme.lcdText)
        .frame(maxWidth: .infinity, minHeight: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .stroke(AppTheme.menuBorder, lineWidth: 3)
        )
    }
}

private struct Menu1KeyButton: View {
    let label: String
    let selected: Bool
    var compactStyle: Bool = false

    var body: some View {
        Text(label)
            .font(.system(size: compactStyle ? 16 : 22, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.lcdText)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .fill(selected ? Color.black.opacity(0.30) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .stroke(AppTheme.menuBorder, lineWidth: 3)
            )
    }
}

private struct Menu1InputCell: View {
    let text: String
    let cursor: Bool
    let groupAfter: Bool

    var body: some View {
        Text(text.isEmpty ? " " : text)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundStyle(text.isEmpty ? AppTheme.lcdText.opacity(0.18) : AppTheme.lcdText)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(cursor ? Color.black.opacity(0.26) : Color.clear)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(cursor ? AppTheme.menuBorder.opacity(1) : AppTheme.menuBorder.opacity(0.72))
                    .frame(height: 3)
            }
            .overlay(alignment: .bottom) {
                if cursor {
                    Triangle()
                        .fill(AppTheme.menuBorder.opacity(0.9))
                        .frame(width: 10, height: 6)
                        .offset(y: 6)
                }
            }
            .overlay(alignment: .trailing) {
                if groupAfter {
                    Text(".")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.menuBorder.opacity(0.9))
                        .offset(x: 7, y: -1)
                }
            }
    }
}

private struct DTMFEntryCell: View {
    let text: String
    let cursor: Bool
    let cursorAfter: Bool

    var body: some View {
        Text(displayText)
            .font(.system(size: 25, weight: .black, design: .rounded))
            .foregroundStyle(text.isEmpty ? Color.clear.opacity(0.38) : AppTheme.lcdText)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(backgroundFill)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(cursor ? AppTheme.menuBorder.opacity(1) : AppTheme.menuBorder.opacity(0.72))
                    .frame(height: 3)
            }
            .overlay(alignment: .bottom) {
                if cursor {
                    Triangle()
                        .fill(AppTheme.menuBorder.opacity(0.9))
                        .frame(width: 10, height: 6)
                        .offset(y: 6)
                }
            }
            .overlay(alignment: .trailing) {
                if cursorAfter {
                    Rectangle()
                        .fill(AppTheme.menuBorder.opacity(0.9))
                        .frame(width: 4)
                        .padding(.vertical, 2)
                }
            }
    }

    private var displayText: String {
        text == " " ? "\u{00A0}" : (text.isEmpty ? " " : text)
    }

    private var backgroundFill: Color {
        if cursor {
            return Color.black.opacity(0.30)
        }
        if text == " " {
            return Color.black.opacity(0.12)
        }
        return .clear
    }
}

private struct DTMFKeyButton: View {
    let label: String
    let selected: Bool
    let tool: Bool

    init(label: String, selected: Bool, tool: Bool = false) {
        self.label = label
        self.selected = selected
        self.tool = tool
    }

    var body: some View {
        Text(label)
            .font(.system(size: tool ? 18 : 23, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.lcdText)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, minHeight: 33)
            .background(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .fill(selected ? Color.black.opacity(0.30) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .stroke(AppTheme.menuBorder, lineWidth: 3)
            )
    }
}

private struct MemoryEditRowView: View {
    let label: String
    let value: String
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text(value)
                .frame(maxWidth: 96, alignment: .trailing)
                .lineLimit(1)
            Text("›")
                .frame(width: 12, alignment: .trailing)
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(AppTheme.lcdText)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 32)
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(selected ? Color.black.opacity(0.24) : Color.black.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .stroke(AppTheme.menuBorder.opacity(0.82), lineWidth: 2)
        )
    }
}

private struct MemoryFreqValueCell: View {
    let text: String
    let cursor: Bool

    var body: some View {
        Text(displayText)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.lcdText)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(cursor ? Color.black.opacity(0.30) : Color.clear)
    }

    private var displayText: String {
        text.isEmpty || text == " " ? "\u{00A0}" : text
    }
}

private struct MemoryTagValueCell: View {
    let text: String
    let cursor: Bool

    var body: some View {
        Text(displayText)
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.lcdText)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(cursor ? Color.black.opacity(0.30) : Color.clear)
    }

    private var displayText: String {
        text.isEmpty || text == " " ? "\u{00A0}" : text
    }
}

private struct MemoryPadKeyButton: View {
    let label: String
    let selected: Bool
    var compact: Bool = false
    var blank: Bool = false

    var body: some View {
        Group {
            if blank {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 34)
            } else {
                Text(label)
                    .font(.system(size: compact ? 18 : 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.lcdText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .fill(selected ? Color.black.opacity(0.30) : Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .stroke(AppTheme.menuBorder, lineWidth: 3)
                    )
            }
        }
    }
}

private struct MemoryTagKeyRow: View {
    let labels: [String]
    let selectedKey: Int
    let row: RadioMenuKeypadRow

    private var indexes: [Int] {
        row.idx ?? []
    }

    private var columns: [GridItem] {
        switch row.cls {
        case "row13":
            return Array(repeating: GridItem(.flexible(), spacing: 5), count: 13)
        case "row12":
            return Array(repeating: GridItem(.flexible(), spacing: 5), count: 12)
        case "row11":
            return Array(repeating: GridItem(.flexible(), spacing: 5), count: 11)
        case "row10":
            return Array(repeating: GridItem(.flexible(), spacing: 5), count: 10)
        case "row7":
            return [
                GridItem(.flexible(minimum: 24), spacing: 5),
                GridItem(.flexible(minimum: 24), spacing: 5),
                GridItem(.flexible(minimum: 24), spacing: 5),
                GridItem(.flexible(minimum: 18), spacing: 5),
                GridItem(.flexible(minimum: 42), spacing: 5),
                GridItem(.flexible(minimum: 18), spacing: 5),
                GridItem(.flexible(minimum: 24), spacing: 5),
            ]
        case "row6":
            return Array(repeating: GridItem(.flexible(), spacing: 5), count: 6)
        default:
            return Array(repeating: GridItem(.flexible(), spacing: 5), count: max(indexes.count, 1))
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(indexes, id: \.self) { idx in
                let label = idx < labels.count ? labels[idx] : ""
                MemoryPadKeyButton(
                    label: label,
                    selected: idx == selectedKey,
                    compact: true,
                    blank: label.isEmpty
                )
            }
        }
    }
}

private struct FullMenuRowView: View {
    let rowNum: String
    let primary: String
    let trailingValue: String?
    let selected: Bool
    let editing: Bool
    let inert: Bool

    private var leftActive: Bool {
        selected && (!editing || trailingValue == nil)
    }

    private var rightActive: Bool {
        editing && trailingValue != nil
    }

    private var rowNumWidth: CGFloat {
        rowNum.isEmpty ? 0 : 16
    }

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(rowNum)
                    .frame(width: rowNumWidth, alignment: .leading)
                    .minimumScaleFactor(0.6)

                Text(primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(inert ? "" : "›")
                    .frame(width: 12, alignment: .trailing)
            }
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(leftActive ? AppTheme.orangeBright : .white)
            .padding(.leading, 8)
            .padding(.trailing, 5)
            .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(leftActive ? AppTheme.menuSelectedFill : AppTheme.menuRowFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.menuBorder, lineWidth: 1.5)
            )

            if let trailingValue {
                MenuRowValueBadge(text: trailingValue, active: rightActive)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 42)
        .opacity(inert ? 0.72 : 1)
    }
}

private struct GenericMenuRowView: View {
    let rowNum: String
    let primary: String
    let secondary: String?
    let trailingValue: String?
    let selected: Bool
    let editing: Bool

    private var leftActive: Bool {
        selected && (!editing || trailingValue == nil)
    }

    private var rightActive: Bool {
        editing && trailingValue != nil
    }

    private var rowNumWidth: CGFloat {
        if trailingValue != nil || rowNum.isEmpty {
            return 0
        }
        return 14
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(rowNum)
                    .frame(width: rowNumWidth, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let secondary {
                        Text(secondary)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.lcdText.opacity(leftActive ? 0.74 : 0.58))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            }
            .font(.system(size: 19, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.lcdText)
            .padding(.leading, 8)
            .padding(.trailing, 4)
            .frame(maxWidth: .infinity, minHeight: secondary == nil ? 40 : 44, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(leftActive ? Color.black.opacity(0.28) : AppTheme.menuRowFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.menuBorder, lineWidth: leftActive ? 3 : 1.2)
            )

            if let trailingValue {
                MenuRowValueBadge(text: trailingValue, active: rightActive)
            }
        }
        .frame(maxWidth: .infinity, minHeight: secondary == nil ? 40 : 44)
    }
}

private struct MenuRowValueBadge: View {
    let text: String
    let active: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 19, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.lcdText)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .frame(minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(active ? Color.black.opacity(0.28) : AppTheme.menuRowFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(AppTheme.menuBorder, lineWidth: active ? 3 : 1.2)
            )
    }
}

private struct LCDMenuBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.lcdText)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(AppTheme.menuBorder.opacity(0.82), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.black.opacity(0.08))
                    )
            )
    }
}

private struct LCDStatusBadge: View {
    let text: String
    var minWidth: CGFloat = 0

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.lcdText)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 10)
            .frame(minWidth: minWidth, minHeight: 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.menuBorder.opacity(0.56), lineWidth: 1.5)
            )
    }
}

private struct PowerStateOverlayLabel: View {
    let text: String

    var body: some View {
        ZStack {
            Color(red: 160 / 255, green: 160 / 255, blue: 160 / 255, opacity: 0.28)
            Text(text)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(AppTheme.lcdOffText)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 12)
        }
    }
}

private struct LCDLargeFrequencyView: View {
    let freq: String
    let size: CGFloat

    private var components: (String, String) {
        let trimmed = freq.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count == 2 {
            return ("\(parts[0]).", String(parts[1]))
        }
        return (trimmed, "")
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(components.0.isEmpty ? "---." : components.0)
                .font(.system(size: size, weight: .black, design: .rounded))
                .tracking(-2.4)
            if !components.1.isEmpty {
                Text(components.1)
                    .font(.system(size: size * 0.48, weight: .black, design: .rounded))
                    .baselineOffset(size * 0.18)
                    .tracking(-0.8)
            }
        }
        .foregroundStyle(AppTheme.lcdText)
        .lineLimit(1)
        .minimumScaleFactor(0.55)
    }
}

private struct MemoryMenuHeader: View {
    let parentNum: Int?
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(parentNum.map { String(format: "%02d", $0) } ?? "")
                .frame(width: 34, alignment: .leading)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
        .font(.system(size: 14, weight: .black, design: .rounded))
        .foregroundStyle(AppTheme.lcdText)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 30)
        .background(Color.black.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .stroke(AppTheme.menuBorder.opacity(0.82), lineWidth: 2)
        )
    }
}

private struct MemoryRowView: View {
    let num: String
    let primary: String
    let secondary: String
    let selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(num)
                .frame(width: 42, alignment: .leading)
            Text(primary)
                .frame(width: 78, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text("›")
                .frame(width: 12, alignment: .trailing)
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(AppTheme.lcdText)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(selected ? Color.black.opacity(0.24) : Color.black.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .stroke(AppTheme.menuBorder.opacity(0.82), lineWidth: 2)
        )
    }
}

private struct PMGChannelColumn: View {
    let channel: RadioPMGChannel
    let selected: Bool
    let autoMode: Bool

    private var mainHeight: CGFloat {
        CGFloat(max(0, min(10, channel.bar ?? 0))) * 8.8
    }

    private var shadowHeight: CGFloat {
        CGFloat(max(0, min(10, channel.shadow ?? 0))) * 8.8
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .bottom) {
                if shadowHeight > 0 {
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(AppTheme.menuBorder.opacity(0.34))
                        .frame(width: 18, height: shadowHeight)
                }
                if mainHeight > 0 {
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(barColor)
                        .frame(width: 14, height: mainHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            Rectangle()
                .fill(AppTheme.menuBorder.opacity(0.92))
                .frame(height: autoMode ? 6 : 3)

            Text(channel.label)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.lcdText)
                .frame(maxWidth: .infinity, minHeight: 20)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(selected ? AppTheme.menuBorder.opacity(0.96) : Color.clear, lineWidth: 2)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(channel.registered ? 1 : 0.42)
    }

    private var barColor: Color {
        if channel.receiving == true {
            return AppTheme.menuBorder.opacity(0.98)
        }
        if channel.recent == true {
            return AppTheme.menuBorder.opacity(0.56)
        }
        return AppTheme.menuBorder.opacity(0.88)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private func compact(_ text: String?) -> String? {
    let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? nil : trimmed
}

private struct VisibleMemoryRow: Identifiable {
    let index: Int
    let row: RadioMenuRow

    var id: String {
        "\(index)-\(row.id)"
    }
}

private struct VisibleMenuRow: Identifiable {
    let index: Int
    let row: RadioMenuRow

    var id: String {
        "\(index)-\(row.id)"
    }
}

private func visibleMemoryRows(_ rows: [RadioMenuRow], selectedRow: Int?, pageSize: Int = 6) -> [VisibleMemoryRow] {
    guard rows.count > pageSize else {
        return rows.enumerated().map { index, row in
            VisibleMemoryRow(index: index, row: row)
        }
    }
    let selected = max(0, min(selectedRow ?? 0, rows.count - 1))
    let start = max(0, min(max(selected - (pageSize / 2), 0), rows.count - pageSize))
    let end = min(rows.count, start + pageSize)
    return Array(rows[start ..< end].enumerated()).map { offset, row in
        VisibleMemoryRow(index: start + offset, row: row)
    }
}

private func visibleMenuRows(_ rows: [RadioMenuRow], selectedRow: Int?, pageSize: Int) -> [VisibleMenuRow] {
    guard rows.count > pageSize else {
        return rows.enumerated().map { index, row in
            VisibleMenuRow(index: index, row: row)
        }
    }
    let selected = max(0, min(selectedRow ?? 0, rows.count - 1))
    let start = max(0, min(max(selected - (pageSize / 2), 0), rows.count - pageSize))
    let end = min(rows.count, start + pageSize)
    return Array(rows[start ..< end].enumerated()).map { offset, row in
        VisibleMenuRow(index: start + offset, row: row)
    }
}

private func formattedMenuNum(_ raw: String?) -> String {
    guard let raw = compact(raw) else { return "" }
    if let value = Int(raw) {
        return String(format: "%02d", value)
    }
    return raw
}

private func isRowSelected(_ row: RadioMenuRow, menu: RadioMenuState) -> Bool {
    if let rowIndex = row.row, rowIndex == menu.selectedRow { return true }
    if let selectedIndex = menu.selectedIndex, row.row == selectedIndex { return true }
    if let selectedNum = menu.selectedNum, row.num == String(selectedNum) { return true }
    return false
}

private func rowPrimaryText(_ row: RadioMenuRow) -> String {
    compact(row.label) ?? compact(row.text) ?? compact(row.name) ?? compact(row.freq) ?? " "
}

private func rowSecondaryText(_ row: RadioMenuRow) -> String? {
    let pieces = [compact(row.name), compact(row.freq)].compactMap { $0 }
    let joined = pieces.joined(separator: " · ")
    return joined.isEmpty || joined == rowPrimaryText(row) ? nil : joined
}

private func menuRowTrailingValue(
    _ row: RadioMenuRow,
    primaryText: String,
    secondaryText: String?,
    currentValue: String? = nil,
    suppressBecauseValuePanel: Bool = false
) -> String? {
    guard !suppressBecauseValuePanel, let value = compact(row.value) else { return nil }
    let comparableValue = comparableMenuText(value)
    guard !comparableValue.isEmpty else { return nil }

    let comparableTexts = [primaryText, secondaryText, currentValue]
        .compactMap { $0 }
        .map(comparableMenuText)

    let duplicated = comparableTexts.contains { text in
        !text.isEmpty && (text == comparableValue || text.contains(comparableValue) || comparableValue.contains(text))
    }
    return duplicated ? nil : value
}

private func comparableMenuText(_ text: String) -> String {
    text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .uppercased()
        .replacingOccurrences(of: " ", with: "")
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
    @State private var isPressing = false
    @State private var longPressTask: Task<Void, Never>?

    private let longThreshold: Double = 0.45

    var body: some View {
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
        .background(
            RoundedRectangle(cornerRadius: compact ? 16 : 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isPressing
                            ? [AppTheme.buttonPressedTop, AppTheme.buttonPressedBottom]
                            : [AppTheme.buttonTop, AppTheme.buttonBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 16 : 14, style: .continuous)
                        .stroke(isPressing ? accent.opacity(0.95) : AppTheme.buttonStroke, lineWidth: isPressing ? 1.6 : 1)
                )
        )
        .scaleEffect(isPressing ? 0.985 : 1)
        .shadow(color: .black.opacity(isPressing ? 0.18 : 0.34), radius: isPressing ? 2 : 8, y: isPressing ? 1 : 5)
        .contentShape(RoundedRectangle(cornerRadius: compact ? 16 : 14, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard enabled else { return }
                    if !isPressing {
                        beginPress()
                    }
                }
                .onEnded { _ in
                    guard enabled else {
                        cancelPressState()
                        return
                    }
                    finishPress()
                }
        )
        .opacity(enabled ? 1 : 0.42)
        .accessibilityAddTraits(.isButton)
    }

    private var titleColor: Color {
        title == "⏻" ? accent : .white
    }

    private var subtitleColor: Color {
        title == "⏻" ? accent.opacity(0.82) : AppTheme.buttonSubtitle
    }

    private func beginPress() {
        isPressing = true
        didTriggerLong = false
        longPressTask?.cancel()
        longPressTask = Task {
            try? await Task.sleep(for: .milliseconds(Int(longThreshold * 1000)))
            await MainActor.run {
                guard isPressing, !didTriggerLong else { return }
                didTriggerLong = true
                action(true)
            }
        }
    }

    private func finishPress() {
        let wasLong = didTriggerLong
        cancelPressState()
        if !wasLong {
            action(false)
        }
    }

    private func cancelPressState() {
        isPressing = false
        didTriggerLong = false
        longPressTask?.cancel()
        longPressTask = nil
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
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.98), Color.white.opacity(0.72)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
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
            .frame(minHeight: 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.tagFill)
            )
    }
}

private extension RadioMenuState {
    var isMemoryMenu: Bool {
        switch type {
        case "memory_list", "memory_select", "memory_edit", "memory_freq_keypad", "memory_tag_keypad":
            return true
        default:
            return false
        }
    }
}

private struct ScreenBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(AppTheme.orangeBright)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
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
    static let menuBorder = Color(hex: 0x231E19, opacity: 0.78)
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
    static let lcdOffFill = LinearGradient(colors: [Color(hex: 0x9B9B9B), Color(hex: 0x8B8B8B), Color(hex: 0x7C7C7C)], startPoint: .top, endPoint: .bottom)
    static let lcdOffFrameStroke = Color(hex: 0x505050, opacity: 0.55)
    static let lcdOffText = Color(hex: 0x222222)
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
