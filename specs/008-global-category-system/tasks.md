# Tasks: Global Category Management System

**Input**: Design documents from `/specs/008-global-category-system/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests are REQUIRED per project constitution (TDD). Tests MUST be written and FAIL before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions
- Flutter project at repository root
- `lib/` for source code
- `test/` for test files
- Paths match existing clean architecture: `lib/features/categories/{domain,data,presentation}/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Firestore configuration for global categories

- [ ] T001 Create migration script directory at `scripts/migrations/`
- [ ] T002 [P] Add localization strings for category UI to `lib/l10n/app_en.arb`
- [ ] T003 [P] Update Firestore Security Rules for global categories collection in `firestore.rules`
- [ ] T004 [P] Create Firestore composite indexes configuration in `firestore.indexes.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core domain and data models that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Update Category domain model to remove tripId and add usageCount, nameLowercase in `lib/features/categories/domain/models/category.dart`
- [ ] T006 [P] Update Category Firestore model for global structure in `lib/features/categories/data/models/category_model.dart`
- [ ] T007 [P] Create CategoryValidator for name validation in `lib/core/validators/category_validator.dart`
- [ ] T008 Update CategoryRepository interface for global operations in `lib/features/categories/domain/repositories/category_repository.dart`
- [ ] T009 Refactor CategoryRepositoryImpl for global Firestore queries in `lib/features/categories/data/repositories/category_repository_impl.dart`
- [ ] T010 [P] Create RateLimiterService for spam prevention in `lib/core/services/rate_limiter_service.dart`
- [ ] T011 [P] Create CategoryCubit state definitions in `lib/features/categories/presentation/cubits/category_state.dart`
- [ ] T012 Create CategoryCubit with state management logic in `lib/features/categories/presentation/cubits/category_cubit.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Quick Category Selection from Popular Defaults (Priority: P1) 🎯 MVP

**Goal**: Users can instantly select from 5 popular categories displayed as horizontal chips

**Independent Test**: Create an expense and select from the 5 default popular categories. Verify category is saved and displayed correctly.

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T013 [P] [US1] Unit test for Category model validation in `test/features/categories/domain/models/category_test.dart`
- [ ] T014 [P] [US1] Unit test for CategoryValidator in `test/core/validators/category_validator_test.dart`
- [ ] T015 [P] [US1] Unit test for CategoryRepositoryImpl getTopCategories in `test/features/categories/data/repositories/category_repository_impl_test.dart`
- [ ] T016 [P] [US1] Unit test for CategoryCubit loadTopCategories state transitions in `test/features/categories/presentation/cubits/category_cubit_test.dart`
- [ ] T017 [P] [US1] Widget test for CategorySelector chip display in `test/features/categories/presentation/widgets/category_selector_test.dart`

### Implementation for User Story 1

- [ ] T018 [US1] Refactor CategorySelector to display top 5 chips horizontally in `lib/features/categories/presentation/widgets/category_selector.dart`
- [ ] T019 [US1] Add "Other" chip to CategorySelector for future expansion in `lib/features/categories/presentation/widgets/category_selector.dart`
- [ ] T020 [US1] Integrate CategoryCubit with CategorySelector widget in `lib/features/categories/presentation/widgets/category_selector.dart`
- [ ] T021 [US1] Update ExpenseFormPage to use refactored CategorySelector in `lib/features/expenses/presentation/pages/expense_form_page.dart`
- [ ] T022 [US1] Add activity logging for category selection in expense form in `lib/features/expenses/presentation/pages/expense_form_page.dart`

**Checkpoint**: At this point, User Story 1 should be fully functional - users can select from 5 popular categories

---

## Phase 4: User Story 2 - Browse and Search All Available Categories (Priority: P2)

**Goal**: Users can tap "Other" to browse/search all global categories in a bottom sheet

**Independent Test**: Open category browser, search for categories, select one. Verify bottom sheet opens, search filters results, and selection closes sheet.

### Tests for User Story 2

