/// 每日箴言数据模型
class DailyMotto {
  final int? id;
  final String date;
  final String? quote;
  final String? author;
  final String? source;
  final String? reflection;
  final int? moodAfter;
  final bool isFavorite;
  final DateTime createdAt;

  const DailyMotto({
    this.id,
    required this.date,
    this.quote,
    this.author,
    this.source,
    this.reflection,
    this.moodAfter,
    this.isFavorite = false,
    required this.createdAt,
  });

  DailyMotto copyWith({
    int? id,
    String? date,
    String? quote,
    String? author,
    String? source,
    String? reflection,
    int? moodAfter,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return DailyMotto(
      id: id ?? this.id,
      date: date ?? this.date,
      quote: quote ?? this.quote,
      author: author ?? this.author,
      source: source ?? this.source,
      reflection: reflection ?? this.reflection,
      moodAfter: moodAfter ?? this.moodAfter,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'quote': quote,
      'author': author,
      'source': source,
      'reflection': reflection,
      'mood_after': moodAfter,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyMotto.fromMap(Map<String, dynamic> map) {
    return DailyMotto(
      id: map['id'] as int?,
      date: map['date'] as String,
      quote: map['quote'] as String?,
      author: map['author'] as String?,
      source: map['source'] as String?,
      reflection: map['reflection'] as String?,
      moodAfter: map['mood_after'] as int?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 预置箴言列表
class MottoLibrary {
  static const List<Map<String, String>> defaultMottos = [
    {'quote': '每一天都是新的开始。', 'author': '匿名'},
    {'quote': '坚持就是胜利。', 'author': '谚语'},
    {'quote': '行动胜于空谈。', 'author': '谚语'},
    {'quote': '失败是成功之母。', 'author': '谚语'},
    {'quote': '今日事今日毕。', 'author': '古语'},
    {'quote': '种一棵树最好的时间是十年前，其次是现在。', 'author': '谚语'},
    {'quote': '不要等待，时机永远不会恰到好处。', 'author': '拿破仑·希尔'},
    {'quote': '你的时间有限，不要浪费在别人的生活里。', 'author': '史蒂夫·乔布斯'},
    {'quote': '生活不是等待暴风雨过去，而是学会在雨中跳舞。', 'author': '维维安·伊丽莎白'},
    {'quote': '最大的荣耀不是从不跌倒，而是每次跌倒后都能爬起来。', 'author': '孔子'},
    {'quote': '成功是用努力而非借口来衡量的。', 'author': '匿名'},
    {'quote': '每天进步一点点，一年就是巨大的飞跃。', 'author': '匿名'},
    {'quote': '专注于你所拥有的，而不是你所缺乏的。', 'author': '匿名'},
    {'quote': '习惯决定命运，细节决定成败。', 'author': '古语'},
    {'quote': '健康是最大的财富。', 'author': '谚语'},
    {'quote': '要么旅行，要么阅读，身体和灵魂总要有一个在路上。', 'author': '余光中'},
    {'quote': '少即是多。', 'author': '路德维希·密斯·凡·德·罗'},
    {'quote': '做难的事，做你害怕的事，做你不会做的事。', 'author': '匿名'},
    {'quote': '永远相信美好的事情即将发生。', 'author': '小米'},
    {'quote': '今天你度过的每一个平凡日子，都是昨日未能重来的奇迹。', 'author': '匿名'},
  ];
}
