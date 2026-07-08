// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SourcesTable extends Sources with TableInfo<$SourcesTable, Source> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _isOnlineMeta = const VerificationMeta(
    'isOnline',
  );
  @override
  late final GeneratedColumn<bool> isOnline = GeneratedColumn<bool>(
    'is_online',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_online" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastScrapedMeta = const VerificationMeta(
    'lastScraped',
  );
  @override
  late final GeneratedColumn<DateTime> lastScraped = GeneratedColumn<DateTime>(
    'last_scraped',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _maxDepthMeta = const VerificationMeta(
    'maxDepth',
  );
  @override
  late final GeneratedColumn<int> maxDepth = GeneratedColumn<int>(
    'max_depth',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _autoScrapeMeta = const VerificationMeta(
    'autoScrape',
  );
  @override
  late final GeneratedColumn<bool> autoScrape = GeneratedColumn<bool>(
    'auto_scrape',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_scrape" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _requestDelayMsMeta = const VerificationMeta(
    'requestDelayMs',
  );
  @override
  late final GeneratedColumn<int> requestDelayMs = GeneratedColumn<int>(
    'request_delay_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    baseUrl,
    isOnline,
    lastScraped,
    createdAt,
    maxDepth,
    autoScrape,
    requestDelayMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<Source> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('is_online')) {
      context.handle(
        _isOnlineMeta,
        isOnline.isAcceptableOrUnknown(data['is_online']!, _isOnlineMeta),
      );
    }
    if (data.containsKey('last_scraped')) {
      context.handle(
        _lastScrapedMeta,
        lastScraped.isAcceptableOrUnknown(
          data['last_scraped']!,
          _lastScrapedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('max_depth')) {
      context.handle(
        _maxDepthMeta,
        maxDepth.isAcceptableOrUnknown(data['max_depth']!, _maxDepthMeta),
      );
    }
    if (data.containsKey('auto_scrape')) {
      context.handle(
        _autoScrapeMeta,
        autoScrape.isAcceptableOrUnknown(data['auto_scrape']!, _autoScrapeMeta),
      );
    }
    if (data.containsKey('request_delay_ms')) {
      context.handle(
        _requestDelayMsMeta,
        requestDelayMs.isAcceptableOrUnknown(
          data['request_delay_ms']!,
          _requestDelayMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Source map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Source(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      isOnline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_online'],
      )!,
      lastScraped: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_scraped'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      maxDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_depth'],
      )!,
      autoScrape: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_scrape'],
      )!,
      requestDelayMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}request_delay_ms'],
      ),
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class Source extends DataClass implements Insertable<Source> {
  final int id;
  final String name;
  final String baseUrl;
  final bool isOnline;
  final DateTime? lastScraped;
  final DateTime createdAt;
  final int maxDepth;
  final bool autoScrape;
  final int? requestDelayMs;
  const Source({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.isOnline,
    this.lastScraped,
    required this.createdAt,
    required this.maxDepth,
    required this.autoScrape,
    this.requestDelayMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['base_url'] = Variable<String>(baseUrl);
    map['is_online'] = Variable<bool>(isOnline);
    if (!nullToAbsent || lastScraped != null) {
      map['last_scraped'] = Variable<DateTime>(lastScraped);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['max_depth'] = Variable<int>(maxDepth);
    map['auto_scrape'] = Variable<bool>(autoScrape);
    if (!nullToAbsent || requestDelayMs != null) {
      map['request_delay_ms'] = Variable<int>(requestDelayMs);
    }
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      name: Value(name),
      baseUrl: Value(baseUrl),
      isOnline: Value(isOnline),
      lastScraped: lastScraped == null && nullToAbsent
          ? const Value.absent()
          : Value(lastScraped),
      createdAt: Value(createdAt),
      maxDepth: Value(maxDepth),
      autoScrape: Value(autoScrape),
      requestDelayMs: requestDelayMs == null && nullToAbsent
          ? const Value.absent()
          : Value(requestDelayMs),
    );
  }

  factory Source.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Source(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      isOnline: serializer.fromJson<bool>(json['isOnline']),
      lastScraped: serializer.fromJson<DateTime?>(json['lastScraped']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      maxDepth: serializer.fromJson<int>(json['maxDepth']),
      autoScrape: serializer.fromJson<bool>(json['autoScrape']),
      requestDelayMs: serializer.fromJson<int?>(json['requestDelayMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'isOnline': serializer.toJson<bool>(isOnline),
      'lastScraped': serializer.toJson<DateTime?>(lastScraped),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'maxDepth': serializer.toJson<int>(maxDepth),
      'autoScrape': serializer.toJson<bool>(autoScrape),
      'requestDelayMs': serializer.toJson<int?>(requestDelayMs),
    };
  }

  Source copyWith({
    int? id,
    String? name,
    String? baseUrl,
    bool? isOnline,
    Value<DateTime?> lastScraped = const Value.absent(),
    DateTime? createdAt,
    int? maxDepth,
    bool? autoScrape,
    Value<int?> requestDelayMs = const Value.absent(),
  }) => Source(
    id: id ?? this.id,
    name: name ?? this.name,
    baseUrl: baseUrl ?? this.baseUrl,
    isOnline: isOnline ?? this.isOnline,
    lastScraped: lastScraped.present ? lastScraped.value : this.lastScraped,
    createdAt: createdAt ?? this.createdAt,
    maxDepth: maxDepth ?? this.maxDepth,
    autoScrape: autoScrape ?? this.autoScrape,
    requestDelayMs: requestDelayMs.present
        ? requestDelayMs.value
        : this.requestDelayMs,
  );
  Source copyWithCompanion(SourcesCompanion data) {
    return Source(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      isOnline: data.isOnline.present ? data.isOnline.value : this.isOnline,
      lastScraped: data.lastScraped.present
          ? data.lastScraped.value
          : this.lastScraped,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      maxDepth: data.maxDepth.present ? data.maxDepth.value : this.maxDepth,
      autoScrape: data.autoScrape.present
          ? data.autoScrape.value
          : this.autoScrape,
      requestDelayMs: data.requestDelayMs.present
          ? data.requestDelayMs.value
          : this.requestDelayMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Source(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('isOnline: $isOnline, ')
          ..write('lastScraped: $lastScraped, ')
          ..write('createdAt: $createdAt, ')
          ..write('maxDepth: $maxDepth, ')
          ..write('autoScrape: $autoScrape, ')
          ..write('requestDelayMs: $requestDelayMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    baseUrl,
    isOnline,
    lastScraped,
    createdAt,
    maxDepth,
    autoScrape,
    requestDelayMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Source &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseUrl == this.baseUrl &&
          other.isOnline == this.isOnline &&
          other.lastScraped == this.lastScraped &&
          other.createdAt == this.createdAt &&
          other.maxDepth == this.maxDepth &&
          other.autoScrape == this.autoScrape &&
          other.requestDelayMs == this.requestDelayMs);
}

class SourcesCompanion extends UpdateCompanion<Source> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> baseUrl;
  final Value<bool> isOnline;
  final Value<DateTime?> lastScraped;
  final Value<DateTime> createdAt;
  final Value<int> maxDepth;
  final Value<bool> autoScrape;
  final Value<int?> requestDelayMs;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.isOnline = const Value.absent(),
    this.lastScraped = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.maxDepth = const Value.absent(),
    this.autoScrape = const Value.absent(),
    this.requestDelayMs = const Value.absent(),
  });
  SourcesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String baseUrl,
    this.isOnline = const Value.absent(),
    this.lastScraped = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.maxDepth = const Value.absent(),
    this.autoScrape = const Value.absent(),
    this.requestDelayMs = const Value.absent(),
  }) : name = Value(name),
       baseUrl = Value(baseUrl);
  static Insertable<Source> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? baseUrl,
    Expression<bool>? isOnline,
    Expression<DateTime>? lastScraped,
    Expression<DateTime>? createdAt,
    Expression<int>? maxDepth,
    Expression<bool>? autoScrape,
    Expression<int>? requestDelayMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseUrl != null) 'base_url': baseUrl,
      if (isOnline != null) 'is_online': isOnline,
      if (lastScraped != null) 'last_scraped': lastScraped,
      if (createdAt != null) 'created_at': createdAt,
      if (maxDepth != null) 'max_depth': maxDepth,
      if (autoScrape != null) 'auto_scrape': autoScrape,
      if (requestDelayMs != null) 'request_delay_ms': requestDelayMs,
    });
  }

  SourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? baseUrl,
    Value<bool>? isOnline,
    Value<DateTime?>? lastScraped,
    Value<DateTime>? createdAt,
    Value<int>? maxDepth,
    Value<bool>? autoScrape,
    Value<int?>? requestDelayMs,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      isOnline: isOnline ?? this.isOnline,
      lastScraped: lastScraped ?? this.lastScraped,
      createdAt: createdAt ?? this.createdAt,
      maxDepth: maxDepth ?? this.maxDepth,
      autoScrape: autoScrape ?? this.autoScrape,
      requestDelayMs: requestDelayMs ?? this.requestDelayMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (isOnline.present) {
      map['is_online'] = Variable<bool>(isOnline.value);
    }
    if (lastScraped.present) {
      map['last_scraped'] = Variable<DateTime>(lastScraped.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (maxDepth.present) {
      map['max_depth'] = Variable<int>(maxDepth.value);
    }
    if (autoScrape.present) {
      map['auto_scrape'] = Variable<bool>(autoScrape.value);
    }
    if (requestDelayMs.present) {
      map['request_delay_ms'] = Variable<int>(requestDelayMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('isOnline: $isOnline, ')
          ..write('lastScraped: $lastScraped, ')
          ..write('createdAt: $createdAt, ')
          ..write('maxDepth: $maxDepth, ')
          ..write('autoScrape: $autoScrape, ')
          ..write('requestDelayMs: $requestDelayMs')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  static const VerificationMeta _rawNameMeta = const VerificationMeta(
    'rawName',
  );
  @override
  late final GeneratedColumn<String> rawName = GeneratedColumn<String>(
    'raw_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cleanTitleMeta = const VerificationMeta(
    'cleanTitle',
  );
  @override
  late final GeneratedColumn<String> cleanTitle = GeneratedColumn<String>(
    'clean_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupTitleMeta = const VerificationMeta(
    'groupTitle',
  );
  @override
  late final GeneratedColumn<String> groupTitle = GeneratedColumn<String>(
    'group_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directUrlMeta = const VerificationMeta(
    'directUrl',
  );
  @override
  late final GeneratedColumn<String> directUrl = GeneratedColumn<String>(
    'direct_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ScrapeItemType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ScrapeItemType>($MediaItemsTable.$convertertype);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeMeta = const VerificationMeta(
    'episode',
  );
  @override
  late final GeneratedColumn<int> episode = GeneratedColumn<int>(
    'episode',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileExtensionMeta = const VerificationMeta(
    'fileExtension',
  );
  @override
  late final GeneratedColumn<String> fileExtension = GeneratedColumn<String>(
    'file_extension',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    rawName,
    cleanTitle,
    groupTitle,
    directUrl,
    type,
    season,
    episode,
    fileExtension,
    fileSize,
    indexedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('raw_name')) {
      context.handle(
        _rawNameMeta,
        rawName.isAcceptableOrUnknown(data['raw_name']!, _rawNameMeta),
      );
    } else if (isInserting) {
      context.missing(_rawNameMeta);
    }
    if (data.containsKey('clean_title')) {
      context.handle(
        _cleanTitleMeta,
        cleanTitle.isAcceptableOrUnknown(data['clean_title']!, _cleanTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_cleanTitleMeta);
    }
    if (data.containsKey('group_title')) {
      context.handle(
        _groupTitleMeta,
        groupTitle.isAcceptableOrUnknown(data['group_title']!, _groupTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_groupTitleMeta);
    }
    if (data.containsKey('direct_url')) {
      context.handle(
        _directUrlMeta,
        directUrl.isAcceptableOrUnknown(data['direct_url']!, _directUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_directUrlMeta);
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    }
    if (data.containsKey('episode')) {
      context.handle(
        _episodeMeta,
        episode.isAcceptableOrUnknown(data['episode']!, _episodeMeta),
      );
    }
    if (data.containsKey('file_extension')) {
      context.handle(
        _fileExtensionMeta,
        fileExtension.isAcceptableOrUnknown(
          data['file_extension']!,
          _fileExtensionMeta,
        ),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      rawName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_name'],
      )!,
      cleanTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clean_title'],
      )!,
      groupTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_title'],
      )!,
      directUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direct_url'],
      )!,
      type: $MediaItemsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      ),
      episode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode'],
      ),
      fileExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_extension'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ScrapeItemType, String, String> $convertertype =
      const EnumNameConverter<ScrapeItemType>(ScrapeItemType.values);
}

class MediaItem extends DataClass implements Insertable<MediaItem> {
  final int id;
  final int sourceId;
  final String rawName;
  final String cleanTitle;
  final String groupTitle;
  final String directUrl;
  final ScrapeItemType type;
  final int? season;
  final int? episode;
  final String? fileExtension;
  final int? fileSize;
  final DateTime indexedAt;
  const MediaItem({
    required this.id,
    required this.sourceId,
    required this.rawName,
    required this.cleanTitle,
    required this.groupTitle,
    required this.directUrl,
    required this.type,
    this.season,
    this.episode,
    this.fileExtension,
    this.fileSize,
    required this.indexedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<int>(sourceId);
    map['raw_name'] = Variable<String>(rawName);
    map['clean_title'] = Variable<String>(cleanTitle);
    map['group_title'] = Variable<String>(groupTitle);
    map['direct_url'] = Variable<String>(directUrl);
    {
      map['type'] = Variable<String>(
        $MediaItemsTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || season != null) {
      map['season'] = Variable<int>(season);
    }
    if (!nullToAbsent || episode != null) {
      map['episode'] = Variable<int>(episode);
    }
    if (!nullToAbsent || fileExtension != null) {
      map['file_extension'] = Variable<String>(fileExtension);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      rawName: Value(rawName),
      cleanTitle: Value(cleanTitle),
      groupTitle: Value(groupTitle),
      directUrl: Value(directUrl),
      type: Value(type),
      season: season == null && nullToAbsent
          ? const Value.absent()
          : Value(season),
      episode: episode == null && nullToAbsent
          ? const Value.absent()
          : Value(episode),
      fileExtension: fileExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(fileExtension),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      indexedAt: Value(indexedAt),
    );
  }

  factory MediaItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItem(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
      rawName: serializer.fromJson<String>(json['rawName']),
      cleanTitle: serializer.fromJson<String>(json['cleanTitle']),
      groupTitle: serializer.fromJson<String>(json['groupTitle']),
      directUrl: serializer.fromJson<String>(json['directUrl']),
      type: $MediaItemsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      season: serializer.fromJson<int?>(json['season']),
      episode: serializer.fromJson<int?>(json['episode']),
      fileExtension: serializer.fromJson<String?>(json['fileExtension']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<int>(sourceId),
      'rawName': serializer.toJson<String>(rawName),
      'cleanTitle': serializer.toJson<String>(cleanTitle),
      'groupTitle': serializer.toJson<String>(groupTitle),
      'directUrl': serializer.toJson<String>(directUrl),
      'type': serializer.toJson<String>(
        $MediaItemsTable.$convertertype.toJson(type),
      ),
      'season': serializer.toJson<int?>(season),
      'episode': serializer.toJson<int?>(episode),
      'fileExtension': serializer.toJson<String?>(fileExtension),
      'fileSize': serializer.toJson<int?>(fileSize),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
    };
  }

  MediaItem copyWith({
    int? id,
    int? sourceId,
    String? rawName,
    String? cleanTitle,
    String? groupTitle,
    String? directUrl,
    ScrapeItemType? type,
    Value<int?> season = const Value.absent(),
    Value<int?> episode = const Value.absent(),
    Value<String?> fileExtension = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    DateTime? indexedAt,
  }) => MediaItem(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    rawName: rawName ?? this.rawName,
    cleanTitle: cleanTitle ?? this.cleanTitle,
    groupTitle: groupTitle ?? this.groupTitle,
    directUrl: directUrl ?? this.directUrl,
    type: type ?? this.type,
    season: season.present ? season.value : this.season,
    episode: episode.present ? episode.value : this.episode,
    fileExtension: fileExtension.present
        ? fileExtension.value
        : this.fileExtension,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    indexedAt: indexedAt ?? this.indexedAt,
  );
  MediaItem copyWithCompanion(MediaItemsCompanion data) {
    return MediaItem(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      rawName: data.rawName.present ? data.rawName.value : this.rawName,
      cleanTitle: data.cleanTitle.present
          ? data.cleanTitle.value
          : this.cleanTitle,
      groupTitle: data.groupTitle.present
          ? data.groupTitle.value
          : this.groupTitle,
      directUrl: data.directUrl.present ? data.directUrl.value : this.directUrl,
      type: data.type.present ? data.type.value : this.type,
      season: data.season.present ? data.season.value : this.season,
      episode: data.episode.present ? data.episode.value : this.episode,
      fileExtension: data.fileExtension.present
          ? data.fileExtension.value
          : this.fileExtension,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItem(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('rawName: $rawName, ')
          ..write('cleanTitle: $cleanTitle, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('directUrl: $directUrl, ')
          ..write('type: $type, ')
          ..write('season: $season, ')
          ..write('episode: $episode, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('fileSize: $fileSize, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    rawName,
    cleanTitle,
    groupTitle,
    directUrl,
    type,
    season,
    episode,
    fileExtension,
    fileSize,
    indexedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItem &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.rawName == this.rawName &&
          other.cleanTitle == this.cleanTitle &&
          other.groupTitle == this.groupTitle &&
          other.directUrl == this.directUrl &&
          other.type == this.type &&
          other.season == this.season &&
          other.episode == this.episode &&
          other.fileExtension == this.fileExtension &&
          other.fileSize == this.fileSize &&
          other.indexedAt == this.indexedAt);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItem> {
  final Value<int> id;
  final Value<int> sourceId;
  final Value<String> rawName;
  final Value<String> cleanTitle;
  final Value<String> groupTitle;
  final Value<String> directUrl;
  final Value<ScrapeItemType> type;
  final Value<int?> season;
  final Value<int?> episode;
  final Value<String?> fileExtension;
  final Value<int?> fileSize;
  final Value<DateTime> indexedAt;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rawName = const Value.absent(),
    this.cleanTitle = const Value.absent(),
    this.groupTitle = const Value.absent(),
    this.directUrl = const Value.absent(),
    this.type = const Value.absent(),
    this.season = const Value.absent(),
    this.episode = const Value.absent(),
    this.fileExtension = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.indexedAt = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    this.id = const Value.absent(),
    required int sourceId,
    required String rawName,
    required String cleanTitle,
    required String groupTitle,
    required String directUrl,
    required ScrapeItemType type,
    this.season = const Value.absent(),
    this.episode = const Value.absent(),
    this.fileExtension = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.indexedAt = const Value.absent(),
  }) : sourceId = Value(sourceId),
       rawName = Value(rawName),
       cleanTitle = Value(cleanTitle),
       groupTitle = Value(groupTitle),
       directUrl = Value(directUrl),
       type = Value(type);
  static Insertable<MediaItem> custom({
    Expression<int>? id,
    Expression<int>? sourceId,
    Expression<String>? rawName,
    Expression<String>? cleanTitle,
    Expression<String>? groupTitle,
    Expression<String>? directUrl,
    Expression<String>? type,
    Expression<int>? season,
    Expression<int>? episode,
    Expression<String>? fileExtension,
    Expression<int>? fileSize,
    Expression<DateTime>? indexedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (rawName != null) 'raw_name': rawName,
      if (cleanTitle != null) 'clean_title': cleanTitle,
      if (groupTitle != null) 'group_title': groupTitle,
      if (directUrl != null) 'direct_url': directUrl,
      if (type != null) 'type': type,
      if (season != null) 'season': season,
      if (episode != null) 'episode': episode,
      if (fileExtension != null) 'file_extension': fileExtension,
      if (fileSize != null) 'file_size': fileSize,
      if (indexedAt != null) 'indexed_at': indexedAt,
    });
  }

  MediaItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? sourceId,
    Value<String>? rawName,
    Value<String>? cleanTitle,
    Value<String>? groupTitle,
    Value<String>? directUrl,
    Value<ScrapeItemType>? type,
    Value<int?>? season,
    Value<int?>? episode,
    Value<String?>? fileExtension,
    Value<int?>? fileSize,
    Value<DateTime>? indexedAt,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      rawName: rawName ?? this.rawName,
      cleanTitle: cleanTitle ?? this.cleanTitle,
      groupTitle: groupTitle ?? this.groupTitle,
      directUrl: directUrl ?? this.directUrl,
      type: type ?? this.type,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (rawName.present) {
      map['raw_name'] = Variable<String>(rawName.value);
    }
    if (cleanTitle.present) {
      map['clean_title'] = Variable<String>(cleanTitle.value);
    }
    if (groupTitle.present) {
      map['group_title'] = Variable<String>(groupTitle.value);
    }
    if (directUrl.present) {
      map['direct_url'] = Variable<String>(directUrl.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $MediaItemsTable.$convertertype.toSql(type.value),
      );
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (episode.present) {
      map['episode'] = Variable<int>(episode.value);
    }
    if (fileExtension.present) {
      map['file_extension'] = Variable<String>(fileExtension.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('rawName: $rawName, ')
          ..write('cleanTitle: $cleanTitle, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('directUrl: $directUrl, ')
          ..write('type: $type, ')
          ..write('season: $season, ')
          ..write('episode: $episode, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('fileSize: $fileSize, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }
}

class $MediaShowsTable extends MediaShows
    with TableInfo<$MediaShowsTable, MediaShow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaShowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupTitleMeta = const VerificationMeta(
    'groupTitle',
  );
  @override
  late final GeneratedColumn<String> groupTitle = GeneratedColumn<String>(
    'group_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _resolvedTitleMeta = const VerificationMeta(
    'resolvedTitle',
  );
  @override
  late final GeneratedColumn<String> resolvedTitle = GeneratedColumn<String>(
    'resolved_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleEnMeta = const VerificationMeta(
    'titleEn',
  );
  @override
  late final GeneratedColumn<String> titleEn = GeneratedColumn<String>(
    'title_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _animeTypeMeta = const VerificationMeta(
    'animeType',
  );
  @override
  late final GeneratedColumn<String> animeType = GeneratedColumn<String>(
    'anime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalEpisodesMeta = const VerificationMeta(
    'totalEpisodes',
  );
  @override
  late final GeneratedColumn<int> totalEpisodes = GeneratedColumn<int>(
    'total_episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fanartPathMeta = const VerificationMeta(
    'fanartPath',
  );
  @override
  late final GeneratedColumn<String> fanartPath = GeneratedColumn<String>(
    'fanart_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingSimklMeta = const VerificationMeta(
    'ratingSimkl',
  );
  @override
  late final GeneratedColumn<double> ratingSimkl = GeneratedColumn<double>(
    'rating_simkl',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMalMeta = const VerificationMeta(
    'ratingMal',
  );
  @override
  late final GeneratedColumn<double> ratingMal = GeneratedColumn<double>(
    'rating_mal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingImdbMeta = const VerificationMeta(
    'ratingImdb',
  );
  @override
  late final GeneratedColumn<double> ratingImdb = GeneratedColumn<double>(
    'rating_imdb',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _simklIdMeta = const VerificationMeta(
    'simklId',
  );
  @override
  late final GeneratedColumn<int> simklId = GeneratedColumn<int>(
    'simkl_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _simklSlugMeta = const VerificationMeta(
    'simklSlug',
  );
  @override
  late final GeneratedColumn<String> simklSlug = GeneratedColumn<String>(
    'simkl_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imdbIdMeta = const VerificationMeta('imdbId');
  @override
  late final GeneratedColumn<String> imdbId = GeneratedColumn<String>(
    'imdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<String> tmdbId = GeneratedColumn<String>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _malIdMeta = const VerificationMeta('malId');
  @override
  late final GeneratedColumn<int> malId = GeneratedColumn<int>(
    'mal_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anilistIdMeta = const VerificationMeta(
    'anilistId',
  );
  @override
  late final GeneratedColumn<int> anilistId = GeneratedColumn<int>(
    'anilist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tvdbIdMeta = const VerificationMeta('tvdbId');
  @override
  late final GeneratedColumn<int> tvdbId = GeneratedColumn<int>(
    'tvdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anidbIdMeta = const VerificationMeta(
    'anidbId',
  );
  @override
  late final GeneratedColumn<String> anidbId = GeneratedColumn<String>(
    'anidb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupTitle,
    resolvedTitle,
    titleEn,
    mediaType,
    animeType,
    year,
    totalEpisodes,
    posterPath,
    fanartPath,
    overview,
    ratingSimkl,
    ratingMal,
    ratingImdb,
    simklId,
    simklSlug,
    imdbId,
    tmdbId,
    malId,
    anilistId,
    tvdbId,
    anidbId,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_shows';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaShow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_title')) {
      context.handle(
        _groupTitleMeta,
        groupTitle.isAcceptableOrUnknown(data['group_title']!, _groupTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_groupTitleMeta);
    }
    if (data.containsKey('resolved_title')) {
      context.handle(
        _resolvedTitleMeta,
        resolvedTitle.isAcceptableOrUnknown(
          data['resolved_title']!,
          _resolvedTitleMeta,
        ),
      );
    }
    if (data.containsKey('title_en')) {
      context.handle(
        _titleEnMeta,
        titleEn.isAcceptableOrUnknown(data['title_en']!, _titleEnMeta),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    }
    if (data.containsKey('anime_type')) {
      context.handle(
        _animeTypeMeta,
        animeType.isAcceptableOrUnknown(data['anime_type']!, _animeTypeMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('total_episodes')) {
      context.handle(
        _totalEpisodesMeta,
        totalEpisodes.isAcceptableOrUnknown(
          data['total_episodes']!,
          _totalEpisodesMeta,
        ),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('fanart_path')) {
      context.handle(
        _fanartPathMeta,
        fanartPath.isAcceptableOrUnknown(data['fanart_path']!, _fanartPathMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('rating_simkl')) {
      context.handle(
        _ratingSimklMeta,
        ratingSimkl.isAcceptableOrUnknown(
          data['rating_simkl']!,
          _ratingSimklMeta,
        ),
      );
    }
    if (data.containsKey('rating_mal')) {
      context.handle(
        _ratingMalMeta,
        ratingMal.isAcceptableOrUnknown(data['rating_mal']!, _ratingMalMeta),
      );
    }
    if (data.containsKey('rating_imdb')) {
      context.handle(
        _ratingImdbMeta,
        ratingImdb.isAcceptableOrUnknown(data['rating_imdb']!, _ratingImdbMeta),
      );
    }
    if (data.containsKey('simkl_id')) {
      context.handle(
        _simklIdMeta,
        simklId.isAcceptableOrUnknown(data['simkl_id']!, _simklIdMeta),
      );
    }
    if (data.containsKey('simkl_slug')) {
      context.handle(
        _simklSlugMeta,
        simklSlug.isAcceptableOrUnknown(data['simkl_slug']!, _simklSlugMeta),
      );
    }
    if (data.containsKey('imdb_id')) {
      context.handle(
        _imdbIdMeta,
        imdbId.isAcceptableOrUnknown(data['imdb_id']!, _imdbIdMeta),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('mal_id')) {
      context.handle(
        _malIdMeta,
        malId.isAcceptableOrUnknown(data['mal_id']!, _malIdMeta),
      );
    }
    if (data.containsKey('anilist_id')) {
      context.handle(
        _anilistIdMeta,
        anilistId.isAcceptableOrUnknown(data['anilist_id']!, _anilistIdMeta),
      );
    }
    if (data.containsKey('tvdb_id')) {
      context.handle(
        _tvdbIdMeta,
        tvdbId.isAcceptableOrUnknown(data['tvdb_id']!, _tvdbIdMeta),
      );
    }
    if (data.containsKey('anidb_id')) {
      context.handle(
        _anidbIdMeta,
        anidbId.isAcceptableOrUnknown(data['anidb_id']!, _anidbIdMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaShow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaShow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_title'],
      )!,
      resolvedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_title'],
      ),
      titleEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_en'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      ),
      animeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_type'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      totalEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_episodes'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      fanartPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fanart_path'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      ratingSimkl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating_simkl'],
      ),
      ratingMal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating_mal'],
      ),
      ratingImdb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating_imdb'],
      ),
      simklId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}simkl_id'],
      ),
      simklSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}simkl_slug'],
      ),
      imdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imdb_id'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tmdb_id'],
      ),
      malId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mal_id'],
      ),
      anilistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anilist_id'],
      ),
      tvdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tvdb_id'],
      ),
      anidbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anidb_id'],
      ),
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $MediaShowsTable createAlias(String alias) {
    return $MediaShowsTable(attachedDatabase, alias);
  }
}

class MediaShow extends DataClass implements Insertable<MediaShow> {
  final int id;
  final String groupTitle;
  final String? resolvedTitle;
  final String? titleEn;
  final String? mediaType;
  final String? animeType;
  final int? year;
  final int? totalEpisodes;
  final String? posterPath;
  final String? fanartPath;
  final String? overview;
  final double? ratingSimkl;
  final double? ratingMal;
  final double? ratingImdb;
  final int? simklId;
  final String? simklSlug;
  final String? imdbId;
  final String? tmdbId;
  final int? malId;
  final int? anilistId;
  final int? tvdbId;
  final String? anidbId;
  final DateTime? resolvedAt;
  const MediaShow({
    required this.id,
    required this.groupTitle,
    this.resolvedTitle,
    this.titleEn,
    this.mediaType,
    this.animeType,
    this.year,
    this.totalEpisodes,
    this.posterPath,
    this.fanartPath,
    this.overview,
    this.ratingSimkl,
    this.ratingMal,
    this.ratingImdb,
    this.simklId,
    this.simklSlug,
    this.imdbId,
    this.tmdbId,
    this.malId,
    this.anilistId,
    this.tvdbId,
    this.anidbId,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_title'] = Variable<String>(groupTitle);
    if (!nullToAbsent || resolvedTitle != null) {
      map['resolved_title'] = Variable<String>(resolvedTitle);
    }
    if (!nullToAbsent || titleEn != null) {
      map['title_en'] = Variable<String>(titleEn);
    }
    if (!nullToAbsent || mediaType != null) {
      map['media_type'] = Variable<String>(mediaType);
    }
    if (!nullToAbsent || animeType != null) {
      map['anime_type'] = Variable<String>(animeType);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || totalEpisodes != null) {
      map['total_episodes'] = Variable<int>(totalEpisodes);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || fanartPath != null) {
      map['fanart_path'] = Variable<String>(fanartPath);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || ratingSimkl != null) {
      map['rating_simkl'] = Variable<double>(ratingSimkl);
    }
    if (!nullToAbsent || ratingMal != null) {
      map['rating_mal'] = Variable<double>(ratingMal);
    }
    if (!nullToAbsent || ratingImdb != null) {
      map['rating_imdb'] = Variable<double>(ratingImdb);
    }
    if (!nullToAbsent || simklId != null) {
      map['simkl_id'] = Variable<int>(simklId);
    }
    if (!nullToAbsent || simklSlug != null) {
      map['simkl_slug'] = Variable<String>(simklSlug);
    }
    if (!nullToAbsent || imdbId != null) {
      map['imdb_id'] = Variable<String>(imdbId);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<String>(tmdbId);
    }
    if (!nullToAbsent || malId != null) {
      map['mal_id'] = Variable<int>(malId);
    }
    if (!nullToAbsent || anilistId != null) {
      map['anilist_id'] = Variable<int>(anilistId);
    }
    if (!nullToAbsent || tvdbId != null) {
      map['tvdb_id'] = Variable<int>(tvdbId);
    }
    if (!nullToAbsent || anidbId != null) {
      map['anidb_id'] = Variable<String>(anidbId);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  MediaShowsCompanion toCompanion(bool nullToAbsent) {
    return MediaShowsCompanion(
      id: Value(id),
      groupTitle: Value(groupTitle),
      resolvedTitle: resolvedTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedTitle),
      titleEn: titleEn == null && nullToAbsent
          ? const Value.absent()
          : Value(titleEn),
      mediaType: mediaType == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaType),
      animeType: animeType == null && nullToAbsent
          ? const Value.absent()
          : Value(animeType),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      totalEpisodes: totalEpisodes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalEpisodes),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      fanartPath: fanartPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fanartPath),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      ratingSimkl: ratingSimkl == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingSimkl),
      ratingMal: ratingMal == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingMal),
      ratingImdb: ratingImdb == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingImdb),
      simklId: simklId == null && nullToAbsent
          ? const Value.absent()
          : Value(simklId),
      simklSlug: simklSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(simklSlug),
      imdbId: imdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(imdbId),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      malId: malId == null && nullToAbsent
          ? const Value.absent()
          : Value(malId),
      anilistId: anilistId == null && nullToAbsent
          ? const Value.absent()
          : Value(anilistId),
      tvdbId: tvdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tvdbId),
      anidbId: anidbId == null && nullToAbsent
          ? const Value.absent()
          : Value(anidbId),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory MediaShow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaShow(
      id: serializer.fromJson<int>(json['id']),
      groupTitle: serializer.fromJson<String>(json['groupTitle']),
      resolvedTitle: serializer.fromJson<String?>(json['resolvedTitle']),
      titleEn: serializer.fromJson<String?>(json['titleEn']),
      mediaType: serializer.fromJson<String?>(json['mediaType']),
      animeType: serializer.fromJson<String?>(json['animeType']),
      year: serializer.fromJson<int?>(json['year']),
      totalEpisodes: serializer.fromJson<int?>(json['totalEpisodes']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      fanartPath: serializer.fromJson<String?>(json['fanartPath']),
      overview: serializer.fromJson<String?>(json['overview']),
      ratingSimkl: serializer.fromJson<double?>(json['ratingSimkl']),
      ratingMal: serializer.fromJson<double?>(json['ratingMal']),
      ratingImdb: serializer.fromJson<double?>(json['ratingImdb']),
      simklId: serializer.fromJson<int?>(json['simklId']),
      simklSlug: serializer.fromJson<String?>(json['simklSlug']),
      imdbId: serializer.fromJson<String?>(json['imdbId']),
      tmdbId: serializer.fromJson<String?>(json['tmdbId']),
      malId: serializer.fromJson<int?>(json['malId']),
      anilistId: serializer.fromJson<int?>(json['anilistId']),
      tvdbId: serializer.fromJson<int?>(json['tvdbId']),
      anidbId: serializer.fromJson<String?>(json['anidbId']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupTitle': serializer.toJson<String>(groupTitle),
      'resolvedTitle': serializer.toJson<String?>(resolvedTitle),
      'titleEn': serializer.toJson<String?>(titleEn),
      'mediaType': serializer.toJson<String?>(mediaType),
      'animeType': serializer.toJson<String?>(animeType),
      'year': serializer.toJson<int?>(year),
      'totalEpisodes': serializer.toJson<int?>(totalEpisodes),
      'posterPath': serializer.toJson<String?>(posterPath),
      'fanartPath': serializer.toJson<String?>(fanartPath),
      'overview': serializer.toJson<String?>(overview),
      'ratingSimkl': serializer.toJson<double?>(ratingSimkl),
      'ratingMal': serializer.toJson<double?>(ratingMal),
      'ratingImdb': serializer.toJson<double?>(ratingImdb),
      'simklId': serializer.toJson<int?>(simklId),
      'simklSlug': serializer.toJson<String?>(simklSlug),
      'imdbId': serializer.toJson<String?>(imdbId),
      'tmdbId': serializer.toJson<String?>(tmdbId),
      'malId': serializer.toJson<int?>(malId),
      'anilistId': serializer.toJson<int?>(anilistId),
      'tvdbId': serializer.toJson<int?>(tvdbId),
      'anidbId': serializer.toJson<String?>(anidbId),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  MediaShow copyWith({
    int? id,
    String? groupTitle,
    Value<String?> resolvedTitle = const Value.absent(),
    Value<String?> titleEn = const Value.absent(),
    Value<String?> mediaType = const Value.absent(),
    Value<String?> animeType = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<int?> totalEpisodes = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    Value<String?> fanartPath = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<double?> ratingSimkl = const Value.absent(),
    Value<double?> ratingMal = const Value.absent(),
    Value<double?> ratingImdb = const Value.absent(),
    Value<int?> simklId = const Value.absent(),
    Value<String?> simklSlug = const Value.absent(),
    Value<String?> imdbId = const Value.absent(),
    Value<String?> tmdbId = const Value.absent(),
    Value<int?> malId = const Value.absent(),
    Value<int?> anilistId = const Value.absent(),
    Value<int?> tvdbId = const Value.absent(),
    Value<String?> anidbId = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => MediaShow(
    id: id ?? this.id,
    groupTitle: groupTitle ?? this.groupTitle,
    resolvedTitle: resolvedTitle.present
        ? resolvedTitle.value
        : this.resolvedTitle,
    titleEn: titleEn.present ? titleEn.value : this.titleEn,
    mediaType: mediaType.present ? mediaType.value : this.mediaType,
    animeType: animeType.present ? animeType.value : this.animeType,
    year: year.present ? year.value : this.year,
    totalEpisodes: totalEpisodes.present
        ? totalEpisodes.value
        : this.totalEpisodes,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    fanartPath: fanartPath.present ? fanartPath.value : this.fanartPath,
    overview: overview.present ? overview.value : this.overview,
    ratingSimkl: ratingSimkl.present ? ratingSimkl.value : this.ratingSimkl,
    ratingMal: ratingMal.present ? ratingMal.value : this.ratingMal,
    ratingImdb: ratingImdb.present ? ratingImdb.value : this.ratingImdb,
    simklId: simklId.present ? simklId.value : this.simklId,
    simklSlug: simklSlug.present ? simklSlug.value : this.simklSlug,
    imdbId: imdbId.present ? imdbId.value : this.imdbId,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    malId: malId.present ? malId.value : this.malId,
    anilistId: anilistId.present ? anilistId.value : this.anilistId,
    tvdbId: tvdbId.present ? tvdbId.value : this.tvdbId,
    anidbId: anidbId.present ? anidbId.value : this.anidbId,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  MediaShow copyWithCompanion(MediaShowsCompanion data) {
    return MediaShow(
      id: data.id.present ? data.id.value : this.id,
      groupTitle: data.groupTitle.present
          ? data.groupTitle.value
          : this.groupTitle,
      resolvedTitle: data.resolvedTitle.present
          ? data.resolvedTitle.value
          : this.resolvedTitle,
      titleEn: data.titleEn.present ? data.titleEn.value : this.titleEn,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      animeType: data.animeType.present ? data.animeType.value : this.animeType,
      year: data.year.present ? data.year.value : this.year,
      totalEpisodes: data.totalEpisodes.present
          ? data.totalEpisodes.value
          : this.totalEpisodes,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      fanartPath: data.fanartPath.present
          ? data.fanartPath.value
          : this.fanartPath,
      overview: data.overview.present ? data.overview.value : this.overview,
      ratingSimkl: data.ratingSimkl.present
          ? data.ratingSimkl.value
          : this.ratingSimkl,
      ratingMal: data.ratingMal.present ? data.ratingMal.value : this.ratingMal,
      ratingImdb: data.ratingImdb.present
          ? data.ratingImdb.value
          : this.ratingImdb,
      simklId: data.simklId.present ? data.simklId.value : this.simklId,
      simklSlug: data.simklSlug.present ? data.simklSlug.value : this.simklSlug,
      imdbId: data.imdbId.present ? data.imdbId.value : this.imdbId,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      malId: data.malId.present ? data.malId.value : this.malId,
      anilistId: data.anilistId.present ? data.anilistId.value : this.anilistId,
      tvdbId: data.tvdbId.present ? data.tvdbId.value : this.tvdbId,
      anidbId: data.anidbId.present ? data.anidbId.value : this.anidbId,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaShow(')
          ..write('id: $id, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('resolvedTitle: $resolvedTitle, ')
          ..write('titleEn: $titleEn, ')
          ..write('mediaType: $mediaType, ')
          ..write('animeType: $animeType, ')
          ..write('year: $year, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('posterPath: $posterPath, ')
          ..write('fanartPath: $fanartPath, ')
          ..write('overview: $overview, ')
          ..write('ratingSimkl: $ratingSimkl, ')
          ..write('ratingMal: $ratingMal, ')
          ..write('ratingImdb: $ratingImdb, ')
          ..write('simklId: $simklId, ')
          ..write('simklSlug: $simklSlug, ')
          ..write('imdbId: $imdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('malId: $malId, ')
          ..write('anilistId: $anilistId, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('anidbId: $anidbId, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    groupTitle,
    resolvedTitle,
    titleEn,
    mediaType,
    animeType,
    year,
    totalEpisodes,
    posterPath,
    fanartPath,
    overview,
    ratingSimkl,
    ratingMal,
    ratingImdb,
    simklId,
    simklSlug,
    imdbId,
    tmdbId,
    malId,
    anilistId,
    tvdbId,
    anidbId,
    resolvedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaShow &&
          other.id == this.id &&
          other.groupTitle == this.groupTitle &&
          other.resolvedTitle == this.resolvedTitle &&
          other.titleEn == this.titleEn &&
          other.mediaType == this.mediaType &&
          other.animeType == this.animeType &&
          other.year == this.year &&
          other.totalEpisodes == this.totalEpisodes &&
          other.posterPath == this.posterPath &&
          other.fanartPath == this.fanartPath &&
          other.overview == this.overview &&
          other.ratingSimkl == this.ratingSimkl &&
          other.ratingMal == this.ratingMal &&
          other.ratingImdb == this.ratingImdb &&
          other.simklId == this.simklId &&
          other.simklSlug == this.simklSlug &&
          other.imdbId == this.imdbId &&
          other.tmdbId == this.tmdbId &&
          other.malId == this.malId &&
          other.anilistId == this.anilistId &&
          other.tvdbId == this.tvdbId &&
          other.anidbId == this.anidbId &&
          other.resolvedAt == this.resolvedAt);
}

class MediaShowsCompanion extends UpdateCompanion<MediaShow> {
  final Value<int> id;
  final Value<String> groupTitle;
  final Value<String?> resolvedTitle;
  final Value<String?> titleEn;
  final Value<String?> mediaType;
  final Value<String?> animeType;
  final Value<int?> year;
  final Value<int?> totalEpisodes;
  final Value<String?> posterPath;
  final Value<String?> fanartPath;
  final Value<String?> overview;
  final Value<double?> ratingSimkl;
  final Value<double?> ratingMal;
  final Value<double?> ratingImdb;
  final Value<int?> simklId;
  final Value<String?> simklSlug;
  final Value<String?> imdbId;
  final Value<String?> tmdbId;
  final Value<int?> malId;
  final Value<int?> anilistId;
  final Value<int?> tvdbId;
  final Value<String?> anidbId;
  final Value<DateTime?> resolvedAt;
  const MediaShowsCompanion({
    this.id = const Value.absent(),
    this.groupTitle = const Value.absent(),
    this.resolvedTitle = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.animeType = const Value.absent(),
    this.year = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.fanartPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.ratingSimkl = const Value.absent(),
    this.ratingMal = const Value.absent(),
    this.ratingImdb = const Value.absent(),
    this.simklId = const Value.absent(),
    this.simklSlug = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.malId = const Value.absent(),
    this.anilistId = const Value.absent(),
    this.tvdbId = const Value.absent(),
    this.anidbId = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  });
  MediaShowsCompanion.insert({
    this.id = const Value.absent(),
    required String groupTitle,
    this.resolvedTitle = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.animeType = const Value.absent(),
    this.year = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.fanartPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.ratingSimkl = const Value.absent(),
    this.ratingMal = const Value.absent(),
    this.ratingImdb = const Value.absent(),
    this.simklId = const Value.absent(),
    this.simklSlug = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.malId = const Value.absent(),
    this.anilistId = const Value.absent(),
    this.tvdbId = const Value.absent(),
    this.anidbId = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  }) : groupTitle = Value(groupTitle);
  static Insertable<MediaShow> custom({
    Expression<int>? id,
    Expression<String>? groupTitle,
    Expression<String>? resolvedTitle,
    Expression<String>? titleEn,
    Expression<String>? mediaType,
    Expression<String>? animeType,
    Expression<int>? year,
    Expression<int>? totalEpisodes,
    Expression<String>? posterPath,
    Expression<String>? fanartPath,
    Expression<String>? overview,
    Expression<double>? ratingSimkl,
    Expression<double>? ratingMal,
    Expression<double>? ratingImdb,
    Expression<int>? simklId,
    Expression<String>? simklSlug,
    Expression<String>? imdbId,
    Expression<String>? tmdbId,
    Expression<int>? malId,
    Expression<int>? anilistId,
    Expression<int>? tvdbId,
    Expression<String>? anidbId,
    Expression<DateTime>? resolvedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupTitle != null) 'group_title': groupTitle,
      if (resolvedTitle != null) 'resolved_title': resolvedTitle,
      if (titleEn != null) 'title_en': titleEn,
      if (mediaType != null) 'media_type': mediaType,
      if (animeType != null) 'anime_type': animeType,
      if (year != null) 'year': year,
      if (totalEpisodes != null) 'total_episodes': totalEpisodes,
      if (posterPath != null) 'poster_path': posterPath,
      if (fanartPath != null) 'fanart_path': fanartPath,
      if (overview != null) 'overview': overview,
      if (ratingSimkl != null) 'rating_simkl': ratingSimkl,
      if (ratingMal != null) 'rating_mal': ratingMal,
      if (ratingImdb != null) 'rating_imdb': ratingImdb,
      if (simklId != null) 'simkl_id': simklId,
      if (simklSlug != null) 'simkl_slug': simklSlug,
      if (imdbId != null) 'imdb_id': imdbId,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (malId != null) 'mal_id': malId,
      if (anilistId != null) 'anilist_id': anilistId,
      if (tvdbId != null) 'tvdb_id': tvdbId,
      if (anidbId != null) 'anidb_id': anidbId,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
    });
  }

  MediaShowsCompanion copyWith({
    Value<int>? id,
    Value<String>? groupTitle,
    Value<String?>? resolvedTitle,
    Value<String?>? titleEn,
    Value<String?>? mediaType,
    Value<String?>? animeType,
    Value<int?>? year,
    Value<int?>? totalEpisodes,
    Value<String?>? posterPath,
    Value<String?>? fanartPath,
    Value<String?>? overview,
    Value<double?>? ratingSimkl,
    Value<double?>? ratingMal,
    Value<double?>? ratingImdb,
    Value<int?>? simklId,
    Value<String?>? simklSlug,
    Value<String?>? imdbId,
    Value<String?>? tmdbId,
    Value<int?>? malId,
    Value<int?>? anilistId,
    Value<int?>? tvdbId,
    Value<String?>? anidbId,
    Value<DateTime?>? resolvedAt,
  }) {
    return MediaShowsCompanion(
      id: id ?? this.id,
      groupTitle: groupTitle ?? this.groupTitle,
      resolvedTitle: resolvedTitle ?? this.resolvedTitle,
      titleEn: titleEn ?? this.titleEn,
      mediaType: mediaType ?? this.mediaType,
      animeType: animeType ?? this.animeType,
      year: year ?? this.year,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      posterPath: posterPath ?? this.posterPath,
      fanartPath: fanartPath ?? this.fanartPath,
      overview: overview ?? this.overview,
      ratingSimkl: ratingSimkl ?? this.ratingSimkl,
      ratingMal: ratingMal ?? this.ratingMal,
      ratingImdb: ratingImdb ?? this.ratingImdb,
      simklId: simklId ?? this.simklId,
      simklSlug: simklSlug ?? this.simklSlug,
      imdbId: imdbId ?? this.imdbId,
      tmdbId: tmdbId ?? this.tmdbId,
      malId: malId ?? this.malId,
      anilistId: anilistId ?? this.anilistId,
      tvdbId: tvdbId ?? this.tvdbId,
      anidbId: anidbId ?? this.anidbId,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupTitle.present) {
      map['group_title'] = Variable<String>(groupTitle.value);
    }
    if (resolvedTitle.present) {
      map['resolved_title'] = Variable<String>(resolvedTitle.value);
    }
    if (titleEn.present) {
      map['title_en'] = Variable<String>(titleEn.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (animeType.present) {
      map['anime_type'] = Variable<String>(animeType.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (totalEpisodes.present) {
      map['total_episodes'] = Variable<int>(totalEpisodes.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (fanartPath.present) {
      map['fanart_path'] = Variable<String>(fanartPath.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (ratingSimkl.present) {
      map['rating_simkl'] = Variable<double>(ratingSimkl.value);
    }
    if (ratingMal.present) {
      map['rating_mal'] = Variable<double>(ratingMal.value);
    }
    if (ratingImdb.present) {
      map['rating_imdb'] = Variable<double>(ratingImdb.value);
    }
    if (simklId.present) {
      map['simkl_id'] = Variable<int>(simklId.value);
    }
    if (simklSlug.present) {
      map['simkl_slug'] = Variable<String>(simklSlug.value);
    }
    if (imdbId.present) {
      map['imdb_id'] = Variable<String>(imdbId.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<String>(tmdbId.value);
    }
    if (malId.present) {
      map['mal_id'] = Variable<int>(malId.value);
    }
    if (anilistId.present) {
      map['anilist_id'] = Variable<int>(anilistId.value);
    }
    if (tvdbId.present) {
      map['tvdb_id'] = Variable<int>(tvdbId.value);
    }
    if (anidbId.present) {
      map['anidb_id'] = Variable<String>(anidbId.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaShowsCompanion(')
          ..write('id: $id, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('resolvedTitle: $resolvedTitle, ')
          ..write('titleEn: $titleEn, ')
          ..write('mediaType: $mediaType, ')
          ..write('animeType: $animeType, ')
          ..write('year: $year, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('posterPath: $posterPath, ')
          ..write('fanartPath: $fanartPath, ')
          ..write('overview: $overview, ')
          ..write('ratingSimkl: $ratingSimkl, ')
          ..write('ratingMal: $ratingMal, ')
          ..write('ratingImdb: $ratingImdb, ')
          ..write('simklId: $simklId, ')
          ..write('simklSlug: $simklSlug, ')
          ..write('imdbId: $imdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('malId: $malId, ')
          ..write('anilistId: $anilistId, ')
          ..write('tvdbId: $tvdbId, ')
          ..write('anidbId: $anidbId, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }
}

class $IndexedFoldersTable extends IndexedFolders
    with TableInfo<$IndexedFoldersTable, IndexedFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndexedFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  static const VerificationMeta _folderNameMeta = const VerificationMeta(
    'folderName',
  );
  @override
  late final GeneratedColumn<String> folderName = GeneratedColumn<String>(
    'folder_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cleanTitleMeta = const VerificationMeta(
    'cleanTitle',
  );
  @override
  late final GeneratedColumn<String> cleanTitle = GeneratedColumn<String>(
    'clean_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderUrlMeta = const VerificationMeta(
    'folderUrl',
  );
  @override
  late final GeneratedColumn<String> folderUrl = GeneratedColumn<String>(
    'folder_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isScrapedMeta = const VerificationMeta(
    'isScraped',
  );
  @override
  late final GeneratedColumn<bool> isScraped = GeneratedColumn<bool>(
    'is_scraped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_scraped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastScrapedMeta = const VerificationMeta(
    'lastScraped',
  );
  @override
  late final GeneratedColumn<DateTime> lastScraped = GeneratedColumn<DateTime>(
    'last_scraped',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _scrapeErrorsMeta = const VerificationMeta(
    'scrapeErrors',
  );
  @override
  late final GeneratedColumn<String> scrapeErrors = GeneratedColumn<String>(
    'scrape_errors',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    folderName,
    cleanTitle,
    folderUrl,
    year,
    isScraped,
    lastScraped,
    indexedAt,
    scrapeErrors,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'indexed_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<IndexedFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('folder_name')) {
      context.handle(
        _folderNameMeta,
        folderName.isAcceptableOrUnknown(data['folder_name']!, _folderNameMeta),
      );
    } else if (isInserting) {
      context.missing(_folderNameMeta);
    }
    if (data.containsKey('clean_title')) {
      context.handle(
        _cleanTitleMeta,
        cleanTitle.isAcceptableOrUnknown(data['clean_title']!, _cleanTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_cleanTitleMeta);
    }
    if (data.containsKey('folder_url')) {
      context.handle(
        _folderUrlMeta,
        folderUrl.isAcceptableOrUnknown(data['folder_url']!, _folderUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_folderUrlMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('is_scraped')) {
      context.handle(
        _isScrapedMeta,
        isScraped.isAcceptableOrUnknown(data['is_scraped']!, _isScrapedMeta),
      );
    }
    if (data.containsKey('last_scraped')) {
      context.handle(
        _lastScrapedMeta,
        lastScraped.isAcceptableOrUnknown(
          data['last_scraped']!,
          _lastScrapedMeta,
        ),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    }
    if (data.containsKey('scrape_errors')) {
      context.handle(
        _scrapeErrorsMeta,
        scrapeErrors.isAcceptableOrUnknown(
          data['scrape_errors']!,
          _scrapeErrorsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IndexedFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IndexedFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      folderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_name'],
      )!,
      cleanTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clean_title'],
      )!,
      folderUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_url'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      isScraped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_scraped'],
      )!,
      lastScraped: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_scraped'],
      ),
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
      scrapeErrors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scrape_errors'],
      ),
    );
  }

  @override
  $IndexedFoldersTable createAlias(String alias) {
    return $IndexedFoldersTable(attachedDatabase, alias);
  }
}

class IndexedFolder extends DataClass implements Insertable<IndexedFolder> {
  final int id;
  final int sourceId;
  final String folderName;
  final String cleanTitle;
  final String folderUrl;
  final int? year;
  final bool isScraped;
  final DateTime? lastScraped;
  final DateTime indexedAt;
  final String? scrapeErrors;
  const IndexedFolder({
    required this.id,
    required this.sourceId,
    required this.folderName,
    required this.cleanTitle,
    required this.folderUrl,
    this.year,
    required this.isScraped,
    this.lastScraped,
    required this.indexedAt,
    this.scrapeErrors,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<int>(sourceId);
    map['folder_name'] = Variable<String>(folderName);
    map['clean_title'] = Variable<String>(cleanTitle);
    map['folder_url'] = Variable<String>(folderUrl);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['is_scraped'] = Variable<bool>(isScraped);
    if (!nullToAbsent || lastScraped != null) {
      map['last_scraped'] = Variable<DateTime>(lastScraped);
    }
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    if (!nullToAbsent || scrapeErrors != null) {
      map['scrape_errors'] = Variable<String>(scrapeErrors);
    }
    return map;
  }

  IndexedFoldersCompanion toCompanion(bool nullToAbsent) {
    return IndexedFoldersCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      folderName: Value(folderName),
      cleanTitle: Value(cleanTitle),
      folderUrl: Value(folderUrl),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      isScraped: Value(isScraped),
      lastScraped: lastScraped == null && nullToAbsent
          ? const Value.absent()
          : Value(lastScraped),
      indexedAt: Value(indexedAt),
      scrapeErrors: scrapeErrors == null && nullToAbsent
          ? const Value.absent()
          : Value(scrapeErrors),
    );
  }

  factory IndexedFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IndexedFolder(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
      folderName: serializer.fromJson<String>(json['folderName']),
      cleanTitle: serializer.fromJson<String>(json['cleanTitle']),
      folderUrl: serializer.fromJson<String>(json['folderUrl']),
      year: serializer.fromJson<int?>(json['year']),
      isScraped: serializer.fromJson<bool>(json['isScraped']),
      lastScraped: serializer.fromJson<DateTime?>(json['lastScraped']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
      scrapeErrors: serializer.fromJson<String?>(json['scrapeErrors']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<int>(sourceId),
      'folderName': serializer.toJson<String>(folderName),
      'cleanTitle': serializer.toJson<String>(cleanTitle),
      'folderUrl': serializer.toJson<String>(folderUrl),
      'year': serializer.toJson<int?>(year),
      'isScraped': serializer.toJson<bool>(isScraped),
      'lastScraped': serializer.toJson<DateTime?>(lastScraped),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
      'scrapeErrors': serializer.toJson<String?>(scrapeErrors),
    };
  }

  IndexedFolder copyWith({
    int? id,
    int? sourceId,
    String? folderName,
    String? cleanTitle,
    String? folderUrl,
    Value<int?> year = const Value.absent(),
    bool? isScraped,
    Value<DateTime?> lastScraped = const Value.absent(),
    DateTime? indexedAt,
    Value<String?> scrapeErrors = const Value.absent(),
  }) => IndexedFolder(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    folderName: folderName ?? this.folderName,
    cleanTitle: cleanTitle ?? this.cleanTitle,
    folderUrl: folderUrl ?? this.folderUrl,
    year: year.present ? year.value : this.year,
    isScraped: isScraped ?? this.isScraped,
    lastScraped: lastScraped.present ? lastScraped.value : this.lastScraped,
    indexedAt: indexedAt ?? this.indexedAt,
    scrapeErrors: scrapeErrors.present ? scrapeErrors.value : this.scrapeErrors,
  );
  IndexedFolder copyWithCompanion(IndexedFoldersCompanion data) {
    return IndexedFolder(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      folderName: data.folderName.present
          ? data.folderName.value
          : this.folderName,
      cleanTitle: data.cleanTitle.present
          ? data.cleanTitle.value
          : this.cleanTitle,
      folderUrl: data.folderUrl.present ? data.folderUrl.value : this.folderUrl,
      year: data.year.present ? data.year.value : this.year,
      isScraped: data.isScraped.present ? data.isScraped.value : this.isScraped,
      lastScraped: data.lastScraped.present
          ? data.lastScraped.value
          : this.lastScraped,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
      scrapeErrors: data.scrapeErrors.present
          ? data.scrapeErrors.value
          : this.scrapeErrors,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IndexedFolder(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('folderName: $folderName, ')
          ..write('cleanTitle: $cleanTitle, ')
          ..write('folderUrl: $folderUrl, ')
          ..write('year: $year, ')
          ..write('isScraped: $isScraped, ')
          ..write('lastScraped: $lastScraped, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('scrapeErrors: $scrapeErrors')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    folderName,
    cleanTitle,
    folderUrl,
    year,
    isScraped,
    lastScraped,
    indexedAt,
    scrapeErrors,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndexedFolder &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.folderName == this.folderName &&
          other.cleanTitle == this.cleanTitle &&
          other.folderUrl == this.folderUrl &&
          other.year == this.year &&
          other.isScraped == this.isScraped &&
          other.lastScraped == this.lastScraped &&
          other.indexedAt == this.indexedAt &&
          other.scrapeErrors == this.scrapeErrors);
}

class IndexedFoldersCompanion extends UpdateCompanion<IndexedFolder> {
  final Value<int> id;
  final Value<int> sourceId;
  final Value<String> folderName;
  final Value<String> cleanTitle;
  final Value<String> folderUrl;
  final Value<int?> year;
  final Value<bool> isScraped;
  final Value<DateTime?> lastScraped;
  final Value<DateTime> indexedAt;
  final Value<String?> scrapeErrors;
  const IndexedFoldersCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.folderName = const Value.absent(),
    this.cleanTitle = const Value.absent(),
    this.folderUrl = const Value.absent(),
    this.year = const Value.absent(),
    this.isScraped = const Value.absent(),
    this.lastScraped = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.scrapeErrors = const Value.absent(),
  });
  IndexedFoldersCompanion.insert({
    this.id = const Value.absent(),
    required int sourceId,
    required String folderName,
    required String cleanTitle,
    required String folderUrl,
    this.year = const Value.absent(),
    this.isScraped = const Value.absent(),
    this.lastScraped = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.scrapeErrors = const Value.absent(),
  }) : sourceId = Value(sourceId),
       folderName = Value(folderName),
       cleanTitle = Value(cleanTitle),
       folderUrl = Value(folderUrl);
  static Insertable<IndexedFolder> custom({
    Expression<int>? id,
    Expression<int>? sourceId,
    Expression<String>? folderName,
    Expression<String>? cleanTitle,
    Expression<String>? folderUrl,
    Expression<int>? year,
    Expression<bool>? isScraped,
    Expression<DateTime>? lastScraped,
    Expression<DateTime>? indexedAt,
    Expression<String>? scrapeErrors,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (folderName != null) 'folder_name': folderName,
      if (cleanTitle != null) 'clean_title': cleanTitle,
      if (folderUrl != null) 'folder_url': folderUrl,
      if (year != null) 'year': year,
      if (isScraped != null) 'is_scraped': isScraped,
      if (lastScraped != null) 'last_scraped': lastScraped,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (scrapeErrors != null) 'scrape_errors': scrapeErrors,
    });
  }

  IndexedFoldersCompanion copyWith({
    Value<int>? id,
    Value<int>? sourceId,
    Value<String>? folderName,
    Value<String>? cleanTitle,
    Value<String>? folderUrl,
    Value<int?>? year,
    Value<bool>? isScraped,
    Value<DateTime?>? lastScraped,
    Value<DateTime>? indexedAt,
    Value<String?>? scrapeErrors,
  }) {
    return IndexedFoldersCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      folderName: folderName ?? this.folderName,
      cleanTitle: cleanTitle ?? this.cleanTitle,
      folderUrl: folderUrl ?? this.folderUrl,
      year: year ?? this.year,
      isScraped: isScraped ?? this.isScraped,
      lastScraped: lastScraped ?? this.lastScraped,
      indexedAt: indexedAt ?? this.indexedAt,
      scrapeErrors: scrapeErrors ?? this.scrapeErrors,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (folderName.present) {
      map['folder_name'] = Variable<String>(folderName.value);
    }
    if (cleanTitle.present) {
      map['clean_title'] = Variable<String>(cleanTitle.value);
    }
    if (folderUrl.present) {
      map['folder_url'] = Variable<String>(folderUrl.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (isScraped.present) {
      map['is_scraped'] = Variable<bool>(isScraped.value);
    }
    if (lastScraped.present) {
      map['last_scraped'] = Variable<DateTime>(lastScraped.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    if (scrapeErrors.present) {
      map['scrape_errors'] = Variable<String>(scrapeErrors.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndexedFoldersCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('folderName: $folderName, ')
          ..write('cleanTitle: $cleanTitle, ')
          ..write('folderUrl: $folderUrl, ')
          ..write('year: $year, ')
          ..write('isScraped: $isScraped, ')
          ..write('lastScraped: $lastScraped, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('scrapeErrors: $scrapeErrors')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $MediaShowsTable mediaShows = $MediaShowsTable(this);
  late final $IndexedFoldersTable indexedFolders = $IndexedFoldersTable(this);
  late final Index idxItemsSourceGroup = Index(
    'idx_items_source_group',
    'CREATE INDEX idx_items_source_group ON media_items (source_id, group_title)',
  );
  late final Index idxFoldersSourceTitle = Index(
    'idx_folders_source_title',
    'CREATE INDEX idx_folders_source_title ON indexed_folders (source_id, clean_title)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    mediaItems,
    mediaShows,
    indexedFolders,
    idxItemsSourceGroup,
    idxFoldersSourceTitle,
  ];
}

typedef $$SourcesTableCreateCompanionBuilder =
    SourcesCompanion Function({
      Value<int> id,
      required String name,
      required String baseUrl,
      Value<bool> isOnline,
      Value<DateTime?> lastScraped,
      Value<DateTime> createdAt,
      Value<int> maxDepth,
      Value<bool> autoScrape,
      Value<int?> requestDelayMs,
    });
typedef $$SourcesTableUpdateCompanionBuilder =
    SourcesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> baseUrl,
      Value<bool> isOnline,
      Value<DateTime?> lastScraped,
      Value<DateTime> createdAt,
      Value<int> maxDepth,
      Value<bool> autoScrape,
      Value<int?> requestDelayMs,
    });

final class $$SourcesTableReferences
    extends BaseReferences<_$AppDatabase, $SourcesTable, Source> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaItemsTable, List<MediaItem>>
  _mediaItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaItems,
    aliasName: 'sources__id__media_items__source_id',
  );

  $$MediaItemsTableProcessedTableManager get mediaItemsRefs {
    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IndexedFoldersTable, List<IndexedFolder>>
  _indexedFoldersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.indexedFolders,
    aliasName: 'sources__id__indexed_folders__source_id',
  );

  $$IndexedFoldersTableProcessedTableManager get indexedFoldersRefs {
    final manager = $$IndexedFoldersTableTableManager(
      $_db,
      $_db.indexedFolders,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_indexedFoldersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOnline => $composableBuilder(
    column: $table.isOnline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastScraped => $composableBuilder(
    column: $table.lastScraped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxDepth => $composableBuilder(
    column: $table.maxDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoScrape => $composableBuilder(
    column: $table.autoScrape,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requestDelayMs => $composableBuilder(
    column: $table.requestDelayMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaItemsRefs(
    Expression<bool> Function($$MediaItemsTableFilterComposer f) f,
  ) {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> indexedFoldersRefs(
    Expression<bool> Function($$IndexedFoldersTableFilterComposer f) f,
  ) {
    final $$IndexedFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.indexedFolders,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndexedFoldersTableFilterComposer(
            $db: $db,
            $table: $db.indexedFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOnline => $composableBuilder(
    column: $table.isOnline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastScraped => $composableBuilder(
    column: $table.lastScraped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxDepth => $composableBuilder(
    column: $table.maxDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoScrape => $composableBuilder(
    column: $table.autoScrape,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requestDelayMs => $composableBuilder(
    column: $table.requestDelayMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<bool> get isOnline =>
      $composableBuilder(column: $table.isOnline, builder: (column) => column);

  GeneratedColumn<DateTime> get lastScraped => $composableBuilder(
    column: $table.lastScraped,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get maxDepth =>
      $composableBuilder(column: $table.maxDepth, builder: (column) => column);

  GeneratedColumn<bool> get autoScrape => $composableBuilder(
    column: $table.autoScrape,
    builder: (column) => column,
  );

  GeneratedColumn<int> get requestDelayMs => $composableBuilder(
    column: $table.requestDelayMs,
    builder: (column) => column,
  );

  Expression<T> mediaItemsRefs<T extends Object>(
    Expression<T> Function($$MediaItemsTableAnnotationComposer a) f,
  ) {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> indexedFoldersRefs<T extends Object>(
    Expression<T> Function($$IndexedFoldersTableAnnotationComposer a) f,
  ) {
    final $$IndexedFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.indexedFolders,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndexedFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.indexedFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcesTable,
          Source,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (Source, $$SourcesTableReferences),
          Source,
          PrefetchHooks Function({bool mediaItemsRefs, bool indexedFoldersRefs})
        > {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<bool> isOnline = const Value.absent(),
                Value<DateTime?> lastScraped = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> maxDepth = const Value.absent(),
                Value<bool> autoScrape = const Value.absent(),
                Value<int?> requestDelayMs = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                name: name,
                baseUrl: baseUrl,
                isOnline: isOnline,
                lastScraped: lastScraped,
                createdAt: createdAt,
                maxDepth: maxDepth,
                autoScrape: autoScrape,
                requestDelayMs: requestDelayMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String baseUrl,
                Value<bool> isOnline = const Value.absent(),
                Value<DateTime?> lastScraped = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> maxDepth = const Value.absent(),
                Value<bool> autoScrape = const Value.absent(),
                Value<int?> requestDelayMs = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                name: name,
                baseUrl: baseUrl,
                isOnline: isOnline,
                lastScraped: lastScraped,
                createdAt: createdAt,
                maxDepth: maxDepth,
                autoScrape: autoScrape,
                requestDelayMs: requestDelayMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({mediaItemsRefs = false, indexedFoldersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaItemsRefs) db.mediaItems,
                    if (indexedFoldersRefs) db.indexedFolders,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaItemsRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          MediaItem
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._mediaItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (indexedFoldersRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          IndexedFolder
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._indexedFoldersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).indexedFoldersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcesTable,
      Source,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (Source, $$SourcesTableReferences),
      Source,
      PrefetchHooks Function({bool mediaItemsRefs, bool indexedFoldersRefs})
    >;
typedef $$MediaItemsTableCreateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<int> id,
      required int sourceId,
      required String rawName,
      required String cleanTitle,
      required String groupTitle,
      required String directUrl,
      required ScrapeItemType type,
      Value<int?> season,
      Value<int?> episode,
      Value<String?> fileExtension,
      Value<int?> fileSize,
      Value<DateTime> indexedAt,
    });
typedef $$MediaItemsTableUpdateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<int> id,
      Value<int> sourceId,
      Value<String> rawName,
      Value<String> cleanTitle,
      Value<String> groupTitle,
      Value<String> directUrl,
      Value<ScrapeItemType> type,
      Value<int?> season,
      Value<int?> episode,
      Value<String?> fileExtension,
      Value<int?> fileSize,
      Value<DateTime> indexedAt,
    });

final class $$MediaItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem> {
  $$MediaItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias('media_items__source_id__sources__id');

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cleanTitle => $composableBuilder(
    column: $table.cleanTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directUrl => $composableBuilder(
    column: $table.directUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ScrapeItemType, ScrapeItemType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episode => $composableBuilder(
    column: $table.episode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cleanTitle => $composableBuilder(
    column: $table.cleanTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directUrl => $composableBuilder(
    column: $table.directUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episode => $composableBuilder(
    column: $table.episode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawName =>
      $composableBuilder(column: $table.rawName, builder: (column) => column);

  GeneratedColumn<String> get cleanTitle => $composableBuilder(
    column: $table.cleanTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get directUrl =>
      $composableBuilder(column: $table.directUrl, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScrapeItemType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get episode =>
      $composableBuilder(column: $table.episode, builder: (column) => column);

  GeneratedColumn<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaItemsTable,
          MediaItem,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (MediaItem, $$MediaItemsTableReferences),
          MediaItem,
          PrefetchHooks Function({bool sourceId})
        > {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sourceId = const Value.absent(),
                Value<String> rawName = const Value.absent(),
                Value<String> cleanTitle = const Value.absent(),
                Value<String> groupTitle = const Value.absent(),
                Value<String> directUrl = const Value.absent(),
                Value<ScrapeItemType> type = const Value.absent(),
                Value<int?> season = const Value.absent(),
                Value<int?> episode = const Value.absent(),
                Value<String?> fileExtension = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                sourceId: sourceId,
                rawName: rawName,
                cleanTitle: cleanTitle,
                groupTitle: groupTitle,
                directUrl: directUrl,
                type: type,
                season: season,
                episode: episode,
                fileExtension: fileExtension,
                fileSize: fileSize,
                indexedAt: indexedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sourceId,
                required String rawName,
                required String cleanTitle,
                required String groupTitle,
                required String directUrl,
                required ScrapeItemType type,
                Value<int?> season = const Value.absent(),
                Value<int?> episode = const Value.absent(),
                Value<String?> fileExtension = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                id: id,
                sourceId: sourceId,
                rawName: rawName,
                cleanTitle: cleanTitle,
                groupTitle: groupTitle,
                directUrl: directUrl,
                type: type,
                season: season,
                episode: episode,
                fileExtension: fileExtension,
                fileSize: fileSize,
                indexedAt: indexedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$MediaItemsTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$MediaItemsTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaItemsTable,
      MediaItem,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (MediaItem, $$MediaItemsTableReferences),
      MediaItem,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$MediaShowsTableCreateCompanionBuilder =
    MediaShowsCompanion Function({
      Value<int> id,
      required String groupTitle,
      Value<String?> resolvedTitle,
      Value<String?> titleEn,
      Value<String?> mediaType,
      Value<String?> animeType,
      Value<int?> year,
      Value<int?> totalEpisodes,
      Value<String?> posterPath,
      Value<String?> fanartPath,
      Value<String?> overview,
      Value<double?> ratingSimkl,
      Value<double?> ratingMal,
      Value<double?> ratingImdb,
      Value<int?> simklId,
      Value<String?> simklSlug,
      Value<String?> imdbId,
      Value<String?> tmdbId,
      Value<int?> malId,
      Value<int?> anilistId,
      Value<int?> tvdbId,
      Value<String?> anidbId,
      Value<DateTime?> resolvedAt,
    });
typedef $$MediaShowsTableUpdateCompanionBuilder =
    MediaShowsCompanion Function({
      Value<int> id,
      Value<String> groupTitle,
      Value<String?> resolvedTitle,
      Value<String?> titleEn,
      Value<String?> mediaType,
      Value<String?> animeType,
      Value<int?> year,
      Value<int?> totalEpisodes,
      Value<String?> posterPath,
      Value<String?> fanartPath,
      Value<String?> overview,
      Value<double?> ratingSimkl,
      Value<double?> ratingMal,
      Value<double?> ratingImdb,
      Value<int?> simklId,
      Value<String?> simklSlug,
      Value<String?> imdbId,
      Value<String?> tmdbId,
      Value<int?> malId,
      Value<int?> anilistId,
      Value<int?> tvdbId,
      Value<String?> anidbId,
      Value<DateTime?> resolvedAt,
    });

class $$MediaShowsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaShowsTable> {
  $$MediaShowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvedTitle => $composableBuilder(
    column: $table.resolvedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get animeType => $composableBuilder(
    column: $table.animeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fanartPath => $composableBuilder(
    column: $table.fanartPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ratingSimkl => $composableBuilder(
    column: $table.ratingSimkl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ratingMal => $composableBuilder(
    column: $table.ratingMal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ratingImdb => $composableBuilder(
    column: $table.ratingImdb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get simklId => $composableBuilder(
    column: $table.simklId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get simklSlug => $composableBuilder(
    column: $table.simklSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get malId => $composableBuilder(
    column: $table.malId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anilistId => $composableBuilder(
    column: $table.anilistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anidbId => $composableBuilder(
    column: $table.anidbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaShowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaShowsTable> {
  $$MediaShowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedTitle => $composableBuilder(
    column: $table.resolvedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get animeType => $composableBuilder(
    column: $table.animeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fanartPath => $composableBuilder(
    column: $table.fanartPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ratingSimkl => $composableBuilder(
    column: $table.ratingSimkl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ratingMal => $composableBuilder(
    column: $table.ratingMal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ratingImdb => $composableBuilder(
    column: $table.ratingImdb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get simklId => $composableBuilder(
    column: $table.simklId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get simklSlug => $composableBuilder(
    column: $table.simklSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get malId => $composableBuilder(
    column: $table.malId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anilistId => $composableBuilder(
    column: $table.anilistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tvdbId => $composableBuilder(
    column: $table.tvdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anidbId => $composableBuilder(
    column: $table.anidbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaShowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaShowsTable> {
  $$MediaShowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolvedTitle => $composableBuilder(
    column: $table.resolvedTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titleEn =>
      $composableBuilder(column: $table.titleEn, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get animeType =>
      $composableBuilder(column: $table.animeType, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fanartPath => $composableBuilder(
    column: $table.fanartPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<double> get ratingSimkl => $composableBuilder(
    column: $table.ratingSimkl,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ratingMal =>
      $composableBuilder(column: $table.ratingMal, builder: (column) => column);

  GeneratedColumn<double> get ratingImdb => $composableBuilder(
    column: $table.ratingImdb,
    builder: (column) => column,
  );

  GeneratedColumn<int> get simklId =>
      $composableBuilder(column: $table.simklId, builder: (column) => column);

  GeneratedColumn<String> get simklSlug =>
      $composableBuilder(column: $table.simklSlug, builder: (column) => column);

  GeneratedColumn<String> get imdbId =>
      $composableBuilder(column: $table.imdbId, builder: (column) => column);

  GeneratedColumn<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<int> get malId =>
      $composableBuilder(column: $table.malId, builder: (column) => column);

  GeneratedColumn<int> get anilistId =>
      $composableBuilder(column: $table.anilistId, builder: (column) => column);

  GeneratedColumn<int> get tvdbId =>
      $composableBuilder(column: $table.tvdbId, builder: (column) => column);

  GeneratedColumn<String> get anidbId =>
      $composableBuilder(column: $table.anidbId, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$MediaShowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaShowsTable,
          MediaShow,
          $$MediaShowsTableFilterComposer,
          $$MediaShowsTableOrderingComposer,
          $$MediaShowsTableAnnotationComposer,
          $$MediaShowsTableCreateCompanionBuilder,
          $$MediaShowsTableUpdateCompanionBuilder,
          (
            MediaShow,
            BaseReferences<_$AppDatabase, $MediaShowsTable, MediaShow>,
          ),
          MediaShow,
          PrefetchHooks Function()
        > {
  $$MediaShowsTableTableManager(_$AppDatabase db, $MediaShowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaShowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaShowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaShowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> groupTitle = const Value.absent(),
                Value<String?> resolvedTitle = const Value.absent(),
                Value<String?> titleEn = const Value.absent(),
                Value<String?> mediaType = const Value.absent(),
                Value<String?> animeType = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int?> totalEpisodes = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> fanartPath = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<double?> ratingSimkl = const Value.absent(),
                Value<double?> ratingMal = const Value.absent(),
                Value<double?> ratingImdb = const Value.absent(),
                Value<int?> simklId = const Value.absent(),
                Value<String?> simklSlug = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                Value<String?> tmdbId = const Value.absent(),
                Value<int?> malId = const Value.absent(),
                Value<int?> anilistId = const Value.absent(),
                Value<int?> tvdbId = const Value.absent(),
                Value<String?> anidbId = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
              }) => MediaShowsCompanion(
                id: id,
                groupTitle: groupTitle,
                resolvedTitle: resolvedTitle,
                titleEn: titleEn,
                mediaType: mediaType,
                animeType: animeType,
                year: year,
                totalEpisodes: totalEpisodes,
                posterPath: posterPath,
                fanartPath: fanartPath,
                overview: overview,
                ratingSimkl: ratingSimkl,
                ratingMal: ratingMal,
                ratingImdb: ratingImdb,
                simklId: simklId,
                simklSlug: simklSlug,
                imdbId: imdbId,
                tmdbId: tmdbId,
                malId: malId,
                anilistId: anilistId,
                tvdbId: tvdbId,
                anidbId: anidbId,
                resolvedAt: resolvedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String groupTitle,
                Value<String?> resolvedTitle = const Value.absent(),
                Value<String?> titleEn = const Value.absent(),
                Value<String?> mediaType = const Value.absent(),
                Value<String?> animeType = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int?> totalEpisodes = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> fanartPath = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<double?> ratingSimkl = const Value.absent(),
                Value<double?> ratingMal = const Value.absent(),
                Value<double?> ratingImdb = const Value.absent(),
                Value<int?> simklId = const Value.absent(),
                Value<String?> simklSlug = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                Value<String?> tmdbId = const Value.absent(),
                Value<int?> malId = const Value.absent(),
                Value<int?> anilistId = const Value.absent(),
                Value<int?> tvdbId = const Value.absent(),
                Value<String?> anidbId = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
              }) => MediaShowsCompanion.insert(
                id: id,
                groupTitle: groupTitle,
                resolvedTitle: resolvedTitle,
                titleEn: titleEn,
                mediaType: mediaType,
                animeType: animeType,
                year: year,
                totalEpisodes: totalEpisodes,
                posterPath: posterPath,
                fanartPath: fanartPath,
                overview: overview,
                ratingSimkl: ratingSimkl,
                ratingMal: ratingMal,
                ratingImdb: ratingImdb,
                simklId: simklId,
                simklSlug: simklSlug,
                imdbId: imdbId,
                tmdbId: tmdbId,
                malId: malId,
                anilistId: anilistId,
                tvdbId: tvdbId,
                anidbId: anidbId,
                resolvedAt: resolvedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaShowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaShowsTable,
      MediaShow,
      $$MediaShowsTableFilterComposer,
      $$MediaShowsTableOrderingComposer,
      $$MediaShowsTableAnnotationComposer,
      $$MediaShowsTableCreateCompanionBuilder,
      $$MediaShowsTableUpdateCompanionBuilder,
      (MediaShow, BaseReferences<_$AppDatabase, $MediaShowsTable, MediaShow>),
      MediaShow,
      PrefetchHooks Function()
    >;
typedef $$IndexedFoldersTableCreateCompanionBuilder =
    IndexedFoldersCompanion Function({
      Value<int> id,
      required int sourceId,
      required String folderName,
      required String cleanTitle,
      required String folderUrl,
      Value<int?> year,
      Value<bool> isScraped,
      Value<DateTime?> lastScraped,
      Value<DateTime> indexedAt,
      Value<String?> scrapeErrors,
    });
typedef $$IndexedFoldersTableUpdateCompanionBuilder =
    IndexedFoldersCompanion Function({
      Value<int> id,
      Value<int> sourceId,
      Value<String> folderName,
      Value<String> cleanTitle,
      Value<String> folderUrl,
      Value<int?> year,
      Value<bool> isScraped,
      Value<DateTime?> lastScraped,
      Value<DateTime> indexedAt,
      Value<String?> scrapeErrors,
    });

final class $$IndexedFoldersTableReferences
    extends BaseReferences<_$AppDatabase, $IndexedFoldersTable, IndexedFolder> {
  $$IndexedFoldersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias('indexed_folders__source_id__sources__id');

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IndexedFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $IndexedFoldersTable> {
  $$IndexedFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderName => $composableBuilder(
    column: $table.folderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cleanTitle => $composableBuilder(
    column: $table.cleanTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderUrl => $composableBuilder(
    column: $table.folderUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isScraped => $composableBuilder(
    column: $table.isScraped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastScraped => $composableBuilder(
    column: $table.lastScraped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scrapeErrors => $composableBuilder(
    column: $table.scrapeErrors,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IndexedFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $IndexedFoldersTable> {
  $$IndexedFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderName => $composableBuilder(
    column: $table.folderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cleanTitle => $composableBuilder(
    column: $table.cleanTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderUrl => $composableBuilder(
    column: $table.folderUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isScraped => $composableBuilder(
    column: $table.isScraped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastScraped => $composableBuilder(
    column: $table.lastScraped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scrapeErrors => $composableBuilder(
    column: $table.scrapeErrors,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IndexedFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $IndexedFoldersTable> {
  $$IndexedFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get folderName => $composableBuilder(
    column: $table.folderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cleanTitle => $composableBuilder(
    column: $table.cleanTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderUrl =>
      $composableBuilder(column: $table.folderUrl, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<bool> get isScraped =>
      $composableBuilder(column: $table.isScraped, builder: (column) => column);

  GeneratedColumn<DateTime> get lastScraped => $composableBuilder(
    column: $table.lastScraped,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  GeneratedColumn<String> get scrapeErrors => $composableBuilder(
    column: $table.scrapeErrors,
    builder: (column) => column,
  );

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IndexedFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IndexedFoldersTable,
          IndexedFolder,
          $$IndexedFoldersTableFilterComposer,
          $$IndexedFoldersTableOrderingComposer,
          $$IndexedFoldersTableAnnotationComposer,
          $$IndexedFoldersTableCreateCompanionBuilder,
          $$IndexedFoldersTableUpdateCompanionBuilder,
          (IndexedFolder, $$IndexedFoldersTableReferences),
          IndexedFolder,
          PrefetchHooks Function({bool sourceId})
        > {
  $$IndexedFoldersTableTableManager(
    _$AppDatabase db,
    $IndexedFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndexedFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IndexedFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IndexedFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sourceId = const Value.absent(),
                Value<String> folderName = const Value.absent(),
                Value<String> cleanTitle = const Value.absent(),
                Value<String> folderUrl = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<bool> isScraped = const Value.absent(),
                Value<DateTime?> lastScraped = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
                Value<String?> scrapeErrors = const Value.absent(),
              }) => IndexedFoldersCompanion(
                id: id,
                sourceId: sourceId,
                folderName: folderName,
                cleanTitle: cleanTitle,
                folderUrl: folderUrl,
                year: year,
                isScraped: isScraped,
                lastScraped: lastScraped,
                indexedAt: indexedAt,
                scrapeErrors: scrapeErrors,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sourceId,
                required String folderName,
                required String cleanTitle,
                required String folderUrl,
                Value<int?> year = const Value.absent(),
                Value<bool> isScraped = const Value.absent(),
                Value<DateTime?> lastScraped = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
                Value<String?> scrapeErrors = const Value.absent(),
              }) => IndexedFoldersCompanion.insert(
                id: id,
                sourceId: sourceId,
                folderName: folderName,
                cleanTitle: cleanTitle,
                folderUrl: folderUrl,
                year: year,
                isScraped: isScraped,
                lastScraped: lastScraped,
                indexedAt: indexedAt,
                scrapeErrors: scrapeErrors,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IndexedFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$IndexedFoldersTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn:
                                    $$IndexedFoldersTableReferences
                                        ._sourceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IndexedFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IndexedFoldersTable,
      IndexedFolder,
      $$IndexedFoldersTableFilterComposer,
      $$IndexedFoldersTableOrderingComposer,
      $$IndexedFoldersTableAnnotationComposer,
      $$IndexedFoldersTableCreateCompanionBuilder,
      $$IndexedFoldersTableUpdateCompanionBuilder,
      (IndexedFolder, $$IndexedFoldersTableReferences),
      IndexedFolder,
      PrefetchHooks Function({bool sourceId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$MediaShowsTableTableManager get mediaShows =>
      $$MediaShowsTableTableManager(_db, _db.mediaShows);
  $$IndexedFoldersTableTableManager get indexedFolders =>
      $$IndexedFoldersTableTableManager(_db, _db.indexedFolders);
}
