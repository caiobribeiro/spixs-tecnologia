import 'package:flutter/material.dart';

import '../../../app_dependency_injection.dart';
import '../../../app_routes.dart';
import 'home_viewmodel.dart';
import 'widgets/auth_lock_screen.dart';

/// Home screen entry point.
///
/// Atua como portão do app: o conteúdo e a navegação para os demais módulos
/// só ficam acessíveis depois da autenticação nativa (biometria, senha, PIN
/// ou padrão do dispositivo) via `local_auth` — Android/iOS.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeViewmodel _viewmodel = getIt<HomeViewmodel>();

  @override
  void initState() {
    super.initState();
    // Exige a autenticação nativa antes de liberar o restante do app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewmodel.authenticate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _viewmodel.isAuthenticated,
      builder: (context, isAuthenticated, _) {
        if (isAuthenticated) {
          return _buildHomeContent(context);
        }
        return AnimatedBuilder(
          animation: _viewmodel.authenticateCommand,
          builder: (context, _) {
            return AuthLockScreen(
              isAuthenticating: _viewmodel.authenticateCommand.running,
              errorMessage: _viewmodel.authenticationError,
              onUnlock: _viewmodel.authenticate,
            );
          },
        );
      },
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Home')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.map),
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoute.map.path);
        },
      ),
    );
  }
}