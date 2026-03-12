# VOTA ZA — Setup Guide

## What's in this folder

```
vota/
├── public/
│   └── index.html        ← Your complete website (upload this to Vercel)
├── database/
│   └── schema.sql        ← Run this in Supabase to create all tables + seed data
├── server.js             ← Backend API (for Phase 2 — Railway)
├── package.json          ← Dependencies list
├── .env                  ← Your Supabase credentials (never share this)
└── README.md             ← This file
```

---

## STEP 1 — Set up your database (Do this first)

1. Go to **supabase.com** → open your project
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Open the file `database/schema.sql` and copy ALL the contents
5. Paste into the SQL editor
6. Click **Run** (green button)
7. You should see: "Success. No rows returned"
8. Go to **Table Editor** — you should see 8 parties, 6 promises, 6 voices

---

## STEP 2 — Get your website live on Vercel

1. Go to **github.com** → create a new repository called `vota-za`
2. Upload the entire `vota` folder to that repository
3. Go to **vercel.com** → click "Add New Project"
4. Connect your GitHub account → select the `vota-za` repository
5. Leave all settings as default → click **Deploy**
6. Your site will be live at `vota-za.vercel.app` within 2 minutes

---

## STEP 3 — Connect your domain (votaza.co.za)

1. In Vercel → go to your project → **Settings** → **Domains**
2. Type `votaza.co.za` and click Add
3. Vercel will show you DNS records to add
4. Go to **domains.co.za** → your domain → DNS settings
5. Add the records Vercel shows you
6. Wait 10–30 minutes for DNS to propagate
7. Your site is now live at **votaza.co.za** 🇿🇦

---

## STEP 4 — Run the backend locally (optional for now)

```bash
# Install dependencies
npm install

# Start the server
npm run dev

# Server runs at http://localhost:3000
# Test it: http://localhost:3000/api/parties
```

---

## How to add/update content

**Add a new party:**
1. Supabase → Table Editor → parties → Insert Row
2. Fill in all fields
3. Set is_active = true
4. It appears on the site immediately

**Add a new promise/receipt:**
1. Supabase → Table Editor → promises → Insert Row
2. You need the party_id (copy it from the parties table)
3. Fill in promise_text, reality_text, status, source

**Add a new voice:**
1. Supabase → Table Editor → voices → Insert Row

---

## Your credentials

- Supabase URL: https://mfhxcpwmehbbrffhywch.supabase.co
- Supabase Anon Key: in your .env file
- Dashboard: supabase.com (log in with your account)

---

## Next phases (we'll build these together)

- Phase 3: User accounts (login, save quiz results, bookmarks)
- Phase 4: News feed (live SA political news)
- Phase 5: Municipal ward lookup by location
- Phase 6: Email newsletter campaigns

---

Built with Claude. For South Africa. 🇿🇦
