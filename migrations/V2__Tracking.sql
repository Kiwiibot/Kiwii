-- Revises: V1
-- Creation Date: 2025-04-23 19:53:04.877811Z UTC
-- Reason: Tracking

CREATE TABLE IF NOT EXISTS last_seen (
    id BIGINT PRIMARY KEY,
    date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL
);

CREATE TABLE IF NOT EXISTS last_spoke (
    id BIGINT NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL,
    guild_id BIGINT,
    PRIMARY KEY (id, guild_id)
);

CREATE TABLE IF NOT EXISTS username_changes (
    id BIGINT NOT NULL,
    name TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL,
    idx INTEGER NOT NULL,
    PRIMARY KEY (id, idx)
);

CREATE TABLE IF NOT EXISTS global_name_changes (
    id BIGINT NOT NULL,
    name TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL,
    idx INTEGER DEFAULT 0 NOT NULL,
    PRIMARY KEY (id, idx)
);

CREATE TABLE IF NOT EXISTS nickname_changes (
    id BIGINT NOT NULL,
    guild_id BIGINT NOT NULL,
    name TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL,
    idx INTEGER DEFAULT 0 NOT NULL,
    PRIMARY KEY (id, guild_id, idx)
);

CREATE TABLE IF NOT EXISTS avatar_changes (
    id BIGINT NOT NULL,
    hash TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL,
    avatar BYTEA,
    idx INTEGER DEFAULT 0 NOT NULL,
    PRIMARY KEY (id, idx)
);

CREATE TABLE IF NOT EXISTS banner_changes (
    id BIGINT NOT NULL,
    hash TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL,
    banner BYTEA,
    idx INTEGER DEFAULT 0,
    PRIMARY KEY (id, idx)
);

CREATE TABLE IF NOT EXISTS guild_avatar_changes (
    id BIGINT NOT NULL,
    guild_id BIGINT NOT NULL,
    hash TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL,
    avatar BYTEA,
    idx INTEGER DEFAULT 0,
    PRIMARY KEY (id, guild_id, idx)
);

CREATE TABLE IF NOT EXISTS guild_banner_changes (
    id BIGINT NOT NULL,
    guild_id BIGINT NOT NULL,
    hash TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL,
    banner BYTEA,
    idx INTEGER DEFAULT 0,
    PRIMARY KEY (id, guild_id, idx)
);

CREATE TABLE IF NOT EXISTS user_settings (
    id BIGINT PRIMARY KEY NOT NULL,
    timezone TEXT,
    flags INTEGER
);

-- Function for cleaning up global tables (avatar_changes, banner_changes, username_changes, global_name_changes)
-- These tables only have 'id' to identify the user.
CREATE OR REPLACE FUNCTION cleanup_global_changes()
RETURNS TRIGGER AS $$
DECLARE
    sql TEXT;
BEGIN
    -- Construct the SQL statement using TG_TABLE_NAME
    sql := 'DELETE FROM ONLY ' || quote_ident(TG_TABLE_NAME) || ' 
            WHERE id = $1
            AND idx NOT IN (
                SELECT idx
                FROM ONLY ' || quote_ident(TG_TABLE_NAME) || '
                WHERE id = $1
                ORDER BY idx DESC
                LIMIT 5
            )';

    -- Execute the constructed SQL statement
    EXECUTE sql USING NEW.id;

    RETURN NEW; -- Return the new row for AFTER INSERT triggers
END;
$$ LANGUAGE plpgsql;

-- Function for cleaning up guild-specific tables (nickname_changes, guild_avatar_changes, guild_banner_changes)
-- These tables have 'id' (user_id) and 'guild_id' to identify the context.
CREATE OR REPLACE FUNCTION cleanup_guild_changes()
RETURNS TRIGGER AS $$
DECLARE
    sql TEXT;
BEGIN
    -- Construct the SQL statement using TG_TABLE_NAME
    sql := 'DELETE FROM ONLY ' || quote_ident(TG_TABLE_NAME) || ' 
            WHERE id = $1
            AND guild_id = $2
            AND idx NOT IN (
                SELECT idx
                FROM ONLY ' || quote_ident(TG_TABLE_NAME) || '
                WHERE id = $1 AND guild_id = $2
                ORDER BY idx DESC
                LIMIT 5
            )';

    -- Execute the constructed SQL statement
    EXECUTE sql USING NEW.id, NEW.guild_id;

    RETURN NEW; -- Return the new row for AFTER INSERT triggers
END;
$$ LANGUAGE plpgsql;


-- Triggers for tables that need cleanup based on 'id' and 'idx' (global)
CREATE OR REPLACE TRIGGER cleanup_username_trigger AFTER INSERT ON username_changes FOR EACH ROW EXECUTE FUNCTION cleanup_global_changes();
CREATE OR REPLACE TRIGGER cleanup_global_name_trigger AFTER INSERT ON global_name_changes FOR EACH ROW EXECUTE FUNCTION cleanup_global_changes();
CREATE OR REPLACE TRIGGER cleanup_avatar_trigger AFTER INSERT ON avatar_changes FOR EACH ROW EXECUTE FUNCTION cleanup_global_changes();
CREATE OR REPLACE TRIGGER cleanup_banner_trigger AFTER INSERT ON banner_changes FOR EACH ROW EXECUTE FUNCTION cleanup_global_changes();

-- Triggers for tables that need cleanup based on 'id', 'guild_id', and 'idx' (guild-specific)
CREATE OR REPLACE TRIGGER cleanup_nickname_trigger AFTER INSERT ON nickname_changes FOR EACH ROW EXECUTE FUNCTION cleanup_guild_changes();
CREATE OR REPLACE TRIGGER cleanup_guild_avatar_trigger AFTER INSERT ON guild_avatar_changes FOR EACH ROW EXECUTE FUNCTION cleanup_guild_changes();
CREATE OR REPLACE TRIGGER cleanup_guild_banner_trigger AFTER INSERT ON guild_banner_changes FOR EACH ROW EXECUTE FUNCTION cleanup_guild_changes();
