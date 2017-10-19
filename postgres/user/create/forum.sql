BEGIN;

SET SESSION AUTHORIZATION 'v';

CREATE SCHEMA forum;
SET search_path TO forum, public;

---------------------------------
CREATE ROLE v_anonymous;
GRANT v_anonymous TO v;
COMMENT ON ROLE v_anonymous IS 'Права незарегистрированного пользователя';

CREATE ROLE v_user;
GRANT v_user TO v;
COMMENT ON ROLE v_user IS 'Права рядового пользователя';

CREATE ROLE v_moderator;
GRANT v_moderator TO v;
COMMENT ON ROLE v_moderator IS 'Права модератора';

CREATE ROLE v_administrator;
GRANT v_administrator TO v;
COMMENT ON ROLE v_administrator IS 'Права администратора';

---------------------------------
CREATE TYPE role AS ENUM (
    'user',
    'moderator',
    'administrator'
);

COMMENT ON TYPE role IS 'Возможные роли зарегистрированного (!) пользователя форума';

---------------------------------
CREATE TABLE person (
    id SERIAL PRIMARY KEY, 
    name VARCHAR(100),
    about TEXT
);

COMMENT ON TABLE person IS 'Пользователь форума';
COMMENT ON COLUMN person.id IS 'Первичный ключ пользователя';
COMMENT ON COLUMN person.name IS 'Имя пользователя';
COMMENT ON COLUMN person.about IS 'Пользователь о себе';

---------------------------------
CREATE TABLE account (
    id SERIAL PRIMARY KEY,
    person_id INTEGER REFERENCES person(id),
    login VARCHAR(20) NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role role NOT NULL DEFAULT 'user'
);

COMMENT ON TABLE account IS 'Аккаунт пользователя форума';
COMMENT ON COLUMN account.id IS 'Первичный ключ аккаунта';
COMMENT ON COLUMN account.person_id IS 'Первичный ключ пользователя аккаунта';
COMMENT ON COLUMN account.login IS 'Логин аккаунта';
COMMENT ON COLUMN account.email IS 'Адрес электронной почты аккаунта';
COMMENT ON COLUMN account.password_hash IS 'Хэш пароля аккаунта';

---------------------------------
CREATE TABLE post (
    id SERIAL PRIMARY KEY,
    person_id INTEGER REFERENCES person(id),
    title VARCHAR(200),
    body TEXT,
    created_at TIMESTAMP DEFAULT now(),
    edited_at TIMESTAMP DEFAULT now(),
    post_holder_id INTEGER REFERENCES post(id)
);

COMMENT ON TABLE post IS 'Пост форума';
COMMENT ON COLUMN post.id IS 'Первичный ключ поста';
COMMENT ON COLUMN post.title IS 'Заголовок поста';
COMMENT ON COLUMN post.body IS 'Содержание поста';
COMMENT ON COLUMN post.person_id IS 'Уникальный идентификатор автора поста';
COMMENT ON COLUMN post.created_at IS 'Время создания поста';
COMMENT ON COLUMN post.edited_at IS 'Время последнего изменения поста';
COMMENT ON COLUMN post.post_holder_id IS 'Уникальный идентификатор поста, комментарием к которому является данный пост';

---------------------------------
CREATE FUNCTION set_edited_at() RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at := now();
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_edited_at() IS 'Установка текущего времени при обновлении таблицы.';

CREATE TRIGGER post_edited_at before UPDATE
  ON post
  FOR EACH ROW
  EXECUTE PROCEDURE set_edited_at();

---------------------------------
CREATE TABLE post_like (
    post_id INTEGER REFERENCES post(id),
    person_id INTEGER REFERENCES person(id),
    status BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (person_id, post_id)
);

COMMENT ON TABLE post_like IS 'Лайки';
COMMENT ON COLUMN post_like.post_id IS 'УИД поста';
COMMENT ON COLUMN post_like.person_id IS 'УИД пользователя форума';
COMMENT ON COLUMN post_like.status IS 'Если ИСТИНА, то это лайк, иначе - дизлайк';

