-- Charger manufacturer rule (shared with Flutter + web):
-- Name starts with KOS (case-insensitive) → Kostad; all others → Siemens.

UPDATE public.assets
SET "manufacturer" = CASE
  WHEN upper(trim(name)) LIKE 'KOS%' THEN 'Kostad'
  ELSE 'Siemens'
END
WHERE name IS NOT NULL AND trim(name) <> '';

CREATE OR REPLACE FUNCTION public.set_asset_manufacturer_from_name()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.name IS NOT NULL AND trim(NEW.name) <> '' THEN
    IF upper(trim(NEW.name)) LIKE 'KOS%' THEN
      NEW.manufacturer := 'Kostad';
    ELSE
      NEW.manufacturer := 'Siemens';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS assets_set_manufacturer_from_name ON public.assets;

CREATE TRIGGER assets_set_manufacturer_from_name
  BEFORE INSERT OR UPDATE OF name ON public.assets
  FOR EACH ROW
  EXECUTE FUNCTION public.set_asset_manufacturer_from_name();
