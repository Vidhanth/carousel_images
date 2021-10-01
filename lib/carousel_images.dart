library carouselimages;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_images/carousel_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
export 'carousel_controller.dart';
import 'dart:math' as math;

class CarouselImages extends StatefulWidget {
  ///List with assets path or url. Required
  final List<String> listImages;

  ///OnTap function. Index = index of active page. Optional
  final Function(int index)? onTap;

  ///Height of whole carousel. Required
  final double height;

  ///Possibility to cached images from network. Optional
  final bool cachedNetworkImage;

  ///Height of nearby images. From 0.0 to 1.0. Optional
  final double scaleFactor;

  ///Border radius of image. Optional
  final double? borderRadius;

  ///Vertical alignment of nearby images. Optional
  final Alignment? verticalAlignment;

  ///ViewportFraction. From 0.5 to 1.0. Optional
  final double viewportFraction;

  ///Carousel controller to control externally
  final CarouselController? controller;

  ///Carousel auto play
  final bool? autoPlay;

  ///Interval between every next page
  final Duration? autoPlayInterval;

  ///Auto play transition duration
  final Duration? autoPlayDuration;

  ///Curve for auto play animation
  final Curve autoPlayCurve;

  ///Make carousel infinite
  final bool? infinite;

  const CarouselImages({
    Key? key,
    required this.listImages,
    required this.height,
    this.onTap,
    this.cachedNetworkImage: false,
    this.scaleFactor = 1.0,
    this.borderRadius,
    this.verticalAlignment,
    this.viewportFraction = 0.9,
    this.autoPlay = false,
    this.autoPlayInterval,
    this.autoPlayCurve = Curves.fastOutSlowIn,
    this.infinite = true,
    this.controller,
    this.autoPlayDuration,
  })  : assert(scaleFactor > 0.0),
        assert(scaleFactor <= 1.0),
        super(key: key);

  @override
  _CarouselImagesState createState() => _CarouselImagesState();
}

class _CarouselImagesState extends State<CarouselImages> {
  late PageController _pageController;
  Timer? autoPlayTimer;
  double _currentPageValue = 0.0;
  bool overrideTimer = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
        viewportFraction: widget.viewportFraction.clamp(0.5, 1.0));
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page!;
        autoPlayTimer?.cancel();
        autoPlayTimer = null;
      });
    });
    if (widget.controller != null) {
      setupController();
    }
  }

  @override
  void dispose() {
    super.dispose();
    autoPlayTimer?.cancel();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (widget.autoPlay ?? false) {
      setupAutoPlay();
    }

    if (!(widget.autoPlay ?? false)) {
      autoPlayTimer?.cancel();
      autoPlayTimer = null;
    }

    return SizedBox(
      height: widget.height,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            return GestureDetector(
              onTapDown: (d) {
                overrideTimer = true;
              },
              onHorizontalDragUpdate: (d) {
                overrideTimer = true;
              },
              onTapUp: (d) {
                overrideTimer = false;
              },
              onHorizontalDragEnd: (d) {
                overrideTimer = false;
              },
              child: PageView.builder(
                physics: BouncingScrollPhysics(),
                controller: _pageController,
                itemCount: widget.listImages.length,
                itemBuilder: (context, position) {
                  double value = (1 -
                          ((_currentPageValue - position).abs() *
                              (1 - widget.scaleFactor)))
                      .clamp(0.0, 1.0);
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.0),
                    child: Stack(
                      children: <Widget>[
                        SizedBox(
                            height:
                                Curves.ease.transform(value) * widget.height,
                            child: child),
                        Align(
                          alignment: widget.verticalAlignment != null
                              ? widget.verticalAlignment!
                              : Alignment.center,
                          child: SizedBox(
                            height:
                                Curves.ease.transform(value) * widget.height,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  widget.borderRadius != null
                                      ? widget.borderRadius!
                                      : 16.0),
                              child: Transform.translate(
                                  offset: Offset(
                                      (_currentPageValue - position) *
                                          width /
                                          4 *
                                          math.pow(widget.viewportFraction, 3),
                                      0),
                                  child: widget.listImages[position]
                                          .startsWith('http')
                                      ? widget.cachedNetworkImage
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  widget.listImages[position],
                                              imageBuilder: (context, image) =>
                                                  GestureDetector(
                                                onTap: () {
                                                  widget.onTap?.call(position);
                                                  overrideTimer = false;
                                                },
                                                child: Image(
                                                    image: image,
                                                    fit: BoxFit.fitHeight),
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                widget.onTap?.call(position);
                                                overrideTimer = false;
                                              },
                                              child: FadeInImage.memoryNetwork(
                                                placeholder: kTransparentImage,
                                                image:
                                                    widget.listImages[position],
                                                fit: BoxFit.fitHeight,
                                              ),
                                            )
                                      : GestureDetector(
                                          onTap: () {
                                            widget.onTap?.call(position);
                                            overrideTimer = false;
                                          },
                                          child: Image.asset(
                                            widget.listImages[position],
                                            fit: BoxFit.fitHeight,
                                          ),
                                        )),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void setupController() {
    widget.controller!.previousPage = ({Curve? curve, Duration? duration}) {
      autoPlayTimer?.cancel();
      autoPlayTimer = null;
      int index = _currentPageValue.toInt();
      if (index == 0 && (widget.infinite ?? false)) {
        _currentPageValue = widget.listImages.length - 1;
        _pageController.animateToPage(
          widget.listImages.length - 1,
          duration: duration ?? Duration(milliseconds: 400),
          curve: curve ?? Curves.fastOutSlowIn,
        );
      } else {
        _currentPageValue--;
        _pageController.previousPage(
          duration: duration ?? Duration(milliseconds: 400),
          curve: curve ?? Curves.fastOutSlowIn,
        );
      }
    };
    widget.controller!.nextPage = ({Curve? curve, Duration? duration}) {
      autoPlayTimer?.cancel();
      autoPlayTimer = null;
      int index = _currentPageValue.toInt();
      if (index == (widget.listImages.length - 1) &&
          (widget.infinite ?? false)) {
        _currentPageValue = 0;
        _pageController.animateToPage(
          0,
          duration: duration ?? Duration(milliseconds: 400),
          curve: curve ?? Curves.fastOutSlowIn,
        );
      } else {
        _currentPageValue++;
        _pageController.nextPage(
          duration: duration ?? Duration(milliseconds: 400),
          curve: curve ?? Curves.fastOutSlowIn,
        );
      }
    };
    widget.controller!.goToPage = (index, {Curve? curve, Duration? duration}) {
      autoPlayTimer?.cancel();
      autoPlayTimer = null;
      _pageController.animateToPage(
        index,
        duration: duration ?? Duration(milliseconds: 400),
        curve: curve ?? Curves.fastOutSlowIn,
      );
    };
  }

  void setupAutoPlay() {
    autoPlayTimer ??= Timer.periodic(
      widget.autoPlayInterval ?? Duration(seconds: 3),
      (timer) {
        if (overrideTimer) return;
        int index = _pageController.page?.toInt() ?? 0;
        if (index == widget.listImages.length - 1) {
          _pageController.animateToPage(
            0,
            duration: widget.autoPlayDuration ?? Duration(milliseconds: 400),
            curve: widget.autoPlayCurve,
          );
        } else {
          _pageController.nextPage(
            duration: widget.autoPlayDuration ?? Duration(milliseconds: 400),
            curve: widget.autoPlayCurve,
          );
        }
      },
    );
  }
}
