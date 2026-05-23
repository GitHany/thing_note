import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/app/theme/spacing_constants.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:thing_note/features/dashboard/data/dashboard_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DashboardData? _dashboardData;
  RealtimeStats? _realtimeStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final service = ref.read(dashboardServiceProvider);
    final dashboard = await service.getMonthlyDashboard();
    final stats = await service.getRealtimeStats();

    setState(() {
      _dashboardData = dashboard;
      _realtimeStats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);
    
    // Responsive values
    final horizontalPadding = AppSpacing.getHorizontalPadding(screenWidth);
    final itemSpacing = AppSpacing.getItemSpacing(screenWidth);
    final cardPadding = isUltraSmall ? 10.0 : (isSmall ? 12.0 : 16.0);
    final iconSize = isUltraSmall ? 14.0 : (isSmall ? 16.0 : 18.0);
    final titleFontSize = isUltraSmall ? 12.0 : (isSmall ? 14.0 : 16.0);
    final sectionTitleFontSize = isUltraSmall ? 16.0 : (isSmall ? 18.0 : 20.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.dataDashboard,
          style: TextStyle(fontSize: isUltraSmall ? 16 : 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isSmall || isUltraSmall,
          tabAlignment: isSmall || isUltraSmall ? TabAlignment.start : TabAlignment.center,
          labelPadding: EdgeInsets.symmetric(horizontal: isUltraSmall ? 8 : 12),
          labelStyle: TextStyle(fontSize: isUltraSmall ? 12 : 14),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.overview),
            Tab(text: AppLocalizations.of(context)!.trend),
            Tab(text: AppLocalizations.of(context)!.ranking),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: isUltraSmall ? 18 : 24),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(horizontalPadding, itemSpacing, cardPadding, iconSize, titleFontSize, sectionTitleFontSize),
                _buildTrendTab(horizontalPadding, isUltraSmall, isSmall),
                _buildRankingTab(horizontalPadding, itemSpacing, iconSize, titleFontSize),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(
    double horizontalPadding,
    double itemSpacing,
    double cardPadding,
    double iconSize,
    double titleFontSize,
    double sectionTitleFontSize,
  ) {
    if (_dashboardData == null || _realtimeStats == null) {
      return const Center(child: Text('暂无数据'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: horizontalPadding),
          // 实时统计卡片 - 2x2 布局
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.note,
                  title: AppLocalizations.of(context)!.totalRecords,
                  value: _realtimeStats!.totalRecords.toString(),
                  color: Colors.blue,
                  iconSize: iconSize,
                  titleSize: titleFontSize,
                  cardPadding: cardPadding,
                ),
              ),
              SizedBox(width: itemSpacing),
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite,
                  title: AppLocalizations.of(context)!.favorites,
                  value: _realtimeStats!.favoritesCount.toString(),
                  color: Colors.red,
                  iconSize: iconSize,
                  titleSize: titleFontSize,
                  cardPadding: cardPadding,
                ),
              ),
            ],
          ),
          SizedBox(height: itemSpacing),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  title: AppLocalizations.of(context)!.consecutiveDays,
                  value: AppLocalizations.of(context)!.days(_realtimeStats!.currentStreak),
                  color: Colors.orange,
                  iconSize: iconSize,
                  titleSize: titleFontSize,
                  cardPadding: cardPadding,
                ),
              ),
              SizedBox(width: itemSpacing),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer,
                  title: AppLocalizations.of(context)!.totalDuration,
                  value: _realtimeStats!.formattedTotalDuration,
                  color: Colors.green,
                  iconSize: iconSize,
                  titleSize: titleFontSize,
                  cardPadding: cardPadding,
                ),
              ),
            ],
          ),
          SizedBox(height: horizontalPadding * 1.5),
          
          // 本月统计
          Text(
            AppLocalizations.of(context)!.monthlyStats,
            style: TextStyle(
              fontSize: sectionTitleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: horizontalPadding),
          _Card(
            child: Column(
              children: [
                _InfoRow(
                  label: AppLocalizations.of(context)!.recordCountLabel,
                  value: '${_dashboardData!.recordCount} ${AppLocalizations.of(context)!.records}',
                  titleFontSize: titleFontSize,
                ),
                _InfoRow(
                  label: AppLocalizations.of(context)!.totalDuration, 
                  value: _dashboardData!.formattedDuration,
                  titleFontSize: titleFontSize,
                ),
                _InfoRow(
                  label: AppLocalizations.of(context)!.photos, 
                  value: '${_dashboardData!.photoCount} ${AppLocalizations.of(context)!.photosCount}',
                  titleFontSize: titleFontSize,
                ),
                _InfoRow(
                  label: AppLocalizations.of(context)!.videos, 
                  value: '${_dashboardData!.videoCount} ${AppLocalizations.of(context)!.videosCount}',
                  titleFontSize: titleFontSize,
                ),
                _InfoRow(
                  label: AppLocalizations.of(context)!.activeDays, 
                  value: AppLocalizations.of(context)!.days(_dashboardData!.activeDays),
                  titleFontSize: titleFontSize,
                ),
              ],
            ),
          ),
          SizedBox(height: horizontalPadding),
        ],
      ),
    );
  }

  Widget _buildTrendTab(double horizontalPadding, bool isUltraSmall, bool isSmall) {
    if (_dashboardData == null || _dashboardData!.dailyTrend.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: isUltraSmall ? 48 : 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: isUltraSmall ? 12 : 16),
            Text(
              AppLocalizations.of(context)!.noTrendData,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: isUltraSmall ? 13 : 14,
              ),
            ),
          ],
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    // 动态计算图表高度，确保在不同屏幕上比例合适
    final chartHeight = screenHeight > 700 
        ? 250.0 
        : (screenHeight > 500 ? 200.0 : 160.0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: horizontalPadding),
          Text(
            AppLocalizations.of(context)!.dailyRecordTrend,
            style: TextStyle(
              fontSize: isUltraSmall ? 16 : 20, 
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: horizontalPadding),
          SizedBox(
            height: chartHeight,
            child: BarChart(
              BarChartData(
                barGroups: _dashboardData!.dailyTrend.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.count.toDouble(),
                        color: Theme.of(context).colorScheme.primary,
                        width: isUltraSmall ? 12.0 : (isSmall ? 14.0 : 16.0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _dashboardData!.dailyTrend.length) {
                          final date = _dashboardData!.dailyTrend[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: isUltraSmall ? 9 : 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isUltraSmall ? 24 : 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: isUltraSmall ? 9 : 10),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).colorScheme.outlineVariant.withAlpha(77),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          SizedBox(height: horizontalPadding),
        ],
      ),
    );
  }

  Widget _buildRankingTab(
    double horizontalPadding,
    double itemSpacing,
    double iconSize,
    double titleFontSize,
  ) {
    if (_dashboardData == null) {
      return const Center(child: Text('暂无数据'));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: horizontalPadding),
          Text(
            AppLocalizations.of(context)!.thingNameRanking,
            style: TextStyle(
              fontSize: isUltraSmall ? 14 : 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isUltraSmall ? 8 : 12),
          if (_dashboardData!.topThingNames.isEmpty)
            _buildEmptyRanking(isUltraSmall)
          else
            ...(_dashboardData!.topThingNames.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: itemSpacing),
                child: _RankingItem(
                  rank: entry.key + 1,
                  name: entry.value.name,
                  count: entry.value.count,
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: iconSize,
                  titleSize: titleFontSize,
                  isCompact: isUltraSmall || isSmall,
                ),
              );
            })),
          SizedBox(height: horizontalPadding * 1.5),
          Text(
            AppLocalizations.of(context)!.tagRanking,
            style: TextStyle(
              fontSize: isUltraSmall ? 14 : 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isUltraSmall ? 8 : 12),
          if (_dashboardData!.topTags.isEmpty)
            _buildEmptyRanking(isUltraSmall)
          else
            ...(_dashboardData!.topTags.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: itemSpacing),
                child: _RankingItem(
                  rank: entry.key + 1,
                  name: entry.value.name,
                  count: entry.value.count,
                  color: Colors.green,
                  iconSize: iconSize,
                  titleSize: titleFontSize,
                  isCompact: isUltraSmall || isSmall,
                ),
              );
            })),
          SizedBox(height: horizontalPadding),
        ],
      ),
    );
  }

  Widget _buildEmptyRanking(bool isUltraSmall) {
    return Container(
      padding: EdgeInsets.all(isUltraSmall ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.noData,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: isUltraSmall ? 12 : 14,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final double iconSize;
  final double titleSize;
  final double cardPadding;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.iconSize = 18.0,
    this.titleSize = 12.0,
    this.cardPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(cardPadding * 0.5),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            SizedBox(width: cardPadding * 0.75),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      color: Colors.grey[600], 
                      fontSize: titleSize,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value, 
                    style: TextStyle(
                      fontSize: titleSize + 6, 
                      fontWeight: FontWeight.bold,
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

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double titleFontSize;

  const _InfoRow({
    required this.label, 
    required this.value,
    this.titleFontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: titleFontSize,
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final int rank;
  final String name;
  final int count;
  final Color color;
  final double iconSize;
  final double titleSize;
  final bool isCompact;

  const _RankingItem({
    required this.rank,
    required this.name,
    required this.count,
    required this.color,
    this.iconSize = 16.0,
    this.titleSize = 14.0,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = isCompact ? 24.0 : 32.0;
    final badgeFontSize = isCompact ? 10.0 : 12.0;
    final badgePadding = isCompact ? 4.0 : 6.0;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            borderRadius: BorderRadius.circular(badgeSize / 2),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                color: color, 
                fontWeight: FontWeight.bold,
                fontSize: badgeFontSize,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontSize: titleSize),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: badgePadding * 2, vertical: badgePadding),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(badgePadding * 2),
          ),
          child: Text(
            '$count ${AppLocalizations.of(context)!.times}',
            style: TextStyle(color: color, fontSize: titleSize - 2),
          ),
        ),
      ),
    );
  }
}