import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @StateObject private var conversationStore = ConversationStore.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ConversationListView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Conversations")
                }
                .tag(0)
            
            if let currentConversation = conversationStore.currentConversation {
                ChatView(conversation: currentConversation)
                    .tabItem {
                        Image(systemName: "text.bubble.fill")
                        Text("Chat")
                    }
                    .tag(1)
            }
            
            FilesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Files")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

// MARK: - Placeholder Views (to be implemented)

struct FilesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("File Management")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Coming soon - manage your files and documents")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Files")
        }
    }
}

struct SettingsView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(authService.currentUser?.name ?? "Unknown")
                                .font(.headline)
                            Text(authService.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(authService.currentUser?.subscriptionTier.displayName ?? "")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Usage") {
                    if let user = authService.currentUser {
                        HStack {
                            Text("Messages Used")
                            Spacer()
                            Text("\(user.apiUsageCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        if let remaining = user.remainingMessages {
                            HStack {
                                Text("Messages Remaining")
                                Spacer()
                                Text("\(remaining)")
                                    .foregroundColor(remaining > 10 ? .secondary : .orange)
                            }
                        } else {
                            HStack {
                                Text("Messages")
                                Spacer()
                                Text("Unlimited")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("Subscription") {
                    NavigationLink("Manage Subscription") {
                        SubscriptionView()
                    }
                    
                    NavigationLink("Usage & Billing") {
                        UsageView()
                    }
                }
                
                Section("Support") {
                    Link("Help & FAQ", destination: URL(string: "https://anvil.help")!)
                    Link("Contact Support", destination: URL(string: "mailto:support@anvil.app")!)
                    Link("Privacy Policy", destination: URL(string: "https://anvil.app/privacy")!)
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        authService.logout()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Placeholder Detail Views

struct SubscriptionView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        List {
            ForEach(User.SubscriptionTier.allCases, id: \.self) { tier in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(tier.displayName)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(tier.price)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        if authService.currentUser?.subscriptionTier == tier {
                            Text("Current")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(tier.features, id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(feature)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    if authService.currentUser?.subscriptionTier != tier {
                        Button(tier == .free ? "Downgrade" : "Upgrade") {
                            // TODO: Implement subscription management
                        }
                        .buttonStyle(.bordered)
                        .tint(tier == .free ? .orange : .blue)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Subscription Plans")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UsageView: View {
    var body: some View {
        List {
            Section("This Month") {
                HStack {
                    Text("API Calls")
                    Spacer()
                    Text("127")
                }
                
                HStack {
                    Text("Tokens Used")
                    Spacer()
                    Text("45,231")
                }
                
                HStack {
                    Text("Estimated Cost")
                    Spacer()
                    Text("$3.42")
                }
            }
            
            Section("Usage History") {
                // TODO: Add chart view
                Text("Usage chart coming soon")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Usage & Billing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}