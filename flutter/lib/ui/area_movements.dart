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
      if (model.findExercise(movement.name)?.starred ?? false) movement,
  ];
  return [
    ...starred,
    for (final movement in movements)
      if (!starred.contains(movement)) movement,
  ];
}

/// Height of the pinned handle and title at the top of the pull-up sheet.
const sheetHeaderHeight = 44.0;

/// Height of one two-line movement row.
const movementRowHeight = 72.0;

/// The movement list on the Body tab.
///
/// On a wide screen it is a side panel. With [area] null it shows a hint.
/// With [active] false the list is a greyed preview that does not take taps.
///
/// On a phone it is a pull-up sheet: pass the sheet's [scrollController].
/// While [peeking], a tap on the title or a row calls [onExpand] instead of
/// opening the movement.
class AreaMovementsPanel extends StatelessWidget {
  const AreaMovementsPanel({
    super.key,
    required this.area,
    required this.active,
    this.onClose,
    this.scrollController,
    this.peeking = false,
    this.onExpand,
  });

  final BodyArea? area;
  final bool active;
  final VoidCallback? onClose;
  final ScrollController? scrollController;
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
    required this.peeking,
    this.onExpand,
    this.onClose,
  });

  final BodyArea area;
  final ScrollController controller;
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
  const _SheetHeader({required this.label, this.onTap, this.onClose});

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  double get minExtent => sheetHeaderHeight;

  @override
  double get maxExtent => sheetHeaderHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 6),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: mendingInk.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: mendingBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        tooltip: 'Close',
                        onPressed: onClose,
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
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
    return oldDelegate.label != label ||
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
    final exercise = model.findExercise(movement.name);
    final starred = exercise?.starred ?? false;
    final sets = effectiveSets(movement, exercise);
    final reps = effectiveReps(movement, exercise);
    final cooldown = effectiveCooldown(movement, exercise);
    final status = starred
        ? exerciseStatus(
            now: model.now(),
            completedAt: latestCompletionAt(
              model.completions,
              currentUser,
              movement.name,
            ),
            cooldownDays: cooldown,
          ).label
        : null;
    final starIcon = Icon(
      starred ? Icons.star_rounded : Icons.star_border_rounded,
      color: starred ? mendingBlue : mendingInk,
    );
    return ListTile(
      leading: MovementThumbnail(
        visual: model.catalog.visualFor(movement.name),
      ),
      title: Text(
        movement.name,
        style: const TextStyle(color: mendingInk, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        status == null
            ? prescription(sets, reps, cooldown)
            : '${prescription(sets, reps, cooldown)}\n$status',
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
