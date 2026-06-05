# WhatsApp Bot

This bot provides automated inventory checking and order management via WhatsApp.

## Prerequisites

- Node.js installed
- A Supabase project set up with the following tables:
  - `whatsapp_settings`: (`phone_number_id`, `access_token`, `verify_token`)
  - `inventory_sync`: (`phone_number_id`, `product_name`, `balance`)
  - `incoming_orders`: (`phone_number_id`, `customer_phone`, `product_name`, `quantity`, `status`)

## Setup

1. Copy `.env.example` to `.env` and fill in the required variables:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_KEY`
   - `PORT` (e.g., 3000)
   - `USE_WEB_JS` (true or false)
   - `DEFAULT_PHONE_NUMBER_ID` (if `USE_WEB_JS` is true)

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the bot:
   ```bash
   npm start
   ```

## Functionality

- **Stock Check:** Send "stock" to see current product balances.
- **Order Placement:** Send "Order [Quantity] [Product Name]" to place a pending order.
