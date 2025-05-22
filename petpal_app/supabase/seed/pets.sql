-- Seed data for testing the PetPal app
-- This script adds test pets and related data

-- Insert test users (run this only if you haven't already created test users)
INSERT INTO auth.users (id, email, raw_user_meta_data)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'test@example.com', '{"name":"Test User", "avatar_url": "https://example.com/avatar.jpg"}')
ON CONFLICT DO NOTHING;

INSERT INTO public.users (id, email, display_name, subscription_tier)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'test@example.com', 'Test User', 'premium')
ON CONFLICT (id) DO UPDATE SET
  subscription_tier = 'premium';

-- Insert test household
INSERT INTO households (id, name, owner_id)
VALUES 
  ('10000000-0000-0000-0000-000000000001', 'Test Family', '00000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- Insert test household member
INSERT INTO household_members (household_id, user_id, role)
VALUES 
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'owner')
ON CONFLICT DO NOTHING;

-- Insert test pets
INSERT INTO pets (id, name, type, breed, gender, birthdate, weight, user_id, household_id)
VALUES 
  ('20000000-0000-0000-0000-000000000001', 'Buddy', 'dog', 'Golden Retriever', 'male', '2020-06-15', 28.5, '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002', 'Whiskers', 'cat', 'Siamese', 'female', '2019-03-10', 4.2, '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000003', 'Tweety', 'bird', 'Canary', 'unknown', '2021-01-20', 0.1, '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- Insert test journal entries
INSERT INTO journal_entries (pet_id, timestamp, entry_type, food_data, notes, created_by)
VALUES 
  (
    '20000000-0000-0000-0000-000000000001', 
    NOW() - INTERVAL '1 day', 
    'food', 
    '{"meal_type": "Breakfast", "food_name": "Premium Dog Food", "amount": "1 cup", "finished": true}',
    'Buddy ate with enthusiasm this morning!',
    '00000000-0000-0000-0000-000000000001'
  ),
  (
    '20000000-0000-0000-0000-000000000001', 
    NOW() - INTERVAL '2 day', 
    'activity', 
    '{"activity_type": "Walk", "duration": 30, "intensity": "Medium", "distance": 2.5}',
    'Great walk in the park, Buddy was very active.',
    '00000000-0000-0000-0000-000000000001'
  ),
  (
    '20000000-0000-0000-0000-000000000002', 
    NOW() - INTERVAL '1 day', 
    'mood', 
    '{"mood_name": "Happy", "energy_level": "High"}',
    'Whiskers seems very content today, lots of purring.',
    '00000000-0000-0000-0000-000000000001'
  )
ON CONFLICT DO NOTHING;

-- Insert test reminders
INSERT INTO reminders (pet_id, title, description, reminder_type, start_time, recurrence_rule, created_by)
VALUES 
  (
    '20000000-0000-0000-0000-000000000001',
    'Walk Buddy',
    'Morning walk around the neighborhood',
    'walk',
    NOW() + INTERVAL '1 day' + INTERVAL '8 hours',
    'FREQ=DAILY',
    '00000000-0000-0000-0000-000000000001'
  ),
  (
    '20000000-0000-0000-0000-000000000001',
    'Flea Medication',
    'Monthly flea prevention',
    'medication',
    NOW() + INTERVAL '5 days',
    'FREQ=MONTHLY;BYMONTHDAY=15',
    '00000000-0000-0000-0000-000000000001'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'Whiskers Vet Appointment',
    'Annual checkup',
    'vet',
    NOW() + INTERVAL '14 days' + INTERVAL '10 hours',
    NULL,
    '00000000-0000-0000-0000-000000000001'
  )
ON CONFLICT DO NOTHING;

-- Insert test weight records
INSERT INTO weight_records (pet_id, weight, date, notes, created_by)
VALUES 
  ('20000000-0000-0000-0000-000000000001', 27.5, NOW() - INTERVAL '60 days', 'Initial weight', '00000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000001', 27.8, NOW() - INTERVAL '45 days', NULL, '00000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000001', 28.2, NOW() - INTERVAL '30 days', NULL, '00000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000001', 28.5, NOW() - INTERVAL '15 days', 'Healthy weight gain', '00000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002', 4.0, NOW() - INTERVAL '60 days', 'Initial weight', '00000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002', 4.1, NOW() - INTERVAL '30 days', NULL, '00000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002', 4.2, NOW() - INTERVAL '10 days', NULL, '00000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- Insert test medication
INSERT INTO medications (pet_id, name, dosage, frequency, start_date, end_date, notes, created_by)
VALUES 
  (
    '20000000-0000-0000-0000-000000000001',
    'Frontline Plus',
    '1 pipette',
    'Monthly',
    NOW() - INTERVAL '15 days',
    NULL,
    'Apply between shoulder blades',
    '00000000-0000-0000-0000-000000000001'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'Allergy Medicine',
    '5mg',
    'Daily',
    NOW() - INTERVAL '10 days',
    NOW() + INTERVAL '20 days',
    'Mix with food in the morning',
    '00000000-0000-0000-0000-000000000001'
  )
ON CONFLICT DO NOTHING;

-- Insert test health record
INSERT INTO health_records (pet_id, record_type, date, provider, notes, created_by)
VALUES 
  (
    '20000000-0000-0000-0000-000000000001',
    'vaccination',
    NOW() - INTERVAL '90 days',
    'Healthy Pets Clinic',
    'Rabies and DHPP vaccines, all clear',
    '00000000-0000-0000-0000-000000000001'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'checkup',
    NOW() - INTERVAL '60 days',
    'Healthy Pets Clinic',
    'Annual checkup, all looks good',
    '00000000-0000-0000-0000-000000000001'
  )
ON CONFLICT DO NOTHING;