import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'bot',
      'text': 'Hello! I am your Cabbage Assistant. How can I help you today? You can ask me about diseases, planting, or harvesting.'
    },
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final provider = context.read<AppProvider>();
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || provider.isChatLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': prompt});
      _controller.clear();
    });
    _scrollToBottom();

    final response = await provider.askAi(prompt);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'bot', 'text': response});
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTwi = provider.language == 'Twi';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: colorScheme.primary,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  centerTitle: true,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (isTwi ? 'Kabeji Mmoawa' : 'AI Assistant').toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10, letterSpacing: 3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Online'.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.secondary, fontSize: 7, letterSpacing: 1),
                        ),
                      ],
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                            ),
                          ),
                        ),
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(Icons.psychology_rounded, size: 150, color: Colors.white.withValues(alpha: 0.05)),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                      onSelected: (value) => provider.setAiModel(value),
                      tooltip: 'Select AI Model',
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Gemini', child: Text('Google Gemini (Fast)')),
                        const PopupMenuItem(value: 'Llama', child: Text('Meta Llama 3 (Smart)')),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _messages.length) {
                          return _buildTypingIndicator(colorScheme);
                        }
                        final msg = _messages[index];
                        final isBot = msg['role'] == 'bot';
                        return _buildMessageBubble(msg['text']!, isBot, theme, colorScheme);
                      },
                      childCount: _messages.length + (provider.isChatLoading ? 1 : 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildInputArea(provider, isTwi, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isBot, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: colorScheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isBot ? theme.cardColor : colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isBot ? 4 : 20),
                  bottomRight: Radius.circular(isBot ? 20 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isBot 
                        ? Colors.black.withValues(alpha: 0.03) 
                        : colorScheme.primary.withValues(alpha: 0.1), 
                    blurRadius: 12, 
                    offset: const Offset(0, 6)
                  )
                ],
              ),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              child: Text(
                text,
                style: TextStyle(
                  color: isBot ? colorScheme.onSurface : Colors.white,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: isBot ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.black, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 44, bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cabbage Doctor is thinking...',
                  style: TextStyle(
                    color: colorScheme.primary.withValues(alpha: 0.6), 
                    fontSize: 12, 
                    fontWeight: FontWeight.w700, 
                    fontStyle: FontStyle.italic
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppProvider provider, bool isTwi, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
              ),
              child: TextField(
                controller: _controller,
                enabled: !provider.isChatLoading,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: isTwi ? 'Bisa asɛm bi...' : 'Type a message...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: provider.isChatLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: provider.isChatLoading 
                      ? [Colors.grey, Colors.grey.shade400] 
                      : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  if (!provider.isChatLoading)
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
