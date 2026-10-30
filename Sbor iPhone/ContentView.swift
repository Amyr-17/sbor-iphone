import SwiftUI
import MapKit

enum AppTab: Hashable {
    case events, map, messenger, profile
}

enum MessengerMode: String, CaseIterable {
    case feed = "Лента"
    case messages = "Сообщения"
}

enum AppTheme {
    static let ink = Color(red: 0.09, green: 0.13, blue: 0.20)
    static let muted = Color(red: 0.48, green: 0.52, blue: 0.61)
    static let coral = Color(red: 0.94, green: 0.45, blue: 0.37)
    static let coralSoft = Color(red: 1.00, green: 0.94, blue: 0.91)
    static let mint = Color(red: 0.85, green: 0.95, blue: 0.91)
    static let mintInk = Color(red: 0.16, green: 0.48, blue: 0.40)
    static let canvasTop = Color(red: 0.98, green: 0.98, blue: 1.00)
    static let canvasBottom = Color(red: 0.91, green: 0.94, blue: 0.98)
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .events

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.canvasTop, AppTheme.canvasBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                NavigationStack { EventsView() }
                    .tabItem { Label("События", systemImage: "square.grid.2x2") }
                    .tag(AppTab.events)
                NavigationStack { MapView() }
                    .tabItem { Label("Карта", systemImage: "map") }
                    .tag(AppTab.map)
                NavigationStack { MessengerView() }
                    .tabItem { Label("Мессенджер", systemImage: "bubble.left.and.bubble.right") }
                    .tag(AppTab.messenger)
                NavigationStack { ProfileView() }
                    .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
                    .tag(AppTab.profile)
            }
            .tint(AppTheme.coral)
        }
    }
}

struct GlassCard: ViewModifier {
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.white.opacity(0.78), lineWidth: 1))
            .shadow(color: AppTheme.ink.opacity(0.08), radius: 18, y: 10)
    }
}

extension View {
    func glassCard(radius: CGFloat = 22) -> some View { modifier(GlassCard(radius: radius)) }
}

struct AvatarView: View {
    let initials: String
    let tone: AvatarTone
    var size: CGFloat = 36

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.30, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(avatarGradient)
            .clipShape(Circle())
    }

    private var avatarGradient: LinearGradient {
        let colors: [Color]
        switch tone {
        case .coral: colors = [Color(red: 0.96, green: 0.66, blue: 0.52), Color(red: 0.72, green: 0.32, blue: 0.30)]
        case .blue: colors = [Color(red: 0.58, green: 0.75, blue: 0.90), Color(red: 0.30, green: 0.40, blue: 0.65)]
        case .gold: colors = [Color(red: 0.94, green: 0.80, blue: 0.54), Color(red: 0.61, green: 0.42, blue: 0.25)]
        case .purple: colors = [Color(red: 0.80, green: 0.69, blue: 0.89), Color(red: 0.42, green: 0.30, blue: 0.58)]
        case .user: colors = [Color(red: 0.96, green: 0.76, blue: 0.65), Color(red: 0.76, green: 0.36, blue: 0.27)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct SectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(AppTheme.mintInk)
            Text(title)
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
        }
    }
}

struct EventsView: View {
    @EnvironmentObject private var state: AppState
    @State private var search = ""
    @State private var category = "Все"
    @State private var selectedEvent: SborEvent?

    private let categories = ["Все", "Спорт", "Прогулка", "Творчество", "Лекции", "Встреча"]

