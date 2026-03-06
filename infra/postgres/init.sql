-- SentinelForge Database Initialization
-- This script creates the initial schema for Phase 1

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- USERS & AUTHENTICATION
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    is_superuser BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- ============================================================================
-- AGENTS & CONFIGURATIONS
-- ============================================================================

CREATE TYPE agent_framework AS ENUM ('crewai', 'langgraph', 'openclaw', 'custom');
CREATE TYPE agent_trust_level AS ENUM ('sandbox', 'restricted', 'standard', 'privileged');

CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    framework agent_framework NOT NULL,
    trust_level agent_trust_level DEFAULT 'sandbox',
    config JSONB NOT NULL DEFAULT '{}',
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_agents_framework ON agents(framework);
CREATE INDEX idx_agents_trust_level ON agents(trust_level);
CREATE INDEX idx_agents_created_by ON agents(created_by);

-- ============================================================================
-- TOOLS & PERMISSIONS
-- ============================================================================

CREATE TYPE tool_permission AS ENUM ('read', 'write', 'admin');

CREATE TABLE tools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(100),
    permission tool_permission DEFAULT 'read',
    schema JSONB NOT NULL DEFAULT '{}',
    config JSONB DEFAULT '{}',
    rate_limit_per_minute INTEGER DEFAULT 60,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_tools_permission ON tools(permission);
CREATE INDEX idx_tools_category ON tools(category);

-- Agent-Tool associations
CREATE TABLE agent_tools (
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    tool_id UUID REFERENCES tools(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (agent_id, tool_id)
);

-- ============================================================================
-- RUNS & EXECUTIONS
-- ============================================================================

CREATE TYPE run_status AS ENUM (
    'pending',
    'running',
    'completed',
    'failed',
    'blocked',
    'needs_human'
);

CREATE TABLE runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status run_status DEFAULT 'pending',
    input_data JSONB NOT NULL,
    output_data JSONB,
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_runs_status ON runs(status);
CREATE INDEX idx_runs_agent_id ON runs(agent_id);
CREATE INDEX idx_runs_user_id ON runs(user_id);
CREATE INDEX idx_runs_created_at ON runs(created_at DESC);

-- ============================================================================
-- AUDIT LOG (Immutable, append-only)
-- ============================================================================

CREATE TYPE audit_event_type AS ENUM (
    'run_created',
    'run_started',
    'run_completed',
    'tool_call',
    'policy_decision',
    'auditor_verdict',
    'human_approval',
    'config_changed',
    'user_action'
);

CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type audit_event_type NOT NULL,
    run_id UUID REFERENCES runs(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    agent_id UUID REFERENCES agents(id) ON DELETE SET NULL,
    tool_id UUID REFERENCES tools(id) ON DELETE SET NULL,
    event_data JSONB NOT NULL DEFAULT '{}',
    event_hash VARCHAR(64) NOT NULL,  -- SHA256 of event_data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_audit_log_event_type ON audit_log(event_type);
CREATE INDEX idx_audit_log_run_id ON audit_log(run_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at DESC);

-- Prevent updates and deletes on audit_log
CREATE OR REPLACE FUNCTION prevent_audit_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit log is immutable. Operation % not allowed.', TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_log_immutable
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION prevent_audit_modification();

-- ============================================================================
-- POLICY DECISIONS (Phase 3+)
-- ============================================================================

CREATE TYPE policy_decision AS ENUM ('allow', 'deny');

CREATE TABLE policy_decisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID REFERENCES runs(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES agents(id) ON DELETE SET NULL,
    tool_id UUID REFERENCES tools(id) ON DELETE SET NULL,
    decision policy_decision NOT NULL,
    rule_matched VARCHAR(255),
    reason TEXT,
    policy_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_policy_decisions_run_id ON policy_decisions(run_id);
CREATE INDEX idx_policy_decisions_decision ON policy_decisions(decision);

-- ============================================================================
-- AUDITOR VERDICTS (Phase 3+)
-- ============================================================================

CREATE TYPE auditor_verdict AS ENUM ('approve', 'block', 'needs_human');

CREATE TABLE auditor_verdicts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID REFERENCES runs(id) ON DELETE CASCADE,
    verdict auditor_verdict NOT NULL,
    rationale TEXT,
    model_used VARCHAR(100),
    confidence_score DECIMAL(3, 2),  -- 0.00 to 1.00
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auditor_verdicts_run_id ON auditor_verdicts(run_id);
CREATE INDEX idx_auditor_verdicts_verdict ON auditor_verdicts(verdict);

-- ============================================================================
-- HUMAN APPROVALS (Phase 4+)
-- ============================================================================

CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TABLE approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID REFERENCES runs(id) ON DELETE CASCADE,
    requested_action TEXT NOT NULL,
    status approval_status DEFAULT 'pending',
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approvals_status ON approvals(status);
CREATE INDEX idx_approvals_run_id ON approvals(run_id);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tools_updated_at BEFORE UPDATE ON tools
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Generate event hash for audit log
CREATE OR REPLACE FUNCTION generate_audit_hash()
RETURNS TRIGGER AS $$
BEGIN
    NEW.event_hash := encode(
        digest(
            NEW.id::text || 
            NEW.event_type::text || 
            NEW.event_data::text || 
            NEW.created_at::text,
            'sha256'
        ),
        'hex'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_log_generate_hash BEFORE INSERT ON audit_log
    FOR EACH ROW EXECUTE FUNCTION generate_audit_hash();

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Create default admin user (to be linked with Authentik)
INSERT INTO users (username, email, full_name, is_superuser)
VALUES (
    'admin',
    'admin@sentinelforge.local',
    'SentinelForge Administrator',
    true
) ON CONFLICT (username) DO NOTHING;

-- Create example read-only tools
INSERT INTO tools (name, description, category, permission, schema) VALUES
(
    'http_get',
    'Make HTTP GET requests to allowlisted domains',
    'network',
    'read',
    '{"type": "object", "properties": {"url": {"type": "string"}, "headers": {"type": "object"}}}'
),
(
    'github_read',
    'Read GitHub repository contents and metadata',
    'git',
    'read',
    '{"type": "object", "properties": {"repo": {"type": "string"}, "path": {"type": "string"}}}'
),
(
    'file_read',
    'Read files from readonly mounted volumes',
    'filesystem',
    'read',
    '{"type": "object", "properties": {"path": {"type": "string"}}}'
)
ON CONFLICT (name) DO NOTHING;

-- Grant permissions to sentinelforge user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sentinelforge;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sentinelforge;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO sentinelforge;
