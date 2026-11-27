/// Fixed body regions. Paired sides share one area.
enum BodyArea {
  head,
  neck,
  shoulders,
  chest,
  upperBack,
  arms,
  wrists,
  hands,
  core,
  lowerBack,
  hips,
  thighs,
  knees,
  calves,
  ankles,
  feet,
  wholeBody,
  other;

  String get label => switch (this) {
    BodyArea.head => 'Head',
    BodyArea.neck => 'Neck',
    BodyArea.shoulders => 'Shoulders',
    BodyArea.chest => 'Chest',
    BodyArea.upperBack => 'Upper back',
    BodyArea.arms => 'Arms',
    BodyArea.wrists => 'Wrists',
    BodyArea.hands => 'Hands',
    BodyArea.core => 'Core',
    BodyArea.lowerBack => 'Lower back',
    BodyArea.hips => 'Hips',
    BodyArea.thighs => 'Thighs',
    BodyArea.knees => 'Knees',
    BodyArea.calves => 'Calves',
    BodyArea.ankles => 'Ankles',
    BodyArea.feet => 'Feet',
    BodyArea.wholeBody => 'Whole-body',
    BodyArea.other => 'Other',
  };

  static BodyArea parse(String value) => values.byName(value);
}
