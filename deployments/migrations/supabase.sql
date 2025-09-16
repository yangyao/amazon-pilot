-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.competitor_analysis_groups (
                                                   id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                   user_id uuid NOT NULL,
                                                   name character varying NOT NULL,
                                                   description text,
                                                   main_product_id uuid NOT NULL,
                                                   analysis_metrics jsonb DEFAULT '["price", "bsr", "rating", "features"]'::jsonb,
                                                   is_active boolean DEFAULT true,
                                                   created_at timestamp with time zone DEFAULT now(),
                                                   updated_at timestamp with time zone DEFAULT now(),
                                                   last_analysis_at timestamp with time zone,
                                                   next_analysis_at timestamp with time zone,
                                                   CONSTRAINT competitor_analysis_groups_pkey PRIMARY KEY (id),
                                                   CONSTRAINT competitor_analysis_groups_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
                                                   CONSTRAINT competitor_analysis_groups_main_product_id_fkey FOREIGN KEY (main_product_id) REFERENCES public.products(id)
);
CREATE TABLE public.competitor_analysis_results (
                                                    id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                    analysis_group_id uuid NOT NULL,
                                                    analysis_data jsonb,
                                                    insights jsonb,
                                                    recommendations jsonb,
                                                    status character varying DEFAULT 'pending'::character varying CHECK (status::text = ANY (ARRAY['pending'::character varying, 'queued'::character varying, 'processing'::character varying, 'completed'::character varying, 'failed'::character varying]::text[])),
                                                    started_at timestamp with time zone DEFAULT now(),
                                                    completed_at timestamp with time zone,
                                                    error_message text,
                                                    task_id character varying,
                                                    queue_id character varying,
                                                    CONSTRAINT competitor_analysis_results_pkey PRIMARY KEY (id),
                                                    CONSTRAINT competitor_analysis_results_analysis_group_id_fkey FOREIGN KEY (analysis_group_id) REFERENCES public.competitor_analysis_groups(id)
);
CREATE TABLE public.competitor_products (
                                            id uuid NOT NULL DEFAULT gen_random_uuid(),
                                            analysis_group_id uuid NOT NULL,
                                            product_id uuid NOT NULL,
                                            added_at timestamp with time zone DEFAULT now(),
                                            CONSTRAINT competitor_products_pkey PRIMARY KEY (id),
                                            CONSTRAINT competitor_products_analysis_group_id_fkey FOREIGN KEY (analysis_group_id) REFERENCES public.competitor_analysis_groups(id),
                                            CONSTRAINT competitor_products_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.optimization_analyses (
                                              id uuid NOT NULL DEFAULT gen_random_uuid(),
                                              user_id uuid NOT NULL,
                                              product_id uuid NOT NULL,
                                              analysis_type character varying DEFAULT 'comprehensive'::character varying,
                                              focus_areas jsonb DEFAULT '["title", "pricing", "description", "images", "keywords"]'::jsonb,
                                              status character varying DEFAULT 'pending'::character varying,
                                              overall_score integer,
                                              started_at timestamp with time zone DEFAULT now(),
                                              completed_at timestamp with time zone,
                                              CONSTRAINT optimization_analyses_pkey PRIMARY KEY (id),
                                              CONSTRAINT optimization_analyses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
                                              CONSTRAINT optimization_analyses_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.optimization_suggestions (
                                                 id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                 analysis_id uuid NOT NULL,
                                                 category character varying NOT NULL,
                                                 priority character varying NOT NULL,
                                                 impact_score integer NOT NULL,
                                                 title character varying NOT NULL,
                                                 description text NOT NULL,
                                                 action_items jsonb,
                                                 created_at timestamp with time zone DEFAULT now(),
                                                 CONSTRAINT optimization_suggestions_pkey PRIMARY KEY (id),
                                                 CONSTRAINT optimization_suggestions_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES public.optimization_analyses(id)
);
CREATE TABLE public.product_anomaly_events (
                                               id uuid NOT NULL DEFAULT gen_random_uuid(),
                                               product_id uuid NOT NULL,
                                               asin character varying NOT NULL,
                                               event_type character varying NOT NULL,
                                               old_value numeric,
                                               new_value numeric,
                                               change_percentage numeric,
                                               threshold numeric,
                                               severity character varying NOT NULL DEFAULT 'info'::character varying,
                                               metadata jsonb,
                                               processed boolean DEFAULT false,
                                               processed_at timestamp with time zone,
                                               created_at timestamp with time zone NOT NULL DEFAULT now(),
                                               CONSTRAINT product_anomaly_events_pkey PRIMARY KEY (id),
                                               CONSTRAINT product_anomaly_events_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history (
                                               id uuid NOT NULL DEFAULT gen_random_uuid(),
                                               product_id uuid NOT NULL,
                                               winner_seller character varying,
                                               winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2025_08 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2025_08_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2025_09 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2025_09_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2025_10 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2025_10_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2025_11 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2025_11_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2025_12 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2025_12_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2026_01 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2026_01_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2026_02 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2026_02_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2026_03 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2026_03_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2026_04 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2026_04_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2026_05 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2026_05_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2026_06 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2026_06_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2026_07 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2026_07_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_buybox_history_2026_08 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying,
                                                       winner_price numeric CHECK (winner_price IS NULL OR winner_price >= 0::numeric),
  currency character varying NOT NULL DEFAULT 'USD'::character varying,
  is_prime boolean DEFAULT false,
  is_fba boolean DEFAULT false,
  shipping_info text,
  availability_text character varying,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_buybox_history_2026_08_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history (
                                              id uuid NOT NULL DEFAULT gen_random_uuid(),
                                              product_id uuid NOT NULL,
                                              price numeric NOT NULL,
                                              currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                              buy_box_price numeric,
                                              is_on_sale boolean DEFAULT false,
                                              discount_percentage numeric,
                                              recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                              data_source character varying DEFAULT 'apify'::character varying,
                                              CONSTRAINT product_price_history_pkey PRIMARY KEY (id, recorded_at),
                                              CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2025_08 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2025_08_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2025_09 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2025_09_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2025_10 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2025_10_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2025_11 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2025_11_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2025_12 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2025_12_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2026_01 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2026_01_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2026_02 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2026_02_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2026_03 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2026_03_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2026_04 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2026_04_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2026_05 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2026_05_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2026_06 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2026_06_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2026_07 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2026_07_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_price_history_2026_08 (
                                                      id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                      product_id uuid NOT NULL,
                                                      price numeric NOT NULL,
                                                      currency character varying NOT NULL DEFAULT 'USD'::character varying,
                                                      buy_box_price numeric,
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric,
                                                      recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                      data_source character varying DEFAULT 'apify'::character varying,
                                                      CONSTRAINT product_price_history_2026_08_pkey PRIMARY KEY (id, recorded_at),
                                                      CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history (
                                                id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                product_id uuid NOT NULL,
                                                category character varying NOT NULL,
                                                bsr_rank integer,
                                                bsr_category character varying,
                                                rating numeric,
                                                review_count integer DEFAULT 0,
                                                recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                data_source character varying DEFAULT 'apify'::character varying,
                                                CONSTRAINT product_ranking_history_pkey PRIMARY KEY (id, recorded_at),
                                                CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2025_08 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2025_08_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2025_09 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2025_09_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2025_10 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2025_10_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2025_11 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2025_11_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2025_12 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2025_12_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2026_01 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2026_01_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2026_02 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2026_02_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2026_03 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2026_03_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2026_04 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2026_04_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2026_05 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2026_05_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2026_06 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2026_06_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2026_07 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2026_07_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_ranking_history_2026_08 (
                                                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                        product_id uuid NOT NULL,
                                                        category character varying NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying,
                                                        rating numeric,
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone NOT NULL DEFAULT now(),
                                                        data_source character varying DEFAULT 'apify'::character varying,
                                                        CONSTRAINT product_ranking_history_2026_08_pkey PRIMARY KEY (id, recorded_at),
                                                        CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history (
                                               id uuid NOT NULL DEFAULT gen_random_uuid(),
                                               product_id uuid NOT NULL,
                                               review_count integer DEFAULT 0,
                                               average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2025_08 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2025_08_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2025_09 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2025_09_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2025_10 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2025_10_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2025_11 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2025_11_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2025_12 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2025_12_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2026_01 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2026_01_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2026_02 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2026_02_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2026_03 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2026_03_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2026_04 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2026_04_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2026_05 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2026_05_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2026_06 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2026_06_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2026_07 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2026_07_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.product_review_history_2026_08 (
                                                       id uuid NOT NULL DEFAULT gen_random_uuid(),
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric CHECK (average_rating IS NULL OR average_rating >= 0::numeric AND average_rating <= 5::numeric),
  five_star_count integer DEFAULT 0,
  four_star_count integer DEFAULT 0,
  three_star_count integer DEFAULT 0,
  two_star_count integer DEFAULT 0,
  one_star_count integer DEFAULT 0,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  data_source character varying DEFAULT 'apify'::character varying,
  CONSTRAINT product_review_history_2026_08_pkey PRIMARY KEY (id, recorded_at),
  CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.products (
                                 id uuid NOT NULL DEFAULT gen_random_uuid(),
                                 asin character varying NOT NULL UNIQUE CHECK (length(asin::text) = 10),
                                 title text,
                                 brand character varying,
                                 category character varying,
                                 subcategory character varying,
                                 description text,
                                 bullet_points jsonb,
                                 images jsonb,
                                 dimensions jsonb,
                                 weight numeric,
                                 manufacturer character varying,
                                 model_number character varying,
                                 upc character varying,
                                 ean character varying,
                                 first_seen_at timestamp with time zone DEFAULT now(),
                                 last_updated_at timestamp with time zone DEFAULT now(),
                                 data_source character varying DEFAULT 'apify'::character varying,
                                 bsr integer,
                                 bsr_category character varying,
                                 rating numeric,
                                 review_count integer DEFAULT 0,
                                 current_price numeric,
                                 buy_box_price numeric,
                                 currency character varying DEFAULT 'USD'::character varying,
                                 is_on_sale boolean DEFAULT false,
                                 discount_percentage numeric,
                                 is_available boolean DEFAULT true,
                                 availability_text character varying,
                                 seller_name character varying,
                                 is_prime boolean DEFAULT false,
                                 is_fba boolean DEFAULT false,
                                 url text,
                                 image_url text,
                                 last_updated timestamp with time zone DEFAULT now(),
                                 CONSTRAINT products_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tracked_products (
                                         id uuid NOT NULL DEFAULT gen_random_uuid(),
                                         user_id uuid NOT NULL,
                                         product_id uuid NOT NULL,
                                         alias character varying,
                                         is_active boolean DEFAULT true,
                                         tracking_frequency character varying DEFAULT 'daily'::character varying CHECK (tracking_frequency::text = ANY (ARRAY['hourly'::character varying, 'daily'::character varying, 'weekly'::character varying]::text[])),
                                         price_change_threshold numeric DEFAULT 10.0 CHECK (price_change_threshold >= 0::numeric AND price_change_threshold <= 100::numeric),
  bsr_change_threshold numeric DEFAULT 30.0 CHECK (bsr_change_threshold >= 0::numeric AND bsr_change_threshold <= 100::numeric),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  last_checked_at timestamp with time zone,
  next_check_at timestamp with time zone,
  CONSTRAINT tracked_products_pkey PRIMARY KEY (id),
  CONSTRAINT tracked_products_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT tracked_products_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.users (
                              id uuid NOT NULL DEFAULT gen_random_uuid(),
                              email character varying NOT NULL UNIQUE,
                              password_hash character varying NOT NULL,
                              company_name character varying,
                              plan_type character varying NOT NULL DEFAULT 'basic'::character varying,
                              is_active boolean DEFAULT true,
                              email_verified boolean DEFAULT false,
                              created_at timestamp with time zone DEFAULT now(),
                              updated_at timestamp with time zone DEFAULT now(),
                              last_login_at timestamp with time zone,
                              CONSTRAINT users_pkey PRIMARY KEY (id)
);