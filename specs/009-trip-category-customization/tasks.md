# Task Breakdown: Per-Trip Category Visual Customization

**Feature**: Per-Trip Category Visual Customization + Icon System Improvements
**Branch**: `009-trip-category-customization`
**Generated**: 2025-10-31

## Overview

This task breakdown organizes work by user story to enable independent implementation and testing. Each phase represents a complete, testable increment of functionality.

**Total Estimated Tasks**: 69
**Parallel Opportunities**: 42 parallelizable tasks across phases
**MVP Scope**: Phase 2 (Foundational) + Phase 3 (US1)

---

## Phase 1: Setup & Dependencies

**Goal**: Install dependencies and update project configuration

**Tasks**:

- [ ] T001 Add string_similarity package to pubspec.yaml (^2.0.0 for fuzzy matching)
- [ ] T002 Run flutter pub get to install new dependencies
- [ ] T003 Update Firestore security rules to include categoryIconPreferences collection
- [ ] T004 Add localization strings for voting and similarity features to lib/l10n/app_en.arb
- [ ] T005 Run flutter pub get to regenerate l10n files

**Completion Criteria**: All dependencies installed, security rules deployed, l10n strings available

---

## Phase 2: Foundational - Icon System Infrastructure

**Goal**: Create type-safe icon system and eliminate code duplication (BLOCKS ALL USER STORIES)

**Independent Test**: Icon enum and helper can convert all 30 icons bidirectionally (string ↔ enum ↔ IconData)

### Domain Models (Parallel)

- [ ] T006 [P] Create CategoryIcon enum with 30 icon values in lib/core/enums/category_icon.dart
- [ ] T007 [P] Add iconName getter to CategoryIcon enum (enum → string for Firestore)
- [ ] T008 [P] Add iconData getter to CategoryIcon enum (enum → IconData for rendering)
- [ ] T009 [P] Add tryFromString factory to CategoryIcon enum (string → enum parser)

### Shared Utilities (Depends on T006-T009)

- [ ] T010 Create IconHelper utility class in lib/shared/utils/icon_helper.dart
- [ ] T011 Implement IconHelper.getIconData() with switch for all 30 icons
- [ ] T012 Implement IconHelper.toCategoryIcon() converter method
- [ ] T013 Implement IconHelper.fromCategoryIcon() converter method

### Testing (Parallel after T006-T013)

- [ ] T014 [P] Write unit tests for CategoryIcon enum in test/core/enums/category_icon_test.dart
- [ ] T015 [P] Write unit tests for IconHelper in test/shared/utils/icon_helper_test.dart
- [ ] T016 [P] Test all 30 icons convert correctly (string ↔ enum ↔ IconData)

### Code Deduplication (Parallel after T010-T013)

- [ ] T017 [P] Update category_selector.dart to use IconHelper (remove _getIconData method)
- [ ] T018 [P] Update category_browser_bottom_sheet.dart to use IconHelper (remove _getIconData method)
- [ ] T019 [P] Update customize_categories_screen.dart to use IconHelper (remove _getIconData method)

### Domain Enhancements (Parallel after T006-T009)

- [ ] T020 [P] Add iconEnum getter to Category model in lib/features/categories/domain/models/category.dart
- [ ] T021 [P] Update CategoryCustomizationValidator to use CategoryIcon enum in lib/core/validators/category_customization_validator.dart

**Phase 2 Completion Criteria**:
- ✅ CategoryIcon enum with 30 icons exists
- ✅ IconHelper utility eliminates all _getIconData() duplication
- ✅ All 30 icons render correctly in UI (test with category_selector)
- ✅ Tests achieve >90% coverage for icon system
- ✅ SC-007: All 30 icons render without fallback
- ✅ SC-008: Icon conversion code in exactly 1 location

---

## Phase 3: User Story 1 - Customize Category Icon for Specific Trip (P1)

**Goal**: Enable users to customize category icons per trip

**Story**: Alice wants to change "Meals" icon to "ramen bowl" for her Japan trip only

