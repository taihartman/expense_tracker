# Feature Directory

This document provides an index of all features in this project, their status, and links to detailed documentation.

## Legend

- ✅ **Complete** - Feature is fully implemented, tested, and stable
- 🚧 **In Progress** - Feature is currently being developed
- 📋 **Planned** - Feature is specified but not yet started
- 🗄️ **Archived** - Feature is deprecated or removed

---

## Features

### ✅ 001 - Group Expense Tracker
**Status**: Complete
**Description**: Core expense tracking functionality for group trips
**Documentation**: [specs/001-group-expense-tracker/](specs/001-group-expense-tracker/)
**Key Components**: Expense CRUD, participant management, Firebase integration

---

### ✅ 002 - Itemized Splitter
**Status**: Complete
**Description**: Split expenses by individual items rather than equal splits
**Documentation**: [specs/002-itemized-splitter/](specs/002-itemized-splitter/)
**Key Components**: Item-level expense splitting, participant item selection

---

### ✅ 003 - Trip Invite System
**Status**: Complete
**Description**: Invite system for sharing trips via links or codes
**Documentation**: [specs/003-trip-invite-system/](specs/003-trip-invite-system/)
**Key Components**: Invite generation, join flow, trip access management

---

### ✅ 004 - Device Pairing
**Status**: Complete
**Description**: Multi-device pairing for seamless cross-device experience
**Documentation**: [specs/004-device-pairing/](specs/004-device-pairing/)
**Key Components**: Device registration, pairing codes, identity sync

---

### ✅ 005 - Receipt Split UX
**Status**: Complete
**Description**: Improved user experience for splitting receipts
**Documentation**: [specs/005-receipt-split-ux/](specs/005-receipt-split-ux/)
**Key Components**: Receipt scanning, OCR integration, split preview

---

### ✅ 006 - Centralized Activity Logger
**Status**: Complete
**Description**: Unified activity logging system for audit trail
**Documentation**: [specs/006-centralized-activity-logger/](specs/006-centralized-activity-logger/)
**Key Components**: Activity log repository, log viewer, filtering

---

### ✅ 007 - Web Auto-Update
**Status**: Complete
**Description**: Automatic updates for web deployment
**Documentation**: [specs/007-web-auto-update/](specs/007-web-auto-update/)
**Key Components**: Service worker, update detection, version management

---

### ✅ 008 - Global Category System
**Status**: Complete
**Description**: Global expense categories with curated list
**Documentation**: [specs/008-global-category-system/](specs/008-global-category-system/)
**Key Components**: Category repository, Firestore backend, rate limiting

---

### ✅ 009 - Trip Category Customization
**Status**: Complete
**Description**: Per-trip category customization and management
**Documentation**: [specs/009-trip-category-customization/](specs/009-trip-category-customization/)
**Key Components**: Trip-specific categories, category editor, merge logic

---

### ✅ 010 - ISO 4217 Currencies
**Status**: Complete
**Description**: Support for all ISO 4217 currency codes
**Documentation**: [specs/010-iso-4217-currencies/](specs/010-iso-4217-currencies/)
**Key Components**: Currency code enum, validation, formatting

---

### ✅ 011 - Trip Multi-Currency
**Status**: Complete
**Description**: Multi-currency support within trips
**Documentation**: [specs/011-trip-multi-currency/](specs/011-trip-multi-currency/)
**Key Components**: Currency selection, conversion, settlement

---

## Feature Statistics

**Total Features**: 11
**Complete**: 11 (100%)
**In Progress**: 0
**Planned**: 0
**Archived**: 0

## Adding New Features

When adding a new feature:

1. Create feature branch: `012-feature-name`
2. Run `/speckit.specify` to create specification
3. Follow Spec-Kit workflow (clarify → plan → tasks → analyze → implement)
4. Run `/docs.create` to initialize feature documentation
5. Update this index with the new feature
6. Use `/docs.log` frequently during development
7. Run `/docs.complete` when feature is done

## Feature Documentation Structure

Each feature should have:

```
specs/{id}-{name}/
├── spec.md           # Feature specification
├── plan.md           # Implementation plan
├── tasks.md          # Task breakdown
├── CLAUDE.md         # Feature architecture
├── CHANGELOG.md      # Development log
└── checklists/       # Quality checklists
```

## Searching Features

- **By keyword**: Use `/docs.search "keyword"` to search across all feature docs
- **By status**: Filter this page by status emoji (✅, 🚧, 📋, 🗄️)
- **By component**: Search for specific technology (e.g., "Firestore", "BLoC")

---

**Last Updated**: 2025-11-04
**Maintained By**: Project team
**Update Frequency**: After each feature completion or status change
