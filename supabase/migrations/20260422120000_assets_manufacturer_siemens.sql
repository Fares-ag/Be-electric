-- Set manufacturer to Siemens for all chargers (public.assets)
UPDATE public.assets
SET "manufacturer" = 'Siemens'
WHERE "manufacturer" IS DISTINCT FROM 'Siemens';
