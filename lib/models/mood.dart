import 'package:flutter/material.dart';

enum Mood {
  amazing,
  happy,
  neutral,
  sad,
  angry,
}

extension MoodX on Mood {
  String get emoji {
    switch (this) {
      case Mood.amazing:
        return '🤩';
      case Mood.happy:
        return '😊';
      case Mood.neutral:
        return '😐';
      case Mood.sad:
        return '😔';
      case Mood.angry:
        return '😡';
    }
  }

  String get label {
    switch (this) {
      case Mood.amazing:
        return 'Luar Biasa';
      case Mood.happy:
        return 'Senang';
      case Mood.neutral:
        return 'Biasa';
      case Mood.sad:
        return 'Sedih';
      case Mood.angry:
        return 'Kesal';
    }
  }

  Color get color {
    switch (this) {
      case Mood.amazing:
        return const Color(0xFFFFD6A5);
      case Mood.happy:
        return const Color(0xFFFDFFB6);
      case Mood.neutral:
        return const Color(0xFFCAFFBF);
      case Mood.sad:
        return const Color(0xFFA0C4FF);
      case Mood.angry:
        return const Color(0xFFFFADAD);
    }
  }

  int get score {
    switch (this) {
      case Mood.amazing:
        return 5;
      case Mood.happy:
        return 4;
      case Mood.neutral:
        return 3;
      case Mood.sad:
        return 2;
      case Mood.angry:
        return 1;
    }
  }
}
