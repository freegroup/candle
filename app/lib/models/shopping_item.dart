import 'dart:convert';

import 'package:flutter/widgets.dart';

class ShoppingItem {
  final int? id;
  final String name;
  final bool done;

  ShoppingItem({this.id, required this.name, this.done = false});

  ShoppingItem copyWith({
    ValueGetter<int?>? id,
    String? name,
    bool? done,
  }) {
    return ShoppingItem(
      id: id?.call() ?? this.id,
      name: name ?? this.name,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'done': done ? 1 : 0,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      done: map['done'] == 0 ? false : true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ShoppingItem.fromJson(String source) => ShoppingItem.fromMap(json.decode(source));

  @override
  String toString() => 'ShoppingItem(id: $id, name: $name, done: $done)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShoppingItem && other.id == id && other.name == name && other.done == done;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ done.hashCode;
}
