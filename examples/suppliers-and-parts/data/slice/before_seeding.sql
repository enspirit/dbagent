-- A slice seed is applied (`rake db:apply[slice]`), never installed: it carries
-- one supplier out of a database that holds many, and emptying `suppliers`
-- would take the others with it. Which rows it replaces is therefore its own
-- decision, written here, in the order the foreign keys demand. This is what
-- makes applying it twice an install and then an update.
DELETE FROM public.supplies WHERE sid = 'S9';
DELETE FROM suppliers       WHERE sid = 'S9';
