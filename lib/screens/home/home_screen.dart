import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iconly/iconly.dart';

import '../../constants/app_colors.dart';
import '../../model/item_model.dart';
import '../../model/price_model.dart';
import '../../model/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/shop_provider.dart';
import '../shop/report_price_screen.dart';
import '../complaints/complaint_form_screen.dart';
import '../shop/shop_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "All";

  bool showFab = true;

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_onScroll);

    _loadInitialData();
  }

  @override
  void dispose() {
    scrollController.dispose();
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
      final user = context.read<AuthProvider>().userModel;

      if (user != null) {
        context.read<ItemProvider>().fetchItems();

        context
            .read<PriceProvider>()
            .fetchPricesByUniversity(user.university);

        context.read<ShopProvider>().fetchShopsByUniversity(
          user.university,
          user.uid,
          isAdmin: user.isAdmin,
        );
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good morning";
    }

    if (hour < 17) {
      return "Good afternoon";
    }

    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    final priceProvider = Provider.of<PriceProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);
    final user = Provider.of<AuthProvider>(context).userModel;

    final userName = user?.name ?? "User";

    Map<String, List<MapEntry<Price, Item>>> groupedData = {
      "Food": [],
      "Stationery": [],
      "Electronics": [],
      "Other": [],
    };

    for (var price in priceProvider.prices) {
      final item = itemProvider.items.firstWhere(
        (item) =>
            item.id.trim().toLowerCase() == price.itemId.trim().toLowerCase() ||
            item.name.trim().toLowerCase() == price.itemId.trim().toLowerCase(),
        orElse: () => Item(
          id: '',
          name: price.itemId,
          category: 'Other',
        ),
      );

      // Normalize category for grouping
      String check = item.category.trim().toLowerCase();
      String normalized = "";

      if (check == "food" ||
          check.contains("food") ||
          check.contains("drink") ||
          check.contains("snack") ||
          check.contains("grocer") ||
          check.contains("provision") ||
          check.contains("eat")) {
        normalized = "Food";
      } else if (check == "stationery" ||
          check.contains("station") ||
          check.contains("book") ||
          check.contains("pen") ||
          check.contains("write") ||
          check.contains("office") ||
          check.contains("copy")) {
        normalized = "Stationery";
      } else if (check == "electronics" ||
          check.contains("elect") ||
          check.contains("phone") ||
          check.contains("gadget") ||
          check.contains("tech") ||
          check.contains("laptop") ||
          check.contains("charge")) {
        normalized = "Electronics";
      }

      if (selectedCategory == 'All' || selectedCategory == normalized) {
        groupedData[normalized]?.add(MapEntry(price, item));
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        backgroundColor: Color(AppColors.bgColor).withOpacity(0.7),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                userName.isNotEmpty
                    ? userName[0].toUpperCase()
                    : "U",
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
                    "${_getGreeting()},",
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
          IconButton(
            icon: const Icon(IconlyLight.location),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const ShopMapScreen(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(IconlyLight.logout),
            onPressed: () => _handleLogout(),
          ),
        ],
      ),

      body: priceProvider.isLoading || itemProvider.isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          // CATEGORY FILTERS
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final cat in [
                  "All",
                  "Food",
                  "Stationery",
                  "Electronics",
                  "Other",
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: selectedCategory == cat
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: selectedCategory == cat,
                      onSelected: (s) {
                        setState(() {
                          selectedCategory = cat;
                        });
                      },
                      selectedColor:
                      Color(AppColors.bgColor).withOpacity(0.7),
                      labelStyle: TextStyle(
                        color: selectedCategory == cat
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // PRICE LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadInitialData();
              },
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                children: [
                  for (final group in [
                    'Food',
                    'Stationery',
                    'Electronics',
                    'Other',
                  ])
                    if (groupedData[group]!.isNotEmpty)
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 20,
                              bottom: 8,
                              left: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  group == 'Food'
                                      ? IconlyLight.buy
                                      : group == 'Stationery'
                                      ? IconlyLight.edit
                                      : group ==
                                      'Electronics'
                                      ? IconlyLight.game
                                      : IconlyLight.category,
                                  color: Colors.green[800],
                                  size: 20,
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  group.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          for (final entry in groupedData[group]!)
                            _buildPriceCard(entry.key, entry.value),
                        ],
                      ),

                  if (groupedData.values
                      .every((list) => list.isEmpty))
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 100,
                      ),
                      child: Center(
                        child: Text(
                          'No prices reported for ${user?.university ?? 'campus'} yet.',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
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
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/manage_shops',
          );
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
          IconlyLight.home,
          color: Colors.white,
          size: 20,
        ),
        backgroundColor:
        Color(AppColors.bgColor).withOpacity(0.7),
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
                  builder: (_) =>
                  const ReportPriceScreen(),
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
                  builder: (_) =>
                  const ComplaintFormScreen(),
                ),
              );
            },
            label: const Text('Complain'),
            icon: const Icon(
              IconlyLight.danger,
            ),
            backgroundColor: Colors.redAccent,
          ),
        ],
      )
          : null,
    );
  }

  Widget _buildPriceCard(Price price, Item item) {
    final shops = context.read<ShopProvider>().shops;

    final shop = shops.cast<Shop?>().firstWhere(
          (shop) => shop?.id == price.shopId,
      orElse: () => null,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          Colors.white.withOpacity(0.1),
          radius: 20,
          child: Icon(
            IconlyLight.bag,
            color: Color(AppColors.bgColor),
          ),
        ),

        title: Text(
          item.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),

        subtitle: Text(
          "${shop?.name ?? 'Unknown Shop'} • "
              "${DateFormat('MMM d').format(price.updatedAt)}",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),

        trailing: Text(
          "₦${price.price.toStringAsFixed(0)}",
          style: TextStyle(
            color: Color(AppColors.bgColor),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final auth = context.read<AuthProvider>();

    context.read<PriceProvider>().clearPrices();
    context.read<ShopProvider>().clearShops();

    await auth.logout();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }
}