// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, DateTime> dueAt =
      GeneratedColumn<DateTime>(
        'due_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($TasksTable.$converterdueAtn);
  static const VerificationMeta _dueHasTimeMeta = const VerificationMeta(
    'dueHasTime',
  );
  @override
  late final GeneratedColumn<bool> dueHasTime = GeneratedColumn<bool>(
    'due_has_time',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("due_has_time" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Priority, int> priority =
      GeneratedColumn<int>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(Priority.medium.index),
      ).withConverter<Priority>($TasksTable.$converterpriority);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, DateTime> reminderAt =
      GeneratedColumn<DateTime>(
        'reminder_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($TasksTable.$converterreminderAtn);
  @override
  late final GeneratedColumnWithTypeConverter<RepeatRule, int> reminderRepeat =
      GeneratedColumn<int>(
        'reminder_repeat',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(RepeatRule.none.index),
      ).withConverter<RepeatRule>($TasksTable.$converterreminderRepeat);
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    note,
    dueAt,
    dueHasTime,
    priority,
    reminderAt,
    reminderRepeat,
    completedAt,
    snoozedUntil,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
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
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('due_has_time')) {
      context.handle(
        _dueHasTimeMeta,
        dueHasTime.isAcceptableOrUnknown(
          data['due_has_time']!,
          _dueHasTimeMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      dueAt: $TasksTable.$converterdueAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}due_at'],
        ),
      ),
      dueHasTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}due_has_time'],
      )!,
      priority: $TasksTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}priority'],
        )!,
      ),
      reminderAt: $TasksTable.$converterreminderAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}reminder_at'],
        ),
      ),
      reminderRepeat: $TasksTable.$converterreminderRepeat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}reminder_repeat'],
        )!,
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterdueAt =
      const WallTimeConverter();
  static TypeConverter<DateTime?, DateTime?> $converterdueAtn =
      NullAwareTypeConverter.wrap($converterdueAt);
  static JsonTypeConverter2<Priority, int, int> $converterpriority =
      const EnumIndexConverter<Priority>(Priority.values);
  static TypeConverter<DateTime, DateTime> $converterreminderAt =
      const WallTimeConverter();
  static TypeConverter<DateTime?, DateTime?> $converterreminderAtn =
      NullAwareTypeConverter.wrap($converterreminderAt);
  static JsonTypeConverter2<RepeatRule, int, int> $converterreminderRepeat =
      const EnumIndexConverter<RepeatRule>(RepeatRule.values);
}

class Task extends DataClass implements Insertable<Task> {
  /// AUTOINCREMENT：删除的 id 不会复用，通知 id 直接取自它
  final int id;
  final String title;
  final String? note;

  /// 当地钟点。dueHasTime = false 时只看日期部分
  final DateTime? dueAt;
  final bool dueHasTime;
  final Priority priority;

  /// 当地钟点。不重复时是触发时刻；每天取时分；每周取星期几 + 时分
  final DateTime? reminderAt;
  final RepeatRule reminderRepeat;

  /// 完成的时刻。重复任务只在它落在今天时算"今天已完成"
  final DateTime? completedAt;

