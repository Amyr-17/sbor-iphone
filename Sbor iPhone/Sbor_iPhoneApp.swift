import SwiftUI
import MapKit

@main
struct Sbor_iPhoneApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}

enum AvatarTone: String, Codable, CaseIterable {
    case coral, blue, gold, purple, user
}

struct SborEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let category: String
    let dateText: String
    let time: String
    let location: String
    let organizer: String
    let initials: String
    let members: Int
    let capacity: Int
    let latitude: Double
    let longitude: Double
    let description: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct SborComment: Identifiable, Codable, Hashable {
    let id: UUID
    let author: String
    let initials: String
    let avatar: AvatarTone
    let text: String
    let time: String
}

struct SborPost: Identifiable, Codable, Hashable {
    let id: UUID
    let author: String
    let initials: String
    let avatar: AvatarTone
    let time: String
    let text: String
    var likes: Int
    var liked: Bool
    var comments: [SborComment]
}

struct SborMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let isMine: Bool
    let text: String
    let time: String
}

struct SborConversation: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let initials: String
    let avatar: AvatarTone
    var preview: String
    var time: String
    var messages: [SborMessage]
}

struct MessengerStore: Codable {
    var posts: [SborPost]
    var conversations: [SborConversation]
}

@MainActor
final class AppState: ObservableObject {
    @Published var events: [SborEvent] = AppState.seedEvents
    @Published var posts: [SborPost]
    @Published var conversations: [SborConversation]
    @Published var selectedConversationID: UUID?

    private let storeKey = "sbor-iphone-messenger-v1"

    init() {
        let seed = AppState.seedMessenger
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let stored = try? JSONDecoder().decode(MessengerStore.self, from: data) {
            posts = stored.posts
            conversations = stored.conversations
        } else {
            posts = seed.posts
            conversations = seed.conversations
        }
        selectedConversationID = conversations.first?.id
    }

    var selectedConversation: SborConversation? {
        conversations.first { $0.id == selectedConversationID }
    }

