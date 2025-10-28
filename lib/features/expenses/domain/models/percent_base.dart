/// Base for percentage-based extra calculations
///
/// Defines what subtotal percentage-based extras (tax, tip, fees, discounts)
/// should be applied to
enum PercentBase {
  /// Pre-tax item subtotals (sum of all items before tax/discounts)
  preTaxItemSubtotals('Pre-tax Item Subtotals'),

  /// Only taxable item subtotals (excludes tax-exempt items)
  taxableItemSubtotalsOnly('Taxable Items Only'),

  /// Post-discount item subtotals (after discounts applied)
  postDiscountItemSubtotals('Post-discount Item Subtotals'),

  /// Post-tax subtotals (after tax applied, for calculating tip on taxed amount)
  postTaxSubtotals('Post-tax Subtotals'),

  /// Post-fees subtotals (after fees applied)
  postFeesSubtotals('Post-fees Subtotals');

  /// Display name for UI
  final String displayName;

  const PercentBase(this.displayName);

  /// Parse from string
  static PercentBase? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pretaxitemsubtotals':
      case 'pre_tax_item_subtotals':
        return PercentBase.preTaxItemSubtotals;
      case 'taxableitemsubtotalsonly':
      case 'taxable_item_subtotals_only':
        return PercentBase.taxableItemSubtotalsOnly;
      case 'postdiscountitemsubtotals':
      case 'post_discount_item_subtotals':
        return PercentBase.postDiscountItemSubtotals;
      case 'posttaxsubtotals':
      case 'post_tax_subtotals':
        return PercentBase.postTaxSubtotals;
      case 'postfeessubtotals':
      case 'post_fees_subtotals':
        return PercentBase.postFeesSubtotals;
      default:
        return null;
    }
  }

  /// Convert to string for serialization
  String toFirestore() {
    return toString().split('.').last;
  }
}
