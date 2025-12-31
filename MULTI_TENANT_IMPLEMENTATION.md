# Multi-Tenant Implementation Summary

## Overview
This document summarizes the multi-tenant (company-based) implementation for the Be Electric CMMS application. Each company that has purchased chargers will have their own isolated data.

## Database Schema Changes

### 1. Companies Table
- New table: `companies`
- Fields: id, name, contactEmail, contactPhone, address, isActive, createdAt, updatedAt, metadata
- Indexes: name, isActive

### 2. Users Table
- Added: `companyId` (foreign key to companies table)
- Index: companyId

### 3. Assets Table
- Added: `companyId` (foreign key to companies table)
- Index: companyId
- Note: Legacy `company` field (string) is still present for backward compatibility

### 4. Work Orders Table
- Added: `companyId` (foreign key to companies table)
- Index: companyId

## Row Level Security (RLS) Policies

### Companies
- Users can view their own company
- Admins/managers can view all companies

### Users
- Users can view users in their company
- Admins/managers can view all users

### Assets
- Users can view assets in their company
- Admins/managers can view all assets

### Work Orders
- Users can view/create/update work orders in their company
- Admins/managers can view/create/update all work orders

## Model Updates

### Company Model
- New model: `lib/models/company.dart`
- Includes: id, name, contactEmail, contactPhone, address, isActive, metadata

### User Model
- Added: `companyId` field
- Updated: `create()`, `fromMap()`, `toMap()`, `copyWith()` methods

### Asset Model
- Added: `companyId` field
- Legacy: `company` field (string) still exists for backward compatibility
- Updated: `fromMap()`, `toMap()`, `copyWith()` methods

### WorkOrder Model
- Added: `companyId` field
- Updated: `fromMap()`, `toMap()`, `copyWith()` methods

## Application Logic Updates

### Work Order Creation
- Automatically sets `companyId` from the requestor's `companyId`
- If requestor has no `companyId`, logs a warning (but allows creation for backward compatibility)

### Data Filtering
- RLS policies automatically filter data by company at the database level
- Application code should also be aware of company filtering for clarity

## Next Steps

1. **Update Asset Selection Screen**: Filter assets by user's companyId
2. **Update Work Order Queries**: Ensure all queries respect company boundaries
3. **Admin Interface**: Add company management UI for admins
4. **Migration Script**: Create script to assign existing users/assets to companies
5. **Testing**: Test multi-tenant isolation thoroughly

## Migration Notes

- Existing data without `companyId` will need to be migrated
- Admins/managers can see all companies (for management purposes)
- Requestors can only see their company's data
- Technicians can see work orders from all companies (if assigned) or only their company (depending on business logic)

