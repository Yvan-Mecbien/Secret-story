-- ============================================================
-- SECRET STORY — Schéma Supabase complet
-- Exécuter entièrement dans SQL Editor > New query > Run
-- ============================================================

-- Extension UUID
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. GROUPES
-- ============================================================
create table if not exists public.groups (
  id    uuid primary key default uuid_generate_v4(),
  name  text not null unique,
  color text not null,
  lien text not null
);

-- Groupes par défaut
insert into public.groups (name, color) values
  ('Rouge',  '#E24B4A'),
  ('Bleu',   '#378ADD'),
  ('Vert',   '#639922'),
  ('Jaune',  '#EF9F27')
on conflict (name) do nothing;

-- ============================================================
-- 2. UTILISATEURS (profil joueur, lié à auth.users)
-- ============================================================
create table if not exists public.users (
  id            uuid primary key references auth.users(id) on delete cascade,
  pseudo        text not null unique,
  secret        text not null,
  group_id      uuid references public.groups(id),
  points        integer not null default 0,
  is_eliminated boolean not null default false,
  created_at    timestamptz not null default now()
);

-- ============================================================
-- 3. PARAMÈTRES DU JEU (une seule ligne)
-- ============================================================
create table if not exists public.game_settings (
  id            uuid primary key default uuid_generate_v4(),
  game_started  boolean not null default false,
  current_phase text not null default 'waiting'
    check (current_phase in ('waiting','game','vote','elimination','finished'))
);

-- Ligne initiale
insert into public.game_settings (game_started, current_phase)
select false, 'waiting'
where not exists (select 1 from public.game_settings);

-- ============================================================
-- 4. MINI-JEUX
-- ============================================================
create table if not exists public.games (
  id            uuid primary key default uuid_generate_v4(),
  title         text not null,
  description   text not null,
  points_reward integer not null default 50,
  is_active     boolean not null default false,
  created_at    timestamptz not null default now()
);

-- Jeux d'exemple
insert into public.games (title, description, points_reward, is_active) values
  ('Quiz mystère',  'Devinez le secret d''un joueur parmi 4 propositions.', 50, false),
  ('Défi express',  'Accomplissez un défi en moins de 60 secondes.',         75, false),
  ('Qui suis-je ?', 'Trouvez l''identité d''un joueur à partir d''indices.', 60, false)
on conflict do nothing;

-- ============================================================
-- 5. VOTES
-- ============================================================
create table if not exists public.votes (
  id               uuid primary key default uuid_generate_v4(),
  voter_id         uuid not null references public.users(id) on delete cascade,
  target_player_id uuid not null references public.users(id) on delete cascade,
  session_id       text not null,
  created_at       timestamptz not null default now(),
  unique(voter_id, session_id)
);

