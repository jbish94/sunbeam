-- Location: supabase/migrations/20241030194743_sunbeam_location_weather.sql
-- Schema Analysis: No existing schema detected - creating fresh sunbeam backend
-- Integration Type: Complete backend setup for location tracking and weather data collection
-- Dependencies: None (fresh start)

-- 1. Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create custom enum types
CREATE TYPE public.user_role AS ENUM ('admin', 'user');
CREATE TYPE public.session_status AS ENUM ('active', 'completed', 'paused', 'cancelled');
CREATE TYPE public.notification_type AS ENUM ('weather_alert', 'uv_warning', 'session_reminder', 'goal_achievement', 'system');

-- 3. Core tables

-- User profiles table - intermediary between auth.users and public schema
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'user'::public.user_role,
    skin_type INTEGER DEFAULT 2, -- 1-6 Fitzpatrick scale
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Location data table for tracking user locations
CREATE TABLE public.user_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    altitude DOUBLE PRECISION,
    accuracy DOUBLE PRECISION,
    address TEXT,
    city TEXT,
    country TEXT,
    timezone TEXT,
    is_current BOOLEAN DEFAULT true,
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Weather data table for storing real-time weather information
CREATE TABLE public.weather_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id UUID REFERENCES public.user_locations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    temperature DOUBLE PRECISION NOT NULL,
    feels_like DOUBLE PRECISION,
    humidity INTEGER,
    pressure DOUBLE PRECISION,
    visibility DOUBLE PRECISION,
    uv_index DOUBLE PRECISION,
    cloud_cover INTEGER,
    wind_speed DOUBLE PRECISION,
    wind_direction INTEGER,
    weather_condition TEXT,
    description TEXT,
    icon_code TEXT,
    sunrise TIMESTAMPTZ,
    sunset TIMESTAMPTZ,
    data_source TEXT DEFAULT 'openweather',
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Sun exposure sessions table
CREATE TABLE public.sun_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    location_id UUID REFERENCES public.user_locations(id) ON DELETE SET NULL,
    weather_id UUID REFERENCES public.weather_data(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_minutes INTEGER,
    uv_index_start DOUBLE PRECISION,
    uv_index_end DOUBLE PRECISION,
    uv_index_avg DOUBLE PRECISION,
    temperature_start DOUBLE PRECISION,
    temperature_end DOUBLE PRECISION,
    mood_before INTEGER, -- 1-5 scale
    mood_after INTEGER, -- 1-5 scale
    energy_before INTEGER, -- 1-5 scale
    energy_after INTEGER, -- 1-5 scale
    protection_used TEXT[], -- array of protection methods
    notes TEXT,
    status public.session_status DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User goals and preferences table
CREATE TABLE public.user_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    primary_goal_type TEXT NOT NULL,
    enable_secondary_goal BOOLEAN DEFAULT true,
    secondary_goal_type TEXT,
    sessions_per_day INTEGER DEFAULT 2,
    minutes_per_session INTEGER DEFAULT 15,
    sessions_per_week INTEGER DEFAULT 14,
    total_minutes_per_week INTEGER DEFAULT 210,
    target_vitamin_d BOOLEAN DEFAULT true,
    avoid_burning BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    type public.notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    is_delivered BOOLEAN DEFAULT false,
    scheduled_for TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Essential Indexes for performance
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_locations_user_id ON public.user_locations(user_id);
CREATE INDEX idx_user_locations_current ON public.user_locations(user_id, is_current);
CREATE INDEX idx_weather_data_user_id ON public.weather_data(user_id);
CREATE INDEX idx_weather_data_recorded_at ON public.weather_data(recorded_at);
CREATE INDEX idx_sun_sessions_user_id ON public.sun_sessions(user_id);
CREATE INDEX idx_sun_sessions_date ON public.sun_sessions(start_time);
CREATE INDEX idx_user_goals_user_id ON public.user_goals(user_id);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, is_read);

-- 5. Functions for automatic profile creation and data management
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'user')::public.user_role
    );
    RETURN NEW;
