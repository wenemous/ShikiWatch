import 'package:dio/dio.dart';

import '../../domain/models/user_friend.dart';
import '../../domain/models/user_profile.dart';

abstract class ProfileRepository {
  const ProfileRepository();

  Future<UserProfile> getUserProfile({
    required String? id,
    String? userToken,
    CancelToken? cancelToken,
  });

  Future<Iterable<UserFriend>> getUserFriends({
    required String? id,
    CancelToken? cancelToken,
  });
}
