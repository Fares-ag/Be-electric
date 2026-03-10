# Be Electric - CMMS Mobile Application

A Flutter-based Computerized Maintenance Management System (CMMS) mobile application for EV charger maintenance management.

## Overview

Be Electric is a comprehensive maintenance management solution designed for managing EV charger maintenance requests, work orders, and asset tracking.

## Features

- **Multi-tenant Support**: Isolated data per company
- **Role-based Access**: Requestor, Technician, Manager, and Admin roles
- **Real-time Updates**: Supabase real-time synchronization
- **Work Order Management**: Create, track, and manage maintenance requests
- **Asset Management**: Track and manage EV chargers and equipment
- **Photo Attachments**: Attach photos to maintenance requests
- **Analytics Dashboard**: View maintenance statistics and performance metrics

## Technology Stack

- **Framework**: Flutter
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **State Management**: Provider
- **Real-time**: Supabase Realtime

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Supabase account and project

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Supabase:
   - Update `lib/config/supabase_config.dart` with your Supabase credentials
   - Run the SQL migration scripts in your Supabase SQL Editor

4. Run the app:
   ```bash
   flutter run
   ```

## Database Setup

1. Run `supabase_migration.sql` to create the initial schema
2. Run `add_company_support.sql` to add multi-tenant support (if needed)
3. Run `fix_user_lookup_rls.sql` to fix RLS policies for user lookup

## Project Structure

- `lib/screens/` - Application screens
- `lib/models/` - Data models
- `lib/services/` - Business logic and API services
- `lib/providers/` - State management
- `lib/widgets/` - Reusable widgets
- `lib/utils/` - Utility functions and themes

## License

Copyright © 2025 Be Electric


