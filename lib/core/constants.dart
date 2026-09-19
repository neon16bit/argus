import 'package:flutter/widgets.dart';

const Set<String> kMediaExtensions = {
  // video
  'mkv', 'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', 'ts', 'mpg',
  'mpeg', '3gp', 'ogv', 'rmvb',
  // audio
  // 'mp3', 'flac', 'aac', 'ogg', 'wma', 'wav', 'm4a', 'opus',
  // subtitle
  // 'srt', 'ass', 'ssa', 'sub', 'vtt',
};

const Set<String> kVideoExtensions = {
  'mkv',
  'mp4',
  'avi',
  'mov',
  'wmv',
  'flv',
  'webm',
  'm4v',
  'ts',
  'mpg',
  'mpeg',
  '3gp',
  'ogv',
  'rmvb',
};

const Set<String> kAudioExtensions = {
  'mp3',
  'flac',
  'aac',
  'ogg',
  'wma',
  'wav',
  'm4a',
  'opus',
};

const Set<String> kSubtitleExtensions = {'srt', 'ass', 'ssa', 'sub', 'vtt'};

const Duration kPingTimeout = Duration(seconds: 3);
const Duration kScrapeTimeout = Duration(seconds: 10);
const int kMaxConcurrentRequests = 2;
const Duration kDefaultScrapeDelay = Duration(milliseconds: 200);
const int kInsertBatchSize = 100;

const int kFullScrapeDepth = 0;
const int kFlatScrapeDepth = 1;
const int kGroupedScrapeDepth = 2;

const String kSimklBaseUrl = 'https://api.simkl.com';
const String kSimklImageBase = 'https://wsrv.nl/?url=https://simkl.in';

const String kTvdbBaseUrl = 'https://api4.thetvdb.com/v4';
const String kTvdbImageBase = 'https://artworks.thetvdb.com';

const double kCompactBreakpoint = 500.0;
const double kMediumBreakpoint = 600.0;
const double kDesktopBreakpoint = 720.0;
const double kSidebarExpandBreakpoint = 1100.0;
const double kGridPosterMaxExtent = 180.0;

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isDesktop => screenWidth >= kDesktopBreakpoint;
  bool get isMedium => screenWidth >= kMediumBreakpoint;
  bool get isCompact => screenWidth < kCompactBreakpoint;
}
