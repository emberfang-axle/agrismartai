import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../services/chatbot_service.dart';
import '../utils/chatbot_qa.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';
import '../widgets/app_decoration.dart';

/// Ka-Agro — Premium AI agricultural assistant with Taglish support.
class ChatbotScreen extends ConsumerStatefulWidget {
  static const route = '/chatbot';
  final bool showAppBar;

  const ChatbotScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMsg {
  final String text;
  final bool isUser;
  final String? source;
  const _ChatMsg(this.text, this.isUser, [this.source]);
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = ref.read(scanProvider).contextDisease;
      if (_messages.isEmpty) {
        setState(() {
          _messages.add(
              _ChatMsg(ChatbotQA.greeting(contextDisease: ctx), false, 'ka_agro'));
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _clearChat() {
    AppHaptics.tap();
    final ctx = ref.read(scanProvider).contextDisease;
    setState(() {
      _messages
        ..clear()
        ..add(_ChatMsg(ChatbotQA.greeting(contextDisease: ctx), false, 'ka_agro'));
    });
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _sending) return;
    await AppHaptics.tap();

    final contextDisease = ref.read(scanProvider).contextDisease;
    final history = _messages
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    setState(() {
      _messages.add(_ChatMsg(msg, true));
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();

    final user = ref.read(currentUserProvider);
    final ChatReply reply = await ref.read(chatbotServiceProvider).ask(
          message: msg,
          contextDisease: contextDisease,
          history: history,
          userId: user?.id,
        );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMsg(reply.text, false, reply.source));
      _sending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contextDisease = ref.watch(scanProvider).contextDisease;
    final diseaseName = contextDisease != null
        ? DiseaseData.byCode(contextDisease).name
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? AppBar(
              title: Row(
                children: [
                  _botAvatar(32),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppConfig.assistantName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Text('AGRISMARTAI Intelligence',
                          style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear chat',
                  onPressed: _clearChat,
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          if (!widget.showAppBar) _embeddedHeader(context),
          if (diseaseName != null && diseaseName != 'Healthy Rice Leaf')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.softGreen,
              child: Row(
                children: [
                  const Icon(Icons.biotech, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Asking about: $diseaseName',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warmGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Context',
                        style: TextStyle(fontSize: 10, color: AppColors.warmGold)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _sending) return _typingBubble();
                return _bubble(_messages[i])
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.04, end: 0);
              },
            ),
          ),
          _suggestions(),
          _composer(),
        ],
      ),
    );
  }

  Widget _botAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.greenGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _embeddedHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 8),
      child: Row(
        children: [
          _botAvatar(44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConfig.assistantName,
                    style: Theme.of(context).textTheme.headlineMedium),
                Text('Your rice farming expert',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 12, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('Offline • No API needed',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _botAvatar(24),
            const SizedBox(width: 10),
            const TypingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_ChatMsg m) {
    final isUser = m.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[_botAvatar(28), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? AppTheme.greenGradient
                    : null,
                color: isUser ? null : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: AppTheme.cardShadow(0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.ink,
                      height: 1.45,
                      fontSize: 15,
                    ),
                  ),
                  if (!isUser && m.source != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        m.source == 'ka_agro_offline'
                            ? 'Ka-Agro • Offline'
                            : 'Ka-Agro',
                        style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.white70 : AppColors.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 36),
          if (!isUser) const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _suggestions() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: ChatbotQA.suggestions
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.softGreen,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                    onPressed: _sending ? null : () => _send(s),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Pangutana kay ${AppConfig.assistantName}...',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.warmGold,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: _sending ? null : () => _send(_controller.text),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
