import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/search_provider.dart';
import 'place_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilterType;

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá địa điểm'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          searchProvider.searchAutocomplete('');
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                searchProvider.searchAutocomplete(value);
                setState(() {});
              },
            ),
          ),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Nhà hàng', 'nhà hàng', searchProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Khách sạn', 'khách sạn', searchProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Điểm du lịch', 'điểm du lịch', searchProvider),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Results
          Expanded(
            child: searchProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildResultsList(searchProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type, SearchProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilterType == type,
      selectedColor: colorScheme.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: _selectedFilterType == type ? Colors.white : colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: _selectedFilterType == type
            ? colorScheme.primary
            : colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        final isCurrentlySelected = _selectedFilterType == type;

        if (isCurrentlySelected) {
          setState(() {
            _selectedFilterType = null;
          });
          provider.searchAutocomplete(_searchController.text);
          return;
        }

        setState(() {
          _selectedFilterType = type;
        });
        provider.filterPlaces(type, query: _searchController.text);
      },
    );
  }

  Widget _buildResultsList(SearchProvider provider) {
    if (provider.searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: provider.searchResults.length,
        itemBuilder: (context, index) {
          final place = provider.searchResults[index];
          return _buildCardTile(
            context: context,
            title: place.name,
            subtitle: place.address,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaceDetailScreen(place: place),
                ),
              );
            },
          );
        },
      );
    }

    if (provider.predictions.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: provider.predictions.length,
        itemBuilder: (context, index) {
          final prediction = provider.predictions[index];
          return _buildCardTile(
            context: context,
            title: prediction.description,
            onTap: () async {
              _searchController.text = prediction.description.split(',').first;
              final place = await provider.getDetails(prediction.placeId);
              if (place != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
                );
              }
            },
          );
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Gõ địa điểm du lịch bạn muốn khám phá.'),
        ],
      ),
    );
  }

  Widget _buildCardTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(Icons.gps_fixed, color: colorScheme.primary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
