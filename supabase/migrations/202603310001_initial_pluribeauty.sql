create extension if not exists "pgcrypto";

do $$
begin
  if not exists (select 1 from pg_type where typname = 'service_category') then
    create type public.service_category as enum ('cabelo', 'barba', 'unhas', 'estetica', 'maquiagem', 'outros');
  end if;

  if not exists (select 1 from pg_type where typname = 'service_type') then
    create type public.service_type as enum ('salao', 'domicilio');
  end if;

  if not exists (select 1 from pg_type where typname = 'booking_status') then
    create type public.booking_status as enum ('pendente', 'confirmado', 'concluido', 'cancelado');
  end if;

  if not exists (select 1 from pg_type where typname = 'notification_type') then
    create type public.notification_type as enum ('new_booking', 'booking_confirmed', 'booking_cancelled');
  end if;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  avatar_url text,
  phone text,
  city text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.professionals (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  cover_photo text,
  profile_photo text,
  specialties public.service_category[] not null default '{}',
  bio text,
  address text,
  city text not null,
  service_types public.service_type[] not null default '{}',
  rating numeric(2,1) not null default 5.0 check (rating between 0 and 5),
  total_reviews integer not null default 0 check (total_reviews >= 0),
  portfolio jsonb not null default '[]'::jsonb,
  is_featured boolean not null default false,
  price_from numeric(10,2) not null default 0 check (price_from >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid not null references public.professionals (id) on delete cascade,
  name text not null,
  category public.service_category not null,
  description text,
  price numeric(10,2) not null check (price >= 0),
  duration_minutes integer not null check (duration_minutes > 0),
  available_at public.service_type[] not null default '{salao}',
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles (id) on delete cascade,
  professional_id uuid not null references public.professionals (id) on delete cascade,
  booking_date date not null,
  booking_time time not null,
  location_type public.service_type not null,
  address text,
  status public.booking_status not null default 'pendente',
  total_price numeric(10,2) not null default 0 check (total_price >= 0),
  total_duration_minutes integer not null default 0 check (total_duration_minutes >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.booking_services (
  booking_id uuid not null references public.bookings (id) on delete cascade,
  service_id uuid not null references public.services (id) on delete restrict,
  service_name text not null,
  price numeric(10,2) not null check (price >= 0),
  primary key (booking_id, service_id)
);

create table if not exists public.favorites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  professional_id uuid not null references public.professionals (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, professional_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references public.bookings (id) on delete set null,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type public.notification_type not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings (id) on delete cascade,
  professional_id uuid not null references public.professionals (id) on delete cascade,
  client_id uuid not null references public.profiles (id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.professional_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending',
  business_name text not null,
  cpf_cnpj text not null,
  rg_cnh_url text,
  portfolio_links jsonb not null default '[]'::jsonb,
  specialties public.service_category[] not null default '{}',
  service_types public.service_type[] not null default '{}',
  coverage_radius_km integer not null default 10 check (coverage_radius_km between 1 and 50),
  notes text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists professionals_owner_id_idx on public.professionals (owner_id);
create index if not exists professionals_featured_idx on public.professionals (is_featured) where is_featured = true;
create index if not exists professionals_city_idx on public.professionals (city);
create index if not exists services_professional_id_idx on public.services (professional_id);
create index if not exists services_category_idx on public.services (category);
create index if not exists bookings_client_id_date_idx on public.bookings (client_id, booking_date desc);
create index if not exists bookings_professional_id_date_idx on public.bookings (professional_id, booking_date desc);
create index if not exists messages_sender_recipient_created_idx on public.messages (sender_id, recipient_id, created_at desc);
create index if not exists notifications_user_created_idx on public.notifications (user_id, created_at desc);
create index if not exists reviews_professional_id_idx on public.reviews (professional_id);

alter table public.profiles enable row level security;
alter table public.professionals enable row level security;
alter table public.services enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_services enable row level security;
alter table public.favorites enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.reviews enable row level security;
alter table public.professional_applications enable row level security;

create policy "profiles are readable by authenticated users"
on public.profiles for select
to authenticated
using (true);

create policy "users manage their own profile"
on public.profiles for all
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "professionals are publicly readable"
on public.professionals for select
to anon, authenticated
using (true);

create policy "owners manage their professionals"
on public.professionals for all
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "services are publicly readable"
on public.services for select
to anon, authenticated
using (true);

create policy "professional owners manage services"
on public.services for all
to authenticated
using (
  exists (
    select 1
    from public.professionals p
    where p.id = professional_id
      and p.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.professionals p
    where p.id = professional_id
      and p.owner_id = auth.uid()
  )
);

create policy "booking participants can read bookings"
on public.bookings for select
to authenticated
using (
  client_id = auth.uid()
  or exists (
    select 1
    from public.professionals p
    where p.id = professional_id
      and p.owner_id = auth.uid()
  )
);

create policy "clients create bookings"
on public.bookings for insert
to authenticated
with check (client_id = auth.uid());

create policy "participants update bookings"
on public.bookings for update
to authenticated
using (
  client_id = auth.uid()
  or exists (
    select 1
    from public.professionals p
    where p.id = professional_id
      and p.owner_id = auth.uid()
  )
)
with check (
  client_id = auth.uid()
  or exists (
    select 1
    from public.professionals p
    where p.id = professional_id
      and p.owner_id = auth.uid()
  )
);

create policy "booking services follow booking visibility"
on public.booking_services for select
to authenticated
using (
  exists (
    select 1
    from public.bookings b
    where b.id = booking_id
      and (
        b.client_id = auth.uid()
        or exists (
          select 1
          from public.professionals p
          where p.id = b.professional_id
            and p.owner_id = auth.uid()
        )
      )
  )
);

create policy "users manage their favorites"
on public.favorites for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "message participants can read and send"
on public.messages for select
to authenticated
using (sender_id = auth.uid() or recipient_id = auth.uid());

create policy "users send their own messages"
on public.messages for insert
to authenticated
with check (sender_id = auth.uid());

create policy "users read their notifications"
on public.notifications for select
to authenticated
using (user_id = auth.uid());

create policy "users update their notifications"
on public.notifications for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "reviews are publicly readable"
on public.reviews for select
to anon, authenticated
using (true);

create policy "clients create reviews from own bookings"
on public.reviews for insert
to authenticated
with check (client_id = auth.uid());

create policy "users manage own applications"
on public.professional_applications for all
to authenticated
using (applicant_id = auth.uid())
with check (applicant_id = auth.uid());
