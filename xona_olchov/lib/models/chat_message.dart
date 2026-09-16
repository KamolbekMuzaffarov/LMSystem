/// Suhbatdagi bitta xabar — kim yozgani va matni.
enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.failed = false,
  });

  const ChatMessage.user(this.text) : role = ChatRole.user, failed = false;

  const ChatMessage.assistant(this.text)
    : role = ChatRole.assistant,
      failed = false;

  /// Xatolik ko'rsatadigan javob pufagi.
  const ChatMessage.error(this.text) : role = ChatRole.assistant, failed = true;

  final ChatRole role;
  final String text;

  /// Javob o'rniga xatolik ko'rsatilyaptimi.
  final bool failed;

  bool get isUser => role == ChatRole.user;

  /// Serverga yuboriladigan ko'rinish.
  Map<String, String> toWire() => <String, String>{
    'role': role.name,
    'content': text,
  };
}
