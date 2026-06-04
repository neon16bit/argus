const Set<String> kMediaExtensions = {
  // video
  'mkv', 'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', 'ts', 'mpg',
  'mpeg', '3gp', 'ogv', 'rmvb',
  // audio
  'mp3', 'flac', 'aac', 'ogg', 'wma', 'wav', 'm4a', 'opus',
  // subtitle
  'srt', 'ass', 'ssa', 'sub', 'vtt',
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
const int kMaxConcurrentRequests = 5;
