-- Revises: V0
-- Creation Date: 2025-04-09 22:03:43.104101Z UTC
-- Reason: Initial setup

CREATE OR REPLACE FUNCTION set_current_timestamp_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.content IS DISTINCT FROM OLD.content THEN
        NEW.updated_at := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TABLE IF NOT EXISTS starboard (
    id BIGINT PRIMARY KEY,
    channel_id BIGINT,
    threshold INTEGER DEFAULT (3) NOT NULL,
    max_age INTERVAL DEFAULT ('7 days'::interval) NOT NULL,
    emojis TEXT DEFAULT ('🌟,⭐,🌠') NOT NULL
);

CREATE TABLE IF NOT EXISTS starboard_entries (
    id SERIAL PRIMARY KEY,
    self_message_id BIGINT,
    message_id BIGINT UNIQUE NOT NULL,
    channel_id BIGINT,
    author_id BIGINT,
    total INTEGER DEFAULT (0) NOT NULL,
    guild_id BIGINT REFERENCES starboard (id) ON DELETE CASCADE ON UPDATE NO ACTION NOT NULL
);


CREATE INDEX IF NOT EXISTS starboard_entries_self_message_id_idx ON starboard_entries (self_message_id);
CREATE INDEX IF NOT EXISTS starboard_entries_message_id_idx ON starboard_entries (message_id);
CREATE INDEX IF NOT EXISTS starboard_entries_guild_id_idx ON starboard_entries (guild_id);


CREATE TABLE IF NOT EXISTS starrers (
    id SERIAL PRIMARY KEY,
    author_id BIGINT NOT NULL,
    entry_id INTEGER REFERENCES starboard_entries (id) ON DELETE CASCADE ON UPDATE NO ACTION NOT NULL
);

CREATE INDEX IF NOT EXISTS starrers_entry_id_idx ON starrers (entry_id);
CREATE UNIQUE INDEX IF NOT EXISTS starrers_uniq_idx ON starrers (author_id, entry_id);

CREATE TABLE IF NOT EXISTS tags (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMP WITH TIME ZONE,
    location_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    owner_id BIGINT NOT NULL,
    times_called INTEGER DEFAULT (0)
);


CREATE INDEX IF NOT EXISTS tags_name_idx ON tags (name);
CREATE INDEX IF NOT EXISTS tags_location_id_idx ON tags (location_id);
CREATE INDEX IF NOT EXISTS tags_name_lower_idx ON tags (LOWER(name));
CREATE UNIQUE INDEX IF NOT EXISTS tags_uniq_idx ON tags (LOWER(name), location_id);

CREATE OR REPLACE TRIGGER set_updated_at BEFORE UPDATE ON tags FOR EACH ROW EXECUTE FUNCTION set_current_timestamp_updated_at();

CREATE TABLE IF NOT EXISTS guild_table (
    id BIGINT PRIMARY KEY,
    locale TEXT DEFAULT ('en-GB') NOT NULL,
    auto_mod_threshold DOUBLE PRECISION DEFAULT (0.8) NOT NULL,
    report_type_tags BIGINT[] DEFAULT ARRAY[]::BIGINT[] NOT NULL,
    report_status_tags BIGINT[] DEFAULT ARRAY[]::BIGINT[] NOT NULL,
    appeal_channel_id BIGINT,
    mod_log_channel_id BIGINT,
    report_channel_id BIGINT,
    log_ignore_channels BIGINT[] DEFAULT ARRAY[]::BIGINT[] NOT NULL,
    guild_log_webhook_id BIGINT,
    enabled_modules TEXT[] DEFAULT ARRAY[]::TEXT[] NOT NULL
);

CREATE TABLE IF NOT EXISTS appeals (
    guild_id BIGINT NOT NULL,
    appeal_id BIGINT NOT NULL,
    status BIGINT DEFAULT 0,
    target_id BIGINT,
    target_tag TEXT,
    mod_id BIGINT,
    mod_tag TEXT,
    reason TEXT,
    ref_id BIGINT,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    log_post_id BIGINT,
    PRIMARY KEY (guild_id, appeal_id)
);

CREATE OR REPLACE TRIGGER set_updated_at BEFORE UPDATE ON appeals FOR EACH ROW EXECUTE FUNCTION set_current_timestamp_updated_at();

CREATE FUNCTION next_appeal(BIGINT) RETURNS INTEGER
		LANGUAGE plpgsql
		stable
		AS $$
		DECLARE next_id INTEGER;
		BEGIN
			SELECT MAX(appeal_id) INTO next_id FROM appeals WHERE guild_id = $1;
			IF next_id IS NULL THEN RETURN 1; END IF;
			RETURN next_id + 1;
		END;
		$$;

CREATE TABLE IF NOT EXISTS cases (
    guild_id BIGINT NOT NULL,
    log_message_id BIGINT,
    case_id BIGINT NOT NULL,
    ref_id BIGINT,
    target_id BIGINT NOT NULL,
    target_tag TEXT NOT NULL,
    mod_id BIGINT,
    mod_tag TEXT,
    action BIGINT NOT NULL,
    reason TEXT,
    action_expiration TIMESTAMP WITH TIME ZONE,
    action_processed BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    context_message_id BIGINT,
    role_id BIGINT,
    multi BOOLEAN DEFAULT false,
    report_ref_id BIGINT,
    appeal_ref_id BIGINT,
    log_dm_message_id BIGINT,
    PRIMARY KEY (guild_id, case_id)
);


CREATE OR REPLACE FUNCTION next_case(BIGINT) RETURNS INTEGER
		LANGUAGE plpgsql
		stable
		AS $$
		DECLARE next_id INTEGER;
		BEGIN
			SELECT MAX(case_id) INTO next_id FROM cases WHERE guild_id = $1;
			IF next_id IS NULL THEN RETURN 1; END IF;
			RETURN next_id + 1;
		END;
		$$;

CREATE TABLE IF NOT EXISTS reports (
    guild_id BIGINT NOT NULL,
    report_id BIGINT NOT NULL,
    type BIGINT,
    status BIGINT,
    message_id BIGINT,
    channel_id BIGINT,
    target_id BIGINT,
    target_tag TEXT,
    author_id BIGINT,
    author_tag TEXT,
    mod_id BIGINT,
    mod_tag TEXT,
    reason TEXT,
    attachment_url TEXT,
    log_post_id BIGINT,
    ref_id BIGINT,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    context_messages_ids BIGINT[]
);

CREATE OR REPLACE TRIGGER set_updated_at BEFORE UPDATE ON reports FOR EACH ROW EXECUTE FUNCTION set_current_timestamp_updated_at();


CREATE OR REPLACE FUNCTION next_report(BIGINT) RETURNS INTEGER
		LANGUAGE plpgsql
		stable
		AS $$
		DECLARE next_id INTEGER;
		BEGIN
			SELECT MAX(report_id) INTO next_id FROM reports WHERE guild_id = $1;
			IF next_id IS NULL THEN RETURN 1; END IF;
			RETURN next_id + 1;
		END;
		$$;