  /// "稍后提醒"的再次响铃时刻（v3）。全量重建提醒时据此恢复，不会丢
  final DateTime? snoozedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Task({
    required this.id,
    required this.title,
    this.note,
    this.dueAt,
    required this.dueHasTime,
    required this.priority,
    this.reminderAt,
    required this.reminderRepeat,
    this.completedAt,
    this.snoozedUntil,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(
        $TasksTable.$converterdueAtn.toSql(dueAt),
      );
    }
    map['due_has_time'] = Variable<bool>(dueHasTime);
    {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority),
      );
    }
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<DateTime>(
        $TasksTable.$converterreminderAtn.toSql(reminderAt),
      );
    }
    {
      map['reminder_repeat'] = Variable<int>(
        $TasksTable.$converterreminderRepeat.toSql(reminderRepeat),
      );
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      dueHasTime: Value(dueHasTime),
      priority: Value(priority),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      reminderRepeat: Value(reminderRepeat),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      dueHasTime: serializer.fromJson<bool>(json['dueHasTime']),
      priority: $TasksTable.$converterpriority.fromJson(
        serializer.fromJson<int>(json['priority']),
      ),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      reminderRepeat: $TasksTable.$converterreminderRepeat.fromJson(
        serializer.fromJson<int>(json['reminderRepeat']),
      ),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'dueHasTime': serializer.toJson<bool>(dueHasTime),
      'priority': serializer.toJson<int>(
        $TasksTable.$converterpriority.toJson(priority),
      ),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'reminderRepeat': serializer.toJson<int>(
        $TasksTable.$converterreminderRepeat.toJson(reminderRepeat),
      ),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    Value<String?> note = const Value.absent(),
    Value<DateTime?> dueAt = const Value.absent(),
    bool? dueHasTime,
    Priority? priority,
    Value<DateTime?> reminderAt = const Value.absent(),
    RepeatRule? reminderRepeat,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> snoozedUntil = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    dueHasTime: dueHasTime ?? this.dueHasTime,
    priority: priority ?? this.priority,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    reminderRepeat: reminderRepeat ?? this.reminderRepeat,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      dueHasTime: data.dueHasTime.present
          ? data.dueHasTime.value
          : this.dueHasTime,
      priority: data.priority.present ? data.priority.value : this.priority,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      reminderRepeat: data.reminderRepeat.present
          ? data.reminderRepeat.value
          : this.reminderRepeat,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('dueAt: $dueAt, ')
          ..write('dueHasTime: $dueHasTime, ')
          ..write('priority: $priority, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('reminderRepeat: $reminderRepeat, ')
          ..write('completedAt: $completedAt, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    note,
    dueAt,
    dueHasTime,
    priority,
    reminderAt,
    reminderRepeat,
    completedAt,
    snoozedUntil,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.dueAt == this.dueAt &&
          other.dueHasTime == this.dueHasTime &&
          other.priority == this.priority &&
          other.reminderAt == this.reminderAt &&
          other.reminderRepeat == this.reminderRepeat &&
          other.completedAt == this.completedAt &&
          other.snoozedUntil == this.snoozedUntil &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> note;
  final Value<DateTime?> dueAt;
  final Value<bool> dueHasTime;
  final Value<Priority> priority;
  final Value<DateTime?> reminderAt;
  final Value<RepeatRule> reminderRepeat;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> snoozedUntil;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.dueHasTime = const Value.absent(),
    this.priority = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.reminderRepeat = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.dueHasTime = const Value.absent(),
    this.priority = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.reminderRepeat = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<DateTime>? dueAt,
    Expression<bool>? dueHasTime,
    Expression<int>? priority,
    Expression<DateTime>? reminderAt,
    Expression<int>? reminderRepeat,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? snoozedUntil,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (dueAt != null) 'due_at': dueAt,
      if (dueHasTime != null) 'due_has_time': dueHasTime,
      if (priority != null) 'priority': priority,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (reminderRepeat != null) 'reminder_repeat': reminderRepeat,
      if (completedAt != null) 'completed_at': completedAt,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? note,
    Value<DateTime?>? dueAt,
    Value<bool>? dueHasTime,
    Value<Priority>? priority,
    Value<DateTime?>? reminderAt,
    Value<RepeatRule>? reminderRepeat,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? snoozedUntil,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      dueAt: dueAt ?? this.dueAt,
      dueHasTime: dueHasTime ?? this.dueHasTime,
      priority: priority ?? this.priority,
      reminderAt: reminderAt ?? this.reminderAt,
      reminderRepeat: reminderRepeat ?? this.reminderRepeat,
      completedAt: completedAt ?? this.completedAt,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(
        $TasksTable.$converterdueAtn.toSql(dueAt.value),
      );
    }
    if (dueHasTime.present) {
      map['due_has_time'] = Variable<bool>(dueHasTime.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority.value),
      );
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<DateTime>(
        $TasksTable.$converterreminderAtn.toSql(reminderAt.value),
      );
    }
    if (reminderRepeat.present) {
      map['reminder_repeat'] = Variable<int>(
        $TasksTable.$converterreminderRepeat.toSql(reminderRepeat.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('dueAt: $dueAt, ')
          ..write('dueHasTime: $dueHasTime, ')
          ..write('priority: $priority, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('reminderRepeat: $reminderRepeat, ')
          ..write('completedAt: $completedAt, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LogEntriesTable extends LogEntries
    with TableInfo<$LogEntriesTable, LogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LogEntriesTable createAlias(String alias) {
    return $LogEntriesTable(attachedDatabase, alias);
  }
}

class LogEntry extends DataClass implements Insertable<LogEntry> {
  final int id;
  final String content;
  final DateTime createdAt;
  const LogEntry({
    required this.id,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: Value(id),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory LogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogEntry(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LogEntry copyWith({int? id, String? content, DateTime? createdAt}) =>
      LogEntry(
        id: id ?? this.id,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  LogEntry copyWithCompanion(LogEntriesCompanion data) {
    return LogEntry(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogEntry(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogEntry &&
          other.id == this.id &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class LogEntriesCompanion extends UpdateCompanion<LogEntry> {
  final Value<int> id;
  final Value<String> content;
  final Value<DateTime> createdAt;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required DateTime createdAt,
  }) : content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<LogEntry> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LogEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<DateTime>? createdAt,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingEntriesTable extends SettingEntries
    with TableInfo<$SettingEntriesTable, SettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingEntriesTable createAlias(String alias) {
    return $SettingEntriesTable(attachedDatabase, alias);
  }
}

class SettingEntry extends DataClass implements Insertable<SettingEntry> {
  final String key;
  final String value;
  const SettingEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory SettingEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingEntry copyWith({String? key, String? value}) =>
      SettingEntry(key: key ?? this.key, value: value ?? this.value);
  SettingEntry copyWithCompanion(SettingEntriesCompanion data) {
    return SettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingEntriesCompanion extends UpdateCompanion<SettingEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRemindersTable extends TaskReminders
    with TableInfo<$TaskRemindersTable, TaskReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRemindersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(ReminderKind.notification.index),
      ).withConverter<ReminderKind>($TaskRemindersTable.$converterkind);
  @override
  List<GeneratedColumn> get $columns => [id, taskId, offsetMinutes, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offsetMinutesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {taskId, offsetMinutes},
  ];
  @override
  TaskReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskReminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      )!,
      kind: $TaskRemindersTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
    );
  }

  @override
  $TaskRemindersTable createAlias(String alias) {
    return $TaskRemindersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReminderKind, int, int> $converterkind =
      const EnumIndexConverter<ReminderKind>(ReminderKind.values);
}

class TaskReminder extends DataClass implements Insertable<TaskReminder> {
  final int id;
  final int taskId;

  /// 提前多少分钟（0 = 准时）
  final int offsetMinutes;
  final ReminderKind kind;
  const TaskReminder({
    required this.id,
    required this.taskId,
    required this.offsetMinutes,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    {
      map['kind'] = Variable<int>(
        $TaskRemindersTable.$converterkind.toSql(kind),
      );
    }
    return map;
  }

  TaskRemindersCompanion toCompanion(bool nullToAbsent) {
    return TaskRemindersCompanion(
      id: Value(id),
      taskId: Value(taskId),
      offsetMinutes: Value(offsetMinutes),
      kind: Value(kind),
    );
  }

  factory TaskReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskReminder(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
      kind: $TaskRemindersTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
      'kind': serializer.toJson<int>(
        $TaskRemindersTable.$converterkind.toJson(kind),
      ),
    };
  }

  TaskReminder copyWith({
    int? id,
    int? taskId,
    int? offsetMinutes,
    ReminderKind? kind,
  }) => TaskReminder(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    kind: kind ?? this.kind,
  );
  TaskReminder copyWithCompanion(TaskRemindersCompanion data) {
    return TaskReminder(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskReminder(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, offsetMinutes, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskReminder &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.offsetMinutes == this.offsetMinutes &&
          other.kind == this.kind);
}

class TaskRemindersCompanion extends UpdateCompanion<TaskReminder> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<int> offsetMinutes;
  final Value<ReminderKind> kind;
  const TaskRemindersCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.kind = const Value.absent(),
  });
  TaskRemindersCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required int offsetMinutes,
    this.kind = const Value.absent(),
  }) : taskId = Value(taskId),
       offsetMinutes = Value(offsetMinutes);
  static Insertable<TaskReminder> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<int>? offsetMinutes,
    Expression<int>? kind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (kind != null) 'kind': kind,
    });
  }

  TaskRemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<int>? offsetMinutes,
    Value<ReminderKind>? kind,
  }) {
    return TaskRemindersCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      kind: kind ?? this.kind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $TaskRemindersTable.$converterkind.toSql(kind.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRemindersCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $LogEntriesTable logEntries = $LogEntriesTable(this);
  late final $SettingEntriesTable settingEntries = $SettingEntriesTable(this);
  late final $TaskRemindersTable taskReminders = $TaskRemindersTable(this);
  late final Index idxTasksDue = Index(
    'idx_tasks_due',
    'CREATE INDEX idx_tasks_due ON tasks (due_at)',
  );
  late final Index idxTasksReminder = Index(
    'idx_tasks_reminder',
    'CREATE INDEX idx_tasks_reminder ON tasks (reminder_at)',
  );
  late final Index idxLogCreated = Index(
    'idx_log_created',
    'CREATE INDEX idx_log_created ON log_entries (created_at)',
  );
  late final Index idxTaskRemindersTask = Index(
    'idx_task_reminders_task',
    'CREATE INDEX idx_task_reminders_task ON task_reminders (task_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    logEntries,
    settingEntries,
    taskReminders,
    idxTasksDue,
    idxTasksReminder,
    idxLogCreated,
    idxTaskRemindersTask,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_reminders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> note,
  Value<DateTime?> dueAt,
  Value<bool> dueHasTime,
  Value<Priority> priority,
  Value<DateTime?> reminderAt,
  Value<RepeatRule> reminderRepeat,
  Value<DateTime?> completedAt,
  Value<DateTime?> snoozedUntil,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> note,
  Value<DateTime?> dueAt,
  Value<bool> dueHasTime,
  Value<Priority> priority,
  Value<DateTime?> reminderAt,
  Value<RepeatRule> reminderRepeat,
  Value<DateTime?> completedAt,
  Value<DateTime?> snoozedUntil,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskRemindersTable, List<TaskReminder>>
  _taskRemindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskReminders,
    aliasName: 'tasks__id__task_reminders__task_id',
  );

  $$TaskRemindersTableProcessedTableManager get taskRemindersRefs {
    final manager = $$TaskRemindersTableTableManager(
      $_db,
      $_db.taskReminders,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskRemindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, DateTime> get dueAt =>
      $composableBuilder(
        column: $table.dueAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get dueHasTime => $composableBuilder(
    column: $table.dueHasTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Priority, Priority, int> get priority =>
      $composableBuilder(
        column: $table.priority,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, DateTime>
  get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<RepeatRule, RepeatRule, int>
  get reminderRepeat => $composableBuilder(
    column: $table.reminderRepeat,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskRemindersRefs(
    Expression<bool> Function($$TaskRemindersTableFilterComposer f) f,
  ) {
    final $$TaskRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRemindersTableFilterComposer(
            $db: $db,
            $table: $db.taskReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dueHasTime => $composableBuilder(
    column: $table.dueHasTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderRepeat => $composableBuilder(
    column: $table.reminderRepeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
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

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<bool> get dueHasTime => $composableBuilder(
    column: $table.dueHasTime,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Priority, int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, DateTime> get reminderAt =>
      $composableBuilder(
        column: $table.reminderAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<RepeatRule, int> get reminderRepeat =>
      $composableBuilder(
        column: $table.reminderRepeat,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> taskRemindersRefs<T extends Object>(
    Expression<T> Function($$TaskRemindersTableAnnotationComposer a) f,
  ) {
    final $$TaskRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.taskReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({bool taskRemindersRefs})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<bool> dueHasTime = const Value.absent(),
                Value<Priority> priority = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<RepeatRule> reminderRepeat = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                note: note,
                dueAt: dueAt,
                dueHasTime: dueHasTime,
                priority: priority,
                reminderAt: reminderAt,
                reminderRepeat: reminderRepeat,
                completedAt: completedAt,
                snoozedUntil: snoozedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<bool> dueHasTime = const Value.absent(),
                Value<Priority> priority = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<RepeatRule> reminderRepeat = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                note: note,
                dueAt: dueAt,
                dueHasTime: dueHasTime,
                priority: priority,
                reminderAt: reminderAt,
                reminderRepeat: reminderRepeat,
                completedAt: completedAt,
                snoozedUntil: snoozedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskRemindersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (taskRemindersRefs) db.taskReminders,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (taskRemindersRefs)
                    await $_getPrefetchedDataByColumns<
                      Task,
                      $TasksTable,
                      TaskReminder,
                      $TaskRemindersTable
                    >(
                      currentTable: table,
                      referencedTable: $$TasksTableReferences
                          ._taskRemindersRefsTable(db),
                      managerFromTypedResult: (p0) => $$TasksTableReferences(
                        db,
                        table,
                        p0,
                      ).taskRemindersRefs,
                      currentColumn: 'id',
                      referencedColumn: 'task_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({bool taskRemindersRefs})
    >;
typedef $$LogEntriesTableCreateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  required String content,
  required DateTime createdAt,
});
typedef $$LogEntriesTableUpdateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  Value<String> content,
  Value<DateTime> createdAt,
});

class $$LogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableFilterComposer({
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

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogEntriesTable,
          LogEntry,
          $$LogEntriesTableFilterComposer,
          $$LogEntriesTableOrderingComposer,
          $$LogEntriesTableAnnotationComposer,
          $$LogEntriesTableCreateCompanionBuilder,
          $$LogEntriesTableUpdateCompanionBuilder,
          (LogEntry, BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>),
          LogEntry,
          PrefetchHooks Function()
        > {
  $$LogEntriesTableTableManager(_$AppDatabase db, $LogEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                content: content,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                required DateTime createdAt,
              }) => LogEntriesCompanion.insert(
                id: id,
                content: content,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LogEntriesTable, LogEntry>(table),
                  BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogEntriesTable,
      LogEntry,
      $$LogEntriesTableFilterComposer,
      $$LogEntriesTableOrderingComposer,
      $$LogEntriesTableAnnotationComposer,
      $$LogEntriesTableCreateCompanionBuilder,
      $$LogEntriesTableUpdateCompanionBuilder,
      (LogEntry, BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>),
      LogEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingEntriesTableCreateCompanionBuilder =
    SettingEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingEntriesTableUpdateCompanionBuilder =
    SettingEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingEntriesTable,
          SettingEntry,
          $$SettingEntriesTableFilterComposer,
          $$SettingEntriesTableOrderingComposer,
          $$SettingEntriesTableAnnotationComposer,
          $$SettingEntriesTableCreateCompanionBuilder,
          $$SettingEntriesTableUpdateCompanionBuilder,
          (
            SettingEntry,
            BaseReferences<_$AppDatabase, $SettingEntriesTable, SettingEntry>,
          ),
          SettingEntry,
          PrefetchHooks Function()
        > {
  $$SettingEntriesTableTableManager(
    _$AppDatabase db,
    $SettingEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingEntriesTable, SettingEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingEntriesTable,
                    SettingEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingEntriesTable,
      SettingEntry,
      $$SettingEntriesTableFilterComposer,
      $$SettingEntriesTableOrderingComposer,
      $$SettingEntriesTableAnnotationComposer,
      $$SettingEntriesTableCreateCompanionBuilder,
      $$SettingEntriesTableUpdateCompanionBuilder,
      (
        SettingEntry,
        BaseReferences<_$AppDatabase, $SettingEntriesTable, SettingEntry>,
      ),
      SettingEntry,
      PrefetchHooks Function()
    >;
typedef $$TaskRemindersTableCreateCompanionBuilder =
    TaskRemindersCompanion Function({
      Value<int> id,
      required int taskId,
      required int offsetMinutes,
      Value<ReminderKind> kind,
    });
typedef $$TaskRemindersTableUpdateCompanionBuilder =
    TaskRemindersCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<int> offsetMinutes,
      Value<ReminderKind> kind,
    });

final class $$TaskRemindersTableReferences
    extends BaseReferences<_$AppDatabase, $TaskRemindersTable, TaskReminder> {
  $$TaskRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_reminders__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableFilterComposer({
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

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderKind, ReminderKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableOrderingComposer({
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

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReminderKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRemindersTable,
          TaskReminder,
          $$TaskRemindersTableFilterComposer,
          $$TaskRemindersTableOrderingComposer,
          $$TaskRemindersTableAnnotationComposer,
          $$TaskRemindersTableCreateCompanionBuilder,
          $$TaskRemindersTableUpdateCompanionBuilder,
          (TaskReminder, $$TaskRemindersTableReferences),
          TaskReminder,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskRemindersTableTableManager(_$AppDatabase db, $TaskRemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<int> offsetMinutes = const Value.absent(),
                Value<ReminderKind> kind = const Value.absent(),
              }) => TaskRemindersCompanion(
                id: id,
                taskId: taskId,
                offsetMinutes: offsetMinutes,
                kind: kind,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required int offsetMinutes,
                Value<ReminderKind> kind = const Value.absent(),
              }) => TaskRemindersCompanion.insert(
                id: id,
                taskId: taskId,
                offsetMinutes: offsetMinutes,
                kind: kind,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskRemindersTable, TaskReminder>(table),
                  $$TaskRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$TaskRemindersTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$TaskRemindersTableReferences
                            ._taskIdTable(db)
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

typedef $$TaskRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRemindersTable,
      TaskReminder,
      $$TaskRemindersTableFilterComposer,
      $$TaskRemindersTableOrderingComposer,
      $$TaskRemindersTableAnnotationComposer,
      $$TaskRemindersTableCreateCompanionBuilder,
      $$TaskRemindersTableUpdateCompanionBuilder,
      (TaskReminder, $$TaskRemindersTableReferences),
      TaskReminder,
      PrefetchHooks Function({bool taskId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db, _db.logEntries);
  $$SettingEntriesTableTableManager get settingEntries =>
      $$SettingEntriesTableTableManager(_db, _db.settingEntries);
  $$TaskRemindersTableTableManager get taskReminders =>
      $$TaskRemindersTableTableManager(_db, _db.taskReminders);
}
