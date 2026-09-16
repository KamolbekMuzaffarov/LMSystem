import 'package:flutter/material.dart';

import '../../data/potolok_store.dart';
import '../../models/chat_message.dart';
import '../../services/assistant_service.dart';
import '../../services/contact_links.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_bits.dart';

/// AI yordamchi — mijozning savollariga javob beradigan suhbat oynasi.
///
/// Suhbat qurilma xotirasida saqlanmaydi: oyna yopilsa tozalanadi.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.service});

  /// Testlar uchun tayyor xizmat. Berilmasa o'zi yaratiladi.
  final AssistantService? service;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[];

  late final AssistantService _service = widget.service ?? AssistantService();
  bool _sending = false;

  static const List<String> _suggestions = <String>[
    'Narxi qancha?',
    'Kafolat necha yil?',
    'Bir kunda o‘rnatasizmi?',
    'Qanday turlari bor?',
    'Chang chiqadimi?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _messages.add(ChatMessage.user(text));
      _sending = true;
    });
    _scrollToEnd();

    final result = await _service.ask(_messages);
    if (!mounted) return;
    setState(() {
      _messages.add(
        result.isOk
            ? ChatMessage.assistant(result.reply!)
            : ChatMessage.error(result.errorText),
      );
      _sending = false;
    });
    _scrollToEnd();
  }

  /// Oxirgi savolni qayta yuboradi (xatolikdan keyin).
  Future<void> _retryLast() async {
    if (_sending) return;
    // Oxirgi xatolik pufagini olib tashlaymiz, savol tarixda qoladi.
    final lastUser = _messages.lastWhere(
      (m) => m.isUser,
      orElse: () => const ChatMessage.user(''),
    );
    if (lastUser.text.isEmpty) return;
    setState(() {
      if (_messages.isNotEmpty && _messages.last.failed) _messages.removeLast();
      _sending = true;
    });

    final result = await _service.ask(_messages);
    if (!mounted) return;
    setState(() {
      _messages.add(
        result.isOk
            ? ChatMessage.assistant(result.reply!)
            : ChatMessage.error(result.errorText),
      );
      _sending = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _call() async {
    final phone = PotolokScope.read(context).contactPhone;
    if (phone == null) {
      context.showSnack('Telefon raqami «Potolok» bo‘limida kiritiladi');
      return;
    }
    final ok = await ContactLinks.call(phone);
    if (!ok && mounted) context.showSnack('Qo‘ng‘iroqni ochib bo‘lmadi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI yordamchi'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Qo‘ng‘iroq',
            onPressed: _call,
            icon: const Icon(Icons.call, color: AppColors.gold),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _messages.isEmpty
                ? _Intro(onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const _TypingBubble();
                      }
                      final message = _messages[index];
                      return _Bubble(
                        message: message,
                        onRetry: message.failed ? _retryLast : null,
                      );
                    },
                  ),
          ),
          _Composer(controller: _input, enabled: !_sending, onSend: _send),
        ],
      ),
    );
  }
}

/// Bo'sh holat — salom va tayyor savollar.
class _Intro extends StatelessWidget {
  const _Intro({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      children: <Widget>[
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: AppColors.gold,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Savolingiz bormi?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: 22,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Natyajnoy potolok haqida xohlagan narsangizni so‘rang — '
          'narx, kafolat, turlari va o‘rnatish bo‘yicha javob beraman. '
          'Aniq summa uchun bepul o‘lchov yoki qo‘ng‘iroq kerak bo‘ladi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final suggestion in _AssistantScreenState._suggestions)
              ActionChip(
                label: Text(suggestion),
                onPressed: () => onPick(suggestion),
                backgroundColor: AppColors.surfaceHigh,
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.30)),
                labelStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final color = message.failed
        ? AppColors.danger.withValues(alpha: 0.14)
        : isUser
        ? AppColors.shapeFill
        : AppColors.surfaceHigh;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: message.failed
              ? Border.all(color: AppColors.danger.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (message.failed) ...<Widget>[
                  const Icon(
                    Icons.cloud_off,
                    size: 15,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: message.failed
                          ? AppColors.textPrimary
                          : (isUser
                                ? AppColors.textPrimary
                                : AppColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text('Qayta urinish'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const SizedBox(
          width: 20,
          height: 16,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? onSend : null,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Savolingizni yozing…',
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(enabled: enabled, onTap: () => onSend(controller.text)),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.gold : AppColors.surfaceHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            Icons.arrow_upward,
            size: 20,
            color: enabled ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
