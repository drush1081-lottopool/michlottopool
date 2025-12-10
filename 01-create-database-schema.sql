-- Michigan Lotto Pool Database Schema
-- Version 1.0 - Initial Setup
-- Run this first to create all tables

-- Users table with KYC and role management
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    phone VARCHAR(20),
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('member', 'helper', 'moderator', 'admin')),
    
    -- KYC/Identity Verification
    kyc_status VARCHAR(20) DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'in_review', 'approved', 'rejected')),
    kyc_submitted_at TIMESTAMP,
    kyc_reviewed_at TIMESTAMP,
    kyc_reviewed_by UUID REFERENCES users(id),
    
    -- Personal Information
    date_of_birth DATE,
    ssn_last_4 VARCHAR(4),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(2) DEFAULT 'MI',
    zip_code VARCHAR(10),
    
    -- Verification Documents
    id_document_url TEXT,
    id_document_type VARCHAR(50),
    proof_of_residency_url TEXT,
    selfie_url TEXT,
    
    -- Social Media
    facebook_url TEXT,
    twitter_url TEXT,
    instagram_url TEXT,
    linkedin_url TEXT,
    youtube_url TEXT,
    
    -- Crypto Settings
    bitcoin_wallet_address VARCHAR(100),
    auto_convert_to_btc BOOLEAN DEFAULT false,
    btc_conversion_threshold DECIMAL(10, 2) DEFAULT 100.00,
    
    -- Preferences
    email_verified BOOLEAN DEFAULT false,
    email_verification_token VARCHAR(255),
    daily_email_enabled BOOLEAN DEFAULT true,
    email_time VARCHAR(5) DEFAULT '08:00',
    
    -- Account Status
    is_active BOOLEAN DEFAULT true,
    is_banned BOOLEAN DEFAULT false,
    ban_reason TEXT,
    last_login TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pools table
CREATE TABLE IF NOT EXISTS pools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    creator_id UUID REFERENCES users(id) ON DELETE SET NULL,
    max_members INTEGER DEFAULT 5000,
    current_members INTEGER DEFAULT 0,
    entry_fee DECIMAL(10, 2) DEFAULT 5.00,
    min_investment DECIMAL(10, 2) DEFAULT 5.00,
    max_investment DECIMAL(10, 2) DEFAULT 1000.00,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'full', 'closed', 'archived')),
    region VARCHAR(100),
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pool Members
CREATE TABLE IF NOT EXISTS pool_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    investment_amount DECIMAL(10, 2) DEFAULT 5.00,
    share_percentage DECIMAL(5, 2),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    UNIQUE(pool_id, user_id)
);

-- Lottery Combinations (all 10,000 four-digit combinations)
CREATE TABLE IF NOT EXISTS lottery_combinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
    combination VARCHAR(4) NOT NULL,
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    assigned_at TIMESTAMP,
    is_winner BOOLEAN DEFAULT false,
    winning_date DATE,
    winning_amount DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(pool_id, combination)
);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    pool_id UUID REFERENCES pools(id) ON DELETE SET NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_type VARCHAR(50) CHECK (payment_type IN ('entry_fee', 'investment', 'payout', 'refund')),
    payment_method VARCHAR(50) CHECK (payment_method IN ('credit_card', 'debit_card', 'bank_transfer', 'bitcoin')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    stripe_payment_id VARCHAR(255),
    bitcoin_transaction_id VARCHAR(255),
    btc_amount DECIMAL(18, 8),
    btc_conversion_rate DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Voting Sessions
CREATE TABLE IF NOT EXISTS voting_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    voting_type VARCHAR(50) CHECK (voting_type IN ('distribution', 'rule_change', 'general')),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
    total_votes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Voting Options
CREATE TABLE IF NOT EXISTS voting_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voting_session_id UUID REFERENCES voting_sessions(id) ON DELETE CASCADE,
    option_text VARCHAR(255) NOT NULL,
    description TEXT,
    vote_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Votes
CREATE TABLE IF NOT EXISTS user_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voting_session_id UUID REFERENCES voting_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    option_id UUID REFERENCES voting_options(id) ON DELETE CASCADE,
    voted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(voting_session_id, user_id)
);

-- Comments
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
    voting_session_id UUID REFERENCES voting_sessions(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    deleted_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Comment Likes
CREATE TABLE IF NOT EXISTS comment_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(comment_id, user_id)
);

-- Tax Documents (1099-MISC)
CREATE TABLE IF NOT EXISTS tax_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tax_year INTEGER NOT NULL,
    form_type VARCHAR(20) DEFAULT '1099-MISC',
    total_winnings DECIMAL(10, 2) NOT NULL,
    document_url TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'generated', 'sent', 'filed')),
    generated_at TIMESTAMP,
    sent_at TIMESTAMP,
    filed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    severity VARCHAR(20) DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Compliance Reports
CREATE TABLE IF NOT EXISTS compliance_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type VARCHAR(50) NOT NULL,
    report_date DATE NOT NULL,
    data JSONB,
    generated_by UUID REFERENCES users(id),
    file_url TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_kyc_status ON users(kyc_status);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_pool_members_user ON pool_members(user_id);
CREATE INDEX idx_pool_members_pool ON pool_members(pool_id);
CREATE INDEX idx_lottery_combinations_pool ON lottery_combinations(pool_id);
CREATE INDEX idx_lottery_combinations_assigned ON lottery_combinations(assigned_to);
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_comments_pool ON comments(pool_id);
CREATE INDEX idx_comments_voting ON comments(voting_session_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pools_updated_at BEFORE UPDATE ON pools
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
