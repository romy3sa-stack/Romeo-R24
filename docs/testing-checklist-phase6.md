# Phase 6 Testing Checklist

## Expense Categories (6.1)
- [ ] All 16 seeded categories load in classification dropdown
- [ ] Categories display tax_deductible and vat_eligible flags in data model

## Automatic Categorisation (6.2)
- [ ] Suggested category shown after saving receipt
- [ ] Confidence score displayed
- [ ] Reason for suggestion shown
- [ ] Merchant keyword rules work (e.g. Shell → Fuel)
- [ ] User can override suggested category
- [ ] Past user confirmations influence future suggestions

## Business/Personal Classification (6.3)
- [ ] Personal, Business, Mixed use options available
- [ ] Mixed use shows business percentage slider
- [ ] Classification saved to receipt_expense_classification
- [ ] Expense type badge shown on receipt wallet cards
- [ ] Filter by expense type in wallet works

## Duplicate Detection (6.4)
- [ ] Duplicate flagged when merchant + amount match
- [ ] Duplicate never auto-deleted
- [ ] Warning banner on receipt detail
- [ ] Duplicate alerts screen lists flagged receipts
- [ ] "Not a duplicate" dismisses flag
- [ ] Badge count on wallet app bar

## Integration
- [ ] Auto-classify runs after OCR save
- [ ] Auto-classify runs after manual entry
- [ ] Classification card on receipt detail screen
- [ ] Save classification refreshes wallet and detail
