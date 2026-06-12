-- Remove development test accounts (seeded by the initial migration).
-- All user data cascades from auth.users -> user_profiles -> child tables.
DELETE FROM auth.users
WHERE email IN ('admin@sunbeam.com', 'user@sunbeam.com');

-- Self-service account deletion, required for App Store compliance.
-- SECURITY DEFINER so the function (owned by the migration role) may delete
-- from auth.users; callers can only ever delete their own account.
CREATE OR REPLACE FUNCTION public.delete_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.delete_account() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_account() FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated;
