import 'package:flutter/material.dart';

import '../domain/body_area.dart';
import '../domain/effective.dart';
import '../domain/movement_type.dart';
import '../domain/my_exercise.dart';
import '../domain/readiness.dart';
import '../state/app_model.dart';
import '../state/mending_scope.dart';
import 'movement_page.dart';
import 'movement_visual_view.dart';
import 'theme.dart';

/// Movements for [area], starred first, then catalog order.
List<MovementType> sortedForArea(AppModel model, BodyArea area) {
  final movements = model.catalog.forArea(area);
  final starred = [
    for (final movement in movements)
      if (model.findExercise(movement.id)?.starred ?? false) movement,
  ];
  return [
    ...starred,
    for (final movement in movements)
      if (!starred.contains(movement)) movement,
  ];
}

/// The movement list on the Body tab.
///
/// On a wide screen it is a side panel. With [area] null it shows a hint.
/// With [active] false the list is a greyed preview that does not take taps.
///
/// On a phone it is a pull-up sheet: pass the sheet's [scrollController] and
/// the pinned header's height. While [peeking], a tap on the title or a row
/// calls [onExpand] instead of opening the movement.
class AreaMovementsPanel extends StatelessWidget {
  const AreaMovementsPanel({
    super.key,
    required this.area,
    required this.active,
    this.onClose,
    this.scrollController,
    this.headerHeight,
    this.peeking = false,
    this.onExpand,
  }) : assert(scrollController == null || headerHeight != null);

  final BodyArea? area;
  final bool active;
  final VoidCallback? onClose;
  final ScrollController? scrollController;
  final double? headerHeight;
  final bool peeking;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final area = this.area;
    final controller = scrollController;
    final border = BorderSide(
      color: active ? mendingBlue : mendingInk.withValues(alpha: 0.18),
      width: 2,
    );
    if (controller != null) {
      return Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          side: border,
        ),
        child: area == null
            ? const SizedBox.shrink()
            : _SheetList(
                area: area,
                controller: controller,
                headerHeight: headerHeight!,
                peeking: peeking,
                onExpand: onExpand,
                onClose: onClose,
              ),
      );
    }
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: border,
      ),
      child: area == null
          ? const _Hint()
          : _AreaList(area: area, active: active, onClose: onClose),
    );
  }
}

class _SheetList extends StatelessWidget {
  const _SheetList({
    required this.area,
    required this.controller,
    required this.headerHeight,
    required this.peeking,
    this.onExpand,
    this.onClose,
  });

  final BodyArea area;
  final ScrollController controller;
  final double headerHeight;
  final bool peeking;
  final VoidCallback? onExpand;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final movements = sortedForArea(model, area);
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SheetHeader(
            height: headerHeight,
            label: area.label,
            onTap: peeking ? onExpand : null,
            onClose: onClose,
          ),
        ),
        if (movements.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text(
                'No movements for ${area.label} yet.',
                style: const TextStyle(color: mendingInk, fontSize: 16),
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: movements.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _MovementTile(
              movement: movements[index],
              active: true,
              onTap: peeking ? onExpand : null,
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}

class _SheetHeader extends SliverPersistentHeaderDelegate {
  const _SheetHeader({
    required this.height,
    required this.label,
    this.onTap,
    this.onClose,
  });

  /// Everything inside is sized from this, so the header scales with the page.
  final double height;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final handleGap = height * 0.14;
    final handleHeight = height * 0.09;
    final button = height * 0.72;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(height: handleGap),
            Container(
              width: height * 0.8,
              height: handleHeight,
              decoration: BoxDecoration(
                color: mendingInk.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(handleHeight / 2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: height * 0.45,
                  right: height * 0.1,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mendingBlue,
                          fontSize: height * 0.36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        tooltip: 'Close',
                        onPressed: onClose,
                        iconSize: button * 0.6,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tightFor(
                          width: button,
                          height: button,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SheetHeader oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.label != label ||
        oldDelegate.onTap != onTap ||
        oldDelegate.onClose != onClose;
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Point at a body part to see its movements.',
          textAlign: TextAlign.center,
          style: TextStyle(color: mendingInk.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class _AreaList extends StatelessWidget {
  const _AreaList({required this.area, required this.active, this.onClose});

  final BodyArea area;
  final bool active;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final movements = sortedForArea(model, area);
    final list = movements.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No movements for ${area.label} yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: mendingInk, fontSize: 16),
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: movements.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _MovementTile(movement: movements[index], active: active),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  area.label,
                  style: TextStyle(
                    color: active ? mendingBlue : mendingInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (active && onClose != null)
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
        if (!active)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Click to choose',
              style: TextStyle(color: mendingInk.withValues(alpha: 0.55)),
            ),
          ),
        Expanded(
          child: active
              ? list
              : IgnorePointer(child: Opacity(opacity: 0.45, child: list)),
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.movement,
    required this.active,
    this.onTap,
  });

  final MovementType movement;
  final bool active;

  /// Replaces opening the movement, and the star button, while set.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final exercise = model.findExercise(movement.id);
    final starred = exercise?.starred ?? false;
    final sets = effectiveSets(movement, exercise);
    final reps = effectiveReps(movement, exercise);
    final cooldown = effectiveCooldown(movement, exercise);
    final status = starred
        ? exerciseStatus(
            now: model.now(),
            completedTimes: completionTimes(
              model.completions,
              currentUser,
              movement.id,
            ),
            cooldown: cooldown,
          ).label
        : null;
    final starIcon = Icon(
      starred ? Icons.star_rounded : Icons.star_border_rounded,
      color: starred ? mendingBlue : mendingInk,
    );
    return ListTile(
      leading: MovementThumbnail(visual: model.catalog.visualFor(movement.id)),
      title: Text(
        movement.name,
        style: const TextStyle(color: mendingInk, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        status == null
            ? prescription(sets, reps, cooldown, seconds: movement.timed)
            : '${prescription(sets, reps, cooldown, seconds: movement.timed)}\n$status',
      ),
      isThreeLine: status != null,
      trailing: active && onTap == null
          ? IconButton(
              tooltip: starred ? 'Unstar' : 'Star',
              onPressed: () => model.setStarred(movement, !starred),
              icon: starIcon,
            )
          : Padding(padding: const EdgeInsets.all(8), child: starIcon),
      onTap:
          onTap ??
          (active
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MovementPage(movement: movement),
                  ),
                )
              : null),
    );
  }
}
