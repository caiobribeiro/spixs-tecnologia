import 'package:flutter/material.dart';
import 'package:spixs_tecnologia/app_dependency_injection.dart';

import '../../../../app_routes.dart';
import '../widgets/auth_lock_screen.dart';
import 'home_viewmodel.dart';

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

  /// Evita navegar duas vezes para o formulário de endereços.
  bool _navigatedToForm = false;

  @override
  void initState() {
    super.initState();
    // Exige a autenticação nativa antes de liberar o restante do app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewmodel.authenticate();
    });
    _viewmodel.isAuthenticated.addListener(_onAuthenticationChanged);
  }

  @override
  void dispose() {
    _viewmodel.isAuthenticated.removeListener(_onAuthenticationChanged);
    super.dispose();
  }

  /// Após o login com `local_auth`, a navegação leva ao formulário de
  /// endereços ([RoutesFormView]) em substituição à tela de bloqueio.
  void _onAuthenticationChanged() {
    if (!mounted || _navigatedToForm || !_viewmodel.isAuthenticated.value) {
      return;
    }
    _navigatedToForm = true;
    Navigator.of(context).pushReplacementNamed(AppRoute.form.path);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _viewmodel.isAuthenticated,
      builder: (context, isAuthenticated, _) {
        if (isAuthenticated) {
          // A navegação para o formulário é disparada por
          // [_onAuthenticationChanged]; este é apenas um fallback vazio
          // durante a transição de rota.
          return const Scaffold();
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
}
