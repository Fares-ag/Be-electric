// Test Data Fixtures

import 'dart:convert';

import 'package:qauto_cmms/models/asset.dart';
import 'package:qauto_cmms/models/inventory_item.dart';
import 'package:qauto_cmms/models/pm_task.dart';
import 'package:qauto_cmms/models/user.dart';
import 'package:qauto_cmms/models/work_order.dart';

/// Test Users
class TestUsers {
  static User get admin => User(
        id: 'admin_001',
        email: 'admin@test.com',
        name: 'Admin User',
        role: 'admin',
        department: 'Administration',
        createdAt: DateTime(2024),
      );

  static User get manager => User(
        id: 'manager_001',
        email: 'manager@test.com',
        name: 'Manager User',
        role: 'manager',
        department: 'Management',
        createdAt: DateTime(2024),
      );

  static User get technician => User(
        id: 'tech_001',
        email: 'tech@test.com',
        name: 'Technician User',
        role: 'technician',
        department: 'Maintenance',
        createdAt: DateTime(2024),
      );

  static User get requestor => User(
        id: 'requestor_001',
        email: 'requestor@test.com',
        name: 'Requestor User',
        role: 'requestor',
        department: 'Operations',
        createdAt: DateTime(2024),
      );

  static User get inactiveUser => User(
        id: 'inactive_001',
        email: 'inactive@test.com',
        name: 'Inactive User',
        role: 'technician',
        department: 'Maintenance',
        isActive: false,
        createdAt: DateTime(2024),
      );

  static List<User> get all => [admin, manager, technician, requestor];
}

