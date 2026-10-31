-- FamBon Supabase foundation
-- Run in Supabase SQL Editor only after creating a project.
-- Never put a service-role key in browser code.

create extension if not exists pgcrypto;

create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 70),
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 50),
  role text not null default 'member' check (role in ('owner','adult','member')),
  joined_at timestamptz not null default now(),
  primary key (family_id,user_id)
);

create table if not exists public.family_invites (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  token_hash text not null unique,
  invited_by uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('adult','member')),
  expires_at timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.family_answers (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  prompt text not null check (char_length(prompt) between 1 and 500),
  answer text not null check (char_length(answer) between 1 and 5000),
  visibility text not null default 'family' check (visibility in ('private','family')),
  created_at timestamptz not null default now()
);

create table if not exists public.family_memories (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  body text not null check (char_length(body) between 1 and 5000),
  emoji text not null default '💛',
  created_at timestamptz not null default now()
);

create table if not exists public.family_game_sessions (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  game_type text not null check (game_type in ('most_likely','two_truths_wish','remember_when')),
  state jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('active','completed','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.family_characters (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null unique references public.families(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  drawing_path text,
  drawing_data jsonb not null default '{}'::jsonb,
  turn_order uuid[] not null default '{}',
  current_turn integer not null default 0 check (current_turn >= 0),
  updated_at timestamptz not null default now()
);


-- Member spotlights: family-shared birthdays, milestones, and support moments.
create table if not exists public.family_spotlights (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  member_name text not null check (char_length(member_name) between 1 and 60),
  occasion_type text not null check (occasion_type in ('birthday','graduation','new_job','new_baby','milestone','challenge','anniversary','other')),
  title text not null default '' check (char_length(title) <= 100),
  event_date date,
  support_note text not null default '' check (char_length(support_note) <= 700),
  emoji text not null default '💛' check (char_length(emoji) <= 8),
  completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists family_spotlights_family_date_idx on public.family_spotlights(family_id,event_date);

-- Family memory ideas: suggestions for experiences the family hopes to make.
create table if not exists public.family_memory_ideas (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  suggested_by uuid not null references auth.users(id) on delete cascade,
  suggested_by_name text not null check (char_length(suggested_by_name) between 1 and 50),
  title text not null check (char_length(title) between 1 and 100),
  category text not null default 'Other' check (char_length(category) between 1 and 40),
  details text not null default '' check (char_length(details) <= 1000),
  status text not null default 'idea' check (status in ('idea','planned','made')),
  planned_for date,
  made_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists family_memory_ideas_family_created_idx on public.family_memory_ideas(family_id,created_at desc);
create unique index if not exists family_memory_ideas_id_family_uidx on public.family_memory_ideas(id,family_id);

-- One authenticated vote per family member and idea. A member may change their choice.
create table if not exists public.family_memory_idea_votes (
  idea_id uuid not null references public.family_memory_ideas(id) on delete cascade,
  family_id uuid not null references public.families(id) on delete cascade,
  voter_id uuid not null references auth.users(id) on delete cascade,
  choice text not null check (choice in ('love','maybe')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (idea_id, voter_id),
  constraint family_memory_idea_votes_idea_family_fk
    foreign key (idea_id, family_id)
    references public.family_memory_ideas(id, family_id)
    on delete cascade
);
create index if not exists family_memory_idea_votes_family_idx on public.family_memory_idea_votes(family_id,idea_id);


create table if not exists public.family_garden_steps (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  completed_by uuid not null references auth.users(id) on delete cascade,
  step_key text not null check (char_length(step_key) between 1 and 80),
  reflection text check (reflection is null or char_length(reflection) <= 2000),
  completed_at timestamptz not null default now()
);

create index if not exists family_members_user_idx on public.family_members(user_id);
create index if not exists family_answers_family_created_idx on public.family_answers(family_id,created_at desc);
create index if not exists family_memories_family_created_idx on public.family_memories(family_id,created_at desc);
create index if not exists family_games_family_created_idx on public.family_game_sessions(family_id,created_at desc);
create index if not exists family_invites_family_idx on public.family_invites(family_id);

-- SECURITY DEFINER membership helpers avoid recursive RLS policy evaluation.
create or replace function public.is_family_member(target_family uuid)
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.family_members m
    where m.family_id = target_family and m.user_id = auth.uid()
  );
$$;

create or replace function public.is_family_manager(target_family uuid)
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.family_members m
    where m.family_id = target_family and m.user_id = auth.uid()
      and m.role in ('owner','adult')
  );
$$;

revoke all on function public.is_family_member(uuid) from public;
revoke all on function public.is_family_manager(uuid) from public;
grant execute on function public.is_family_member(uuid) to authenticated;
grant execute on function public.is_family_manager(uuid) to authenticated;

alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.family_invites enable row level security;
alter table public.family_answers enable row level security;
alter table public.family_memories enable row level security;
alter table public.family_game_sessions enable row level security;
alter table public.family_characters enable row level security;
alter table public.family_garden_steps enable row level security;
alter table public.family_spotlights enable row level security;
alter table public.family_memory_ideas enable row level security;
alter table public.family_memory_idea_votes enable row level security;

drop policy if exists "family members can view their family" on public.families;
create policy "family members can view their family" on public.families
for select to authenticated using (public.is_family_member(id));
drop policy if exists "family managers can update family" on public.families;
create policy "family managers can update family" on public.families
for update to authenticated using (public.is_family_manager(id))
with check (public.is_family_manager(id));

drop policy if exists "members can view family roster" on public.family_members;
create policy "members can view family roster" on public.family_members
for select to authenticated using (public.is_family_member(family_id));
drop policy if exists "managers can add family members" on public.family_members;
create policy "managers can add family members" on public.family_members
for insert to authenticated with check (public.is_family_manager(family_id));
drop policy if exists "managers can update family members" on public.family_members;
create policy "managers can update family members" on public.family_members
for update to authenticated using (public.is_family_manager(family_id))
with check (public.is_family_manager(family_id));
drop policy if exists "managers or self can leave family" on public.family_members;
create policy "managers or self can leave family" on public.family_members
for delete to authenticated using (user_id = auth.uid() or public.is_family_manager(family_id));

drop policy if exists "managers can manage invites" on public.family_invites;
create policy "managers can manage invites" on public.family_invites
for all to authenticated using (public.is_family_manager(family_id))
with check (public.is_family_manager(family_id));

drop policy if exists "members can read family answers" on public.family_answers;
create policy "members can read family answers" on public.family_answers
for select to authenticated using (
  public.is_family_member(family_id) and (visibility = 'family' or author_id = auth.uid())
);
drop policy if exists "members can create own answers" on public.family_answers;
create policy "members can create own answers" on public.family_answers
for insert to authenticated with check (
  public.is_family_member(family_id) and author_id = auth.uid()
);
drop policy if exists "authors can update own answers" on public.family_answers;
create policy "authors can update own answers" on public.family_answers
for update to authenticated using (author_id = auth.uid() and public.is_family_member(family_id))
with check (author_id = auth.uid() and public.is_family_member(family_id));
drop policy if exists "authors or managers can delete answers" on public.family_answers;
create policy "authors or managers can delete answers" on public.family_answers
for delete to authenticated using (author_id = auth.uid() or public.is_family_manager(family_id));

drop policy if exists "family members can read memories" on public.family_memories;
create policy "family members can read memories" on public.family_memories
for select to authenticated using (public.is_family_member(family_id));
drop policy if exists "members can create memories" on public.family_memories;
create policy "members can create memories" on public.family_memories
for insert to authenticated with check (public.is_family_member(family_id) and author_id = auth.uid());
drop policy if exists "authors can update memories" on public.family_memories;
create policy "authors can update memories" on public.family_memories
for update to authenticated using (author_id = auth.uid() and public.is_family_member(family_id))
with check (author_id = auth.uid() and public.is_family_member(family_id));
drop policy if exists "authors or managers can delete memories" on public.family_memories;
create policy "authors or managers can delete memories" on public.family_memories
for delete to authenticated using (author_id = auth.uid() or public.is_family_manager(family_id));

drop policy if exists "members can read games" on public.family_game_sessions;
create policy "members can read games" on public.family_game_sessions
for select to authenticated using (public.is_family_member(family_id));
drop policy if exists "members can create games" on public.family_game_sessions;
create policy "members can create games" on public.family_game_sessions
for insert to authenticated with check (public.is_family_member(family_id) and created_by = auth.uid());
drop policy if exists "members can update games" on public.family_game_sessions;
create policy "members can update games" on public.family_game_sessions
for update to authenticated using (public.is_family_member(family_id))
with check (public.is_family_member(family_id));
drop policy if exists "managers can delete games" on public.family_game_sessions;
create policy "managers can delete games" on public.family_game_sessions
for delete to authenticated using (public.is_family_manager(family_id));

drop policy if exists "members can read character" on public.family_characters;
create policy "members can read character" on public.family_characters
for select to authenticated using (public.is_family_member(family_id));
drop policy if exists "members can create character" on public.family_characters;
create policy "members can create character" on public.family_characters
for insert to authenticated with check (public.is_family_member(family_id) and created_by = auth.uid());
drop policy if exists "members can update character" on public.family_characters;
create policy "members can update character" on public.family_characters
for update to authenticated using (public.is_family_member(family_id))
with check (public.is_family_member(family_id));
drop policy if exists "managers can delete character" on public.family_characters;
create policy "managers can delete character" on public.family_characters
for delete to authenticated using (public.is_family_manager(family_id));


drop policy if exists "family members can view spotlights" on public.family_spotlights;
create policy "family members can view spotlights" on public.family_spotlights
for select to authenticated using (public.is_family_member(family_id));
drop policy if exists "family members can create spotlights" on public.family_spotlights;
create policy "family members can create spotlights" on public.family_spotlights
for insert to authenticated with check (public.is_family_member(family_id) and created_by = auth.uid());
drop policy if exists "authors or managers can update spotlights" on public.family_spotlights;
create policy "authors or managers can update spotlights" on public.family_spotlights
for update to authenticated using (created_by = auth.uid() or public.is_family_manager(family_id))
with check (public.is_family_member(family_id));
drop policy if exists "authors or managers can delete spotlights" on public.family_spotlights;
create policy "authors or managers can delete spotlights" on public.family_spotlights
for delete to authenticated using (created_by = auth.uid() or public.is_family_manager(family_id));

drop policy if exists "family members can view memory ideas" on public.family_memory_ideas;
create policy "family members can view memory ideas" on public.family_memory_ideas
for select to authenticated using (public.is_family_member(family_id));
drop policy if exists "members can suggest memory ideas" on public.family_memory_ideas;
create policy "members can suggest memory ideas" on public.family_memory_ideas
for insert to authenticated with check (public.is_family_member(family_id) and suggested_by = auth.uid());
drop policy if exists "members can update memory idea status" on public.family_memory_ideas;
create policy "members can update memory idea status" on public.family_memory_ideas
for update to authenticated using (public.is_family_member(family_id))
with check (public.is_family_member(family_id));
drop policy if exists "authors or managers can delete memory ideas" on public.family_memory_ideas;
create policy "authors or managers can delete memory ideas" on public.family_memory_ideas
for delete to authenticated using (suggested_by = auth.uid() or public.is_family_manager(family_id));

drop policy if exists "family members can read idea votes" on public.family_memory_idea_votes;
create policy "family members can read idea votes" on public.family_memory_idea_votes
for select to authenticated using (public.is_family_member(family_id));
drop policy if exists "members can cast their own idea votes" on public.family_memory_idea_votes;
create policy "members can cast their own idea votes" on public.family_memory_idea_votes
for insert to authenticated with check (
  voter_id = auth.uid()
  and public.is_family_member(family_id)
  and exists (
    select 1 from public.family_memory_ideas i
    where i.id = family_memory_idea_votes.idea_id and i.family_id = family_memory_idea_votes.family_id and i.status <> 'made'
  )
);
drop policy if exists "members can change their own idea votes" on public.family_memory_idea_votes;
create policy "members can change their own idea votes" on public.family_memory_idea_votes
for update to authenticated using (
  voter_id = auth.uid() and public.is_family_member(family_id)
) with check (
  voter_id = auth.uid() and public.is_family_member(family_id)
  and exists (
    select 1 from public.family_memory_ideas i
    where i.id = family_memory_idea_votes.idea_id and i.family_id = family_memory_idea_votes.family_id and i.status <> 'made'
  )
);
drop policy if exists "members can remove their own idea votes" on public.family_memory_idea_votes;
create policy "members can remove their own idea votes" on public.family_memory_idea_votes
for delete to authenticated using (voter_id = auth.uid() and public.is_family_member(family_id));


drop policy if exists "members can read garden steps" on public.family_garden_steps;
create policy "members can read garden steps" on public.family_garden_steps
for select to authenticated using (public.is_family_member(family_id));
drop policy if exists "members can add own garden steps" on public.family_garden_steps;
create policy "members can add own garden steps" on public.family_garden_steps
for insert to authenticated with check (public.is_family_member(family_id) and completed_by = auth.uid());
drop policy if exists "authors or managers can delete garden steps" on public.family_garden_steps;
create policy "authors or managers can delete garden steps" on public.family_garden_steps
for delete to authenticated using (completed_by = auth.uid() or public.is_family_manager(family_id));

-- Create a family and make the signed-in user its owner in one transaction.
create or replace function public.create_family(family_name text, member_display_name text)
returns uuid language plpgsql security definer
set search_path = public, pg_temp
as $$
declare new_family_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if length(trim(family_name)) not between 1 and 70 then raise exception 'Family name must be 1–70 characters'; end if;
  if length(trim(member_display_name)) not between 1 and 50 then raise exception 'Display name must be 1–50 characters'; end if;
  insert into public.families(name,created_by) values(trim(family_name),auth.uid()) returning id into new_family_id;
  insert into public.family_members(family_id,user_id,display_name,role)
  values(new_family_id,auth.uid(),trim(member_display_name),'owner');
  return new_family_id;
end;
$$;
revoke all on function public.create_family(text,text) from public;
grant execute on function public.create_family(text,text) to authenticated;

-- Invite token is returned once; only its SHA-256 hash is stored.
create or replace function public.create_family_invite(target_family uuid, member_role text default 'member')
returns text language plpgsql security definer
set search_path = public, pg_temp
as $$
declare raw_token text;
begin
  if not public.is_family_manager(target_family) then raise exception 'Family manager access required'; end if;
  if member_role not in ('adult','member') then raise exception 'Invalid invite role'; end if;
  raw_token := encode(gen_random_bytes(32),'hex');
  insert into public.family_invites(family_id,token_hash,invited_by,role,expires_at)
  values(target_family,encode(digest(raw_token,'sha256'),'hex'),auth.uid(),member_role,now()+interval '7 days');
  return raw_token;
end;
$$;
revoke all on function public.create_family_invite(uuid,text) from public;
grant execute on function public.create_family_invite(uuid,text) to authenticated;

-- Redeem a single-use invite while signed in; raw token is never stored.
create or replace function public.accept_family_invite(invite_token text, member_display_name text)
returns uuid language plpgsql security definer
set search_path = public, pg_temp
as $$
declare invite_row public.family_invites%rowtype;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if length(trim(member_display_name)) not between 1 and 50 then raise exception 'Display name must be 1–50 characters'; end if;
  select * into invite_row from public.family_invites
  where token_hash = encode(digest(invite_token,'sha256'),'hex')
    and accepted_at is null and expires_at > now()
  for update;
  if not found then raise exception 'Invite is invalid, expired, or already used'; end if;
  insert into public.family_members(family_id,user_id,display_name,role)
  values(invite_row.family_id,auth.uid(),trim(member_display_name),invite_row.role)
  on conflict (family_id,user_id) do nothing;
  update public.family_invites set accepted_at=now() where id=invite_row.id;
  return invite_row.family_id;
end;
$$;
revoke all on function public.accept_family_invite(text,text) from public;
grant execute on function public.accept_family_invite(text,text) to authenticated;

grant select, update on public.families to authenticated;
grant select, insert, update, delete on public.family_members to authenticated;
grant select, insert, update, delete on public.family_invites to authenticated;
grant select, insert, update, delete on public.family_answers to authenticated;
grant select, insert, update, delete on public.family_memories to authenticated;
grant select, insert, update, delete on public.family_game_sessions to authenticated;
grant select, insert, update, delete on public.family_characters to authenticated;
grant select, insert, delete on public.family_garden_steps to authenticated;
grant select, insert, update, delete on public.family_spotlights to authenticated;
grant select, insert, update, delete on public.family_memory_ideas to authenticated;
grant select, insert, update, delete on public.family_memory_idea_votes to authenticated;
