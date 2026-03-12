# Anvil iOS App Development Plan 🚀

## Project Overview
Transform the current web-based Anvil into a native iOS application with proper backend architecture.

## Phase 1: Backend Infrastructure (Week 1-2)

### 1.1 Vercel Backend Setup
```
anvil-backend/
├── api/
│   ├── chat.js          # Main Claude API proxy
│   ├── auth.js          # User authentication
│   ├── history.js       # Conversation history
│   └── tools.js         # Tool execution proxy
├── lib/
│   ├── claude.js        # Claude API client
│   ├── auth.js          # JWT helpers
│   └── db.js           # Database helpers
├── package.json
└── vercel.json
```

**Key Endpoints:**
- `POST /api/chat` - Proxy to Claude API
- `POST /api/tools/execute` - Execute JavaScript/tools
- `GET/POST /api/history` - Conversation management
- `POST /api/auth/login` - User authentication

### 1.2 Database Schema (Supabase/PlanetScale)
```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE,
  name VARCHAR(255),
  api_usage_count INT DEFAULT 0,
  subscription_tier VARCHAR(50) DEFAULT 'free',
  created_at TIMESTAMP
);

-- Conversations table  
CREATE TABLE conversations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  title VARCHAR(255),
  messages JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Usage tracking
CREATE TABLE api_calls (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  tokens_used INT,
  cost_cents INT,
  created_at TIMESTAMP
);
```

## Phase 2: iOS App Development (Week 2-4)

### 2.1 Project Structure
```
AnvilApp/
├── AnvilApp/
│   ├── App/
│   │   ├── AnvilApp.swift
│   │   └── ContentView.swift
│   ├── Views/
│   │   ├── ChatView.swift
│   │   ├── ConversationListView.swift
│   │   ├── SettingsView.swift
│   │   └── AuthView.swift
│   ├── Models/
│   │   ├── Message.swift
│   │   ├── Conversation.swift
│   │   └── User.swift
│   ├── Services/
│   │   ├── APIService.swift
│   │   ├── AuthService.swift
│   │   └── StorageService.swift
│   └── Utils/
│       ├── Extensions.swift
│       └── Constants.swift
├── AnvilAppTests/
└── AnvilAppUITests/
```

### 2.2 Core Features
1. **Chat Interface** - Clean, iMessage-style UI
2. **Tool Execution** - File operations, code execution, web previews
3. **Conversation History** - Persistent across devices
4. **Authentication** - Email/password + biometric
5. **Offline Mode** - Basic functionality when disconnected
6. **Settings** - Usage tracking, subscription management

### 2.3 Technology Stack
- **Framework**: SwiftUI + Combine
- **Networking**: URLSession with async/await
- **Local Storage**: Core Data + FileManager
- **Authentication**: Custom JWT + Keychain
- **File Management**: Document picker integration
- **Web Rendering**: WKWebView for previews

## Phase 3: Advanced Features (Week 4-6)

### 3.1 Tool System
- **File Operations**: Create, read, write, delete files
- **Code Execution**: JavaScript runner with npm packages
- **Web Previews**: Built-in browser with live updates
- **GitHub Integration**: Repository management
- **Database Tools**: SQLite integration

### 3.2 Premium Features
- **Unlimited Usage** - No message limits
- **Priority Processing** - Faster responses
- **Advanced Tools** - More npm packages, bigger files
- **Cloud Sync** - Cross-device conversation sync
- **Export Options** - Share conversations, files

## Implementation Timeline

### Week 1: Backend Foundation
- [x] Planning document created
- [ ] Vercel project setup
- [ ] Claude API proxy implementation
- [ ] Basic authentication system
- [ ] Database schema deployment

### Week 2: Core Backend + iOS Setup
- [ ] Tool execution endpoints
- [ ] Conversation history API
- [ ] iOS project initialization
- [ ] Basic UI framework
- [ ] API service integration

### Week 3: iOS Core Features
- [ ] Chat interface implementation
- [ ] Real-time messaging
- [ ] File operations
- [ ] Authentication flow
- [ ] Local storage

### Week 4: Polish & Testing
- [ ] Tool system integration
- [ ] Web preview functionality
- [ ] Error handling
- [ ] Testing & debugging
- [ ] App Store preparation

## Monetization Strategy

### Free Tier
- 50 messages per month
- Basic file operations
- Limited tool access
- No cloud sync

### Pro Tier ($9.99/month)
- Unlimited messages
- Full tool access
- Cloud sync
- Priority support
- Export features

### Enterprise ($29.99/month)
- Everything in Pro
- Advanced integrations
- Custom tool development
- Priority processing
- White-label options

## Technical Requirements

### iOS App Requirements
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Device storage: 100MB minimum

### Backend Requirements  
- Node.js 18+
- Vercel Pro account
- Database (Supabase/PlanetScale)
- Claude API key
- GitHub integration

## Risk Mitigation

### Technical Risks
- **API Rate Limits**: Implement request queuing
- **Cost Control**: Usage caps per user
- **Offline Functionality**: Local caching strategy
- **App Store Approval**: Follow guidelines strictly

### Business Risks
- **Claude API Changes**: Vendor diversification plan
- **Competition**: Focus on unique tool integration
- **User Acquisition**: Freemium conversion strategy

## Success Metrics
- **User Engagement**: Daily/monthly active users
- **Conversion Rate**: Free to paid upgrades
- **Retention**: 30-day user retention rate
- **Revenue**: Monthly recurring revenue growth
- **App Store**: Rating above 4.5 stars

## Next Steps
1. **Immediate**: Set up Vercel backend project
2. **This Week**: Implement Claude API proxy
3. **Next Week**: Start iOS app development
4. **Month 1**: Beta release to TestFlight
5. **Month 2**: App Store submission

Ready to start building! 🛠️