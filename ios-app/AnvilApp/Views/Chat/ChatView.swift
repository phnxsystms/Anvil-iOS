import SwiftUI
import Combine

struct ChatView: View {
    let conversation: Conversation
    @StateObject private var chatService = ChatService.shared
    @StateObject private var conversationStore = ConversationStore.shared
    @State private var messageText = ""
    @State private var isComposing = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(conversation.messages) { message in
                                MessageRowView(message: message)
                                    .id(message.id)
                            }
                            
                            // Typing indicator
                            if chatService.isLoading {
                                TypingIndicatorView()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: conversation.messages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: chatService.isLoading) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                Divider()
                
                // Message Input
                MessageInputView(
                    messageText: $messageText,
                    isComposing: $isComposing,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSend: sendMessage
                )
            }
            .navigationTitle(conversation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear Chat") {
                            conversationStore.clearMessages(conversation.id)
                        }
                        
                        Button("Export Chat") {
                            // TODO: Implement export
                        }
                        
                        Button("Delete Conversation", role: .destructive) {
                            conversationStore.deleteConversation(conversation.id)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onReceive(chatService.$lastError) { error in
            // Handle errors
            if let error = error {
                print("Chat error: \(error)")
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(
            role: .user,
            content: messageText,
            timestamp: Date()
        )
        
        conversationStore.addMessage(to: conversation.id, message: userMessage)
        messageText = ""
        isComposing = false
        
        // Send to API
        chatService.sendMessage(
            conversationId: conversation.id,
            message: userMessage
        )
    }
    
    private func scrollToBottom(proxy: ScrollViewReader) {
        withAnimation(.easeOut(duration: 0.3)) {
            if chatService.isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = conversation.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct MessageRowView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.role == .user
                            ? Color.blue
                            : Color(.systemGray5)
                    )
                    .foregroundColor(
                        message.role == .user
                            ? .white
                            : .primary
                    )
                    .clipShape(MessageBubble(isFromUser: message.role == .user))
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}

struct MessageBubble: Shape {
    let isFromUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isFromUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}

struct MessageInputView: View {
    @Binding var messageText: String
    @Binding var isComposing: Bool
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                // Text input
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                    .focused($isTextFieldFocused)
                    .onChange(of: messageText) { newValue in
                        isComposing = !newValue.isEmpty
                    }
                    .onSubmit {
                        if !messageText.isEmpty {
                            onSend()
                        }
                    }
                
                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? .secondary : .blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct TypingIndicatorView: View {
    @State private var animating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .clipShape(MessageBubble(isFromUser: false))
            
            Spacer(minLength: 60)
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    let sampleConversation = Conversation(
        title: "Sample Chat",
        messages: [
            Message(role: .user, content: "Hello!", timestamp: Date()),
            Message(role: .assistant, content: "Hi there! How can I help you today?", timestamp: Date())
        ]
    )
    
    return ChatView(conversation: sampleConversation)
}