import UIKit

// "Compartir → PrezHome" en iOS (Instagram, TikTok, YouTube, Safari...).
// Coge el enlace o el texto compartido y abre PrezHome con
// com.prezhome.app://share?text=..., que services/share_inbox.dart recibe y
// manda a importar como en Android (MainActivity.kt).
class ShareViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    sharedText { text in
      DispatchQueue.main.async {
        if let text = text, let url = Self.appUrl(text) { self.openApp(url) }
        self.extensionContext?.completeRequest(returningItems: nil)
      }
    }
  }

  // El enlace si lo hay (Instagram y TikTok mandan la URL); si no, el texto.
  private func sharedText(_ done: @escaping (String?) -> Void) {
    let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
      .flatMap { $0.attachments ?? [] }
    if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier("public.url") }) {
      p.loadItem(forTypeIdentifier: "public.url") { item, _ in done((item as? URL)?.absoluteString) }
    } else if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier("public.plain-text") }) {
      p.loadItem(forTypeIdentifier: "public.plain-text") { item, _ in done(item as? String) }
    } else {
      done(nil)
    }
  }

  static func appUrl(_ text: String) -> URL? {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    guard let q = text.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
    return URL(string: "com.prezhome.app://share?text=\(q)")
  }

  // Las extensiones no tienen UIApplication.shared: se busca en la cadena de
  // respondedores (por eso APPLICATION_EXTENSION_API_ONLY = NO en el target).
  private func openApp(_ url: URL) {
    var responder: UIResponder? = self
    while let r = responder {
      if let app = r as? UIApplication {
        app.open(url, options: [:], completionHandler: nil)
        return
      }
      responder = r.next
    }
  }
}