- [ ] T023 [P] [US2] Unit test for CategoryCubit searchCategories state transitions in `test/features/categories/presentation/cubits/category_cubit_test.dart`
- [ ] T024 [P] [US2] Widget test for CategoryBrowserBottomSheet display and search in `test/features/categories/presentation/widgets/category_browser_bottom_sheet_test.dart`
- [ ] T025 [P] [US2] Integration test for complete browse and select flow in `test/integration/category_browser_flow_test.dart`

### Implementation for User Story 2

- [ ] T026 [P] [US2] Create CategoryBrowserBottomSheet widget with DraggableScrollableSheet in `lib/features/categories/presentation/widgets/category_browser_bottom_sheet.dart`
- [ ] T027 [US2] Implement search field with real-time filtering in CategoryBrowserBottomSheet in `lib/features/categories/presentation/widgets/category_browser_bottom_sheet.dart`
- [ ] T028 [US2] Add category list with shimmer loading state in CategoryBrowserBottomSheet in `lib/features/categories/presentation/widgets/category_browser_bottom_sheet.dart`
- [ ] T029 [US2] Wire up "Other" chip tap to open CategoryBrowserBottomSheet in CategorySelector in `lib/features/categories/presentation/widgets/category_selector.dart`
- [ ] T030 [US2] Implement category selection and bottom sheet dismiss in CategoryBrowserBottomSheet in `lib/features/categories/presentation/widgets/category_browser_bottom_sheet.dart`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - users can quick-select or browse/search

---

## Phase 5: User Story 3 - Create New Custom Categories (Priority: P3)

**Goal**: Users can create new categories when search returns no results, with spam prevention

**Independent Test**: Search for non-existent category, create it, verify it appears in global pool. Test rate limiting by creating 3 categories quickly.

### Tests for User Story 3

- [ ] T031 [P] [US3] Unit test for RateLimiterService canCreateCategory logic in `test/core/services/rate_limiter_service_test.dart`
- [ ] T032 [P] [US3] Unit test for CategoryCubit createCategory with validation in `test/features/categories/presentation/cubits/category_cubit_test.dart`
- [ ] T033 [P] [US3] Unit test for CategoryCubit rate limit handling in `test/features/categories/presentation/cubits/category_cubit_test.dart`
- [ ] T034 [P] [US3] Widget test for CategoryCreationDialog form and validation in `test/features/categories/presentation/widgets/category_creation_dialog_test.dart`
- [ ] T035 [P] [US3] Integration test for complete category creation flow with rate limiting in `test/integration/category_creation_flow_test.dart`

### Implementation for User Story 3

- [ ] T036 [P] [US3] Create CategoryCreationDialog widget with form fields in `lib/features/categories/presentation/widgets/category_creation_dialog.dart`
- [ ] T037 [US3] Implement default icon and color logic in CategoryCreationDialog in `lib/features/categories/presentation/widgets/category_creation_dialog.dart`
- [ ] T038 [US3] Add validation to CategoryCreationDialog (character rules, length, duplicates) in `lib/features/categories/presentation/widgets/category_creation_dialog.dart`
- [ ] T039 [US3] Wire up "Create" option in CategoryBrowserBottomSheet when search has no results in `lib/features/categories/presentation/widgets/category_browser_bottom_sheet.dart`
- [ ] T040 [US3] Implement rate limit check and disabled "Create" button state in CategoryBrowserBottomSheet in `lib/features/categories/presentation/widgets/category_browser_bottom_sheet.dart`
- [ ] T041 [US3] Add CategoryCubit createCategory method with repository call in `lib/features/categories/presentation/cubits/category_cubit.dart`
- [ ] T042 [US3] Handle duplicate category error with "already exists" message in CategoryCubit in `lib/features/categories/presentation/cubits/category_cubit.dart`
- [ ] T043 [US3] Add activity logging for category creation in CategoryCubit in `lib/features/categories/presentation/cubits/category_cubit.dart`

**Checkpoint**: All core user stories should now be independently functional - quick select, browse, search, create

