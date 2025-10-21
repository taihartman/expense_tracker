# Feature Changelog: Group Expense Tracker for Trips

**Feature ID**: 001-group-expense-tracker

This changelog tracks all changes made during the development of this feature.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### In Progress
- Completing widget tests for expense forms
- Integration testing for expense recording flow
- Firebase Emulators configuration for local testing

---

## Development Log

## 2025-10-21 - Performance Optimization

### Changed
- Optimized app performance with offline-first architecture
- Implemented cache-first queries for Firestore data access
- Enhanced loading states and error handling

## 2025-10-21 - Settlement Calculation System

### Added
- Settlement calculator domain service (`lib/features/settlements/domain/services/settlement_calculator.dart`)
- Settlement domain models: PersonSummary, SettlementSummary, PairwiseDebt, MinimalTransfer
- Settlement data models with Firestore serialization
- Settlement repository with caching
- Settlement Cubit for state management
- Settlement UI pages and widgets:
  - Settlement Summary Page
  - All People Summary Table
  - Minimal Transfers View
- Pairwise debt netting algorithm
- Minimal transfer optimization using greedy matching

### Technical Details
- Implements full decimal precision for monetary calculations
- Settlement calculations complete within 2 seconds requirement
- Color coding for positive (green) and negative (red) net balances
- Copy-to-clipboard functionality for settlement plans

## 2025-10-21 - Trip Management Features

### Added
- Trip settings page (`lib/features/trips/presentation/pages/trip_settings_page.dart`)
- Participant management:
  - Participant form bottom sheet for adding/editing participants
  - Delete participant dialog with validation
  - Dynamic participant list per trip
- Trip selector widget with dropdown navigation
- Trip creation and list pages
- Trip Cubit for state management
- Trip domain and data models with Firestore integration

### Changed
- Enhanced Trip model to support dynamic participants (beyond fixed list)
- Updated trip selector to show current trip context

## 2025-10-21 - Expense Recording System

### Added
- Expense domain entity with split calculation (`lib/features/expenses/domain/models/expense.dart`)
- Category domain entity and repository
- Expense Firestore models and repository implementation
- Expense Cubit for state management
- Expense UI components:
  - Expense form page with split type selection
  - Expense list page
  - Expense card widget
  - Expense form bottom sheet
  - Participant selector with equal/weighted split support
  - Category selector widget
- Split calculation logic:
  - Equal split across selected participants
  - Weighted split with custom weights
  - Decimal precision throughout calculations
- Client-side validation for expense inputs
- Loading states and error handling

### Technical Details
- Supports multi-currency (USD/VND)
- Split types: Equal and Weighted
- Uses Decimal for precise monetary calculations
- Firestore integration with subcollection structure

## 2025-10-20 - Core Infrastructure Setup

### Added
- Firebase project initialization with FlutterFire
- Project dependencies:
  - flutter_bloc for state management
  - cloud_firestore for database
  - firebase_auth for authentication
  - firebase_functions for serverless functions
  - decimal for precise monetary calculations
  - fl_chart for data visualization
  - intl for internationalization
  - go_router for navigation
- Firestore security rules configuration
- Firestore indexes configuration
- Material Design 3 theme with 8px grid
- App router with go_router
- Firebase initialization in main.dart
- Core utilities:
  - Decimal helper utilities
  - Currency formatters (USD 2dp, VND 0dp)
  - Error handler utilities
- Core constants:
  - Fixed participants list (Tai, Khiet, Bob, Ethan, Ryan, Izzy)
  - Default categories (Meals, Transport, Accommodation, Activities)
- Base UI components (CustomButton, CustomTextField, LoadingIndicator)
- Firestore service wrapper
- Analysis options with zero-tolerance linting
- Cloud Functions project with TypeScript

### Technical Details
- Clean architecture: features/{feature}/domain|data|presentation
- Participant value object with id and name
- CurrencyCode enum (USD, VND)
- SplitType enum (Equal, Weighted)
- Repository pattern for data access

## 2025-10-20 - Testing Infrastructure

### Added
- Unit tests for expense split calculations (equal and weighted)
- Unit tests for expense validation rules
- Test structure following clean architecture

### Pending
- Widget tests for ExpenseForm and ExpenseCard
- Integration tests for expense recording flow

## 2025-10-20 - Spec-Kit Integration

### Added
- GitHub Spec-Kit for spec-driven development
- Slash commands: /speckit.specify, /speckit.plan, /speckit.tasks, /speckit.analyze, /speckit.clarify, /speckit.implement, /speckit.checklist
- Feature specification in specs/001-group-expense-tracker/spec.md
- Implementation plan in specs/001-group-expense-tracker/plan.md
- Task breakdown in specs/001-group-expense-tracker/tasks.md
- Data model documentation

## 2025-10-20 - Initial Setup

### Added
- Created feature specification
- Set up feature branch `001-group-expense-tracker`
- Initialized documentation structure
- Flutter web project initialization
- GitHub Actions CI/CD with auto-deploy to GitHub Pages
- Claude Code Action integration for GitHub
