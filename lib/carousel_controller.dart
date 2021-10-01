import 'package:flutter/material.dart';

class CarouselController {
  Function(int, {Duration? duration, Curve? curve})? goToPage;
  Function({Duration? duration, Curve? curve})? nextPage;
  Function({Duration? duration, Curve? curve})? previousPage;
  CarouselController({
    this.goToPage,
    this.nextPage,
    this.previousPage,
  });
}
