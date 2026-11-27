enum Sensation {
  muscleSoreness,
  hurt,
  stingingPain,
  fine,
  tight,
  tingling;

  String get label => switch (this) {
    Sensation.muscleSoreness => 'Muscle soreness',
    Sensation.hurt => 'Hurt',
    Sensation.stingingPain => 'Stinging pain',
    Sensation.fine => 'Fine',
    Sensation.tight => 'Tight',
    Sensation.tingling => 'Tingling',
  };

  static Sensation parse(String value) => values.byName(value);
}
