// ================================================
// VOTA ZA — Backend Server
// ================================================
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Supabase client ──
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// ── Middleware ──
app.use(cors());
app.use(express.json());
app.use(express.static('public')); // serves your frontend HTML

// ── Health check ──
app.get('/api/health', (req, res) => {
  res.json({ status: 'VOTA API is running', timestamp: new Date().toISOString() });
});

// ================================================
// PARTIES
// ================================================

// GET all active parties
app.get('/api/parties', async (req, res) => {
  try {
    const { spectrum, search } = req.query;
    let query = supabase
      .from('parties')
      .select('*')
      .eq('is_active', true)
      .order('name');

    if (spectrum && spectrum !== 'all') {
      query = query.eq('spectrum', spectrum);
    }

    const { data, error } = await query;
    if (error) throw error;

    // Filter by search term if provided
    let result = data;
    if (search) {
      const q = search.toLowerCase();
      result = data.filter(p =>
        p.name.toLowerCase().includes(q) ||
        p.abbreviation.toLowerCase().includes(q)
      );
    }

    res.json({ success: true, data: result });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET single party by ID
app.get('/api/parties/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('parties')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error) throw error;
    res.json({ success: true, data });
  } catch (err) {
    res.status(404).json({ success: false, error: 'Party not found' });
  }
});

// GET party by abbreviation (e.g. /api/parties/abbr/ANC)
app.get('/api/parties/abbr/:abbr', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('parties')
      .select('*')
      .ilike('abbreviation', req.params.abbr)
      .single();

    if (error) throw error;
    res.json({ success: true, data });
  } catch (err) {
    res.status(404).json({ success: false, error: 'Party not found' });
  }
});

// ================================================
// PROMISES (Receipts)
// ================================================

