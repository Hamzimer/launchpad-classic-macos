import SwiftUI
import AppKit

struct ScrollWheelMonitor: NSViewRepresentable {
    let onPage: (Int) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPage: onPage) }
    func makeNSView(context: Context) -> NSView {
        let view = MousePassthroughView(frame: .zero)
        context.coordinator.install(for: view)
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) { context.coordinator.onPage = onPage }
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) { coordinator.uninstall() }

    @MainActor final class Coordinator {
        var onPage: (Int) -> Void
        private weak var view: NSView?
        private var monitor: Any?
        private var accumulated: CGFloat = 0
        private var lastChange = Date.distantPast

        init(onPage: @escaping (Int) -> Void) { self.onPage = onPage }
        func install(for view: NSView) {
            self.view = view
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let windowNumber = view?.window?.windowNumber else { return }
                self.installMonitor(windowNumber: windowNumber)
            }
        }

        private func installMonitor(windowNumber: Int) {
            uninstall()
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard event.windowNumber == windowNumber else { return event }
                let movement = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY)
                    ? -event.scrollingDeltaX : -event.scrollingDeltaY
                Task { @MainActor [weak self] in self?.handle(movement: movement) }
                return event
            }
        }

        private func handle(movement: CGFloat) {
            accumulated += movement
            guard abs(accumulated) >= 32, Date().timeIntervalSince(lastChange) > 0.28 else { return }
            onPage(accumulated > 0 ? 1 : -1)
            accumulated = 0
            lastChange = Date()
        }

        func uninstall() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
    }
}

private final class MousePassthroughView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
