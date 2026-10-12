import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconly/iconly.dart';

import '../../model/item_model.dart';
import '../../model/price_model.dart';
import '../../model/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/shop_provider.dart';
import '../Notification_screen/notification_screen.dart';
import '../shop/report_price_screen.dart';
import '../complaints/complaint_form_screen.dart';
import '../shop/shop_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String _searchQuery = '';

  bool showFab = true;

  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        showFab) {
      setState(() {
        showFab = false;
      });
    } else if (scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !showFab) {
      setState(() {
        showFab = true;
      });
    }
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final user = context.read<AuthProvider>().userModel;

      if (user == null) return;

      context.read<ItemProvider>().fetchItems();

      context.read<PriceProvider>().fetchPricesByUniversity(user.university);

      if (user.isAdmin) {
        context.read<PriceProvider>().fetchPriceReportsByUniversity(
          user.university,
        );
      } else {
        context.read<PriceProvider>().fetchMyPriceReports(user.uid);
      }

      context.read<ShopProvider>().fetchShopsByUniversity(
        user.university,
        user.uid,
        isAdmin: user.isAdmin,
      );
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';

    return 'Good evening';
  }

  String _normalizeCategory(String category) {
    final check = category.trim().toLowerCase();

    if (check.contains('food') ||
        check.contains('drink') ||
        check.contains('snack') ||
        check.contains('grocer') ||
        check.contains('provision') ||
        check.contains('eat')) {
      return 'Food';
    }

    if (check.contains('station') ||
        check.contains('book') ||
        check.contains('pen') ||
        check.contains('write') ||
        check.contains('office') ||
        check.contains('copy')) {
      return 'Stationery';
    }

    if (check.contains('elect') ||
        check.contains('phone') ||
        check.contains('gadget') ||
        check.contains('tech') ||
        check.contains('laptop') ||
        check.contains('charge')) {
      return 'Electronics';
    }

    return 'Other';
  }

  Item _findItem(Price price, List<Item> items) {
    final itemId = price.itemId.trim().toLowerCase();

    return items.firstWhere(
      (item) => item.id.trim().toLowerCase() == itemId,
      orElse: () => items.firstWhere(
        (item) => item.name.trim().toLowerCase() == itemId,
        orElse: () =>
            Item(id: price.itemId, name: price.itemId, category: 'Other'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceProvider = context.watch<PriceProvider>();
    final itemProvider = context.watch<ItemProvider>();
    final shopProvider = context.watch<ShopProvider>();
    final user = context.watch<AuthProvider>().userModel;

    final userName = user?.name ?? 'User';
    final shops = shopProvider.shops;

    final groupedData = <String, List<MapEntry<Price, Item>>>{
      'Food': [],
      'Stationery': [],
      'Electronics': [],
      'Other': [],
    };

    // Match prices to items and apply search/category filters.
    for (final price in priceProvider.prices) {
      final item = _findItem(price, itemProvider.items);

      final itemName = item.name.trim().toLowerCase();
      final itemId = item.id.trim().toLowerCase();

      if (_searchQuery.isNotEmpty &&
          !itemName.contains(_searchQuery) &&
          !itemId.contains(_searchQuery)) {
        continue;
      }

      final category = _normalizeCategory(item.category);

      if (selectedCategory != 'All' && selectedCategory != category) {
        continue;
      }

      groupedData[category]!.add(MapEntry(price, item));
    }

    // Group matching prices by item.
    final comparisonGroups = <String, List<MapEntry<Price, Item>>>{};

    if (_searchQuery.isNotEmpty) {
      for (final entries in groupedData.values) {
        for (final entry in entries) {
          final key = entry.value.id.trim().isNotEmpty
              ? entry.value.id.trim().toLowerCase()
              : entry.value.name.trim().toLowerCase();

          comparisonGroups.putIfAbsent(key, () => []).add(entry);
        }
      }
    }

    // Sort item groups by their cheapest recorded price.
    // The item with the lowest price appears first.
    final sortedComparisonGroups = comparisonGroups.entries.toList()
      ..sort((a, b) {
        final cheapestA = a.value
            .map((entry) => entry.key.price)
            .reduce((x, y) => x < y ? x : y);

        final cheapestB = b.value
            .map((entry) => entry.key.price)
            .reduce((x, y) => x < y ? x : y);

        return cheapestA.compareTo(cheapestB);
      });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_getGreeting()},',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;

              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(IconlyLight.notification),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(IconlyLight.location),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopMapScreen()),
              );
            },
          ),
        ],
      ),
      body: priceProvider.isLoading || itemProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SEARCH FIELD
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search for an item...',
                      prefixIcon: const Icon(
                        IconlyLight.search,
                        color: Colors.teal,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(IconlyLight.close_square),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // CATEGORY FILTERS
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    children: [
                      for (final category in [
                        'All',
                        'Food',
                        'Stationery',
                        'Electronics',
                        'Other',
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                color: selectedCategory == category
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            selected: selectedCategory == category,
                            selectedColor: Colors.teal,
                            onSelected: (_) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // SEARCH COMPARISON / NORMAL PRICE LIST
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _loadInitialData();
                    },
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        if (_searchQuery.isNotEmpty) ...[
                          if (sortedComparisonGroups.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 100),
                              child: Center(
                                child: Text(
                                  'No matching items found.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            for (final group in sortedComparisonGroups)
                              _buildComparisonCard(group.value, shops),
                        ] else ...[
                          for (final category in [
                            'Food',
                            'Stationery',
                            'Electronics',
                            'Other',
                          ])
                            for (final entry in groupedData[category]!)
                              _buildPriceCard(entry.key, entry.value, shops),

                          if (groupedData.values.every((list) => list.isEmpty))
                            Padding(
                              padding: const EdgeInsets.only(top: 100),
                              child: Center(
                                child: Text(
                                  'No prices reported for '
                                  '${user?.university ?? 'campus'} yet.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // FLOATING ACTION BUTTONS
      floatingActionButton: showFab
          ? user?.isAdmin == true
                ? FloatingActionButton.extended(
                    heroTag: 'manageShops',
                    onPressed: () {
                      Navigator.pushNamed(context, '/manage_shops');
                    },
                    label: const Text(
                      'Manage Shops',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    icon: const Icon(
                      IconlyLight.edit_square,
                      color: Colors.white,
                      size: 20,
                    ),
                    backgroundColor: Colors.teal,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'report',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportPriceScreen(),
                            ),
                          );
                        },
                        label: const Text('Report Price'),
                        icon: const Icon(IconlyLight.buy),
                        backgroundColor: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton.extended(
                        heroTag: 'complain',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ComplaintFormScreen(),
                            ),
                          );
                        },
                        label: const Text('Complain'),
                        icon: const Icon(IconlyLight.danger),
                        backgroundColor: Colors.redAccent,
                      ),
                    ],
                  )
          : null,
    );
  }

  // Regular price card.
  Widget _buildPriceCard(Price price, Item item, List<Shop> shops) {
    final shop = shops.cast<Shop?>().firstWhere(
      (shop) => shop?.id == price.shopId,
      orElse: () => null,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.1),
          radius: 20,
          child: const Icon(IconlyLight.buy, color: Colors.teal),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${shop?.name ?? 'Unknown Shop'} • '
          '${DateFormat('MMM d').format(price.updatedAt)}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(
          '₦${price.price.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Comparison card: cheapest shop first.
  Widget _buildComparisonCard(
    List<MapEntry<Price, Item>> entries,
    List<Shop> shops,
  ) {
    final sortedEntries = List<MapEntry<Price, Item>>.from(entries)
      ..sort((a, b) => a.key.price.compareTo(b.key.price));

    final item = sortedEntries.first.value;
    final cheapestPrice = sortedEntries.first.key.price;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(IconlyLight.buy, color: Colors.teal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Cheapest price: '
                '₦${cheapestPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < sortedEntries.length; index++)
              _buildShopPriceRow(
                sortedEntries[index].key,
                shops,
                isCheapest: index == 0,
              ),
          ],
        ),
      ),
    );
  }

  // Displays a shop and its price.
  Widget _buildShopPriceRow(
    Price price,
    List<Shop> shops, {
    required bool isCheapest,
  }) {
    final shop = shops.cast<Shop?>().firstWhere(
      (shop) => shop?.id == price.shopId,
      orElse: () => null,
    );

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isCheapest ? Colors.teal.withOpacity(0.06) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCheapest ? Colors.teal : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop?.name ?? 'Unknown Shop',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  'Updated ${DateFormat('MMM d').format(price.updatedAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦${price.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isCheapest ? Colors.teal : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCheapest)
                const Text(
                  'CHEAPEST',
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
