import SwiftUI
import Textual

enum OfflineAttachmentError: Error {
    case externalResourcesDisabled
}

struct OfflineAttachmentLoader: AttachmentLoader {
    func attachment(
        for url: URL,
        text: String,
        environment: ColorEnvironmentValues
    ) async throws -> OfflineAttachment {
        try rejectedAttachment()
    }

    func rejectedAttachment() throws -> OfflineAttachment {
        throw OfflineAttachmentError.externalResourcesDisabled
    }
}

struct OfflineAttachment: Attachment {
    let description: String

    @MainActor
    var body: some View {
        EmptyView()
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        in environment: TextEnvironmentValues
    ) -> CGSize {
        .zero
    }
}
