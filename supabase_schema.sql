-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.homes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL DEFAULT 'Mi Hogar'::text,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  supermarkets ARRAY NOT NULL DEFAULT '{}'::text[],
  CONSTRAINT homes_pkey PRIMARY KEY (id),
  CONSTRAINT homes_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  home_id uuid,
  full_name text,
  avatar_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  sex text CHECK (sex = ANY (ARRAY['male'::text, 'female'::text])),
  birth_date date,
  height_cm numeric,
  weight_kg numeric,
  activity_level text DEFAULT 'moderate'::text CHECK (activity_level = ANY (ARRAY['sedentary'::text, 'light'::text, 'moderate'::text, 'active'::text, 'very_active'::text])),
  goal text DEFAULT 'maintain'::text CHECK (goal = ANY (ARRAY['maintain'::text, 'lose'::text, 'gain'::text])),
  meals_per_day integer DEFAULT 4,
  is_public boolean NOT NULL DEFAULT false,
  meal_split jsonb NOT NULL DEFAULT '{"lunch": 40, "snack": 0, "dinner": 40, "dessert": 0, "breakfast": 20}'::jsonb,
  meals_at_home jsonb,
  cooking_mode text NOT NULL DEFAULT 'daily'::text CHECK (cooking_mode = ANY (ARRAY['daily'::text, 'mealprep'::text])),
  portion_mode text NOT NULL DEFAULT 'practical'::text CHECK (portion_mode = ANY (ARRAY['practical'::text, 'strict'::text])),
  dashboard_prefs jsonb,
  diet text,
  allergies ARRAY NOT NULL DEFAULT '{}'::text[],
  disliked ARRAY NOT NULL DEFAULT '{}'::text[],
  cook_time_pref text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT profiles_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.home_members (
  home_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role text NOT NULL DEFAULT 'member'::text CHECK (role = ANY (ARRAY['owner'::text, 'member'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT home_members_pkey PRIMARY KEY (home_id, user_id),
  CONSTRAINT home_members_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT home_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.subscriptions (
  home_id uuid NOT NULL,
  plan text NOT NULL DEFAULT 'free'::text CHECK (plan = ANY (ARRAY['free'::text, 'pro'::text])),
  ai_monthly_limit integer NOT NULL DEFAULT 20,
  ai_used_this_month integer NOT NULL DEFAULT 0,
  renews_at timestamp with time zone,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  ai_period_start date NOT NULL DEFAULT (date_trunc('month'::text, now()))::date,
  CONSTRAINT subscriptions_pkey PRIMARY KEY (home_id),
  CONSTRAINT subscriptions_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.inventory_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  name text NOT NULL,
  category text NOT NULL DEFAULT 'Despensa'::text CHECK (category = ANY (ARRAY['Despensa'::text, 'Nevera'::text, 'Congelador'::text, 'Especias'::text, 'Bebidas'::text, 'Limpieza'::text, 'Hogar'::text])),
  quantity numeric NOT NULL DEFAULT 1,
  unit text NOT NULL DEFAULT 'unidades'::text,
  expiration_date date,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  kind text NOT NULL DEFAULT 'ingredient'::text CHECK (kind = ANY (ARRAY['ingredient'::text, 'prep'::text, 'dish'::text])),
  recipe_id uuid,
  servings numeric,
  frozen_on date,
  best_before date,
  item_type text NOT NULL DEFAULT 'comida'::text CHECK (item_type = ANY (ARRAY['comida'::text, 'hogar'::text])),
  is_staple boolean NOT NULL DEFAULT false,
  image_url text,
  CONSTRAINT inventory_items_pkey PRIMARY KEY (id),
  CONSTRAINT inventory_items_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT inventory_items_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.recipes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  servings integer NOT NULL DEFAULT 1,
  prep_time_minutes integer,
  calories_per_serving integer,
  protein_grams numeric,
  carbs_grams numeric,
  fat_grams numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  prep_minutes integer,
  cook_minutes integer,
  appliance text DEFAULT 'none'::text CHECK (appliance = ANY (ARRAY['none'::text, 'oven'::text, 'stovetop'::text, 'pot'::text, 'airfryer'::text, 'microwave'::text])),
  meal_type text DEFAULT 'lunch'::text CHECK (meal_type = ANY (ARRAY['breakfast'::text, 'lunch'::text, 'dinner'::text, 'snack'::text])),
  is_favorite boolean NOT NULL DEFAULT false,
  freezable boolean NOT NULL DEFAULT false,
  meal_types ARRAY NOT NULL DEFAULT '{}'::text[],
  instructions text,
  grams_per_serving numeric,
  image_path text,
  components jsonb,
  freezer_days integer,
  video_url text,
  image_url text,
  CONSTRAINT recipes_pkey PRIMARY KEY (id),
  CONSTRAINT recipes_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.tickets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  storage_path text NOT NULL,
  merchant text,
  total_amount numeric,
  purchased_at date,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  store_category text,
  CONSTRAINT tickets_pkey PRIMARY KEY (id),
  CONSTRAINT tickets_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.recipe_ingredients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid NOT NULL,
  home_id uuid NOT NULL,
  name text NOT NULL,
  quantity numeric,
  unit text,
  position integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT recipe_ingredients_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_ingredients_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_ingredients_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  title text NOT NULL,
  notes text,
  points integer NOT NULL DEFAULT 10,
  recurrence text NOT NULL DEFAULT 'once'::text CHECK (recurrence = ANY (ARRAY['once'::text, 'daily'::text, 'weekly'::text, 'custom_interval'::text, 'custom_weekdays'::text])),
  assigned_to uuid,
  due_date date,
  is_done boolean NOT NULL DEFAULT false,
  completed_by uuid,
  completed_at timestamp with time zone,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  interval_count integer,
  interval_unit text CHECK (interval_unit = ANY (ARRAY['day'::text, 'week'::text])),
  weekdays ARRAY,
  due_time time without time zone,
  next_due date,
  last_completed_at timestamp with time zone,
  effort_points integer NOT NULL DEFAULT 10,
  CONSTRAINT tasks_pkey PRIMARY KEY (id),
  CONSTRAINT tasks_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES auth.users(id),
  CONSTRAINT tasks_completed_by_fkey FOREIGN KEY (completed_by) REFERENCES auth.users(id),
  CONSTRAINT tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id)
);
CREATE TABLE public.task_points (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  user_id uuid NOT NULL,
  points integer NOT NULL,
  task_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT task_points_pkey PRIMARY KEY (id),
  CONSTRAINT task_points_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT task_points_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT task_points_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id)
);
CREATE TABLE public.budgets (
  home_id uuid NOT NULL,
  monthly_amount numeric NOT NULL DEFAULT 0,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT budgets_pkey PRIMARY KEY (home_id),
  CONSTRAINT budgets_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.expenses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  amount numeric NOT NULL,
  category text NOT NULL DEFAULT 'Supermercado'::text CHECK (category = ANY (ARRAY['Supermercado'::text, 'Hogar'::text, 'Ocio'::text, 'Otros'::text])),
  store text,
  note text,
  spent_on date NOT NULL DEFAULT (now())::date,
  ticket_path text,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT expenses_pkey PRIMARY KEY (id),
  CONSTRAINT expenses_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT expenses_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id)
);
CREATE TABLE public.ticket_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL,
  home_id uuid NOT NULL,
  raw_name text,
  name text NOT NULL,
  category text,
  quantity numeric DEFAULT 1,
  unit_price numeric,
  total_price numeric,
  position integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT ticket_items_pkey PRIMARY KEY (id),
  CONSTRAINT ticket_items_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id),
  CONSTRAINT ticket_items_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.product_aliases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  raw_name text NOT NULL,
  correct_name text NOT NULL,
  category text,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT product_aliases_pkey PRIMARY KEY (id),
  CONSTRAINT product_aliases_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.meal_plan_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  plan_date date NOT NULL,
  meal_type text NOT NULL CHECK (meal_type = ANY (ARRAY['breakfast'::text, 'lunch'::text, 'dinner'::text, 'snack'::text, 'dessert'::text])),
  recipe_id uuid,
  skipped boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  from_freezer boolean NOT NULL DEFAULT false,
  inventory_item_id uuid,
  servings integer,
  CONSTRAINT meal_plan_entries_pkey PRIMARY KEY (id),
  CONSTRAINT meal_plan_entries_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT meal_plan_entries_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT meal_plan_entries_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id)
);
CREATE TABLE public.meal_plan_feedback (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  recipe_id uuid NOT NULL,
  action text NOT NULL CHECK (action = ANY (ARRAY['accepted'::text, 'rejected'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT meal_plan_feedback_pkey PRIMARY KEY (id),
  CONSTRAINT meal_plan_feedback_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT meal_plan_feedback_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.shopping_list_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  name text NOT NULL,
  quantity numeric,
  unit text,
  checked boolean NOT NULL DEFAULT false,
  source text NOT NULL DEFAULT 'manual'::text CHECK (source = ANY (ARRAY['manual'::text, 'auto'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  image_url text,
  item_type text NOT NULL DEFAULT 'comida'::text,
  category text,
  list_id uuid,
  category_id uuid,
  CONSTRAINT shopping_list_items_pkey PRIMARY KEY (id),
  CONSTRAINT shopping_list_items_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT shopping_list_items_list_id_fkey FOREIGN KEY (list_id) REFERENCES public.shopping_lists(id),
  CONSTRAINT shopping_list_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.shopping_categories(id)
);
CREATE TABLE public.food_log_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  log_date date NOT NULL,
  meal_type text CHECK (meal_type = ANY (ARRAY['breakfast'::text, 'lunch'::text, 'dinner'::text, 'snack'::text, 'dessert'::text])),
  name text NOT NULL,
  calories numeric,
  protein numeric,
  carbs numeric,
  fat numeric,
  source text NOT NULL DEFAULT 'manual'::text CHECK (source = ANY (ARRAY['manual'::text, 'receta'::text, 'foto'::text])),
  recipe_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT food_log_entries_pkey PRIMARY KEY (id),
  CONSTRAINT food_log_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT food_log_entries_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.food_photo_cache (
  home_id uuid NOT NULL,
  name_normalized text NOT NULL,
  url text,
  fetched_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT food_photo_cache_pkey PRIMARY KEY (home_id, name_normalized),
  CONSTRAINT food_photo_cache_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.product_prices (
  home_id uuid NOT NULL,
  name_normalized text NOT NULL,
  display_name text,
  last_unit_price numeric,
  avg_unit_price numeric,
  samples integer NOT NULL DEFAULT 0,
  last_seen timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT product_prices_pkey PRIMARY KEY (home_id, name_normalized),
  CONSTRAINT product_prices_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.rewards (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  cost_points integer NOT NULL DEFAULT 50 CHECK (cost_points >= 0),
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT rewards_pkey PRIMARY KEY (id),
  CONSTRAINT rewards_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT rewards_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id)
);
CREATE TABLE public.reward_redemptions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  reward_id uuid,
  redeemed_by uuid NOT NULL,
  cost_points integer NOT NULL,
  redeemed_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT reward_redemptions_pkey PRIMARY KEY (id),
  CONSTRAINT reward_redemptions_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id),
  CONSTRAINT reward_redemptions_reward_id_fkey FOREIGN KEY (reward_id) REFERENCES public.rewards(id),
  CONSTRAINT reward_redemptions_redeemed_by_fkey FOREIGN KEY (redeemed_by) REFERENCES auth.users(id)
);
CREATE TABLE public.shopping_lists (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  name text NOT NULL,
  color text,
  icon text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT shopping_lists_pkey PRIMARY KEY (id),
  CONSTRAINT shopping_lists_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
CREATE TABLE public.shopping_categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  home_id uuid NOT NULL,
  name text NOT NULL,
  position integer,
  color text,
  icon text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT shopping_categories_pkey PRIMARY KEY (id),
  CONSTRAINT shopping_categories_home_id_fkey FOREIGN KEY (home_id) REFERENCES public.homes(id)
);