**Independent Test**: 
1. Open trip settings → "Customize Categories"
2. Change "Meals" icon to "fastfood"
3. Create expense with "Meals" category
4. Verify "fastfood" icon appears in that trip
5. Verify other trips still show global default "restaurant" icon

### Models & Serialization (Parallel after Phase 2)

- [ ] T022 [P] [US1] Ensure CategoryCustomization model exists in lib/core/models/category_customization.dart
- [ ] T023 [P] [US1] Ensure CategoryCustomizationModel Firestore serialization exists in lib/features/categories/data/models/category_customization_model.dart

### Repository Layer (After T022-T023)

- [ ] T024 [US1] Add getCustomization() method to CategoryCustomizationRepository interface in lib/features/categories/domain/repositories/category_customization_repository.dart
- [ ] T025 [US1] Add customizeCategory() method to CategoryCustomizationRepository interface
- [ ] T026 [US1] Add resetCustomization() method to CategoryCustomizationRepository interface
- [ ] T027 [US1] Implement getCustomization() in CategoryCustomizationRepositoryImpl in lib/features/categories/data/repositories/category_customization_repository_impl.dart
- [ ] T028 [US1] Implement customizeCategory() in CategoryCustomizationRepositoryImpl (icon only for now)
- [ ] T029 [US1] Implement resetCustomization() in CategoryCustomizationRepositoryImpl

### State Management (After T024-T029)

- [ ] T030 [US1] Create CategoryCustomizationCubit in lib/features/categories/presentation/cubit/category_customization_cubit.dart
- [ ] T031 [US1] Create CategoryCustomizationState in lib/features/categories/presentation/cubit/category_customization_state.dart
- [ ] T032 [US1] Implement loadCustomizations() method in CategoryCustomizationCubit
- [ ] T033 [US1] Implement customizeIcon() method in CategoryCustomizationCubit (uses CategoryIcon enum)
- [ ] T034 [US1] Implement resetIcon() method in CategoryCustomizationCubit

### UI Components (Parallel after T030-T034)

- [ ] T035 [P] [US1] Update CategoryIconPicker to generate grid from CategoryIcon.values in lib/features/categories/presentation/widgets/category_icon_picker.dart
- [ ] T036 [P] [US1] Create CustomizeCategoriesScreen in lib/features/categories/presentation/widgets/customize_categories_screen.dart
- [ ] T037 [P] [US1] Add "Customize Categories" navigation to Trip Settings page
- [ ] T038 [P] [US1] Update CategorySelector to display custom icons using DisplayCategory helper

### Testing (Parallel after T022-T038)

- [ ] T039 [P] [US1] Write unit tests for CategoryCustomizationCubit in test/features/categories/presentation/cubit/category_customization_cubit_test.dart
- [ ] T040 [P] [US1] Write widget tests for CategoryIconPicker in test/features/categories/presentation/widgets/category_icon_picker_test.dart
- [ ] T041 [P] [US1] Write widget tests for CustomizeCategoriesScreen in test/features/categories/presentation/widgets/customize_categories_screen_test.dart
- [ ] T042 [P] [US1] Write integration test for icon customization flow in test/integration/category_customization_flow_test.dart

### Mobile Testing (After T035-T038)

- [ ] T043 [US1] Test CustomizeCategoriesScreen on 375x667px viewport
- [ ] T044 [US1] Verify icon picker grid is scrollable and touch targets are 44x44px
- [ ] T045 [US1] Test customization persists across app restarts

**Phase 3 Completion Criteria**:
- ✅ Users can customize category icons per trip
- ✅ Customizations isolated to specific trip
- ✅ Reset to default works
- ✅ FR-001: Icon customization per trip ✓
- ✅ SC-001: Customize in <30 seconds ✓
- ✅ SC-002: Custom icons appear within 200ms ✓

---

## Phase 4: User Story 4 - Seamless Icon Voting System (P1)

**Goal**: Enable crowd-sourced improvement of category icons through implicit voting

**Story**: David customizes "Skiing" icon to "ski"; after 3 users do same, global default updates

