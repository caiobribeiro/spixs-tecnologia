import 'package:flutter/material.dart';

import '../../../app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Home')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.map),
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoute.map.path);
        },
      ),
    );
  }
}