// GET all promises (with optional filters)
app.get('/api/promises', async (req, res) => {
  try {
    const { status, party_id, topic } = req.query;
    let query = supabase
      .from('promises')
      .select(`
        *,
        parties (name, abbreviation, color)
      `)
      .order('year_made', { ascending: false });

    if (status) query = query.eq('status', status);
    if (party_id) query = query.eq('party_id', party_id);
    if (topic) query = query.eq('topic', topic);

    const { data, error } = await query;
    if (error) throw error;
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET promises for a specific party
app.get('/api/parties/:id/promises', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('promises')
      .select('*')
      .eq('party_id', req.params.id)
      .order('year_made', { ascending: false });

    if (error) throw error;
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ================================================
// VOICES
// ================================================

// GET all voices
app.get('/api/voices', async (req, res) => {
  try {
    const { type, featured } = req.query;
    let query = supabase
      .from('voices')
      .select('*')
      .eq('is_active', true)
      .order('is_featured', { ascending: false });

    if (type) query = query.eq('type', type);
    if (featured === 'true') query = query.eq('is_featured', true);

    const { data, error } = await query;
    if (error) throw error;
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ================================================
// NEWSLETTER
// ================================================

// POST subscribe to newsletter
app.post('/api/newsletter/subscribe', async (req, res) => {
  try {
    const { email, source } = req.body;
    if (!email || !email.includes('@')) {
      return res.status(400).json({ success: false, error: 'Valid email required' });
    }

    // Check if already subscribed
    const { data: existing } = await supabase
      .from('newsletter_subscribers')
      .select('id, is_active')
      .eq('email', email.toLowerCase())
      .single();

    if (existing) {
      if (existing.is_active) {
        return res.json({ success: true, message: 'Already subscribed!' });
      }
      // Reactivate
      await supabase
        .from('newsletter_subscribers')
        .update({ is_active: true })
        .eq('email', email.toLowerCase());
      return res.json({ success: true, message: 'Welcome back!' });
    }

    const { error } = await supabase
      .from('newsletter_subscribers')
      .insert({ email: email.toLowerCase(), source: source || 'homepage' });

    if (error) throw error;

    // Track the event
    await supabase.from('analytics_events').insert({
      event_name: 'newsletter_subscribed',
      event_data: { source: source || 'homepage' }
    });

    res.json({ success: true, message: 'Subscribed successfully! Welcome to VOTA.' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ================================================
// QUIZ RESULTS
// ================================================

// POST save quiz result
app.post('/api/quiz/save', async (req, res) => {
  try {
    const { session_id, answers, scores, top_party_abbreviation } = req.body;

    // Get the top party ID
    let top_party_id = null;
    if (top_party_abbreviation) {
      const { data: party } = await supabase
        .from('parties')
        .select('id')
        .ilike('abbreviation', top_party_abbreviation)
        .single();
      if (party) top_party_id = party.id;
    }

    const { data, error } = await supabase
      .from('quiz_results')
      .insert({ session_id, answers, scores, top_party_id })
      .select()
      .single();

    if (error) throw error;

    // Track the event
    await supabase.from('analytics_events').insert({
      event_name: 'quiz_completed',
      event_data: { top_party: top_party_abbreviation }
    });

    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET quiz stats (which parties come up most)
app.get('/api/quiz/stats', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('quiz_results')
      .select(`
        top_party_id,
        parties (name, abbreviation, color)
      `);

    if (error) throw error;

    // Count by party
    const counts = {};
    data.forEach(r => {
      if (r.parties) {
        const key = r.parties.abbreviation;
        counts[key] = (counts[key] || 0) + 1;
      }
    });

    const sorted = Object.entries(counts)
      .sort((a, b) => b[1] - a[1])
      .map(([abbr, count]) => ({ abbreviation: abbr, count }));

    res.json({ success: true, data: sorted, total: data.length });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ================================================
// ANALYTICS
// ================================================

// POST track an event
app.post('/api/analytics/event', async (req, res) => {
  try {
    const { event_name, event_data } = req.body;
    await supabase.from('analytics_events').insert({ event_name, event_data });
    res.json({ success: true });
  } catch (err) {
    res.status(200).json({ success: true }); // Never fail on analytics
  }
});

// GET analytics summary (admin use)
app.get('/api/analytics/summary', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('analytics_events')
      .select('event_name')
      .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());

    if (error) throw error;

    const counts = {};
    data.forEach(e => {
      counts[e.event_name] = (counts[e.event_name] || 0) + 1;
    });

    const { data: subCount } = await supabase
      .from('newsletter_subscribers')
      .select('id', { count: 'exact' })
      .eq('is_active', true);

    res.json({
      success: true,
      events_last_30_days: counts,
      newsletter_subscribers: subCount?.length || 0
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ================================================
// SEARCH
// ================================================

app.get('/api/search', async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.length < 2) {
      return res.json({ success: true, data: { parties: [], promises: [], voices: [] } });
    }

    const term = `%${q}%`;

    const [partiesRes, promisesRes, voicesRes] = await Promise.all([
      supabase.from('parties').select('id, name, abbreviation, color, spectrum').ilike('name', term).eq('is_active', true).limit(5),
      supabase.from('promises').select('id, promise_text, status, party_id').ilike('promise_text', term).limit(5),
      supabase.from('voices').select('id, name, handle, bio').ilike('name', term).limit(5),
    ]);

    res.json({
      success: true,
      data: {
        parties: partiesRes.data || [],
        promises: promisesRes.data || [],
        voices: voicesRes.data || [],
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ================================================
// START SERVER
// ================================================
app.listen(PORT, () => {
  console.log(`\n🇿🇦 VOTA API running on http://localhost:${PORT}`);
  console.log(`📊 Supabase: ${process.env.SUPABASE_URL}`);
  console.log(`\nEndpoints ready:`);
  console.log(`  GET  /api/parties`);
  console.log(`  GET  /api/parties/:id`);
  console.log(`  GET  /api/promises`);
  console.log(`  GET  /api/voices`);
  console.log(`  POST /api/newsletter/subscribe`);
  console.log(`  POST /api/quiz/save`);
  console.log(`  GET  /api/search?q=`);
});