---

## Phase 6: User Story 4 - Customize Category Icons (Priority: P4)

**Goal**: Users can customize icon and color when creating categories

**Independent Test**: Create category, tap icon field, select custom icon, tap color field, select color. Verify category is created with custom visuals.

### Tests for User Story 4

- [ ] T044 [P] [US4] Widget test for IconPicker grid display and search in `test/features/categories/presentation/widgets/icon_picker_test.dart`
- [ ] T045 [P] [US4] Widget test for ColorPicker palette display and selection in `test/features/categories/presentation/widgets/color_picker_test.dart`
- [ ] T046 [P] [US4] Integration test for icon and color customization flow in `test/integration/category_customization_flow_test.dart`

### Implementation for User Story 4

- [ ] T047 [P] [US4] Create IconPicker widget with Material icons grid in `lib/features/categories/presentation/widgets/icon_picker.dart`
- [ ] T048 [P] [US4] Add search field to IconPicker for filtering icons in `lib/features/categories/presentation/widgets/icon_picker.dart`
- [ ] T049 [P] [US4] Create ColorPicker widget with preset color palette in `lib/features/categories/presentation/widgets/color_picker.dart`
- [ ] T050 [US4] Integrate IconPicker with CategoryCreationDialog icon field in `lib/features/categories/presentation/widgets/category_creation_dialog.dart`
- [ ] T051 [US4] Integrate ColorPicker with CategoryCreationDialog color field in `lib/features/categories/presentation/widgets/category_creation_dialog.dart`
- [ ] T052 [US4] Implement icon usage tracking (optional) for smart defaults in `lib/features/categories/data/repositories/category_repository_impl.dart`

**Checkpoint**: All user stories complete with full customization capabilities

---

## Phase 7: Migration & Polish

**Purpose**: Data migration, cross-cutting improvements, and final validation

### Migration

- [ ] T053 Create migration script for trip-specific to global categories in `scripts/migrations/migrate_categories_to_global.dart`
- [ ] T054 Implement category grouping and duplicate merging logic in migration script in `scripts/migrations/migrate_categories_to_global.dart`
- [ ] T055 Implement expense categoryId reference updates in migration script in `scripts/migrations/migrate_categories_to_global.dart`
- [ ] T056 Add dry-run mode and logging to migration script in `scripts/migrations/migrate_categories_to_global.dart`
- [ ] T057 Test migration script on staging data and verify results

### Polish & Cross-Cutting

- [ ] T058 [P] Update CLAUDE.md feature docs with category system architecture
- [ ] T059 [P] Update CHANGELOG.md with feature development log
- [ ] T060 [P] Add all localized strings to app_en.arb (error messages, UI labels, tooltips)
- [ ] T061 [P] Run flutter analyze and fix any linting warnings
- [ ] T062 [P] Run flutter format . to format all code
- [ ] T063 Run flutter test --coverage and verify 80%+ business logic coverage
- [ ] T064 Test mobile viewport (375x667px) in Chrome DevTools
- [ ] T065 Test keyboard interaction with bottom sheet on mobile
- [ ] T066 Test category chip touch targets (44x44px minimum)
- [ ] T067 [P] Performance testing: verify search <500ms, cache load <200ms
- [ ] T068 Review and update Firestore Security Rules for production readiness
- [ ] T069 Deploy Firestore indexes to production
- [ ] T070 Run migration script on production data (with backup)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3 → P4)
- **Migration & Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Extends US1 (adds "Other" chip functionality)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Uses US2 bottom sheet, adds creation
- **User Story 4 (P4)**: Can start after US3 complete - Extends creation dialog with pickers

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD)
- Models before services
- Services before UI widgets
- Core widgets before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T002, T003, T004)
- All Foundational tasks marked [P] can run in parallel within Phase 2 (T006, T007, T010, T011)
- Once Foundational phase completes, user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models/widgets within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for Category model validation in test/features/categories/domain/models/category_test.dart"
Task: "Unit test for CategoryValidator in test/core/validators/category_validator_test.dart"
Task: "Unit test for CategoryRepositoryImpl getTopCategories"
Task: "Unit test for CategoryCubit loadTopCategories state transitions"
Task: "Widget test for CategorySelector chip display"
```

## Parallel Example: User Story 3

```bash
# Launch all parallel test tasks together:
Task: "Unit test for RateLimiterService"
Task: "Unit test for CategoryCubit createCategory"
Task: "Unit test for CategoryCubit rate limit handling"
Task: "Widget test for CategoryCreationDialog"