/// Test Assets
class TestAssets {
  static Asset get pump01 => Asset(
        id: 'asset_001',
        name: 'Main Water Pump',
        category: 'Pumps',
        location: 'Building A - Basement',
        status: 'Operational',
        manufacturer: 'TestCorp',
        model: 'P-1000',
        qrCode: 'QR_PUMP_001',
        createdAt: DateTime(2024, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

  static Asset get motor01 => Asset(
        id: 'asset_002',
        name: 'Primary Motor',
        category: 'Motors',
        location: 'Building B - Floor 1',
        status: 'Operational',
        manufacturer: 'MotorCo',
        model: 'M-500',
        qrCode: 'QR_MOTOR_001',
        createdAt: DateTime(2024, 1),
        updatedAt: DateTime(2024, 1, 3),
      );

  static Asset get hvac01 => Asset(
        id: 'asset_003',
        name: 'HVAC Unit 1',
        category: 'HVAC',
        location: 'Building A - Roof',
        status: 'Operational',
        manufacturer: 'CoolAir',
        model: 'CA-2000',
        qrCode: 'QR_HVAC_001',
        createdAt: DateTime(2024, 1),
        updatedAt: DateTime(2024, 1, 4),
      );

  static List<Asset> get all => [pump01, motor01, hvac01];
}

/// Test Work Orders
class TestWorkOrders {
  static WorkOrder get openWorkOrder => WorkOrder(
        id: 'wo_001',
        ticketNumber: 'WO-2024-001',
        problemDescription: 'Pump making unusual noise',
        assetId: TestAssets.pump01.id,
        asset: TestAssets.pump01,
        priority: WorkOrderPriority.high,
        createdAt: DateTime(2024, 1, 1, 10),
        updatedAt: DateTime(2024, 1, 1, 12),
        requestorId: TestUsers.requestor.id,
        requestor: TestUsers.requestor,
      );

  static WorkOrder get assignedWorkOrder => WorkOrder(
        id: 'wo_002',
        ticketNumber: 'WO-2024-002',
        problemDescription: 'Motor vibration detected',
        assetId: TestAssets.motor01.id,
        asset: TestAssets.motor01,
        status: WorkOrderStatus.assigned,
        createdAt: DateTime(2024, 1, 2, 9),
        updatedAt: DateTime(2024, 1, 2, 11),
        requestorId: TestUsers.requestor.id,
        requestor: TestUsers.requestor,
        primaryTechnicianId: TestUsers.technician.id,
        assignedTechnicianIds: [TestUsers.technician.id],
        assignedTechnicians: [TestUsers.technician],
      );

  static WorkOrder get inProgressWorkOrder => WorkOrder(
        id: 'wo_003',
        ticketNumber: 'WO-2024-003',
        problemDescription: 'HVAC not cooling properly',
        assetId: TestAssets.hvac01.id,
        asset: TestAssets.hvac01,
        priority: WorkOrderPriority.urgent,
        status: WorkOrderStatus.inProgress,
        createdAt: DateTime(2024, 1, 3, 8),
        updatedAt: DateTime(2024, 1, 3, 11),
        startedAt: DateTime(2024, 1, 3, 10),
        requestorId: TestUsers.requestor.id,
        requestor: TestUsers.requestor,
        primaryTechnicianId: TestUsers.technician.id,
        assignedTechnicianIds: [TestUsers.technician.id],
        assignedTechnicians: [TestUsers.technician],
      );

  static WorkOrder get completedWorkOrder => WorkOrder(
        id: 'wo_004',
        ticketNumber: 'WO-2024-004',
        problemDescription: 'Routine maintenance check',
        assetId: TestAssets.pump01.id,
        asset: TestAssets.pump01,
        priority: WorkOrderPriority.low,
        status: WorkOrderStatus.completed,
        createdAt: DateTime(2024, 1, 4, 7),
        startedAt: DateTime(2024, 1, 4, 8),
        completedAt: DateTime(2024, 1, 4, 9),
        updatedAt: DateTime(2024, 1, 4, 10),
        requestorId: TestUsers.requestor.id,
        requestor: TestUsers.requestor,
        primaryTechnicianId: TestUsers.technician.id,
        assignedTechnicianIds: [TestUsers.technician.id],
        assignedTechnicians: [TestUsers.technician],
        technicianNotes: 'All checks passed',
      );

  static List<WorkOrder> get all => [
        openWorkOrder,
        assignedWorkOrder,
        inProgressWorkOrder,
        completedWorkOrder,
      ];
}

/// Test PM Tasks
class TestPMTasks {
  static PMTask get weeklyPMTask => PMTask(
        id: 'pm_001',
        taskName: 'Weekly Pump Inspection',
        description: 'Check pump operation and pressure',
        assetId: TestAssets.pump01.id,
        asset: TestAssets.pump01,
        frequency: PMTaskFrequency.weekly,
        intervalDays: 7,
        primaryTechnicianId: TestUsers.technician.id,
        assignedTechnicianIds: [TestUsers.technician.id],
        assignedTechnicians: [TestUsers.technician],
        nextDueDate: DateTime(2024, 1, 8),
        createdAt: DateTime(2024, 1),
        updatedAt: DateTime(2024, 1, 2),
        checklist: _checklistJson(
          ['Check oil level', 'Inspect belts', 'Check pressure gauge'],
        ),
      );

  static PMTask get monthlyPMTask => PMTask(
        id: 'pm_002',
        taskName: 'Monthly HVAC Filter Change',
        description: 'Replace HVAC air filters',
        assetId: TestAssets.hvac01.id,
        asset: TestAssets.hvac01,
        frequency: PMTaskFrequency.monthly,
        intervalDays: 30,
        primaryTechnicianId: TestUsers.technician.id,
        assignedTechnicianIds: [TestUsers.technician.id],
        assignedTechnicians: [TestUsers.technician],
        nextDueDate: DateTime(2024, 2),
        createdAt: DateTime(2024, 1, 5),
        updatedAt: DateTime(2024, 1, 6),
        checklist: _checklistJson(
          ['Remove old filter', 'Install new filter', 'Check airflow'],
        ),
      );

  static PMTask get overduePMTask => PMTask(
        id: 'pm_003',
        taskName: 'Overdue Motor Lubrication',
        description: 'Lubricate motor bearings',
        assetId: TestAssets.motor01.id,
        asset: TestAssets.motor01,
        frequency: PMTaskFrequency.quarterly,
        intervalDays: 90,
        status: PMTaskStatus.overdue,
        primaryTechnicianId: TestUsers.technician.id,
        assignedTechnicianIds: [TestUsers.technician.id],
        assignedTechnicians: [TestUsers.technician],
        nextDueDate: DateTime(2023, 12, 31), // Overdue
        createdAt: DateTime(2023, 10),
        updatedAt: DateTime(2023, 12, 31),
        checklist: _checklistJson(
          ['Apply lubricant', 'Check bearing temperature'],
        ),
      );

  static List<PMTask> get all => [weeklyPMTask, monthlyPMTask, overduePMTask];
}

/// Test Inventory Items
class TestInventoryItems {
  static InventoryItem get oilFilter => InventoryItem(
        id: 'inv_001',
        partNumber: 'OF-100',
        name: 'Oil Filter',
        description: 'Standard oil filter',
        category: 'Filters',
        quantity: 25,
        minimumStock: 10,
        maximumStock: 50,
        cost: 15.99,
        location: 'Warehouse A - Shelf 1',
        unit: 'pieces',
        createdAt: DateTime(2024, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

  static InventoryItem get lowStockItem => InventoryItem(
        id: 'inv_002',
        partNumber: 'BT-200',
        name: 'Drive Belt',
        description: 'V-Belt for motors',
        category: 'Belts',
        quantity: 5, // Below min stock
        minimumStock: 10,
        maximumStock: 30,
        cost: 25.50,
        location: 'Warehouse A - Shelf 2',
        unit: 'pieces',
        createdAt: DateTime(2024, 1),
        updatedAt: DateTime(2024, 1, 3),
      );

  static List<InventoryItem> get all => [oilFilter, lowStockItem];
}

String _checklistJson(List<String> items) => jsonEncode(
      items
          .map(
            (item) => {
              'text': item,
              'required': true,
            },
          )
          .toList(),
    );
