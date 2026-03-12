import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String
    let subscriptionTier: SubscriptionTier
    let apiUsageCount: Int
    let createdAt: Date
    
    enum SubscriptionTier: String, Codable, CaseIterable {
        case free
        case pro
        case enterprise
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .pro: return "Pro"
            case .enterprise: return "Enterprise"
            }
        }
        
        var messageLimit: Int? {
            switch self {
            case .free: return 50
            case .pro, .enterprise: return nil
            }
        }
        
        var price: String {
            switch self {
            case .free: return "Free"
            case .pro: return "$9.99/month"
            case .enterprise: return "$29.99/month"
            }
        }
        
        var features: [String] {
            switch self {
            case .free:
                return [
                    "50 messages per month",
                    "Basic file operations",
                    "Limited tool access"
                ]
            case .pro:
                return [
                    "Unlimited messages",
                    "Full tool access",
                    "Cloud sync",
                    "Priority support",
                    "Export features"
                ]
            case .enterprise:
                return [
                    "Everything in Pro",
                    "Advanced integrations",
                    "Custom tool development",
                    "Priority processing",
                    "White-label options"
                ]
            }
        }
    }
    
    var remainingMessages: Int? {
        guard let limit = subscriptionTier.messageLimit else { return nil }
        return max(0, limit - apiUsageCount)
    }
    
    var canSendMessage: Bool {
        return remainingMessages == nil || remainingMessages! > 0
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, createdAt
        case subscriptionTier = "subscription_tier"
        case apiUsageCount = "api_usage_count"
    }
}