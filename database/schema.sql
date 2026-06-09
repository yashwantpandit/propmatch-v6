-- ============================================================
-- PROPMATCH v6 FULL DATABASE SCHEMA
-- ============================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- USERS
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT    NOT NULL,
  email         TEXT    NOT NULL UNIQUE,
  password_hash TEXT    NOT NULL,
  role          TEXT    NOT NULL CHECK(role IN ('admin','team_lead','advisor')),
  team_lead_id  INTEGER REFERENCES users(id),
  phone         TEXT,
  is_active     INTEGER DEFAULT 1,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- PROJECTS
CREATE TABLE IF NOT EXISTS projects (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  project_name        TEXT    NOT NULL,
  builder_name        TEXT,
  city                TEXT    DEFAULT 'Bangalore',
  location_area       TEXT,
  project_status      TEXT,
  possession_timeline TEXT,
  configurations      TEXT,
  price_min           REAL,
  price_max           REAL,
  floor_options       TEXT,
  vastu_facing        TEXT,
  amenities           TEXT,
  highlights          TEXT,
  map_link            TEXT,
  brochure_link       TEXT,
  rera_number         TEXT,
  use_type            TEXT    DEFAULT 'both',
  is_deleted          INTEGER DEFAULT 0,
  created_by          INTEGER REFERENCES users(id),
  created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(project_name, builder_name, location_area, city)
);

-- UNITS
CREATE TABLE IF NOT EXISTS units (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id    INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  config        TEXT,
  area_sqft     REAL,
  price         REAL,
  floor_range   TEXT,
  facing        TEXT,
  availability  TEXT    DEFAULT 'available',
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- LEADS
CREATE TABLE IF NOT EXISTS leads (
  id                   INTEGER PRIMARY KEY AUTOINCREMENT,
  client_name          TEXT    NOT NULL,
  client_phone         TEXT,
  client_email         TEXT,
  configuration        TEXT,
  preferred_location   TEXT,
  floor_preference     TEXT,
  vastu_preference     TEXT,
  possession_timeline  TEXT,
  budget_max           REAL,
  use_type             TEXT,
  additional_notes     TEXT,
  stage                TEXT    DEFAULT 'new'
                         CHECK(stage IN ('new','contacted','site_visit','negotiation','booked','lost','on_hold')),
  priority             TEXT    DEFAULT 'medium'
                         CHECK(priority IN ('low','medium','high')),
  next_followup        DATETIME,
  source               TEXT,
  advisor_id           INTEGER REFERENCES users(id),
  team_lead_id         INTEGER REFERENCES users(id),
  is_deleted           INTEGER DEFAULT 0,
  created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at           DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- LEAD STAGE HISTORY (Kanban)
CREATE TABLE IF NOT EXISTS lead_stage_history (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id     INTEGER NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  from_stage  TEXT,
  to_stage    TEXT    NOT NULL,
  changed_by  INTEGER REFERENCES users(id),
  note        TEXT,
  changed_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- LEAD NOTES
CREATE TABLE IF NOT EXISTS lead_notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id    INTEGER NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  user_id    INTEGER REFERENCES users(id),
  note       TEXT    NOT NULL,
  note_type  TEXT    DEFAULT 'general'
               CHECK(note_type IN ('call','meeting','whatsapp','email','general')),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- FOLLOW-UP REMINDERS
CREATE TABLE IF NOT EXISTS follow_up_reminders (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id       INTEGER NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  user_id       INTEGER REFERENCES users(id),
  remind_at     DATETIME NOT NULL,
  title         TEXT     NOT NULL,
  description   TEXT,
  status        TEXT     DEFAULT 'pending'
                  CHECK(status IN ('pending','done','snoozed','cancelled')),
  reminder_type TEXT    DEFAULT 'call'
                  CHECK(reminder_type IN ('call','site_visit','follow_up','meeting','document')),
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- RECOMMENDATIONS
CREATE TABLE IF NOT EXISTS recommendations (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id      INTEGER NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  project_id   INTEGER NOT NULL REFERENCES projects(id),
  match_score  REAL,
  match_reasons TEXT,
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- WHATSAPP TEMPLATES
CREATE TABLE IF NOT EXISTS whatsapp_templates (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  stage       TEXT NOT NULL,
  title       TEXT NOT NULL,
  message     TEXT NOT NULL,
  is_active   INTEGER DEFAULT 1,
  created_by  INTEGER REFERENCES users(id),
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- WHATSAPP LOGS
CREATE TABLE IF NOT EXISTS whatsapp_logs (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id     INTEGER REFERENCES leads(id),
  user_id     INTEGER REFERENCES users(id),
  phone       TEXT,
  message     TEXT,
  template_id INTEGER REFERENCES whatsapp_templates(id),
  sent_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- IMPORTS
CREATE TABLE IF NOT EXISTS imports (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  filename       TEXT,
  uploaded_by    INTEGER REFERENCES users(id),
  total_rows     INTEGER DEFAULT 0,
  inserted_rows  INTEGER DEFAULT 0,
  updated_rows   INTEGER DEFAULT 0,
  error_rows     INTEGER DEFAULT 0,
  status         TEXT DEFAULT 'pending',
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- IMPORT ERRORS
CREATE TABLE IF NOT EXISTS import_errors (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  import_id  INTEGER REFERENCES imports(id),
  row_number INTEGER,
  raw_data   TEXT,
  error_msg  TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- LEAD ATTACHMENTS
CREATE TABLE IF NOT EXISTS lead_attachments (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id       INTEGER NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  filename      TEXT    NOT NULL,
  original_name TEXT    NOT NULL,
  file_type     TEXT    DEFAULT 'general'
                  CHECK(file_type IN ('brochure','booking_form','payment_plan','id_proof','general')),
  uploaded_by   INTEGER REFERENCES users(id),
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- CLIENT PROPOSALS
CREATE TABLE IF NOT EXISTS proposals (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id      INTEGER NOT NULL REFERENCES leads(id),
  advisor_id   INTEGER REFERENCES users(id),
  title        TEXT    NOT NULL,
  intro_text   TEXT,
  project_ids  TEXT,
  status       TEXT    DEFAULT 'draft'
                 CHECK(status IN ('draft','sent','accepted','rejected')),
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- AUDIT TRAIL
CREATE TABLE IF NOT EXISTS audit_logs (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id     INTEGER REFERENCES users(id),
  user_name   TEXT,
  user_role   TEXT,
  action      TEXT    NOT NULL,
  entity      TEXT    NOT NULL,
  entity_id   INTEGER,
  old_value   TEXT,
  new_value   TEXT,
  ip_address  TEXT,
  user_agent  TEXT,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_leads_stage      ON leads(stage);
CREATE INDEX IF NOT EXISTS idx_leads_advisor    ON leads(advisor_id);
CREATE INDEX IF NOT EXISTS idx_leads_priority   ON leads(priority);
CREATE INDEX IF NOT EXISTS idx_reminders_date   ON follow_up_reminders(remind_at);
CREATE INDEX IF NOT EXISTS idx_reminders_user   ON follow_up_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity     ON audit_logs(entity, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_user       ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_created    ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_projects_loc     ON projects(location_area);
CREATE INDEX IF NOT EXISTS idx_stage_history    ON lead_stage_history(lead_id);
