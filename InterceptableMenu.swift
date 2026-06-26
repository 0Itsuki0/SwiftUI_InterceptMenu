
extension View {
    @ContentBuilder
    func contextMenu<Menu: View>(
        @ContentBuilder menu: @escaping () -> Menu,
        menuWillOpen: @escaping () -> Bool
    ) -> some View {
        ViewWithContextMenu(
            root: {
                self
            },
            menu: menu,
            menuWillOpen: menuWillOpen
        )
    }
}

struct ViewWithContextMenu<Root: View, Menu: View>: NSViewRepresentable {

    init(
        root: @escaping () -> Root,
        menu: @escaping () -> Menu,
        menuWillOpen: @escaping () -> Bool
    ) {
        self.rootView = NSHostingView(rootView: root())
        self.menuView = NSHostingMenu(rootView: menu())
        self.menuWillOpen = menuWillOpen
    }

    let rootView: NSHostingView<Root>
    let menuView: NSHostingMenu<Menu>
    let menuWillOpen: () -> Bool

    func makeNSView(context: Context) -> NSView {
        rootView.setFrameSize(rootView.fittingSize)
        rootView.translatesAutoresizingMaskIntoConstraints = false
        rootView.gestureRecognizers = [
            self.makeNSGestureRecognizer(context: context)
        ]
        return rootView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.setFrameSize(nsView.fittingSize)
    }

    func makeNSGestureRecognizer(context: Context) -> NSClickGestureRecognizer {
        let gesture = NSClickGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleGesture)
        )
        // buttonMask for secondary click (ex: right click, double tap and etc. based on settings)
        // numberOfClicksRequired and numberOfTouchesRequired are not what we need here.
        // Those are for consecutive touches / clicks, not simultaneous one
        gesture.buttonMask = 0x2
        gesture.delegate = context.coordinator
        return gesture
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            menuWillOpen: menuWillOpen,
            rootSender: rootView,
            menu: menuView
        )
    }

    class Coordinator: NSObject, NSGestureRecognizerDelegate {
        let menuWillOpen: () -> Bool
        let rootSender: NSView
        let menu: NSMenu

        init(
            menuWillOpen: @escaping () -> Bool,
            rootSender: NSView,
            menu: NSMenu
        ) {
            self.menuWillOpen = menuWillOpen
            self.rootSender = rootSender
            self.menu = menu
        }

        func showMenu(_ sender: NSView) {
            let event = NSApp.currentEvent ?? NSEvent()
            NSMenu.popUpContextMenu(self.menu, with: event, for: sender)
        }

        @objc func handleGesture() {
            let result = self.menuWillOpen()
            if result {
                self.showMenu(rootSender)
            }
        }

        // Allow coexistence with other gestures (e.g., native single tap)
        func gestureRecognizer(
            _ gestureRecognizer: NSGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
                NSGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}
