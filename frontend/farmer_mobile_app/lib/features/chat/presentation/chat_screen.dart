import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../shared/branding/app_brand.dart';
import '../../../shared/branding/app_logo.dart';
import '../../scan/domain/scan_result.dart';
import '../domain/chat_message.dart';

/// ChatGPT-style conversational assistant for rice farming support.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  bool _typing = false;

  static const _starters = [
    'Ano ang ibig sabihin ng result ko?',
    'Paano i-treat ang sakit na ito?',
    'Kailangan ba pumunta sa DA?',
    'What fertilizer should I use?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text:
          'Kumusta! 👋 Ako si **AgriSmartAI**, rice farming assistant mo.\n\n'
          'Magtanong ka sa **Taglish o English** — diseases, treatment, fertilizer, o DA office. '
          'Kung may scan result ka, tanungin mo ako para i-explain ko nang simple.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: 250.ms, curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _typing) return;
    _input.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _typing = true;
    });
    _scrollDown();

    final history = _messages
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    final scan = ref.read(scanContextProvider);
    final reply = await ref.read(chatRepositoryProvider).send(
          messages: history,
          scanContext: scan?.toChatContext(),
        );

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _typing = false;
      });
      _scrollDown();
    }
  }

  void _newChat() {
    setState(() {
      _messages
        ..clear()
        ..add(ChatMessage(
          text: 'New conversation started. Ano ang matutulong ko sa iyo ngayon?',
          isUser: false,
        ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanContextProvider);
    final hasUserMsgs = _messages.any((m) => m.isUser);

    return Scaffold(
      backgroundColor: AppBrand.background,
      appBar: AppBar(
        backgroundColor: AppBrand.surface,
        elevation: 0,
        title: Row(
          children: [
            const AppLogo(size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AgriSmartAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppBrand.text)),
                Text('Rice Farming Assistant', style: TextStyle(fontSize: 11, color: AppBrand.textMuted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: _newChat,
            icon: const Icon(Icons.edit_square, color: AppBrand.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          if (scan != null) _ScanContextBanner(scan: scan),
          Expanded(
            child: _messages.isEmpty && !hasUserMsgs
                ? _EmptyState(onTap: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length + (_typing ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_typing && i == _messages.length) return const _TypingBubble();
                      return _MessageBubble(message: _messages[i]);
                    },
                  ),
          ),
          if (!hasUserMsgs && !_typing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _starters.map((s) => _StarterChip(label: s, onTap: () => _send(s))).toList(),
              ),
            ),
          _Composer(
            controller: _input,
            typing: _typing,
            onSend: () => _send(),
          ),
        ],
      ),
    );
  }
}

class _ScanContextBanner extends StatelessWidget {
  final ScanResult scan;
  const _ScanContextBanner({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppBrand.diseaseColor(scan.disease).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppBrand.diseaseColor(scan.disease).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.biotech_rounded, color: AppBrand.diseaseColor(scan.disease)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Latest scan: ${scan.displayName} (${(scan.confidence * 100).toStringAsFixed(0)}% — ${scan.severity})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppBrand.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final void Function(String) onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 80, animate: true),
            const SizedBox(height: 20),
            const Text('How can I help you today?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Magtanong about rice diseases, treatment, o DA office', style: TextStyle(color: AppBrand.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const AppLogo(size: 32),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppBrand.primary : AppBrand.surface,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: isUser ? null : AppBrand.cardShadow,
                border: isUser ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppBrand.text,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 42),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const AppLogo(size: 32),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppBrand.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppBrand.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7, height: 7,
                decoration: const BoxDecoration(color: AppBrand.textMuted, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat()).fade(begin: 0.3, duration: 500.ms, delay: (i * 150).ms)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StarterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppBrand.accent.withValues(alpha: 0.1),
      side: BorderSide(color: AppBrand.accent.withValues(alpha: 0.3)),
      onPressed: onTap,
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool typing;
  final VoidCallback onSend;

  const _Composer({required this.controller, required this.typing, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + 12),
      decoration: BoxDecoration(
        color: AppBrand.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Message AgriSmartAI...',
                hintStyle: TextStyle(color: AppBrand.textMuted),
                filled: true,
                fillColor: AppBrand.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: typing ? AppBrand.textMuted : AppBrand.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: typing ? null : onSend,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
