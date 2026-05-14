import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:raspucat/common/widgets/cards/phone_mockup.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';

const _kCarouselHeight = 420.0;
const _kPhoneAspectRatio = 9 / 19.5;

class LiveAppCarousel extends StatefulWidget {
  const LiveAppCarousel({super.key, required this.screenshots});

  final List<String> screenshots;

  @override
  State<LiveAppCarousel> createState() => _LiveAppCarouselState();
}

class _LiveAppCarouselState extends State<LiveAppCarousel> {
  final CarouselSliderController _ctrl = CarouselSliderController();
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _ctrl,
          itemCount: widget.screenshots.length,
          options: CarouselOptions(
            height: _kCarouselHeight,
            viewportFraction: 0.45,
            enlargeCenterPage: true,
            enlargeFactor: 0.25,
            enableInfiniteScroll: widget.screenshots.length > 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (i, _) => setState(() => _current = i),
          ),
          itemBuilder: (_, i, __) => AspectRatio(
            aspectRatio: _kPhoneAspectRatio,
            child: PhoneMockup(
              child: Image.asset(
                widget.screenshots[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        const SizedBox(height: ESizes.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.screenshots.length,
            (i) => GestureDetector(
              onTap: () => _ctrl.animateToPage(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? ESizes.md : ESizes.xs,
                height: ESizes.xs,
                decoration: BoxDecoration(
                  color: i == _current ? EColors.primary : EColors.primary.withAlpha(77),
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusXxl),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
