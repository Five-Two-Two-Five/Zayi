require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(bodyParser.json());

const PORT = process.env.PORT || 3000;
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);

// 1. Message Processing Logic (Refactored)
async function handleMessage(phoneNumberId, from, text) {
    console.log(`Processing message from ${from}: ${text}`);
    
    // Lookup business credentials
    const { data: settings } = await supabase
        .from('whatsapp_settings')
        .select('*')
        .eq('phone_number_id', phoneNumberId)
        .single();

    if (!settings) {
        console.error(`No settings found for Phone ID: ${phoneNumberId}`);
        return;
    }

    if (text.includes('order')) {
        // Simplified parsing: "order 5 chicken"
        const parts = text.split(' ');
        if (parts.length < 3) {
            await sendMessage(phoneNumberId, settings.access_token, from, "Please format as: 'Order [Quantity] [Product Name]' (e.g., 'Order 5 Chickens')");
            return;
        }
        const quantity = parseInt(parts[1]);
        const productName = parts.slice(2).join(' ');

        // 1. Check stock
        const { data: inventory } = await supabase
            .from('inventory_sync')
            .select('balance')
            .eq('phone_number_id', phoneNumberId)
            .ilike('product_name', `%${productName}%`)
            .single();

        if (!inventory || inventory.balance < quantity) {
            await sendMessage(phoneNumberId, settings.access_token, from, `Sorry, we only have ${inventory?.balance || 0} ${productName} available.`);
            return;
        }

        // 2. Store Order
        const { error } = await supabase
            .from('incoming_orders')
            .insert({
                phone_number_id: phoneNumberId,
                customer_phone: from,
                product_name: productName,
                quantity: quantity,
                status: 'pending'
            });

        if (error) {
            await sendMessage(phoneNumberId, settings.access_token, from, "Error placing order. Please try again later.");
            console.error('Order insert error:', error);
        } else {
            await sendMessage(phoneNumberId, settings.access_token, from, `Order confirmed! We've received your request for ${quantity} ${productName}.`);
        }
    } else if (text.includes('stock')) {
        const { data: inventory } = await supabase
            .from('inventory_sync')
            .select('product_name, balance')
            .eq('phone_number_id', phoneNumberId);
        
        const response = inventory && inventory.length > 0
            ? inventory.map(item => `${item.product_name}: ${item.balance}`).join('\n')
            : "No stock information available.";
        
        await sendMessage(phoneNumberId, settings.access_token, from, `Current Stock:\n${response}`);
    } else {
        await sendMessage(phoneNumberId, settings.access_token, from, "Welcome! Type 'stock' to check availability or 'Order [Qty] [Product]' to place an order.");
    }
}

// 2. Helper: Send Message
async function sendMessage(phoneNumberId, accessToken, to, text) {
    try {
        await axios({
            method: 'POST',
            url: `https://graph.facebook.com/v18.0/${phoneNumberId}/messages?access_token=${accessToken}`,
            data: { messaging_product: 'whatsapp', to: to, text: { body: text } },
            headers: { 'Content-Type': 'application/json' },
        });
    } catch (error) {
        console.error('Error sending message:', error.response?.data || error.message);
    }
}

// 3. Webhook Verification
app.get('/webhook', async (req, res) => {
    const mode = req.query['hub.mode'];
    const challenge = req.query['hub.challenge'];
    const verifyToken = req.query['hub.verify_token'];

    // Lookup settings for this specific business
    const { data: settings } = await supabase
        .from('whatsapp_settings')
        .select('verify_token')
        .eq('verify_token', verifyToken)
        .single();

    if (mode === 'subscribe' && settings) {
        res.status(200).send(challenge);
    } else {
        res.sendStatus(403);
    }
});

// 4. Webhook Receiver
app.post('/webhook', async (req, res) => {
    const body = req.body;
    if (body.object !== 'whatsapp_business_account') return res.sendStatus(404);

    for (const entry of body.entry) {
        for (const change of entry.changes) {
            if (!change.value.messages) continue;

            for (const message of change.value.messages) {
                const phoneNumberId = change.value.metadata.phone_number_id;
                const from = message.from;
                const text = message.text ? message.text.body.toLowerCase() : '';

                await handleMessage(phoneNumberId, from, text);
            }
        }
    }
    res.sendStatus(200);
});

// 5. Start Server
app.listen(PORT, () => console.log(`Webhook server listening on port ${PORT}`));

// 6. Optional: WhatsApp Web Service integration
if (process.env.USE_WEB_JS === 'true') {
    console.log('Running in Unofficial WhatsApp Web mode');
    const client = require('./whatsapp_web_service.js');
    
    // Note: For whatsapp-web.js, phone_number_id is not available via metadata
    // We assume the bot owner's phone ID from settings or a default
    client.on('message', async msg => {
        const from = msg.from;
        const text = msg.body.toLowerCase();
        
        // This is a limitation of the workaround: 
        // We need to know which phone_number_id this corresponds to in Supabase
        const phoneNumberId = process.env.DEFAULT_PHONE_NUMBER_ID; 
        
        await handleMessage(phoneNumberId, from, text);
    });
}
