-- Revises: V2
-- Creation Date: 2025-06-22 00:23:13.486622Z UTC
-- Reason: notifications

CREATE TABLE IF NOT EXISTS notification_channels (
    id BIGSERIAL PRIMARY KEY,
    guild_id BIGINT NOT NULL REFERENCES guild_table(id) ON DELETE CASCADE,
    service_type INTEGER NOT NULL,
    channel_id BIGINT NOT NULL,
    webhook_url TEXT,
    enabled BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT unique_guild_service_channel UNIQUE (guild_id, service_type, channel_id)
);

CREATE TABLE IF NOT EXISTS service_subscriptions (
    id BIGSERIAL PRIMARY KEY,
    notification_channel_id BIGINT NOT NULL REFERENCES notification_channels(id) ON DELETE CASCADE,
    service_id TEXT NOT NULL,
    last_checked TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    latest_item_id TEXT,
    enabled BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT unique_subscription_per_channel UNIQUE (notification_channel_id, service_id)
);

CREATE TABLE IF NOT EXISTS notification_logs (
    id BIGSERIAL PRIMARY KEY,
    subscription_id BIGINT NOT NULL REFERENCES service_subscriptions(id) ON DELETE CASCADE,
    notified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    item_id TEXT NOT NULL,
    notification_message TEXT NOT NULL,
    status TEXT NOT NULL,
    error_message TEXT
);

CREATE TABLE IF NOT EXISTS notification_templates (
    id BIGSERIAL,
    guild_id BIGINT NOT NULL REFERENCES guild_table(id) ON DELETE CASCADE,
    service_type INTEGER NOT NULL,
    template_content TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE NOT NULL,
    service_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS unique_guild_service_default_template_idx ON notification_templates (guild_id, service_type) WHERE is_default = TRUE;

CREATE INDEX IF NOT EXISTS idx_notification_templates_guild_service ON notification_templates (guild_id, service_type);
