import 'package:alba/routing.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class PassMiddleware extends Middleware {
  @override
  void handle(RouteDefinition subject, next) {
    next(subject);
  }
}

class AbortMiddleware extends Middleware {
  @override
  void handle(RouteDefinition subject, next) {
    // This middleware doesn't call next.
  }
}

RouterRoot createRouter(
    {String Function()? initialPath, GlobalKey<NavigatorState>? navigatorKey}) {
  return RouterRoot(
    configuration: RouterRootConfiguration(
      routeDefinitions: [
        RouteDefinition('/', (context, parameters) => const HomeScreen()),
        RouteDefinition(
            '/first-screen', (context, parameters) => const FirstScreen()),
        RouteDefinition(
            '/second-screen', (context, parameters) => const FirstScreen()),
        RouteDefinition(
          '/pass-middleware',
          (context, parameters) => const FirstScreen(),
          middlewares: () => [PassMiddleware()],
        ),
        RouteDefinition(
          '/abort-middleware',
          (context, parameters) => const FirstScreen(),
          middlewares: () => [AbortMiddleware()],
        ),
        RouteDefinition(
            '/not-found', (context, parameters) => const NotFoundScreen()),
      ],
      initialPath: initialPath,
      navigatorKey: navigatorKey,
    ),
    builder: (
      BuildContext context,
      AlbaRouterDelegate pageRouterDelegate,
      AlbaRouteInformationParser pageRouteInformationParser,
    ) {
      return MaterialApp.router(
        restorationScopeId: 'app',
        routerDelegate: pageRouterDelegate,
        routeInformationParser: pageRouteInformationParser,
      );
    },
  );
}

void main() {
  group('Router', () {
    testWidgets('shows the initial route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('shows the initial custom route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter(initialPath: () => '/first-screen'));

      expect(find.byType(FirstScreen), findsOneWidget);
    });

    testWidgets('pushes a route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsOneWidget);
    });

    testWidgets('pushes an undefined route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/non-exist-route');
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
    });

    testWidgets('pushes a route with a middleware',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/pass-middleware');
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsOneWidget);
    });

    testWidgets('pushes a route with a middleware that abort the navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/abort-middleware');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('sets the navigator key', (WidgetTester tester) async {
      var navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(createRouter(navigatorKey: navigatorKey));

      expect(navigatorKey.currentState, isA<NavigatorState>());
    });

    testWidgets('pops a route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsNothing);
    });

    testWidgets('pops a route (using Navigator)', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsNothing);
    });

    testWidgets('removes a route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).push('/second-screen');
      await tester.pumpAndSettle();

      tester
          .state<RouterState>(find.byType(Router))
          .removeRoute('/first-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsNothing);
    });

    testWidgets('restores routes', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsOneWidget);

      await tester.restartAndRestore();

      expect(find.byType(FirstScreen), findsOneWidget);

      tester.state<RouterState>(find.byType(Router)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('removes all routes and push a new one',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).push('/second-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).removeAllAndPush('/');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
