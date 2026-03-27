import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../search/provider/search_provider.dart';
import '../../search/screens/place_detail_screen.dart';
import '../../../data/models/place.dart';

class LocationList extends StatelessWidget {
  final String title;
  const LocationList({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          final places = provider.nearbyPlaces;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),
              provider.isLoading && places.isEmpty
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          return _buildLocationCard(context, places[index]);
                        },
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, Place place) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailScreen(place: place),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                height: 132,
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                child: place.imageUrl != null
                    ? Image.network(place.imageUrl!, fit: BoxFit.cover)
                    : Icon(
                        Icons.image_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 36,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              place.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                Text(
                  ' ${place.rating}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(Icons.location_on, size: 14, color: colorScheme.primary),
                Text(
                  ' Gần bạn',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