    private var filteredEvents: [SborEvent] {
        state.events.filter { event in
            let categoryMatch = category == "Все" || event.category == category
            let searchMatch = search.isEmpty || [event.title, event.location, event.organizer, event.category].contains { $0.localizedCaseInsensitiveContains(search) }
            return categoryMatch && searchMatch
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(eyebrow: "Новосибирск · 29 октября", title: "События рядом", subtitle: "Подобрали встречи, к которым можно присоединиться")

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.muted)
                    TextField("Найти событие…", text: $search)
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .glassCard(radius: 14)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { item in
                            Button(item == "Прогулка" ? "Прогулки" : item) { category = item }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(category == item ? .white : AppTheme.muted)
                                .padding(.horizontal, 13)
                                .frame(height: 32)
                                .background(category == item ? AppTheme.ink : Color.white.opacity(0.62), in: Capsule())
                        }
                    }
                }

                VStack(spacing: 11) {
                    ForEach(filteredEvents) { event in
                        Button { selectedEvent = event } label: {
                            EventCard(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .environmentObject(state)
        }
    }
}

struct EventCard: View {
    let event: SborEvent

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(event.dateText.split(separator: " ").first.map(String.init) ?? "")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.coral)
                Text(event.dateText.split(separator: " ").dropFirst().first.map(String.init) ?? "")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
            }
            .frame(width: 52, height: 58)
            .background(AppTheme.coralSoft.opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(event.category.uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(AppTheme.coral)
                    if event.title.contains("Йога") {
                        Text("ОРГАНИЗАТОР")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.12), in: Capsule())
                    }
                }
                Text(event.title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 10) {
                    Label(event.time, systemImage: "clock")
                    Label(event.location, systemImage: "mappin.and.ellipse")
                        .lineLimit(1)
                }
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.muted)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.muted.opacity(0.7))
                AvatarView(initials: event.initials, tone: event.title.contains("Кат") ? .blue : .coral, size: 25)
                Text("\(event.members) мест")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(14)
        .glassCard(radius: 18)
    }
}

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let event: SborEvent
    @State private var joined = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(colors: [AppTheme.ink, Color(red: 0.34, green: 0.55, blue: 0.53)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Text(event.title)
                            .font(.system(size: 23, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(18)
                    }
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        DetailCell(icon: "calendar", title: "Дата и время", value: "\(event.dateText), \(event.time)")
                        DetailCell(icon: "mappin", title: "Место", value: event.location)
                        DetailCell(icon: "person.2", title: "Участники", value: "\(event.members) из \(event.capacity) мест")
                        DetailCell(icon: "lock.open", title: "Доступ", value: "Открытое событие")
                    }
                    Text(event.description)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.muted)
                        .lineSpacing(5)
                    HStack(spacing: 10) {
                        AvatarView(initials: event.initials, tone: .coral, size: 38)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.organizer).font(.system(size: 13, weight: .bold))
                            Text("Организатор события").font(.system(size: 11)).foregroundStyle(AppTheme.muted)
                        }
                    }
                    HStack(spacing: 10) {
                        Button { joined.toggle() } label: {
                            Label(joined ? "Вы участвуете" : "Присоединиться", systemImage: joined ? "checkmark" : "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CoralButtonStyle())
                        Button { dismiss() } label: {
                            Image(systemName: "bubble.left")
                                .frame(width: 48, height: 44)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }
                .padding(18)
            }
            .navigationTitle("Детали события")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Готово") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

struct DetailCell: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(AppTheme.coral)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 9)).foregroundStyle(AppTheme.muted)
                Text(value).font(.system(size: 10, weight: .bold)).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.38), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct MapView: View {
    @EnvironmentObject private var state: AppState
    @State private var satellite = false

    var body: some View {
        ZStack(alignment: .top) {
            SborTileMap(events: state.events, satellite: satellite)
            .ignoresSafeArea(edges: .bottom)

            HStack {
                Label("Новосибирск", systemImage: "map")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 13)
                    .frame(height: 38)
                    .glassCard(radius: 13)
                Spacer()
                Button { satellite.toggle() } label: {
                    Text(satellite ? "Схема" : "Спутник")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(satellite ? .white : AppTheme.ink)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(satellite ? AppTheme.ink : Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(satellite ? "Imagery © Esri" : "© OpenStreetMap contributors")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(AppTheme.ink.opacity(0.72))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 70)
            }
        }
        .navigationTitle("Карта")
        .navigationBarTitleDisplayMode(.inline)
    }
}

final class SborEventAnnotation: NSObject, MKAnnotation {
    let event: SborEvent
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(event: SborEvent) {
        self.event = event
        coordinate = event.coordinate
        title = event.title
        subtitle = event.location
    }
}

final class SborTileOverlay: MKTileOverlay {
    private let folder: String
    private let remoteTemplate: String

    init(folder: String, remoteTemplate: String) {
        self.folder = folder
        self.remoteTemplate = remoteTemplate
        super.init(urlTemplate: remoteTemplate)
        canReplaceMapContent = true
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let resourceName = "\(folder)/z\(path.z)_x\(path.x)_y\(path.y)"
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "png"), let data = try? Data(contentsOf: url) {
            result(data, nil)
            return
        }
        let urlString = remoteTemplate
            .replacingOccurrences(of: "{z}", with: String(path.z))
            .replacingOccurrences(of: "{x}", with: String(path.x))
            .replacingOccurrences(of: "{y}", with: String(path.y))
        guard let remoteURL = URL(string: urlString) else {
            result(nil, URLError(.badURL))
            return
        }
        URLSession.shared.dataTask(with: remoteURL) { data, _, error in
            result(data, error)
        }.resume()
    }
}

