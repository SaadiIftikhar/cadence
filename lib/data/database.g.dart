// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('alarm'),
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8),
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _daysMaskMeta = const VerificationMeta(
    'daysMask',
  );
  @override
  late final GeneratedColumn<int> daysMask = GeneratedColumn<int>(
    'days_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _alarmEnabledMeta = const VerificationMeta(
    'alarmEnabled',
  );
  @override
  late final GeneratedColumn<bool> alarmEnabled = GeneratedColumn<bool>(
    'alarm_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("alarm_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _multiStepMeta = const VerificationMeta(
    'multiStep',
  );
  @override
  late final GeneratedColumn<bool> multiStep = GeneratedColumn<bool>(
    'multi_step',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("multi_step" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    iconKey,
    hour,
    minute,
    daysMask,
    notificationsEnabled,
    alarmEnabled,
    multiStep,
    enabled,
    imagePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    }
    if (data.containsKey('days_mask')) {
      context.handle(
        _daysMaskMeta,
        daysMask.isAcceptableOrUnknown(data['days_mask']!, _daysMaskMeta),
      );
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('alarm_enabled')) {
      context.handle(
        _alarmEnabledMeta,
        alarmEnabled.isAcceptableOrUnknown(
          data['alarm_enabled']!,
          _alarmEnabledMeta,
        ),
      );
    }
    if (data.containsKey('multi_step')) {
      context.handle(
        _multiStepMeta,
        multiStep.isAcceptableOrUnknown(data['multi_step']!, _multiStepMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      daysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_mask'],
      )!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      alarmEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}alarm_enabled'],
      )!,
      multiStep: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}multi_step'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final String title;
  final String iconKey;
  final int hour;
  final int minute;

  /// Bit 0 = Monday … bit 6 = Sunday. Zero means "no repeat".
  final int daysMask;
  final bool notificationsEnabled;
  final bool alarmEnabled;
  final bool multiStep;
  final bool enabled;
  final String? imagePath;
  final DateTime createdAt;
  const Reminder({
    required this.id,
    required this.title,
    required this.iconKey,
    required this.hour,
    required this.minute,
    required this.daysMask,
    required this.notificationsEnabled,
    required this.alarmEnabled,
    required this.multiStep,
    required this.enabled,
    this.imagePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['icon_key'] = Variable<String>(iconKey);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['days_mask'] = Variable<int>(daysMask);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['alarm_enabled'] = Variable<bool>(alarmEnabled);
    map['multi_step'] = Variable<bool>(multiStep);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      iconKey: Value(iconKey),
      hour: Value(hour),
      minute: Value(minute),
      daysMask: Value(daysMask),
      notificationsEnabled: Value(notificationsEnabled),
      alarmEnabled: Value(alarmEnabled),
      multiStep: Value(multiStep),
      enabled: Value(enabled),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      createdAt: Value(createdAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      daysMask: serializer.fromJson<int>(json['daysMask']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      alarmEnabled: serializer.fromJson<bool>(json['alarmEnabled']),
      multiStep: serializer.fromJson<bool>(json['multiStep']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'iconKey': serializer.toJson<String>(iconKey),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'daysMask': serializer.toJson<int>(daysMask),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'alarmEnabled': serializer.toJson<bool>(alarmEnabled),
      'multiStep': serializer.toJson<bool>(multiStep),
      'enabled': serializer.toJson<bool>(enabled),
      'imagePath': serializer.toJson<String?>(imagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? iconKey,
    int? hour,
    int? minute,
    int? daysMask,
    bool? notificationsEnabled,
    bool? alarmEnabled,
    bool? multiStep,
    bool? enabled,
    Value<String?> imagePath = const Value.absent(),
    DateTime? createdAt,
  }) => Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    iconKey: iconKey ?? this.iconKey,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    daysMask: daysMask ?? this.daysMask,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    multiStep: multiStep ?? this.multiStep,
    enabled: enabled ?? this.enabled,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    createdAt: createdAt ?? this.createdAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      daysMask: data.daysMask.present ? data.daysMask.value : this.daysMask,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      alarmEnabled: data.alarmEnabled.present
          ? data.alarmEnabled.value
          : this.alarmEnabled,
      multiStep: data.multiStep.present ? data.multiStep.value : this.multiStep,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconKey: $iconKey, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('daysMask: $daysMask, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('alarmEnabled: $alarmEnabled, ')
          ..write('multiStep: $multiStep, ')
          ..write('enabled: $enabled, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    iconKey,
    hour,
    minute,
    daysMask,
    notificationsEnabled,
    alarmEnabled,
    multiStep,
    enabled,
    imagePath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.title == this.title &&
          other.iconKey == this.iconKey &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.daysMask == this.daysMask &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.alarmEnabled == this.alarmEnabled &&
          other.multiStep == this.multiStep &&
          other.enabled == this.enabled &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> iconKey;
  final Value<int> hour;
  final Value<int> minute;
  final Value<int> daysMask;
  final Value<bool> notificationsEnabled;
  final Value<bool> alarmEnabled;
  final Value<bool> multiStep;
  final Value<bool> enabled;
  final Value<String?> imagePath;
  final Value<DateTime> createdAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.alarmEnabled = const Value.absent(),
    this.multiStep = const Value.absent(),
    this.enabled = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.alarmEnabled = const Value.absent(),
    this.multiStep = const Value.absent(),
    this.enabled = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? iconKey,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? daysMask,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? alarmEnabled,
    Expression<bool>? multiStep,
    Expression<bool>? enabled,
    Expression<String>? imagePath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (iconKey != null) 'icon_key': iconKey,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (daysMask != null) 'days_mask': daysMask,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (alarmEnabled != null) 'alarm_enabled': alarmEnabled,
      if (multiStep != null) 'multi_step': multiStep,
      if (enabled != null) 'enabled': enabled,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? iconKey,
    Value<int>? hour,
    Value<int>? minute,
    Value<int>? daysMask,
    Value<bool>? notificationsEnabled,
    Value<bool>? alarmEnabled,
    Value<bool>? multiStep,
    Value<bool>? enabled,
    Value<String?>? imagePath,
    Value<DateTime>? createdAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysMask: daysMask ?? this.daysMask,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      multiStep: multiStep ?? this.multiStep,
      enabled: enabled ?? this.enabled,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (daysMask.present) {
      map['days_mask'] = Variable<int>(daysMask.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (alarmEnabled.present) {
      map['alarm_enabled'] = Variable<bool>(alarmEnabled.value);
    }
    if (multiStep.present) {
      map['multi_step'] = Variable<bool>(multiStep.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconKey: $iconKey, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('daysMask: $daysMask, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('alarmEnabled: $alarmEnabled, ')
          ..write('multiStep: $multiStep, ')
          ..write('enabled: $enabled, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReminderStepsTable extends ReminderSteps
    with TableInfo<$ReminderStepsTable, ReminderStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderStepsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<int> reminderId = GeneratedColumn<int>(
    'reminder_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reminders (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timerSecondsMeta = const VerificationMeta(
    'timerSeconds',
  );
  @override
  late final GeneratedColumn<int> timerSeconds = GeneratedColumn<int>(
    'timer_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reminderId,
    title,
    iconKey,
    timerSeconds,
    position,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('timer_seconds')) {
      context.handle(
        _timerSecondsMeta,
        timerSeconds.isAcceptableOrUnknown(
          data['timer_seconds']!,
          _timerSecondsMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderStep(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      ),
      timerSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timer_seconds'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $ReminderStepsTable createAlias(String alias) {
    return $ReminderStepsTable(attachedDatabase, alias);
  }
}

class ReminderStep extends DataClass implements Insertable<ReminderStep> {
  final int id;
  final int reminderId;
  final String title;
  final String? iconKey;

  /// Null means the step has no timer.
  final int? timerSeconds;
  final int position;

  /// Survives leaving and re-entering a routine. Only an explicit Reset
  /// clears it.
  final bool completed;
  const ReminderStep({
    required this.id,
    required this.reminderId,
    required this.title,
    this.iconKey,
    this.timerSeconds,
    required this.position,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reminder_id'] = Variable<int>(reminderId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    if (!nullToAbsent || timerSeconds != null) {
      map['timer_seconds'] = Variable<int>(timerSeconds);
    }
    map['position'] = Variable<int>(position);
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  ReminderStepsCompanion toCompanion(bool nullToAbsent) {
    return ReminderStepsCompanion(
      id: Value(id),
      reminderId: Value(reminderId),
      title: Value(title),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      timerSeconds: timerSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(timerSeconds),
      position: Value(position),
      completed: Value(completed),
    );
  }

  factory ReminderStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderStep(
      id: serializer.fromJson<int>(json['id']),
      reminderId: serializer.fromJson<int>(json['reminderId']),
      title: serializer.fromJson<String>(json['title']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      timerSeconds: serializer.fromJson<int?>(json['timerSeconds']),
      position: serializer.fromJson<int>(json['position']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reminderId': serializer.toJson<int>(reminderId),
      'title': serializer.toJson<String>(title),
      'iconKey': serializer.toJson<String?>(iconKey),
      'timerSeconds': serializer.toJson<int?>(timerSeconds),
      'position': serializer.toJson<int>(position),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  ReminderStep copyWith({
    int? id,
    int? reminderId,
    String? title,
    Value<String?> iconKey = const Value.absent(),
    Value<int?> timerSeconds = const Value.absent(),
    int? position,
    bool? completed,
  }) => ReminderStep(
    id: id ?? this.id,
    reminderId: reminderId ?? this.reminderId,
    title: title ?? this.title,
    iconKey: iconKey.present ? iconKey.value : this.iconKey,
    timerSeconds: timerSeconds.present ? timerSeconds.value : this.timerSeconds,
    position: position ?? this.position,
    completed: completed ?? this.completed,
  );
  ReminderStep copyWithCompanion(ReminderStepsCompanion data) {
    return ReminderStep(
      id: data.id.present ? data.id.value : this.id,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      title: data.title.present ? data.title.value : this.title,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      timerSeconds: data.timerSeconds.present
          ? data.timerSeconds.value
          : this.timerSeconds,
      position: data.position.present ? data.position.value : this.position,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderStep(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('title: $title, ')
          ..write('iconKey: $iconKey, ')
          ..write('timerSeconds: $timerSeconds, ')
          ..write('position: $position, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reminderId,
    title,
    iconKey,
    timerSeconds,
    position,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderStep &&
          other.id == this.id &&
          other.reminderId == this.reminderId &&
          other.title == this.title &&
          other.iconKey == this.iconKey &&
          other.timerSeconds == this.timerSeconds &&
          other.position == this.position &&
          other.completed == this.completed);
}

class ReminderStepsCompanion extends UpdateCompanion<ReminderStep> {
  final Value<int> id;
  final Value<int> reminderId;
  final Value<String> title;
  final Value<String?> iconKey;
  final Value<int?> timerSeconds;
  final Value<int> position;
  final Value<bool> completed;
  const ReminderStepsCompanion({
    this.id = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.title = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.timerSeconds = const Value.absent(),
    this.position = const Value.absent(),
    this.completed = const Value.absent(),
  });
  ReminderStepsCompanion.insert({
    this.id = const Value.absent(),
    required int reminderId,
    this.title = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.timerSeconds = const Value.absent(),
    this.position = const Value.absent(),
    this.completed = const Value.absent(),
  }) : reminderId = Value(reminderId);
  static Insertable<ReminderStep> custom({
    Expression<int>? id,
    Expression<int>? reminderId,
    Expression<String>? title,
    Expression<String>? iconKey,
    Expression<int>? timerSeconds,
    Expression<int>? position,
    Expression<bool>? completed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reminderId != null) 'reminder_id': reminderId,
      if (title != null) 'title': title,
      if (iconKey != null) 'icon_key': iconKey,
      if (timerSeconds != null) 'timer_seconds': timerSeconds,
      if (position != null) 'position': position,
      if (completed != null) 'completed': completed,
    });
  }

  ReminderStepsCompanion copyWith({
    Value<int>? id,
    Value<int>? reminderId,
    Value<String>? title,
    Value<String?>? iconKey,
    Value<int?>? timerSeconds,
    Value<int>? position,
    Value<bool>? completed,
  }) {
    return ReminderStepsCompanion(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      position: position ?? this.position,
      completed: completed ?? this.completed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<int>(reminderId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (timerSeconds.present) {
      map['timer_seconds'] = Variable<int>(timerSeconds.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderStepsCompanion(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('title: $title, ')
          ..write('iconKey: $iconKey, ')
          ..write('timerSeconds: $timerSeconds, ')
          ..write('position: $position, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $ReminderStepsTable reminderSteps = $ReminderStepsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reminders,
    reminderSteps,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'reminders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminder_steps', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> iconKey,
  Value<int> hour,
  Value<int> minute,
  Value<int> daysMask,
  Value<bool> notificationsEnabled,
  Value<bool> alarmEnabled,
  Value<bool> multiStep,
  Value<bool> enabled,
  Value<String?> imagePath,
  Value<DateTime> createdAt,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> iconKey,
  Value<int> hour,
  Value<int> minute,
  Value<int> daysMask,
  Value<bool> notificationsEnabled,
  Value<bool> alarmEnabled,
  Value<bool> multiStep,
  Value<bool> enabled,
  Value<String?> imagePath,
  Value<DateTime> createdAt,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReminderStepsTable, List<ReminderStep>>
  _reminderStepsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminderSteps,
    aliasName: 'reminders__id__reminder_steps__reminder_id',
  );

  $$ReminderStepsTableProcessedTableManager get reminderStepsRefs {
    final manager = $$ReminderStepsTableTableManager(
      $_db,
      $_db.reminderSteps,
    ).filter((f) => f.reminderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reminderStepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysMask => $composableBuilder(
    column: $table.daysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alarmEnabled => $composableBuilder(
    column: $table.alarmEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get multiStep => $composableBuilder(
    column: $table.multiStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reminderStepsRefs(
    Expression<bool> Function($$ReminderStepsTableFilterComposer f) f,
  ) {
    final $$ReminderStepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderSteps,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderStepsTableFilterComposer(
            $db: $db,
            $table: $db.reminderSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysMask => $composableBuilder(
    column: $table.daysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alarmEnabled => $composableBuilder(
    column: $table.alarmEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get multiStep => $composableBuilder(
    column: $table.multiStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<int> get daysMask =>
      $composableBuilder(column: $table.daysMask, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get alarmEnabled => $composableBuilder(
    column: $table.alarmEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get multiStep =>
      $composableBuilder(column: $table.multiStep, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> reminderStepsRefs<T extends Object>(
    Expression<T> Function($$ReminderStepsTableAnnotationComposer a) f,
  ) {
    final $$ReminderStepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderSteps,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderStepsTableAnnotationComposer(
            $db: $db,
            $table: $db.reminderSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool reminderStepsRefs})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> hour = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> alarmEnabled = const Value.absent(),
                Value<bool> multiStep = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                title: title,
                iconKey: iconKey,
                hour: hour,
                minute: minute,
                daysMask: daysMask,
                notificationsEnabled: notificationsEnabled,
                alarmEnabled: alarmEnabled,
                multiStep: multiStep,
                enabled: enabled,
                imagePath: imagePath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> hour = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> alarmEnabled = const Value.absent(),
                Value<bool> multiStep = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                title: title,
                iconKey: iconKey,
                hour: hour,
                minute: minute,
                daysMask: daysMask,
                notificationsEnabled: notificationsEnabled,
                alarmEnabled: alarmEnabled,
                multiStep: multiStep,
                enabled: enabled,
                imagePath: imagePath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, Reminder>(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reminderStepsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (reminderStepsRefs) db.reminderSteps,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reminderStepsRefs)
                    await $_getPrefetchedData<
                      Reminder,
                      $RemindersTable,
                      ReminderStep
                    >(
                      currentTable: table,
                      referencedTable: $$RemindersTableReferences
                          ._reminderStepsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RemindersTableReferences(
                            db,
                            table,
                            p0,
                          ).reminderStepsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.reminderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool reminderStepsRefs})
    >;
typedef $$ReminderStepsTableCreateCompanionBuilder =
    ReminderStepsCompanion Function({
      Value<int> id,
      required int reminderId,
      Value<String> title,
      Value<String?> iconKey,
      Value<int?> timerSeconds,
      Value<int> position,
      Value<bool> completed,
    });
typedef $$ReminderStepsTableUpdateCompanionBuilder =
    ReminderStepsCompanion Function({
      Value<int> id,
      Value<int> reminderId,
      Value<String> title,
      Value<String?> iconKey,
      Value<int?> timerSeconds,
      Value<int> position,
      Value<bool> completed,
    });

final class $$ReminderStepsTableReferences
    extends BaseReferences<_$AppDatabase, $ReminderStepsTable, ReminderStep> {
  $$ReminderStepsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RemindersTable _reminderIdTable(_$AppDatabase db) =>
      db.reminders.createAlias('reminder_steps__reminder_id__reminders__id');

  $$RemindersTableProcessedTableManager get reminderId {
    final $_column = $_itemColumn<int>('reminder_id')!;

    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reminderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReminderStepsTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderStepsTable> {
  $$ReminderStepsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timerSeconds => $composableBuilder(
    column: $table.timerSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  $$RemindersTableFilterComposer get reminderId {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReminderStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderStepsTable> {
  $$ReminderStepsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timerSeconds => $composableBuilder(
    column: $table.timerSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  $$RemindersTableOrderingComposer get reminderId {
    final $$RemindersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableOrderingComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReminderStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderStepsTable> {
  $$ReminderStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get timerSeconds => $composableBuilder(
    column: $table.timerSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  $$RemindersTableAnnotationComposer get reminderId {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReminderStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReminderStepsTable,
          ReminderStep,
          $$ReminderStepsTableFilterComposer,
          $$ReminderStepsTableOrderingComposer,
          $$ReminderStepsTableAnnotationComposer,
          $$ReminderStepsTableCreateCompanionBuilder,
          $$ReminderStepsTableUpdateCompanionBuilder,
          (ReminderStep, $$ReminderStepsTableReferences),
          ReminderStep,
          PrefetchHooks Function({bool reminderId})
        > {
  $$ReminderStepsTableTableManager(_$AppDatabase db, $ReminderStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> reminderId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<int?> timerSeconds = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => ReminderStepsCompanion(
                id: id,
                reminderId: reminderId,
                title: title,
                iconKey: iconKey,
                timerSeconds: timerSeconds,
                position: position,
                completed: completed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int reminderId,
                Value<String> title = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<int?> timerSeconds = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => ReminderStepsCompanion.insert(
                id: id,
                reminderId: reminderId,
                title: title,
                iconKey: iconKey,
                timerSeconds: timerSeconds,
                position: position,
                completed: completed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderStepsTable, ReminderStep>(table),
                  $$ReminderStepsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reminderId = false}) {
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
                    if (reminderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.reminderId,
                        referencedTable: $$ReminderStepsTableReferences
                            ._reminderIdTable(db),
                        referencedColumn: $$ReminderStepsTableReferences
                            ._reminderIdTable(db)
                            .id,
                      ) as T;
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

typedef $$ReminderStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReminderStepsTable,
      ReminderStep,
      $$ReminderStepsTableFilterComposer,
      $$ReminderStepsTableOrderingComposer,
      $$ReminderStepsTableAnnotationComposer,
      $$ReminderStepsTableCreateCompanionBuilder,
      $$ReminderStepsTableUpdateCompanionBuilder,
      (ReminderStep, $$ReminderStepsTableReferences),
      ReminderStep,
      PrefetchHooks Function({bool reminderId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$ReminderStepsTableTableManager get reminderSteps =>
      $$ReminderStepsTableTableManager(_db, _db.reminderSteps);
}
