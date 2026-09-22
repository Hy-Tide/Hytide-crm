// lib/features/users/providers/user_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/models/user_model.dart';
import '../../auth/repositories/auth_repository.dart';

enum UserViewMode { table, grid }

enum UserRoleFilter {
  all('All Roles'),
  admin('Admins'),
  manager('Managers'),
  salesStaff('Sales Staff');

  final String label;
  const UserRoleFilter(this.label);
}

enum UserStatusFilter {
  all('All Statuses'),
  active('Active'),
  inactive('Inactive');

  final String label;
  const UserStatusFilter(this.label);
}

class UserKpiData {
  final int totalCount;
  final int adminCount;
  final int managerCount;
  final int salesStaffCount;
  final int activeCount;

  const UserKpiData({
    this.totalCount = 0,
    this.adminCount = 0,
    this.managerCount = 0,
    this.salesStaffCount = 0,
    this.activeCount = 0,
  });
}

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(authRepositoryProvider).streamAllUsers();
});

final userSearchQueryProvider = StateProvider<String>((ref) => '');
final userRoleFilterProvider = StateProvider<UserRoleFilter>((ref) => UserRoleFilter.all);
final userStatusFilterProvider = StateProvider<UserStatusFilter>((ref) => UserStatusFilter.all);
final userViewModeProvider = StateProvider<UserViewMode>((ref) => UserViewMode.table);

final userKpiProvider = Provider<UserKpiData>((ref) {
  final users = ref.watch(allUsersProvider).asData?.value ?? [];

  int admins = 0;
  int managers = 0;
  int sales = 0;
  int active = 0;

  for (final user in users) {
    if (user.isActive) active++;
    switch (user.role) {
      case UserRole.admin:
        admins++;
        break;
      case UserRole.manager:
        managers++;
        break;
      case UserRole.salesStaff:
        sales++;
        break;
    }
  }

  return UserKpiData(
    totalCount: users.length,
    adminCount: admins,
    managerCount: managers,
    salesStaffCount: sales,
    activeCount: active,
  );
});

final filteredUsersProvider = Provider<List<UserModel>>((ref) {
  final users = ref.watch(allUsersProvider).asData?.value ?? [];
  final query = ref.watch(userSearchQueryProvider).trim().toLowerCase();
  final roleFilter = ref.watch(userRoleFilterProvider);
  final statusFilter = ref.watch(userStatusFilterProvider);

  return users.where((user) {
    // Search filter
    if (query.isNotEmpty) {
      final nameMatches = user.displayName.toLowerCase().contains(query);
      final emailMatches = user.email.toLowerCase().contains(query);
      if (!nameMatches && !emailMatches) return false;
    }

    // Role filter
    if (roleFilter != UserRoleFilter.all) {
      switch (roleFilter) {
        case UserRoleFilter.admin:
          if (user.role != UserRole.admin) return false;
          break;
        case UserRoleFilter.manager:
          if (user.role != UserRole.manager) return false;
          break;
        case UserRoleFilter.salesStaff:
          if (user.role != UserRole.salesStaff) return false;
          break;
        case UserRoleFilter.all:
          break;
      }
    }

    // Status filter
    if (statusFilter != UserStatusFilter.all) {
      switch (statusFilter) {
        case UserStatusFilter.active:
          if (!user.isActive) return false;
          break;
        case UserStatusFilter.inactive:
          if (user.isActive) return false;
          break;
        case UserStatusFilter.all:
          break;
      }
    }

    return true;
  }).toList();
});