struct SborTileMap: UIViewRepresentable {
    let events: [SborEvent]
    let satellite: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.pointOfInterestFilter = .excludingAll
        let center = CLLocationCoordinate2D(latitude: 55.0415, longitude: 82.9346)
        mapView.setRegion(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.28, longitudeDelta: 0.42)), animated: false)
        context.coordinator.update(mapView, events: events, satellite: satellite)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.update(mapView, events: events, satellite: satellite)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private var currentSatellite = false

        func update(_ mapView: MKMapView, events: [SborEvent], satellite: Bool) {
            if mapView.overlays.isEmpty || currentSatellite != satellite {
                mapView.removeOverlays(mapView.overlays)
                let template = satellite
                    ? "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
                    : "https://tile.openstreetmap.de/{z}/{x}/{y}.png"
                let folder = satellite ? "MapTiles/satellite" : "MapTiles/streets"
                let tileOverlay = SborTileOverlay(folder: folder, remoteTemplate: template)
                mapView.addOverlay(tileOverlay, level: .aboveLabels)
                currentSatellite = satellite
            }
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(events.map(SborEventAnnotation.init))
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tileOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let eventAnnotation = annotation as? SborEventAnnotation else { return nil }
            let identifier = "sbor-event-marker"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView) ?? MKMarkerAnnotationView(annotation: eventAnnotation, reuseIdentifier: identifier)
            view.annotation = eventAnnotation
            view.markerTintColor = UIColor(AppTheme.coral)
            view.glyphText = "•"
            view.titleVisibility = .adaptive
            view.subtitleVisibility = .adaptive
            return view
        }
    }
}

struct MessengerView: View {
    @EnvironmentObject private var state: AppState
    @State private var mode: MessengerMode = .feed
    @State private var postText = ""
    @State private var commentPost: SborPost?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(eyebrow: "Открытое пространство", title: "Мессенджер", subtitle: "Публикации, комментарии и диалоги доступны всем")

                Picker("Раздел", selection: $mode) {
                    ForEach(MessengerMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if mode == .feed {
                    composer
                    ForEach(state.posts) { post in
                        PostCard(post: post, onLike: { state.toggleLike(for: post.id) }, onComment: { commentPost = post }, onMessage: {
                            state.openConversation(with: post.author, avatar: post.avatar, initials: post.initials)
                            mode = .messages
                        })
                    }
                } else {
                    MessagesPane()
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $commentPost) { post in
            CommentsSheet(postID: post.id)
                .environmentObject(state)
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AvatarView(initials: "НИ", tone: .user, size: 34)
                Text("Публикация будет видна всем")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            TextEditor(text: $postText)
                .frame(minHeight: 78)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if postText.isEmpty { Text("Что у вас на уме? Расскажите всем участникам…").font(.system(size: 12)).foregroundStyle(AppTheme.muted.opacity(0.7)).padding(18).allowsHitTesting(false) }
                }
            HStack {
                Spacer()
                Button("Опубликовать") { state.addPost(postText); postText = "" }
                    .buttonStyle(CoralButtonStyle())
                    .disabled(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .glassCard(radius: 20)
    }
}

struct PostCard: View {
    let post: SborPost
    let onLike: () -> Void
    let onComment: () -> Void
    let onMessage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                AvatarView(initials: post.initials, tone: post.avatar, size: 35)
                VStack(alignment: .leading, spacing: 3) {
                    Text(post.author).font(.system(size: 13, weight: .bold))
                    Text(post.time).font(.system(size: 10)).foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Image(systemName: "ellipsis").foregroundStyle(AppTheme.muted)
            }
            Text(post.text)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.ink.opacity(0.82))
                .lineSpacing(4)
            Divider().opacity(0.5)
            HStack(spacing: 10) {
                Button(action: onLike) { Label("\(post.likes)", systemImage: post.liked ? "heart.fill" : "heart") }
                    .foregroundStyle(post.liked ? AppTheme.coral : AppTheme.muted)
                Button(action: onComment) { Label("\(post.comments.count) комментариев", systemImage: "bubble.left") }
                    .foregroundStyle(AppTheme.muted)
                Button(action: onMessage) { Label("Написать", systemImage: "paperplane") }
                    .foregroundStyle(AppTheme.muted)
                Spacer()
            }
            .font(.system(size: 10, weight: .bold))
        }
        .padding(15)
        .glassCard(radius: 20)
    }
}

