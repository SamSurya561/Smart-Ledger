import 'package:flutter/material.dart';
import '../../widgets/add_batch_dialog.dart';
import 'pages/batches_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/settings_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Default to the "Dashboard" page

  // A list of the pages to be displayed in the body
  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    BatchesPage(),
    SettingsPage(),
  ];

  // A list of titles corresponding to each page
  static const List<String> _pageTitles = <String>[
    'Dashboard',
    'Batches',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        // The actions have been moved to the SettingsPage
      ),
      // Use IndexedStack to keep the state of each page alive when switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Batches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      // The FloatingActionButton is only shown when the "Batches" page is active
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                // This calls the function from our separate dialog file
                showAddBatchDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
