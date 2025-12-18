-- Add an email column to user_profiles if it doesn't exist yet
alter table public.user_profiles
  add column if not exists email text;

-- Optional index for easier debugging or searching
create index if not exists user_profiles_email_idx
  on public.user_profiles (lower(email))
  where email is not null;
