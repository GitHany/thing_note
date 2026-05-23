import 'package:flutter/material.dart';

class PlaceCluster {
  final int? id;
  final String clusterName;
  final String clusterType;
  final double? centerLatitude;
  final double? centerLongitude;
  final String? icon;
  final String? color;
  final int visitCount;
  final int avgDurationMinutes;
  final String createdAt;

  PlaceCluster({
    this.id,
    required this.clusterName,
    required this.clusterType,
    this.centerLatitude,
    this.centerLongitude,
    this.icon,
    this.color,
    this.visitCount = 0,
    this.avgDurationMinutes = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cluster_name': clusterName,
      'cluster_type': clusterType,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'icon': icon,
      'color': color,
      'visit_count': visitCount,
      'avg_duration_minutes': avgDurationMinutes,
      'created_at': createdAt,
    };
  }

  factory PlaceCluster.fromMap(Map<String, dynamic> map) {
    return PlaceCluster(
      id: map['id'] as int?,
      clusterName: map['cluster_name'] as String,
      clusterType: map['cluster_type'] as String,
      centerLatitude: map['center_latitude'] as double?,
      centerLongitude: map['center_longitude'] as double?,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      visitCount: map['visit_count'] as int? ?? 0,
      avgDurationMinutes: map['avg_duration_minutes'] as int? ?? 0,
      createdAt: map['created_at'] as String,
    );
  }

  PlaceCluster copyWith({
    int? id,
    String? clusterName,
    String? clusterType,
    double? centerLatitude,
    double? centerLongitude,
    String? icon,
    String? color,
    int? visitCount,
    int? avgDurationMinutes,
    String? createdAt,
  }) {
    return PlaceCluster(
      id: id ?? this.id,
      clusterName: clusterName ?? this.clusterName,
      clusterType: clusterType ?? this.clusterType,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      visitCount: visitCount ?? this.visitCount,
      avgDurationMinutes: avgDurationMinutes ?? this.avgDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  IconData get iconData {
    switch (clusterType) {
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      case 'restaurant': return Icons.restaurant;
      case 'shopping': return Icons.shopping_bag;
      case 'entertainment': return Icons.movie;
      case 'sports': return Icons.sports_soccer;
      case 'education': return Icons.school;
      case 'hospital': return Icons.local_hospital;
      case 'park': return Icons.park;
      case 'transport': return Icons.directions_transit;
      default: return Icons.place;
    }
  }

  Color get colorValue {
    switch (color) {
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'red': return Colors.red;
      case 'teal': return Colors.teal;
      case 'pink': return Colors.pink;
      case 'amber': return Colors.amber;
      default: return Colors.blueGrey;
    }
  }

  String get typeLabel {
    switch (clusterType) {
      case 'home': return '住宅';
      case 'work': return '工作';
      case 'restaurant': return '餐饮';
      case 'shopping': return '购物';
      case 'entertainment': return '娱乐';
      case 'sports': return '运动';
      case 'education': return '教育';
      case 'hospital': return '医疗';
      case 'park': return '公园';
      case 'transport': return '交通';
      default: return '其他';
    }
  }

  String get durationLabel {
    if (avgDurationMinutes < 60) {
      return '$avgDurationMinutes分钟';
    } else {
      final hours = avgDurationMinutes ~/ 60;
      final minutes = avgDurationMinutes % 60;
      if (minutes == 0) {
        return '$hours小时';
      }
      return '$hours小时$minutes分钟';
    }
  }

  static List<String> get clusterTypes => [
    'home',
    'work',
    'restaurant',
    'shopping',
    'entertainment',
    'sports',
    'education',
    'hospital',
    'park',
    'transport',
    'other',
  ];

  static String getTypeLabel(String type) {
    final labels = {
      'home': '住宅',
      'work': '工作',
      'restaurant': '餐饮',
      'shopping': '购物',
      'entertainment': '娱乐',
      'sports': '运动',
      'education': '教育',
      'hospital': '医疗',
      'park': '公园',
      'transport': '交通',
      'other': '其他',
    };
    return labels[type] ?? '其他';
  }
}

class PlaceVisitHistory {
  final int? id;
  final int clusterId;
  final double latitude;
  final double longitude;
  final String arrivedAt;
  final String? leftAt;
  final int? durationMinutes;

  PlaceVisitHistory({
    this.id,
    required this.clusterId,
    required this.latitude,
    required this.longitude,
    required this.arrivedAt,
    this.leftAt,
    this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cluster_id': clusterId,
      'latitude': latitude,
      'longitude': longitude,
      'arrived_at': arrivedAt,
      'left_at': leftAt,
      'duration_minutes': durationMinutes,
    };
  }

  factory PlaceVisitHistory.fromMap(Map<String, dynamic> map) {
    return PlaceVisitHistory(
      id: map['id'] as int?,
      clusterId: map['cluster_id'] as int,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      arrivedAt: map['arrived_at'] as String,
      leftAt: map['left_at'] as String?,
      durationMinutes: map['duration_minutes'] as int?,
    );
  }
}
