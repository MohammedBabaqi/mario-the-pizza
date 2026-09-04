import 'package:equatable/equatable.dart';

/// Represents an authenticated user.
class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final String? phoneNumber;
  final String? defaultAddress;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.phoneNumber,
    this.defaultAddress,
  });

  static final empty = UserModel(
    uid: '',
    email: '',
    displayName: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;
  String get name => displayName;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      phoneNumber: json['phoneNumber'] as String?,
      defaultAddress: json['defaultAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'phoneNumber': phoneNumber,
      'defaultAddress': defaultAddress,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    String? phoneNumber,
    String? defaultAddress,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      defaultAddress: defaultAddress ?? this.defaultAddress,
    );
  }

  @override
  List<Object?> get props => [
        uid, email, displayName, photoUrl,
        createdAt, phoneNumber, defaultAddress,
      ];
}