    func toggleLike(for postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].liked.toggle()
        posts[index].likes = max(0, posts[index].likes + (posts[index].liked ? 1 : -1))
        saveMessenger()
    }

    func addPost(_ text: String) {
        let trimmed = sanitized(text, limit: 500)
        guard !trimmed.isEmpty else { return }
        posts.insert(SborPost(id: UUID(), author: "Никита Иванов", initials: "НИ", avatar: .user, time: "только что", text: trimmed, likes: 0, liked: false, comments: []), at: 0)
        saveMessenger()
    }

    func addComment(to postID: UUID, text: String) {
        let trimmed = sanitized(text, limit: 300)
        guard !trimmed.isEmpty, let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].comments.append(SborComment(id: UUID(), author: "Никита Иванов", initials: "НИ", avatar: .user, text: trimmed, time: "только что"))
        saveMessenger()
    }

    func openConversation(with name: String, avatar: AvatarTone, initials: String) {
        if let conversation = conversations.first(where: { $0.name == name }) {
            selectedConversationID = conversation.id
        } else {
            let conversation = SborConversation(id: UUID(), name: name, initials: initials, avatar: avatar, preview: "Новый диалог", time: "сейчас", messages: [])
            conversations.insert(conversation, at: 0)
            selectedConversationID = conversation.id
            saveMessenger()
        }
    }

    func sendMessage(_ text: String) {
        let trimmed = sanitized(text, limit: 300)
        guard !trimmed.isEmpty, let id = selectedConversationID, let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        let time = Date.now.formatted(date: .omitted, time: .shortened)
        conversations[index].messages.append(SborMessage(id: UUID(), isMine: true, text: trimmed, time: time))
        conversations[index].preview = trimmed
        conversations[index].time = time
        saveMessenger()
    }

    private func sanitized(_ value: String, limit: Int) -> String {
        value.replacingOccurrences(of: "\u{0000}", with: "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(limit).description
    }

    private func saveMessenger() {
        let store = MessengerStore(posts: posts, conversations: conversations)
        if let data = try? JSONEncoder().encode(store) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }

    static let seedEvents: [SborEvent] = [
        SborEvent(id: UUID(), title: "Ранний бег в Заельцовском", category: "Спорт", dateText: "30 октября", time: "07:30", location: "Заельцовский парк", organizer: "Анна Петрова", initials: "АП", members: 8, capacity: 12, latitude: 55.0702, longitude: 82.8802, description: "Лёгкий темп, кофе после пробежки и компания для новичков."),
        SborEvent(id: UUID(), title: "Лекция: как думать о будущем", category: "Лекции", dateText: "30 октября", time: "18:30", location: "Академпарк, зал 2", organizer: "Дмитрий Волков", initials: "ДВ", members: 42, capacity: 60, latitude: 54.8438, longitude: 83.0932, description: "Разговор о сценариях будущего и технологиях. После — открытый микрофон."),
        SborEvent(id: UUID(), title: "Вечер настолок у Кати", category: "Встреча", dateText: "31 октября", time: "19:00", location: "Красный проспект, 32", organizer: "Катя Орлова", initials: "КО", members: 6, capacity: 10, latitude: 55.0302, longitude: 82.9204, description: "Новые игры и старые любимые хиты. Пицца и чай на месте."),
        SborEvent(id: UUID(), title: "Осенний пикник у Обского моря", category: "Прогулка", dateText: "1 ноября", time: "12:00", location: "Парк у Обского моря", organizer: "Лера Смирнова", initials: "ЛС", members: 14, capacity: 20, latitude: 54.8426, longitude: 82.9310, description: "Пледы, термосы и прогулка у воды. Можно присоединиться с друзьями."),
        SborEvent(id: UUID(), title: "Керамика для своих", category: "Творчество", dateText: "2 ноября", time: "18:00", location: "Мастерская «Глина»", organizer: "Анна Петрова", initials: "АП", members: 5, capacity: 8, latitude: 55.0350, longitude: 82.9220, description: "Два часа лепим руками всё, что придёт в голову. Материалы включены."),
        SborEvent(id: UUID(), title: "Йога на крыше", category: "Спорт", dateText: "3 ноября", time: "10:00", location: "БЦ «Сити», 12 этаж", organizer: "Никита Иванов", initials: "НИ", members: 9, capacity: 12, latitude: 55.0410, longitude: 82.9340, description: "Спокойная практика для всех уровней. Коврик можно взять на месте.")
    ]

    static let seedMessenger = MessengerStore(
        posts: [
            SborPost(id: UUID(), author: "Алина Петрова", initials: "АП", avatar: .coral, time: "12 минут назад", text: "Кто сегодня идёт на ранний бег в Заельцовском? После можно взять кофе ☕️", likes: 12, liked: false, comments: [SborComment(id: UUID(), author: "Дима Волков", initials: "ДВ", avatar: .gold, text: "Я с вами, буду у входа в 7:30!", time: "8 минут назад")]),
            SborPost(id: UUID(), author: "Катя Орлова", initials: "КО", avatar: .blue, time: "34 минуты назад", text: "Собираю компанию на вечер настолок. Если любите новые игры — присоединяйтесь, будем рады всем.", likes: 8, liked: false, comments: [SborComment(id: UUID(), author: "Лера Смирнова", initials: "ЛС", avatar: .purple, text: "Звучит здорово! Возьму «Кодовые имена».", time: "21 минуту назад")]),
            SborPost(id: UUID(), author: "Дмитрий Волков", initials: "ДВ", avatar: .gold, time: "1 час назад", text: "После лекции в Академпарке предлагаю продолжить разговор за чаем. Пишите в личку, если хотите присоединиться.", likes: 5, liked: false, comments: [])
        ],
        conversations: [
            SborConversation(id: UUID(), name: "Катя Орлова", initials: "КО", avatar: .blue, preview: "Давай после лекции?", time: "11:49", messages: [SborMessage(id: UUID(), isMine: false, text: "Привет! Давай после лекции обсудим настолки?", time: "11:46"), SborMessage(id: UUID(), isMine: true, text: "Давай, я буду в мессенджере.", time: "11:49")]),
            SborConversation(id: UUID(), name: "Дмитрий Волков", initials: "ДВ", avatar: .gold, preview: "Скину материалы вечером", time: "10:32", messages: [SborMessage(id: UUID(), isMine: false, text: "Скину материалы лекции вечером.", time: "10:32")]),
            SborConversation(id: UUID(), name: "Лера Смирнова", initials: "ЛС", avatar: .purple, preview: "Плед уже в рюкзаке", time: "вчера", messages: [SborMessage(id: UUID(), isMine: false, text: "Плед уже в рюкзаке, не забудь термос.", time: "вчера")])
        ]
    )
}