END;
$$;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Function to calculate session duration
CREATE OR REPLACE FUNCTION public.calculate_session_duration()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.end_time IS NOT NULL AND NEW.start_time IS NOT NULL THEN
        NEW.duration_minutes = EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 60;
    END IF;
    RETURN NEW;
END;
$$;

-- 6. Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weather_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sun_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies using safe patterns

-- Pattern 1: Core user table - simple ownership
CREATE POLICY "users_manage_own_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for all other tables
CREATE POLICY "users_manage_own_locations"
ON public.user_locations
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_weather_data"
ON public.weather_data
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_sessions"
ON public.sun_sessions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_goals"
ON public.user_goals
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_notifications"
ON public.notifications
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 8. Triggers
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_goals_updated_at
    BEFORE UPDATE ON public.user_goals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_sun_sessions_updated_at
    BEFORE UPDATE ON public.sun_sessions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER calculate_sun_session_duration
    BEFORE INSERT OR UPDATE ON public.sun_sessions
    FOR EACH ROW EXECUTE FUNCTION public.calculate_session_duration();

-- 9. Mock data for testing
DO $$
DECLARE
    user1_id UUID := gen_random_uuid();
    user2_id UUID := gen_random_uuid();
    location1_id UUID := gen_random_uuid();
    location2_id UUID := gen_random_uuid();
    weather1_id UUID := gen_random_uuid();
    weather2_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with all required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (user1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@sunbeam.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'user@sunbeam.com', crypt('user123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Test User"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Insert location data
    INSERT INTO public.user_locations (id, user_id, latitude, longitude, address, city, country, timezone) VALUES
        (location1_id, user1_id, 37.7749, -122.4194, '123 Market St', 'San Francisco', 'United States', 'America/Los_Angeles'),
        (location2_id, user2_id, 34.0522, -118.2437, '456 Hollywood Blvd', 'Los Angeles', 'United States', 'America/Los_Angeles');

    -- Insert weather data
    INSERT INTO public.weather_data (id, location_id, user_id, temperature, feels_like, humidity, pressure, uv_index, cloud_cover, wind_speed, weather_condition, description) VALUES
        (weather1_id, location1_id, user1_id, 22.5, 24.1, 65, 1013.2, 7.2, 20, 8.5, 'Partly Cloudy', 'Few clouds with sunshine'),
        (weather2_id, location2_id, user2_id, 26.8, 28.3, 58, 1015.1, 8.1, 15, 6.2, 'Clear Sky', 'Clear sunny day');

    -- Insert user goals
    INSERT INTO public.user_goals (user_id, primary_goal_type, enable_secondary_goal, secondary_goal_type, sessions_per_day, minutes_per_session) VALUES
        (user1_id, 'sessions_per_day', true, 'minutes_per_session', 2, 15),
        (user2_id, 'sessions_per_week', false, null, 1, 20);

    -- Insert sample sun sessions
    INSERT INTO public.sun_sessions (user_id, location_id, weather_id, start_time, end_time, uv_index_start, mood_before, energy_before, protection_used, status) VALUES
        (user1_id, location1_id, weather1_id, now() - interval '2 hours', now() - interval '1 hour 45 minutes', 7.2, 3, 4, ARRAY['sunscreen', 'sunglasses'], 'completed'),
        (user2_id, location2_id, weather2_id, now() - interval '1 day', now() - interval '1 day' + interval '20 minutes', 8.1, 4, 3, ARRAY['sunscreen', 'hat'], 'completed');

    -- Insert sample notifications
    INSERT INTO public.notifications (user_id, type, title, message, data) VALUES
        (user1_id, 'uv_warning', 'High UV Alert', 'UV index is currently 8. Consider protective measures.', '{"uv_index": 8, "location": "San Francisco"}'),
        (user2_id, 'goal_achievement', 'Goal Completed!', 'You have reached your weekly sun exposure goal.', '{"achievement": "weekly_goal", "progress": 100}');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;