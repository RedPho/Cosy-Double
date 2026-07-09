import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/cozy_theme.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../domain/entities/item.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/shop/shop_bloc.dart';
import '../../blocs/shop/shop_event.dart';
import '../../blocs/shop/shop_state.dart';
import '../../blocs/canvas/canvas_bloc.dart';
import '../../blocs/canvas/canvas_event.dart';
import '../../blocs/canvas/canvas_state.dart';

class OasisScreen extends StatefulWidget {
  const OasisScreen({super.key});

  @override
  State<OasisScreen> createState() => _OasisScreenState();
}

class _OasisScreenState extends State<OasisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load shop items and user oasis items
    context.read<ShopBloc>().add(LoadShopItems());
    context.read<CanvasBloc>().add(LoadOasisItems());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShopBloc, ShopState>(
      listener: (context, state) {
        if (state is PurchaseSuccess) {
          // Trigger wallet refresh
          context.read<AuthBloc>().add(AppStarted());
          
          // Re-load owned items for canvas state hydration
          context.read<CanvasBloc>().add(LoadOasisItems());
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bought successfully! Cha-ching! 🍃')),
          );
        } else if (state is ShopError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              context.go('/lobby');
            },
          ),
          title: Text(
            'My Oasis',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 22),
          ),
          actions: [
            // Wallet balance
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                int leaves = 0;
                if (authState is Authenticated) {
                  leaves = authState.user.leavesBalance;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Chip(
                    avatar: const Text('🍃', style: TextStyle(fontSize: 16)),
                    label: Text('$leaves', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    shape: RoundedRectangleBorder(borderRadius: CozyTheme.radiusMedium),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Top portion: Visual Canvas
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: CozyTheme.radiusLarge,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
                    ),
                    child: BlocBuilder<CanvasBloc, CanvasState>(
                      builder: (context, canvasState) {
                        if (canvasState is CanvasLoading) {
                          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                        }
                        
                        if (canvasState is CanvasError) {
                          return Center(child: Text('Error loading canvas: ${canvasState.message}'));
                        }
                        
                        if (canvasState is CanvasLoaded) {
                          final placedItems = canvasState.items.where((i) => i.isPlaced).cast<InventoryItem>().toList();
                          
                          // Check active applied theme
                          final activeTheme = placedItems.isEmpty 
                              ? null 
                              : placedItems.first;
                          
                          final palette = activeTheme != null 
                              ? ThemePalette.get(activeTheme.name)
                              : ThemePalette.defaultPalette;
                          
                          return _buildCozyWorkspacePreview(palette);
                        }
                        
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // Lower portion: Interactive Tabs (Shop & Inventory)
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0D000000), blurRadius: 10, spreadRadius: 1),
                  ],
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      tabs: const [
                        Tab(text: 'Shop'),
                        Tab(text: 'My Items'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildShopTab(context),
                          _buildInventoryTab(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopTab(BuildContext context) {
    // Watch canvas state to detect owned items
    final canvasState = context.watch<CanvasBloc>().state;
    List<int> ownedItemIds = [];
    if (canvasState is CanvasLoaded) {
      ownedItemIds = canvasState.items.map((i) => i.itemId).toList();
    }

    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        if (state is ShopLoading) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
        }
        
        List<Item> items = [];
        if (state is ShopLoaded) {
          items = state.items;
        } else if (state is PurchaseSuccess) {
          // Fallback loading states
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
        }
        
        if (items.isEmpty) {
          return const Center(child: Text('Loading shop items...'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isOwned = ownedItemIds.contains(item.id);

            return Card(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: CozyTheme.radiusMedium,
                side: BorderSide(
                  color: isOwned
                      ? Theme.of(context).colorScheme.outline
                      : (item.isPremium
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                          : Theme.of(context).colorScheme.outline),
                  width: item.isPremium && !isOwned ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: CozyTheme.radiusMedium,
                        child: _buildThemeMockupPreview(ThemePalette.get(item.name)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildPurchaseButton(context, item, isOwned),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 3-way purchase button:
  ///  - Owned → greyed-out "Owned ✓"
  ///  - Dual (leaves + USD) → stacked row: 🍃 button | $ button
  ///  - Premium-only (USD) → shimmer FilledButton
  ///  - Free (costLeaves == 0, not premium) → single FilledButton "Claim Free"
  ///  - Leaves-only → OutlinedButton 🍃
  Widget _buildPurchaseButton(BuildContext context, item, bool isOwned) {
    final cs = Theme.of(context).colorScheme;
    final bool isFree = item.costLeaves == 0 && item.priceUsd == 0;

    if (isOwned) {
      return FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          backgroundColor: cs.outline.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: CozyTheme.radiusSmall),
        ),
        child: const Text('Owned ✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black38)),
      );
    }


    if (isFree) {
      return FilledButton(
        onPressed: () => context.read<ShopBloc>().add(BuyItemWithLeaves(itemId: item.id)),
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondary,
          padding: const EdgeInsets.symmetric(vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: CozyTheme.radiusSmall),
        ),
        child: const Text('Claim Free', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    // Leaves-only
    return OutlinedButton(
      onPressed: () => context.read<ShopBloc>().add(BuyItemWithLeaves(itemId: item.id)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: cs.secondary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: CozyTheme.radiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍃 ', style: TextStyle(fontSize: 12)),
          Text('${item.costLeaves}', style: TextStyle(fontSize: 12, color: cs.secondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInventoryTab(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      builder: (context, state) {
        if (state is CanvasLoading) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
        }
        
        List<InventoryItem> items = [];
        if (state is CanvasLoaded) {
          items = state.items;
        }
        
        if (items.isEmpty) {
          return const Center(
            child: Text('You don\'t own any themes yet. Visit the Shop!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final palette = ThemePalette.get(item.name);

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              color: item.isPlaced 
                  ? palette.primaryColor.withOpacity(0.08)
                  : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: CozyTheme.radiusMedium, 
                side: BorderSide(
                  color: item.isPlaced ? palette.primaryColor : Theme.of(context).colorScheme.outline,
                  width: item.isPlaced ? 2 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: _buildThemeSwatchStrip(palette),
                  title: Text(palette.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Color Theme', style: TextStyle(fontSize: 12, color: Colors.black45)),
                  trailing: item.isPlaced
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Active ✓',
                            style: TextStyle(
                              color: palette.name.contains('Midnight') ? Colors.white : palette.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : FilledButton(
                          onPressed: () {
                            context.read<CanvasBloc>().add(PlaceItemOnCanvas(inventoryId: item.id));
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: CozyTheme.radiusSmall),
                          ),
                          child: const Text('Apply', style: TextStyle(fontSize: 13)),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // Color Palette representation
  /// Compact 3-color dot swatch — used only in inventory list leading
  Widget _buildThemeThumbnail(ThemePalette palette) {
    return Container(
      width: 72,
      height: 48,
      decoration: BoxDecoration(
        color: palette.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.borderColor),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: palette.previewColors.map((color) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Horizontal color swatch strip — used in inventory list leading
  Widget _buildThemeSwatchStrip(ThemePalette palette) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 44,
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: palette.backgroundColor)),
            Expanded(child: ColoredBox(color: palette.primaryColor)),
            Expanded(child: ColoredBox(color: palette.secondaryColor)),
          ],
        ),
      ),
    );
  }

  /// Rich mini UI mockup preview for the shop card grid
  Widget _buildThemeMockupPreview(ThemePalette palette) {
    final isDark = palette.brightness == Brightness.dark;
    final onPrimary = isDark ? Colors.white : palette.surfaceColor;

    return Container(
      color: palette.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Fake App Bar ──
          Container(
            height: 28,
            color: palette.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: palette.primaryColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: palette.textColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 18, height: 8,
                  decoration: BoxDecoration(
                    color: palette.primaryColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──
          Container(height: 1, color: palette.borderColor),

          // ── Body ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1 — focus room card
                  Container(
                    height: 38,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: palette.surfaceColor,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: palette.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: palette.secondaryColor.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Center(
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: palette.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 5,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: palette.textColor.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                height: 4,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: palette.textColor.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 26, height: 13,
                          decoration: BoxDecoration(
                            color: palette.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Card 2 — task item
                  Container(
                    height: 28,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: palette.surfaceColor,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: palette.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 9, height: 9,
                          decoration: BoxDecoration(
                            border: Border.all(color: palette.primaryColor, width: 1.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: palette.textColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('🍃', style: TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom action button
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: palette.primaryColor,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        height: 4,
                        width: 30,
                        decoration: BoxDecoration(
                          color: onPrimary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(2),
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
    );
  }

  // Vector cozy study workspace drawing (completely customizable by theme)
  Widget _buildCozyWorkspacePreview(ThemePalette palette) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: palette.backgroundColor,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glowing sun/moon in top right corner
            Positioned(
              top: 20,
              right: 25,
              child: Icon(
                palette.name.contains('Midnight') ? Icons.dark_mode : Icons.wb_sunny,
                color: palette.primaryColor.withOpacity(0.3),
                size: 28,
              ),
            ),

            // Window panel on the wall
            Positioned(
              top: 25,
              left: 35,
              child: Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: palette.borderColor.withOpacity(0.2),
                  border: Border.all(color: palette.borderColor, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(child: Container(width: 3, color: palette.borderColor)),
                    Center(child: Container(height: 3, color: palette.borderColor)),
                  ],
                ),
              ),
            ),

            // Cozy Chair backrest (behind table)
            Positioned(
              bottom: 45,
              child: Container(
                width: 36,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.primaryColor.withOpacity(0.25),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border.all(color: palette.primaryColor, width: 2.5),
                ),
              ),
            ),
            
            // Desk table surface & legs
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: palette.borderColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Container(width: 8, height: 62, color: palette.borderColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Container(width: 8, height: 62, color: palette.borderColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Coffee Cup on the desk
            Positioned(
              bottom: 78,
              left: 45,
              child: Container(
                width: 12,
                height: 14,
                decoration: BoxDecoration(
                  color: palette.primaryColor,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(3), bottomRight: Radius.circular(3)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -3,
                      top: 3,
                      child: Container(
                        width: 4,
                        height: 7,
                        decoration: BoxDecoration(
                          border: Border.all(color: palette.primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Laptop in the center of the desk
            Positioned(
              bottom: 78,
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 32,
                    decoration: BoxDecoration(
                      color: palette.textColor.withOpacity(0.08),
                      border: Border.all(color: palette.textColor.withOpacity(0.4), width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: palette.primaryColor.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 58,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.borderColor,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: palette.textColor.withOpacity(0.4), width: 1),
                    ),
                  ),
                ],
              ),
            ),

            // Desk Lamp on the right
            Positioned(
              bottom: 78,
              right: 45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 20,
                    height: 12,
                    decoration: BoxDecoration(
                      color: palette.primaryColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ),
                  Container(
                    width: 4,
                    height: 22,
                    color: palette.borderColor,
                  ),
                  Container(
                    width: 14,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



