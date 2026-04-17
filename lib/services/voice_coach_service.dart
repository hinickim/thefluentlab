import '../providers/chat_notifier.dart';

/// VoiceCoachService provides AI-powered coaching messages
/// using the OpenAI chat completion integration.
class VoiceCoachService {
  static const ChatConfig coachConfig = ChatConfig(
    provider: 'OPEN_AI',
    model: 'gpt-4.1-mini',
    streaming: false,
  );

  /// System prompt that defines the voice coach persona
  static const String _systemPrompt = '''
You are an encouraging, expert voice and speech coach named "Coach Aria" for The Fluent Lab app.
Your role is to guide users through voice practice sessions in a warm, conversational, and motivating way.
Keep responses concise (2-3 sentences max). Be specific, actionable, and upbeat.
Avoid technical jargon unless explaining a concept. Always end with encouragement or a clear next step.
''';

  /// Generate a welcome/intro message for a new practice session
  static List<Map<String, dynamic>> sessionStartMessages({
    String? userName,
    String? level,
    List<String>? struggles,
  }) {
    final name = (userName != null && userName.isNotEmpty) ? userName : 'there';
    final levelText = level ?? 'Beginner';
    final struggleText = (struggles != null && struggles.isNotEmpty)
        ? struggles.join(', ')
        : 'general speech';

    return [
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'user',
        'content':
            'Start a new practice session for $name. Their level is $levelText and they are working on: $struggleText. Give a short, warm welcome and tell them what to expect today.',
      },
    ];
  }

  /// Generate feedback message after a practice attempt
  static List<Map<String, dynamic>> feedbackMessages({
    required String sentenceText,
    required int overallScore,
    required String tip,
    required List<String> highlightedWords,
  }) {
    return [
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'user',
        'content':
            'The user just practiced: "$sentenceText". Their overall score was $overallScore/100. '
            'The challenging words were: ${highlightedWords.join(", ")}. '
            'Coaching tip: $tip. '
            'Give a brief, encouraging spoken feedback as if you are speaking to them directly.',
      },
    ];
  }

  /// Generate a motivational message when a session is completed
  static List<Map<String, dynamic>> sessionCompleteMessages({
    required int streak,
    required int score,
  }) {
    return [
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'user',
        'content':
            'The user just completed a full practice session! Their streak is now $streak days and their average score was $score/100. '
            'Give a short, celebratory message to keep them motivated.',
      },
    ];
  }

  /// Generate onboarding welcome message
  static List<Map<String, dynamic>> onboardingWelcomeMessages({
    required String role,
    required List<String> struggles,
    required String level,
  }) {
    return [
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'user',
        'content':
            'A new user just completed onboarding. They are a $role working on: ${struggles.join(", ")}. '
            'Their recommended level is $level. '
            'Give a short, personalized welcome message that acknowledges their goals and gets them excited to start.',
      },
    ];
  }
}

/// Provider for the voice coach chat state
final voiceCoachProvider = chatNotifierProvider(VoiceCoachService.coachConfig);
