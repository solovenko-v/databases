SET SESSION AUTHORIZATION 'v';
SET search_path TO forum, public;
SET LOCAL ROLE v_user;
SET LOCAL jwt.claims.person_id TO 2;

-- --
-- QUERY
-- --

UPDATE post_tag SET tag_id = 2 WHERE post_id = 1 AND tag_id = 3;