-- ============================================================
-- 6. HISTORIQUE DES POINTS
-- ============================================================
create table if not exists public.point_history (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.users(id) on delete cascade,
  game_id    uuid references public.games(id),
  points     integer not null,
  reason     text not null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 7. PARTICIPATIONS AUX JEUX (anti-doublon)
-- ============================================================
create table if not exists public.game_participations (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.users(id) on delete cascade,
  game_id    uuid not null references public.games(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, game_id)
);

-- ============================================================
-- 8. REALTIME — activer sur les tables dynamiques
-- ============================================================
alter publication supabase_realtime add table public.users;
alter publication supabase_realtime add table public.game_settings;
alter publication supabase_realtime add table public.games;

-- ============================================================
-- 9. ROW LEVEL SECURITY
-- ============================================================

-- groups : lecture pour tous les joueurs connectés
alter table public.groups enable row level security;
drop policy if exists "groups_read" on public.groups;
create policy "groups_read" on public.groups
  for select using (auth.role() = 'authenticated');

-- users : lecture publique, modification uniquement de soi-même
alter table public.users enable row level security;
drop policy if exists "users_read"   on public.users;
drop policy if exists "users_insert" on public.users;
drop policy if exists "users_update" on public.users;
create policy "users_read" on public.users
  for select using (auth.role() = 'authenticated');
create policy "users_insert" on public.users
  for insert with check (auth.uid() = id);
create policy "users_update" on public.users
  for update using (auth.uid() = id);

-- game_settings : lecture publique
alter table public.game_settings enable row level security;
drop policy if exists "settings_read" on public.game_settings;
create policy "settings_read" on public.game_settings
  for select using (auth.role() = 'authenticated');

-- games : lecture publique
alter table public.games enable row level security;
drop policy if exists "games_read" on public.games;
create policy "games_read" on public.games
  for select using (auth.role() = 'authenticated');

-- votes : un joueur voit et insère uniquement ses votes
alter table public.votes enable row level security;
drop policy if exists "votes_read"   on public.votes;
drop policy if exists "votes_insert" on public.votes;
create policy "votes_read" on public.votes
  for select using (auth.uid() = voter_id);
create policy "votes_insert" on public.votes
  for insert with check (auth.uid() = voter_id);

-- point_history : un joueur voit uniquement son historique
alter table public.point_history enable row level security;
drop policy if exists "history_read"   on public.point_history;
drop policy if exists "history_insert" on public.point_history;
create policy "history_read" on public.point_history
  for select using (auth.uid() = user_id);
create policy "history_insert" on public.point_history
  for insert with check (auth.uid() = user_id);

-- game_participations
alter table public.game_participations enable row level security;
drop policy if exists "participation_read"   on public.game_participations;
drop policy if exists "participation_insert" on public.game_participations;
create policy "participation_read" on public.game_participations
  for select using (auth.uid() = user_id);
create policy "participation_insert" on public.game_participations
  for insert with check (auth.uid() = user_id);

-- ============================================================
-- 10. FONCTIONS POSTGRESQL
-- ============================================================

-- Ajouter des points à un joueur + enregistrer l'historique
create or replace function public.add_points(
  p_user_id uuid,
  p_points   integer,
  p_game_id  uuid,
  p_reason   text
)
returns void
language plpgsql
security definer
as $$
begin
  update public.users
    set points = points + p_points
    where id = p_user_id;

  insert into public.point_history (user_id, game_id, points, reason)
    values (p_user_id, p_game_id, p_points, p_reason);
end;
$$;

-- Retourner le groupe avec le moins de joueurs
create or replace function public.least_populated_group()
returns uuid
language sql
security definer
as $$
  select g.id
  from public.groups g
  left join public.users u on u.group_id = g.id
  group by g.id
  order by count(u.id) asc
  limit 1;
$$;


CREATE OR REPLACE FUNCTION register_user(
  p_user_id TEXT,
  p_pseudo TEXT,
  p_email TEXT,
  p_password_hash TEXT,
  p_secret TEXT,
  p_group_id TEXT,
  p_created_at TIMESTAMPTZ
) RETURNS VOID AS $$
BEGIN
  -- Insérer l'utilisateur
  INSERT INTO users (
    id, pseudo, email, password_hash, secret, 
    group_id, points, is_eliminated, created_at, updated_at
  ) VALUES (
    p_user_id, p_pseudo, p_email, p_password_hash, p_secret,
    p_group_id, 0, false, p_created_at, p_created_at
  );
  
  -- Mettre à jour le compteur du groupe
  UPDATE groups 
  SET nbr_membre = nbr_membre + 1 
  WHERE id = p_group_id;
END;
$$ LANGUAGE plpgsql;

-- Donner accès en lecture à tous les utilisateurs authentifiés
CREATE POLICY "Lecture groupes pour tous" ON groups
  FOR SELECT USING (auth.role() = 'authenticated');

-- Donner accès en lecture aux utilisateurs anonymes aussi si nécessaire
CREATE POLICY "Lecture groupes pour anonymes" ON groups
  FOR SELECT USING (auth.role() = 'anon');

-- ============================================================
-- 11. COMMANDES ADMIN (à exécuter manuellement depuis SQL Editor)
-- ============================================================

-- Démarrer la partie :
-- update public.game_settings set game_started = true, current_phase = 'game';

-- Activer un mini-jeu :
-- update public.games set is_active = true where title = 'Quiz mystère';

-- Désactiver tous les jeux :
-- update public.games set is_active = false;

-- Passer en phase de vote :
-- update public.game_settings set current_phase = 'vote';

-- Voir les résultats du vote du jour :
-- select u.pseudo, count(*) as nb_votes
-- from public.votes v
-- join public.users u on u.id = v.target_player_id
-- where v.session_id = 'vote_' || extract(year from now()) || '_'
--                               || extract(month from now()) || '_'
--                               || extract(day from now())
-- group by u.pseudo
-- order by nb_votes desc;

-- Éliminer le joueur le plus voté :
-- update public.users set is_eliminated = true
-- where id = (
--   select target_player_id from public.votes
--   where session_id = 'vote_' || extract(year from now()) || '_'
--                               || extract(month from now()) || '_'
--                               || extract(day from now())
--   group by target_player_id
--   order by count(*) desc
--   limit 1
-- );

-- Passer en phase d'élimination puis retour au jeu :
-- update public.game_settings set current_phase = 'elimination';
-- update public.game_settings set current_phase = 'game';

-- Terminer la partie :
-- update public.game_settings set current_phase = 'finished';

-- Réinitialiser complètement (nouvelle partie) :
-- truncate public.votes, public.point_history, public.game_participations;
-- update public.users set points = 0, is_eliminated = false;
-- update public.game_settings set game_started = false, current_phase = 'waiting';
-- update public.games set is_active = false;



-- ============================================================
-- TABLE: indices
-- Indice révélé sur un joueur (envoyé comme pénalité de vote faux)
-- ============================================================
create table if not exists public.indices (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.users(id) on delete cascade,  -- joueur concerné par l'indice
  indice     text not null,                -- texte de l'indice
  visible    boolean not null default true, -- visible dans l'app ou non
  created_at timestamptz not null default now()
);

-- RLS
alter table public.indices enable row level security;

-- Tous les joueurs connectés peuvent lire les indices visibles
drop policy if exists "indices_read" on public.indices;
create policy "indices_read" on public.indices
  for select using (auth.role() = 'authenticated' and visible = true);

-- Seul le service (admin) peut insérer
-- (les insertions se font via la fonction add_penalty ci-dessous)
drop policy if exists "indices_insert_service" on public.indices;
create policy "indices_insert_service" on public.indices
  for insert with check (auth.role() = 'service_role');

-- ============================================================
-- TABLE: vote_attempts  (remplace l'ancienne table votes)
-- Stocke chaque tentative de vote avec le secret proposé
-- ============================================================
create table if not exists public.vote_attempts (
  id               uuid primary key default uuid_generate_v4(),
  voter_id         uuid not null references public.users(id) on delete cascade,
  target_player_id uuid not null references public.users(id) on delete cascade,
  secret_proposed  text not null,   -- secret que le votant a sélectionné
  is_correct       boolean,         -- null = pas encore évalué, true/false après vérif
  session_date     date not null default current_date,
  created_at       timestamptz not null default now()
);

-- RLS
alter table public.vote_attempts enable row level security;

drop policy if exists "vote_attempts_read"   on public.vote_attempts;
drop policy if exists "vote_attempts_insert" on public.vote_attempts;

-- Un joueur voit uniquement ses propres tentatives
create policy "vote_attempts_read" on public.vote_attempts
  for select using (auth.uid() = voter_id);

-- Un joueur insère avec son propre voter_id
create policy "vote_attempts_insert" on public.vote_attempts
  for insert with check (auth.uid() = voter_id);

-- ============================================================
-- FONCTION: traiter un vote
-- Vérifie si le secret proposé correspond au joueur ciblé.
-- • Correct  → le joueur cible est éliminé
-- • Incorrect → déduit 20 pts au votant + insère un indice public
-- ============================================================
create or replace function public.process_vote(
  p_voter_id         uuid,
  p_target_player_id uuid,
  p_secret_proposed  text
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_real_secret text;
  v_correct     boolean;
  v_indice      text;
begin
  -- Récupérer le vrai secret du joueur cible
  select secret into v_real_secret
    from public.users
    where id = p_target_player_id;

  -- Comparer (insensible à la casse et aux espaces)
  v_correct := lower(trim(p_secret_proposed)) = lower(trim(v_real_secret));

  -- Enregistrer la tentative
  insert into public.vote_attempts
    (voter_id, target_player_id, secret_proposed, is_correct, session_date)
  values
    (p_voter_id, p_target_player_id, p_secret_proposed, v_correct, current_date);

  if v_correct then
    -- Éliminer le joueur cible
    update public.users set is_eliminated = true where id = p_target_player_id;
  else
    -- Pénalité: -20 pts au votant
    update public.users
      set points = greatest(0, points - 20)
      where id = p_voter_id;

    -- Insérer un indice sur le votant (les autres joueurs le voient)
    -- L'indice est: les 3 premiers mots du secret du votant
    select concat(
      split_part(secret, ' ', 1), ' ',
      split_part(secret, ' ', 2), ' ',
      split_part(secret, ' ', 3), '...'
    ) into v_indice
    from public.users where id = p_voter_id;

    insert into public.indices (user_id, indice, visible)
      values (p_voter_id, v_indice, true);

    -- Enregistrer la pénalité dans l'historique
    insert into public.point_history (user_id, game_id, points, reason)
      values (p_voter_id, null, -20, 'Pénalité : vote incorrect');
  end if;

  return jsonb_build_object('correct', v_correct);
end;
$$;

-- ============================================================
-- Activer Realtime sur les nouvelles tables
-- ============================================================
alter publication supabase_realtime add table public.indices;









-- ============================================================
-- MISE À JOUR COMPLÈTE DU SYSTÈME DE JEUX
-- ============================================================

-- 1. Ajouter game_type à la table games
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS
  game_type text NOT NULL DEFAULT 'quiz'
  CHECK (game_type IN (
    'quiz', 'intrus', 'tap_challenge', 'vrai_faux',
    'enquete', 'puzzle', 'association', 'memoire', 'calcul'
  ));

-- 2. Table questions (liées à un jeu)
CREATE TABLE IF NOT EXISTS public.questions (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  game_id      uuid NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  position     integer NOT NULL DEFAULT 0,  -- ordre d'affichage
  question     text NOT NULL,
  options      jsonb,        -- tableau ["A","B","C","D"] pour QCM/intrus/etc.
  answer       text NOT NULL, -- bonne réponse ou index
  extra        jsonb,        -- données spécifiques au type (mots, suspects, etc.)
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_questions_game ON public.questions(game_id, position);

-- RLS questions
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "questions_read" ON public.questions;
CREATE POLICY "questions_read" ON public.questions
  FOR SELECT USING (auth.role() = 'authenticated');

-- 3. Table game_sessions : suivi progression par joueur
CREATE TABLE IF NOT EXISTS public.game_sessions (
  id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  game_id         uuid NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  score           integer NOT NULL DEFAULT 0,
  current_question integer NOT NULL DEFAULT 0,  -- index question en cours
  completed       boolean NOT NULL DEFAULT false,
  started_at      timestamptz NOT NULL DEFAULT now(),
  last_active_at  timestamptz NOT NULL DEFAULT now(),
  completed_at    timestamptz,
  UNIQUE(user_id, game_id)  -- une seule session par joueur par jeu
);

ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sessions_read"   ON public.game_sessions;
DROP POLICY IF EXISTS "sessions_insert" ON public.game_sessions;
DROP POLICY IF EXISTS "sessions_update" ON public.game_sessions;
CREATE POLICY "sessions_read"   ON public.game_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "sessions_insert" ON public.game_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "sessions_update" ON public.game_sessions FOR UPDATE USING (auth.uid() = user_id);

-- 4. Fonction : sauvegarder progression
CREATE OR REPLACE FUNCTION public.save_game_progress(
  p_user_id        uuid,
  p_game_id        uuid,
  p_score          integer,
  p_current_q      integer,
  p_completed      boolean
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.game_sessions
    (user_id, game_id, score, current_question, completed, last_active_at, completed_at)
  VALUES
    (p_user_id, p_game_id, p_score, p_current_q, p_completed,
     now(), CASE WHEN p_completed THEN now() ELSE null END)
  ON CONFLICT (user_id, game_id) DO UPDATE SET
    score            = EXCLUDED.score,
    current_question = EXCLUDED.current_question,
    completed        = EXCLUDED.completed,
    last_active_at   = now(),
    completed_at     = CASE WHEN EXCLUDED.completed THEN now()
                            ELSE public.game_sessions.completed_at END;

  -- Si complété → ajouter points dans l'historique
  IF p_completed THEN
    PERFORM public.add_points(
      p_user_id,
      p_score,
      p_game_id,
      'Mini-jeu terminé'
    ); 
  END IF;
END;
$$;

-- 5. Données de démonstration pour chaque type de jeu
DELETE FROM public.questions WHERE game_id IN (SELECT id FROM public.games);
DELETE FROM public.games;

-- QUIZ
INSERT INTO public.games (title, description, points_reward, is_active, game_type) VALUES
('Quiz Général', 'Testez vos connaissances générales !', 100, false, 'quiz');

WITH g AS (SELECT id FROM public.games WHERE game_type='quiz' LIMIT 1)
INSERT INTO public.questions (game_id, position, question, options, answer) VALUES
((SELECT id FROM g), 0, 'Quelle est la capitale de la France ?',
 '["Berlin","Madrid","Paris","Rome"]', '2'),
((SELECT id FROM g), 1, 'Combien font 7 × 8 ?',
 '["54","56","64","48"]', '1'),
((SELECT id FROM g), 2, 'Quel océan est le plus grand ?',
 '["Atlantique","Indien","Arctique","Pacifique"]', '3'),
((SELECT id FROM g), 3, 'Quel est le plus petit pays du monde ?',
 '["Monaco","San Marin","Vatican","Liechtenstein"]', '2'),
((SELECT id FROM g), 4, 'En quelle année a eu lieu la Révolution française ?',
 '["1789","1799","1776","1812"]', '0');

-- INTRUS
INSERT INTO public.games (title, description, points_reward, is_active, game_type) VALUES
('Trouve l''Intrus', 'Trouvez le mot qui ne va pas avec les autres !', 80, false, 'intrus');

WITH g AS (SELECT id FROM public.games WHERE game_type='intrus' LIMIT 1)
INSERT INTO public.questions (game_id, position, question, options, answer) VALUES
((SELECT id FROM g), 0, 'Quel mot est l''intrus ?',
 '["Chien","Chat","Serpent","Lapin"]', '2'),
((SELECT id FROM g), 1, 'Quel mot est l''intrus ?',
 '["Rouge","Bleu","Chaud","Vert"]', '2'),
((SELECT id FROM g), 2, 'Quel mot est l''intrus ?',
 '["Paris","Lyon","Marseille","Belgique"]', '3'),
((SELECT id FROM g), 3, 'Quel mot est l''intrus ?',
 '["Piano","Guitare","Violon","Pinceau"]', '3'),
((SELECT id FROM g), 4, 'Quel mot est l''intrus ?',
 '["Pomme","Cerise","Carotte","Poire"]', '2');

-- TAP CHALLENGE
INSERT INTO public.games (title, description, points_reward, is_active, game_type) VALUES
('Tap Challenge', 'Appuyez aussi vite que possible sur le bouton !', 120, false, 'tap_challenge');

-- VRAI / FAUX
INSERT INTO public.games (title, description, points_reward, is_active, game_type) VALUES
('Vrai ou Faux ?', 'Une courte histoire : vraie ou inventée ?', 70, false, 'vrai_faux');

WITH g AS (SELECT id FROM public.games WHERE game_type='vrai_faux' LIMIT 1)
INSERT INTO public.questions (game_id, position, question, options, answer) VALUES
((SELECT id FROM g), 0, 'La Grande Muraille de Chine est visible depuis l''espace à l''œil nu.',
 '["Vrai","Faux"]', '1'),
((SELECT id FROM g), 1, 'Les dauphins dorment avec un œil ouvert.',
 '["Vrai","Faux"]', '0'),
((SELECT id FROM g), 2, 'Le cœur humain bat environ 10 000 fois par jour.',
 '["Vrai","Faux"]', '1'),
((SELECT id FROM g), 3, 'Les araignées ont 8 pattes.',
 '["Vrai","Faux"]', '0'),
((SELECT id FROM g), 4, 'L''eau bout à 90°C au niveau de la mer.',
 '["Vrai","Faux"]', '1');

-- ENQUETE
INSERT INTO public.games (title, description, points_reward, is_active, game_type) VALUES
('L''Enquête', 'Lisez la situation et trouvez le coupable !', 150, false, 'enquete');

WITH g AS (SELECT id FROM public.games WHERE game_type='enquete' LIMIT 1)
INSERT INTO public.questions (game_id, position, question, options, answer, extra) VALUES
((SELECT id FROM g), 0,
 'Un tableau a disparu du musée. La caméra était éteinte. Qui est le coupable ?',
 '["Le gardien qui était en pause","Le conservateur qui avait les clés","Le visiteur pressé","Le technicien qui a éteint la caméra"]',
 '3',
 '{"story":"Le technicien a éteint la caméra juste avant la disparition. Il avait accès à toutes les pièces."}'::jsonb
),
((SELECT id FROM g), 1,
 'Le gâteau d''anniversaire a disparu de la cuisine. Qui est le coupable ?',
 '["La maman qui était au jardin","Le papa qui regardait la télé","Le petit frère avec du chocolat sur les mains","La sœur qui était dehors"]',
 '2',
 '{"story":"Tout le monde avait un alibi sauf celui qui avait les mains chocolatées."}'::jsonb
);

-- PUZZLE
INSERT INTO public.games (title, description, points_reward, is_active, game_type) VALUES
('Puzzle Secret', 'Reconstituez la phrase dans le bon ordre !', 90, false, 'puzzle');

WITH g AS (SELECT id FROM public.games WHERE game_type='puzzle' LIMIT 1)
INSERT INTO public.questions (game_id, position, question, options, answer, extra) VALUES
((SELECT id FROM g), 0, 'Reconstituez la phrase',
 '["est","La","belle","vie"]', 'La vie est belle',
 '{"sentence":"La vie est belle"}'::jsonb),
((SELECT id FROM g), 1, 'Reconstituez la phrase',
 '["les","J''aime","chocolats","manger"]', 'J''aime manger les chocolats',
 '{"sentence":"J''aime manger les chocolats"}'::jsonb),
((SELECT id FROM g), 2, 'Reconstituez la phrase',
 '["tôt","se","lève","Il"]', 'Il se lève tôt',
 '{"sentence":"Il se lève tôt"}'::jsonb);

-- ASSOCIATION
INSERT INTO public.games (title, description, points_reward, is_active, game_type) VALUES
('Association Rapide', 'Associez le mot au bon lien !', 80, false, 'association');

WITH g AS (SELECT id FROM public.games WHERE game_type='association' LIMIT 1)
INSERT INTO public.questions (game_id, position, question, options, answer) VALUES
((SELECT id FROM g), 0, 'Médecin →', '["Tribunal","Hôpital","École","Stade"]', '1'),
((SELECT id FROM g), 1, 'Avocat →', '["Hôpital","Cuisine","Tribunal","Forêt"]', '2'),
((SELECT id FROM g), 2, 'Chef cuisinier →', '["Garage","Cuisine","Salle de sport","Bureau"]', '1'),
((SELECT id FROM g), 3, 'Pilote →', '["Mer","Avion","Train","Bus"]', '1'),
((SELECT id FROM g), 4, 'Pompier →', '["Caserne","Tribunal","École","Bibliothèque"]', '0');

-- MÉMOIRE
INSERT INTO public.games (title, description, points_reward, is_active, game_type) VALUES
('Mémoire Inversée', 'Quel mot a disparu de la liste ?', 110, false, 'memoire');

WITH g AS (SELECT id FROM public.games WHERE game_type='memoire' LIMIT 1)
INSERT INTO public.questions (game_id, position, question, options, answer, extra) VALUES
((SELECT id FROM g), 0, 'Quel mot a disparu ?',
 '["Soleil","Lune","Étoile","Nuage"]', '2',
 '{"words":["Soleil","Lune","Étoile","Nuage"],"missing":"Étoile","show_without":["Soleil","Lune","Nuage"]}'::jsonb),
((SELECT id FROM g), 1, 'Quel mot a disparu ?',
 '["Chat","Chien","Lapin","Oiseau"]', '3',
 '{"words":["Chat","Chien","Lapin","Oiseau"],"missing":"Oiseau","show_without":["Chat","Chien","Lapin"]}'::jsonb),
((SELECT id FROM g), 2, 'Quel mot a disparu ?',
 '["Pomme","Banane","Cerise","Mangue"]', '1',
 '{"words":["Pomme","Banane","Cerise","Mangue"],"missing":"Banane","show_without":["Pomme","Cerise","Mangue"]}'::jsonb);

-- CALCUL
INSERT INTO public.games (title, description, points_reward, is_active, game_type) VALUES
('Calcul Rapide', 'Résolvez les calculs le plus vite possible !', 130, false, 'calcul');

WITH g AS (SELECT id FROM public.games WHERE game_type='calcul' LIMIT 1)
INSERT INTO public.questions (game_id, position, question, options, answer, extra) VALUES
((SELECT id FROM g), 0, '12 + 8 = ?', '["18","20","22","19"]', '1', '{"max_seconds":10}'::jsonb),
((SELECT id FROM g), 1, '7 × 6 = ?', '["42","36","48","40"]', '0', '{"max_seconds":10}'::jsonb),
((SELECT id FROM g), 2, '100 - 37 = ?', '["63","73","57","67"]', '0', '{"max_seconds":12}'::jsonb),
((SELECT id FROM g), 3, '9 × 9 = ?', '["72","81","90","63"]', '1', '{"max_seconds":8}'::jsonb),
((SELECT id FROM g), 4, '144 ÷ 12 = ?', '["14","11","12","13"]', '2', '{"max_seconds":12}'::jsonb);