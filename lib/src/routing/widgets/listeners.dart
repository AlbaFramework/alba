import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../routing.dart';
import '../router_state.dart';
import 'page_router.dart';

/// A push event callback.
typedef PushEventCallback = void Function(ActiveRoute activeRoute);

/// A pop event callback.
///
/// The type argument `T` is the page's result type.
typedef PopEventCallback<T> = void Function(ActiveRoute activeRoute, T? result);

/// A listener for router events.
///
/// The type argument `T` is the page's result type, as used by [PopEventCallback].
/// The type `void` may be used if the route does not return a value.
abstract class PageListener<T> extends StatefulWidget {
  /// The callback which is called when a page is pushed.
  final PushEventCallback? onPush;

  /// The callback which is called when a page is popped.
  final PopEventCallback<T>? onPop;

  /// The widget below this widget in the tree.
  final Widget? child;

  /// Creates a [PageListener].
  const PageListener({
    this.onPush,
    this.onPop,
    this.child,
    Key? key,
  }) : super(key: key);

  @override
  _PageListenerState<T> createState() => _PageListenerState<T>();

  /// Test if the page matches.
  bool isMatch(ActiveRoute activeRoute);
}

class _PageListenerState<T> extends State<PageListener<T>> {
  late final StreamSubscription<RouterEvent> _routerEventStreamSubscription;

  @override
  void initState() {
    super.initState();
    _routerEventStreamSubscription =
        PageRouter
            .of(context)
            .eventStream
            .listen(_notifyEvent);
  }

  @override
  void dispose() {
    super.dispose();
    _routerEventStreamSubscription.cancel();
  }

  void _notifyEvent(RouterEvent event) {
    if (!widget.isMatch(event.activeRoute)) {
      return;
    }

    if (event is PopEvent) {
      widget.onPop?.call(event.activeRoute, event.result as T);
    } else if (event is PushEvent) {
      widget.onPush?.call(event.activeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? Container();
  }
}

/// A router listener for a specific page path.
class PathPageListener<T> extends PageListener<T> {
  final String _path;

  /// Creates a [PathPageListener].
  const PathPageListener({
    required String path,
    PushEventCallback? onPush,
    PopEventCallback<T>? onPop,
    Widget? child,
    Key? key,
  })
      : _path = path,
        super(onPush: onPush, onPop: onPop, child: child, key: key);

  @override
  bool isMatch(ActiveRoute activeRoute) => _path == activeRoute.path;
}

/// A router listener for a specific page id.
class IdPageListener<T> extends PageListener<T> {
  final String _id;

  /// Creates a [IdPageListener].
  const IdPageListener({
    required String id,
    PushEventCallback? onPush,
    PopEventCallback<T>? onPop,
    Widget? child,
    Key? key,
  })
      : _id = id,
        super(onPush: onPush, onPop: onPop, child: child, key: key);

  @override
  bool isMatch(ActiveRoute activeRoute) => _id == activeRoute.id;
}

/// A router listener for several page paths or page ids.
class MultiPageListener<T> extends PageListener<T> {
  final List<String>? _paths;
  final List<String>? _ids;

  /// Creates a [MultiPageListener].
  const MultiPageListener({
    PushEventCallback? onPush,
    PopEventCallback<T>? onPop,
    Widget? child,
    List<String>? paths,
    List<String>? ids,
    Key? key,
  })
      : _paths = paths,
        _ids = ids,
        super(onPush: onPush, onPop: onPop, child: child, key: key);

  @override
  bool isMatch(ActiveRoute activeRoute) =>
      (null != _paths && _paths!.any((path) => path == activeRoute.path)) ||
          (null != _ids && _ids!.any((id) => id == activeRoute.id));
}
