const { Pool } = require('pg');
const Redis = require('redis');
require('dotenv').config();

// PostgreSQL Configuration
const pool = new Pool({
  connectionString: process.env.DB_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

// Redis Configuration
const redisClient = Redis.createClient({
  url: process.env.REDIS_URL,
});

redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err);
});

redisClient.on('connect', () => {
  console.log('Connected to Redis');
});

// Initialize Redis connection
const connectRedis = async () => {
  try {
    await redisClient.connect();
  } catch (error) {
    console.error('Redis connection error:', error);
  }
};

// Database initialization
const initializeDatabase = async () => {
  try {
    // Test PostgreSQL connection
    const client = await pool.connect();
    console.log('Connected to PostgreSQL');
    client.release();
    
    // Connect to Redis
    await connectRedis();
    
    // Create tables
    await createTables();
  } catch (error) {
    console.error('Database initialization error:', error);
  }
};

// Create database tables
const createTables = async () => {
  const createUsersTable = `
    CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      email VARCHAR(255) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      full_name VARCHAR(255) NOT NULL,
      phone_number VARCHAR(20),
      date_of_birth DATE,
      emergency_medical_info TEXT,
      profile_picture_url VARCHAR(500),
      is_active BOOLEAN DEFAULT true,
      email_verified BOOLEAN DEFAULT false,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `;

  const createEmergencyContactsTable = `
    CREATE TABLE IF NOT EXISTS emergency_contacts (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name VARCHAR(255) NOT NULL,
      phone_number VARCHAR(20) NOT NULL,
      email VARCHAR(255),
      relationship VARCHAR(50) NOT NULL,
      is_active BOOLEAN DEFAULT true,
      priority_order INTEGER DEFAULT 1,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `;

  const createEmergencyAlertsTable = `
    CREATE TABLE IF NOT EXISTS emergency_alerts (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      alert_type VARCHAR(50) NOT NULL,
      message TEXT,
      latitude DECIMAL(10, 8),
      longitude DECIMAL(11, 8),
      address TEXT,
      location_accuracy DECIMAL(10, 2),
      status VARCHAR(20) DEFAULT 'pending',
      contacts_notified JSONB,
      police_contacted BOOLEAN DEFAULT false,
      acknowledged_at TIMESTAMP WITH TIME ZONE,
      resolved_at TIMESTAMP WITH TIME ZONE,
      metadata JSONB,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `;

  const createUserSettingsTable = `
    CREATE TABLE IF NOT EXISTS user_settings (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      enable_location_sharing BOOLEAN DEFAULT true,
      auto_contact_police BOOLEAN DEFAULT false,
      enable_vibration BOOLEAN DEFAULT true,
      enable_sound_alerts BOOLEAN DEFAULT true,
      enable_push_notifications BOOLEAN DEFAULT true,
      alert_delay_seconds INTEGER DEFAULT 10,
      share_location_with_contacts BOOLEAN DEFAULT true,
      enable_quick_dial BOOLEAN DEFAULT true,
      require_pin_on_startup BOOLEAN DEFAULT false,
      enable_biometric_auth BOOLEAN DEFAULT false,
      enable_stealth_mode BOOLEAN DEFAULT false,
      auto_lock_minutes INTEGER DEFAULT 5,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `;

  const createAuditLogsTable = `
    CREATE TABLE IF NOT EXISTS audit_logs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID REFERENCES users(id) ON DELETE SET NULL,
      action VARCHAR(100) NOT NULL,
      resource_type VARCHAR(50) NOT NULL,
      resource_id UUID,
      old_values JSONB,
      new_values JSONB,
      ip_address INET,
      user_agent TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `;

  const createIndexes = `
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON emergency_contacts(user_id);
    CREATE INDEX IF NOT EXISTS idx_emergency_alerts_user_id ON emergency_alerts(user_id);
    CREATE INDEX IF NOT EXISTS idx_emergency_alerts_status ON emergency_alerts(status);
    CREATE INDEX IF NOT EXISTS idx_emergency_alerts_created_at ON emergency_alerts(created_at);
    CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);
    CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
    CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
  `;

  try {
    await pool.query(createUsersTable);
    await pool.query(createEmergencyContactsTable);
    await pool.query(createEmergencyAlertsTable);
    await pool.query(createUserSettingsTable);
    await pool.query(createAuditLogsTable);
    await pool.query(createIndexes);
    
    console.log('Database tables created successfully');
  } catch (error) {
    console.error('Error creating tables:', error);
  }
};

module.exports = {
  pool,
  redisClient,
  initializeDatabase,
};