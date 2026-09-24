import 'package:flutter/material.dart';
import 'package:spixs_tecnologia/app_dependency_injection.dart';

import '../../../../app_routes.dart';
import '../widgets/auth_lock_screen.dart';
import 'home_viewmodel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeViewmodel _viewmodel = getIt<HomeViewmodel>();

  bool _navigatedToForm = false;

  @override
  void initState() {
    super.initState();

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
