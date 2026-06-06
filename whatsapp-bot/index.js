const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Supabase configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

/**
 * Get business summary for a specific phone number
 * This includes revenue, profit, debt, and inventory value
 */
app.get('/api/:phone/summary', async (req, res) => {
  const { phone } = req.params;
  
  try {
    const { data, error } = await supabase
      .from('user_summaries')
      .select('*')
      .eq('phone_number_id', phone)
      .single();

    if (error) throw error;
    if (!data) return res.status(404).json({ message: 'No data found for this phone number' });

    res.json(data);
  } catch (error) {
    console.error('Error fetching summary:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get current inventory levels
 */
app.get('/api/:phone/inventory', async (req, res) => {
  const { phone } = req.params;

  try {
    const { data, error } = await supabase
      .from('inventory_sync')
      .select('*')
      .eq('phone_number_id', phone);

    if (error) throw error;
    res.json(data);
  } catch (error) {
    console.error('Error fetching inventory:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get recent sales transactions
 */
app.get('/api/:phone/sales', async (req, res) => {
  const { phone } = req.params;

  try {
    const { data, error } = await supabase
      .from('recent_transactions')
      .select('*')
      .eq('phone_number_id', phone)
      .eq('type', 'sale')
      .order('created_at', { ascending: false })
      .limit(5);

    if (error) throw error;
    res.json(data);
  } catch (error) {
    console.error('Error fetching sales:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * WhatsApp Bot Webhook (Placeholder)
 * This is where you would handle incoming messages from WhatsApp
 */
app.post('/api/whatsapp/webhook', async (req, res) => {
  // Logic to handle WhatsApp messages and use the above APIs to respond
  console.log('Received WhatsApp message:', req.body);
  res.status(200).send('EVENT_RECEIVED');
});

app.listen(port, () => {
  console.log(`Zayi WhatsApp Bot API listening at http://localhost:${port}`);
});
