-- Seed Initial Data for Michigan Lotto Pool
-- Version 1.0
-- Run this after creating the schema

-- Insert default admin user (Change password in production!)
INSERT INTO users (email, password_hash, full_name, role, kyc_status, email_verified, is_active)
VALUES (
    'admin@milottopool.com',
    '$2a$10$YourHashedPasswordHere', -- CHANGE THIS!
    'System Administrator',
    'admin',
    'approved',
    true,
    true
) ON CONFLICT (email) DO NOTHING;

-- Insert demo pool for testing
INSERT INTO pools (name, description, creator_id, max_members, entry_fee, region, status)
SELECT 
    'Detroit Metro Pool',
    'The largest and most active lottery pool for Detroit metro area residents',
    id,
    5000,
    5.00,
    'Detroit Metro',
    'active'
FROM users WHERE email = 'admin@milottopool.com'
ON CONFLICT DO NOTHING;

-- Generate all 10,000 four-digit combinations for the demo pool
DO $$
DECLARE
    pool_uuid UUID;
    i INTEGER;
BEGIN
    SELECT id INTO pool_uuid FROM pools WHERE name = 'Detroit Metro Pool' LIMIT 1;
    
    IF pool_uuid IS NOT NULL THEN
        FOR i IN 0..9999 LOOP
            INSERT INTO lottery_combinations (pool_id, combination)
            VALUES (pool_uuid, LPAD(i::TEXT, 4, '0'))
            ON CONFLICT (pool_id, combination) DO NOTHING;
        END LOOP;
    END IF;
END $$;

-- Insert sample compliance report
INSERT INTO compliance_reports (report_type, report_date, data, status)
VALUES (
    'monthly_audit',
    CURRENT_DATE,
    '{"kyc_compliance": 100, "tax_compliance": 100, "data_protection": 100}',
    'completed'
);
