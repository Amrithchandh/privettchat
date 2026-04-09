import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../services/auth_service.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Implement Responsive Layout (Dual Pane for wide screens)
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    if (isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildMobileLayout(),
            ),
            const VerticalDivider(width: 1, color: Colors.grey),
            const Expanded(
              flex: 2,
              child: ChatScreen(), // Hardcoded active chat for 1:1 dual pane
            ),
          ],
        ),
      );
    }

    return _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PrivateApp", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await _authService.signOut();
                if (mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: "CHATS"),
            Tab(text: "STATUS"),
            Tab(text: "CALLS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chats Tab - Just jumping to the single chat room instead of a list for the 1:1 setup
          ListView(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: const Text("Partner", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Tap to view your private chat..."),
                trailing: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Now", style: TextStyle(color: Colors.green, fontSize: 12)),
                    SizedBox(height: 5),
                    CircleAvatar(radius: 10, backgroundColor: Colors.green, child: Text("1", style: TextStyle(color: Colors.white, fontSize: 10))),
                  ],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                },
              )
            ],
          ),
          // Status Tab Placeholder
          ListView(
            children: [
              ListTile(
                leading: Stack(
                  children: [
                    const CircleAvatar(radius: 25, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 15),
                      ),
                    )
                  ],
                ),
                title: const Text("My status", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Tap to add status update"),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Recent updates", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              const Center(child: Text("No recent updates", style: TextStyle(color: Colors.grey))),
            ],
          ),
          // Calls Tab Placeholder
          ListView(
            children: const [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.link, color: Colors.white),
                ),
                title: Text("Create call link", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Share a link for your WhatsApp call"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Recent", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              Center(child: Text("No recent calls", style: TextStyle(color: Colors.grey))),
            ],
          )
        ],
      ),
      floatingActionButton: _getFAB(),
    );
  }

  Widget _getFAB() {
    if (_tabController.index == 0) {
      return FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        onPressed: () {},
        child: const Icon(Icons.message, color: Colors.white),
      );
    } else if (_tabController.index == 1) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.grey[200],
            onPressed: () {},
            child: const Icon(Icons.edit, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: const Color(0xFF25D366),
            onPressed: () {},
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      );
    } else {
      return FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        onPressed: () {},
        child: const Icon(Icons.add_call, color: Colors.white),
      );
    }
  }
}
