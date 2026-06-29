create table if not exists public.online_rooms (
  id uuid default gen_random_uuid() primary key,
  host_id uuid references auth.users(id) on delete cascade not null,
  guest_id uuid references auth.users(id) on delete cascade,
  board_size int not null default 15,
  host_symbol text not null default 'X',
  status text not null default 'waiting',
  winner_id uuid,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.online_rooms enable row level security;

create policy "Anyone can read online rooms" 
  on public.online_rooms for select 
  using (true);

create policy "Authenticated users can create rooms" 
  on public.online_rooms for insert 
  with check (auth.role() = 'authenticated');

create policy "Hosts and guests can update their room" 
  on public.online_rooms for update 
  using (auth.uid() = host_id or auth.uid() = guest_id);