---------------------------------
CREATE TABLE tag (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

COMMENT ON TABLE tag IS 'Возможные тэги';
COMMENT ON COLUMN tag.id IS 'УИД тэга';
COMMENT ON COLUMN tag.name IS 'Имя тэга';

---------------------------------
CREATE TABLE post_tag (
    post_id INTEGER REFERENCES post(id),
    tag_id INTEGER REFERENCES tag(id),
    PRIMARY KEY (post_id, tag_id)
);

COMMENT ON TABLE post_tag IS 'Возможные тэги';
COMMENT ON COLUMN post_tag.post_id IS 'УИД поста';
COMMENT ON COLUMN post_tag.tag_id IS 'УИД тэга для поста';

---------------------------------
CREATE TYPE jwt_token AS (
  role TEXT,
  person_id INTEGER
);

COMMENT ON TYPE jwt_token IS 'Тип для токена';

---------------------------------
CREATE FUNCTION register(
  name TEXT,
  email TEXT,
  login TEXT,
  password TEXT
) RETURNS person AS $$
DECLARE
  person person;
BEGIN
  INSERT INTO person (name) VALUES (name)
    RETURNING * INTO person;
  INSERT INTO account (person_id, email, login, password_hash) VALUES
    (person.id, email, login, crypt(password, gen_salt('bf')));
  RETURN person;
END;
$$ LANGUAGE plpgsql STRICT SECURITY DEFINER;

COMMENT ON FUNCTION register(TEXT, TEXT, TEXT, TEXT) IS 'Регистрация пользователя.';

---------------------------------
CREATE FUNCTION authenticate(
  email TEXT,
  password TEXT
) RETURNS jwt_token AS $$
DECLARE
  account account;
BEGIN
  SELECT a.* INTO account
  FROM account as a
  where a.email = authenticate.email;

  IF account.password_hash = crypt(password, account.password_hash) THEN
    RETURN (CURRENT_USER::text || '_' || account.role, account.person_id)::jwt_token;
  ELSE
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql STRICT SECURITY DEFINER;

COMMENT ON FUNCTION authenticate(TEXT, TEXT) IS 'Создает JWT - токен, который будет использоваться для идентификации пользователя';

---------------------------------
CREATE FUNCTION encrypt_passwords() RETURNS void AS $$
    DECLARE
        current_account account;
    BEGIN
        FOR current_account IN SELECT * FROM account LOOP
            IF char_length(current_account.password_hash) <> 60 THEN
                UPDATE account SET password_hash = crypt(current_account.password_hash, gen_salt('bf')) WHERE id = current_account.id;
            END IF;
        END LOOP;
    END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION encrypt_passwords() IS 'Шифрует пароли после загрузки аккаунтов из внешнего источника';

---------------------------------
-- Разграничение прав

GRANT usage ON SCHEMA forum TO v_anonymous, v_user, v_moderator, v_administrator;

GRANT SELECT ON TABLE person, post, post_like, tag, post_tag TO v_anonymous, v_user;
GRANT INSERT, UPDATE, DELETE ON TABLE post, post_like, post_tag TO v_user;
GRANT ALL ON TABLE person, post, post_like, tag, post_tag TO v_moderator, v_administrator;

GRANT EXECUTE ON FUNCTION register(TEXT, TEXT, TEXT, TEXT) TO v_anonymous;
GRANT EXECUTE ON FUNCTION authenticate(TEXT, TEXT) TO v_anonymous, v_user, v_moderator, v_administrator;
GRANT EXECUTE ON FUNCTION encrypt_passwords() TO v_administrator;

ALTER TABLE person ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_person ON person FOR SELECT
  USING (TRUE);
CREATE POLICY update_person_as_user ON person FOR UPDATE TO v_user
  USING (id = current_setting('jwt.claims.person_id')::INTEGER);
CREATE POLICY delete_person_as_user ON person FOR DELETE TO v_user
  USING (id = current_setting('jwt.claims.person_id')::INTEGER);

ALTER TABLE post ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_post ON post FOR SELECT
  USING (TRUE);
CREATE POLICY update_post_as_user ON post FOR UPDATE TO v_user
  USING (person_id = current_setting('jwt.claims.person_id')::INTEGER);
CREATE POLICY delete_post_as_user ON post FOR DELETE TO v_user
  USING (person_id = current_setting('jwt.claims.person_id')::INTEGER);

ALTER TABLE post_like ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_post_like ON post_like FOR SELECT
  USING (TRUE);
CREATE POLICY update_post_like_as_user ON post_like FOR UPDATE TO v_user
  USING (person_id = current_setting('jwt.claims.person_id')::INTEGER);
CREATE POLICY delete_post_like_as_user ON post_like FOR DELETE TO v_user
  USING (person_id = current_setting('jwt.claims.person_id')::INTEGER);

ALTER TABLE post_tag ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_post_tag ON post_tag FOR SELECT
  USING (TRUE);
CREATE POLICY update_post_tag_as_user ON post_tag FOR UPDATE TO v_user
  USING (current_setting('jwt.claims.person_id')::INTEGER = (SELECT person_id FROM post WHERE id = post_id));
CREATE POLICY delete_post_tag_as_user ON post_tag FOR DELETE TO v_user
  USING (current_setting('jwt.claims.person_id')::INTEGER = (SELECT person_id FROM post WHERE id = post_id));

COMMIT;