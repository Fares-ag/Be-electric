enum UserRole {
  requestor,
  technician,
  manager,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.requestor:
        return 'Requestor';
      case UserRole.technician:
        return 'Technician';
      case UserRole.manager:
        return 'Manager';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.requestor:
        return 'Can scan QR codes and request maintenance';
      case UserRole.technician:
        return 'Can view and complete assigned tasks';
      case UserRole.manager:
        return 'Full system access and user management';
      case UserRole.admin:
        return 'Full system access and user management';
    }
  }

  List<String> get permissions {
    switch (this) {
      case UserRole.requestor:
        return [
          'scan_qr_code',
          'request_maintenance',
          'view_own_requests',
        ];
      case UserRole.technician:
        return [
          'view_assigned_work_orders',
          'view_assigned_pm_tasks',
          'complete_work_orders',
          'complete_pm_tasks',
          'view_own_analytics',
          'update_task_status',
        ];
      case UserRole.manager:
        return [
          'view_all_work_orders',
          'view_all_pm_tasks',
          'create_work_orders',
          'create_pm_tasks',
          'assign_tasks',
          'create_technician_accounts',
          'view_all_analytics',
          'manage_users',
          'system_settings',
        ];
      case UserRole.admin:
        return [
          'view_all_work_orders',
          'view_all_pm_tasks',
          'create_work_orders',
          'create_pm_tasks',
          'assign_tasks',
          'create_technician_accounts',
          'view_all_analytics',
          'manage_users',
          'system_settings',
        ];
    }
  }
}