# Launch all parallel implementation tasks together:
Task: "Create CategoryCreationDialog widget"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T012) - CRITICAL, blocks all stories
3. Complete Phase 3: User Story 1 (T013-T022)
4. **STOP and VALIDATE**: Test User Story 1 independently
   - Users can see 5 popular categories
   - Users can select a category
   - Category is saved with expense
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational (Phase 1-2) → Foundation ready
2. Add User Story 1 (Phase 3) → Test independently → Deploy/Demo (MVP!)
   - Value: 80% of users can categorize expenses instantly
3. Add User Story 2 (Phase 4) → Test independently → Deploy/Demo
   - Value: Users can find any existing category via search
4. Add User Story 3 (Phase 5) → Test independently → Deploy/Demo
   - Value: Users can create categories, global pool grows organically
5. Add User Story 4 (Phase 6) → Test independently → Deploy/Demo
   - Value: Users can personalize categories with custom icons/colors
6. Run Migration & Polish (Phase 7) → Final production deployment
   - Migrate existing data, optimize, validate

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (Phase 1-2)
2. Once Foundational is done:
   - Developer A: User Story 1 (Phase 3)
   - Developer B: User Story 2 (Phase 4) - can work in parallel
   - Developer C: User Story 3 (Phase 5) - can work in parallel
   - Developer D: User Story 4 (Phase 6) - can start after US3
3. Stories complete and integrate independently
4. Team collaborates on Migration & Polish (Phase 7)

---

## Task Summary

**Total Tasks**: 70

**By Phase**:
- Phase 1 (Setup): 4 tasks
- Phase 2 (Foundational): 8 tasks
- Phase 3 (US1 - MVP): 10 tasks (5 tests + 5 implementation)
- Phase 4 (US2 - Browse/Search): 8 tasks (3 tests + 5 implementation)
- Phase 5 (US3 - Create): 13 tasks (5 tests + 8 implementation)
- Phase 6 (US4 - Customize): 9 tasks (3 tests + 6 implementation)
- Phase 7 (Migration & Polish): 18 tasks

**By User Story**:
- User Story 1 (P1 - MVP): 10 tasks
- User Story 2 (P2): 8 tasks
- User Story 3 (P3): 13 tasks
- User Story 4 (P4): 9 tasks
- Shared (Setup + Foundational + Polish): 30 tasks

**Parallel Opportunities**: 27 tasks marked [P] can run in parallel within their phase

**Test Coverage**: 16 test tasks (TDD approach per constitution)

---

## Notes

- **[P] tasks**: Different files, no dependencies within phase - can run in parallel
- **[Story] label**: Maps task to specific user story for traceability
- **TDD Required**: Constitution mandates tests written FIRST, must FAIL before implementation
- **Independent Stories**: Each user story should be independently completable and testable
- **Verify tests fail**: Before implementing, run tests and confirm they fail
- **Commit frequently**: After each task or logical group
- **Stop at checkpoints**: Validate story independently before proceeding
- **Mobile-first**: Test on 375x667px viewport before considering complete
- **Migration last**: Run migration script ONLY after all features validated in staging

---

## Ready to Implement

Follow TDD strictly:
1. Write test (it should fail)
2. Implement minimum code to pass test
3. Refactor while keeping test green

Start with Phase 1 (Setup), then Phase 2 (Foundational), then User Story 1 (MVP).

Use `/docs.log` to document progress as you complete tasks.

Good luck! 🚀
