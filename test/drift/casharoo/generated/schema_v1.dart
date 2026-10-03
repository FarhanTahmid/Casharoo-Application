// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Workspaces extends Table with TableInfo<Workspaces, WorkspacesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Workspaces(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> defaultCurrency = GeneratedColumn<String>(
    'default_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<bool> isDemo = GeneratedColumn<bool>(
    'is_demo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_demo" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    defaultCurrency,
    isDemo,
    role,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspacesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspacesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      defaultCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_currency'],
      )!,
      isDemo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_demo'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
    );
  }

  @override
  Workspaces createAlias(String alias) {
    return Workspaces(attachedDatabase, alias);
  }
}

class WorkspacesData extends DataClass implements Insertable<WorkspacesData> {
  final String id;
  final String name;
  final String kind;
  final String defaultCurrency;
  final bool isDemo;
  final String role;
  const WorkspacesData({
    required this.id,
    required this.name,
    required this.kind,
    required this.defaultCurrency,
    required this.isDemo,
    required this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['default_currency'] = Variable<String>(defaultCurrency);
    map['is_demo'] = Variable<bool>(isDemo);
    map['role'] = Variable<String>(role);
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      defaultCurrency: Value(defaultCurrency),
      isDemo: Value(isDemo),
      role: Value(role),
    );
  }

  factory WorkspacesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspacesData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      defaultCurrency: serializer.fromJson<String>(json['defaultCurrency']),
      isDemo: serializer.fromJson<bool>(json['isDemo']),
      role: serializer.fromJson<String>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'defaultCurrency': serializer.toJson<String>(defaultCurrency),
      'isDemo': serializer.toJson<bool>(isDemo),
      'role': serializer.toJson<String>(role),
    };
  }

  WorkspacesData copyWith({
    String? id,
    String? name,
    String? kind,
    String? defaultCurrency,
    bool? isDemo,
    String? role,
  }) => WorkspacesData(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    isDemo: isDemo ?? this.isDemo,
    role: role ?? this.role,
  );
  WorkspacesData copyWithCompanion(WorkspacesCompanion data) {
    return WorkspacesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      defaultCurrency: data.defaultCurrency.present
          ? data.defaultCurrency.value
          : this.defaultCurrency,
      isDemo: data.isDemo.present ? data.isDemo.value : this.isDemo,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('isDemo: $isDemo, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, kind, defaultCurrency, isDemo, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspacesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.defaultCurrency == this.defaultCurrency &&
          other.isDemo == this.isDemo &&
          other.role == this.role);
}

class WorkspacesCompanion extends UpdateCompanion<WorkspacesData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> defaultCurrency;
  final Value<bool> isDemo;
  final Value<String> role;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.defaultCurrency = const Value.absent(),
    this.isDemo = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    required String defaultCurrency,
    this.isDemo = const Value.absent(),
    required String role,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       defaultCurrency = Value(defaultCurrency),
       role = Value(role);
  static Insertable<WorkspacesData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? defaultCurrency,
    Expression<bool>? isDemo,
    Expression<String>? role,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (defaultCurrency != null) 'default_currency': defaultCurrency,
      if (isDemo != null) 'is_demo': isDemo,
      if (role != null) 'role': role,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? defaultCurrency,
    Value<bool>? isDemo,
    Value<String>? role,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      isDemo: isDemo ?? this.isDemo,
      role: role ?? this.role,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (defaultCurrency.present) {
      map['default_currency'] = Variable<String>(defaultCurrency.value);
    }
    if (isDemo.present) {
      map['is_demo'] = Variable<bool>(isDemo.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('isDemo: $isDemo, ')
          ..write('role: $role, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Cashbooks extends Table with TableInfo<Cashbooks, CashbooksData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Cashbooks(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    bookName,
    description,
    currency,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cashbooks';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashbooksData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashbooksData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
    );
  }

  @override
  Cashbooks createAlias(String alias) {
    return Cashbooks(attachedDatabase, alias);
  }
}

class CashbooksData extends DataClass implements Insertable<CashbooksData> {
  final String id;
  final String workspaceId;
  final int version;
  final int serverSeq;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String bookName;
  final String? description;
  final String currency;
  const CashbooksData({
    required this.id,
    required this.workspaceId,
    required this.version,
    required this.serverSeq,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.bookName,
    this.description,
    required this.currency,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['version'] = Variable<int>(version);
    map['server_seq'] = Variable<int>(serverSeq);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['book_name'] = Variable<String>(bookName);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['currency'] = Variable<String>(currency);
    return map;
  }

  CashbooksCompanion toCompanion(bool nullToAbsent) {
    return CashbooksCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      version: Value(version),
      serverSeq: Value(serverSeq),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      bookName: Value(bookName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      currency: Value(currency),
    );
  }

  factory CashbooksData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashbooksData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      version: serializer.fromJson<int>(json['version']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      bookName: serializer.fromJson<String>(json['bookName']),
      description: serializer.fromJson<String?>(json['description']),
      currency: serializer.fromJson<String>(json['currency']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'version': serializer.toJson<int>(version),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'bookName': serializer.toJson<String>(bookName),
      'description': serializer.toJson<String?>(description),
      'currency': serializer.toJson<String>(currency),
    };
  }

  CashbooksData copyWith({
    String? id,
    String? workspaceId,
    int? version,
    int? serverSeq,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? bookName,
    Value<String?> description = const Value.absent(),
    String? currency,
  }) => CashbooksData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    version: version ?? this.version,
    serverSeq: serverSeq ?? this.serverSeq,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    bookName: bookName ?? this.bookName,
    description: description.present ? description.value : this.description,
    currency: currency ?? this.currency,
  );
  CashbooksData copyWithCompanion(CashbooksCompanion data) {
    return CashbooksData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      version: data.version.present ? data.version.value : this.version,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      description: data.description.present
          ? data.description.value
          : this.description,
      currency: data.currency.present ? data.currency.value : this.currency,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashbooksData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('bookName: $bookName, ')
          ..write('description: $description, ')
          ..write('currency: $currency')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    bookName,
    description,
    currency,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashbooksData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.version == this.version &&
          other.serverSeq == this.serverSeq &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.bookName == this.bookName &&
          other.description == this.description &&
          other.currency == this.currency);
}

