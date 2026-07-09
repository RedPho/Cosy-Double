import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection.dart' as di;
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/room/room_bloc.dart';
import 'presentation/blocs/shop/shop_bloc.dart';
import 'presentation/blocs/canvas/canvas_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/screens/lobby/lobby_screen.dart';
import 'presentation/screens/focus/focus_screen.dart';
import 'presentation/screens/summary/summary_screen.dart';
import 'presentation/screens/oasis/oasis_screen.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const CozyDoubleApp());
}

class CozyDoubleApp extends StatefulWidget {
  const CozyDoubleApp({super.key});

  @override
  State<CozyDoubleApp> createState() => _CozyDoubleAppState();
}

class _CozyDoubleAppState extends State<CozyDoubleApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    
    _router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authState = di.sl<AuthBloc>().state;
        
        final isLoggingIn = state.matchedLocation == '/login';
        
        if (authState is Unauthenticated && !isLoggingIn) {
          return '/login';
        }
        if (authState is Authenticated && isLoggingIn) {
          return '/lobby';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/lobby',
          builder: (context, state) => const LobbyScreen(),
        ),
        GoRoute(
          path: '/focus/:roomId',
          builder: (context, state) {
            final roomId = int.parse(state.pathParameters['roomId']!);
            return FocusScreen(roomId: roomId);
          },
        ),
        GoRoute(
          path: '/summary',
          builder: (context, state) => const SummaryScreen(),
        ),
        GoRoute(
          path: '/oasis',
          builder: (context, state) => const OasisScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(AppStarted()),
        ),
        BlocProvider<RoomBloc>(
          create: (context) => di.sl<RoomBloc>(),
        ),
        BlocProvider<ShopBloc>(
          create: (context) => di.sl<ShopBloc>(),
        ),
        BlocProvider<CanvasBloc>(
          create: (context) => di.sl<CanvasBloc>(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // ThemeCubit needs the CanvasBloc from the widget tree, so we
          // create it inside a Builder that sits below MultiBlocProvider.
          return BlocProvider<ThemeCubit>(
            create: (ctx) => ThemeCubit(canvasBloc: ctx.read<CanvasBloc>()),
            child: BlocBuilder<ThemeCubit, ThemeData>(
              builder: (context, themeData) {
                return BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    _router.refresh();
                  },
                  child: MaterialApp.router(
                    title: 'Cozy Double',
                    theme: themeData,
                    routerConfig: _router,
                    debugShowCheckedModeBanner: false,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
