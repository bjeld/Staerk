import SwiftUI
import UIKit

enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct KeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "keyboard.done")) {
                    Keyboard.dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

struct ScrollKeyboardDismiss: ViewModifier {
    var mode: ScrollDismissesKeyboardMode = .interactively

    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(mode)
            .simultaneousGesture(
                TapGesture().onEnded {
                    Keyboard.dismiss()
                }
            )
    }
}

extension View {
    func staerkKeyboardDone() -> some View {
        modifier(KeyboardDoneToolbar())
    }

    func staerkKeyboard() -> some View {
        modifier(ScrollKeyboardDismiss())
    }

    func staerkKeyboardImmediate() -> some View {
        modifier(ScrollKeyboardDismiss(mode: .immediately))
    }

    /// A tap gesture on a `Form` swallows taps meant for menu-style `Picker`s, so forms only dismiss on scroll.
    func staerkFormKeyboard() -> some View {
        scrollDismissesKeyboard(.immediately)
    }
}
