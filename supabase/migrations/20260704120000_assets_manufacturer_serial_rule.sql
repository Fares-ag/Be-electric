-- Charger manufacturer rule (shared with Flutter + web):
-- Name starts with KOS → Kostad; otherwise Siemens only when serialNumber starts with KOS.

UPDATE public.assets
SET "manufacturer" = CASE
  WHEN upper(trim(name)) LIKE 'KOS%' THEN 'Kostad'
  WHEN "serialNumber" IS NOT NULL
    AND trim("serialNumber") <> ''
    AND upper(trim("serialNumber")) LIKE 'KOS%' THEN 'Siemens'
  ELSE NULL
END
WHERE name IS NOT NULL AND trim(name) <> '';

CREATE OR REPLACE FUNCTION public.set_asset_manufacturer_from_name()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.name IS NOT NULL AND trim(NEW.name) <> '' THEN
    IF upper(trim(NEW.name)) LIKE 'KOS%' THEN
      NEW.manufacturer := 'Kostad';
    ELSIF NEW."serialNumber" IS NOT NULL
      AND trim(NEW."serialNumber") <> ''
      AND upper(trim(NEW."serialNumber")) LIKE 'KOS%' THEN
      NEW.manufacturer := 'Siemens';
    ELSE
      NEW.manufacturer := NULL;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS assets_set_manufacturer_from_name ON public.assets;

CREATE TRIGGER assets_set_manufacturer_from_name
  BEFORE INSERT OR UPDATE OF name, "serialNumber" ON public.assets
  FOR EACH ROW
  EXECUTE FUNCTION public.set_asset_manufacturer_from_name();

NOTIFY pgrst, 'reload schema';
