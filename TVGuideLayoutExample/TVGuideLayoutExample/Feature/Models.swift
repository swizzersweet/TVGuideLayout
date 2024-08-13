import Foundation

struct MainSectionDetails: Hashable, Identifiable {
    let id: String
    let title: String
}

struct MainDetailsItem: Hashable, Identifiable {
    var id: String
    let text: String
    let minutes: Int
}

struct TimeDetailsItem: Hashable, Identifiable {
    var id: String
    var text: String
}

struct ChannelDetailsItem: Hashable, Identifiable {
    var id: String
    var text: String
}
