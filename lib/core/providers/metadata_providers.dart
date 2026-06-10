import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/data/remote/metadata/metadata_provider.dart';
import 'package:argus/data/remote/metadata/simkl_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return await simkl.fetchMetadata(title);
});
