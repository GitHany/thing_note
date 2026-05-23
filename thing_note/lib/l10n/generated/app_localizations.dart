import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'事件记录'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @themeModeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get themeModeDark;

  /// No description provided for @selectTheme.
  ///
  /// In zh, this message translates to:
  /// **'选择主题'**
  String get selectTheme;

  /// No description provided for @thingNameManage.
  ///
  /// In zh, this message translates to:
  /// **'事情名称管理'**
  String get thingNameManage;

  /// No description provided for @thingNameManageDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理可用的事情名称列表'**
  String get thingNameManageDesc;

  /// No description provided for @clearTempZips.
  ///
  /// In zh, this message translates to:
  /// **'清除临时压缩包'**
  String get clearTempZips;

  /// No description provided for @clearTempZipsDesc.
  ///
  /// In zh, this message translates to:
  /// **'删除分享时生成的临时文件'**
  String get clearTempZipsDesc;

  /// No description provided for @clearAllData.
  ///
  /// In zh, this message translates to:
  /// **'清除所有数据'**
  String get clearAllData;

  /// No description provided for @confirmClear.
  ///
  /// In zh, this message translates to:
  /// **'确认清除'**
  String get confirmClear;

  /// No description provided for @confirmClearTemp.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有临时压缩包吗？\n\n此操作不会删除记录。'**
  String get confirmClearTemp;

  /// No description provided for @confirmClearData.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有数据吗？此操作不可撤销！'**
  String get confirmClearData;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @confirmClearBtn.
  ///
  /// In zh, this message translates to:
  /// **'确认清除'**
  String get confirmClearBtn;

  /// No description provided for @tempZipsCleared.
  ///
  /// In zh, this message translates to:
  /// **'临时压缩包已清除'**
  String get tempZipsCleared;

  /// No description provided for @clearFailed.
  ///
  /// In zh, this message translates to:
  /// **'清除失败: {error}'**
  String clearFailed(String error);

  /// No description provided for @allDataCleared.
  ///
  /// In zh, this message translates to:
  /// **'所有数据已清除'**
  String get allDataCleared;

  /// No description provided for @noRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无记录'**
  String get noRecords;

  /// No description provided for @addFirstRecord.
  ///
  /// In zh, this message translates to:
  /// **'点击右下角按钮添加第一条记录'**
  String get addFirstRecord;

  /// No description provided for @selectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 项'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get selectAll;

  /// No description provided for @share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除选中的 {count} 条记录吗？'**
  String confirmDeleteSelected(int count);

  /// No description provided for @shareRecords.
  ///
  /// In zh, this message translates to:
  /// **'分享 {count} 条记录'**
  String shareRecords(int count);

  /// No description provided for @shareFailed.
  ///
  /// In zh, this message translates to:
  /// **'分享失败: {error}'**
  String shareFailed(String error);

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败: {error}'**
  String loadFailed(String error);

  /// No description provided for @exporting.
  ///
  /// In zh, this message translates to:
  /// **'导出中'**
  String get exporting;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @selectLanguage.
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get selectLanguage;

  /// No description provided for @dateFormat.
  ///
  /// In zh, this message translates to:
  /// **'日期格式'**
  String get dateFormat;

  /// No description provided for @dateFormatYMD.
  ///
  /// In zh, this message translates to:
  /// **'YYYY-MM-DD'**
  String get dateFormatYMD;

  /// No description provided for @dateFormatMDY.
  ///
  /// In zh, this message translates to:
  /// **'MM/DD/YYYY'**
  String get dateFormatMDY;

  /// No description provided for @dateFormatDMY.
  ///
  /// In zh, this message translates to:
  /// **'DD/MM/YYYY'**
  String get dateFormatDMY;

  /// No description provided for @timeFormat.
  ///
  /// In zh, this message translates to:
  /// **'时间格式'**
  String get timeFormat;

  /// No description provided for @timeFormat24h.
  ///
  /// In zh, this message translates to:
  /// **'24小时制'**
  String get timeFormat24h;

  /// No description provided for @timeFormat12h.
  ///
  /// In zh, this message translates to:
  /// **'12小时制'**
  String get timeFormat12h;

  /// No description provided for @newRecord.
  ///
  /// In zh, this message translates to:
  /// **'新建记录'**
  String get newRecord;

  /// No description provided for @editRecord.
  ///
  /// In zh, this message translates to:
  /// **'编辑记录'**
  String get editRecord;

  /// No description provided for @occurredAt.
  ///
  /// In zh, this message translates to:
  /// **'发生时间'**
  String get occurredAt;

  /// No description provided for @duration.
  ///
  /// In zh, this message translates to:
  /// **'持续时长'**
  String get duration;

  /// No description provided for @note.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get note;

  /// No description provided for @photos.
  ///
  /// In zh, this message translates to:
  /// **'照片'**
  String get photos;

  /// No description provided for @audios.
  ///
  /// In zh, this message translates to:
  /// **'录音'**
  String get audios;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @unsavedChanges.
  ///
  /// In zh, this message translates to:
  /// **'有未保存的变更'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesDesc.
  ///
  /// In zh, this message translates to:
  /// **'确定要放弃当前编辑的内容吗？'**
  String get unsavedChangesDesc;

  /// No description provided for @discard.
  ///
  /// In zh, this message translates to:
  /// **'放弃'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In zh, this message translates to:
  /// **'继续编辑'**
  String get keepEditing;

  /// No description provided for @thingName.
  ///
  /// In zh, this message translates to:
  /// **'事情名称'**
  String get thingName;

  /// No description provided for @defaultThingName.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get defaultThingName;

  /// No description provided for @defaultThingNameRemark.
  ///
  /// In zh, this message translates to:
  /// **'未选择事件名称的记录将归类到此处'**
  String get defaultThingNameRemark;

  /// No description provided for @addThingName.
  ///
  /// In zh, this message translates to:
  /// **'添加事情名称'**
  String get addThingName;

  /// No description provided for @editThingName.
  ///
  /// In zh, this message translates to:
  /// **'编辑事情名称'**
  String get editThingName;

  /// No description provided for @name.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get name;

  /// No description provided for @remark.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get remark;

  /// No description provided for @nameExists.
  ///
  /// In zh, this message translates to:
  /// **'该名称已存在'**
  String get nameExists;

  /// No description provided for @defaultNameProtected.
  ///
  /// In zh, this message translates to:
  /// **'默认名称不可修改'**
  String get defaultNameProtected;

  /// No description provided for @relatedRecords.
  ///
  /// In zh, this message translates to:
  /// **'相关记录'**
  String get relatedRecords;

  /// No description provided for @noRelatedRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无相关记录'**
  String get noRelatedRecords;

  /// No description provided for @selectThingName.
  ///
  /// In zh, this message translates to:
  /// **'选择事情名称'**
  String get selectThingName;

  /// No description provided for @searchThingName.
  ///
  /// In zh, this message translates to:
  /// **'搜索事情名称'**
  String get searchThingName;

  /// No description provided for @addFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册选择'**
  String get addFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get takePhoto;

  /// No description provided for @startRecording.
  ///
  /// In zh, this message translates to:
  /// **'开始录音'**
  String get startRecording;

  /// No description provided for @startTimer.
  ///
  /// In zh, this message translates to:
  /// **'开始计时'**
  String get startTimer;

  /// No description provided for @stopRecording.
  ///
  /// In zh, this message translates to:
  /// **'停止录音'**
  String get stopRecording;

  /// No description provided for @play.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @recordDetail.
  ///
  /// In zh, this message translates to:
  /// **'记录详情'**
  String get recordDetail;

  /// No description provided for @photoView.
  ///
  /// In zh, this message translates to:
  /// **'照片查看'**
  String get photoView;

  /// No description provided for @annotationEditor.
  ///
  /// In zh, this message translates to:
  /// **'图片标注'**
  String get annotationEditor;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @toolArrow.
  ///
  /// In zh, this message translates to:
  /// **'箭头'**
  String get toolArrow;

  /// No description provided for @toolText.
  ///
  /// In zh, this message translates to:
  /// **'文字'**
  String get toolText;

  /// No description provided for @toolRect.
  ///
  /// In zh, this message translates to:
  /// **'矩形'**
  String get toolRect;

  /// No description provided for @toolDraw.
  ///
  /// In zh, this message translates to:
  /// **'画笔'**
  String get toolDraw;

  /// No description provided for @toolMosaic.
  ///
  /// In zh, this message translates to:
  /// **'马赛克'**
  String get toolMosaic;

  /// No description provided for @toolUndo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get toolUndo;

  /// No description provided for @color.
  ///
  /// In zh, this message translates to:
  /// **'颜色'**
  String get color;

  /// No description provided for @strokeWidth.
  ///
  /// In zh, this message translates to:
  /// **'粗细'**
  String get strokeWidth;

  /// No description provided for @fontSize.
  ///
  /// In zh, this message translates to:
  /// **'字号'**
  String get fontSize;

  /// No description provided for @enterText.
  ///
  /// In zh, this message translates to:
  /// **'输入文字'**
  String get enterText;

  /// No description provided for @reminder.
  ///
  /// In zh, this message translates to:
  /// **'提醒'**
  String get reminder;

  /// No description provided for @reminderSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置提醒'**
  String get reminderSet;

  /// No description provided for @closeReminder.
  ///
  /// In zh, this message translates to:
  /// **'关闭提醒'**
  String get closeReminder;

  /// No description provided for @reminderRecords.
  ///
  /// In zh, this message translates to:
  /// **'提醒记录'**
  String get reminderRecords;

  /// No description provided for @noReminderRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无提醒记录'**
  String get noReminderRecords;

  /// No description provided for @noNote.
  ///
  /// In zh, this message translates to:
  /// **'无备注'**
  String get noNote;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'事件记录 v{version}'**
  String version(String version);

  /// No description provided for @saveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {error}'**
  String saveFailed(String error);

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// No description provided for @pleaseSelect.
  ///
  /// In zh, this message translates to:
  /// **'请选择'**
  String get pleaseSelect;

  /// No description provided for @doNotSelect.
  ///
  /// In zh, this message translates to:
  /// **'不选择'**
  String get doNotSelect;

  /// No description provided for @noMatchResult.
  ///
  /// In zh, this message translates to:
  /// **'无匹配结果'**
  String get noMatchResult;

  /// No description provided for @recordNotExist.
  ///
  /// In zh, this message translates to:
  /// **'记录不存在'**
  String get recordNotExist;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @confirmDeleteRecord.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这条记录吗？此操作不可撤销。'**
  String get confirmDeleteRecord;

  /// No description provided for @createdAt.
  ///
  /// In zh, this message translates to:
  /// **'创建于'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In zh, this message translates to:
  /// **'更新于'**
  String get updatedAt;

  /// No description provided for @thingNameNotExist.
  ///
  /// In zh, this message translates to:
  /// **'事件名称不存在'**
  String get thingNameNotExist;

  /// No description provided for @confirmDeleteThingName.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这个事件名称吗？\n\n相关的记录不会被删除，但它们的事件名称会被移除。'**
  String get confirmDeleteThingName;

  /// No description provided for @defaultThingNameCannotDelete.
  ///
  /// In zh, this message translates to:
  /// **'默认事件名称不能被删除'**
  String get defaultThingNameCannotDelete;

  /// No description provided for @cannotCreateDefaultName.
  ///
  /// In zh, this message translates to:
  /// **'不能创建名为\"默认\"的事件名称'**
  String get cannotCreateDefaultName;

  /// No description provided for @thingNameAlreadyExists.
  ///
  /// In zh, this message translates to:
  /// **'事件名称\"{name}\"已存在，请使用其他名称'**
  String thingNameAlreadyExists(String name);

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @noThingNames.
  ///
  /// In zh, this message translates to:
  /// **'暂无事件名称'**
  String get noThingNames;

  /// No description provided for @tapToAddThingName.
  ///
  /// In zh, this message translates to:
  /// **'点击右下角按钮添加'**
  String get tapToAddThingName;

  /// No description provided for @pleaseEnterThingName.
  ///
  /// In zh, this message translates to:
  /// **'请输入事件名称'**
  String get pleaseEnterThingName;

  /// No description provided for @pleaseEnterRemark.
  ///
  /// In zh, this message translates to:
  /// **'请输入备注（可选）'**
  String get pleaseEnterRemark;

  /// No description provided for @confirmDeleteSelectedThingNames.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除选中的 {count} 个事件名称吗？\n\n相关的记录不会被删除，但它们的事件名称会被移除。'**
  String confirmDeleteSelectedThingNames(int count);

  /// No description provided for @exportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败: {error}'**
  String exportFailed(String error);

  /// No description provided for @pickFromGalleryFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择图片失败: {error}'**
  String pickFromGalleryFailed(String error);

  /// No description provided for @takePhotoFailed.
  ///
  /// In zh, this message translates to:
  /// **'拍照失败: {error}'**
  String takePhotoFailed(String error);

  /// No description provided for @gallery.
  ///
  /// In zh, this message translates to:
  /// **'相册'**
  String get gallery;

  /// No description provided for @justNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'分钟前'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'小时前'**
  String get hoursAgo;

  /// No description provided for @yesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In zh, this message translates to:
  /// **'天前'**
  String get daysAgo;

  /// No description provided for @location.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get location;

  /// No description provided for @addLocation.
  ///
  /// In zh, this message translates to:
  /// **'添加位置'**
  String get addLocation;

  /// No description provided for @getCurrentLocation.
  ///
  /// In zh, this message translates to:
  /// **'获取当前位置'**
  String get getCurrentLocation;

  /// No description provided for @manualInput.
  ///
  /// In zh, this message translates to:
  /// **'手动输入'**
  String get manualInput;

  /// No description provided for @locating.
  ///
  /// In zh, this message translates to:
  /// **'定位中...'**
  String get locating;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'位置权限被拒绝，请在设置中开启'**
  String get locationPermissionDenied;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'麦克风权限被拒绝，请在设置中开启'**
  String get microphonePermissionDenied;

  /// No description provided for @locationFailed.
  ///
  /// In zh, this message translates to:
  /// **'获取位置失败: {error}'**
  String locationFailed(String error);

  /// No description provided for @addressHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入地址'**
  String get addressHint;

  /// No description provided for @clearLocation.
  ///
  /// In zh, this message translates to:
  /// **'清除位置'**
  String get clearLocation;

  /// No description provided for @videos.
  ///
  /// In zh, this message translates to:
  /// **'视频'**
  String get videos;

  /// No description provided for @selectVideo.
  ///
  /// In zh, this message translates to:
  /// **'选择视频'**
  String get selectVideo;

  /// No description provided for @pickVideoFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择视频失败: {error}'**
  String pickVideoFailed(String error);

  /// No description provided for @viewBackupZips.
  ///
  /// In zh, this message translates to:
  /// **'查看备份压缩包'**
  String get viewBackupZips;

  /// No description provided for @viewBackupZipsDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看和管理导出的备份文件'**
  String get viewBackupZipsDesc;

  /// No description provided for @backupList.
  ///
  /// In zh, this message translates to:
  /// **'备份压缩包'**
  String get backupList;

  /// No description provided for @noBackupZips.
  ///
  /// In zh, this message translates to:
  /// **'暂无备份压缩包'**
  String get noBackupZips;

  /// No description provided for @noBackupZipsDesc.
  ///
  /// In zh, this message translates to:
  /// **'导出记录后会在此处显示'**
  String get noBackupZipsDesc;

  /// No description provided for @confirmDeleteBackup.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除选中的 {count} 个备份压缩包吗？\n\n此操作不会删除对应的记录。'**
  String confirmDeleteBackup(int count);

  /// No description provided for @backupDeleted.
  ///
  /// In zh, this message translates to:
  /// **'备份压缩包已删除'**
  String get backupDeleted;

  /// No description provided for @backupDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败: {error}'**
  String backupDeleteFailed(String error);

  /// No description provided for @shareBackup.
  ///
  /// In zh, this message translates to:
  /// **'分享 {count} 个备份压缩包'**
  String shareBackup(int count);

  /// No description provided for @fileSize.
  ///
  /// In zh, this message translates to:
  /// **'文件大小'**
  String get fileSize;

  /// No description provided for @addAudioFromFile.
  ///
  /// In zh, this message translates to:
  /// **'从文件选择'**
  String get addAudioFromFile;

  /// No description provided for @pickAudioFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择音频失败: {error}'**
  String pickAudioFailed(String error);

  /// No description provided for @documents.
  ///
  /// In zh, this message translates to:
  /// **'文档'**
  String get documents;

  /// No description provided for @addDocument.
  ///
  /// In zh, this message translates to:
  /// **'添加文档'**
  String get addDocument;

  /// No description provided for @addMoreDocuments.
  ///
  /// In zh, this message translates to:
  /// **'添加更多'**
  String get addMoreDocuments;

  /// No description provided for @selectDocumentType.
  ///
  /// In zh, this message translates to:
  /// **'选择文档类型'**
  String get selectDocumentType;

  /// No description provided for @wordDocument.
  ///
  /// In zh, this message translates to:
  /// **'Word 文档'**
  String get wordDocument;

  /// No description provided for @excelDocument.
  ///
  /// In zh, this message translates to:
  /// **'Excel 表格'**
  String get excelDocument;

  /// No description provided for @pptDocument.
  ///
  /// In zh, this message translates to:
  /// **'PPT 演示文稿'**
  String get pptDocument;

  /// No description provided for @pdfDocument.
  ///
  /// In zh, this message translates to:
  /// **'PDF 文档'**
  String get pdfDocument;

  /// No description provided for @markdownDocument.
  ///
  /// In zh, this message translates to:
  /// **'Markdown'**
  String get markdownDocument;

  /// No description provided for @textDocument.
  ///
  /// In zh, this message translates to:
  /// **'纯文本'**
  String get textDocument;

  /// No description provided for @otherDocument.
  ///
  /// In zh, this message translates to:
  /// **'其他文档'**
  String get otherDocument;

  /// No description provided for @pickDocumentFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择文档失败: {error}'**
  String pickDocumentFailed(String error);

  /// No description provided for @backupPassword.
  ///
  /// In zh, this message translates to:
  /// **'备份密码'**
  String get backupPassword;

  /// No description provided for @noPasswordSetDesc.
  ///
  /// In zh, this message translates to:
  /// **'设置密码后，导出的备份将自动加密'**
  String get noPasswordSetDesc;

  /// No description provided for @enableEncryption.
  ///
  /// In zh, this message translates to:
  /// **'启用加密'**
  String get enableEncryption;

  /// No description provided for @encryptionEnabledDesc.
  ///
  /// In zh, this message translates to:
  /// **'导出时将对备份进行加密'**
  String get encryptionEnabledDesc;

  /// No description provided for @encryptionDisabledDesc.
  ///
  /// In zh, this message translates to:
  /// **'导出时不对备份进行加密'**
  String get encryptionDisabledDesc;

  /// No description provided for @generatePassword.
  ///
  /// In zh, this message translates to:
  /// **'生成密码'**
  String get generatePassword;

  /// No description provided for @customPassword.
  ///
  /// In zh, this message translates to:
  /// **'自定义密码'**
  String get customPassword;

  /// No description provided for @copyPassword.
  ///
  /// In zh, this message translates to:
  /// **'复制密码'**
  String get copyPassword;

  /// No description provided for @passwordStrength.
  ///
  /// In zh, this message translates to:
  /// **'密码强度'**
  String get passwordStrength;

  /// No description provided for @changePassword.
  ///
  /// In zh, this message translates to:
  /// **'修改密码'**
  String get changePassword;

  /// No description provided for @resetPassword.
  ///
  /// In zh, this message translates to:
  /// **'重置密码'**
  String get resetPassword;

  /// No description provided for @passwordCopied.
  ///
  /// In zh, this message translates to:
  /// **'密码已复制到剪贴板'**
  String get passwordCopied;

  /// No description provided for @confirmResetPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认重置密码'**
  String get confirmResetPassword;

  /// No description provided for @confirmResetPasswordDesc.
  ///
  /// In zh, this message translates to:
  /// **'确定要重置密码吗？新密码将自动生成并覆盖旧密码。'**
  String get confirmResetPasswordDesc;

  /// No description provided for @setCustomPassword.
  ///
  /// In zh, this message translates to:
  /// **'设置自定义密码'**
  String get setCustomPassword;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @enterPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get enterPasswordHint;

  /// No description provided for @favorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favorites;

  /// No description provided for @filterRecords.
  ///
  /// In zh, this message translates to:
  /// **'筛选记录'**
  String get filterRecords;

  /// No description provided for @showFavoritesOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅显示收藏'**
  String get showFavoritesOnly;

  /// No description provided for @addToFavorites.
  ///
  /// In zh, this message translates to:
  /// **'添加到收藏'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get removeFromFavorites;

  /// No description provided for @tags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get tags;

  /// No description provided for @tagManagement.
  ///
  /// In zh, this message translates to:
  /// **'标签管理'**
  String get tagManagement;

  /// No description provided for @tagManagementDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理和创建标签'**
  String get tagManagementDesc;

  /// No description provided for @tagName.
  ///
  /// In zh, this message translates to:
  /// **'标签名称'**
  String get tagName;

  /// No description provided for @createTag.
  ///
  /// In zh, this message translates to:
  /// **'创建标签'**
  String get createTag;

  /// No description provided for @editTag.
  ///
  /// In zh, this message translates to:
  /// **'编辑标签'**
  String get editTag;

  /// No description provided for @selectColor.
  ///
  /// In zh, this message translates to:
  /// **'选择颜色'**
  String get selectColor;

  /// No description provided for @noTags.
  ///
  /// In zh, this message translates to:
  /// **'暂无标签'**
  String get noTags;

  /// No description provided for @createFirstTag.
  ///
  /// In zh, this message translates to:
  /// **'点击右下角按钮创建第一个标签'**
  String get createFirstTag;

  /// No description provided for @confirmDeleteTag.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除标签「{name}」吗？\n\n此操作不会删除相关的记录。'**
  String confirmDeleteTag(String name);

  /// No description provided for @tagNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入标签名称'**
  String get tagNameRequired;

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// No description provided for @statistics.
  ///
  /// In zh, this message translates to:
  /// **'统计'**
  String get statistics;

  /// No description provided for @statisticsDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看记录统计和数据可视化'**
  String get statisticsDesc;

  /// No description provided for @totalRecords.
  ///
  /// In zh, this message translates to:
  /// **'总记录数'**
  String get totalRecords;

  /// No description provided for @thisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get thisWeek;

  /// No description provided for @mediaBreakdown.
  ///
  /// In zh, this message translates to:
  /// **'媒体统计'**
  String get mediaBreakdown;

  /// No description provided for @media.
  ///
  /// In zh, this message translates to:
  /// **'媒体'**
  String get media;

  /// No description provided for @audio.
  ///
  /// In zh, this message translates to:
  /// **'录音'**
  String get audio;

  /// No description provided for @recordTrend.
  ///
  /// In zh, this message translates to:
  /// **'记录趋势'**
  String get recordTrend;

  /// No description provided for @categoryDistribution.
  ///
  /// In zh, this message translates to:
  /// **'分类分布'**
  String get categoryDistribution;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @searchRecords.
  ///
  /// In zh, this message translates to:
  /// **'搜索记录'**
  String get searchRecords;

  /// No description provided for @noSearchResults.
  ///
  /// In zh, this message translates to:
  /// **'无搜索结果'**
  String get noSearchResults;

  /// No description provided for @calendar.
  ///
  /// In zh, this message translates to:
  /// **'日历'**
  String get calendar;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @selectDayToViewRecords.
  ///
  /// In zh, this message translates to:
  /// **'选择日期查看记录'**
  String get selectDayToViewRecords;

  /// No description provided for @noRecordsOnDay.
  ///
  /// In zh, this message translates to:
  /// **'当日暂无记录'**
  String get noRecordsOnDay;

  /// No description provided for @addRecord.
  ///
  /// In zh, this message translates to:
  /// **'添加记录'**
  String get addRecord;

  /// No description provided for @records.
  ///
  /// In zh, this message translates to:
  /// **'条记录'**
  String get records;

  /// No description provided for @allRecords.
  ///
  /// In zh, this message translates to:
  /// **'全部记录'**
  String get allRecords;

  /// No description provided for @filterByTag.
  ///
  /// In zh, this message translates to:
  /// **'按标签筛选'**
  String get filterByTag;

  /// No description provided for @timeline.
  ///
  /// In zh, this message translates to:
  /// **'时间线'**
  String get timeline;

  /// No description provided for @timelineDesc.
  ///
  /// In zh, this message translates to:
  /// **'以时间线形式浏览记录'**
  String get timelineDesc;

  /// No description provided for @thisMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In zh, this message translates to:
  /// **'今年'**
  String get thisYear;

  /// No description provided for @allTime.
  ///
  /// In zh, this message translates to:
  /// **'全部时间'**
  String get allTime;

  /// No description provided for @older.
  ///
  /// In zh, this message translates to:
  /// **'更早'**
  String get older;

  /// No description provided for @linkedRecords.
  ///
  /// In zh, this message translates to:
  /// **'关联记录'**
  String get linkedRecords;

  /// No description provided for @noLinkedRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无关联记录'**
  String get noLinkedRecords;

  /// No description provided for @addLink.
  ///
  /// In zh, this message translates to:
  /// **'添加关联'**
  String get addLink;

  /// No description provided for @manageLinks.
  ///
  /// In zh, this message translates to:
  /// **'管理关联'**
  String get manageLinks;

  /// No description provided for @moreLinkedRecords.
  ///
  /// In zh, this message translates to:
  /// **'还有 {count} 条关联记录'**
  String moreLinkedRecords(int count);

  /// No description provided for @linkRecords.
  ///
  /// In zh, this message translates to:
  /// **'关联记录'**
  String get linkRecords;

  /// No description provided for @currentLinks.
  ///
  /// In zh, this message translates to:
  /// **'当前关联'**
  String get currentLinks;

  /// No description provided for @selectRecordToLink.
  ///
  /// In zh, this message translates to:
  /// **'选择要关联的记录'**
  String get selectRecordToLink;

  /// No description provided for @noRecordsToLink.
  ///
  /// In zh, this message translates to:
  /// **'没有可关联的记录'**
  String get noRecordsToLink;

  /// No description provided for @link.
  ///
  /// In zh, this message translates to:
  /// **'关联'**
  String get link;

  /// No description provided for @linkCreated.
  ///
  /// In zh, this message translates to:
  /// **'已创建关联'**
  String get linkCreated;

  /// No description provided for @linkRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已移除关联'**
  String get linkRemoved;

  /// No description provided for @linkFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败: {error}'**
  String linkFailed(String error);

  /// No description provided for @repeatType.
  ///
  /// In zh, this message translates to:
  /// **'重复类型'**
  String get repeatType;

  /// No description provided for @repeatNone.
  ///
  /// In zh, this message translates to:
  /// **'不重复'**
  String get repeatNone;

  /// No description provided for @repeatDaily.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In zh, this message translates to:
  /// **'每月'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In zh, this message translates to:
  /// **'每年'**
  String get repeatYearly;

  /// No description provided for @recurringRecords.
  ///
  /// In zh, this message translates to:
  /// **'重复记录'**
  String get recurringRecords;

  /// No description provided for @noRecurringRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无重复记录'**
  String get noRecurringRecords;

  /// No description provided for @advancedSearch.
  ///
  /// In zh, this message translates to:
  /// **'高级搜索'**
  String get advancedSearch;

  /// No description provided for @quickSearch.
  ///
  /// In zh, this message translates to:
  /// **'快速搜索'**
  String get quickSearch;

  /// No description provided for @todayStats.
  ///
  /// In zh, this message translates to:
  /// **'今日统计'**
  String get todayStats;

  /// No description provided for @quickActions.
  ///
  /// In zh, this message translates to:
  /// **'快捷操作'**
  String get quickActions;

  /// No description provided for @dateRange.
  ///
  /// In zh, this message translates to:
  /// **'日期范围'**
  String get dateRange;

  /// No description provided for @startDate.
  ///
  /// In zh, this message translates to:
  /// **'开始日期'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In zh, this message translates to:
  /// **'结束日期'**
  String get endDate;

  /// No description provided for @clearFilters.
  ///
  /// In zh, this message translates to:
  /// **'清除筛选'**
  String get clearFilters;

  /// No description provided for @searchResults.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果'**
  String get searchResults;

  /// No description provided for @showDashboard.
  ///
  /// In zh, this message translates to:
  /// **'显示概览'**
  String get showDashboard;

  /// No description provided for @hideDashboard.
  ///
  /// In zh, this message translates to:
  /// **'隐藏概览'**
  String get hideDashboard;

  /// No description provided for @batchEdit.
  ///
  /// In zh, this message translates to:
  /// **'批量编辑'**
  String get batchEdit;

  /// No description provided for @changeThingName.
  ///
  /// In zh, this message translates to:
  /// **'修改事情名称'**
  String get changeThingName;

  /// No description provided for @changeThingNameHint.
  ///
  /// In zh, this message translates to:
  /// **'批量修改记录的事件名称'**
  String get changeThingNameHint;

  /// No description provided for @addTags.
  ///
  /// In zh, this message translates to:
  /// **'添加标签'**
  String get addTags;

  /// No description provided for @addTagsHint.
  ///
  /// In zh, this message translates to:
  /// **'批量添加标签到记录'**
  String get addTagsHint;

  /// No description provided for @removeTags.
  ///
  /// In zh, this message translates to:
  /// **'移除标签'**
  String get removeTags;

  /// No description provided for @removeTagsHint.
  ///
  /// In zh, this message translates to:
  /// **'批量从记录中移除标签'**
  String get removeTagsHint;

  /// No description provided for @markAsFavorite.
  ///
  /// In zh, this message translates to:
  /// **'标记为收藏'**
  String get markAsFavorite;

  /// No description provided for @markAsFavoriteHint.
  ///
  /// In zh, this message translates to:
  /// **'将选中的记录标记为收藏'**
  String get markAsFavoriteHint;

  /// No description provided for @removeFavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get removeFavorite;

  /// No description provided for @removeFavoriteHint.
  ///
  /// In zh, this message translates to:
  /// **'将选中的记录从收藏中移除'**
  String get removeFavoriteHint;

  /// No description provided for @batchEditFailed.
  ///
  /// In zh, this message translates to:
  /// **'批量编辑失败: {error}'**
  String batchEditFailed(String error);

  /// No description provided for @clearSelection.
  ///
  /// In zh, this message translates to:
  /// **'清除选择'**
  String get clearSelection;

  /// No description provided for @selectTags.
  ///
  /// In zh, this message translates to:
  /// **'选择标签'**
  String get selectTags;

  /// No description provided for @exportPdf.
  ///
  /// In zh, this message translates to:
  /// **'导出 PDF'**
  String get exportPdf;

  /// No description provided for @exportPdfDesc.
  ///
  /// In zh, this message translates to:
  /// **'将记录导出为 PDF 文档'**
  String get exportPdfDesc;

  /// No description provided for @exportPdfSuccess.
  ///
  /// In zh, this message translates to:
  /// **'PDF 导出成功'**
  String get exportPdfSuccess;

  /// No description provided for @exportPdfFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出 PDF 失败: {error}'**
  String exportPdfFailed(String error);

  /// No description provided for @shareRecord.
  ///
  /// In zh, this message translates to:
  /// **'分享记录'**
  String get shareRecord;

  /// No description provided for @playbackSpeed.
  ///
  /// In zh, this message translates to:
  /// **'播放速度'**
  String get playbackSpeed;

  /// No description provided for @speedSlow.
  ///
  /// In zh, this message translates to:
  /// **'慢速'**
  String get speedSlow;

  /// No description provided for @speedNormal.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get speedNormal;

  /// No description provided for @speedFast.
  ///
  /// In zh, this message translates to:
  /// **'快速'**
  String get speedFast;

  /// No description provided for @videoPlayer.
  ///
  /// In zh, this message translates to:
  /// **'视频播放器'**
  String get videoPlayer;

  /// No description provided for @audioPlayer.
  ///
  /// In zh, this message translates to:
  /// **'音频播放器'**
  String get audioPlayer;

  /// No description provided for @fullscreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏'**
  String get fullscreen;

  /// No description provided for @audioWaveform.
  ///
  /// In zh, this message translates to:
  /// **'音频波形'**
  String get audioWaveform;

  /// No description provided for @voiceToText.
  ///
  /// In zh, this message translates to:
  /// **'语音转文字'**
  String get voiceToText;

  /// No description provided for @voiceToTextDesc.
  ///
  /// In zh, this message translates to:
  /// **'将录音转换为文字'**
  String get voiceToTextDesc;

  /// No description provided for @voiceToTextFailed.
  ///
  /// In zh, this message translates to:
  /// **'语音转文字失败: {error}'**
  String voiceToTextFailed(String error);

  /// No description provided for @speechToTextUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'此设备不支持语音转文字功能'**
  String get speechToTextUnavailable;

  /// No description provided for @recentSearches.
  ///
  /// In zh, this message translates to:
  /// **'最近搜索'**
  String get recentSearches;

  /// No description provided for @clearSearchHistory.
  ///
  /// In zh, this message translates to:
  /// **'清除搜索历史'**
  String get clearSearchHistory;

  /// No description provided for @searchHistoryCleared.
  ///
  /// In zh, this message translates to:
  /// **'搜索历史已清除'**
  String get searchHistoryCleared;

  /// No description provided for @suggestions.
  ///
  /// In zh, this message translates to:
  /// **'建议'**
  String get suggestions;

  /// No description provided for @recordTemplates.
  ///
  /// In zh, this message translates to:
  /// **'记录模板'**
  String get recordTemplates;

  /// No description provided for @createTemplate.
  ///
  /// In zh, this message translates to:
  /// **'创建模板'**
  String get createTemplate;

  /// No description provided for @templateName.
  ///
  /// In zh, this message translates to:
  /// **'模板名称'**
  String get templateName;

  /// No description provided for @applyTemplate.
  ///
  /// In zh, this message translates to:
  /// **'应用模板'**
  String get applyTemplate;

  /// No description provided for @deleteTemplate.
  ///
  /// In zh, this message translates to:
  /// **'删除模板'**
  String get deleteTemplate;

  /// No description provided for @noTemplates.
  ///
  /// In zh, this message translates to:
  /// **'暂无模板'**
  String get noTemplates;

  /// No description provided for @createFirstTemplate.
  ///
  /// In zh, this message translates to:
  /// **'为常用的记录模式创建模板'**
  String get createFirstTemplate;

  /// No description provided for @templateApplied.
  ///
  /// In zh, this message translates to:
  /// **'模板已应用'**
  String get templateApplied;

  /// No description provided for @templateCreated.
  ///
  /// In zh, this message translates to:
  /// **'模板已创建'**
  String get templateCreated;

  /// No description provided for @templateDeleted.
  ///
  /// In zh, this message translates to:
  /// **'模板已删除'**
  String get templateDeleted;

  /// No description provided for @exportStats.
  ///
  /// In zh, this message translates to:
  /// **'导出统计'**
  String get exportStats;

  /// No description provided for @exportStatsDesc.
  ///
  /// In zh, this message translates to:
  /// **'将统计数据导出为图片'**
  String get exportStatsDesc;

  /// No description provided for @statsExportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'统计数据导出成功'**
  String get statsExportSuccess;

  /// No description provided for @weeklyTrend.
  ///
  /// In zh, this message translates to:
  /// **'周趋势'**
  String get weeklyTrend;

  /// No description provided for @monthlyTrend.
  ///
  /// In zh, this message translates to:
  /// **'月趋势'**
  String get monthlyTrend;

  /// No description provided for @tagDistribution.
  ///
  /// In zh, this message translates to:
  /// **'标签分布'**
  String get tagDistribution;

  /// No description provided for @thingNameDistribution.
  ///
  /// In zh, this message translates to:
  /// **'事件名称分布'**
  String get thingNameDistribution;

  /// No description provided for @totalDuration.
  ///
  /// In zh, this message translates to:
  /// **'总时长'**
  String get totalDuration;

  /// No description provided for @averageDuration.
  ///
  /// In zh, this message translates to:
  /// **'平均时长'**
  String get averageDuration;

  /// No description provided for @mostUsedThingName.
  ///
  /// In zh, this message translates to:
  /// **'最常用的事件名称'**
  String get mostUsedThingName;

  /// No description provided for @mostUsedTag.
  ///
  /// In zh, this message translates to:
  /// **'最常用的标签'**
  String get mostUsedTag;

  /// No description provided for @recordStreaks.
  ///
  /// In zh, this message translates to:
  /// **'记录连续天数'**
  String get recordStreaks;

  /// No description provided for @currentStreak.
  ///
  /// In zh, this message translates to:
  /// **'当前连续'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In zh, this message translates to:
  /// **'最长连续'**
  String get longestStreak;

  /// No description provided for @days.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天'**
  String days(int count);

  /// No description provided for @recordCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条记录'**
  String recordCount(int count);

  /// No description provided for @hours.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小时'**
  String hours(int count);

  /// No description provided for @minutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String minutes(int count);

  /// No description provided for @recentRecords.
  ///
  /// In zh, this message translates to:
  /// **'最近记录'**
  String get recentRecords;

  /// No description provided for @quickAccess.
  ///
  /// In zh, this message translates to:
  /// **'快捷访问'**
  String get quickAccess;

  /// No description provided for @frequentlyUsed.
  ///
  /// In zh, this message translates to:
  /// **'常用'**
  String get frequentlyUsed;

  /// No description provided for @daily.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In zh, this message translates to:
  /// **'每月'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In zh, this message translates to:
  /// **'每年'**
  String get yearly;

  /// No description provided for @biweekly.
  ///
  /// In zh, this message translates to:
  /// **'每两周'**
  String get biweekly;

  /// No description provided for @quarterly.
  ///
  /// In zh, this message translates to:
  /// **'每季度'**
  String get quarterly;

  /// No description provided for @reminderManagement.
  ///
  /// In zh, this message translates to:
  /// **'提醒管理'**
  String get reminderManagement;

  /// No description provided for @batchSetReminder.
  ///
  /// In zh, this message translates to:
  /// **'批量设置提醒'**
  String get batchSetReminder;

  /// No description provided for @batchSetReminderHint.
  ///
  /// In zh, this message translates to:
  /// **'为选中的记录设置提醒'**
  String get batchSetReminderHint;

  /// No description provided for @batchRemoveReminder.
  ///
  /// In zh, this message translates to:
  /// **'批量移除提醒'**
  String get batchRemoveReminder;

  /// No description provided for @batchRemoveReminderHint.
  ///
  /// In zh, this message translates to:
  /// **'移除选中的记录的提醒'**
  String get batchRemoveReminderHint;

  /// No description provided for @setReminder.
  ///
  /// In zh, this message translates to:
  /// **'设置提醒'**
  String get setReminder;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索记录...'**
  String get searchHint;

  /// No description provided for @voiceSearch.
  ///
  /// In zh, this message translates to:
  /// **'语音搜索'**
  String get voiceSearch;

  /// No description provided for @reminders.
  ///
  /// In zh, this message translates to:
  /// **'提醒'**
  String get reminders;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @exportStatistics.
  ///
  /// In zh, this message translates to:
  /// **'导出统计'**
  String get exportStatistics;

  /// No description provided for @exportStatisticsDesc.
  ///
  /// In zh, this message translates to:
  /// **'将统计数据导出为图片'**
  String get exportStatisticsDesc;

  /// No description provided for @weeklyDistribution.
  ///
  /// In zh, this message translates to:
  /// **'周分布'**
  String get weeklyDistribution;

  /// No description provided for @syncSettings.
  ///
  /// In zh, this message translates to:
  /// **'同步设置'**
  String get syncSettings;

  /// No description provided for @syncStatus.
  ///
  /// In zh, this message translates to:
  /// **'同步状态'**
  String get syncStatus;

  /// No description provided for @syncNow.
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get syncNow;

  /// No description provided for @syncIdle.
  ///
  /// In zh, this message translates to:
  /// **'空闲'**
  String get syncIdle;

  /// No description provided for @syncInProgress.
  ///
  /// In zh, this message translates to:
  /// **'同步中...'**
  String get syncInProgress;

  /// No description provided for @syncSuccess.
  ///
  /// In zh, this message translates to:
  /// **'同步成功'**
  String get syncSuccess;

  /// No description provided for @syncFailed.
  ///
  /// In zh, this message translates to:
  /// **'同步失败'**
  String get syncFailed;

  /// No description provided for @autoSync.
  ///
  /// In zh, this message translates to:
  /// **'自动同步'**
  String get autoSync;

  /// No description provided for @autoSyncDesc.
  ///
  /// In zh, this message translates to:
  /// **'启用后自动同步数据'**
  String get autoSyncDesc;

  /// No description provided for @syncInterval.
  ///
  /// In zh, this message translates to:
  /// **'同步间隔'**
  String get syncInterval;

  /// No description provided for @syncDirection.
  ///
  /// In zh, this message translates to:
  /// **'同步方向'**
  String get syncDirection;

  /// No description provided for @uploadOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅上传'**
  String get uploadOnly;

  /// No description provided for @uploadOnlyDesc.
  ///
  /// In zh, this message translates to:
  /// **'仅上传本地数据到云端'**
  String get uploadOnlyDesc;

  /// No description provided for @downloadOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅下载'**
  String get downloadOnly;

  /// No description provided for @downloadOnlyDesc.
  ///
  /// In zh, this message translates to:
  /// **'仅从云端下载数据'**
  String get downloadOnlyDesc;

  /// No description provided for @lastSyncTime.
  ///
  /// In zh, this message translates to:
  /// **'上次同步时间'**
  String get lastSyncTime;

  /// No description provided for @larkConnection.
  ///
  /// In zh, this message translates to:
  /// **'飞书连接'**
  String get larkConnection;

  /// No description provided for @larkConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get larkConnected;

  /// No description provided for @smartReminders.
  ///
  /// In zh, this message translates to:
  /// **'智能提醒'**
  String get smartReminders;

  /// No description provided for @noPatternsFound.
  ///
  /// In zh, this message translates to:
  /// **'暂无模式'**
  String get noPatternsFound;

  /// No description provided for @noPatternsDesc.
  ///
  /// In zh, this message translates to:
  /// **'记录更多事件以发现你的提醒模式'**
  String get noPatternsDesc;

  /// No description provided for @patternsFound.
  ///
  /// In zh, this message translates to:
  /// **'发现模式'**
  String get patternsFound;

  /// No description provided for @highConfidence.
  ///
  /// In zh, this message translates to:
  /// **'高置信度'**
  String get highConfidence;

  /// No description provided for @suggestedTime.
  ///
  /// In zh, this message translates to:
  /// **'建议时间: {time}'**
  String suggestedTime(String time);

  /// No description provided for @confidence.
  ///
  /// In zh, this message translates to:
  /// **'置信度: {percent}%'**
  String confidence(int percent);

  /// No description provided for @confidenceLabel.
  ///
  /// In zh, this message translates to:
  /// **'置信度'**
  String get confidenceLabel;

  /// No description provided for @analyzeNow.
  ///
  /// In zh, this message translates to:
  /// **'立即分析'**
  String get analyzeNow;

  /// No description provided for @tapToApply.
  ///
  /// In zh, this message translates to:
  /// **'点击应用'**
  String get tapToApply;

  /// No description provided for @reminderApplied.
  ///
  /// In zh, this message translates to:
  /// **'已应用提醒时间 {time}'**
  String reminderApplied(String time);

  /// No description provided for @charts.
  ///
  /// In zh, this message translates to:
  /// **'数据图表'**
  String get charts;

  /// No description provided for @durationTrend.
  ///
  /// In zh, this message translates to:
  /// **'时长趋势'**
  String get durationTrend;

  /// No description provided for @recordCountTrend.
  ///
  /// In zh, this message translates to:
  /// **'记录数趋势'**
  String get recordCountTrend;

  /// No description provided for @hourlyDist.
  ///
  /// In zh, this message translates to:
  /// **'小时分布'**
  String get hourlyDist;

  /// No description provided for @hourlyDistribution.
  ///
  /// In zh, this message translates to:
  /// **'每小时分布'**
  String get hourlyDistribution;

  /// No description provided for @activeDays.
  ///
  /// In zh, this message translates to:
  /// **'活跃天数'**
  String get activeDays;

  /// No description provided for @mostActiveTime.
  ///
  /// In zh, this message translates to:
  /// **'最活跃时间: {hour}:00'**
  String mostActiveTime(String hour);

  /// No description provided for @batchOperations.
  ///
  /// In zh, this message translates to:
  /// **'批量操作'**
  String get batchOperations;

  /// No description provided for @adjustTime.
  ///
  /// In zh, this message translates to:
  /// **'调整时间'**
  String get adjustTime;

  /// No description provided for @adjustTimeDesc.
  ///
  /// In zh, this message translates to:
  /// **'批量调整记录的时间'**
  String get adjustTimeDesc;

  /// No description provided for @adjustTimeTip.
  ///
  /// In zh, this message translates to:
  /// **'选择时间偏移量（分钟）'**
  String get adjustTimeTip;

  /// No description provided for @minus15.
  ///
  /// In zh, this message translates to:
  /// **'-15分钟'**
  String get minus15;

  /// No description provided for @plus15.
  ///
  /// In zh, this message translates to:
  /// **'+15分钟'**
  String get plus15;

  /// No description provided for @minus60.
  ///
  /// In zh, this message translates to:
  /// **'-60分钟'**
  String get minus60;

  /// No description provided for @plus60.
  ///
  /// In zh, this message translates to:
  /// **'+60分钟'**
  String get plus60;

  /// No description provided for @changeThingNameDesc.
  ///
  /// In zh, this message translates to:
  /// **'批量更改记录的事件名称'**
  String get changeThingNameDesc;

  /// No description provided for @toggleFavorite.
  ///
  /// In zh, this message translates to:
  /// **'标记收藏'**
  String get toggleFavorite;

  /// No description provided for @toggleFavoriteDesc.
  ///
  /// In zh, this message translates to:
  /// **'将选中的记录标记为收藏'**
  String get toggleFavoriteDesc;

  /// No description provided for @removeFavoriteDesc.
  ///
  /// In zh, this message translates to:
  /// **'取消选中的记录收藏状态'**
  String get removeFavoriteDesc;

  /// No description provided for @addTagsDesc.
  ///
  /// In zh, this message translates to:
  /// **'为选中的记录添加标签'**
  String get addTagsDesc;

  /// No description provided for @availableOperations.
  ///
  /// In zh, this message translates to:
  /// **'可用操作'**
  String get availableOperations;

  /// No description provided for @batchOperationDesc.
  ///
  /// In zh, this message translates to:
  /// **'批量操作将应用到所有选中的记录'**
  String get batchOperationDesc;

  /// No description provided for @selectedRecords.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 条记录'**
  String selectedRecords(int count);

  /// No description provided for @processing.
  ///
  /// In zh, this message translates to:
  /// **'处理中...'**
  String get processing;

  /// No description provided for @batchOperationSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功更新 {count} 条记录'**
  String batchOperationSuccess(int count);

  /// No description provided for @batchOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'批量操作失败: {error}'**
  String batchOperationFailed(String error);

  /// No description provided for @usageInsights.
  ///
  /// In zh, this message translates to:
  /// **'使用洞察'**
  String get usageInsights;

  /// No description provided for @noInsightsYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无洞察'**
  String get noInsightsYet;

  /// No description provided for @insights.
  ///
  /// In zh, this message translates to:
  /// **'洞察'**
  String get insights;

  /// No description provided for @achievements.
  ///
  /// In zh, this message translates to:
  /// **'成就'**
  String get achievements;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @enhancedBackup.
  ///
  /// In zh, this message translates to:
  /// **'增强备份'**
  String get enhancedBackup;

  /// No description provided for @createBackup.
  ///
  /// In zh, this message translates to:
  /// **'创建备份'**
  String get createBackup;

  /// No description provided for @backupSettings.
  ///
  /// In zh, this message translates to:
  /// **'备份设置'**
  String get backupSettings;

  /// No description provided for @restoreBackup.
  ///
  /// In zh, this message translates to:
  /// **'恢复备份'**
  String get restoreBackup;

  /// No description provided for @deleteBackup.
  ///
  /// In zh, this message translates to:
  /// **'删除备份'**
  String get deleteBackup;

  /// No description provided for @restore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get restore;

  /// No description provided for @restoreReplace.
  ///
  /// In zh, this message translates to:
  /// **'覆盖恢复'**
  String get restoreReplace;

  /// No description provided for @restoreMerge.
  ///
  /// In zh, this message translates to:
  /// **'合并恢复'**
  String get restoreMerge;

  /// No description provided for @restoreWarning.
  ///
  /// In zh, this message translates to:
  /// **'恢复备份将替换或合并现有数据'**
  String get restoreWarning;

  /// No description provided for @restoreConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'确定要恢复备份「{name}」吗？'**
  String restoreConfirmation(String name);

  /// No description provided for @deleteConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除「{name}」吗？'**
  String deleteConfirmation(String name);

  /// No description provided for @noBackupsFound.
  ///
  /// In zh, this message translates to:
  /// **'暂无备份'**
  String get noBackupsFound;

  /// No description provided for @createFirstBackup.
  ///
  /// In zh, this message translates to:
  /// **'创建第一个备份'**
  String get createFirstBackup;

  /// No description provided for @createFirstBackupDesc.
  ///
  /// In zh, this message translates to:
  /// **'创建备份以保护你的数据'**
  String get createFirstBackupDesc;

  /// No description provided for @fullBackup.
  ///
  /// In zh, this message translates to:
  /// **'完整备份'**
  String get fullBackup;

  /// No description provided for @fullBackupDesc.
  ///
  /// In zh, this message translates to:
  /// **'备份所有数据'**
  String get fullBackupDesc;

  /// No description provided for @incrementalBackup.
  ///
  /// In zh, this message translates to:
  /// **'增量备份'**
  String get incrementalBackup;

  /// No description provided for @incrementalBackupDesc.
  ///
  /// In zh, this message translates to:
  /// **'仅备份新增数据'**
  String get incrementalBackupDesc;

  /// No description provided for @auto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get auto;

  /// No description provided for @autoBackup.
  ///
  /// In zh, this message translates to:
  /// **'自动备份'**
  String get autoBackup;

  /// No description provided for @autoBackupDesc.
  ///
  /// In zh, this message translates to:
  /// **'定期自动创建备份'**
  String get autoBackupDesc;

  /// No description provided for @maxBackups.
  ///
  /// In zh, this message translates to:
  /// **'最大保留数量'**
  String get maxBackups;

  /// No description provided for @selectInterval.
  ///
  /// In zh, this message translates to:
  /// **'选择间隔'**
  String get selectInterval;

  /// No description provided for @summary.
  ///
  /// In zh, this message translates to:
  /// **'摘要'**
  String get summary;

  /// No description provided for @view.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get view;

  /// No description provided for @auto_sync.
  ///
  /// In zh, this message translates to:
  /// **'自动同步'**
  String get auto_sync;

  /// No description provided for @auto_syncDesc.
  ///
  /// In zh, this message translates to:
  /// **'自动同步记录数据'**
  String get auto_syncDesc;

  /// No description provided for @goals.
  ///
  /// In zh, this message translates to:
  /// **'目标追踪'**
  String get goals;

  /// No description provided for @goalsDesc.
  ///
  /// In zh, this message translates to:
  /// **'设定并追踪你的目标'**
  String get goalsDesc;

  /// No description provided for @mood.
  ///
  /// In zh, this message translates to:
  /// **'情绪记录'**
  String get mood;

  /// No description provided for @moodDesc.
  ///
  /// In zh, this message translates to:
  /// **'记录每日心情变化'**
  String get moodDesc;

  /// No description provided for @habits.
  ///
  /// In zh, this message translates to:
  /// **'习惯追踪'**
  String get habits;

  /// No description provided for @habitsDesc.
  ///
  /// In zh, this message translates to:
  /// **'培养好习惯'**
  String get habitsDesc;

  /// No description provided for @projects.
  ///
  /// In zh, this message translates to:
  /// **'项目管理'**
  String get projects;

  /// No description provided for @projectsDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理你的项目'**
  String get projectsDesc;

  /// No description provided for @notificationCenter.
  ///
  /// In zh, this message translates to:
  /// **'通知中心'**
  String get notificationCenter;

  /// No description provided for @notificationCenterDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看系统通知'**
  String get notificationCenterDesc;

  /// No description provided for @dataReport.
  ///
  /// In zh, this message translates to:
  /// **'数据分析报告'**
  String get dataReport;

  /// No description provided for @dataReportDesc.
  ///
  /// In zh, this message translates to:
  /// **'生成统计报告'**
  String get dataReportDesc;

  /// No description provided for @customTheme.
  ///
  /// In zh, this message translates to:
  /// **'自定义主题'**
  String get customTheme;

  /// No description provided for @customThemeDesc.
  ///
  /// In zh, this message translates to:
  /// **'选择你喜欢的主题'**
  String get customThemeDesc;

  /// No description provided for @dataImport.
  ///
  /// In zh, this message translates to:
  /// **'数据导入'**
  String get dataImport;

  /// No description provided for @dataImportDesc.
  ///
  /// In zh, this message translates to:
  /// **'从其他应用导入数据'**
  String get dataImportDesc;

  /// No description provided for @addGoal.
  ///
  /// In zh, this message translates to:
  /// **'添加目标'**
  String get addGoal;

  /// No description provided for @goalTracking.
  ///
  /// In zh, this message translates to:
  /// **'目标追踪'**
  String get goalTracking;

  /// No description provided for @goalTitle.
  ///
  /// In zh, this message translates to:
  /// **'目标标题'**
  String get goalTitle;

  /// No description provided for @goalDescription.
  ///
  /// In zh, this message translates to:
  /// **'目标描述'**
  String get goalDescription;

  /// No description provided for @goalPriority.
  ///
  /// In zh, this message translates to:
  /// **'优先级'**
  String get goalPriority;

  /// No description provided for @goalDeadline.
  ///
  /// In zh, this message translates to:
  /// **'截止日期'**
  String get goalDeadline;

  /// No description provided for @goalProgress.
  ///
  /// In zh, this message translates to:
  /// **'进度'**
  String get goalProgress;

  /// No description provided for @markCompleted.
  ///
  /// In zh, this message translates to:
  /// **'标记完成'**
  String get markCompleted;

  /// No description provided for @addMood.
  ///
  /// In zh, this message translates to:
  /// **'记录心情'**
  String get addMood;

  /// No description provided for @moodLevel.
  ///
  /// In zh, this message translates to:
  /// **'心情程度'**
  String get moodLevel;

  /// No description provided for @moodTriggers.
  ///
  /// In zh, this message translates to:
  /// **'触发因素'**
  String get moodTriggers;

  /// No description provided for @addHabit.
  ///
  /// In zh, this message translates to:
  /// **'添加习惯'**
  String get addHabit;

  /// No description provided for @habitName.
  ///
  /// In zh, this message translates to:
  /// **'习惯名称'**
  String get habitName;

  /// No description provided for @habitFrequency.
  ///
  /// In zh, this message translates to:
  /// **'频率'**
  String get habitFrequency;

  /// No description provided for @bestStreak.
  ///
  /// In zh, this message translates to:
  /// **'最佳连续'**
  String get bestStreak;

  /// No description provided for @completeHabit.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get completeHabit;

  /// No description provided for @addProject.
  ///
  /// In zh, this message translates to:
  /// **'创建项目'**
  String get addProject;

  /// No description provided for @projectName.
  ///
  /// In zh, this message translates to:
  /// **'项目名称'**
  String get projectName;

  /// No description provided for @projectColor.
  ///
  /// In zh, this message translates to:
  /// **'项目颜色'**
  String get projectColor;

  /// No description provided for @projectProgress.
  ///
  /// In zh, this message translates to:
  /// **'进度'**
  String get projectProgress;

  /// No description provided for @importFile.
  ///
  /// In zh, this message translates to:
  /// **'导入文件'**
  String get importFile;

  /// No description provided for @selectFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get selectFile;

  /// No description provided for @startImport.
  ///
  /// In zh, this message translates to:
  /// **'开始导入'**
  String get startImport;

  /// No description provided for @importResult.
  ///
  /// In zh, this message translates to:
  /// **'导入结果'**
  String get importResult;

  /// No description provided for @importSuccess.
  ///
  /// In zh, this message translates to:
  /// **'导入成功'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败'**
  String get importFailed;

  /// No description provided for @exportReport.
  ///
  /// In zh, this message translates to:
  /// **'导出报告'**
  String get exportReport;

  /// No description provided for @dailyReport.
  ///
  /// In zh, this message translates to:
  /// **'日报'**
  String get dailyReport;

  /// No description provided for @weeklyReport.
  ///
  /// In zh, this message translates to:
  /// **'周报'**
  String get weeklyReport;

  /// No description provided for @monthlyReport.
  ///
  /// In zh, this message translates to:
  /// **'月报'**
  String get monthlyReport;

  /// No description provided for @themeOcean.
  ///
  /// In zh, this message translates to:
  /// **'海洋'**
  String get themeOcean;

  /// No description provided for @themeForest.
  ///
  /// In zh, this message translates to:
  /// **'森林'**
  String get themeForest;

  /// No description provided for @themeSunset.
  ///
  /// In zh, this message translates to:
  /// **'日落'**
  String get themeSunset;

  /// No description provided for @themePurple.
  ///
  /// In zh, this message translates to:
  /// **'紫罗兰'**
  String get themePurple;

  /// No description provided for @themeMidnight.
  ///
  /// In zh, this message translates to:
  /// **'午夜'**
  String get themeMidnight;

  /// No description provided for @themeDarkForest.
  ///
  /// In zh, this message translates to:
  /// **'暗夜森林'**
  String get themeDarkForest;

  /// No description provided for @goalActive.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get goalActive;

  /// No description provided for @goalPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get goalPaused;

  /// No description provided for @goalCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get goalCompleted;

  /// No description provided for @goalCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get goalCancelled;

  /// No description provided for @goalPriorityLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get goalPriorityLow;

  /// No description provided for @goalPriorityMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get goalPriorityMedium;

  /// No description provided for @goalPriorityHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get goalPriorityHigh;

  /// No description provided for @goalPriorityCritical.
  ///
  /// In zh, this message translates to:
  /// **'紧急'**
  String get goalPriorityCritical;

  /// No description provided for @projectActive.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get projectActive;

  /// No description provided for @projectPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get projectPaused;

  /// No description provided for @projectCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get projectCompleted;

  /// No description provided for @projectArchived.
  ///
  /// In zh, this message translates to:
  /// **'已归档'**
  String get projectArchived;

  /// No description provided for @moodVeryBad.
  ///
  /// In zh, this message translates to:
  /// **'非常差'**
  String get moodVeryBad;

  /// No description provided for @moodBad.
  ///
  /// In zh, this message translates to:
  /// **'较差'**
  String get moodBad;

  /// No description provided for @moodNeutral.
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get moodNeutral;

  /// No description provided for @moodGood.
  ///
  /// In zh, this message translates to:
  /// **'良好'**
  String get moodGood;

  /// No description provided for @moodVeryGood.
  ///
  /// In zh, this message translates to:
  /// **'非常好'**
  String get moodVeryGood;

  /// No description provided for @frequencyDaily.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get frequencyWeekly;

  /// No description provided for @frequencyCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get frequencyCustom;

  /// No description provided for @recurrencePatterns.
  ///
  /// In zh, this message translates to:
  /// **'重复模式'**
  String get recurrencePatterns;

  /// No description provided for @analyze.
  ///
  /// In zh, this message translates to:
  /// **'分析'**
  String get analyze;

  /// No description provided for @noRecurrencePatterns.
  ///
  /// In zh, this message translates to:
  /// **'暂无重复模式'**
  String get noRecurrencePatterns;

  /// No description provided for @createRecordsToDetect.
  ///
  /// In zh, this message translates to:
  /// **'创建更多记录以检测重复模式'**
  String get createRecordsToDetect;

  /// No description provided for @confirmDeletePattern.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此重复模式吗？'**
  String get confirmDeletePattern;

  /// No description provided for @monthlyOn.
  ///
  /// In zh, this message translates to:
  /// **'每月 {day} 日'**
  String monthlyOn(int day);

  /// No description provided for @advancedAnalytics.
  ///
  /// In zh, this message translates to:
  /// **'高级分析'**
  String get advancedAnalytics;

  /// No description provided for @aiInsights.
  ///
  /// In zh, this message translates to:
  /// **'AI 洞察'**
  String get aiInsights;

  /// No description provided for @activityTrend.
  ///
  /// In zh, this message translates to:
  /// **'活动趋势'**
  String get activityTrend;

  /// No description provided for @prediction.
  ///
  /// In zh, this message translates to:
  /// **'预测'**
  String get prediction;

  /// No description provided for @automationRules.
  ///
  /// In zh, this message translates to:
  /// **'自动化规则'**
  String get automationRules;

  /// No description provided for @myRules.
  ///
  /// In zh, this message translates to:
  /// **'我的规则'**
  String get myRules;

  /// No description provided for @ruleTemplates.
  ///
  /// In zh, this message translates to:
  /// **'规则模板'**
  String get ruleTemplates;

  /// No description provided for @collaborativeWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'协作空间'**
  String get collaborativeWorkspace;

  /// No description provided for @inviteMember.
  ///
  /// In zh, this message translates to:
  /// **'邀请成员'**
  String get inviteMember;

  /// No description provided for @workspaces.
  ///
  /// In zh, this message translates to:
  /// **'工作空间'**
  String get workspaces;

  /// No description provided for @teamMembers.
  ///
  /// In zh, this message translates to:
  /// **'团队成员'**
  String get teamMembers;

  /// No description provided for @viewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get viewAll;

  /// No description provided for @recentShared.
  ///
  /// In zh, this message translates to:
  /// **'最近共享'**
  String get recentShared;

  /// No description provided for @members.
  ///
  /// In zh, this message translates to:
  /// **'成员'**
  String get members;

  /// No description provided for @createWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'创建工作空间'**
  String get createWorkspace;

  /// No description provided for @workspaceName.
  ///
  /// In zh, this message translates to:
  /// **'工作空间名称'**
  String get workspaceName;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @email.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get email;

  /// No description provided for @role.
  ///
  /// In zh, this message translates to:
  /// **'角色'**
  String get role;

  /// No description provided for @customReports.
  ///
  /// In zh, this message translates to:
  /// **'自定义报告'**
  String get customReports;

  /// No description provided for @selectReportType.
  ///
  /// In zh, this message translates to:
  /// **'选择报告类型'**
  String get selectReportType;

  /// No description provided for @generateReport.
  ///
  /// In zh, this message translates to:
  /// **'生成报告'**
  String get generateReport;

  /// No description provided for @reportPreview.
  ///
  /// In zh, this message translates to:
  /// **'报告预览'**
  String get reportPreview;

  /// No description provided for @exportOptions.
  ///
  /// In zh, this message translates to:
  /// **'导出选项'**
  String get exportOptions;

  /// No description provided for @reportHistory.
  ///
  /// In zh, this message translates to:
  /// **'报告历史'**
  String get reportHistory;

  /// No description provided for @generatingReport.
  ///
  /// In zh, this message translates to:
  /// **'正在生成报告...'**
  String get generatingReport;

  /// No description provided for @dataExportHub.
  ///
  /// In zh, this message translates to:
  /// **'数据导出中心'**
  String get dataExportHub;

  /// No description provided for @exportTemplates.
  ///
  /// In zh, this message translates to:
  /// **'导出模板'**
  String get exportTemplates;

  /// No description provided for @customExport.
  ///
  /// In zh, this message translates to:
  /// **'自定义导出'**
  String get customExport;

  /// No description provided for @exportFormat.
  ///
  /// In zh, this message translates to:
  /// **'导出格式'**
  String get exportFormat;

  /// No description provided for @includeContent.
  ///
  /// In zh, this message translates to:
  /// **'包含内容'**
  String get includeContent;

  /// No description provided for @exportPreview.
  ///
  /// In zh, this message translates to:
  /// **'导出预览'**
  String get exportPreview;

  /// No description provided for @startExport.
  ///
  /// In zh, this message translates to:
  /// **'开始导出'**
  String get startExport;

  /// No description provided for @documentScanner.
  ///
  /// In zh, this message translates to:
  /// **'文档扫描'**
  String get documentScanner;

  /// No description provided for @extractedText.
  ///
  /// In zh, this message translates to:
  /// **'提取的文本'**
  String get extractedText;

  /// No description provided for @scannedDocuments.
  ///
  /// In zh, this message translates to:
  /// **'已扫描文档'**
  String get scannedDocuments;

  /// No description provided for @healthConnect.
  ///
  /// In zh, this message translates to:
  /// **'健康连接'**
  String get healthConnect;

  /// No description provided for @connected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get notConnected;

  /// No description provided for @lastSync.
  ///
  /// In zh, this message translates to:
  /// **'上次同步'**
  String get lastSync;

  /// No description provided for @disconnect.
  ///
  /// In zh, this message translates to:
  /// **'断开连接'**
  String get disconnect;

  /// No description provided for @connect.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get connect;

  /// No description provided for @syncOptions.
  ///
  /// In zh, this message translates to:
  /// **'同步选项'**
  String get syncOptions;

  /// No description provided for @steps.
  ///
  /// In zh, this message translates to:
  /// **'步数'**
  String get steps;

  /// No description provided for @stepsDesc.
  ///
  /// In zh, this message translates to:
  /// **'健康数据中的步数统计'**
  String get stepsDesc;

  /// No description provided for @sessionCompleted.
  ///
  /// In zh, this message translates to:
  /// **'冥想完成'**
  String get sessionCompleted;

  /// No description provided for @greatJob.
  ///
  /// In zh, this message translates to:
  /// **'太棒了！'**
  String get greatJob;

  /// No description provided for @mindfulMoments.
  ///
  /// In zh, this message translates to:
  /// **'正念时刻'**
  String get mindfulMoments;

  /// No description provided for @sessions.
  ///
  /// In zh, this message translates to:
  /// **'会话数'**
  String get sessions;

  /// No description provided for @totalMinutes.
  ///
  /// In zh, this message translates to:
  /// **'总时长'**
  String get totalMinutes;

  /// No description provided for @resumed.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get resumed;

  /// No description provided for @stop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stop;

  /// No description provided for @selectDuration.
  ///
  /// In zh, this message translates to:
  /// **'选择时长'**
  String get selectDuration;

  /// No description provided for @minutesShort.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get minutesShort;

  /// No description provided for @breathingGuide.
  ///
  /// In zh, this message translates to:
  /// **'呼吸指导'**
  String get breathingGuide;

  /// No description provided for @inhaleExhale.
  ///
  /// In zh, this message translates to:
  /// **'吸气 / 呼气'**
  String get inhaleExhale;

  /// No description provided for @startSession.
  ///
  /// In zh, this message translates to:
  /// **'开始冥想'**
  String get startSession;

  /// No description provided for @meditationHistory.
  ///
  /// In zh, this message translates to:
  /// **'冥想历史'**
  String get meditationHistory;

  /// No description provided for @notificationHub.
  ///
  /// In zh, this message translates to:
  /// **'通知中心'**
  String get notificationHub;

  /// No description provided for @notificationSettings.
  ///
  /// In zh, this message translates to:
  /// **'通知设置'**
  String get notificationSettings;

  /// No description provided for @pushNotifications.
  ///
  /// In zh, this message translates to:
  /// **'推送通知'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In zh, this message translates to:
  /// **'邮件通知'**
  String get emailNotifications;

  /// No description provided for @reminderNotifications.
  ///
  /// In zh, this message translates to:
  /// **'提醒通知'**
  String get reminderNotifications;

  /// No description provided for @weeklyDigest.
  ///
  /// In zh, this message translates to:
  /// **'每周摘要'**
  String get weeklyDigest;

  /// No description provided for @marketingEmails.
  ///
  /// In zh, this message translates to:
  /// **'营销邮件'**
  String get marketingEmails;

  /// No description provided for @recentNotifications.
  ///
  /// In zh, this message translates to:
  /// **'最近通知'**
  String get recentNotifications;

  /// No description provided for @clearAll.
  ///
  /// In zh, this message translates to:
  /// **'全部清除'**
  String get clearAll;

  /// No description provided for @projectManagement.
  ///
  /// In zh, this message translates to:
  /// **'项目管理'**
  String get projectManagement;

  /// No description provided for @smartGeofence.
  ///
  /// In zh, this message translates to:
  /// **'智能地理围栏'**
  String get smartGeofence;

  /// No description provided for @locationEnabled.
  ///
  /// In zh, this message translates to:
  /// **'位置已启用'**
  String get locationEnabled;

  /// No description provided for @locationDisabled.
  ///
  /// In zh, this message translates to:
  /// **'位置已禁用'**
  String get locationDisabled;

  /// No description provided for @myGeofences.
  ///
  /// In zh, this message translates to:
  /// **'我的地理围栏'**
  String get myGeofences;

  /// No description provided for @smartScheduling.
  ///
  /// In zh, this message translates to:
  /// **'智能日程'**
  String get smartScheduling;

  /// No description provided for @suggestedTimeSlots.
  ///
  /// In zh, this message translates to:
  /// **'建议时段'**
  String get suggestedTimeSlots;

  /// No description provided for @quickSchedule.
  ///
  /// In zh, this message translates to:
  /// **'快速日程'**
  String get quickSchedule;

  /// No description provided for @todaySchedule.
  ///
  /// In zh, this message translates to:
  /// **'今日日程'**
  String get todaySchedule;

  /// No description provided for @conflictDetection.
  ///
  /// In zh, this message translates to:
  /// **'冲突检测'**
  String get conflictDetection;

  /// No description provided for @findOptimalTime.
  ///
  /// In zh, this message translates to:
  /// **'查找最佳时间'**
  String get findOptimalTime;

  /// No description provided for @sleepData.
  ///
  /// In zh, this message translates to:
  /// **'睡眠数据'**
  String get sleepData;

  /// No description provided for @sleepDataDesc.
  ///
  /// In zh, this message translates to:
  /// **'来自健康源的睡眠数据'**
  String get sleepDataDesc;

  /// No description provided for @heartRate.
  ///
  /// In zh, this message translates to:
  /// **'心率'**
  String get heartRate;

  /// No description provided for @heartRateDesc.
  ///
  /// In zh, this message translates to:
  /// **'来自健康源的心率数据'**
  String get heartRateDesc;

  /// No description provided for @weight.
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get weight;

  /// No description provided for @weightDesc.
  ///
  /// In zh, this message translates to:
  /// **'体重追踪'**
  String get weightDesc;

  /// No description provided for @syncNowDesc.
  ///
  /// In zh, this message translates to:
  /// **'立即同步健康数据'**
  String get syncNowDesc;

  /// No description provided for @autoSyncSchedule.
  ///
  /// In zh, this message translates to:
  /// **'自动同步日程'**
  String get autoSyncSchedule;

  /// No description provided for @syncFrequency.
  ///
  /// In zh, this message translates to:
  /// **'同步频率'**
  String get syncFrequency;

  /// No description provided for @syncDaily.
  ///
  /// In zh, this message translates to:
  /// **'每日一次'**
  String get syncDaily;

  /// No description provided for @syncing.
  ///
  /// In zh, this message translates to:
  /// **'同步中...'**
  String get syncing;

  /// No description provided for @every15Minutes.
  ///
  /// In zh, this message translates to:
  /// **'每15分钟'**
  String get every15Minutes;

  /// No description provided for @everyHour.
  ///
  /// In zh, this message translates to:
  /// **'每小时'**
  String get everyHour;

  /// No description provided for @description.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get description;

  /// No description provided for @invite.
  ///
  /// In zh, this message translates to:
  /// **'邀请'**
  String get invite;

  /// No description provided for @paused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get paused;

  /// No description provided for @resume.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get resume;

  /// No description provided for @sessionsCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成会话'**
  String get sessionsCompleted;

  /// No description provided for @totalTime.
  ///
  /// In zh, this message translates to:
  /// **'总时间'**
  String get totalTime;

  /// No description provided for @smartSuggestions.
  ///
  /// In zh, this message translates to:
  /// **'智能建议'**
  String get smartSuggestions;

  /// No description provided for @dismissAll.
  ///
  /// In zh, this message translates to:
  /// **'全部忽略'**
  String get dismissAll;

  /// No description provided for @ignore.
  ///
  /// In zh, this message translates to:
  /// **'忽略'**
  String get ignore;

  /// No description provided for @voiceCommands.
  ///
  /// In zh, this message translates to:
  /// **'语音命令'**
  String get voiceCommands;

  /// No description provided for @listening.
  ///
  /// In zh, this message translates to:
  /// **'正在聆听...'**
  String get listening;

  /// No description provided for @tapToSpeak.
  ///
  /// In zh, this message translates to:
  /// **'点击说话'**
  String get tapToSpeak;

  /// No description provided for @availableCommands.
  ///
  /// In zh, this message translates to:
  /// **'可用命令'**
  String get availableCommands;

  /// No description provided for @commandHistory.
  ///
  /// In zh, this message translates to:
  /// **'命令历史'**
  String get commandHistory;

  /// No description provided for @habitStreak.
  ///
  /// In zh, this message translates to:
  /// **'习惯连续'**
  String get habitStreak;

  /// No description provided for @moodCalendar.
  ///
  /// In zh, this message translates to:
  /// **'心情日历'**
  String get moodCalendar;

  /// No description provided for @quickStats.
  ///
  /// In zh, this message translates to:
  /// **'快速统计'**
  String get quickStats;

  /// No description provided for @smartCalendar.
  ///
  /// In zh, this message translates to:
  /// **'智能日历'**
  String get smartCalendar;

  /// No description provided for @timeAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'时间分析'**
  String get timeAnalysis;

  /// No description provided for @dailyRoutine.
  ///
  /// In zh, this message translates to:
  /// **'日常习惯'**
  String get dailyRoutine;

  /// No description provided for @focusTimer.
  ///
  /// In zh, this message translates to:
  /// **'专注计时'**
  String get focusTimer;

  /// No description provided for @locationHistory.
  ///
  /// In zh, this message translates to:
  /// **'位置历史'**
  String get locationHistory;

  /// No description provided for @moodHeatmap.
  ///
  /// In zh, this message translates to:
  /// **'心情热力图'**
  String get moodHeatmap;

  /// No description provided for @tagCloud.
  ///
  /// In zh, this message translates to:
  /// **'标签云'**
  String get tagCloud;

  /// No description provided for @reminderAnalytics.
  ///
  /// In zh, this message translates to:
  /// **'提醒分析'**
  String get reminderAnalytics;

  /// No description provided for @dailyScore.
  ///
  /// In zh, this message translates to:
  /// **'每日评分'**
  String get dailyScore;

  /// No description provided for @consecutiveDays.
  ///
  /// In zh, this message translates to:
  /// **'连续天数'**
  String get consecutiveDays;

  /// No description provided for @dataDashboard.
  ///
  /// In zh, this message translates to:
  /// **'数据仪表盘'**
  String get dataDashboard;

  /// No description provided for @dailyRecordTrend.
  ///
  /// In zh, this message translates to:
  /// **'每日记录趋势'**
  String get dailyRecordTrend;

  /// No description provided for @goalTrackingDesc.
  ///
  /// In zh, this message translates to:
  /// **'设定并追踪你的目标'**
  String get goalTrackingDesc;

  /// No description provided for @habitTracking.
  ///
  /// In zh, this message translates to:
  /// **'习惯追踪'**
  String get habitTracking;

  /// No description provided for @habitTrackingDesc.
  ///
  /// In zh, this message translates to:
  /// **'培养好习惯'**
  String get habitTrackingDesc;

  /// No description provided for @projectManagementDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理你的项目'**
  String get projectManagementDesc;

  /// No description provided for @dataDashboardDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看数据概览和趋势'**
  String get dataDashboardDesc;

  /// No description provided for @monthlyStats.
  ///
  /// In zh, this message translates to:
  /// **'月度统计'**
  String get monthlyStats;

  /// No description provided for @noTrendData.
  ///
  /// In zh, this message translates to:
  /// **'暂无趋势数据'**
  String get noTrendData;

  /// No description provided for @overview.
  ///
  /// In zh, this message translates to:
  /// **'概览'**
  String get overview;

  /// No description provided for @photosCount.
  ///
  /// In zh, this message translates to:
  /// **'照片数量'**
  String get photosCount;

  /// No description provided for @ranking.
  ///
  /// In zh, this message translates to:
  /// **'排名'**
  String get ranking;

  /// No description provided for @tagRanking.
  ///
  /// In zh, this message translates to:
  /// **'标签排名'**
  String get tagRanking;

  /// No description provided for @thingNameRanking.
  ///
  /// In zh, this message translates to:
  /// **'事件名称排名'**
  String get thingNameRanking;

  /// No description provided for @times.
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get times;

  /// No description provided for @trend.
  ///
  /// In zh, this message translates to:
  /// **'趋势'**
  String get trend;

  /// No description provided for @videosCount.
  ///
  /// In zh, this message translates to:
  /// **'视频数量'**
  String get videosCount;

  /// No description provided for @recordCountLabel.
  ///
  /// In zh, this message translates to:
  /// **'记录数'**
  String get recordCountLabel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
