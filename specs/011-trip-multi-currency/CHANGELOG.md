# Feature Changelog: Feature 011

**Feature ID**: 011-trip-multi-currency

This changelog tracks all changes made during the development of this feature.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- [New features, files, or capabilities added]

### Changed
- [Changes to existing functionality]

### Fixed
- [Bug fixes]

### Removed
- [Removed features or files]

---

## Development Log

<!-- Add entries below in reverse chronological order (newest first) -->

## 2025-11-03

### Changed
- Fixed remaining mock generation issues in trip_create_flow_test.mocks.dart and device_pairing_flow_test.mocks.dart. Applied same fix (adding CurrencyCode import and updating method signatures). All compilation errors resolved - flutter analyze now shows 0 errors.


## 2025-11-03

### Changed
- Completed T033: Fixed mock generation issues and validated cubit unit tests. Manually added CurrencyCode import to both settlement_cubit_test.mocks.dart and trip_cubit_test.mocks.dart, then updated getAllowedCurrencies and updateAllowedCurrencies method signatures to use proper types (List<CurrencyCode> instead of List<dynamic>, String instead of String?). All 4 T033 tests now passing: USD/EUR currency filtering, correct base currency emission, and null filter handling.


## 2025-11-03

### Changed
- Completed T030, T031, T032: Implemented complete per-currency settlement UI flow. T030: Added currency switcher (SegmentedButton) to settlements page showing allowed currencies. T031: Implemented empty state UI when no expenses exist in selected currency. T032: Added SettlementCubit.loadSettlementForCurrency() method to load settlements filtered by currency, connected to UI. Currency switcher now triggers real settlement recomputation. All T027 (7/7) and T028 (8/8) tests passing.


## 2025-11-03

### Changed
- Completed T031: Added empty state UI for currencies with no expenses. When activeTransfers and settledTransfers are both empty, displays centered empty state with wallet icon (Icons.account_balance_wallet_outlined), message 'No expenses in {CURRENCY}', and suggestion 'Try switching to another currency to view settlements'. All 8 T028 widget tests now passing.


## 2025-11-03

### Changed
- Completed T029: Updated SettlementRepository to accept optional currencyFilter parameter. Modified both domain interface and implementation (SettlementRepositoryImpl) to pass currencyFilter through to SettlementCalculator methods. When currencyFilter is provided, it becomes the baseCurrency for filtered settlement calculations. Updated computeSettlement() and computeSettlementWithExpenses() methods. All T027 tests still passing.


## 2025-11-03

### Changed
- Completed T028: Created comprehensive widget tests for currency-switcher UI in settlements page. Tests cover: 1) Rendering tabs/dropdown for allowed currencies, 2) Currency switching interactions, 3) Currency-filtered settlement display, 4) Empty state handling. Tests written following TDD (RED phase - 6/8 tests failing as expected, awaiting T030-T031 implementation). Generated mocks for SettlementCubit, TripCubit, and ExpenseRepository.


## 2025-11-03

### Changed
- Completed T027: Implemented per-currency settlement calculations with TDD approach. Added optional currencyFilter parameter to all settlement calculation methods (calculateSettlementData, calculatePersonSummaries, calculatePersonCategorySpending, calculatePairwiseNetTransfers). Filter enables independent settlement calculations per currency without cross-currency conversion. Updated rounding error tolerance to 0.02 to account for division precision. All 7 comprehensive unit tests passing.


## 2025-11-03

### Changed
- Completed T024-T026: Multi-currency support for itemized expense wizard and validation. Added currency dropdown to receipt info step (Step 1) filtering to trip's allowed currencies. Updated ItemizedExpenseCubit.setReceiptInfo() to accept optional currencyCode parameter. Quick-add expense already complete via ExpenseFormBottomSheet. Added client-side validation with warning message for expenses using non-allowed currencies. Created integration test (T022) with 3 scenarios. Fixed expense_form_test.dart by adding CategoryCubit and CategoryCustomizationCubit mock dependencies.


## 2025-11-03

### Changed
- Completed T022: Created integration test for multi-currency expense creation flow. Test file at test/integration/expense_currency_flow_test.dart includes 3 test scenarios: (1) end-to-end expense creation with filtered currencies, (2) verification that currency dropdown only shows trip's allowed currencies, (3) verification that default currency is pre-selected for new expenses. Tests use IntegrationTestWidgetsFlutterBinding for full app integration testing.


