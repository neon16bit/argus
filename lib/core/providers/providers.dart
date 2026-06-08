import 'package:argus/data/remote/metadata/metadata_provider.dart';
import 'package:argus/data/remote/metadata/simkl_provider.dart';
import 'package:argus/data/scrapers/scrape_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final packageInfoProvider = Provider<PackageInfo>((ref) {
  throw UnimplementedError('Initialized in main()');
});

final simklProvider = Provider<SimklProvider>((ref) {
  final packageInfo = ref.watch(packageInfoProvider);
  return SimklProvider(
    appName: packageInfo.appName,
    appVersion: packageInfo.version,
  );
});

final metadataProvider = FutureProvider.family<ShowMetadata?, String>((
  ref,
  title,
) async {
  final simkl = ref.watch(simklProvider);

  var result = await simkl.fetchMetadata(title);
  return result;
});

class Source {
  final String name;
  final String baseUrl;
  bool isOnline = true;
  DateTime? lastScraped;
  List<ScrapeResult> items = [];

  Source({required this.name, required this.baseUrl});
}

class SearchResult {
  final String cleanTitle;
  final List<ScrapeResult> items;

  SearchResult({required this.cleanTitle, required this.items});
}

class GlobalSourcesNotifier extends Notifier<List<Source>> {
  @override
  List<Source> build() {
    return [];
  }

  void addSource(Source source) {
    state = [...state, source];
  }

  void removeSourceAt(int index) {
    final newState = [...state];
    newState.removeAt(index);
    state = newState;
  }
}

final sourcesProvider = NotifierProvider<GlobalSourcesNotifier, List<Source>>(
  () {
    return GlobalSourcesNotifier();
  },
);
