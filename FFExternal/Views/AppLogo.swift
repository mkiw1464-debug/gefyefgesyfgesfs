import SwiftUI
import UIKit

struct AppLogo: View {
    let size: CGFloat
    var body: some View {
        Group {
            if let image = UIImage(named: "AppLogo") ?? UIImage(named: "AppIcon") {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Image(systemName: "app.fill").resizable().scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
    }
}