## 2025-11-03

### Changed
- Completed T026: Added client-side validation for currency selection. New expenses can only select from trip's allowedCurrencies (enforced by filtered dropdown). Existing expenses can keep their currency for backward compatibility. Added informative warning message when editing expense with currency no longer in allowed list ('Note: XXX is no longer in the allowed currencies'). Validation rules clearly documented in code comments.


## 2025-11-03

### Changed
- Completed T024-T025: Updated itemized expense form currency dropdown. Added currency selector to ReceiptInfoStepPage (Step 1 of itemized wizard) that filters to trip's 1-10 allowed currencies. Currency selection updates cubit and is used for all amount fields. Updated ItemizedExpenseCubit.setReceiptInfo() to accept optional currencyCode parameter. All ItemizedExpenseWizard call sites updated to pass allowedCurrencies. Quick-add expense already complete - uses ExpenseFormBottomSheet which was updated in T023.


## 2025-11-03

### Changed
- Completed Phase 4 - User Story 2: Filtered Expense Currency Selection (T021-T023). Added 6 comprehensive widget tests for expense form currency dropdown covering filtering by trip's allowed currencies, pre-selection of default currency, and backward compatibility for existing expenses. Implemented currency dropdown filtering in ExpenseFormPage and ExpenseFormBottomSheet - currency dropdowns now show only trip's 1-10 allowed currencies instead of all 170+ currencies. Added backward compatibility to preserve existing expense currencies even if not in current allowed list. Default currency (first in allowedCurrencies) pre-selected for new expenses. ✅


## 2025-11-03

### Changed
- Completed Phase 3 - User Story 1: Multi-Currency Selection UI (T015-T020). Implemented MultiCurrencySelector widget with 19 passing widget tests covering rendering, add/remove/reorder, validation, accessibility, and responsive design. Added TripCubit.updateTripCurrencies() method with 9 passing unit tests covering success, error handling, activity logging, and edge cases. Integrated currency selector into Trip Settings page with modal bottom sheet UI. Activity logging verified working end-to-end - logs currency changes when actorName provided, skips logging when actorName null/empty. All 28 new tests passing ✅


## 2025-11-03

### Changed
- Implemented TripCubit.updateTripCurrencies() method with TDD approach. Created 9 comprehensive unit tests covering success scenarios, error handling (trip not found, repository errors), activity logging (with/without actor name), field preservation, and edge cases (single currency, maximum 10 currencies). Method updates trip's allowedCurrencies, refreshes state, and logs activity when actorName provided. All tests passing ✅


## 2025-11-03

### Changed
- Implemented MultiCurrencySelector widget with TDD approach. Created 19 comprehensive widget tests covering rendering, user interactions (add/remove/reorder), validation (min/max currencies), accessibility (tooltips/semantics), responsive design (mobile/desktop), and edge cases. Widget uses custom Material container instead of standard Chip to support interactive buttons. All tests passing ✅


## 2025-11-03

### Changed
- Fixed mock signature errors and deprecated baseCurrency usage. Resolved getAllowedCurrencies return type in all mock files (List<CurrencyCode> instead of List<dynamic>), fixed duplicate import alias in device_pairing_flow_test.mocks.dart, and updated tests to use allowedCurrencies instead of deprecated baseCurrency. All 63 multi-currency tests passing with 0 compilation errors.


## 2025-11-03

### Changed
- test: Added comprehensive TDD tests for multi-currency foundation (T011-T014). Created 63 passing tests across Trip domain model (30 tests), TripModel serialization (20 tests), and TripRepository methods (13 tests). Tests cover validation, migration logic, error handling, and backward compatibility. Foundation layer fully tested before UI implementation begins.


## 2025-11-02

### Changed
- Complete Spec-Kit planning workflow: specification (4 user stories), implementation plan (mobile-first), task breakdown (58 tasks in 7 phases), cross-artifact analysis (passed), and implementation readiness checklist (125 quality checks). Ready for implementation.


## 2025-11-02 - Initial Setup

### Added
- Created feature specification
- Set up feature branch
- Initialized documentation structure
