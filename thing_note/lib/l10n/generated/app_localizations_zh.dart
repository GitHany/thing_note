import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '事件记录';

  @override
  String get settings => '设置';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '浅色模式';

  @override
  String get themeModeDark => '深色模式';

  @override
  String get selectTheme => '选择主题';

  @override
  String get thingNameManage => '事情名称管理';

  @override
  String get thingNameManageDesc => '管理可用的事情名称列表';

  @override
  String get clearTempZips => '清除临时压缩包';

  @override
  String get clearTempZipsDesc => '删除分享时生成的临时文件';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get confirmClear => '确认清除';

  @override
  String get confirmClearTemp => '确定要清除所有临时压缩包吗？\n\n此操作不会删除记录。';

  @override
  String get confirmClearData => '确定要清除所有数据吗？此操作不可撤销！';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get confirmClearBtn => '确认清除';

  @override
  String get tempZipsCleared => '临时压缩包已清除';

  @override
  String clearFailed(String error) {
    return '清除失败: $error';
  }

  @override
  String get allDataCleared => '所有数据已清除';

  @override
  String get noRecords => '暂无记录';

  @override
  String get addFirstRecord => '点击右下角按钮添加第一条记录';

  @override
  String selectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get selectAll => '全选';

  @override
  String get share => '分享';

  @override
  String get delete => '删除';

  @override
  String get confirmDelete => '确认删除';

  @override
  String confirmDeleteSelected(int count) {
    return '确定要删除选中的 $count 条记录吗？';
  }

  @override
  String shareRecords(int count) {
    return '分享 $count 条记录';
  }

  @override
  String shareFailed(String error) {
    return '分享失败: $error';
  }

  @override
  String loadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String get exporting => '导出中';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get dateFormat => '日期格式';

  @override
  String get dateFormatYMD => 'YYYY-MM-DD';

  @override
  String get dateFormatMDY => 'MM/DD/YYYY';

  @override
  String get dateFormatDMY => 'DD/MM/YYYY';

  @override
  String get timeFormat => '时间格式';

  @override
  String get timeFormat24h => '24小时制';

  @override
  String get timeFormat12h => '12小时制';

  @override
  String get newRecord => '新建记录';

  @override
  String get editRecord => '编辑记录';

  @override
  String get occurredAt => '发生时间';

  @override
  String get duration => '持续时长';

  @override
  String get note => '备注';

  @override
  String get photos => '照片';

  @override
  String get audios => '录音';

  @override
  String get save => '保存';

  @override
  String get unsavedChanges => '有未保存的变更';

  @override
  String get unsavedChangesDesc => '确定要放弃当前编辑的内容吗？';

  @override
  String get discard => '放弃';

  @override
  String get keepEditing => '继续编辑';

  @override
  String get thingName => '事情名称';

  @override
  String get defaultThingName => '默认';

  @override
  String get defaultThingNameRemark => '未选择事件名称的记录将归类到此处';

  @override
  String get addThingName => '添加事情名称';

  @override
  String get editThingName => '编辑事情名称';

  @override
  String get name => '名称';

  @override
  String get remark => '备注';

  @override
  String get nameExists => '该名称已存在';

  @override
  String get defaultNameProtected => '默认名称不可修改';

  @override
  String get relatedRecords => '相关记录';

  @override
  String get noRelatedRecords => '暂无相关记录';

  @override
  String get selectThingName => '选择事情名称';

  @override
  String get searchThingName => '搜索事情名称';

  @override
  String get addFromGallery => '从相册选择';

  @override
  String get takePhoto => '拍照';

  @override
  String get startRecording => '开始录音';

  @override
  String get startTimer => '开始计时';

  @override
  String get stopRecording => '停止录音';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get recordDetail => '记录详情';

  @override
  String get photoView => '照片查看';

  @override
  String get annotationEditor => '图片标注';

  @override
  String get done => '完成';

  @override
  String get toolArrow => '箭头';

  @override
  String get toolText => '文字';

  @override
  String get toolRect => '矩形';

  @override
  String get toolDraw => '画笔';

  @override
  String get toolMosaic => '马赛克';

  @override
  String get toolUndo => '撤销';

  @override
  String get color => '颜色';

  @override
  String get strokeWidth => '粗细';

  @override
  String get fontSize => '字号';

  @override
  String get enterText => '输入文字';

  @override
  String get reminder => '提醒';

  @override
  String get reminderSet => '已设置提醒';

  @override
  String get closeReminder => '关闭提醒';

  @override
  String get reminderRecords => '提醒记录';

  @override
  String get noReminderRecords => '暂无提醒记录';

  @override
  String get noNote => '无备注';

  @override
  String version(String version) {
    return '事件记录 v$version';
  }

  @override
  String saveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get loading => '加载中...';

  @override
  String get pleaseSelect => '请选择';

  @override
  String get doNotSelect => '不选择';

  @override
  String get noMatchResult => '无匹配结果';

  @override
  String get recordNotExist => '记录不存在';

  @override
  String get edit => '编辑';

  @override
  String get confirmDeleteRecord => '确定要删除这条记录吗？此操作不可撤销。';

  @override
  String get createdAt => '创建于';

  @override
  String get updatedAt => '更新于';

  @override
  String get thingNameNotExist => '事件名称不存在';

  @override
  String get confirmDeleteThingName => '确定要删除这个事件名称吗？\n\n相关的记录不会被删除，但它们的事件名称会被移除。';

  @override
  String get defaultThingNameCannotDelete => '默认事件名称不能被删除';

  @override
  String get cannotCreateDefaultName => '不能创建名为\"默认\"的事件名称';

  @override
  String thingNameAlreadyExists(String name) {
    return '事件名称\"$name\"已存在，请使用其他名称';
  }

  @override
  String get add => '添加';

  @override
  String get noThingNames => '暂无事件名称';

  @override
  String get tapToAddThingName => '点击右下角按钮添加';

  @override
  String get pleaseEnterThingName => '请输入事件名称';

  @override
  String get pleaseEnterRemark => '请输入备注（可选）';

  @override
  String confirmDeleteSelectedThingNames(int count) {
    return '确定要删除选中的 $count 个事件名称吗？\n\n相关的记录不会被删除，但它们的事件名称会被移除。';
  }

  @override
  String exportFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String pickFromGalleryFailed(String error) {
    return '选择图片失败: $error';
  }

  @override
  String takePhotoFailed(String error) {
    return '拍照失败: $error';
  }

  @override
  String get gallery => '相册';

  @override
  String get justNow => '刚刚';

  @override
  String get minutesAgo => '分钟前';

  @override
  String get hoursAgo => '小时前';

  @override
  String get yesterday => '昨天';

  @override
  String get daysAgo => '天前';

  @override
  String get location => '位置';

  @override
  String get addLocation => '添加位置';

  @override
  String get getCurrentLocation => '获取当前位置';

  @override
  String get manualInput => '手动输入';

  @override
  String get locating => '定位中...';

  @override
  String get locationPermissionDenied => '位置权限被拒绝，请在设置中开启';

  @override
  String get microphonePermissionDenied => '麦克风权限被拒绝，请在设置中开启';

  @override
  String locationFailed(String error) {
    return '获取位置失败: $error';
  }

  @override
  String get addressHint => '请输入地址';

  @override
  String get clearLocation => '清除位置';

  @override
  String get videos => '视频';

  @override
  String get selectVideo => '选择视频';

  @override
  String pickVideoFailed(String error) {
    return '选择视频失败: $error';
  }

  @override
  String get viewBackupZips => '查看备份压缩包';

  @override
  String get viewBackupZipsDesc => '查看和管理导出的备份文件';

  @override
  String get backupList => '备份压缩包';

  @override
  String get noBackupZips => '暂无备份压缩包';

  @override
  String get noBackupZipsDesc => '导出记录后会在此处显示';

  @override
  String confirmDeleteBackup(int count) {
    return '确定要删除选中的 $count 个备份压缩包吗？\n\n此操作不会删除对应的记录。';
  }

  @override
  String get backupDeleted => '备份压缩包已删除';

  @override
  String backupDeleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String shareBackup(int count) {
    return '分享 $count 个备份压缩包';
  }

  @override
  String get fileSize => '文件大小';

  @override
  String get addAudioFromFile => '从文件选择';

  @override
  String pickAudioFailed(String error) {
    return '选择音频失败: $error';
  }

  @override
  String get documents => '文档';

  @override
  String get addDocument => '添加文档';

  @override
  String get addMoreDocuments => '添加更多';

  @override
  String get selectDocumentType => '选择文档类型';

  @override
  String get wordDocument => 'Word 文档';

  @override
  String get excelDocument => 'Excel 表格';

  @override
  String get pptDocument => 'PPT 演示文稿';

  @override
  String get pdfDocument => 'PDF 文档';

  @override
  String get markdownDocument => 'Markdown';

  @override
  String get textDocument => '纯文本';

  @override
  String get otherDocument => '其他文档';

  @override
  String pickDocumentFailed(String error) {
    return '选择文档失败: $error';
  }

  @override
  String get backupPassword => '备份密码';

  @override
  String get noPasswordSetDesc => '设置密码后，导出的备份将自动加密';

  @override
  String get enableEncryption => '启用加密';

  @override
  String get encryptionEnabledDesc => '导出时将对备份进行加密';

  @override
  String get encryptionDisabledDesc => '导出时不对备份进行加密';

  @override
  String get generatePassword => '生成密码';

  @override
  String get customPassword => '自定义密码';

  @override
  String get copyPassword => '复制密码';

  @override
  String get passwordStrength => '密码强度';

  @override
  String get changePassword => '修改密码';

  @override
  String get resetPassword => '重置密码';

  @override
  String get passwordCopied => '密码已复制到剪贴板';

  @override
  String get confirmResetPassword => '确认重置密码';

  @override
  String get confirmResetPasswordDesc => '确定要重置密码吗？新密码将自动生成并覆盖旧密码。';

  @override
  String get setCustomPassword => '设置自定义密码';

  @override
  String get password => '密码';

  @override
  String get enterPasswordHint => '请输入密码';

  @override
  String get favorites => '收藏';

  @override
  String get filterRecords => '筛选记录';

  @override
  String get showFavoritesOnly => '仅显示收藏';

  @override
  String get addToFavorites => '添加到收藏';

  @override
  String get removeFromFavorites => '取消收藏';

  @override
  String get tags => '标签';

  @override
  String get tagManagement => '标签管理';

  @override
  String get tagManagementDesc => '管理和创建标签';

  @override
  String get tagName => '标签名称';

  @override
  String get createTag => '创建标签';

  @override
  String get editTag => '编辑标签';

  @override
  String get selectColor => '选择颜色';

  @override
  String get noTags => '暂无标签';

  @override
  String get createFirstTag => '点击右下角按钮创建第一个标签';

  @override
  String confirmDeleteTag(String name) {
    return '确定要删除标签「$name」吗？\n\n此操作不会删除相关的记录。';
  }

  @override
  String get tagNameRequired => '请输入标签名称';

  @override
  String get preview => '预览';

  @override
  String get statistics => '统计';

  @override
  String get statisticsDesc => '查看记录统计和数据可视化';

  @override
  String get totalRecords => '总记录数';

  @override
  String get thisWeek => '本周';

  @override
  String get mediaBreakdown => '媒体统计';

  @override
  String get media => '媒体';

  @override
  String get audio => '录音';

  @override
  String get recordTrend => '记录趋势';

  @override
  String get categoryDistribution => '分类分布';

  @override
  String get noData => '暂无数据';

  @override
  String get search => '搜索';

  @override
  String get searchRecords => '搜索记录';

  @override
  String get noSearchResults => '无搜索结果';

  @override
  String get calendar => '日历';

  @override
  String get today => '今天';

  @override
  String get selectDayToViewRecords => '选择日期查看记录';

  @override
  String get noRecordsOnDay => '当日暂无记录';

  @override
  String get addRecord => '添加记录';

  @override
  String get records => '条记录';

  @override
  String get allRecords => '全部记录';

  @override
  String get filterByTag => '按标签筛选';

  @override
  String get timeline => '时间线';

  @override
  String get timelineDesc => '以时间线形式浏览记录';

  @override
  String get thisMonth => '本月';

  @override
  String get thisYear => '今年';

  @override
  String get allTime => '全部时间';

  @override
  String get older => '更早';

  @override
  String get linkedRecords => '关联记录';

  @override
  String get noLinkedRecords => '暂无关联记录';

  @override
  String get addLink => '添加关联';

  @override
  String get manageLinks => '管理关联';

  @override
  String moreLinkedRecords(int count) {
    return '还有 $count 条关联记录';
  }

  @override
  String get linkRecords => '关联记录';

  @override
  String get currentLinks => '当前关联';

  @override
  String get selectRecordToLink => '选择要关联的记录';

  @override
  String get noRecordsToLink => '没有可关联的记录';

  @override
  String get link => '关联';

  @override
  String get linkCreated => '已创建关联';

  @override
  String get linkRemoved => '已移除关联';

  @override
  String linkFailed(String error) {
    return '操作失败: $error';
  }

  @override
  String get repeatType => '重复类型';

  @override
  String get repeatNone => '不重复';

  @override
  String get repeatDaily => '每天';

  @override
  String get repeatWeekly => '每周';

  @override
  String get repeatMonthly => '每月';

  @override
  String get repeatYearly => '每年';

  @override
  String get recurringRecords => '重复记录';

  @override
  String get noRecurringRecords => '暂无重复记录';

  @override
  String get advancedSearch => '高级搜索';

  @override
  String get quickSearch => '快速搜索';

  @override
  String get todayStats => '今日统计';

  @override
  String get quickActions => '快捷操作';

  @override
  String get dateRange => '日期范围';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期';

  @override
  String get clearFilters => '清除筛选';

  @override
  String get searchResults => '搜索结果';

  @override
  String get showDashboard => '显示概览';

  @override
  String get hideDashboard => '隐藏概览';

  @override
  String get batchEdit => '批量编辑';

  @override
  String get changeThingName => '修改事情名称';

  @override
  String get changeThingNameHint => '批量修改记录的事件名称';

  @override
  String get addTags => '添加标签';

  @override
  String get addTagsHint => '批量添加标签到记录';

  @override
  String get removeTags => '移除标签';

  @override
  String get removeTagsHint => '批量从记录中移除标签';

  @override
  String get markAsFavorite => '标记为收藏';

  @override
  String get markAsFavoriteHint => '将选中的记录标记为收藏';

  @override
  String get removeFavorite => '取消收藏';

  @override
  String get removeFavoriteHint => '将选中的记录从收藏中移除';

  @override
  String batchEditFailed(String error) {
    return '批量编辑失败: $error';
  }

  @override
  String get clearSelection => '清除选择';

  @override
  String get selectTags => '选择标签';

  @override
  String get exportPdf => '导出 PDF';

  @override
  String get exportPdfDesc => '将记录导出为 PDF 文档';

  @override
  String get exportPdfSuccess => 'PDF 导出成功';

  @override
  String exportPdfFailed(String error) {
    return '导出 PDF 失败: $error';
  }

  @override
  String get shareRecord => '分享记录';

  @override
  String get playbackSpeed => '播放速度';

  @override
  String get speedSlow => '慢速';

  @override
  String get speedNormal => '正常';

  @override
  String get speedFast => '快速';

  @override
  String get videoPlayer => '视频播放器';

  @override
  String get audioPlayer => '音频播放器';

  @override
  String get fullscreen => '全屏';

  @override
  String get audioWaveform => '音频波形';

  @override
  String get voiceToText => '语音转文字';

  @override
  String get voiceToTextDesc => '将录音转换为文字';

  @override
  String voiceToTextFailed(String error) {
    return '语音转文字失败: $error';
  }

  @override
  String get speechToTextUnavailable => '此设备不支持语音转文字功能';

  @override
  String get recentSearches => '最近搜索';

  @override
  String get clearSearchHistory => '清除搜索历史';

  @override
  String get searchHistoryCleared => '搜索历史已清除';

  @override
  String get suggestions => '建议';

  @override
  String get recordTemplates => '记录模板';

  @override
  String get createTemplate => '创建模板';

  @override
  String get templateName => '模板名称';

  @override
  String get applyTemplate => '应用模板';

  @override
  String get deleteTemplate => '删除模板';

  @override
  String get noTemplates => '暂无模板';

  @override
  String get createFirstTemplate => '为常用的记录模式创建模板';

  @override
  String get templateApplied => '模板已应用';

  @override
  String get templateCreated => '模板已创建';

  @override
  String get templateDeleted => '模板已删除';

  @override
  String get exportStats => '导出统计';

  @override
  String get exportStatsDesc => '将统计数据导出为图片';

  @override
  String get statsExportSuccess => '统计数据导出成功';

  @override
  String get weeklyTrend => '周趋势';

  @override
  String get monthlyTrend => '月趋势';

  @override
  String get tagDistribution => '标签分布';

  @override
  String get thingNameDistribution => '事件名称分布';

  @override
  String get totalDuration => '总时长';

  @override
  String get averageDuration => '平均时长';

  @override
  String get mostUsedThingName => '最常用的事件名称';

  @override
  String get mostUsedTag => '最常用的标签';

  @override
  String get recordStreaks => '记录连续天数';

  @override
  String get currentStreak => '当前连续';

  @override
  String get longestStreak => '最长连续';

  @override
  String days(int count) {
    return '$count 天';
  }

  @override
  String recordCount(int count) {
    return '$count 条记录';
  }

  @override
  String hours(int count) {
    return '$count 小时';
  }

  @override
  String minutes(int count) {
    return '分钟';
  }

  @override
  String get recentRecords => '最近记录';

  @override
  String get quickAccess => '快捷访问';

  @override
  String get frequentlyUsed => '常用';

  @override
  String get daily => '每天';

  @override
  String get weekly => '每周';

  @override
  String get monthly => '每月';

  @override
  String get yearly => '每年';

  @override
  String get biweekly => '每两周';

  @override
  String get quarterly => '每季度';

  @override
  String get reminderManagement => '提醒管理';

  @override
  String get batchSetReminder => '批量设置提醒';

  @override
  String get batchSetReminderHint => '为选中的记录设置提醒';

  @override
  String get batchRemoveReminder => '批量移除提醒';

  @override
  String get batchRemoveReminderHint => '移除选中的记录的提醒';

  @override
  String get setReminder => '设置提醒';

  @override
  String get searchHint => '搜索记录...';

  @override
  String get voiceSearch => '语音搜索';

  @override
  String get reminders => '提醒';

  @override
  String get refresh => '刷新';

  @override
  String get exportStatistics => '导出统计';

  @override
  String get exportStatisticsDesc => '将统计数据导出为图片';

  @override
  String get weeklyDistribution => '周分布';

  @override
  String get syncSettings => '同步设置';

  @override
  String get syncStatus => '同步状态';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncIdle => '空闲';

  @override
  String get syncInProgress => '同步中...';

  @override
  String get syncSuccess => '同步成功';

  @override
  String get syncFailed => '同步失败';

  @override
  String get autoSync => '自动同步';

  @override
  String get autoSyncDesc => '启用后自动同步数据';

  @override
  String get syncInterval => '同步间隔';

  @override
  String get syncDirection => '同步方向';

  @override
  String get uploadOnly => '仅上传';

  @override
  String get uploadOnlyDesc => '仅上传本地数据到云端';

  @override
  String get downloadOnly => '仅下载';

  @override
  String get downloadOnlyDesc => '仅从云端下载数据';

  @override
  String get lastSyncTime => '上次同步时间';

  @override
  String get larkConnection => '飞书连接';

  @override
  String get larkConnected => '已连接';

  @override
  String get smartReminders => '智能提醒';

  @override
  String get noPatternsFound => '暂无模式';

  @override
  String get noPatternsDesc => '记录更多事件以发现你的提醒模式';

  @override
  String get patternsFound => '发现模式';

  @override
  String get highConfidence => '高置信度';

  @override
  String suggestedTime(String time) {
    return '建议时间: $time';
  }

  @override
  String confidence(int percent) {
    return '置信度: $percent%';
  }

  @override
  String get confidenceLabel => '置信度';

  @override
  String get analyzeNow => '立即分析';

  @override
  String get tapToApply => '点击应用';

  @override
  String reminderApplied(String time) {
    return '已应用提醒时间 $time';
  }

  @override
  String get charts => '数据图表';

  @override
  String get durationTrend => '时长趋势';

  @override
  String get recordCountTrend => '记录数趋势';

  @override
  String get hourlyDist => '小时分布';

  @override
  String get hourlyDistribution => '每小时分布';

  @override
  String get activeDays => '活跃天数';

  @override
  String mostActiveTime(String hour) {
    return '最活跃时间: $hour:00';
  }

  @override
  String get batchOperations => '批量操作';

  @override
  String get adjustTime => '调整时间';

  @override
  String get adjustTimeDesc => '批量调整记录的时间';

  @override
  String get adjustTimeTip => '选择时间偏移量（分钟）';

  @override
  String get minus15 => '-15分钟';

  @override
  String get plus15 => '+15分钟';

  @override
  String get minus60 => '-60分钟';

  @override
  String get plus60 => '+60分钟';

  @override
  String get changeThingNameDesc => '批量更改记录的事件名称';

  @override
  String get toggleFavorite => '标记收藏';

  @override
  String get toggleFavoriteDesc => '将选中的记录标记为收藏';

  @override
  String get removeFavoriteDesc => '取消选中的记录收藏状态';

  @override
  String get addTagsDesc => '为选中的记录添加标签';

  @override
  String get availableOperations => '可用操作';

  @override
  String get batchOperationDesc => '批量操作将应用到所有选中的记录';

  @override
  String selectedRecords(int count) {
    return '已选择 $count 条记录';
  }

  @override
  String get processing => '处理中...';

  @override
  String batchOperationSuccess(int count) {
    return '成功更新 $count 条记录';
  }

  @override
  String batchOperationFailed(String error) {
    return '批量操作失败: $error';
  }

  @override
  String get usageInsights => '使用洞察';

  @override
  String get noInsightsYet => '暂无洞察';

  @override
  String get insights => '洞察';

  @override
  String get achievements => '成就';

  @override
  String get retry => '重试';

  @override
  String get enhancedBackup => '增强备份';

  @override
  String get createBackup => '创建备份';

  @override
  String get backupSettings => '备份设置';

  @override
  String get restoreBackup => '恢复备份';

  @override
  String get deleteBackup => '删除备份';

  @override
  String get restore => '恢复';

  @override
  String get restoreReplace => '覆盖恢复';

  @override
  String get restoreMerge => '合并恢复';

  @override
  String get restoreWarning => '恢复备份将替换或合并现有数据';

  @override
  String restoreConfirmation(String name) {
    return '确定要恢复备份「$name」吗？';
  }

  @override
  String deleteConfirmation(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get noBackupsFound => '暂无备份';

  @override
  String get createFirstBackup => '创建第一个备份';

  @override
  String get createFirstBackupDesc => '创建备份以保护你的数据';

  @override
  String get fullBackup => '完整备份';

  @override
  String get fullBackupDesc => '备份所有数据';

  @override
  String get incrementalBackup => '增量备份';

  @override
  String get incrementalBackupDesc => '仅备份新增数据';

  @override
  String get auto => '自动';

  @override
  String get autoBackup => '自动备份';

  @override
  String get autoBackupDesc => '定期自动创建备份';

  @override
  String get maxBackups => '最大保留数量';

  @override
  String get selectInterval => '选择间隔';

  @override
  String get summary => '摘要';

  @override
  String get view => '查看';

  @override
  String get auto_sync => '自动同步';

  @override
  String get auto_syncDesc => '自动同步记录数据';

  @override
  String get goals => '目标追踪';

  @override
  String get goalsDesc => '设定并追踪你的目标';

  @override
  String get mood => '情绪记录';

  @override
  String get moodDesc => '记录每日心情变化';

  @override
  String get habits => '习惯追踪';

  @override
  String get habitsDesc => '培养好习惯';

  @override
  String get projects => '项目管理';

  @override
  String get projectsDesc => '管理你的项目';

  @override
  String get notificationCenter => '通知中心';

  @override
  String get notificationCenterDesc => '查看系统通知';

  @override
  String get dataReport => '数据分析报告';

  @override
  String get dataReportDesc => '生成统计报告';

  @override
  String get customTheme => '自定义主题';

  @override
  String get customThemeDesc => '选择你喜欢的主题';

  @override
  String get dataImport => '数据导入';

  @override
  String get dataImportDesc => '从其他应用导入数据';

  @override
  String get addGoal => '添加目标';

  @override
  String get goalTracking => '目标追踪';

  @override
  String get goalTitle => '目标标题';

  @override
  String get goalDescription => '目标描述';

  @override
  String get goalPriority => '优先级';

  @override
  String get goalDeadline => '截止日期';

  @override
  String get goalProgress => '进度';

  @override
  String get markCompleted => '标记完成';

  @override
  String get addMood => '记录心情';

  @override
  String get moodLevel => '心情程度';

  @override
  String get moodTriggers => '触发因素';

  @override
  String get addHabit => '添加习惯';

  @override
  String get habitName => '习惯名称';

  @override
  String get habitFrequency => '频率';

  @override
  String get bestStreak => '最佳连续';

  @override
  String get completeHabit => '完成';

  @override
  String get addProject => '创建项目';

  @override
  String get projectName => '项目名称';

  @override
  String get projectColor => '项目颜色';

  @override
  String get projectProgress => '进度';

  @override
  String get importFile => '导入文件';

  @override
  String get selectFile => '选择文件';

  @override
  String get startImport => '开始导入';

  @override
  String get importResult => '导入结果';

  @override
  String get importSuccess => '导入成功';

  @override
  String get importFailed => '导入失败';

  @override
  String get exportReport => '导出报告';

  @override
  String get dailyReport => '日报';

  @override
  String get weeklyReport => '周报';

  @override
  String get monthlyReport => '月报';

  @override
  String get themeOcean => '海洋';

  @override
  String get themeForest => '森林';

  @override
  String get themeSunset => '日落';

  @override
  String get themePurple => '紫罗兰';

  @override
  String get themeMidnight => '午夜';

  @override
  String get themeDarkForest => '暗夜森林';

  @override
  String get goalActive => '进行中';

  @override
  String get goalPaused => '已暂停';

  @override
  String get goalCompleted => '已完成';

  @override
  String get goalCancelled => '已取消';

  @override
  String get goalPriorityLow => '低';

  @override
  String get goalPriorityMedium => '中';

  @override
  String get goalPriorityHigh => '高';

  @override
  String get goalPriorityCritical => '紧急';

  @override
  String get projectActive => '进行中';

  @override
  String get projectPaused => '已暂停';

  @override
  String get projectCompleted => '已完成';

  @override
  String get projectArchived => '已归档';

  @override
  String get moodVeryBad => '非常差';

  @override
  String get moodBad => '较差';

  @override
  String get moodNeutral => '一般';

  @override
  String get moodGood => '良好';

  @override
  String get moodVeryGood => '非常好';

  @override
  String get frequencyDaily => '每天';

  @override
  String get frequencyWeekly => '每周';

  @override
  String get frequencyCustom => '自定义';

  @override
  String get recurrencePatterns => '重复模式';

  @override
  String get analyze => '分析';

  @override
  String get noRecurrencePatterns => '暂无重复模式';

  @override
  String get createRecordsToDetect => '创建更多记录以检测重复模式';

  @override
  String get confirmDeletePattern => '确定要删除此重复模式吗？';

  @override
  String monthlyOn(int day) {
    return '每月 $day 日';
  }

  @override
  String get advancedAnalytics => '高级分析';

  @override
  String get aiInsights => 'AI 洞察';

  @override
  String get activityTrend => '活动趋势';

  @override
  String get prediction => '预测';

  @override
  String get automationRules => '自动化规则';

  @override
  String get myRules => '我的规则';

  @override
  String get ruleTemplates => '规则模板';

  @override
  String get collaborativeWorkspace => '协作空间';

  @override
  String get inviteMember => '邀请成员';

  @override
  String get workspaces => '工作空间';

  @override
  String get teamMembers => '团队成员';

  @override
  String get viewAll => '查看全部';

  @override
  String get recentShared => '最近共享';

  @override
  String get members => '成员';

  @override
  String get createWorkspace => '创建工作空间';

  @override
  String get workspaceName => '工作空间名称';

  @override
  String get create => '创建';

  @override
  String get email => '邮箱';

  @override
  String get role => '角色';

  @override
  String get customReports => '自定义报告';

  @override
  String get selectReportType => '选择报告类型';

  @override
  String get generateReport => '生成报告';

  @override
  String get reportPreview => '报告预览';

  @override
  String get exportOptions => '导出选项';

  @override
  String get reportHistory => '报告历史';

  @override
  String get generatingReport => '正在生成报告...';

  @override
  String get dataExportHub => '数据导出中心';

  @override
  String get exportTemplates => '导出模板';

  @override
  String get customExport => '自定义导出';

  @override
  String get exportFormat => '导出格式';

  @override
  String get includeContent => '包含内容';

  @override
  String get exportPreview => '导出预览';

  @override
  String get startExport => '开始导出';

  @override
  String get documentScanner => '文档扫描';

  @override
  String get extractedText => '提取的文本';

  @override
  String get scannedDocuments => '已扫描文档';

  @override
  String get healthConnect => '健康连接';

  @override
  String get connected => '已连接';

  @override
  String get notConnected => '未连接';

  @override
  String get lastSync => '上次同步';

  @override
  String get disconnect => '断开连接';

  @override
  String get connect => '连接';

  @override
  String get syncOptions => '同步选项';

  @override
  String get steps => '步数';

  @override
  String get stepsDesc => '健康数据中的步数统计';

  @override
  String get sessionCompleted => '冥想完成';

  @override
  String get greatJob => '太棒了！';

  @override
  String get mindfulMoments => '正念时刻';

  @override
  String get sessions => '会话数';

  @override
  String get totalMinutes => '总时长';

  @override
  String get resumed => '继续';

  @override
  String get stop => '停止';

  @override
  String get selectDuration => '选择时长';

  @override
  String get minutesShort => '分钟';

  @override
  String get breathingGuide => '呼吸指导';

  @override
  String get inhaleExhale => '吸气 / 呼气';

  @override
  String get startSession => '开始冥想';

  @override
  String get meditationHistory => '冥想历史';

  @override
  String get notificationHub => '通知中心';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get pushNotifications => '推送通知';

  @override
  String get emailNotifications => '邮件通知';

  @override
  String get reminderNotifications => '提醒通知';

  @override
  String get weeklyDigest => '每周摘要';

  @override
  String get marketingEmails => '营销邮件';

  @override
  String get recentNotifications => '最近通知';

  @override
  String get clearAll => '全部清除';

  @override
  String get projectManagement => '项目管理';

  @override
  String get smartGeofence => '智能地理围栏';

  @override
  String get locationEnabled => '位置已启用';

  @override
  String get locationDisabled => '位置已禁用';

  @override
  String get myGeofences => '我的地理围栏';

  @override
  String get smartScheduling => '智能日程';

  @override
  String get suggestedTimeSlots => '建议时段';

  @override
  String get quickSchedule => '快速日程';

  @override
  String get todaySchedule => '今日日程';

  @override
  String get conflictDetection => '冲突检测';

  @override
  String get findOptimalTime => '查找最佳时间';

  @override
  String get sleepData => '睡眠数据';

  @override
  String get sleepDataDesc => '来自健康源的睡眠数据';

  @override
  String get heartRate => '心率';

  @override
  String get heartRateDesc => '来自健康源的心率数据';

  @override
  String get weight => '体重';

  @override
  String get weightDesc => '体重追踪';

  @override
  String get syncNowDesc => '立即同步健康数据';

  @override
  String get autoSyncSchedule => '自动同步日程';

  @override
  String get syncFrequency => '同步频率';

  @override
  String get syncDaily => '每日一次';

  @override
  String get syncing => '同步中...';

  @override
  String get every15Minutes => '每15分钟';

  @override
  String get everyHour => '每小时';

  @override
  String get description => '描述';

  @override
  String get invite => '邀请';

  @override
  String get paused => '已暂停';

  @override
  String get resume => '继续';

  @override
  String get sessionsCompleted => '已完成会话';

  @override
  String get totalTime => '总时间';

  @override
  String get smartSuggestions => '智能建议';

  @override
  String get dismissAll => '全部忽略';

  @override
  String get ignore => '忽略';

  @override
  String get voiceCommands => '语音命令';

  @override
  String get listening => '正在聆听...';

  @override
  String get tapToSpeak => '点击说话';

  @override
  String get availableCommands => '可用命令';

  @override
  String get commandHistory => '命令历史';

  @override
  String get habitStreak => '习惯连续';

  @override
  String get moodCalendar => '心情日历';

  @override
  String get quickStats => '快速统计';

  @override
  String get smartCalendar => '智能日历';

  @override
  String get timeAnalysis => '时间分析';

  @override
  String get dailyRoutine => '日常习惯';

  @override
  String get focusTimer => '专注计时';

  @override
  String get locationHistory => '位置历史';

  @override
  String get moodHeatmap => '心情热力图';

  @override
  String get tagCloud => '标签云';

  @override
  String get reminderAnalytics => '提醒分析';

  @override
  String get dailyScore => '每日评分';

  @override
  String get consecutiveDays => '连续天数';

  @override
  String get dataDashboard => '数据仪表盘';

  @override
  String get dailyRecordTrend => '每日记录趋势';

  @override
  String get goalTrackingDesc => '设定并追踪你的目标';

  @override
  String get habitTracking => '习惯追踪';

  @override
  String get habitTrackingDesc => '培养好习惯';

  @override
  String get projectManagementDesc => '管理你的项目';

  @override
  String get dataDashboardDesc => '查看数据概览和趋势';

  @override
  String get monthlyStats => '月度统计';

  @override
  String get noTrendData => '暂无趋势数据';

  @override
  String get overview => '概览';

  @override
  String get photosCount => '照片数量';

  @override
  String get ranking => '排名';

  @override
  String get tagRanking => '标签排名';

  @override
  String get thingNameRanking => '事件名称排名';

  @override
  String get times => '次';

  @override
  String get trend => '趋势';

  @override
  String get videosCount => '视频数量';

  @override
  String get recordCountLabel => '记录数';
}