struct CommentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var state: AppState
    let postID: UUID
    @State private var text = ""

    private var post: SborPost? { state.posts.first { $0.id == postID } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let post {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 13) {
                            Text(post.text).font(.system(size: 14)).foregroundStyle(AppTheme.ink).padding(.bottom, 5)
                            ForEach(post.comments) { comment in
                                HStack(alignment: .top, spacing: 9) {
                                    AvatarView(initials: comment.initials, tone: comment.avatar, size: 28)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(comment.author).font(.system(size: 11, weight: .bold))
                                        Text(comment.text).font(.system(size: 12)).foregroundStyle(AppTheme.muted)
                                        Text(comment.time).font(.system(size: 9)).foregroundStyle(AppTheme.muted.opacity(0.7))
                                    }
                                    Spacer()
                                }
                                .padding(11)
                                .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            }
                        }
                        .padding(18)
                    }
                }
                HStack(spacing: 8) {
                    TextField("Написать комментарий…", text: $text, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 42)
                        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button { state.addComment(to: postID, text: text); text = "" } label: {
                        Image(systemName: "paperplane.fill").frame(width: 42, height: 42)
                    }
                    .buttonStyle(CoralButtonStyle())
                }
                .padding(15)
            }
            .navigationTitle("Комментарии")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Готово") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

struct MessagesPane: View {
    @EnvironmentObject private var state: AppState
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Диалоги").font(.system(size: 16, weight: .heavy, design: .rounded))
                Spacer()
                Text("ОТКРЫТО ВСЕМ").font(.system(size: 9, weight: .heavy)).foregroundStyle(AppTheme.mintInk)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(state.conversations) { conversation in
                        Button { state.selectedConversationID = conversation.id } label: {
                            VStack(spacing: 5) {
                                AvatarView(initials: conversation.initials, tone: conversation.avatar, size: 40)
                                Text(conversation.name.components(separatedBy: " ").first ?? conversation.name)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                            }
                            .frame(width: 66)
                            .padding(.vertical, 8)
                            .background(state.selectedConversationID == conversation.id ? AppTheme.coralSoft : Color.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }

            if let conversation = state.selectedConversation {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 9) {
                        AvatarView(initials: conversation.initials, tone: conversation.avatar, size: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conversation.name).font(.system(size: 12, weight: .bold))
                            Text("Можно написать напрямую").font(.system(size: 9)).foregroundStyle(AppTheme.mintInk)
                        }
                        Spacer()
                    }
                    .padding(13)
                    Divider().opacity(0.5)
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(conversation.messages) { message in
                                HStack {
                                    if message.isMine { Spacer() }
                                    VStack(alignment: message.isMine ? .trailing : .leading, spacing: 3) {
                                        Text(message.text).font(.system(size: 11)).foregroundStyle(message.isMine ? Color(red: 0.45, green: 0.25, blue: 0.22) : AppTheme.ink)
                                        Text(message.time).font(.system(size: 8)).foregroundStyle(AppTheme.muted)
                                    }
                                    .padding(10)
                                    .background(message.isMine ? AppTheme.coralSoft : Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                    if !message.isMine { Spacer() }
                                }
                            }
                        }
                        .padding(12)
                    }
                    .frame(maxHeight: 220)
                    HStack(spacing: 8) {
                        TextField("Написать сообщение…", text: $text, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(.horizontal, 11)
                            .frame(minHeight: 40)
                            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        Button { state.sendMessage(text); text = "" } label: {
                            Image(systemName: "paperplane.fill").frame(width: 40, height: 40)
                        }
                        .buttonStyle(CoralButtonStyle())
                    }
                    .padding(12)
                }
                .background(Color.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(14)
        .glassCard(radius: 20)
    }
}

struct ProfileView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(eyebrow: "Sbor", title: "Профиль", subtitle: "Ваши события и общение рядом")
                HStack(spacing: 13) {
                    AvatarView(initials: "НИ", tone: .user, size: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Никита Иванов").font(.system(size: 17, weight: .heavy, design: .rounded))
                        Text("Новосибирск · открыт к новым знакомствам").font(.system(size: 11)).foregroundStyle(AppTheme.muted)
                    }
                }
                .padding(16)
                .glassCard(radius: 20)
                VStack(spacing: 10) {
                    ProfileRow(icon: "calendar", title: "Мои события", value: "1 организовано")
                    ProfileRow(icon: "bubble.left.and.bubble.right", title: "Мессенджер", value: "Открыт всем участникам")
                    ProfileRow(icon: "lock.shield", title: "Демо-режим", value: "Данные хранятся на устройстве")
                }
            }
            .padding(18)
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(AppTheme.coral).frame(width: 23)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12, weight: .bold))
                Text(value).font(.system(size: 10)).foregroundStyle(AppTheme.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold)).foregroundStyle(AppTheme.muted)
        }
        .padding(14)
        .glassCard(radius: 16)
    }
}

struct CoralButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .frame(minHeight: 40)
            .background(AppTheme.coral.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .shadow(color: AppTheme.coral.opacity(0.2), radius: 10, y: 5)
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AppTheme.ink)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Color.white.opacity(0.8), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
