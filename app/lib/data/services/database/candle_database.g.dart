// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_database.dart';

// ignore_for_file: type=lint
class $LocationsTable extends Locations
    with TableInfo<$LocationsTable, LocationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _formattedAddressMeta = const VerificationMeta(
    'formattedAddress',
  );
  @override
  late final GeneratedColumn<String> formattedAddress = GeneratedColumn<String>(
    'formatted_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _streetMeta = const VerificationMeta('street');
  @override
  late final GeneratedColumn<String> street = GeneratedColumn<String>(
    'street',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _zipMeta = const VerificationMeta('zip');
  @override
  late final GeneratedColumn<String> zip = GeneratedColumn<String>(
    'zip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    formattedAddress,
    street,
    number,
    zip,
    city,
    country,
    lat,
    lon,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationRow> instance, {
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
    if (data.containsKey('formatted_address')) {
      context.handle(
        _formattedAddressMeta,
        formattedAddress.isAcceptableOrUnknown(
          data['formatted_address']!,
          _formattedAddressMeta,
        ),
      );
    }
    if (data.containsKey('street')) {
      context.handle(
        _streetMeta,
        street.isAcceptableOrUnknown(data['street']!, _streetMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('zip')) {
      context.handle(
        _zipMeta,
        zip.isAcceptableOrUnknown(data['zip']!, _zipMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      formattedAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formatted_address'],
      )!,
      street: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}street'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      zip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zip'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
    );
  }

  @override
  $LocationsTable createAlias(String alias) {
    return $LocationsTable(attachedDatabase, alias);
  }
}

class LocationRow extends DataClass implements Insertable<LocationRow> {
  final int id;
  final String name;
  final String formattedAddress;
  final String street;
  final String number;
  final String zip;
  final String city;
  final String country;
  final double lat;
  final double lon;
  const LocationRow({
    required this.id,
    required this.name,
    required this.formattedAddress,
    required this.street,
    required this.number,
    required this.zip,
    required this.city,
    required this.country,
    required this.lat,
    required this.lon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['formatted_address'] = Variable<String>(formattedAddress);
    map['street'] = Variable<String>(street);
    map['number'] = Variable<String>(number);
    map['zip'] = Variable<String>(zip);
    map['city'] = Variable<String>(city);
    map['country'] = Variable<String>(country);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    return map;
  }

  LocationsCompanion toCompanion(bool nullToAbsent) {
    return LocationsCompanion(
      id: Value(id),
      name: Value(name),
      formattedAddress: Value(formattedAddress),
      street: Value(street),
      number: Value(number),
      zip: Value(zip),
      city: Value(city),
      country: Value(country),
      lat: Value(lat),
      lon: Value(lon),
    );
  }

  factory LocationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      formattedAddress: serializer.fromJson<String>(json['formattedAddress']),
      street: serializer.fromJson<String>(json['street']),
      number: serializer.fromJson<String>(json['number']),
      zip: serializer.fromJson<String>(json['zip']),
      city: serializer.fromJson<String>(json['city']),
      country: serializer.fromJson<String>(json['country']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'formattedAddress': serializer.toJson<String>(formattedAddress),
      'street': serializer.toJson<String>(street),
      'number': serializer.toJson<String>(number),
      'zip': serializer.toJson<String>(zip),
      'city': serializer.toJson<String>(city),
      'country': serializer.toJson<String>(country),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
    };
  }

  LocationRow copyWith({
    int? id,
    String? name,
    String? formattedAddress,
    String? street,
    String? number,
    String? zip,
    String? city,
    String? country,
    double? lat,
    double? lon,
  }) => LocationRow(
    id: id ?? this.id,
    name: name ?? this.name,
    formattedAddress: formattedAddress ?? this.formattedAddress,
    street: street ?? this.street,
    number: number ?? this.number,
    zip: zip ?? this.zip,
    city: city ?? this.city,
    country: country ?? this.country,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
  );
  LocationRow copyWithCompanion(LocationsCompanion data) {
    return LocationRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      formattedAddress: data.formattedAddress.present
          ? data.formattedAddress.value
          : this.formattedAddress,
      street: data.street.present ? data.street.value : this.street,
      number: data.number.present ? data.number.value : this.number,
      zip: data.zip.present ? data.zip.value : this.zip,
      city: data.city.present ? data.city.value : this.city,
      country: data.country.present ? data.country.value : this.country,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('formattedAddress: $formattedAddress, ')
          ..write('street: $street, ')
          ..write('number: $number, ')
          ..write('zip: $zip, ')
          ..write('city: $city, ')
          ..write('country: $country, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    formattedAddress,
    street,
    number,
    zip,
    city,
    country,
    lat,
    lon,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.formattedAddress == this.formattedAddress &&
          other.street == this.street &&
          other.number == this.number &&
          other.zip == this.zip &&
          other.city == this.city &&
          other.country == this.country &&
          other.lat == this.lat &&
          other.lon == this.lon);
}

class LocationsCompanion extends UpdateCompanion<LocationRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> formattedAddress;
  final Value<String> street;
  final Value<String> number;
  final Value<String> zip;
  final Value<String> city;
  final Value<String> country;
  final Value<double> lat;
  final Value<double> lon;
  const LocationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.formattedAddress = const Value.absent(),
    this.street = const Value.absent(),
    this.number = const Value.absent(),
    this.zip = const Value.absent(),
    this.city = const Value.absent(),
    this.country = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
  });
  LocationsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.formattedAddress = const Value.absent(),
    this.street = const Value.absent(),
    this.number = const Value.absent(),
    this.zip = const Value.absent(),
    this.city = const Value.absent(),
    this.country = const Value.absent(),
    required double lat,
    required double lon,
  }) : name = Value(name),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<LocationRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? formattedAddress,
    Expression<String>? street,
    Expression<String>? number,
    Expression<String>? zip,
    Expression<String>? city,
    Expression<String>? country,
    Expression<double>? lat,
    Expression<double>? lon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (formattedAddress != null) 'formatted_address': formattedAddress,
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (zip != null) 'zip': zip,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
    });
  }

  LocationsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? formattedAddress,
    Value<String>? street,
    Value<String>? number,
    Value<String>? zip,
    Value<String>? city,
    Value<String>? country,
    Value<double>? lat,
    Value<double>? lon,
  }) {
    return LocationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      street: street ?? this.street,
      number: number ?? this.number,
      zip: zip ?? this.zip,
      city: city ?? this.city,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
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
    if (formattedAddress.present) {
      map['formatted_address'] = Variable<String>(formattedAddress.value);
    }
    if (street.present) {
      map['street'] = Variable<String>(street.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (zip.present) {
      map['zip'] = Variable<String>(zip.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('formattedAddress: $formattedAddress, ')
          ..write('street: $street, ')
          ..write('number: $number, ')
          ..write('zip: $zip, ')
          ..write('city: $city, ')
          ..write('country: $country, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon')
          ..write(')'))
        .toString();
  }
}

class $VoicePinsTable extends VoicePins
    with TableInfo<$VoicePinsTable, VoicePinRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoicePinsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, memo, lat, lon, created];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoicePinRow> instance, {
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
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoicePinRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoicePinRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      )!,
    );
  }

  @override
  $VoicePinsTable createAlias(String alias) {
    return $VoicePinsTable(attachedDatabase, alias);
  }
}

