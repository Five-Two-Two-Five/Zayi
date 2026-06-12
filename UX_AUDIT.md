# Zayi UI/UX Audit & Recommendations

## 1. Visual Design & Theme

### Current State
- **Minimalist Aesthetic:** The Instagram-inspired theme is clean, professional, and modern.
- **Color Usage:** Heavily relies on white and the accent blue. Financial "meaning" (profit/loss) isn't always reflected in colors.

### Recommendations
- **Semantic Coloring:** Introduce meaningful colors for financial data. Net profit should be green, losses red, and debts amber. 
- **Dark Mode Support:** Business users often work in different lighting conditions. Adding a dark mode would be a significant UX boost.
- **Iconography:** Use more descriptive icons for summary metrics (e.g., a trend-up icon for revenue, a package icon for stock).

---

## 2. Navigation & Layout

### Current State
- **Bottom Navigation:** Solid, industry-standard approach.
- **Information Density:** Some screens, like the Dashboard and Sales list, are quite dense.

### Recommendations
- **Dashboard Filters:** The dropdowns for Currency and Payment Method at the top of the Dashboard take up vertical space and feel "heavy." 
    - *Idea:* Use a horizontal scrolling list of `FilterChip` widgets for quicker toggling.
- **Sales List Clarity:** 
    - *Idea:* Replace standard `ListTile` with a custom widget that uses a "Chip" for the payment status (Paid/Partial/Unpaid).
    - *Safety:* Add a "Confirm Delete" dialog to the `Dismissible` action in `SaleScreen`.

---

## 3. Data Entry (Form UX)

### Current State
- **Complex Forms:** `SaleFormPage` is a long vertical scroll with many fields.
- **Quick Actions:** The "Add New Customer" within the sale flow is excellent UX.

### Recommendations
- **Step-based Forms:** For complex sales (with taxes, multiple currencies, etc.), consider a multi-step form or clear visual sectioning (e.g., "Customer Info", "Transaction Details", "Payment").
- **Input Types:** Use `SegmentedButton` or `ChoiceChip` for fields with few options (like Payment Method) instead of dropdowns to reduce the number of clicks.
- **Smart Defaults:** Pre-fill fields where possible based on previous entries or settings.

---

## 4. Visualizations & Reports

### Current State
- **Charts:** The `fl_chart` implementation is clean and fits the theme well.

### Recommendations
- **Interactivity:** Ensure all charts have touch tooltips (currently implemented in `TrendChart`, but ensure consistency).
- **Empty States:** When no data is available, replace the "No data" text with a small illustration and a clear "Add Data" call-to-action button.

---

## 5. Specific Widget Improvements

### `_buildSummaryCard`
- Add a subtle background trend line (sparkline) behind the main number to show recent movement at a glance.

### `_buildLargeButton`
- Use more vibrant colors for primary actions (e.g., "NEW SALE" could be a soft green) to help them stand out from secondary actions.

---

## Proposed Action Plan

1.  **Immediate:** Add confirmation dialogs to destructive actions (delete).
2.  **Visual:** Implement semantic colors (Red/Green) in the Dashboard and Sales lists.
3.  **Refinement:** Replace Dashboard filter dropdowns with `FilterChip` widgets.
4.  **Polish:** Add "Empty State" illustrations for better user onboarding.