**Independent Test**:
1. Create category with suboptimal icon (e.g., "Skiing" with "tree")
2. Have 3 users customize to "ski" icon
3. Verify global default icon updates to "ski"
4. Verify new users see "ski" as default

### Domain Models (Parallel after Phase 2)

- [ ] T046 [P] [US4] Create CategoryIconPreference model in lib/features/categories/domain/models/category_icon_preference.dart
- [ ] T047 [P] [US4] Add getVoteCount() method to CategoryIconPreference
- [ ] T048 [P] [US4] Add hasReachedThreshold() method to CategoryIconPreference
- [ ] T049 [P] [US4] Create CategoryIconPreferenceModel for Firestore in lib/features/categories/data/models/category_icon_preference_model.dart

### Repository Enhancement (After T046-T049)

- [ ] T050 [US4] Add recordIconPreference() method to CategoryCustomizationRepository interface
- [ ] T051 [US4] Implement recordIconPreference() with Firestore transaction in CategoryCustomizationRepositoryImpl
- [ ] T052 [US4] Implement vote count increment logic in transaction
- [ ] T053 [US4] Implement mostPopular recalculation in transaction
- [ ] T054 [US4] Implement global icon update when threshold reached (3 votes) in transaction

### Integration with Customization Flow (After T051-T054)

