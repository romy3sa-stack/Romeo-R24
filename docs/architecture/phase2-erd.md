# Phase 2 — Entity Relationship Diagram

```mermaid
erDiagram
  AUTH_USERS ||--|| USERS : "id"
  USERS ||--o| CONSUMER_PROFILES : "user_id"
  USERS ||--o| ACCOUNTANTS : "user_id"
  ACCOUNTANTS ||--o{ ACCOUNTING_FIRM_MEMBERS : "accountant_id"
  USERS ||--o{ ACCOUNTING_FIRM_MEMBERS : "user_id"
  ACCOUNTANTS ||--o{ ACCOUNTANT_CLIENT_ACCESS : "accountant_id"
  USERS ||--o{ ACCOUNTANT_CLIENT_ACCESS : "consumer_user_id"
  USERS ||--o{ RECEIPTS : "consumer_user_id"
  MERCHANTS ||--o{ RECEIPTS : "merchant_id"
  RECEIPT_CATEGORIES ||--o{ RECEIPTS : "receipt_category_id"
  RECEIPTS ||--o{ RECEIPT_ITEMS : "receipt_id"
  RECEIPTS ||--o| RECEIPT_EXPENSE_CLASSIFICATION : "receipt_id"
  EXPENSE_CATEGORIES ||--o{ RECEIPT_EXPENSE_CLASSIFICATION : "expense_category_id"
  USERS ||--o{ RECEIPT_UPLOADS : "user_id"
  RECEIPTS ||--o{ RECEIPT_UPLOADS : "linked_receipt_id"
  RECEIPTS ||--o{ WARRANTIES : "receipt_id"
  RECEIPTS ||--o{ RETURNS_AND_REFUNDS : "receipt_id"
  RECEIPTS ||--o{ DUPLICATE_RECEIPT_ALERTS : "primary/duplicate"
  USERS ||--o{ NOTIFICATIONS : "user_id"
  USERS ||--o{ SUBSCRIPTIONS : "user_id"
  ACCOUNTANTS ||--o{ SUBSCRIPTIONS : "accountant_id"
  SUBSCRIPTION_PLANS ||--o{ SUBSCRIPTIONS : "plan_id"
  USERS ||--o{ SUPPORT_TICKETS : "user_id"
  USERS ||--o{ AUDIT_LOGS : "user_id"
  USERS ||--o{ USER_DEVICES : "user_id"
  ACCOUNTANTS ||--o{ DOCUMENT_REQUESTS : "accountant_id"
  ACCOUNTANTS ||--o{ ACCOUNTANT_NOTES : "accountant_id"

  MERCHANTS {
    uuid id PK
    text merchant_name
    enum merchant_source
    note "No auth.users link"
  }
```

Merchant records are receipt metadata only — never platform users.
