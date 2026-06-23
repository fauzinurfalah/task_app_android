import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'dashboard_screen.dart';
import 'task_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'join_task_helper.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final int _selectedIndex = 3;
  final _userService = UserService();
  final _searchController = TextEditingController();

  // ── DUMMY DATA ─────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _connections = [
    {
      'name': 'Luna Sterling',
      'username': '@luna_wave',
      'avatar': 'https://i.pravatar.cc/80?img=1',
      'online': true,
    },
    {
      'name': 'Atlas Neon',
      'username': '@atlas_n',
      'avatar': 'https://i.pravatar.cc/80?img=2',
      'online': true,
    },
    {
      'name': 'Nova Synth',
      'username': '@nova_synth',
      'avatar': 'https://i.pravatar.cc/80?img=3',
      'online': false,
    },
    {
      'name': 'Zero Cool',
      'username': '@zero_c',
      'avatar': null,
      'online': true,
    },
    {
      'name': 'Echo Ray',
      'username': '@echo_ray',
      'avatar': 'https://i.pravatar.cc/80?img=5',
      'online': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onUserChanged);
    _userService.loadUser();
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => JoinTaskHelper.show(context),
        backgroundColor: const Color(0xFFE91E8C),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tambah Tugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 24),
              _buildPageTitle(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildInviteCard(),
              const SizedBox(height: 28),
              _buildConnectionsSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── TOP BAR ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final photoUrl = _userService.photoUrl;
    return Stack(
      alignment: Alignment.center,
      children: [
        const Center(
          child: Text(
            'Tetugas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E8C),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Positioned(
          right: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Belum ada notifikasi baru'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: const Icon(Icons.notifications_outlined, color: Color(0xFF333333), size: 26),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF5C5C5C),
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── PAGE TITLE ────────────────────────────────────────────────────────────

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Network',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Connect, compete, and grow.',
          style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
        ),
      ],
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Find new friends...',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFFAAAAAA), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── INVITE CARD ───────────────────────────────────────────────────────────

  Widget _buildInviteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E8C), Color(0xFFFF6EC7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boost badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.bolt, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Boost Your Rank',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Invite Friends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Share your unique code to unlock special ranks and connect with more vaporwave enthusiasts.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          // Invite code box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TTG-X9V2-W',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFE91E8C),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Share Invite Link',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONNECTIONS LIST ──────────────────────────────────────────────────────

  Widget _buildConnectionsSection() {
    final onlineCount = _connections.where((c) => c['online'] == true).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Current Connections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$onlineCount Online',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(_connections.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildConnectionCard(_connections[i]),
          );
        }),
      ],
    );
  }

  Widget _buildConnectionCard(Map<String, dynamic> conn) {
    final avatarUrl = conn['avatar'] as String?;
    final isOnline = conn['online'] as bool;
    final initial = (conn['name'] as String)[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEEEEEE),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(initial,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF555555),
                        ))
                    : null,
              ),
              if (isOnline)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conn['name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  conn['username'],
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          // Message button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF555555)),
          ),
        ],
      ),
    );
  }



  // ── BOTTOM NAV ────────────────────────────────────────────────────────────

  static const _navLabels = ['Dashboard', 'Tasks', 'Calendar', 'Social'];
  static const _navIcons = [
    Icons.dashboard_rounded,
    Icons.check_box_outlined,
    Icons.calendar_month_outlined,
    Icons.people_outline,
  ];

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navLabels.length, (i) {
          final selected = _selectedIndex == i;
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
              } else if (i == 1) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TaskScreen()));
              } else if (i == 2) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
              } else if (i == 3) {
                setState(() {}); // already here
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_navIcons[i], size: 22,
                      color: selected ? const Color(0xFFE91E8C) : const Color(0xFFBBBBBB)),
                  const SizedBox(height: 3),
                  Text(
                    _navLabels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? const Color(0xFFE91E8C) : const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
