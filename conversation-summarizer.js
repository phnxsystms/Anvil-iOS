/**
 * Conversation Summarizer - Analyzes and compresses chat history
 * Integrates with Token Manager for smart context preservation
 */

class ConversationSummarizer {
    constructor() {
        this.tokenManager = new TokenManager();
        this.patterns = {
            achievements: /🎯|✅|🎉/g,
            issues: /⚠️|❌|🚨|Load failed|error/gi,
            insights: /💡.*$/gm,
            tools: /<invoke name="([^"]+)">/g,
            files: /file_write.*?path.*?["'](.*?)["']/g,
            timestamps: /\d{1,2}\/\d{1,2}\/\d{4}.*?\d{1,2}:\d{2}/g
        };
    }

    /**
     * Analyze conversation for key metrics
     */
    analyzeConversation(text) {
        const analysis = {
            totalLength: text.length,
            estimatedTokens: this.tokenManager.estimateTokens(text),
            achievements: (text.match(this.patterns.achievements) || []).length,
            issues: (text.match(this.patterns.issues) || []).length,
            insights: (text.match(this.patterns.insights) || []).length,
            toolCalls: (text.match(this.patterns.tools) || []).length,
            filesCreated: (text.match(this.patterns.files) || []).length,
            timespan: this.extractTimespan(text)
        };

        return analysis;
    }

    /**
     * Extract timespan from conversation
     */
    extractTimespan(text) {
        const timestamps = text.match(this.patterns.timestamps) || [];
        if (timestamps.length < 2) return 'Single session';
        
        const first = timestamps[0];
        const last = timestamps[timestamps.length - 1];
        return `${first} → ${last}`;
    }

    /**
     * Extract the most important parts of a conversation
     */
    extractKeyContent(text) {
        const sections = {
            recentActivity: '',
            achievements: [],
            criticalIssues: [],
            learningInsights: [],
            toolUsage: [],
            fileOperations: []
        };

        // Get recent activity (last 2000 characters with context)
        const lines = text.split('\n');
        const recentLines = lines.slice(-50); // Last 50 lines
        sections.recentActivity = recentLines.join('\n');

        // Extract achievements
        const achievementMatches = text.match(/[🎯✅🎉].*$/gm) || [];
        sections.achievements = achievementMatches.slice(-10);

        // Extract critical issues
        const issueMatches = text.match(/[⚠️❌🚨].*$/gm) || [];
        sections.criticalIssues = issueMatches.slice(-5);

        // Extract learning insights
        sections.learningInsights = text.match(this.patterns.insights) || [];
        sections.learningInsights = sections.learningInsights.slice(-15);

        // Extract tool usage
        const toolMatches = text.match(this.patterns.tools) || [];
        const toolCounts = {};
        toolMatches.forEach(match => {
            const tool = match.match(/name="([^"]+)"/)[1];
            toolCounts[tool] = (toolCounts[tool] || 0) + 1;
        });
        sections.toolUsage = Object.entries(toolCounts).map(([tool, count]) => `${tool}: ${count}`);

        // Extract file operations
        const fileMatches = text.match(this.patterns.files) || [];
        sections.fileOperations = fileMatches.map(match => {
            const path = match.match(/["'](.*?)["']/)[1];
            return path;
        });

        return sections;
    }

    /**
     * Create a comprehensive summary
     */
    createSummary(conversationText) {
        const analysis = this.analyzeConversation(conversationText);
        const keyContent = this.extractKeyContent(conversationText);

        let summary = `# Conversation Summary\n`;
        summary += `**Generated:** ${new Date().toLocaleString()}\n`;
        summary += `**Token Usage:** ${analysis.estimatedTokens.toLocaleString()} tokens (~${Math.round(analysis.totalLength/1024)}KB)\n`;
        summary += `**Timespan:** ${analysis.timespan}\n\n`;

        // Metrics overview
        summary += `## Session Metrics 📊\n`;
        summary += `- 🎯 Achievements: ${analysis.achievements}\n`;
        summary += `- ⚠️ Issues Found: ${analysis.issues}\n`;
        summary += `- 💡 Learning Insights: ${analysis.insights}\n`;
        summary += `- 🛠️ Tool Executions: ${analysis.toolCalls}\n`;
        summary += `- 📄 Files Created: ${analysis.filesCreated}\n\n`;

        // Tool usage breakdown
        if (keyContent.toolUsage.length > 0) {
            summary += `## Tool Usage 🛠️\n`;
            keyContent.toolUsage.forEach(usage => {
                summary += `- ${usage}\n`;
            });
            summary += `\n`;
        }

        // Recent achievements
        if (keyContent.achievements.length > 0) {
            summary += `## Key Achievements 🎯\n`;
            keyContent.achievements.forEach(achievement => {
                summary += `- ${achievement}\n`;
            });
            summary += `\n`;
        }

        // Critical insights
        if (keyContent.learningInsights.length > 0) {
            summary += `## Learning Insights 💡\n`;
            keyContent.learningInsights.slice(-10).forEach(insight => {
                summary += `- ${insight}\n`;
            });
            summary += `\n`;
        }

        // Files created
        if (keyContent.fileOperations.length > 0) {
            summary += `## Files Created 📄\n`;
            [...new Set(keyContent.fileOperations)].forEach(file => {
                summary += `- \`${file}\`\n`;
            });
            summary += `\n`;
        }

        // Issues to address
        if (keyContent.criticalIssues.length > 0) {
            summary += `## Issues to Address ⚠️\n`;
            keyContent.criticalIssues.forEach(issue => {
                summary += `- ${issue}\n`;
            });
            summary += `\n`;
        }

        // Recent activity (preserve full context)
        summary += `## Recent Activity (Full Context)\n`;
        summary += `\`\`\`\n${keyContent.recentActivity}\n\`\`\`\n\n`;

        summary += `---\n*Auto-generated by Anvil Token Management System*`;

        return summary;
    }

    /**
     * Main function: analyze and potentially compress conversation
     */
    processConversation(conversationText) {
        const analysis = this.analyzeConversation(conversationText);
        
        console.log('📊 Conversation Analysis:', analysis);

        if (analysis.estimatedTokens > 180000) {
            console.log('🔄 Compression recommended - generating summary...');
            return {
                needsCompression: true,
                summary: this.createSummary(conversationText),
                analysis: analysis
            };
        }

        return {
            needsCompression: false,
            original: conversationText,
            analysis: analysis
        };
    }
}

// Export for use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ConversationSummarizer;
}

if (typeof window !== 'undefined') {
    window.ConversationSummarizer = ConversationSummarizer;
}

console.log('📝 Conversation Summarizer loaded!');