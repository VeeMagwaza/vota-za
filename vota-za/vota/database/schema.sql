-- ================================================
-- VOTA ZA — Complete Database Schema
-- Run this in your Supabase SQL Editor
-- Go to: Supabase Dashboard → SQL Editor → New Query
-- Paste everything below and click RUN
-- ================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ================================================
-- PARTIES TABLE
-- ================================================
create table if not exists parties (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  abbreviation text not null,
  color text not null default '#888888',
  spectrum text check (spectrum in ('left', 'centre', 'right', 'far-left', 'far-right', 'populist')),
  description text,
  leader text,
  founded_year integer,
  website_url text,
  logo_url text,
  economy_score integer default 0 check (economy_score >= 0 and economy_score <= 100),
  delivery_score integer default 0 check (delivery_score >= 0 and delivery_score <= 100),
  transparency_score integer default 0 check (transparency_score >= 0 and transparency_score <= 100),
  economy_policy text,
  land_policy text,
  healthcare_policy text,
  education_policy text,
  safety_policy text,
  energy_policy text,
  is_active boolean default true,
  is_national boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- ================================================
-- PROMISES TABLE
-- ================================================
create table if not exists promises (
  id uuid primary key default uuid_generate_v4(),
  party_id uuid references parties(id) on delete cascade,
  promise_text text not null,
  source text,
  source_url text,
  year_made integer,
  topic text check (topic in ('economy', 'land', 'housing', 'healthcare', 'education', 'safety', 'energy', 'corruption', 'other')),
  status text check (status in ('kept', 'broken', 'partial', 'pending')),
  reality_text text,
  evidence_url text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- ================================================
-- VOICES TABLE
-- ================================================
create table if not exists voices (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  handle text,
  bio text,
  type text check (type in ('analyst', 'journalist', 'podcast', 'youtube', 'commentator')),
  platforms text[] default '{}',
  tags text[] default '{}',
  avatar_initials text,
  is_featured boolean default false,
  is_active boolean default true,
  created_at timestamp with time zone default now()
);

-- ================================================
-- NEWSLETTER SUBSCRIBERS TABLE
-- ================================================
create table if not exists newsletter_subscribers (
  id uuid primary key default uuid_generate_v4(),
  email text unique not null,
  subscribed_at timestamp with time zone default now(),
  is_active boolean default true,
  source text default 'homepage'
);

-- ================================================
-- QUIZ RESULTS TABLE
-- ================================================
create table if not exists quiz_results (
  id uuid primary key default uuid_generate_v4(),
  session_id text,
  answers jsonb,
  top_party_id uuid references parties(id),
  scores jsonb,
  created_at timestamp with time zone default now()
);

-- ================================================
-- ANALYTICS EVENTS TABLE
-- ================================================
create table if not exists analytics_events (
  id uuid primary key default uuid_generate_v4(),
  event_name text not null,
  event_data jsonb,
  created_at timestamp with time zone default now()
);

-- ================================================
-- AUTO-UPDATE updated_at TRIGGER
-- ================================================
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger parties_updated_at before update on parties
  for each row execute function update_updated_at();

create trigger promises_updated_at before update on promises
  for each row execute function update_updated_at();

-- ================================================
-- ROW LEVEL SECURITY (RLS)
-- Public can read parties, promises, voices
-- Only authenticated users can write
-- ================================================
alter table parties enable row level security;
alter table promises enable row level security;
alter table voices enable row level security;
alter table newsletter_subscribers enable row level security;
alter table quiz_results enable row level security;
alter table analytics_events enable row level security;

-- Public read access
create policy "Public read parties" on parties for select using (true);
create policy "Public read promises" on promises for select using (true);
create policy "Public read voices" on voices for select using (true);

-- Public insert for newsletter and quiz
create policy "Public insert newsletter" on newsletter_subscribers for insert with check (true);
create policy "Public insert quiz" on quiz_results for insert with check (true);
create policy "Public insert analytics" on analytics_events for insert with check (true);

-- ================================================
-- SEED DATA — PARTIES
-- ================================================
insert into parties (name, abbreviation, color, spectrum, description, leader, founded_year, website_url, economy_score, delivery_score, transparency_score, economy_policy, land_policy, healthcare_policy, education_policy, safety_policy, energy_policy, is_active, is_national) values

('African National Congress', 'ANC', '#007A4D', 'centre',
'Centre-left. In power since 1994. Dropped below 50% for the first time in 2024. Now governs in a GNU coalition with DA and IFP.',
'Cyril Ramaphosa', 1912, 'https://www.anc1912.org.za', 42, 35, 28,
'State-led growth, BEE transformation, public employment programmes, and social grants as economic cushion.',
'Land reform within constitutional framework. Open to constitutional amendment for expropriation if needed.',
'Universal healthcare via NHI. Plans to integrate private sector funding into a national fund.',
'Free higher education via NSFAS. No-fee schools. NSFAS implementation has been troubled.',
'Increase police numbers, improve SAPS funding. Community policing forums as a supplement.',
'Transitioning Eskom to renewable mix while maintaining coal in medium term.',
true, true),

('Democratic Alliance', 'DA', '#0070C0', 'right',
'Centre-right. Liberal democracy, free markets. Governs Western Cape and City of Cape Town. Part of GNU since 2024.',
'John Steenhuisen', 1959, 'https://www.da.org.za', 68, 62, 70,
'Free market, reduce red tape, attract private investment. Job creation through growth, not grants.',
'Oppose expropriation without compensation. Willing seller/buyer model and title deeds for informal settlers.',
'Fix public hospitals before restructuring system. Oppose NHI as currently designed.',
'Increase school funding, end cadre deployment in education, reform NSFAS completely.',
'More police, better pay for SAPS, stricter enforcement. Expand law enforcement in metros.',
'Open energy market fully to private producers. Unbundle Eskom completely. Fast-track IPPs.',
true, true),

('Economic Freedom Fighters', 'EFF', '#E03A2E', 'far-left',
'Far-left. Land expropriation without compensation. Nationalisation of mines and banks. Known for confrontational parliamentary tactics.',
'Julius Malema', 2013, 'https://www.effonline.org', 30, 22, 20,
'Nationalise mines, banks, and key industries. Radical economic transformation and redistribution.',
'Expropriate all land without compensation. State to become custodian of all land in South Africa.',
'Fully free and nationalised healthcare system. Abolish private healthcare.',
'Free education at all levels, funded by the state. Nationalise all schools and universities.',
'Community policing, demilitarise police. Address socioeconomic roots of crime first.',
'Nationalise all energy production. Rapid transition but state-controlled.',
true, true),

('uMkhonto we Sizwe Party', 'MK', '#7B2D8B', 'populist',
'Zuma-aligned. Debuted with 14.6% in 2024 national election. KwaZulu-Natal stronghold. Has disputed constitutional order.',
'Jacob Zuma', 2023, null, 18, 10, 8,
'Radical economic restructuring. Resource nationalisation. Renegotiate international trade terms.',
'Immediate expropriation without compensation. Suspend current land tenure systems.',
'Free healthcare for all. Review NHI to be more radical in implementation.',
'Free education. Decolonise curriculum completely. Remove colonial influences.',
'Community-based safety. Critique of current SAPS structure and leadership.',
'State control of energy. Review all IPP contracts negotiated under current government.',
true, true),

('Inkatha Freedom Party', 'IFP', '#FF8C00', 'right',
'Centre-right. Zulu cultural heritage. Rural KZN base. Long-standing party with consistent local governance. Part of GNU since 2024.',
'Velenkosini Hlabisa', 1975, 'https://www.ifp.org.za', 50, 52, 48,
'Mixed economy with strong rural development focus. Traditional leadership to play economic role.',
'Land reform with community consent. Traditional authorities central in land allocation.',
'Improve rural healthcare access. Cautious on NHI implementation timeline.',
'Rural school improvement. Mother-tongue education emphasis in early grades.',
'Traditional courts to play supplementary role. Strong anti-crime stance.',
'Loadshedding is unacceptable. Support renewable energy in rural communities.',
true, true),

('ActionSA', 'ActionSA', '#E91E8C', 'right',
'Centre-right. Founded by former Johannesburg mayor Herman Mashaba. Anti-corruption, pro-business, strict on immigration.',
'Herman Mashaba', 2020, 'https://www.actionsa.org.za', 55, 40, 58,
'Pro-business, anti-corruption. Remove barriers to investment. Focus on formal job creation.',
'Property rights are sacrosanct. Oppose expropriation without compensation firmly.',
'Fix public health before NHI. Full accountability for all health officials.',
'Merit-based appointments. Fix school infrastructure. End cadre deployment in education.',
'Strict immigration enforcement. More police. Tougher sentencing for violent crime.',
'Open energy market. Prosecute Eskom officials. Fast-track private energy producers.',
true, true),

('Rise Mzansi', 'Rise', '#00BCD4', 'centre',
'Centre-progressive. New party targeting young urban voters. Led by former journalist Songezo Zibi. Strong on accountability.',
'Songezo Zibi', 2023, 'https://www.risemzansi.org', 52, 30, 65,
'Inclusive growth. Fix infrastructure. Attract ethical investment. Tackle unemployment structurally.',
'Constitutional land reform. Speed up redistribution within the rule of law.',
'Conditional NHI support. Fix public system first. No blank cheques for implementation.',
'Early childhood development as priority. Teacher accountability. Full NSFAS reform.',
'Address root causes. Community-centred policing. Anti-gang strategies in metros.',
'Accelerate private energy, retire coal carefully, protect workers in transition.',
true, true),

('GOOD Party', 'GOOD', '#4CAF50', 'centre',
'Centre-left. Founded by former Cape Town mayor Patricia de Lille. Focus on inclusive growth, social justice, and coalition politics.',
'Patricia de Lille', 2018, 'https://www.goodparty.org.za', 48, 44, 55,
'Mixed economy approach. Strong focus on inclusive growth and closing inequality gaps.',
'Constitutional land reform. Speed but within legal framework and community consultation.',
'Improve NHI implementation. Fix public hospitals. Address health worker shortages.',
'Increase education funding. Address school infrastructure backlogs in townships.',
'Community policing. Address inequality as root cause. Better resourcing of SAPS.',
'Renewable energy transition. Support for green jobs and just transition for coal workers.',
true, true);

-- ================================================
-- SEED DATA — PROMISES
-- ================================================
insert into promises (party_id, promise_text, source, year_made, topic, status, reality_text, evidence_url) values

((select id from parties where abbreviation = 'ANC'),
'We will end load-shedding within 18 months of taking office.',
'2019 ANC Election Manifesto', 2019, 'energy', 'broken',
'Load-shedding reached record Stage 6 in 2023, more than 4 years after the promise. Eskom debt exceeded R400 billion.',
'https://www.eskom.co.za/annualreport'),

((select id from parties where abbreviation = 'ANC'),
'One million new social housing units by 2024.',
'2019 ANC Election Manifesto', 2019, 'housing', 'partial',
'Approximately 220,000 units were delivered by 2024. Budget shortfalls and contractor failures cited.',
'https://www.dhs.gov.za'),

((select id from parties where abbreviation = 'ANC'),
'Fix potholes and water infrastructure in all ANC-run municipalities within 12 months.',
'2021 Local Government Manifesto', 2021, 'other', 'partial',
'67% of municipalities still had water supply issues in 2023. Infrastructure backlogs grew according to COGTA.',
null),

((select id from parties where abbreviation = 'DA'),
'Cape Town will maintain the highest audited financial rating in South Africa.',
'DA Western Cape Governance Commitment', 2009, 'other', 'kept',
'City of Cape Town received unqualified clean audits from the Auditor-General for 15 consecutive years.',
'https://www.agsa.co.za'),

((select id from parties where abbreviation = 'EFF'),
'Free quality education, healthcare, housing and sanitation for all South Africans.',
'EFF 2014 Election Manifesto', 2014, 'education', 'pending',
'EFF has not governed nationally. Promise remains untested. NSFAS improvements they championed have been marred by mismanagement.',
null),

((select id from parties where abbreviation = 'MK'),
'We will suspend the constitution and hold a people''s assembly within 2 years.',
'MK Party 2024 Campaign Statements', 2024, 'other', 'pending',
'MK won 14.6% in 2024 but is in opposition. Constitutional changes require two-thirds majority they do not hold.',
null);

-- ================================================
-- SEED DATA — VOICES
-- ================================================
insert into voices (name, handle, bio, type, platforms, tags, avatar_initials, is_featured) values

('Eusebius McKaiser', '@Eusebius_M',
'Radio host, author, and political analyst. Known for sharp, accessible takes on democracy, race, and civic society in South Africa.',
'analyst', ARRAY['Podcast', 'Twitter', 'Books'], ARRAY['Analysis', 'Democracy', 'Race'], 'EM', true),

('Ralph Mathekga', '@RalphMathekga',
'Political analyst and author of "When Zuma Goes." Regular TV and radio commentator. Balanced and clear on ANC internal dynamics.',
'analyst', ARRAY['TV', 'Twitter', 'Books'], ARRAY['ANC', 'Governance', 'Analysis'], 'RM', true),

('Songezo Zibi', '@SongezoZibi',
'Former journalist, now Rise Mzansi leader. Strong communicator on systemic reform, infrastructure, and what good governance looks like.',
'commentator', ARRAY['Twitter', 'Parliament'], ARRAY['Reform', 'Infrastructure'], 'SZ', false),

('Pieter du Toit', '@PieterduToit',
'News24 associate editor. Long-form political journalism. Excellent on DA internal politics and Western Cape governance.',
'journalist', ARRAY['News24', 'Twitter'], ARRAY['Journalism', 'DA', 'W Cape'], 'PD', false),

('Power Politics Podcast', null,
'Weekly breakdown of SA political news. Accessible and well-researched — good for people who do not follow politics every day.',
'podcast', ARRAY['Spotify', 'Apple Podcasts'], ARRAY['Podcast', 'Weekly', 'Accessible'], 'PP', true),

('Daily Maverick Politics', '@dailymaverick',
'South Africa''s leading independent news outlet. Investigative journalism on corruption, state capture, and public accountability.',
'journalist', ARRAY['Daily Maverick', 'Twitter'], ARRAY['Corruption', 'Investigative', 'News'], 'DM', true);

-- ================================================
-- DONE
-- ================================================
-- Your database is ready. You should see:
-- 8 parties in the parties table
-- 6 promises in the promises table  
-- 6 voices in the voices table
-- All tables secured with Row Level Security
-- ================================================
