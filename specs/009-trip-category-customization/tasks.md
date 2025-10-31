# Tasks: Per-Trip Category Visual Customization

**Input**: Design documents from `/specs/009-trip-category-customization/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: ✅ **TESTS REQUIRED** - This feature follows TDD (Principle I). Tests MUST be written FIRST and FAIL before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- Domain layer: `lib/core/`
- Data layer: `lib/features/categories/data/`
- Presentation layer: `lib/features/categories/presentation/`
- Shared utilities: `lib/shared/`
- Tests: `test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Firestore configuration

- [ ] T001 Add Firestore security rules for `/trips/{tripId}/categoryCustomizations/{categoryId}` in firestore.rules
- [ ] T002 [P] Create directory structure: `lib/core/models/`, `lib/core/repositories/`, `lib/core/validators/`
- [ ] T003 [P] Create directory structure: `lib/features/categories/data/models/`, `lib/features/categories/data/repositories/`
- [ ] T004 [P] Create directory structure: `lib/features/categories/presentation/cubit/`, `lib/features/categories/presentation/widgets/`
- [ ] T005 [P] Create test directory structure: `test/features/categories/cubit/`, `test/features/categories/data/`, `test/features/categories/presentation/widgets/`, `test/integration/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T006 [P] Create CategoryCustomization domain model in lib/core/models/category_customization.dart (entity with categoryId, tripId, customIcon, customColor, updatedAt)
- [ ] T007 [P] Create CategoryCustomizationModel (Firestore serialization) in lib/features/categories/data/models/category_customization_model.dart (fromFirestore, toFirestore)
- [ ] T008 [P] Create CategoryCustomizationValidator in lib/core/validators/category_customization_validator.dart (validateIcon, validateColor, validIcons Set, validColors Set)
- [ ] T009 [P] Create DisplayCategory helper class in lib/shared/utils/category_display_helper.dart (fromGlobalAndCustomization static method)
- [ ] T010 Extract CategoryIconPicker from CategoryCreationBottomSheet into lib/features/categories/presentation/widgets/category_icon_picker.dart (reusable bottom sheet widget, 30 Material Icons)
- [ ] T011 Extract CategoryColorPicker from CategoryCreationBottomSheet into lib/features/categories/presentation/widgets/category_color_picker.dart (reusable bottom sheet widget, 19 predefined colors)
- [ ] T012 Refactor CategoryCreationBottomSheet to use extracted CategoryIconPicker and CategoryColorPicker widgets in lib/features/categories/presentation/widgets/category_creation_bottom_sheet.dart
- [ ] T013 [P] Create CategoryCustomizationRepository interface in lib/core/repositories/category_customization_repository.dart (getCustomizationsForTrip, getCustomization, saveCustomization, deleteCustomization)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Customize Category Icon for Specific Trip (Priority: P1) 🎯 MVP

**Goal**: Alice can customize the "Meals" category icon to "ramen bowl" for her Japan Trip, and the custom icon appears throughout the app for that trip only, without affecting other trips.

**Independent Test**: (1) Open trip settings, (2) Select "Customize Categories", (3) Change "Meals" icon to "fastfood", (4) Create expense with "Meals" category, (5) Verify "fastfood" icon appears in expense list and forms. (6) Switch to different trip, (7) Verify "Meals" uses global default "restaurant" icon.

### Tests for User Story 1 ⚠️ WRITE THESE FIRST

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T014 [P] [US1] Unit test for CategoryCustomizationRepositoryImpl in test/features/categories/data/category_customization_repository_test.dart (mock Firestore, test getCustomizationsForTrip, getCustomization, saveCustomization, deleteCustomization)
- [ ] T015 [P] [US1] Unit test for CategoryCustomizationCubit in test/features/categories/cubit/category_customization_cubit_test.dart (test loadCustomizations, getCustomization, saveCustomization, resetCustomization, isCustomized)
- [ ] T016 [P] [US1] Unit test for CategoryDisplayHelper in test/shared/utils/category_display_helper_test.dart (test fromGlobalAndCustomization with various inputs)
- [ ] T017 [P] [US1] Widget test for CustomizeCategoriesScreen in test/features/categories/presentation/widgets/customize_categories_screen_test.dart (test UI renders, category list, tap to edit)
- [ ] T018 [P] [US1] Widget test for CategoryIconPicker in test/features/categories/presentation/widgets/category_icon_picker_test.dart (test grid renders, icon selection, callback)
- [ ] T019 [P] [US1] Integration test for complete icon customization flow in test/integration/category_customization_flow_test.dart (navigate to settings → customize categories → select category → change icon → save → verify in expense list)

### Implementation for User Story 1

- [ ] T020 [P] [US1] Implement CategoryCustomizationRepositoryImpl in lib/features/categories/data/repositories/category_customization_repository_impl.dart (Firestore operations, Stream<List<CategoryCustomization>> getCustomizationsForTrip, single doc reads/writes)
- [ ] T021 [US1] Generate mocks for CategoryCustomizationRepository and ActivityLogRepository using build_runner (run `dart run build_runner build --delete-conflicting-outputs`)
- [ ] T022 [US1] Create CategoryCustomizationState classes in lib/features/categories/presentation/cubit/category_customization_state.dart (CategoryCustomizationInitial, Loading, Loaded with Map<String, CategoryCustomization>, Saving, Resetting, Error)
- [ ] T023 [US1] Implement CategoryCustomizationCubit in lib/features/categories/presentation/cubit/category_customization_cubit.dart (loadCustomizations, getCustomization, saveCustomization, resetCustomization, isCustomized, dispose)
- [ ] T024 [US1] Create CustomizeCategoriesScreen in lib/features/categories/presentation/widgets/customize_categories_screen.dart (Scaffold, BlocBuilder, ListView of categories used in trip, each ListTile shows icon/color with edit button, loads customizations on init)
- [ ] T025 [US1] Add navigation to CustomizeCategoriesScreen from TripSettingsPage in lib/features/trips/presentation/pages/trip_settings_page.dart (add "Customize Categories" ListTile, route to CustomizeCategoriesScreen with tripId)
- [ ] T026 [US1] Update CategorySelector widget to use CategoryDisplayHelper in lib/features/categories/presentation/widgets/category_selector.dart (BlocBuilder<CategoryCustomizationCubit>, merge global + customization, display customized icon)
- [ ] T027 [US1] Integrate CategoryIconPicker into CustomizeCategoriesScreen (show bottom sheet when user taps icon, onIconSelected callback saves customization via cubit)
- [ ] T028 [US1] Add BlocProvider for CategoryCustomizationCubit at trip scope in lib/main.dart or trip detail screen (provide cubit with repository, tripId, auto-call loadCustomizations)
- [ ] T029 [US1] Update dependency injection to provide CategoryCustomizationRepository singleton in lib/main.dart (inject FirestoreService)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. Icon customization works end-to-end.

---

## Phase 4: User Story 2 - Customize Category Color for Specific Trip (Priority: P2)

**Goal**: Bob can customize the "Transport" category color from green to blue for his Work Trip, helping him visually distinguish work trips from personal trips.

**Independent Test**: (1) Open trip settings, (2) Select "Customize Categories", (3) Change "Transport" color to "#9C27B0" (purple), (4) Verify color appears in expense list category chips, (5) Switch to different trip, (6) Verify "Transport" uses global default color.

### Tests for User Story 2 ⚠️ WRITE THESE FIRST

- [ ] T030 [P] [US2] Unit test for color customization in test/features/categories/cubit/category_customization_cubit_test.dart (test saveCustomization with color only, test color-only customization loads correctly)
- [ ] T031 [P] [US2] Widget test for CategoryColorPicker in test/features/categories/presentation/widgets/category_color_picker_test.dart (test color grid renders, color selection, callback)
- [ ] T032 [P] [US2] Widget test for CustomizeCategoriesScreen color UI in test/features/categories/presentation/widgets/customize_categories_screen_test.dart (test color picker opens, color saves)

### Implementation for User Story 2

- [ ] T033 [US2] Integrate CategoryColorPicker into CustomizeCategoriesScreen in lib/features/categories/presentation/widgets/customize_categories_screen.dart (show bottom sheet when user taps color indicator, onColorSelected callback saves customization)
- [ ] T034 [US2] Update CategorySelector to use customized color in lib/features/categories/presentation/widgets/category_selector.dart (apply DisplayCategory.color to Chip backgroundColor)
- [ ] T035 [US2] Update ExpenseCard/ExpenseListTile to use customized color in lib/features/expenses/presentation/widgets/ (use CategoryDisplayHelper to get merged color)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. Users can customize both icon and color.

---

## Phase 5: User Story 3 - View Which Categories Are Customized (Priority: P3)

**Goal**: Clara can quickly see which categories have been customized in each trip, so she can maintain consistency or identify trips with personalized visuals.

**Independent Test**: (1) Customize 3 categories in a trip, (2) Open "Customize Categories" screen, (3) Verify customized categories show "Customized" badge or indicator, (4) Verify default categories show "Using global default" text.

### Tests for User Story 3 ⚠️ WRITE THESE FIRST

- [ ] T036 [P] [US3] Widget test for customization indicators in test/features/categories/presentation/widgets/customize_categories_screen_test.dart (test "Customized" badge appears for customized categories, test "Using global default" text for defaults)
- [ ] T037 [P] [US3] Unit test for filtering used categories in test/features/categories/cubit/category_customization_cubit_test.dart (test that only categories used in trip expenses are shown)

### Implementation for User Story 3

- [ ] T038 [US3] Add customization indicators to CustomizeCategoriesScreen in lib/features/categories/presentation/widgets/customize_categories_screen.dart (show Chip with "Customized" label if isCustomized, show subtitle "Using global default" otherwise)
- [ ] T039 [US3] Filter CustomizeCategoriesScreen to show only categories used in trip expenses in lib/features/categories/presentation/widgets/customize_categories_screen.dart (query expenses for trip, get unique categoryIds, filter global categories by usage)
- [ ] T040 [US3] Show customization count in TripSettingsPage in lib/features/trips/presentation/pages/trip_settings_page.dart (subtitle on "Customize Categories" tile shows "X categories customized")

**Checkpoint**: All user stories should now be independently functional. Full feature complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T041 [P] Add activity logging for customization operations in lib/features/categories/presentation/cubit/category_customization_cubit.dart (inject ActivityLogRepository, log saveCustomization, log resetCustomization, non-fatal try-catch)
- [ ] T042 [P] Add localized strings for customization UI in lib/l10n/app_en.arb (categoryCustomizationTitle, categoryCustomizationCustomized, categoryCustomizationUsingDefault, categoryCustomizationResetButton, categoryCustomizationIconLabel, categoryCustomizationColorLabel)
- [ ] T043 [P] Update CustomizeCategoriesScreen to use localized strings in lib/features/categories/presentation/widgets/customize_categories_screen.dart (replace hardcoded strings with context.l10n.*)
- [ ] T044 [P] Add error handling UI for CustomizeCategoriesScreen in lib/features/categories/presentation/widgets/customize_categories_screen.dart (BlocListener shows SnackBar on CategoryCustomizationError, retry button)
- [ ] T045 [P] Add loading states UI for CustomizeCategoriesScreen in lib/features/categories/presentation/widgets/customize_categories_screen.dart (show shimmer during CategoryCustomizationLoading, show spinner during Saving/Resetting)
- [ ] T046 Mobile testing on 375x667px viewport for CustomizeCategoriesScreen (verify scrollable, touch targets 44x44px, no layout overflow, keyboard doesn't hide inputs)
- [ ] T047 [P] Run flutter analyze and fix any issues
- [ ] T048 [P] Run flutter test and verify all 16+ tests pass
- [ ] T049 Verify performance: Load 50 customizations <200ms, cache access <10ms, save <500ms (add performance logging if needed)
- [ ] T050 Update feature CLAUDE.md using /docs.update (document architecture, key files, testing strategy)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Extends US1 UI but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Extends US1 UI but independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD)
- Models before services
- Services before UI
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members
- Polish tasks marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (run these FIRST):
Task T014: "Unit test for CategoryCustomizationRepositoryImpl"
Task T015: "Unit test for CategoryCustomizationCubit"
Task T016: "Unit test for CategoryDisplayHelper"
Task T017: "Widget test for CustomizeCategoriesScreen"
Task T018: "Widget test for CategoryIconPicker"
Task T019: "Integration test for icon customization flow"

# After tests FAIL, launch parallel implementation tasks:
Task T020: "Implement CategoryCustomizationRepositoryImpl"
Task T022: "Create CategoryCustomizationState classes"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T013) - CRITICAL - blocks all stories
3. Write tests for US1 (T014-T019) - Ensure they FAIL
4. Complete Phase 3: User Story 1 (T020-T029)
5. **STOP and VALIDATE**: Run tests, verify US1 works independently
6. Deploy/demo if ready

**MVP Deliverable**: Users can customize category icons on a per-trip basis. Full icon customization workflow functional.

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (icon) → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 (color) → Test independently → Deploy/Demo
4. Add User Story 3 (indicators) → Test independently → Deploy/Demo
5. Add Polish → Final release
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (icon customization)
   - Developer B: User Story 2 (color customization)
   - Developer C: User Story 3 (indicators)
3. Stories complete and integrate independently

---

## Notes

- **[P] tasks** = different files, no dependencies - can run in parallel
- **[Story] label** maps task to specific user story for traceability
- **Tests FIRST**: This feature follows TDD (Constitution Principle I). All tests must be written FIRST and FAIL before implementation begins
- Each user story should be independently completable and testable
- Verify tests fail before implementing (Red → Green → Refactor)
- Commit after each task or logical group using `/docs.log`
- Stop at any checkpoint to validate story independently
- Run `flutter analyze && flutter format . && flutter test` before committing
- Use `/docs.update` after architectural changes
- Use `/docs.complete` when feature is ready for merge

---

## Task Summary

**Total Tasks**: 50
- Setup: 5 tasks
- Foundational: 8 tasks (BLOCKS all user stories)
- User Story 1 (P1 - Icon): 16 tasks (6 tests + 10 implementation)
- User Story 2 (P2 - Color): 6 tasks (3 tests + 3 implementation)
- User Story 3 (P3 - Indicators): 3 tasks (2 tests + 1 implementation)
- Polish: 10 tasks

**Parallel Opportunities**: 31 tasks marked [P]

**Test Coverage**: 16 test tasks (Unit: 7, Widget: 5, Integration: 1)

**MVP Scope**: Phase 1 + Phase 2 + Phase 3 (User Story 1) = 29 tasks

**Constitution Compliance**:
- ✅ TDD: Tests written first (T014-T019 before T020-T029)
- ✅ Clean Architecture: Domain/Data/Presentation separation
- ✅ Mobile-First: T046 validates mobile viewport
- ✅ Performance: T049 validates performance targets
- ✅ Documentation: T050 updates CLAUDE.md