class CashbooksCompanion extends UpdateCompanion<CashbooksData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> version;
  final Value<int> serverSeq;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> bookName;
  final Value<String?> description;
  final Value<String> currency;
  final Value<int> rowid;
  const CashbooksCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.bookName = const Value.absent(),
    this.description = const Value.absent(),
    this.currency = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashbooksCompanion.insert({
    required String id,
    required String workspaceId,
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String bookName,
    this.description = const Value.absent(),
    required String currency,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       bookName = Value(bookName),
       currency = Value(currency);
  static Insertable<CashbooksData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? version,
    Expression<int>? serverSeq,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? bookName,
    Expression<String>? description,
    Expression<String>? currency,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (version != null) 'version': version,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (bookName != null) 'book_name': bookName,
      if (description != null) 'description': description,
      if (currency != null) 'currency': currency,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashbooksCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? version,
    Value<int>? serverSeq,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? bookName,
    Value<String?>? description,
    Value<String>? currency,
    Value<int>? rowid,
  }) {
    return CashbooksCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      version: version ?? this.version,
      serverSeq: serverSeq ?? this.serverSeq,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      bookName: bookName ?? this.bookName,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashbooksCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('bookName: $bookName, ')
          ..write('description: $description, ')
          ..write('currency: $currency, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class EntryCategories extends Table
    with TableInfo<EntryCategories, EntryCategoriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EntryCategories(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> cashbookId = GeneratedColumn<String>(
    'cashbook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    cashbookId,
    categoryName,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_categories';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryCategoriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryCategoriesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      cashbookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashbook_id'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  EntryCategories createAlias(String alias) {
    return EntryCategories(attachedDatabase, alias);
  }
}

class EntryCategoriesData extends DataClass
    implements Insertable<EntryCategoriesData> {
  final String id;
  final String workspaceId;
  final int version;
  final int serverSeq;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String cashbookId;
  final String categoryName;
  final bool isDefault;
  const EntryCategoriesData({
    required this.id,
    required this.workspaceId,
    required this.version,
    required this.serverSeq,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.cashbookId,
    required this.categoryName,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['version'] = Variable<int>(version);
    map['server_seq'] = Variable<int>(serverSeq);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['cashbook_id'] = Variable<String>(cashbookId);
    map['category_name'] = Variable<String>(categoryName);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  EntryCategoriesCompanion toCompanion(bool nullToAbsent) {
    return EntryCategoriesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      version: Value(version),
      serverSeq: Value(serverSeq),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      cashbookId: Value(cashbookId),
      categoryName: Value(categoryName),
      isDefault: Value(isDefault),
    );
  }

  factory EntryCategoriesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryCategoriesData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      version: serializer.fromJson<int>(json['version']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      cashbookId: serializer.fromJson<String>(json['cashbookId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'version': serializer.toJson<int>(version),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'cashbookId': serializer.toJson<String>(cashbookId),
      'categoryName': serializer.toJson<String>(categoryName),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  EntryCategoriesData copyWith({
    String? id,
    String? workspaceId,
    int? version,
    int? serverSeq,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? cashbookId,
    String? categoryName,
    bool? isDefault,
  }) => EntryCategoriesData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    version: version ?? this.version,
    serverSeq: serverSeq ?? this.serverSeq,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    cashbookId: cashbookId ?? this.cashbookId,
    categoryName: categoryName ?? this.categoryName,
    isDefault: isDefault ?? this.isDefault,
  );
  EntryCategoriesData copyWithCompanion(EntryCategoriesCompanion data) {
    return EntryCategoriesData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      version: data.version.present ? data.version.value : this.version,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      cashbookId: data.cashbookId.present
          ? data.cashbookId.value
          : this.cashbookId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryCategoriesData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cashbookId: $cashbookId, ')
          ..write('categoryName: $categoryName, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    cashbookId,
    categoryName,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryCategoriesData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.version == this.version &&
          other.serverSeq == this.serverSeq &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.cashbookId == this.cashbookId &&
          other.categoryName == this.categoryName &&
          other.isDefault == this.isDefault);
}

class EntryCategoriesCompanion extends UpdateCompanion<EntryCategoriesData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> version;
  final Value<int> serverSeq;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> cashbookId;
  final Value<String> categoryName;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const EntryCategoriesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.cashbookId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryCategoriesCompanion.insert({
    required String id,
    required String workspaceId,
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String cashbookId,
    required String categoryName,
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cashbookId = Value(cashbookId),
       categoryName = Value(categoryName);
  static Insertable<EntryCategoriesData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? version,
    Expression<int>? serverSeq,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? cashbookId,
    Expression<String>? categoryName,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (version != null) 'version': version,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (cashbookId != null) 'cashbook_id': cashbookId,
      if (categoryName != null) 'category_name': categoryName,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? version,
    Value<int>? serverSeq,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? cashbookId,
    Value<String>? categoryName,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return EntryCategoriesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      version: version ?? this.version,
      serverSeq: serverSeq ?? this.serverSeq,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      cashbookId: cashbookId ?? this.cashbookId,
      categoryName: categoryName ?? this.categoryName,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (cashbookId.present) {
      map['cashbook_id'] = Variable<String>(cashbookId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cashbookId: $cashbookId, ')
          ..write('categoryName: $categoryName, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PaymentMethods extends Table
    with TableInfo<PaymentMethods, PaymentMethodsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PaymentMethods(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> cashbookId = GeneratedColumn<String>(
    'cashbook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> paymentMethodName =
      GeneratedColumn<String>(
        'payment_method_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    cashbookId,
    paymentMethodName,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethodsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethodsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      cashbookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashbook_id'],
      )!,
      paymentMethodName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method_name'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  PaymentMethods createAlias(String alias) {
    return PaymentMethods(attachedDatabase, alias);
  }
}

class PaymentMethodsData extends DataClass
    implements Insertable<PaymentMethodsData> {
  final String id;
  final String workspaceId;
  final int version;
  final int serverSeq;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String cashbookId;
  final String paymentMethodName;
  final bool isDefault;
  const PaymentMethodsData({
    required this.id,
    required this.workspaceId,
    required this.version,
    required this.serverSeq,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.cashbookId,
    required this.paymentMethodName,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['version'] = Variable<int>(version);
    map['server_seq'] = Variable<int>(serverSeq);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['cashbook_id'] = Variable<String>(cashbookId);
    map['payment_method_name'] = Variable<String>(paymentMethodName);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  PaymentMethodsCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      version: Value(version),
      serverSeq: Value(serverSeq),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      cashbookId: Value(cashbookId),
      paymentMethodName: Value(paymentMethodName),
      isDefault: Value(isDefault),
    );
  }

  factory PaymentMethodsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethodsData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      version: serializer.fromJson<int>(json['version']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      cashbookId: serializer.fromJson<String>(json['cashbookId']),
      paymentMethodName: serializer.fromJson<String>(json['paymentMethodName']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'version': serializer.toJson<int>(version),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'cashbookId': serializer.toJson<String>(cashbookId),
      'paymentMethodName': serializer.toJson<String>(paymentMethodName),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  PaymentMethodsData copyWith({
    String? id,
    String? workspaceId,
    int? version,
    int? serverSeq,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? cashbookId,
    String? paymentMethodName,
    bool? isDefault,
  }) => PaymentMethodsData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    version: version ?? this.version,
    serverSeq: serverSeq ?? this.serverSeq,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    cashbookId: cashbookId ?? this.cashbookId,
    paymentMethodName: paymentMethodName ?? this.paymentMethodName,
    isDefault: isDefault ?? this.isDefault,
  );
  PaymentMethodsData copyWithCompanion(PaymentMethodsCompanion data) {
    return PaymentMethodsData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      version: data.version.present ? data.version.value : this.version,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      cashbookId: data.cashbookId.present
          ? data.cashbookId.value
          : this.cashbookId,
      paymentMethodName: data.paymentMethodName.present
          ? data.paymentMethodName.value
          : this.paymentMethodName,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cashbookId: $cashbookId, ')
          ..write('paymentMethodName: $paymentMethodName, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    cashbookId,
    paymentMethodName,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethodsData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.version == this.version &&
          other.serverSeq == this.serverSeq &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.cashbookId == this.cashbookId &&
          other.paymentMethodName == this.paymentMethodName &&
          other.isDefault == this.isDefault);
}

class PaymentMethodsCompanion extends UpdateCompanion<PaymentMethodsData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> version;
  final Value<int> serverSeq;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> cashbookId;
  final Value<String> paymentMethodName;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const PaymentMethodsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.cashbookId = const Value.absent(),
    this.paymentMethodName = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentMethodsCompanion.insert({
    required String id,
    required String workspaceId,
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String cashbookId,
    required String paymentMethodName,
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cashbookId = Value(cashbookId),
       paymentMethodName = Value(paymentMethodName);
  static Insertable<PaymentMethodsData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? version,
    Expression<int>? serverSeq,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? cashbookId,
    Expression<String>? paymentMethodName,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (version != null) 'version': version,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (cashbookId != null) 'cashbook_id': cashbookId,
      if (paymentMethodName != null) 'payment_method_name': paymentMethodName,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentMethodsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? version,
    Value<int>? serverSeq,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? cashbookId,
    Value<String>? paymentMethodName,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return PaymentMethodsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      version: version ?? this.version,
      serverSeq: serverSeq ?? this.serverSeq,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      cashbookId: cashbookId ?? this.cashbookId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (cashbookId.present) {
      map['cashbook_id'] = Variable<String>(cashbookId.value);
    }
    if (paymentMethodName.present) {
      map['payment_method_name'] = Variable<String>(paymentMethodName.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cashbookId: $cashbookId, ')
          ..write('paymentMethodName: $paymentMethodName, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Entries extends Table with TableInfo<Entries, EntriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Entries(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> cashbookId = GeneratedColumn<String>(
    'cashbook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> paymentMethodId = GeneratedColumn<String>(
    'payment_method_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
    'entry_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> entryDate = GeneratedColumn<String>(
    'entry_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'manual\''),
  );
  late final GeneratedColumn<String> createdById = GeneratedColumn<String>(
    'created_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    cashbookId,
    categoryId,
    paymentMethodId,
    entryType,
    amountMinor,
    currency,
    title,
    remarks,
    entryDate,
    source,
    createdById,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntriesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      cashbookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashbook_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      paymentMethodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method_id'],
      ),
      entryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_type'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      entryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_date'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_id'],
      ),
    );
  }

  @override
  Entries createAlias(String alias) {
    return Entries(attachedDatabase, alias);
  }
}

class EntriesData extends DataClass implements Insertable<EntriesData> {
  final String id;
  final String workspaceId;
  final int version;
  final int serverSeq;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String cashbookId;
  final String? categoryId;
  final String? paymentMethodId;
  final String entryType;
  final int amountMinor;
  final String currency;
  final String? title;
  final String? remarks;
  final String entryDate;
  final String source;
  final String? createdById;
  const EntriesData({
    required this.id,
    required this.workspaceId,
    required this.version,
    required this.serverSeq,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.cashbookId,
    this.categoryId,
    this.paymentMethodId,
    required this.entryType,
    required this.amountMinor,
    required this.currency,
    this.title,
    this.remarks,
    required this.entryDate,
    required this.source,
    this.createdById,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['version'] = Variable<int>(version);
    map['server_seq'] = Variable<int>(serverSeq);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['cashbook_id'] = Variable<String>(cashbookId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || paymentMethodId != null) {
      map['payment_method_id'] = Variable<String>(paymentMethodId);
    }
    map['entry_type'] = Variable<String>(entryType);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    map['entry_date'] = Variable<String>(entryDate);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || createdById != null) {
      map['created_by_id'] = Variable<String>(createdById);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      version: Value(version),
      serverSeq: Value(serverSeq),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      cashbookId: Value(cashbookId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      paymentMethodId: paymentMethodId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodId),
      entryType: Value(entryType),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      entryDate: Value(entryDate),
      source: Value(source),
      createdById: createdById == null && nullToAbsent
          ? const Value.absent()
          : Value(createdById),
    );
  }

  factory EntriesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntriesData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      version: serializer.fromJson<int>(json['version']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      cashbookId: serializer.fromJson<String>(json['cashbookId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      paymentMethodId: serializer.fromJson<String?>(json['paymentMethodId']),
      entryType: serializer.fromJson<String>(json['entryType']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      title: serializer.fromJson<String?>(json['title']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      entryDate: serializer.fromJson<String>(json['entryDate']),
      source: serializer.fromJson<String>(json['source']),
      createdById: serializer.fromJson<String?>(json['createdById']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'version': serializer.toJson<int>(version),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'cashbookId': serializer.toJson<String>(cashbookId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'paymentMethodId': serializer.toJson<String?>(paymentMethodId),
      'entryType': serializer.toJson<String>(entryType),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'title': serializer.toJson<String?>(title),
      'remarks': serializer.toJson<String?>(remarks),
      'entryDate': serializer.toJson<String>(entryDate),
      'source': serializer.toJson<String>(source),
      'createdById': serializer.toJson<String?>(createdById),
    };
  }

  EntriesData copyWith({
    String? id,
    String? workspaceId,
    int? version,
    int? serverSeq,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? cashbookId,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> paymentMethodId = const Value.absent(),
    String? entryType,
    int? amountMinor,
    String? currency,
    Value<String?> title = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    String? entryDate,
    String? source,
    Value<String?> createdById = const Value.absent(),
  }) => EntriesData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    version: version ?? this.version,
    serverSeq: serverSeq ?? this.serverSeq,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    cashbookId: cashbookId ?? this.cashbookId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    paymentMethodId: paymentMethodId.present
        ? paymentMethodId.value
        : this.paymentMethodId,
    entryType: entryType ?? this.entryType,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    title: title.present ? title.value : this.title,
    remarks: remarks.present ? remarks.value : this.remarks,
    entryDate: entryDate ?? this.entryDate,
    source: source ?? this.source,
    createdById: createdById.present ? createdById.value : this.createdById,
  );
  EntriesData copyWithCompanion(EntriesCompanion data) {
    return EntriesData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      version: data.version.present ? data.version.value : this.version,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      cashbookId: data.cashbookId.present
          ? data.cashbookId.value
          : this.cashbookId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      paymentMethodId: data.paymentMethodId.present
          ? data.paymentMethodId.value
          : this.paymentMethodId,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      title: data.title.present ? data.title.value : this.title,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      source: data.source.present ? data.source.value : this.source,
      createdById: data.createdById.present
          ? data.createdById.value
          : this.createdById,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntriesData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cashbookId: $cashbookId, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('entryType: $entryType, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('title: $title, ')
          ..write('remarks: $remarks, ')
          ..write('entryDate: $entryDate, ')
          ..write('source: $source, ')
          ..write('createdById: $createdById')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    cashbookId,
    categoryId,
    paymentMethodId,
    entryType,
    amountMinor,
    currency,
    title,
    remarks,
    entryDate,
    source,
    createdById,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntriesData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.version == this.version &&
          other.serverSeq == this.serverSeq &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.cashbookId == this.cashbookId &&
          other.categoryId == this.categoryId &&
          other.paymentMethodId == this.paymentMethodId &&
          other.entryType == this.entryType &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.title == this.title &&
          other.remarks == this.remarks &&
          other.entryDate == this.entryDate &&
          other.source == this.source &&
          other.createdById == this.createdById);
}

class EntriesCompanion extends UpdateCompanion<EntriesData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> version;
  final Value<int> serverSeq;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> cashbookId;
  final Value<String?> categoryId;
  final Value<String?> paymentMethodId;
  final Value<String> entryType;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<String?> title;
  final Value<String?> remarks;
  final Value<String> entryDate;
  final Value<String> source;
  final Value<String?> createdById;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.cashbookId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.entryType = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.title = const Value.absent(),
    this.remarks = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.source = const Value.absent(),
    this.createdById = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    required String workspaceId,
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String cashbookId,
    this.categoryId = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    required String entryType,
    required int amountMinor,
    required String currency,
    this.title = const Value.absent(),
    this.remarks = const Value.absent(),
    required String entryDate,
    this.source = const Value.absent(),
    this.createdById = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cashbookId = Value(cashbookId),
       entryType = Value(entryType),
       amountMinor = Value(amountMinor),
       currency = Value(currency),
       entryDate = Value(entryDate);
  static Insertable<EntriesData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? version,
    Expression<int>? serverSeq,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? cashbookId,
    Expression<String>? categoryId,
    Expression<String>? paymentMethodId,
    Expression<String>? entryType,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? title,
    Expression<String>? remarks,
    Expression<String>? entryDate,
    Expression<String>? source,
    Expression<String>? createdById,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (version != null) 'version': version,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (cashbookId != null) 'cashbook_id': cashbookId,
      if (categoryId != null) 'category_id': categoryId,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (entryType != null) 'entry_type': entryType,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (title != null) 'title': title,
      if (remarks != null) 'remarks': remarks,
      if (entryDate != null) 'entry_date': entryDate,
      if (source != null) 'source': source,
      if (createdById != null) 'created_by_id': createdById,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? version,
    Value<int>? serverSeq,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? cashbookId,
    Value<String?>? categoryId,
    Value<String?>? paymentMethodId,
    Value<String>? entryType,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<String?>? title,
    Value<String?>? remarks,
    Value<String>? entryDate,
    Value<String>? source,
    Value<String?>? createdById,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      version: version ?? this.version,
      serverSeq: serverSeq ?? this.serverSeq,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      cashbookId: cashbookId ?? this.cashbookId,
      categoryId: categoryId ?? this.categoryId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      entryType: entryType ?? this.entryType,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      title: title ?? this.title,
      remarks: remarks ?? this.remarks,
      entryDate: entryDate ?? this.entryDate,
      source: source ?? this.source,
      createdById: createdById ?? this.createdById,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (cashbookId.present) {
      map['cashbook_id'] = Variable<String>(cashbookId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (paymentMethodId.present) {
      map['payment_method_id'] = Variable<String>(paymentMethodId.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<String>(entryDate.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdById.present) {
      map['created_by_id'] = Variable<String>(createdById.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cashbookId: $cashbookId, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('entryType: $entryType, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('title: $title, ')
          ..write('remarks: $remarks, ')
          ..write('entryDate: $entryDate, ')
          ..write('source: $source, ')
          ..write('createdById: $createdById, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CashbookMembers extends Table
    with TableInfo<CashbookMembers, CashbookMembersData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CashbookMembers(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> cashbookId = GeneratedColumn<String>(
    'cashbook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    cashbookId,
    memberId,
    role,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cashbook_members';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashbookMembersData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashbookMembersData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      cashbookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashbook_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
    );
  }

  @override
  CashbookMembers createAlias(String alias) {
    return CashbookMembers(attachedDatabase, alias);
  }
}

class CashbookMembersData extends DataClass
    implements Insertable<CashbookMembersData> {
  final String id;
  final String workspaceId;
  final int version;
  final int serverSeq;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String cashbookId;
  final String memberId;
  final String role;
  const CashbookMembersData({
    required this.id,
    required this.workspaceId,
    required this.version,
    required this.serverSeq,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.cashbookId,
    required this.memberId,
    required this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['version'] = Variable<int>(version);
    map['server_seq'] = Variable<int>(serverSeq);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['cashbook_id'] = Variable<String>(cashbookId);
    map['member_id'] = Variable<String>(memberId);
    map['role'] = Variable<String>(role);
    return map;
  }

  CashbookMembersCompanion toCompanion(bool nullToAbsent) {
    return CashbookMembersCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      version: Value(version),
      serverSeq: Value(serverSeq),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      cashbookId: Value(cashbookId),
      memberId: Value(memberId),
      role: Value(role),
    );
  }

  factory CashbookMembersData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashbookMembersData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      version: serializer.fromJson<int>(json['version']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      cashbookId: serializer.fromJson<String>(json['cashbookId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      role: serializer.fromJson<String>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'version': serializer.toJson<int>(version),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'cashbookId': serializer.toJson<String>(cashbookId),
      'memberId': serializer.toJson<String>(memberId),
      'role': serializer.toJson<String>(role),
    };
  }

  CashbookMembersData copyWith({
    String? id,
    String? workspaceId,
    int? version,
    int? serverSeq,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? cashbookId,
    String? memberId,
    String? role,
  }) => CashbookMembersData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    version: version ?? this.version,
    serverSeq: serverSeq ?? this.serverSeq,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    cashbookId: cashbookId ?? this.cashbookId,
    memberId: memberId ?? this.memberId,
    role: role ?? this.role,
  );
  CashbookMembersData copyWithCompanion(CashbookMembersCompanion data) {
    return CashbookMembersData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      version: data.version.present ? data.version.value : this.version,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      cashbookId: data.cashbookId.present
          ? data.cashbookId.value
          : this.cashbookId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashbookMembersData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cashbookId: $cashbookId, ')
          ..write('memberId: $memberId, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    cashbookId,
    memberId,
    role,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashbookMembersData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.version == this.version &&
          other.serverSeq == this.serverSeq &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.cashbookId == this.cashbookId &&
          other.memberId == this.memberId &&
          other.role == this.role);
}

class CashbookMembersCompanion extends UpdateCompanion<CashbookMembersData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> version;
  final Value<int> serverSeq;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> cashbookId;
  final Value<String> memberId;
  final Value<String> role;
  final Value<int> rowid;
  const CashbookMembersCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.cashbookId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashbookMembersCompanion.insert({
    required String id,
    required String workspaceId,
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String cashbookId,
    required String memberId,
    required String role,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cashbookId = Value(cashbookId),
       memberId = Value(memberId),
       role = Value(role);
  static Insertable<CashbookMembersData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? version,
    Expression<int>? serverSeq,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? cashbookId,
    Expression<String>? memberId,
    Expression<String>? role,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (version != null) 'version': version,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (cashbookId != null) 'cashbook_id': cashbookId,
      if (memberId != null) 'member_id': memberId,
      if (role != null) 'role': role,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashbookMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? version,
    Value<int>? serverSeq,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? cashbookId,
    Value<String>? memberId,
    Value<String>? role,
    Value<int>? rowid,
  }) {
    return CashbookMembersCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      version: version ?? this.version,
      serverSeq: serverSeq ?? this.serverSeq,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      cashbookId: cashbookId ?? this.cashbookId,
      memberId: memberId ?? this.memberId,
      role: role ?? this.role,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (cashbookId.present) {
      map['cashbook_id'] = Variable<String>(cashbookId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashbookMembersCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cashbookId: $cashbookId, ')
          ..write('memberId: $memberId, ')
          ..write('role: $role, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Accounts extends Table with TableInfo<Accounts, AccountsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Accounts(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> openingBalanceMinor = GeneratedColumn<int>(
    'opening_balance_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    kind,
    currency,
    openingBalanceMinor,
    isArchived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      openingBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance_minor'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
    );
  }

  @override
  Accounts createAlias(String alias) {
    return Accounts(attachedDatabase, alias);
  }
}

class AccountsData extends DataClass implements Insertable<AccountsData> {
  final String id;
  final String workspaceId;
  final int version;
  final int serverSeq;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String name;
  final String kind;
  final String currency;
  final int openingBalanceMinor;
  final bool isArchived;
  const AccountsData({
    required this.id,
    required this.workspaceId,
    required this.version,
    required this.serverSeq,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.kind,
    required this.currency,
    required this.openingBalanceMinor,
    required this.isArchived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['version'] = Variable<int>(version);
    map['server_seq'] = Variable<int>(serverSeq);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['currency'] = Variable<String>(currency);
    map['opening_balance_minor'] = Variable<int>(openingBalanceMinor);
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      version: Value(version),
      serverSeq: Value(serverSeq),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      kind: Value(kind),
      currency: Value(currency),
      openingBalanceMinor: Value(openingBalanceMinor),
      isArchived: Value(isArchived),
    );
  }

  factory AccountsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountsData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      version: serializer.fromJson<int>(json['version']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      currency: serializer.fromJson<String>(json['currency']),
      openingBalanceMinor: serializer.fromJson<int>(
        json['openingBalanceMinor'],
      ),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'version': serializer.toJson<int>(version),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'currency': serializer.toJson<String>(currency),
      'openingBalanceMinor': serializer.toJson<int>(openingBalanceMinor),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  AccountsData copyWith({
    String? id,
    String? workspaceId,
    int? version,
    int? serverSeq,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? name,
    String? kind,
    String? currency,
    int? openingBalanceMinor,
    bool? isArchived,
  }) => AccountsData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    version: version ?? this.version,
    serverSeq: serverSeq ?? this.serverSeq,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    currency: currency ?? this.currency,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    isArchived: isArchived ?? this.isArchived,
  );
  AccountsData copyWithCompanion(AccountsCompanion data) {
    return AccountsData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      version: data.version.present ? data.version.value : this.version,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      currency: data.currency.present ? data.currency.value : this.currency,
      openingBalanceMinor: data.openingBalanceMinor.present
          ? data.openingBalanceMinor.value
          : this.openingBalanceMinor,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountsData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('currency: $currency, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    kind,
    currency,
    openingBalanceMinor,
    isArchived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountsData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.version == this.version &&
          other.serverSeq == this.serverSeq &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.currency == this.currency &&
          other.openingBalanceMinor == this.openingBalanceMinor &&
          other.isArchived == this.isArchived);
}

class AccountsCompanion extends UpdateCompanion<AccountsData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> version;
  final Value<int> serverSeq;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> currency;
  final Value<int> openingBalanceMinor;
  final Value<bool> isArchived;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.currency = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String workspaceId,
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required String kind,
    required String currency,
    this.openingBalanceMinor = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       kind = Value(kind),
       currency = Value(currency);
  static Insertable<AccountsData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? version,
    Expression<int>? serverSeq,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? currency,
    Expression<int>? openingBalanceMinor,
    Expression<bool>? isArchived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (version != null) 'version': version,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (openingBalanceMinor != null)
        'opening_balance_minor': openingBalanceMinor,
      if (isArchived != null) 'is_archived': isArchived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? version,
    Value<int>? serverSeq,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? currency,
    Value<int>? openingBalanceMinor,
    Value<bool>? isArchived,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      version: version ?? this.version,
      serverSeq: serverSeq ?? this.serverSeq,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      currency: currency ?? this.currency,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      isArchived: isArchived ?? this.isArchived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (openingBalanceMinor.present) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('currency: $currency, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('isArchived: $isArchived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Categories extends Table with TableInfo<Categories, CategoriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Categories(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    kind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  Categories createAlias(String alias) {
    return Categories(attachedDatabase, alias);
  }
}

class CategoriesData extends DataClass implements Insertable<CategoriesData> {
  final String id;
  final String workspaceId;
  final int version;
  final int serverSeq;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String name;
  final String kind;
  const CategoriesData({
    required this.id,
    required this.workspaceId,
    required this.version,
    required this.serverSeq,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['version'] = Variable<int>(version);
    map['server_seq'] = Variable<int>(serverSeq);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      version: Value(version),
      serverSeq: Value(serverSeq),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      kind: Value(kind),
    );
  }

  factory CategoriesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      version: serializer.fromJson<int>(json['version']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'version': serializer.toJson<int>(version),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
    };
  }

  CategoriesData copyWith({
    String? id,
    String? workspaceId,
    int? version,
    int? serverSeq,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? name,
    String? kind,
  }) => CategoriesData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    version: version ?? this.version,
    serverSeq: serverSeq ?? this.serverSeq,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    kind: kind ?? this.kind,
  );
  CategoriesData copyWithCompanion(CategoriesCompanion data) {
    return CategoriesData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      version: data.version.present ? data.version.value : this.version,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    kind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.version == this.version &&
          other.serverSeq == this.serverSeq &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.kind == this.kind);
}

class CategoriesCompanion extends UpdateCompanion<CategoriesData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> version;
  final Value<int> serverSeq;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> name;
  final Value<String> kind;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String workspaceId,
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required String kind,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       kind = Value(kind);
  static Insertable<CategoriesData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? version,
    Expression<int>? serverSeq,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (version != null) 'version': version,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? version,
    Value<int>? serverSeq,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? name,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      version: version ?? this.version,
      serverSeq: serverSeq ?? this.serverSeq,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Transactions extends Table
    with TableInfo<Transactions, TransactionsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Transactions(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> transferGroupId = GeneratedColumn<String>(
    'transfer_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> occurredOn = GeneratedColumn<String>(
    'occurred_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'\''),
  );
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'manual\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    accountId,
    categoryId,
    kind,
    amountMinor,
    currency,
    transferGroupId,
    occurredOn,
    note,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      transferGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_group_id'],
      ),
      occurredOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_on'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  Transactions createAlias(String alias) {
    return Transactions(attachedDatabase, alias);
  }
}

class TransactionsData extends DataClass
    implements Insertable<TransactionsData> {
  final String id;
  final String workspaceId;
  final int version;
  final int serverSeq;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String accountId;
  final String? categoryId;
  final String kind;
  final int amountMinor;
  final String currency;
  final String? transferGroupId;
  final String occurredOn;
  final String note;
  final String source;
  const TransactionsData({
    required this.id,
    required this.workspaceId,
    required this.version,
    required this.serverSeq,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.accountId,
    this.categoryId,
    required this.kind,
    required this.amountMinor,
    required this.currency,
    this.transferGroupId,
    required this.occurredOn,
    required this.note,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['version'] = Variable<int>(version);
    map['server_seq'] = Variable<int>(serverSeq);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['kind'] = Variable<String>(kind);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || transferGroupId != null) {
      map['transfer_group_id'] = Variable<String>(transferGroupId);
    }
    map['occurred_on'] = Variable<String>(occurredOn);
    map['note'] = Variable<String>(note);
    map['source'] = Variable<String>(source);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      version: Value(version),
      serverSeq: Value(serverSeq),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      accountId: Value(accountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      kind: Value(kind),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      transferGroupId: transferGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferGroupId),
      occurredOn: Value(occurredOn),
      note: Value(note),
      source: Value(source),
    );
  }

  factory TransactionsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      version: serializer.fromJson<int>(json['version']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      accountId: serializer.fromJson<String>(json['accountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      kind: serializer.fromJson<String>(json['kind']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      transferGroupId: serializer.fromJson<String?>(json['transferGroupId']),
      occurredOn: serializer.fromJson<String>(json['occurredOn']),
      note: serializer.fromJson<String>(json['note']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'version': serializer.toJson<int>(version),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'accountId': serializer.toJson<String>(accountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'kind': serializer.toJson<String>(kind),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'transferGroupId': serializer.toJson<String?>(transferGroupId),
      'occurredOn': serializer.toJson<String>(occurredOn),
      'note': serializer.toJson<String>(note),
      'source': serializer.toJson<String>(source),
    };
  }

  TransactionsData copyWith({
    String? id,
    String? workspaceId,
    int? version,
    int? serverSeq,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? accountId,
    Value<String?> categoryId = const Value.absent(),
    String? kind,
    int? amountMinor,
    String? currency,
    Value<String?> transferGroupId = const Value.absent(),
    String? occurredOn,
    String? note,
    String? source,
  }) => TransactionsData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    version: version ?? this.version,
    serverSeq: serverSeq ?? this.serverSeq,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    kind: kind ?? this.kind,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    transferGroupId: transferGroupId.present
        ? transferGroupId.value
        : this.transferGroupId,
    occurredOn: occurredOn ?? this.occurredOn,
    note: note ?? this.note,
    source: source ?? this.source,
  );
  TransactionsData copyWithCompanion(TransactionsCompanion data) {
    return TransactionsData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      version: data.version.present ? data.version.value : this.version,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      transferGroupId: data.transferGroupId.present
          ? data.transferGroupId.value
          : this.transferGroupId,
      occurredOn: data.occurredOn.present
          ? data.occurredOn.value
          : this.occurredOn,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('note: $note, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    accountId,
    categoryId,
    kind,
    amountMinor,
    currency,
    transferGroupId,
    occurredOn,
    note,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.version == this.version &&
          other.serverSeq == this.serverSeq &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.kind == this.kind &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.transferGroupId == this.transferGroupId &&
          other.occurredOn == this.occurredOn &&
          other.note == this.note &&
          other.source == this.source);
}

class TransactionsCompanion extends UpdateCompanion<TransactionsData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> version;
  final Value<int> serverSeq;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> accountId;
  final Value<String?> categoryId;
  final Value<String> kind;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<String?> transferGroupId;
  final Value<String> occurredOn;
  final Value<String> note;
  final Value<String> source;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String workspaceId,
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String accountId,
    this.categoryId = const Value.absent(),
    required String kind,
    required int amountMinor,
    required String currency,
    this.transferGroupId = const Value.absent(),
    required String occurredOn,
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       accountId = Value(accountId),
       kind = Value(kind),
       amountMinor = Value(amountMinor),
       currency = Value(currency),
       occurredOn = Value(occurredOn);
  static Insertable<TransactionsData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? version,
    Expression<int>? serverSeq,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<String>? kind,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? transferGroupId,
    Expression<String>? occurredOn,
    Expression<String>? note,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (version != null) 'version': version,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (kind != null) 'kind': kind,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (transferGroupId != null) 'transfer_group_id': transferGroupId,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? version,
    Value<int>? serverSeq,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? accountId,
    Value<String?>? categoryId,
    Value<String>? kind,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<String?>? transferGroupId,
    Value<String>? occurredOn,
    Value<String>? note,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      version: version ?? this.version,
      serverSeq: serverSeq ?? this.serverSeq,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      kind: kind ?? this.kind,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      occurredOn: occurredOn ?? this.occurredOn,
      note: note ?? this.note,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (transferGroupId.present) {
      map['transfer_group_id'] = Variable<String>(transferGroupId.value);
    }
    if (occurredOn.present) {
      map['occurred_on'] = Variable<String>(occurredOn.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Budgets extends Table with TableInfo<Budgets, BudgetsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Budgets(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    categoryId,
    amountMinor,
    currency,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
    );
  }

  @override
  Budgets createAlias(String alias) {
    return Budgets(attachedDatabase, alias);
  }
}

class BudgetsData extends DataClass implements Insertable<BudgetsData> {
  final String id;
  final String workspaceId;
  final int version;
  final int serverSeq;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String categoryId;
  final int amountMinor;
  final String currency;
  const BudgetsData({
    required this.id,
    required this.workspaceId,
    required this.version,
    required this.serverSeq,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.categoryId,
    required this.amountMinor,
    required this.currency,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['version'] = Variable<int>(version);
    map['server_seq'] = Variable<int>(serverSeq);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['category_id'] = Variable<String>(categoryId);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      version: Value(version),
      serverSeq: Value(serverSeq),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      categoryId: Value(categoryId),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
    );
  }

  factory BudgetsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetsData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      version: serializer.fromJson<int>(json['version']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'version': serializer.toJson<int>(version),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'categoryId': serializer.toJson<String>(categoryId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
    };
  }

  BudgetsData copyWith({
    String? id,
    String? workspaceId,
    int? version,
    int? serverSeq,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? categoryId,
    int? amountMinor,
    String? currency,
  }) => BudgetsData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    version: version ?? this.version,
    serverSeq: serverSeq ?? this.serverSeq,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    categoryId: categoryId ?? this.categoryId,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
  );
  BudgetsData copyWithCompanion(BudgetsCompanion data) {
    return BudgetsData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      version: data.version.present ? data.version.value : this.version,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    version,
    serverSeq,
    createdAt,
    updatedAt,
    deletedAt,
    categoryId,
    amountMinor,
    currency,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetsData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.version == this.version &&
          other.serverSeq == this.serverSeq &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.categoryId == this.categoryId &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency);
}

class BudgetsCompanion extends UpdateCompanion<BudgetsData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> version;
  final Value<int> serverSeq;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> categoryId;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String workspaceId,
    this.version = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String categoryId,
    required int amountMinor,
    required String currency,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       categoryId = Value(categoryId),
       amountMinor = Value(amountMinor),
       currency = Value(currency);
  static Insertable<BudgetsData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? version,
    Expression<int>? serverSeq,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? categoryId,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (version != null) 'version': version,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (categoryId != null) 'category_id': categoryId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? version,
    Value<int>? serverSeq,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? categoryId,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      version: version ?? this.version,
      serverSeq: serverSeq ?? this.serverSeq,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('version: $version, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Outbox extends Table with TableInfo<Outbox, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Outbox(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> tableName_ = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    mutationId,
    workspaceId,
    tableName_,
    op,
    rowId,
    data,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      tableName_: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  Outbox createAlias(String alias) {
    return Outbox(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final int seq;
  final String mutationId;
  final String workspaceId;
  final String tableName_;
  final String op;
  final String rowId;
  final String data;
  const OutboxData({
    required this.seq,
    required this.mutationId,
    required this.workspaceId,
    required this.tableName_,
    required this.op,
    required this.rowId,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['mutation_id'] = Variable<String>(mutationId);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['table_name'] = Variable<String>(tableName_);
    map['op'] = Variable<String>(op);
    map['row_id'] = Variable<String>(rowId);
    map['data'] = Variable<String>(data);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      mutationId: Value(mutationId),
      workspaceId: Value(workspaceId),
      tableName_: Value(tableName_),
      op: Value(op),
      rowId: Value(rowId),
      data: Value(data),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      seq: serializer.fromJson<int>(json['seq']),
      mutationId: serializer.fromJson<String>(json['mutationId']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      tableName_: serializer.fromJson<String>(json['tableName_']),
      op: serializer.fromJson<String>(json['op']),
      rowId: serializer.fromJson<String>(json['rowId']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'mutationId': serializer.toJson<String>(mutationId),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'tableName_': serializer.toJson<String>(tableName_),
      'op': serializer.toJson<String>(op),
      'rowId': serializer.toJson<String>(rowId),
      'data': serializer.toJson<String>(data),
    };
  }

  OutboxData copyWith({
    int? seq,
    String? mutationId,
    String? workspaceId,
    String? tableName_,
    String? op,
    String? rowId,
    String? data,
  }) => OutboxData(
    seq: seq ?? this.seq,
    mutationId: mutationId ?? this.mutationId,
    workspaceId: workspaceId ?? this.workspaceId,
    tableName_: tableName_ ?? this.tableName_,
    op: op ?? this.op,
    rowId: rowId ?? this.rowId,
    data: data ?? this.data,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      seq: data.seq.present ? data.seq.value : this.seq,
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      tableName_: data.tableName_.present
          ? data.tableName_.value
          : this.tableName_,
      op: data.op.present ? data.op.value : this.op,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('tableName_: $tableName_, ')
          ..write('op: $op, ')
          ..write('rowId: $rowId, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seq, mutationId, workspaceId, tableName_, op, rowId, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.seq == this.seq &&
          other.mutationId == this.mutationId &&
          other.workspaceId == this.workspaceId &&
          other.tableName_ == this.tableName_ &&
          other.op == this.op &&
          other.rowId == this.rowId &&
          other.data == this.data);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> seq;
  final Value<String> mutationId;
  final Value<String> workspaceId;
  final Value<String> tableName_;
  final Value<String> op;
  final Value<String> rowId;
  final Value<String> data;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.tableName_ = const Value.absent(),
    this.op = const Value.absent(),
    this.rowId = const Value.absent(),
    this.data = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String mutationId,
    required String workspaceId,
    required String tableName_,
    required String op,
    required String rowId,
    required String data,
  }) : mutationId = Value(mutationId),
       workspaceId = Value(workspaceId),
       tableName_ = Value(tableName_),
       op = Value(op),
       rowId = Value(rowId),
       data = Value(data);
  static Insertable<OutboxData> custom({
    Expression<int>? seq,
    Expression<String>? mutationId,
    Expression<String>? workspaceId,
    Expression<String>? tableName_,
    Expression<String>? op,
    Expression<String>? rowId,
    Expression<String>? data,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (mutationId != null) 'mutation_id': mutationId,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (tableName_ != null) 'table_name': tableName_,
      if (op != null) 'op': op,
      if (rowId != null) 'row_id': rowId,
      if (data != null) 'data': data,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? mutationId,
    Value<String>? workspaceId,
    Value<String>? tableName_,
    Value<String>? op,
    Value<String>? rowId,
    Value<String>? data,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      mutationId: mutationId ?? this.mutationId,
      workspaceId: workspaceId ?? this.workspaceId,
      tableName_: tableName_ ?? this.tableName_,
      op: op ?? this.op,
      rowId: rowId ?? this.rowId,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (tableName_.present) {
      map['table_name'] = Variable<String>(tableName_.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('tableName_: $tableName_, ')
          ..write('op: $op, ')
          ..write('rowId: $rowId, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class SyncCursors extends Table with TableInfo<SyncCursors, SyncCursorsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncCursors(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> since = GeneratedColumn<int>(
    'since',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [workspaceId, since];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId};
  @override
  SyncCursorsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorsData(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      since: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}since'],
      )!,
    );
  }

  @override
  SyncCursors createAlias(String alias) {
    return SyncCursors(attachedDatabase, alias);
  }
}

class SyncCursorsData extends DataClass implements Insertable<SyncCursorsData> {
  final String workspaceId;
  final int since;
  const SyncCursorsData({required this.workspaceId, required this.since});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['since'] = Variable<int>(since);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      workspaceId: Value(workspaceId),
      since: Value(since),
    );
  }

  factory SyncCursorsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorsData(
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      since: serializer.fromJson<int>(json['since']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspaceId': serializer.toJson<String>(workspaceId),
      'since': serializer.toJson<int>(since),
    };
  }

  SyncCursorsData copyWith({String? workspaceId, int? since}) =>
      SyncCursorsData(
        workspaceId: workspaceId ?? this.workspaceId,
        since: since ?? this.since,
      );
  SyncCursorsData copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursorsData(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      since: data.since.present ? data.since.value : this.since,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsData(')
          ..write('workspaceId: $workspaceId, ')
          ..write('since: $since')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workspaceId, since);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorsData &&
          other.workspaceId == this.workspaceId &&
          other.since == this.since);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursorsData> {
  final Value<String> workspaceId;
  final Value<int> since;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.workspaceId = const Value.absent(),
    this.since = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String workspaceId,
    required int since,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       since = Value(since);
  static Insertable<SyncCursorsData> custom({
    Expression<String>? workspaceId,
    Expression<int>? since,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (since != null) 'since': since,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? workspaceId,
    Value<int>? since,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      since: since ?? this.since,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (since.present) {
      map['since'] = Variable<int>(since.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('since: $since, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncFailures extends Table
    with TableInfo<SyncFailures, SyncFailuresData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncFailures(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<String> tableName_ = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tableName_,
    rowId,
    code,
    detail,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_failures';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncFailuresData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncFailuresData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tableName_: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  SyncFailures createAlias(String alias) {
    return SyncFailures(attachedDatabase, alias);
  }
}

class SyncFailuresData extends DataClass
    implements Insertable<SyncFailuresData> {
  final int id;
  final String tableName_;
  final String rowId;
  final String code;
  final String detail;
  final String createdAt;
  const SyncFailuresData({
    required this.id,
    required this.tableName_,
    required this.rowId,
    required this.code,
    required this.detail,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['table_name'] = Variable<String>(tableName_);
    map['row_id'] = Variable<String>(rowId);
    map['code'] = Variable<String>(code);
    map['detail'] = Variable<String>(detail);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SyncFailuresCompanion toCompanion(bool nullToAbsent) {
    return SyncFailuresCompanion(
      id: Value(id),
      tableName_: Value(tableName_),
      rowId: Value(rowId),
      code: Value(code),
      detail: Value(detail),
      createdAt: Value(createdAt),
    );
  }

  factory SyncFailuresData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncFailuresData(
      id: serializer.fromJson<int>(json['id']),
      tableName_: serializer.fromJson<String>(json['tableName_']),
      rowId: serializer.fromJson<String>(json['rowId']),
      code: serializer.fromJson<String>(json['code']),
      detail: serializer.fromJson<String>(json['detail']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tableName_': serializer.toJson<String>(tableName_),
      'rowId': serializer.toJson<String>(rowId),
      'code': serializer.toJson<String>(code),
      'detail': serializer.toJson<String>(detail),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  SyncFailuresData copyWith({
    int? id,
    String? tableName_,
    String? rowId,
    String? code,
    String? detail,
    String? createdAt,
  }) => SyncFailuresData(
    id: id ?? this.id,
    tableName_: tableName_ ?? this.tableName_,
    rowId: rowId ?? this.rowId,
    code: code ?? this.code,
    detail: detail ?? this.detail,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncFailuresData copyWithCompanion(SyncFailuresCompanion data) {
    return SyncFailuresData(
      id: data.id.present ? data.id.value : this.id,
      tableName_: data.tableName_.present
          ? data.tableName_.value
          : this.tableName_,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      code: data.code.present ? data.code.value : this.code,
      detail: data.detail.present ? data.detail.value : this.detail,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncFailuresData(')
          ..write('id: $id, ')
          ..write('tableName_: $tableName_, ')
          ..write('rowId: $rowId, ')
          ..write('code: $code, ')
          ..write('detail: $detail, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tableName_, rowId, code, detail, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncFailuresData &&
          other.id == this.id &&
          other.tableName_ == this.tableName_ &&
          other.rowId == this.rowId &&
          other.code == this.code &&
          other.detail == this.detail &&
          other.createdAt == this.createdAt);
}

class SyncFailuresCompanion extends UpdateCompanion<SyncFailuresData> {
  final Value<int> id;
  final Value<String> tableName_;
  final Value<String> rowId;
  final Value<String> code;
  final Value<String> detail;
  final Value<String> createdAt;
  const SyncFailuresCompanion({
    this.id = const Value.absent(),
    this.tableName_ = const Value.absent(),
    this.rowId = const Value.absent(),
    this.code = const Value.absent(),
    this.detail = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncFailuresCompanion.insert({
    this.id = const Value.absent(),
    required String tableName_,
    required String rowId,
    required String code,
    required String detail,
    required String createdAt,
  }) : tableName_ = Value(tableName_),
       rowId = Value(rowId),
       code = Value(code),
       detail = Value(detail),
       createdAt = Value(createdAt);
  static Insertable<SyncFailuresData> custom({
    Expression<int>? id,
    Expression<String>? tableName_,
    Expression<String>? rowId,
    Expression<String>? code,
    Expression<String>? detail,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableName_ != null) 'table_name': tableName_,
      if (rowId != null) 'row_id': rowId,
      if (code != null) 'code': code,
      if (detail != null) 'detail': detail,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncFailuresCompanion copyWith({
    Value<int>? id,
    Value<String>? tableName_,
    Value<String>? rowId,
    Value<String>? code,
    Value<String>? detail,
    Value<String>? createdAt,
  }) {
    return SyncFailuresCompanion(
      id: id ?? this.id,
      tableName_: tableName_ ?? this.tableName_,
      rowId: rowId ?? this.rowId,
      code: code ?? this.code,
      detail: detail ?? this.detail,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tableName_.present) {
      map['table_name'] = Variable<String>(tableName_.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncFailuresCompanion(')
          ..write('id: $id, ')
          ..write('tableName_: $tableName_, ')
          ..write('rowId: $rowId, ')
          ..write('code: $code, ')
          ..write('detail: $detail, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class Settings extends Table with TableInfo<Settings, SettingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Settings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const String $name = 'settings';
  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsData(
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
  Settings createAlias(String alias) {
    return Settings(attachedDatabase, alias);
  }
}

class SettingsData extends DataClass implements Insertable<SettingsData> {
  final String key;
  final String value;
  const SettingsData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsData(
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

  SettingsData copyWith({String? key, String? value}) =>
      SettingsData(key: key ?? this.key, value: value ?? this.value);
  SettingsData copyWithCompanion(SettingsCompanion data) {
    return SettingsData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsData(')
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
      (other is SettingsData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingsData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsData> custom({
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

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
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
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV1 extends GeneratedDatabase {
  DatabaseAtV1(QueryExecutor e) : super(e);
  late final Workspaces workspaces = Workspaces(this);
  late final Cashbooks cashbooks = Cashbooks(this);
  late final EntryCategories entryCategories = EntryCategories(this);
  late final PaymentMethods paymentMethods = PaymentMethods(this);
  late final Entries entries = Entries(this);
  late final CashbookMembers cashbookMembers = CashbookMembers(this);
  late final Accounts accounts = Accounts(this);
  late final Categories categories = Categories(this);
  late final Transactions transactions = Transactions(this);
  late final Budgets budgets = Budgets(this);
  late final Outbox outbox = Outbox(this);
  late final SyncCursors syncCursors = SyncCursors(this);
  late final SyncFailures syncFailures = SyncFailures(this);
  late final Settings settings = Settings(this);
  late final Index entriesBookDate = Index(
    'entries_book_date',
    'CREATE INDEX entries_book_date ON entries (cashbook_id, entry_date)',
  );
  late final Index transactionsAccountDate = Index(
    'transactions_account_date',
    'CREATE INDEX transactions_account_date ON transactions (account_id, occurred_on)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    cashbooks,
    entryCategories,
    paymentMethods,
    entries,
    cashbookMembers,
    accounts,
    categories,
    transactions,
    budgets,
    outbox,
    syncCursors,
    syncFailures,
    settings,
    entriesBookDate,
    transactionsAccountDate,
  ];
  @override
  int get schemaVersion => 1;
}
