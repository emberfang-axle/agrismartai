-- AgriSmartAI :: PostgreSQL Schema (Capstone Final)
-- Step 1: createdb agrismartai   (or CREATE DATABASE agrismartai;)
-- Step 2: psql -d agrismartai -f postgresql/schema.sql

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) DEFAULT 'farmer' CHECK (role IN ('farmer', 'admin')),
    barangay VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    image_url TEXT,
    disease_label VARCHAR(100),
    disease_code VARCHAR(50),
    confidence_score DECIMAL(5,2),
    severity VARCHAR(20) CHECK (severity IN ('mild', 'moderate', 'severe')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    reviewer_note TEXT,
    location TEXT,
    barangay VARCHAR(100) DEFAULT 'New Bataan',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS diseases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    scientific_name VARCHAR(150),
    description TEXT,
    fertilizer_tips TEXT[],
    resistant_varieties TEXT[],
    da_referral TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chatbot_qa (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    keywords TEXT[],
    created_at TIMESTAMP DEFAULT NOW()
);

-- Seed diseases
INSERT INTO diseases (name, scientific_name, description, fertilizer_tips, resistant_varieties, da_referral) VALUES
('Bacterial Leaf Blight', 'Xanthomonas oryzae pv. oryzae', 'Bacterial disease causing yellow-white lesions along leaf margins.',
 ARRAY['Reduce nitrogen application', 'Apply potassium and phosphorus', 'Use resistant varieties'],
 ARRAY['NSIC Rc 222', 'NSIC Rc 216', 'NSIC Rc 300'],
 'Consult DA for bactericide recommendations.'),
('Rice Blast', 'Pyricularia oryzae', 'Fungal disease causing gray lesions with brown borders.',
 ARRAY['Apply silicon-based fertilizers', 'Avoid excess nitrogen', 'Monitor fields daily'],
 ARRAY['NSIC Rc 222', 'NSIC Rc 360', 'NSIC Rc 216'],
 'Consult DA for fungicide guidance.'),
('Tungro', 'Rice Tungro Bacilliform Virus (RTBV) + Rice Tungro Spherical Virus (RTSV)', 'Viral disease causing yellow-orange leaves and stunted growth.',
 ARRAY['Control leafhopper vectors', 'Apply balanced fertilizer', 'Use resistant varieties'],
 ARRAY['NSIC Rc 222', 'NSIC Rc 300', 'NSIC Rc 216'],
 'Consult DA IMMEDIATELY for management.'),
('Healthy', 'No disease detected', 'Leaf is healthy with no disease symptoms.',
 ARRAY['Continue regular fertilizer schedule', 'Monitor weekly', 'Maintain good irrigation'],
 ARRAY['All varieties'],
 'Consult DA for soil analysis.')
ON CONFLICT (name) DO NOTHING;

-- Seed chatbot Q&A
INSERT INTO chatbot_qa (question, answer, keywords) VALUES
('What is Bacterial Leaf Blight?', 'Bacterial Leaf Blight (BLB) is caused by Xanthomonas oryzae pv. oryzae. Symptoms include yellow-white lesions along leaf margins. Yield loss: 20-50%.', ARRAY['blb', 'bacterial', 'leaf blight']),
('What is Rice Blast?', 'Rice Blast is caused by Pyricularia oryzae. Symptoms include gray lesions with brown borders. Yield loss: 30-70%.', ARRAY['blast', 'rice blast']),
('What is Tungro?', 'Tungro is a viral disease caused by RTBV and RTSV. Spread by green leafhoppers. Causes yellow-orange leaves and stunting.', ARRAY['tungro', 'virus']),
('What fertilizer for BLB?', 'For Bacterial Leaf Blight: Reduce nitrogen, apply potassium and phosphorus. Recommended NPK: 14-14-14.', ARRAY['blb', 'fertilizer', 'abono']),
('What fertilizer for Blast?', 'For Rice Blast: Apply silicon-based fertilizers. Avoid excess nitrogen. NPK: 14-14-14 with added silicon.', ARRAY['blast', 'fertilizer', 'abono']),
('What fertilizer for Tungro?', 'For Tungro: Control leafhopper vectors first. Apply balanced fertilizer NPK: 14-14-14.', ARRAY['tungro', 'fertilizer', 'abono']),
('Resistant varieties for BLB?', 'Resistant varieties for BLB: NSIC Rc 222, NSIC Rc 216, NSIC Rc 300.', ARRAY['blb', 'variety', 'klase', 'resistant']),
('Resistant varieties for Blast?', 'Resistant varieties for Blast: NSIC Rc 222, NSIC Rc 360, NSIC Rc 216.', ARRAY['blast', 'variety', 'klase', 'resistant']),
('Resistant varieties for Tungro?', 'Resistant varieties for Tungro: NSIC Rc 222, NSIC Rc 300, NSIC Rc 216.', ARRAY['tungro', 'variety', 'klase', 'resistant']),
('Where is DA office?', 'DA Compound, Barangay Bago Oshiro, Davao City. Phone: (082) 123-4567.', ARRAY['da', 'office', 'agriculture', 'department']),
('When to plant rice?', 'Best planting months in New Bataan: May-June and November-December.', ARRAY['plant', 'tanom', 'season']),
('When to harvest?', '110-120 days after planting depending on variety.', ARRAY['harvest', 'ani']),
('How to prevent rice diseases?', 'Use resistant varieties, practice crop rotation, apply balanced fertilizer, monitor fields regularly.', ARRAY['prevent', 'likay', 'sakit']),
('What is the best rice variety?', 'Recommended varieties for New Bataan: NSIC Rc 222, NSIC Rc 216, NSIC Rc 360.', ARRAY['variety', 'klase', 'best']),
('How to contact DA?', 'Call (082) 123-4567 or visit DA Compound, Barangay Bago Oshiro, Davao City.', ARRAY['da', 'contact', 'agriculture'])
ON CONFLICT DO NOTHING;

-- Default admin (password: admin123) — bcrypt hash generated at runtime if missing
-- Run backend seed script: python -m db seed
