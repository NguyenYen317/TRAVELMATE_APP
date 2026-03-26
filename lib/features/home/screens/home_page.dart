import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/search_bar.dart';
import '../widgets/ai_hero_card.dart';
import '../widgets/location_list.dart';
import '../widgets/category_list.dart';
import '../widgets/trip_summary.dart';
import '../widgets/social_snippet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const HomeHeader(),
            const HomeSearchBar(),
            const AIHeroCard(),
            const LocationList(title: 'Địa điểm gần bạn'),
            const CategoryList(),
            const TripSummary(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text(
                  'Cộng đồng du lịch',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SocialSnippet(),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}