- [ ] T055 [US4] Update CategoryCustomizationCubit.customizeIcon() to call recordIconPreference() (non-blocking)
- [ ] T056 [US4] Add error handling for voting failures (log but don't fail customization)

### Testing (Parallel after T046-T056)

- [ ] T057 [P] [US4] Write unit tests for CategoryIconPreference model in test/features/categories/domain/models/category_icon_preference_test.dart
- [ ] T058 [P] [US4] Write unit tests for recordIconPreference() transaction in test/features/categories/data/repositories/category_customization_repository_test.dart
- [ ] T059 [P] [US4] Write integration test for voting flow in test/integration/icon_voting_flow_test.dart
- [ ] T060 [P] [US4] Test threshold logic (3 votes triggers global update)

**Phase 4 Completion Criteria**:
- ✅ Icon votes recorded silently during customization
- ✅ Global icons update after 3 votes
- ✅ Voting failures don't block customization
- ✅ FR-013: Icon preference tracking ✓
- ✅ FR-014: Global icon updates at threshold ✓
- ✅ SC-009: Suboptimal icons replaced within 10 customizations ✓

---

## Phase 5: User Story 2 - Customize Category Color for Specific Trip (P2)

**Goal**: Enable users to customize category colors per trip

**Story**: Bob wants "Transport" category to use blue instead of green for his work trip

**Independent Test**:
1. Customize "Transport" color to purple in trip settings
2. Verify color appears in expense list
3. Verify other trips still show green

### Repository Enhancement (After Phase 3)

- [ ] T061 [US2] Enhance customizeCategory() to support color parameter in CategoryCustomizationRepositoryImpl
- [ ] T062 [US2] Enhance resetCustomization() to support resetting color independently

### State Management (After T061-T062)

- [ ] T063 [US2] Add customizeColor() method to CategoryCustomizationCubit
- [ ] T064 [US2] Add resetColor() method to CategoryCustomizationCubit

### UI Components (Parallel after T063-T064)

- [ ] T065 [P] [US2] Ensure CategoryColorPicker exists in lib/features/categories/presentation/widgets/category_color_picker.dart
- [ ] T066 [P] [US2] Update CustomizeCategoriesScreen to support color customization
- [ ] T067 [P] [US2] Update CategorySelector to display custom colors

### Testing (Parallel after T061-T067)

- [ ] T068 [P] [US2] Add color customization tests to CategoryCustomizationCubit tests
- [ ] T069 [P] [US2] Write widget tests for CategoryColorPicker
- [ ] T070 [P] [US2] Add color tests to integration test suite

**Phase 5 Completion Criteria**:
- ✅ Users can customize category colors per trip
- ✅ Color and icon customizable independently
- ✅ FR-002: Color customization per trip ✓

---

## Phase 6: User Story 5 - Similar Category Detection (P2)

**Goal**: Prevent duplicate categories by detecting similar names

**Story**: Emma types "Ski"; system suggests existing "Skiing" category

**Independent Test**:
1. Create category "Skiing" with high usage
2. Attempt to create "Ski"
3. Verify warning banner appears
4. Test "Use Existing" button
5. Test "Create Anyway" button

### Repository Enhancement (Parallel after Phase 2)

- [ ] T071 [P] [US5] Add findSimilarCategories() method to CategoryRepository interface
- [ ] T072 [P] [US5] Implement findSimilarCategories() with Jaro-Winkler similarity in CategoryRepositoryImpl
- [ ] T073 [P] [US5] Add caching for category list to optimize similarity checks

### State Management (After T071-T073)

- [ ] T074 [US5] Add checkSimilarCategories() method to CategoryCubit
- [ ] T075 [US5] Add CategorySimilarExists state to CategoryState

### UI Components (After T074-T075)

- [ ] T076 [US5] Update CategoryCreationBottomSheet to call checkSimilarCategories() on name change
- [ ] T077 [US5] Add similar category warning banner to CategoryCreationBottomSheet
- [ ] T078 [US5] Implement "Use Existing" button behavior
- [ ] T079 [US5] Implement "Create Anyway" button behavior

### Testing (Parallel after T071-T079)

- [ ] T080 [P] [US5] Write unit tests for findSimilarCategories() in test/features/categories/data/repositories/category_repository_test.dart
- [ ] T081 [P] [US5] Write widget tests for similar category warning in test/features/categories/presentation/widgets/category_creation_bottom_sheet_test.dart
- [ ] T082 [P] [US5] Test fuzzy matching with various similarity levels (80%, 90%, 100%)

**Phase 6 Completion Criteria**:
- ✅ Similar categories detected during creation
- ✅ Warning banner appears with "Use Existing" option
- ✅ FR-015: Fuzzy matching at 80% threshold ✓
- ✅ FR-016: Suggest existing with usage counts ✓
- ✅ SC-010: 90% detection rate ✓

---

## Phase 7: User Story 3 - View Which Categories Are Customized (P3)

**Goal**: Visual indicators for customized vs default categories

**Story**: Clara wants to see which categories are customized in each trip

**Independent Test**:
1. Customize several categories
2. View customization screen
3. Verify "Customized" badge appears
4. Verify default categories show "Using global default"

### UI Enhancements (After Phase 3)

- [ ] T083 [US3] Add isCustomized indicator to DisplayCategory in lib/shared/utils/category_display_helper.dart
- [ ] T084 [US3] Update CustomizeCategoriesScreen to show "Customized" badge for custom categories
- [ ] T085 [US3] Add "Using global default" text for default categories
- [ ] T086 [US3] Update trip statistics to display custom visuals

### Testing (Parallel after T083-T086)

- [ ] T087 [P] [US3] Write widget tests for customization badges
- [ ] T088 [P] [US3] Test visual indicators appear correctly

**Phase 7 Completion Criteria**:
- ✅ Users can identify customized categories
- ✅ Visual distinction between custom and default
- ✅ FR-006: Visual indicators ✓
- ✅ SC-004: 95% users identify customized categories ✓

---

## Phase 8: Polish & Cross-Cutting Concerns

**Goal**: Final refinements, performance optimization, and documentation

### Performance (Parallel)

- [ ] T089 [P] Benchmark customization load times (<200ms target)
- [ ] T090 [P] Optimize category list caching for fuzzy matching
- [ ] T091 [P] Add loading states for customization operations

### Error Handling (Parallel)

- [ ] T092 [P] Add graceful fallback for missing customization data
- [ ] T093 [P] Add error messages for failed customization operations
- [ ] T094 [P] Test offline behavior (show cached customizations)

### Documentation (Parallel)

- [ ] T095 [P] Update CLAUDE.md with icon system architecture
- [ ] T096 [P] Update CHANGELOG.md with feature implementation notes
- [ ] T097 [P] Run /docs.complete to roll up changes to root

### Final Testing (Sequential)

- [ ] T098 Run full test suite and ensure >80% coverage
- [ ] T099 Run flutter analyze and resolve all warnings
- [ ] T100 Manual testing on mobile viewport (375x667px)
- [ ] T101 Manual testing on desktop viewport (>1024px)
- [ ] T102 Test with 50+ customized categories (performance check)

**Phase 8 Completion Criteria**:
- ✅ All success criteria met (SC-001 through SC-010)
- ✅ All functional requirements satisfied (FR-001 through FR-016)
- ✅ Tests passing with >80% coverage
- ✅ No lint warnings
- ✅ Performance targets met

---

## Dependencies & Execution Order

### Critical Path (Must Complete in Order):

1. **Phase 1** (Setup) → **Phase 2** (Foundational) → **Phase 3** (US1)
2. **Phase 3** (US1) → **Phase 4** (US4) [voting depends on customization]
3. **Phase 2** → **Phase 5** (US2) [independent]
4. **Phase 2** → **Phase 6** (US5) [independent]
5. **Phase 3** → **Phase 7** (US3) [visual indicators depend on customization screen]

### Parallel Opportunities:

**After Phase 2 completes**, these can run in parallel:
- Phase 3 (US1) + Phase 6 (US5) [similar detection is independent]
- Phase 5 (US2) [color customization is independent]

**After Phase 3 completes**, these can run in parallel:
- Phase 4 (US4) [voting]
- Phase 7 (US3) [visual indicators]

**Within each phase**, tasks marked `[P]` can run in parallel.

### User Story Independence:

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 (Icon Customization) | Phase 2 | US2, US5 |
| US4 (Voting) | US1 | US2, US3, US5 |
| US2 (Color Customization) | Phase 2 | US1, US4, US3, US5 |
| US5 (Similar Detection) | Phase 2 | US1, US2, US4, US3 |
| US3 (Visual Indicators) | US1 | US2, US4, US5 |

---

## Implementation Strategy

### MVP (Minimum Viable Product):

**Scope**: Phase 1 + Phase 2 + Phase 3 (US1)

**Why**: Delivers core value (icon customization per trip) with solid foundation (type-safe icons, zero duplication)

**Estimated Tasks**: 45 tasks

**Delivers**:
- Type-safe CategoryIcon enum (30 icons)
- IconHelper utility (eliminates duplication)
- Per-trip icon customization
- Reset to default functionality

### Incremental Delivery After MVP:

1. **+Phase 4**: Add voting system (makes icons self-correcting)
2. **+Phase 5**: Add color customization (completes visual customization)
3. **+Phase 6**: Add similar detection (prevents duplicates)
4. **+Phase 7**: Add visual indicators (improves UX)
5. **+Phase 8**: Polish and optimize

---

## Task Summary

**Total Tasks**: 102
**Parallel Tasks**: 42 (41% parallelizable)
**Sequential Tasks**: 60

**By Phase**:
- Phase 1 (Setup): 5 tasks
- Phase 2 (Foundational): 16 tasks (11 parallelizable)
- Phase 3 (US1): 24 tasks (10 parallelizable)
- Phase 4 (US4): 15 tasks (8 parallelizable)
- Phase 5 (US2): 10 tasks (7 parallelizable)
- Phase 6 (US5): 12 tasks (6 parallelizable)
- Phase 7 (US3): 6 tasks (2 parallelizable)
- Phase 8 (Polish): 14 tasks (10 parallelizable)

**Test Coverage**:
- Unit tests: 20 test tasks
- Widget tests: 10 test tasks
- Integration tests: 4 test tasks
- Manual testing: 5 test tasks

---

## Format Validation

✅ All tasks follow checklist format: `- [ ] [TaskID] [Labels] Description with file path`
✅ Task IDs sequential (T001-T102)
✅ Parallel tasks marked with [P]
✅ User story tasks marked with [US1], [US2], etc.
✅ File paths included where applicable
✅ Organized by user story for independent implementation

---

**Generated**: 2025-10-31
**Status**: Ready for implementation
**Next Step**: Begin with Phase 1 (Setup & Dependencies)
