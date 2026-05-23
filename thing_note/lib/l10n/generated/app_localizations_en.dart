import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Event Record';

  @override
  String get settings => 'Settings';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get thingNameManage => 'Event Names';

  @override
  String get thingNameManageDesc => 'Manage available event names';

  @override
  String get clearTempZips => 'Clear Temp Archives';

  @override
  String get clearTempZipsDesc => 'Delete temporary files from sharing';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get confirmClear => 'Confirm Clear';

  @override
  String get confirmClearTemp => 'Are you sure you want to clear all temporary archives?\n\nThis will not delete your records.';

  @override
  String get confirmClearData => 'Are you sure you want to clear all data? This cannot be undone!';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmClearBtn => 'Clear';

  @override
  String get tempZipsCleared => 'Temporary archives cleared';

  @override
  String clearFailed(String error) {
    return 'Clear failed: $error';
  }

  @override
  String get allDataCleared => 'All data cleared';

  @override
  String get noRecords => 'No records yet';

  @override
  String get addFirstRecord => 'Tap the button below to add your first record';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get share => 'Share';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String confirmDeleteSelected(int count) {
    return 'Are you sure you want to delete $count selected records?';
  }

  @override
  String shareRecords(int count) {
    return 'Share $count records';
  }

  @override
  String shareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String loadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String get exporting => 'Exporting';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get dateFormat => 'Date Format';

  @override
  String get dateFormatYMD => 'YYYY-MM-DD';

  @override
  String get dateFormatMDY => 'MM/DD/YYYY';

  @override
  String get dateFormatDMY => 'DD/MM/YYYY';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get timeFormat24h => '24-hour';

  @override
  String get timeFormat12h => '12-hour';

  @override
  String get newRecord => 'New Record';

  @override
  String get editRecord => 'Edit Record';

  @override
  String get occurredAt => 'Occurred At';

  @override
  String get duration => 'Duration';

  @override
  String get note => 'Note';

  @override
  String get photos => 'Photos';

  @override
  String get audios => 'Audio';

  @override
  String get save => 'Save';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get unsavedChangesDesc => 'Are you sure you want to discard your edits?';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep Editing';

  @override
  String get thingName => 'Event Name';

  @override
  String get defaultThingName => 'Default';

  @override
  String get defaultThingNameRemark => 'Records without an event name will be categorized here';

  @override
  String get addThingName => 'Add Event Name';

  @override
  String get editThingName => 'Edit Event Name';

  @override
  String get name => 'Name';

  @override
  String get remark => 'Remark';

  @override
  String get nameExists => 'This name already exists';

  @override
  String get defaultNameProtected => 'Default name cannot be modified';

  @override
  String get relatedRecords => 'Related Records';

  @override
  String get noRelatedRecords => 'No related records';

  @override
  String get selectThingName => 'Select Event Name';

  @override
  String get searchThingName => 'Search event names';

  @override
  String get addFromGallery => 'From Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get startRecording => 'Start Recording';

  @override
  String get startTimer => 'Start Timer';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get recordDetail => 'Record Detail';

  @override
  String get photoView => 'Photo View';

  @override
  String get annotationEditor => 'Annotation Editor';

  @override
  String get done => 'Done';

  @override
  String get toolArrow => 'Arrow';

  @override
  String get toolText => 'Text';

  @override
  String get toolRect => 'Rectangle';

  @override
  String get toolDraw => 'Draw';

  @override
  String get toolMosaic => 'Mosaic';

  @override
  String get toolUndo => 'Undo';

  @override
  String get color => 'Color';

  @override
  String get strokeWidth => 'Stroke Width';

  @override
  String get fontSize => 'Font Size';

  @override
  String get enterText => 'Enter text';

  @override
  String get reminder => 'Reminder';

  @override
  String get reminderSet => 'Reminder set';

  @override
  String get closeReminder => 'Dismiss';

  @override
  String get reminderRecords => 'Reminders';

  @override
  String get noReminderRecords => 'No reminders';

  @override
  String get noNote => 'No note';

  @override
  String version(String version) {
    return 'Event Record v$version';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get pleaseSelect => 'Please select';

  @override
  String get doNotSelect => 'None';

  @override
  String get noMatchResult => 'No matches';

  @override
  String get recordNotExist => 'Record not found';

  @override
  String get edit => 'Edit';

  @override
  String get confirmDeleteRecord => 'Are you sure you want to delete this record? This cannot be undone.';

  @override
  String get createdAt => 'Created at';

  @override
  String get updatedAt => 'Updated at';

  @override
  String get thingNameNotExist => 'Event name not found';

  @override
  String get confirmDeleteThingName => 'Are you sure you want to delete this event name?\n\nRelated records will not be deleted, but their event name will be removed.';

  @override
  String get defaultThingNameCannotDelete => 'Default event name cannot be deleted';

  @override
  String get cannotCreateDefaultName => 'Cannot create an event named \"Default\"';

  @override
  String thingNameAlreadyExists(String name) {
    return 'Event name \"$name\" already exists, please use another name';
  }

  @override
  String get add => 'Add';

  @override
  String get noThingNames => 'No event names yet';

  @override
  String get tapToAddThingName => 'Tap the button below to add';

  @override
  String get pleaseEnterThingName => 'Enter event name';

  @override
  String get pleaseEnterRemark => 'Enter remark (optional)';

  @override
  String confirmDeleteSelectedThingNames(int count) {
    return 'Are you sure you want to delete $count selected event names?\n\nRelated records will not be deleted, but their event name will be removed.';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String pickFromGalleryFailed(String error) {
    return 'Failed to pick from gallery: $error';
  }

  @override
  String takePhotoFailed(String error) {
    return 'Failed to take photo: $error';
  }

  @override
  String get gallery => 'Gallery';

  @override
  String get justNow => 'Just now';

  @override
  String get minutesAgo => 'min ago';

  @override
  String get hoursAgo => 'hr ago';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get daysAgo => 'days ago';

  @override
  String get location => 'Location';

  @override
  String get addLocation => 'Add Location';

  @override
  String get getCurrentLocation => 'Get Current Location';

  @override
  String get manualInput => 'Manual Input';

  @override
  String get locating => 'Locating...';

  @override
  String get locationPermissionDenied => 'Location permission denied, please enable in settings';

  @override
  String get microphonePermissionDenied => 'Microphone permission denied, please enable in settings';

  @override
  String locationFailed(String error) {
    return 'Failed to get location: $error';
  }

  @override
  String get addressHint => 'Enter address';

  @override
  String get clearLocation => 'Clear Location';

  @override
  String get videos => 'Videos';

  @override
  String get selectVideo => 'Select Video';

  @override
  String pickVideoFailed(String error) {
    return 'Failed to pick video: $error';
  }

  @override
  String get viewBackupZips => 'View Backup Archives';

  @override
  String get viewBackupZipsDesc => 'View and manage exported backup files';

  @override
  String get backupList => 'Backup Archives';

  @override
  String get noBackupZips => 'No backup archives';

  @override
  String get noBackupZipsDesc => 'Exported records will appear here';

  @override
  String confirmDeleteBackup(int count) {
    return 'Are you sure you want to delete $count selected backup archives?\n\nThis will not delete the corresponding records.';
  }

  @override
  String get backupDeleted => 'Backup archives deleted';

  @override
  String backupDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String shareBackup(int count) {
    return 'Share $count backup archives';
  }

  @override
  String get fileSize => 'File Size';

  @override
  String get addAudioFromFile => 'From File';

  @override
  String pickAudioFailed(String error) {
    return 'Failed to pick audio: $error';
  }

  @override
  String get documents => 'Documents';

  @override
  String get addDocument => 'Add Document';

  @override
  String get addMoreDocuments => 'Add More';

  @override
  String get selectDocumentType => 'Select Document Type';

  @override
  String get wordDocument => 'Word Document';

  @override
  String get excelDocument => 'Excel Spreadsheet';

  @override
  String get pptDocument => 'PPT Presentation';

  @override
  String get pdfDocument => 'PDF Document';

  @override
  String get markdownDocument => 'Markdown';

  @override
  String get textDocument => 'Plain Text';

  @override
  String get otherDocument => 'Other Documents';

  @override
  String pickDocumentFailed(String error) {
    return 'Failed to pick document: $error';
  }

  @override
  String get backupPassword => 'Backup Password';

  @override
  String get noPasswordSetDesc => 'Set a password to automatically encrypt backups';

  @override
  String get enableEncryption => 'Enable Encryption';

  @override
  String get encryptionEnabledDesc => 'Backups will be encrypted when exporting';

  @override
  String get encryptionDisabledDesc => 'Backups will not be encrypted when exporting';

  @override
  String get generatePassword => 'Generate Password';

  @override
  String get customPassword => 'Custom Password';

  @override
  String get copyPassword => 'Copy Password';

  @override
  String get passwordStrength => 'Strength';

  @override
  String get changePassword => 'Change Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordCopied => 'Password copied to clipboard';

  @override
  String get confirmResetPassword => 'Confirm Reset Password';

  @override
  String get confirmResetPasswordDesc => 'Are you sure you want to reset the password? A new password will be generated.';

  @override
  String get setCustomPassword => 'Set Custom Password';

  @override
  String get password => 'Password';

  @override
  String get enterPasswordHint => 'Enter password';

  @override
  String get favorites => 'Favorites';

  @override
  String get filterRecords => 'Filter Records';

  @override
  String get showFavoritesOnly => 'Show Favorites Only';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get tags => 'Tags';

  @override
  String get tagManagement => 'Tag Management';

  @override
  String get tagManagementDesc => 'Manage tags for records';

  @override
  String get tagName => 'Tag Name';

  @override
  String get createTag => 'Create Tag';

  @override
  String get editTag => 'Edit Tag';

  @override
  String get selectColor => 'Select Color';

  @override
  String get noTags => 'No tags yet';

  @override
  String get createFirstTag => 'Tap the button below to create your first tag';

  @override
  String confirmDeleteTag(String name) {
    return 'Are you sure you want to delete the tag \"$name\"?\n\nThis will not delete related records.';
  }

  @override
  String get tagNameRequired => 'Please enter a tag name';

  @override
  String get preview => 'Preview';

  @override
  String get statistics => 'Statistics';

  @override
  String get statisticsDesc => 'View usage statistics';

  @override
  String get totalRecords => 'Total Records';

  @override
  String get thisWeek => 'This Week';

  @override
  String get mediaBreakdown => 'Media Breakdown';

  @override
  String get media => 'Media';

  @override
  String get audio => 'Audio';

  @override
  String get recordTrend => 'Record Trend';

  @override
  String get categoryDistribution => 'Category Distribution';

  @override
  String get noData => 'No data available';

  @override
  String get search => 'Search';

  @override
  String get searchRecords => 'Search Records';

  @override
  String get noSearchResults => 'No results found';

  @override
  String get calendar => 'Calendar';

  @override
  String get today => 'Today';

  @override
  String get selectDayToViewRecords => 'Select a day to view records';

  @override
  String get noRecordsOnDay => 'No records on this day';

  @override
  String get addRecord => 'Add Record';

  @override
  String get records => 'records';

  @override
  String get allRecords => 'All Records';

  @override
  String get filterByTag => 'Filter by Tag';

  @override
  String get timeline => 'Timeline';

  @override
  String get timelineDesc => 'Browse records in timeline view';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get allTime => 'All Time';

  @override
  String get older => 'Older';

  @override
  String get linkedRecords => 'Linked Records';

  @override
  String get noLinkedRecords => 'No linked records';

  @override
  String get addLink => 'Add Link';

  @override
  String get manageLinks => 'Manage Links';

  @override
  String moreLinkedRecords(int count) {
    return '$count more linked records';
  }

  @override
  String get linkRecords => 'Link Records';

  @override
  String get currentLinks => 'Current Links';

  @override
  String get selectRecordToLink => 'Select a record to link';

  @override
  String get noRecordsToLink => 'No records available to link';

  @override
  String get link => 'Link';

  @override
  String get linkCreated => 'Link created';

  @override
  String get linkRemoved => 'Link removed';

  @override
  String linkFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get repeatType => 'Repeat Type';

  @override
  String get repeatNone => 'None';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get repeatYearly => 'Yearly';

  @override
  String get recurringRecords => 'Recurring Records';

  @override
  String get noRecurringRecords => 'No recurring records';

  @override
  String get advancedSearch => 'Advanced Search';

  @override
  String get quickSearch => 'Quick Search';

  @override
  String get todayStats => 'Today\'s Stats';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get dateRange => 'Date Range';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get searchResults => 'Search Results';

  @override
  String get showDashboard => 'Show Overview';

  @override
  String get hideDashboard => 'Hide Overview';

  @override
  String get batchEdit => 'Batch Edit';

  @override
  String get changeThingName => 'Change Event Name';

  @override
  String get changeThingNameHint => 'Change event name for selected records';

  @override
  String get addTags => 'Add Tags';

  @override
  String get addTagsHint => 'Add tags to selected records';

  @override
  String get removeTags => 'Remove Tags';

  @override
  String get removeTagsHint => 'Remove tags from selected records';

  @override
  String get markAsFavorite => 'Mark as Favorite';

  @override
  String get markAsFavoriteHint => 'Mark selected records as favorites';

  @override
  String get removeFavorite => 'Remove Favorite';

  @override
  String get removeFavoriteHint => 'Remove favorite from selected records';

  @override
  String batchEditFailed(String error) {
    return 'Batch edit failed: $error';
  }

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get selectTags => 'Select Tags';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportPdfDesc => 'Export record as PDF document';

  @override
  String get exportPdfSuccess => 'PDF exported successfully';

  @override
  String exportPdfFailed(String error) {
    return 'Export PDF failed: $error';
  }

  @override
  String get shareRecord => 'Share Record';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get speedSlow => 'Slow';

  @override
  String get speedNormal => 'Normal';

  @override
  String get speedFast => 'Fast';

  @override
  String get videoPlayer => 'Video Player';

  @override
  String get audioPlayer => 'Audio Player';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get audioWaveform => 'Audio Waveform';

  @override
  String get voiceToText => 'Voice to Text';

  @override
  String get voiceToTextDesc => 'Convert voice recording to text';

  @override
  String voiceToTextFailed(String error) {
    return 'Voice to text failed: $error';
  }

  @override
  String get speechToTextUnavailable => 'Speech to text is not available on this device';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clearSearchHistory => 'Clear Search History';

  @override
  String get searchHistoryCleared => 'Search history cleared';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get recordTemplates => 'Record Templates';

  @override
  String get createTemplate => 'Create Template';

  @override
  String get templateName => 'Template Name';

  @override
  String get applyTemplate => 'Apply Template';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String get noTemplates => 'No templates yet';

  @override
  String get createFirstTemplate => 'Create templates for frequently used record patterns';

  @override
  String get templateApplied => 'Template applied';

  @override
  String get templateCreated => 'Template created';

  @override
  String get templateDeleted => 'Template deleted';

  @override
  String get exportStats => 'Export Statistics';

  @override
  String get exportStatsDesc => 'Export statistics as image';

  @override
  String get statsExportSuccess => 'Statistics exported successfully';

  @override
  String get weeklyTrend => 'Weekly Trend';

  @override
  String get monthlyTrend => 'Monthly Trend';

  @override
  String get tagDistribution => 'Tag Distribution';

  @override
  String get thingNameDistribution => 'Event Name Distribution';

  @override
  String get totalDuration => 'Total Duration';

  @override
  String get averageDuration => 'Average Duration';

  @override
  String get mostUsedThingName => 'Most Used Event Name';

  @override
  String get mostUsedTag => 'Most Used Tag';

  @override
  String get recordStreaks => 'Record Streaks';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get longestStreak => 'Longest Streak';

  @override
  String days(int count) {
    return '$count days';
  }

  @override
  String recordCount(int count) {
    return '$count records';
  }

  @override
  String hours(int count) {
    return '$count hours';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get recentRecords => 'Recent Records';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get frequentlyUsed => 'Frequently Used';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get biweekly => 'Biweekly';

  @override
  String get quarterly => 'Quarterly';

  @override
  String get reminderManagement => 'Reminder Management';

  @override
  String get batchSetReminder => 'Batch Set Reminder';

  @override
  String get batchSetReminderHint => 'Set reminder for selected records';

  @override
  String get batchRemoveReminder => 'Batch Remove Reminder';

  @override
  String get batchRemoveReminderHint => 'Remove reminder from selected records';

  @override
  String get setReminder => 'Set Reminder';

  @override
  String get searchHint => 'Search records...';

  @override
  String get voiceSearch => 'Voice Search';

  @override
  String get reminders => 'Reminders';

  @override
  String get refresh => 'Refresh';

  @override
  String get exportStatistics => 'Export Statistics';

  @override
  String get exportStatisticsDesc => 'Export statistics as image';

  @override
  String get weeklyDistribution => 'Weekly Distribution';

  @override
  String get syncSettings => 'Sync Settings';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncIdle => 'Idle';

  @override
  String get syncInProgress => 'Syncing...';

  @override
  String get syncSuccess => 'Sync successful';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get autoSync => 'Auto Sync';

  @override
  String get autoSyncDesc => 'Automatically sync data to cloud';

  @override
  String get syncInterval => 'Sync Interval';

  @override
  String get syncDirection => 'Sync Direction';

  @override
  String get uploadOnly => 'Upload Only';

  @override
  String get uploadOnlyDesc => 'Upload local data to cloud only';

  @override
  String get downloadOnly => 'Download Only';

  @override
  String get downloadOnlyDesc => 'Download data from cloud to local only';

  @override
  String get lastSyncTime => 'Last Sync Time';

  @override
  String get larkConnection => 'Lark Connection';

  @override
  String get larkConnected => 'Connected';

  @override
  String get smartReminders => 'Smart Reminders';

  @override
  String get noPatternsFound => 'No patterns found';

  @override
  String get noPatternsDesc => 'Record more events to discover your reminder patterns';

  @override
  String get patternsFound => 'Patterns Found';

  @override
  String get highConfidence => 'High Confidence';

  @override
  String suggestedTime(String time) {
    return 'Suggested time: $time';
  }

  @override
  String confidence(int percent) {
    return 'Confidence: $percent%';
  }

  @override
  String get confidenceLabel => 'Confidence';

  @override
  String get analyzeNow => 'Analyze Now';

  @override
  String get tapToApply => 'Tap to apply';

  @override
  String reminderApplied(String time) {
    return 'Reminder time applied: $time';
  }

  @override
  String get charts => 'Charts';

  @override
  String get durationTrend => 'Duration Trend';

  @override
  String get recordCountTrend => 'Record Count Trend';

  @override
  String get hourlyDist => 'Hourly Distribution';

  @override
  String get hourlyDistribution => 'Hourly Distribution';

  @override
  String get activeDays => 'Active Days';

  @override
  String mostActiveTime(String hour) {
    return 'Most active time: $hour:00';
  }

  @override
  String get batchOperations => 'Batch Operations';

  @override
  String get adjustTime => 'Adjust Time';

  @override
  String get adjustTimeDesc => 'Batch adjust record times';

  @override
  String get adjustTimeTip => 'Select time offset (minutes)';

  @override
  String get minus15 => '-15 min';

  @override
  String get plus15 => '+15 min';

  @override
  String get minus60 => '-60 min';

  @override
  String get plus60 => '+60 min';

  @override
  String get changeThingNameDesc => 'Batch change event names';

  @override
  String get toggleFavorite => 'Toggle Favorite';

  @override
  String get toggleFavoriteDesc => 'Mark selected records as favorites';

  @override
  String get removeFavoriteDesc => 'Remove favorite from selected records';

  @override
  String get addTagsDesc => 'Add tags to selected records';

  @override
  String get availableOperations => 'Available Operations';

  @override
  String get batchOperationDesc => 'Batch operations will be applied to all selected records';

  @override
  String selectedRecords(int count) {
    return '$count records selected';
  }

  @override
  String get processing => 'Processing...';

  @override
  String batchOperationSuccess(int count) {
    return 'Successfully updated $count records';
  }

  @override
  String batchOperationFailed(String error) {
    return 'Batch operation failed: $error';
  }

  @override
  String get usageInsights => 'Usage Insights';

  @override
  String get noInsightsYet => 'No insights yet';

  @override
  String get insights => 'Insights';

  @override
  String get achievements => 'Achievements';

  @override
  String get retry => 'Retry';

  @override
  String get enhancedBackup => 'Enhanced Backup';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get backupSettings => 'Backup Settings';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get deleteBackup => 'Delete Backup';

  @override
  String get restore => 'Restore';

  @override
  String get restoreReplace => 'Replace Restore';

  @override
  String get restoreMerge => 'Merge Restore';

  @override
  String get restoreWarning => 'Restoring backup will replace or merge existing data';

  @override
  String restoreConfirmation(String name) {
    return 'Are you sure you want to restore backup \"$name\"?';
  }

  @override
  String deleteConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get noBackupsFound => 'No backups found';

  @override
  String get createFirstBackup => 'Create First Backup';

  @override
  String get createFirstBackupDesc => 'Create a backup to protect your data';

  @override
  String get fullBackup => 'Full Backup';

  @override
  String get fullBackupDesc => 'Backup all data';

  @override
  String get incrementalBackup => 'Incremental Backup';

  @override
  String get incrementalBackupDesc => 'Backup only new data';

  @override
  String get auto => 'Auto';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get autoBackupDesc => 'Create backups automatically on schedule';

  @override
  String get maxBackups => 'Max Backups to Keep';

  @override
  String get selectInterval => 'Select Interval';

  @override
  String get summary => 'Summary';

  @override
  String get view => 'View';

  @override
  String get auto_sync => 'Auto Sync';

  @override
  String get auto_syncDesc => 'Automatically sync record data';

  @override
  String get goals => 'Goals';

  @override
  String get goalsDesc => 'Set and track your goals';

  @override
  String get mood => 'Mood';

  @override
  String get moodDesc => 'Track daily mood changes';

  @override
  String get habits => 'Habits';

  @override
  String get habitsDesc => 'Build good habits';

  @override
  String get projects => 'Projects';

  @override
  String get projectsDesc => 'Manage your projects';

  @override
  String get notificationCenter => 'Notification Center';

  @override
  String get notificationCenterDesc => 'View system notifications';

  @override
  String get dataReport => 'Data Report';

  @override
  String get dataReportDesc => 'Generate statistical reports';

  @override
  String get customTheme => 'Custom Theme';

  @override
  String get customThemeDesc => 'Choose your favorite theme';

  @override
  String get dataImport => 'Data Import';

  @override
  String get dataImportDesc => 'Import data from other apps';

  @override
  String get addGoal => 'Add Goal';

  @override
  String get goalTracking => 'Goal Tracking';

  @override
  String get goalTitle => 'Goal Title';

  @override
  String get goalDescription => 'Goal Description';

  @override
  String get goalPriority => 'Priority';

  @override
  String get goalDeadline => 'Deadline';

  @override
  String get goalProgress => 'Progress';

  @override
  String get markCompleted => 'Mark Completed';

  @override
  String get addMood => 'Record Mood';

  @override
  String get moodLevel => 'Mood Level';

  @override
  String get moodTriggers => 'Triggers';

  @override
  String get addHabit => 'Add Habit';

  @override
  String get habitName => 'Habit Name';

  @override
  String get habitFrequency => 'Frequency';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get completeHabit => 'Complete';

  @override
  String get addProject => 'Create Project';

  @override
  String get projectName => 'Project Name';

  @override
  String get projectColor => 'Project Color';

  @override
  String get projectProgress => 'Progress';

  @override
  String get importFile => 'Import File';

  @override
  String get selectFile => 'Select File';

  @override
  String get startImport => 'Start Import';

  @override
  String get importResult => 'Import Result';

  @override
  String get importSuccess => 'Import successful';

  @override
  String get importFailed => 'Import failed';

  @override
  String get exportReport => 'Export Report';

  @override
  String get dailyReport => 'Daily Report';

  @override
  String get weeklyReport => 'Weekly Report';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get themeOcean => 'Ocean';

  @override
  String get themeForest => 'Forest';

  @override
  String get themeSunset => 'Sunset';

  @override
  String get themePurple => 'Violet';

  @override
  String get themeMidnight => 'Midnight';

  @override
  String get themeDarkForest => 'Dark Forest';

  @override
  String get goalActive => 'Active';

  @override
  String get goalPaused => 'Paused';

  @override
  String get goalCompleted => 'Completed';

  @override
  String get goalCancelled => 'Cancelled';

  @override
  String get goalPriorityLow => 'Low';

  @override
  String get goalPriorityMedium => 'Medium';

  @override
  String get goalPriorityHigh => 'High';

  @override
  String get goalPriorityCritical => 'Critical';

  @override
  String get projectActive => 'Active';

  @override
  String get projectPaused => 'Paused';

  @override
  String get projectCompleted => 'Completed';

  @override
  String get projectArchived => 'Archived';

  @override
  String get moodVeryBad => 'Very Bad';

  @override
  String get moodBad => 'Bad';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodGood => 'Good';

  @override
  String get moodVeryGood => 'Very Good';

  @override
  String get frequencyDaily => 'Daily';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get frequencyCustom => 'Custom';

  @override
  String get recurrencePatterns => 'Recurrence Patterns';

  @override
  String get analyze => 'Analyze';

  @override
  String get noRecurrencePatterns => 'No recurrence patterns';

  @override
  String get createRecordsToDetect => 'Create more records to detect patterns';

  @override
  String get confirmDeletePattern => 'Delete this pattern?';

  @override
  String monthlyOn(int day) {
    return 'Monthly on day $day';
  }

  @override
  String get advancedAnalytics => 'Advanced Analytics';

  @override
  String get aiInsights => 'AI Insights';

  @override
  String get activityTrend => 'Activity Trend';

  @override
  String get prediction => 'Prediction';

  @override
  String get automationRules => 'Automation Rules';

  @override
  String get myRules => 'My Rules';

  @override
  String get ruleTemplates => 'Rule Templates';

  @override
  String get collaborativeWorkspace => 'Collaborative Workspace';

  @override
  String get inviteMember => 'Invite Member';

  @override
  String get workspaces => 'Workspaces';

  @override
  String get teamMembers => 'Team Members';

  @override
  String get viewAll => 'View All';

  @override
  String get recentShared => 'Recent Shared';

  @override
  String get members => 'Members';

  @override
  String get createWorkspace => 'Create Workspace';

  @override
  String get workspaceName => 'Workspace Name';

  @override
  String get create => 'Create';

  @override
  String get email => 'Email';

  @override
  String get role => 'Role';

  @override
  String get customReports => 'Custom Reports';

  @override
  String get selectReportType => 'Select Report Type';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get reportPreview => 'Report Preview';

  @override
  String get exportOptions => 'Export Options';

  @override
  String get reportHistory => 'Report History';

  @override
  String get generatingReport => 'Generating Report...';

  @override
  String get dataExportHub => 'Data Export Hub';

  @override
  String get exportTemplates => 'Export Templates';

  @override
  String get customExport => 'Custom Export';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get includeContent => 'Include Content';

  @override
  String get exportPreview => 'Export Preview';

  @override
  String get startExport => 'Start Export';

  @override
  String get documentScanner => 'Document Scanner';

  @override
  String get extractedText => 'Extracted Text';

  @override
  String get scannedDocuments => 'Scanned Documents';

  @override
  String get healthConnect => 'Health Connect';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not Connected';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connect => 'Connect';

  @override
  String get syncOptions => 'Sync Options';

  @override
  String get steps => 'Steps';

  @override
  String get stepsDesc => 'Step count from health data';

  @override
  String get sessionCompleted => 'Session Completed';

  @override
  String get greatJob => 'Great Job!';

  @override
  String get mindfulMoments => 'Mindful Moments';

  @override
  String get sessions => 'Sessions';

  @override
  String get totalMinutes => 'Total Minutes';

  @override
  String get resumed => 'Resume';

  @override
  String get stop => 'Stop';

  @override
  String get selectDuration => 'Select Duration';

  @override
  String get minutesShort => 'min';

  @override
  String get breathingGuide => 'Breathing Guide';

  @override
  String get inhaleExhale => 'Inhale / Exhale';

  @override
  String get startSession => 'Start Session';

  @override
  String get meditationHistory => 'Meditation History';

  @override
  String get notificationHub => 'Notification Hub';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get reminderNotifications => 'Reminder Notifications';

  @override
  String get weeklyDigest => 'Weekly Digest';

  @override
  String get marketingEmails => 'Marketing Emails';

  @override
  String get recentNotifications => 'Recent Notifications';

  @override
  String get clearAll => 'Clear All';

  @override
  String get projectManagement => 'Project Management';

  @override
  String get smartGeofence => 'Smart Geofence';

  @override
  String get locationEnabled => 'Location Enabled';

  @override
  String get locationDisabled => 'Location Disabled';

  @override
  String get myGeofences => 'My Geofences';

  @override
  String get smartScheduling => 'Smart Scheduling';

  @override
  String get suggestedTimeSlots => 'Suggested Time Slots';

  @override
  String get quickSchedule => 'Quick Schedule';

  @override
  String get todaySchedule => 'Today\'s Schedule';

  @override
  String get conflictDetection => 'Conflict Detection';

  @override
  String get findOptimalTime => 'Find Optimal Time';

  @override
  String get sleepData => 'Sleep Data';

  @override
  String get sleepDataDesc => 'Sleep data from health sources';

  @override
  String get heartRate => 'Heart Rate';

  @override
  String get heartRateDesc => 'Heart rate data from health sources';

  @override
  String get weight => 'Weight';

  @override
  String get weightDesc => 'Body weight tracking';

  @override
  String get syncNowDesc => 'Sync health data now';

  @override
  String get autoSyncSchedule => 'Auto Sync Schedule';

  @override
  String get syncFrequency => 'Sync Frequency';

  @override
  String get syncDaily => 'Once daily';

  @override
  String get syncing => 'Syncing...';

  @override
  String get every15Minutes => 'Every 15 minutes';

  @override
  String get everyHour => 'Every hour';

  @override
  String get description => 'Description';

  @override
  String get invite => 'Invite';

  @override
  String get paused => 'Paused';

  @override
  String get resume => 'Resume';

  @override
  String get sessionsCompleted => 'Sessions completed';

  @override
  String get totalTime => 'Total Time';

  @override
  String get smartSuggestions => 'Smart Suggestions';

  @override
  String get dismissAll => 'Dismiss All';

  @override
  String get ignore => 'Ignore';

  @override
  String get voiceCommands => 'Voice Commands';

  @override
  String get listening => 'Listening...';

  @override
  String get tapToSpeak => 'Tap to Speak';

  @override
  String get availableCommands => 'Available Commands';

  @override
  String get commandHistory => 'Command History';

  @override
  String get habitStreak => 'Habit Streak';

  @override
  String get moodCalendar => 'Mood Calendar';

  @override
  String get quickStats => 'Quick Stats';

  @override
  String get smartCalendar => 'Smart Calendar';

  @override
  String get timeAnalysis => 'Time Analysis';

  @override
  String get dailyRoutine => 'Daily Routine';

  @override
  String get focusTimer => 'Focus Timer';

  @override
  String get locationHistory => 'Location History';

  @override
  String get moodHeatmap => 'Mood Heatmap';

  @override
  String get tagCloud => 'Tag Cloud';

  @override
  String get reminderAnalytics => 'Reminder Analytics';

  @override
  String get dailyScore => 'Daily Score';

  @override
  String get consecutiveDays => 'Consecutive Days';

  @override
  String get dataDashboard => 'Data Dashboard';

  @override
  String get dailyRecordTrend => 'Daily Record Trend';

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
  String get monthlyStats => 'Monthly Stats';

  @override
  String get noTrendData => 'No Trend Data';

  @override
  String get overview => 'Overview';

  @override
  String get photosCount => 'Photos Count';

  @override
  String get ranking => 'Ranking';

  @override
  String get tagRanking => 'Tag Ranking';

  @override
  String get thingNameRanking => 'Event Name Ranking';

  @override
  String get times => 'times';

  @override
  String get trend => 'Trend';

  @override
  String get videosCount => 'Videos Count';

  @override
  String get recordCountLabel => 'Record Count';
}