class VoicePinRow extends DataClass implements Insertable<VoicePinRow> {
  final int id;
  final String name;
  final String memo;
  final double lat;
  final double lon;
  final DateTime created;
  const VoicePinRow({
    required this.id,
    required this.name,
    required this.memo,
    required this.lat,
    required this.lon,
    required this.created,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['memo'] = Variable<String>(memo);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['created'] = Variable<DateTime>(created);
    return map;
  }

  VoicePinsCompanion toCompanion(bool nullToAbsent) {
    return VoicePinsCompanion(
      id: Value(id),
      name: Value(name),
      memo: Value(memo),
      lat: Value(lat),
      lon: Value(lon),
      created: Value(created),
    );
  }

  factory VoicePinRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoicePinRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      memo: serializer.fromJson<String>(json['memo']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      created: serializer.fromJson<DateTime>(json['created']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'memo': serializer.toJson<String>(memo),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'created': serializer.toJson<DateTime>(created),
    };
  }

  VoicePinRow copyWith({
    int? id,
    String? name,
    String? memo,
    double? lat,
    double? lon,
    DateTime? created,
  }) => VoicePinRow(
    id: id ?? this.id,
    name: name ?? this.name,
    memo: memo ?? this.memo,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    created: created ?? this.created,
  );
  VoicePinRow copyWithCompanion(VoicePinsCompanion data) {
    return VoicePinRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      memo: data.memo.present ? data.memo.value : this.memo,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      created: data.created.present ? data.created.value : this.created,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoicePinRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('memo: $memo, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, memo, lat, lon, created);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoicePinRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.memo == this.memo &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.created == this.created);
}

class VoicePinsCompanion extends UpdateCompanion<VoicePinRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> memo;
  final Value<double> lat;
  final Value<double> lon;
  final Value<DateTime> created;
  const VoicePinsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.memo = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.created = const Value.absent(),
  });
  VoicePinsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.memo = const Value.absent(),
    required double lat,
    required double lon,
    this.created = const Value.absent(),
  }) : name = Value(name),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<VoicePinRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? memo,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<DateTime>? created,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (memo != null) 'memo': memo,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (created != null) 'created': created,
    });
  }

  VoicePinsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? memo,
    Value<double>? lat,
    Value<double>? lon,
    Value<DateTime>? created,
  }) {
    return VoicePinsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      created: created ?? this.created,
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
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoicePinsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('memo: $memo, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }
}

class $RoutesTable extends Routes with TableInfo<$RoutesTable, RouteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutesTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _annotationMeta = const VerificationMeta(
    'annotation',
  );
  @override
  late final GeneratedColumn<String> annotation = GeneratedColumn<String>(
    'annotation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, annotation, created];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteRow> instance, {
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
    if (data.containsKey('annotation')) {
      context.handle(
        _annotationMeta,
        annotation.isAcceptableOrUnknown(data['annotation']!, _annotationMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RouteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      annotation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotation'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      )!,
    );
  }

  @override
  $RoutesTable createAlias(String alias) {
    return $RoutesTable(attachedDatabase, alias);
  }
}

class RouteRow extends DataClass implements Insertable<RouteRow> {
  final int id;
  final String name;
  final String annotation;
  final DateTime created;
  const RouteRow({
    required this.id,
    required this.name,
    required this.annotation,
    required this.created,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['annotation'] = Variable<String>(annotation);
    map['created'] = Variable<DateTime>(created);
    return map;
  }

  RoutesCompanion toCompanion(bool nullToAbsent) {
    return RoutesCompanion(
      id: Value(id),
      name: Value(name),
      annotation: Value(annotation),
      created: Value(created),
    );
  }

  factory RouteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      annotation: serializer.fromJson<String>(json['annotation']),
      created: serializer.fromJson<DateTime>(json['created']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'annotation': serializer.toJson<String>(annotation),
      'created': serializer.toJson<DateTime>(created),
    };
  }

  RouteRow copyWith({
    int? id,
    String? name,
    String? annotation,
    DateTime? created,
  }) => RouteRow(
    id: id ?? this.id,
    name: name ?? this.name,
    annotation: annotation ?? this.annotation,
    created: created ?? this.created,
  );
  RouteRow copyWithCompanion(RoutesCompanion data) {
    return RouteRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      annotation: data.annotation.present
          ? data.annotation.value
          : this.annotation,
      created: data.created.present ? data.created.value : this.created,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('annotation: $annotation, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, annotation, created);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.annotation == this.annotation &&
          other.created == this.created);
}

class RoutesCompanion extends UpdateCompanion<RouteRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> annotation;
  final Value<DateTime> created;
  const RoutesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.annotation = const Value.absent(),
    this.created = const Value.absent(),
  });
  RoutesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.annotation = const Value.absent(),
    this.created = const Value.absent(),
  }) : name = Value(name);
  static Insertable<RouteRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? annotation,
    Expression<DateTime>? created,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (annotation != null) 'annotation': annotation,
      if (created != null) 'created': created,
    });
  }

  RoutesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? annotation,
    Value<DateTime>? created,
  }) {
    return RoutesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      annotation: annotation ?? this.annotation,
      created: created ?? this.created,
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
    if (annotation.present) {
      map['annotation'] = Variable<String>(annotation.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('annotation: $annotation, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }
}

class $RoutePointsTable extends RoutePoints
    with TableInfo<$RoutePointsTable, RoutePointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutePointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<int> routeId = GeneratedColumn<int>(
    'route_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routes (id) ON DELETE CASCADE',
    ),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annotationMeta = const VerificationMeta(
    'annotation',
  );
  @override
  late final GeneratedColumn<String> annotation = GeneratedColumn<String>(
    'annotation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    routeId,
    position,
    lat,
    lon,
    annotation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'route_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoutePointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('annotation')) {
      context.handle(
        _annotationMeta,
        annotation.isAcceptableOrUnknown(data['annotation']!, _annotationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutePointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutePointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}route_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      annotation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotation'],
      )!,
    );
  }

  @override
  $RoutePointsTable createAlias(String alias) {
    return $RoutePointsTable(attachedDatabase, alias);
  }
}

class RoutePointRow extends DataClass implements Insertable<RoutePointRow> {
  final int id;
  final int routeId;
  final int position;
  final double lat;
  final double lon;
  final String annotation;
  const RoutePointRow({
    required this.id,
    required this.routeId,
    required this.position,
    required this.lat,
    required this.lon,
    required this.annotation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['route_id'] = Variable<int>(routeId);
    map['position'] = Variable<int>(position);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['annotation'] = Variable<String>(annotation);
    return map;
  }

  RoutePointsCompanion toCompanion(bool nullToAbsent) {
    return RoutePointsCompanion(
      id: Value(id),
      routeId: Value(routeId),
      position: Value(position),
      lat: Value(lat),
      lon: Value(lon),
      annotation: Value(annotation),
    );
  }

  factory RoutePointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutePointRow(
      id: serializer.fromJson<int>(json['id']),
      routeId: serializer.fromJson<int>(json['routeId']),
      position: serializer.fromJson<int>(json['position']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      annotation: serializer.fromJson<String>(json['annotation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'routeId': serializer.toJson<int>(routeId),
      'position': serializer.toJson<int>(position),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'annotation': serializer.toJson<String>(annotation),
    };
  }

  RoutePointRow copyWith({
    int? id,
    int? routeId,
    int? position,
    double? lat,
    double? lon,
    String? annotation,
  }) => RoutePointRow(
    id: id ?? this.id,
    routeId: routeId ?? this.routeId,
    position: position ?? this.position,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    annotation: annotation ?? this.annotation,
  );
  RoutePointRow copyWithCompanion(RoutePointsCompanion data) {
    return RoutePointRow(
      id: data.id.present ? data.id.value : this.id,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      position: data.position.present ? data.position.value : this.position,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      annotation: data.annotation.present
          ? data.annotation.value
          : this.annotation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutePointRow(')
          ..write('id: $id, ')
          ..write('routeId: $routeId, ')
          ..write('position: $position, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('annotation: $annotation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, routeId, position, lat, lon, annotation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutePointRow &&
          other.id == this.id &&
          other.routeId == this.routeId &&
          other.position == this.position &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.annotation == this.annotation);
}

class RoutePointsCompanion extends UpdateCompanion<RoutePointRow> {
  final Value<int> id;
  final Value<int> routeId;
  final Value<int> position;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> annotation;
  const RoutePointsCompanion({
    this.id = const Value.absent(),
    this.routeId = const Value.absent(),
    this.position = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.annotation = const Value.absent(),
  });
  RoutePointsCompanion.insert({
    this.id = const Value.absent(),
    required int routeId,
    required int position,
    required double lat,
    required double lon,
    this.annotation = const Value.absent(),
  }) : routeId = Value(routeId),
       position = Value(position),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<RoutePointRow> custom({
    Expression<int>? id,
    Expression<int>? routeId,
    Expression<int>? position,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? annotation,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routeId != null) 'route_id': routeId,
      if (position != null) 'position': position,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (annotation != null) 'annotation': annotation,
    });
  }

  RoutePointsCompanion copyWith({
    Value<int>? id,
    Value<int>? routeId,
    Value<int>? position,
    Value<double>? lat,
    Value<double>? lon,
    Value<String>? annotation,
  }) {
    return RoutePointsCompanion(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      position: position ?? this.position,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      annotation: annotation ?? this.annotation,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<int>(routeId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (annotation.present) {
      map['annotation'] = Variable<String>(annotation.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutePointsCompanion(')
          ..write('id: $id, ')
          ..write('routeId: $routeId, ')
          ..write('position: $position, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('annotation: $annotation')
          ..write(')'))
        .toString();
  }
}

abstract class _$CandleDatabase extends GeneratedDatabase {
  _$CandleDatabase(QueryExecutor e) : super(e);
  $CandleDatabaseManager get managers => $CandleDatabaseManager(this);
  late final $LocationsTable locations = $LocationsTable(this);
  late final $VoicePinsTable voicePins = $VoicePinsTable(this);
  late final $RoutesTable routes = $RoutesTable(this);
  late final $RoutePointsTable routePoints = $RoutePointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    locations,
    voicePins,
    routes,
    routePoints,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'routes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('route_points', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LocationsTableCreateCompanionBuilder =
    LocationsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> formattedAddress,
      Value<String> street,
      Value<String> number,
      Value<String> zip,
      Value<String> city,
      Value<String> country,
      required double lat,
      required double lon,
    });
typedef $$LocationsTableUpdateCompanionBuilder =
    LocationsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> formattedAddress,
      Value<String> street,
      Value<String> number,
      Value<String> zip,
      Value<String> city,
      Value<String> country,
      Value<double> lat,
      Value<double> lon,
    });

class $$LocationsTableFilterComposer
    extends Composer<_$CandleDatabase, $LocationsTable> {
  $$LocationsTableFilterComposer({
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

  ColumnFilters<String> get formattedAddress => $composableBuilder(
    column: $table.formattedAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zip => $composableBuilder(
    column: $table.zip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationsTableOrderingComposer
    extends Composer<_$CandleDatabase, $LocationsTable> {
  $$LocationsTableOrderingComposer({
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

  ColumnOrderings<String> get formattedAddress => $composableBuilder(
    column: $table.formattedAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zip => $composableBuilder(
    column: $table.zip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationsTableAnnotationComposer
    extends Composer<_$CandleDatabase, $LocationsTable> {
  $$LocationsTableAnnotationComposer({
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

  GeneratedColumn<String> get formattedAddress => $composableBuilder(
    column: $table.formattedAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get street =>
      $composableBuilder(column: $table.street, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get zip =>
      $composableBuilder(column: $table.zip, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);
}

class $$LocationsTableTableManager
    extends
        RootTableManager<
          _$CandleDatabase,
          $LocationsTable,
          LocationRow,
          $$LocationsTableFilterComposer,
          $$LocationsTableOrderingComposer,
          $$LocationsTableAnnotationComposer,
          $$LocationsTableCreateCompanionBuilder,
          $$LocationsTableUpdateCompanionBuilder,
          (
            LocationRow,
            BaseReferences<_$CandleDatabase, $LocationsTable, LocationRow>,
          ),
          LocationRow,
          PrefetchHooks Function()
        > {
  $$LocationsTableTableManager(_$CandleDatabase db, $LocationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> formattedAddress = const Value.absent(),
                Value<String> street = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> zip = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> country = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
              }) => LocationsCompanion(
                id: id,
                name: name,
                formattedAddress: formattedAddress,
                street: street,
                number: number,
                zip: zip,
                city: city,
                country: country,
                lat: lat,
                lon: lon,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> formattedAddress = const Value.absent(),
                Value<String> street = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> zip = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> country = const Value.absent(),
                required double lat,
                required double lon,
              }) => LocationsCompanion.insert(
                id: id,
                name: name,
                formattedAddress: formattedAddress,
                street: street,
                number: number,
                zip: zip,
                city: city,
                country: country,
                lat: lat,
                lon: lon,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocationsTable, LocationRow>(table),
                  BaseReferences<
                    _$CandleDatabase,
                    $LocationsTable,
                    LocationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$CandleDatabase,
      $LocationsTable,
      LocationRow,
      $$LocationsTableFilterComposer,
      $$LocationsTableOrderingComposer,
      $$LocationsTableAnnotationComposer,
      $$LocationsTableCreateCompanionBuilder,
      $$LocationsTableUpdateCompanionBuilder,
      (
        LocationRow,
        BaseReferences<_$CandleDatabase, $LocationsTable, LocationRow>,
      ),
      LocationRow,
      PrefetchHooks Function()
    >;
typedef $$VoicePinsTableCreateCompanionBuilder =
    VoicePinsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> memo,
      required double lat,
      required double lon,
      Value<DateTime> created,
    });
typedef $$VoicePinsTableUpdateCompanionBuilder =
    VoicePinsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> memo,
      Value<double> lat,
      Value<double> lon,
      Value<DateTime> created,
    });

class $$VoicePinsTableFilterComposer
    extends Composer<_$CandleDatabase, $VoicePinsTable> {
  $$VoicePinsTableFilterComposer({
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

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoicePinsTableOrderingComposer
    extends Composer<_$CandleDatabase, $VoicePinsTable> {
  $$VoicePinsTableOrderingComposer({
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

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoicePinsTableAnnotationComposer
    extends Composer<_$CandleDatabase, $VoicePinsTable> {
  $$VoicePinsTableAnnotationComposer({
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

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);
}

class $$VoicePinsTableTableManager
    extends
        RootTableManager<
          _$CandleDatabase,
          $VoicePinsTable,
          VoicePinRow,
          $$VoicePinsTableFilterComposer,
          $$VoicePinsTableOrderingComposer,
          $$VoicePinsTableAnnotationComposer,
          $$VoicePinsTableCreateCompanionBuilder,
          $$VoicePinsTableUpdateCompanionBuilder,
          (
            VoicePinRow,
            BaseReferences<_$CandleDatabase, $VoicePinsTable, VoicePinRow>,
          ),
          VoicePinRow,
          PrefetchHooks Function()
        > {
  $$VoicePinsTableTableManager(_$CandleDatabase db, $VoicePinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoicePinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoicePinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoicePinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
              }) => VoicePinsCompanion(
                id: id,
                name: name,
                memo: memo,
                lat: lat,
                lon: lon,
                created: created,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> memo = const Value.absent(),
                required double lat,
                required double lon,
                Value<DateTime> created = const Value.absent(),
              }) => VoicePinsCompanion.insert(
                id: id,
                name: name,
                memo: memo,
                lat: lat,
                lon: lon,
                created: created,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VoicePinsTable, VoicePinRow>(table),
                  BaseReferences<
                    _$CandleDatabase,
                    $VoicePinsTable,
                    VoicePinRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoicePinsTableProcessedTableManager =
    ProcessedTableManager<
      _$CandleDatabase,
      $VoicePinsTable,
      VoicePinRow,
      $$VoicePinsTableFilterComposer,
      $$VoicePinsTableOrderingComposer,
      $$VoicePinsTableAnnotationComposer,
      $$VoicePinsTableCreateCompanionBuilder,
      $$VoicePinsTableUpdateCompanionBuilder,
      (
        VoicePinRow,
        BaseReferences<_$CandleDatabase, $VoicePinsTable, VoicePinRow>,
      ),
      VoicePinRow,
      PrefetchHooks Function()
    >;
typedef $$RoutesTableCreateCompanionBuilder =
    RoutesCompanion Function({
      Value<int> id,
      required String name,
      Value<String> annotation,
      Value<DateTime> created,
    });
typedef $$RoutesTableUpdateCompanionBuilder =
    RoutesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> annotation,
      Value<DateTime> created,
    });

final class $$RoutesTableReferences
    extends BaseReferences<_$CandleDatabase, $RoutesTable, RouteRow> {
  $$RoutesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutePointsTable, List<RoutePointRow>>
  _routePointsRefsTable(_$CandleDatabase db) => MultiTypedResultKey.fromTable(
    db.routePoints,
    aliasName: 'routes__id__route_points__route_id',
  );

  $$RoutePointsTableProcessedTableManager get routePointsRefs {
    final manager = $$RoutePointsTableTableManager(
      $_db,
      $_db.routePoints,
    ).filter((f) => f.routeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_routePointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoutesTableFilterComposer
    extends Composer<_$CandleDatabase, $RoutesTable> {
  $$RoutesTableFilterComposer({
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

  ColumnFilters<String> get annotation => $composableBuilder(
    column: $table.annotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routePointsRefs(
    Expression<bool> Function($$RoutePointsTableFilterComposer f) f,
  ) {
    final $$RoutePointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routePoints,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutePointsTableFilterComposer(
            $db: $db,
            $table: $db.routePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutesTableOrderingComposer
    extends Composer<_$CandleDatabase, $RoutesTable> {
  $$RoutesTableOrderingComposer({
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

  ColumnOrderings<String> get annotation => $composableBuilder(
    column: $table.annotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoutesTableAnnotationComposer
    extends Composer<_$CandleDatabase, $RoutesTable> {
  $$RoutesTableAnnotationComposer({
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

  GeneratedColumn<String> get annotation => $composableBuilder(
    column: $table.annotation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  Expression<T> routePointsRefs<T extends Object>(
    Expression<T> Function($$RoutePointsTableAnnotationComposer a) f,
  ) {
    final $$RoutePointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routePoints,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutePointsTableAnnotationComposer(
            $db: $db,
            $table: $db.routePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutesTableTableManager
    extends
        RootTableManager<
          _$CandleDatabase,
          $RoutesTable,
          RouteRow,
          $$RoutesTableFilterComposer,
          $$RoutesTableOrderingComposer,
          $$RoutesTableAnnotationComposer,
          $$RoutesTableCreateCompanionBuilder,
          $$RoutesTableUpdateCompanionBuilder,
          (RouteRow, $$RoutesTableReferences),
          RouteRow,
          PrefetchHooks Function({bool routePointsRefs})
        > {
  $$RoutesTableTableManager(_$CandleDatabase db, $RoutesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> annotation = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
              }) => RoutesCompanion(
                id: id,
                name: name,
                annotation: annotation,
                created: created,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> annotation = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
              }) => RoutesCompanion.insert(
                id: id,
                name: name,
                annotation: annotation,
                created: created,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RoutesTable, RouteRow>(table),
                  $$RoutesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routePointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (routePointsRefs) db.routePoints],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routePointsRefs)
                    await $_getPrefetchedData<
                      RouteRow,
                      $RoutesTable,
                      RoutePointRow
                    >(
                      currentTable: table,
                      referencedTable: $$RoutesTableReferences
                          ._routePointsRefsTable(db),
                      managerFromTypedResult: (p0) => $$RoutesTableReferences(
                        db,
                        table,
                        p0,
                      ).routePointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.routeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoutesTableProcessedTableManager =
    ProcessedTableManager<
      _$CandleDatabase,
      $RoutesTable,
      RouteRow,
      $$RoutesTableFilterComposer,
      $$RoutesTableOrderingComposer,
      $$RoutesTableAnnotationComposer,
      $$RoutesTableCreateCompanionBuilder,
      $$RoutesTableUpdateCompanionBuilder,
      (RouteRow, $$RoutesTableReferences),
      RouteRow,
      PrefetchHooks Function({bool routePointsRefs})
    >;
typedef $$RoutePointsTableCreateCompanionBuilder =
    RoutePointsCompanion Function({
      Value<int> id,
      required int routeId,
      required int position,
      required double lat,
      required double lon,
      Value<String> annotation,
    });
typedef $$RoutePointsTableUpdateCompanionBuilder =
    RoutePointsCompanion Function({
      Value<int> id,
      Value<int> routeId,
      Value<int> position,
      Value<double> lat,
      Value<double> lon,
      Value<String> annotation,
    });

final class $$RoutePointsTableReferences
    extends BaseReferences<_$CandleDatabase, $RoutePointsTable, RoutePointRow> {
  $$RoutePointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoutesTable _routeIdTable(_$CandleDatabase db) =>
      db.routes.createAlias('route_points__route_id__routes__id');

  $$RoutesTableProcessedTableManager get routeId {
    final $_column = $_itemColumn<int>('route_id')!;

    final manager = $$RoutesTableTableManager(
      $_db,
      $_db.routes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RoutePointsTableFilterComposer
    extends Composer<_$CandleDatabase, $RoutePointsTable> {
  $$RoutePointsTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annotation => $composableBuilder(
    column: $table.annotation,
    builder: (column) => ColumnFilters(column),
  );

  $$RoutesTableFilterComposer get routeId {
    final $$RoutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutesTableFilterComposer(
            $db: $db,
            $table: $db.routes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutePointsTableOrderingComposer
    extends Composer<_$CandleDatabase, $RoutePointsTable> {
  $$RoutePointsTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annotation => $composableBuilder(
    column: $table.annotation,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoutesTableOrderingComposer get routeId {
    final $$RoutesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutesTableOrderingComposer(
            $db: $db,
            $table: $db.routes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutePointsTableAnnotationComposer
    extends Composer<_$CandleDatabase, $RoutePointsTable> {
  $$RoutePointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get annotation => $composableBuilder(
    column: $table.annotation,
    builder: (column) => column,
  );

  $$RoutesTableAnnotationComposer get routeId {
    final $$RoutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutesTableAnnotationComposer(
            $db: $db,
            $table: $db.routes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutePointsTableTableManager
    extends
        RootTableManager<
          _$CandleDatabase,
          $RoutePointsTable,
          RoutePointRow,
          $$RoutePointsTableFilterComposer,
          $$RoutePointsTableOrderingComposer,
          $$RoutePointsTableAnnotationComposer,
          $$RoutePointsTableCreateCompanionBuilder,
          $$RoutePointsTableUpdateCompanionBuilder,
          (RoutePointRow, $$RoutePointsTableReferences),
          RoutePointRow,
          PrefetchHooks Function({bool routeId})
        > {
  $$RoutePointsTableTableManager(_$CandleDatabase db, $RoutePointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutePointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutePointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutePointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> routeId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<String> annotation = const Value.absent(),
              }) => RoutePointsCompanion(
                id: id,
                routeId: routeId,
                position: position,
                lat: lat,
                lon: lon,
                annotation: annotation,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int routeId,
                required int position,
                required double lat,
                required double lon,
                Value<String> annotation = const Value.absent(),
              }) => RoutePointsCompanion.insert(
                id: id,
                routeId: routeId,
                position: position,
                lat: lat,
                lon: lon,
                annotation: annotation,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RoutePointsTable, RoutePointRow>(table),
                  $$RoutePointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routeId = false}) {
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
                    if (routeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.routeId,
                                referencedTable: $$RoutePointsTableReferences
                                    ._routeIdTable(db),
                                referencedColumn: $$RoutePointsTableReferences
                                    ._routeIdTable(db)
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

typedef $$RoutePointsTableProcessedTableManager =
    ProcessedTableManager<
      _$CandleDatabase,
      $RoutePointsTable,
      RoutePointRow,
      $$RoutePointsTableFilterComposer,
      $$RoutePointsTableOrderingComposer,
      $$RoutePointsTableAnnotationComposer,
      $$RoutePointsTableCreateCompanionBuilder,
      $$RoutePointsTableUpdateCompanionBuilder,
      (RoutePointRow, $$RoutePointsTableReferences),
      RoutePointRow,
      PrefetchHooks Function({bool routeId})
    >;

class $CandleDatabaseManager {
  final _$CandleDatabase _db;
  $CandleDatabaseManager(this._db);
  $$LocationsTableTableManager get locations =>
      $$LocationsTableTableManager(_db, _db.locations);
  $$VoicePinsTableTableManager get voicePins =>
      $$VoicePinsTableTableManager(_db, _db.voicePins);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db, _db.routes);
  $$RoutePointsTableTableManager get routePoints =>
      $$RoutePointsTableTableManager(_db, _db.routePoints);
}
