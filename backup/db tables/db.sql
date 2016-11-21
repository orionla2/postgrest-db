CREATE TABLE my_yacht.additional
(
  id serial NOT NULL,
  booking_id integer NOT NULL,
  extras_id integer,
  packages_id integer,
  guests integer NOT NULL,
  amount integer NOT NULL,
  money money,
  CONSTRAINT pk_id_additional PRIMARY KEY (id),
  CONSTRAINT fk_additional_booking FOREIGN KEY (booking_id)
      REFERENCES my_yacht.booking (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_additional_extras FOREIGN KEY (extras_id)
      REFERENCES my_yacht.extras (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_additional_packages FOREIGN KEY (packages_id)
      REFERENCES my_yacht.packages (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.additional
  OWNER TO postgres;

  CREATE TABLE my_yacht.booking
(
  id serial NOT NULL,
  y_id integer NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  user_id integer NOT NULL,
  payment money,
  status integer NOT NULL,
  CONSTRAINT pk_id_booking PRIMARY KEY (id),
  CONSTRAINT fk_booking_user FOREIGN KEY (user_id)
      REFERENCES my_yacht."user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_booking_yacht FOREIGN KEY (y_id)
      REFERENCES my_yacht.yacht (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.booking
  OWNER TO postgres;

  CREATE TABLE my_yacht.devices
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  platform character varying(45) NOT NULL,
  device_id character varying(45) NOT NULL,
  CONSTRAINT pk_id_devices PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.devices
  OWNER TO postgres;

  CREATE TABLE my_yacht.download
(
  id serial NOT NULL,
  tagline character varying(80) NOT NULL,
  filename text NOT NULL,
  CONSTRAINT pk_id_download PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.download
  OWNER TO postgres;

  CREATE TABLE my_yacht.extras
(
  id serial NOT NULL,
  title character varying(45) NOT NULL,
  price money NOT NULL,
  min_charge integer NOT NULL,
  unit character varying(45) NOT NULL,
  terms character varying(255) NOT NULL,
  CONSTRAINT pk_id_extras PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.extras
  OWNER TO postgres;

  CREATE TABLE my_yacht.file
(
  id serial NOT NULL,
  type character varying(45) NOT NULL,
  url text NOT NULL,
  y_id integer NOT NULL,
  CONSTRAINT pk_id_file PRIMARY KEY (id),
  CONSTRAINT fk_file_yacht FOREIGN KEY (y_id)
      REFERENCES my_yacht.yacht (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.file
  OWNER TO postgres;

  CREATE TABLE my_yacht.invoice
(
  id serial NOT NULL,
  booking_id integer NOT NULL,
  invoice_num integer NOT NULL,
  title text NOT NULL,
  amount integer NOT NULL,
  rate money NOT NULL,
  subtotal money NOT NULL,
  total money,
  status boolean,
  invoice_date date NOT NULL,
  CONSTRAINT pk_id_invoice PRIMARY KEY (id),
  CONSTRAINT fk_invoice_booking FOREIGN KEY (booking_id)
      REFERENCES my_yacht.booking (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.invoice
  OWNER TO postgres;

CREATE TABLE my_yacht.packages
(
  id serial NOT NULL,
  title character varying(45) NOT NULL,
  price money NOT NULL,
  min_charge integer NOT NULL,
  description character varying(255),
  CONSTRAINT pk_id_packages PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.packages
  OWNER TO postgres;

  CREATE TABLE my_yacht.payment
(
  id serial NOT NULL,
  invoice_id integer NOT NULL,
  type character varying(45) NOT NULL,
  user_id integer NOT NULL,
  value money,
  CONSTRAINT pk_id_payment PRIMARY KEY (id),
  CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id)
      REFERENCES my_yacht.invoice (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_payment_user FOREIGN KEY (user_id)
      REFERENCES my_yacht."user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.payment
  OWNER TO postgres;

  CREATE TABLE my_yacht."user"
(
  id serial NOT NULL,
  firstname character varying(80),
  lastname character varying(80) NOT NULL,
  email character varying(255) NOT NULL,
  mobile character varying(16) NOT NULL,
  password character varying(45) NOT NULL,
  "group" character varying(45) NOT NULL,
  discount numeric(2,2) DEFAULT 0,
  CONSTRAINT pk_id_yacht PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht."user"
  OWNER TO postgres;

CREATE TABLE my_yacht.yacht
(
  id serial NOT NULL,
  title character varying(255) NOT NULL,
  content text NOT NULL,
  readmore text NOT NULL,
  CONSTRAINT pr_id_yacht PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.yacht
  OWNER TO postgres;

-- USER MANAGMENT SECTION --

create extension if not exists pgcrypto;

-- We put things inside the basic_auth schema to hide
-- them from public view. Certain public procs/views will
-- refer to helpers and tables inside.
create schema if not exists auth;

create table if not exists
auth.users (
  email    text primary key check ( email ~* '^.+@.+\..+$' ),
  pass     text not null check (length(pass) < 512),
  role     name not null check (length(role) < 512),
  verified boolean not null default false
  -- If you like add more columns, or a json column
);

create or replace function
auth.check_role_exists() returns trigger
  language plpgsql
  as $$
begin
  if not exists (select 1 from pg_roles as r where r.rolname = new.role) then
    raise foreign_key_violation using message =
      'unknown database role: ' || new.role;
    return null;
  end if;
  return new;
end
$$;

drop trigger if exists ensure_user_role_exists on auth.users;
create constraint trigger ensure_user_role_exists
  after insert or update on auth.users
  for each row
  execute procedure auth.check_role_exists();

create or replace function
auth.encrypt_pass() returns trigger
  language plpgsql
  as $$
begin
  if tg_op = 'INSERT' or new.pass <> old.pass then
    new.pass = crypt(new.pass, gen_salt('bf'));
  end if;
  return new;
end
$$;

drop trigger if exists encrypt_pass on auth.users;
create trigger encrypt_pass
  before insert or update on auth.users
  for each row
  execute procedure auth.encrypt_pass();


create or replace function
auth.user_role(email text, pass text) returns name
  language plpgsql
  as $$
begin
  return (
  select role from auth.users
   where users.email = user_role.email
     and users.pass = crypt(user_role.pass, users.pass)
  );
end;
$$;


drop type if exists token_type_enum cascade;
create type token_type_enum as enum ('validation', 'reset');

create table if not exists
auth.tokens (
  token       uuid primary key,
  token_type  token_type_enum not null,
  email       text not null references auth.users (email)
                on delete cascade on update cascade,
  created_at  timestamptz not null default current_date
);

create or replace function
my_yacht.request_password_reset(email text) returns void
  language plpgsql
  as $$
declare
  tok uuid;
begin
  delete from auth.tokens
   where token_type = 'reset'
     and tokens.email = request_password_reset.email;

  select gen_random_uuid() into tok;
  insert into auth.tokens (token, token_type, email)
         values (tok, 'reset', request_password_reset.email);
  perform pg_notify('reset',
    json_build_object(
      'email', request_password_reset.email,
      'token', tok,
      'token_type', 'reset'
    )::text
  );
end;
$$;

create or replace function
my_yacht.reset_password(email text, token uuid, pass text)
  returns void
  language plpgsql
  as $$
declare
  tok uuid;
begin
  if exists(select 1 from auth.tokens
             where tokens.email = reset_password.email
               and tokens.token = reset_password.token
               and token_type = 'reset') then
    update auth.users set pass=reset_password.pass
     where users.email = reset_password.email;

    delete from auth.tokens
     where tokens.email = reset_password.email
       and tokens.token = reset_password.token
       and token_type = 'reset';
  else
    raise invalid_password using message =
      'invalid user or token';
  end if;
  delete from auth.tokens
   where token_type = 'reset'
     and tokens.email = reset_password.email;

  select gen_random_uuid() into tok;
  insert into auth.tokens (token, token_type, email)
         values (tok, 'reset', reset_password.email);
  perform pg_notify('reset',
    json_build_object(
      'email', reset_password.email,
      'token', tok
    )::text
  );
end;
$$;


create or replace function
auth.send_validation() returns trigger
  language plpgsql
  as $$
declare
  tok uuid;
begin
  select gen_random_uuid() into tok;
  insert into auth.tokens (token, token_type, email)
         values (tok, 'validation', new.email);
  perform pg_notify('validate',
    json_build_object(
      'email', new.email,
      'token', tok,
      'token_type', 'validation'
    )::text
  );
  return new;
end
$$;

drop trigger if exists send_validation on auth.users;
create trigger send_validation
  after insert on auth.users
  for each row
  execute procedure auth.send_validation();

create or replace view my_yacht.users as
select actual.role as role,
       '***'::text as pass,
       actual.email as email,
       actual.verified as verified
from auth.users as actual,
     (select rolname
        from pg_authid
       where pg_has_role(current_user, oid, 'member')
     ) as member_of
where actual.role = member_of.rolname;

create or replace function
auth.clearance_for_role(u name) returns void as
$$
declare
  ok boolean;
begin
  select exists (
    select rolname
      from pg_authid
     where pg_has_role(current_user, oid, 'member')
       and rolname = u
  ) into ok;
  if not ok then
    raise invalid_password using message =
      'current user not member of role ' || u;
  end if;
end
$$ LANGUAGE plpgsql;

create or replace function
my_yacht.update_users() returns trigger
language plpgsql
AS $$
begin
  if tg_op = 'INSERT' then
    perform auth.clearance_for_role(new.role);

    insert into auth.users
      (role, pass, email, verified)
    values
      (new.role, new.pass, new.email,
      coalesce(new.verified, true));
    return new;
  elsif tg_op = 'UPDATE' then
    -- no need to check clearance for old.role because
    -- an ineligible row would not have been available to update (http 404)
    perform auth.clearance_for_role(new.role);

    update auth.users set
      email  = new.email,
      role   = new.role,
      pass   = new.pass,
      verified = coalesce(new.verified, old.verified, false)
      where email = old.email;
    return new;
  elsif tg_op = 'DELETE' then
    -- no need to check clearance for old.role (see previous case)

    delete from auth.users
     where auth.email = old.email;
    return null;
  end if;
end
$$;

drop trigger if exists my_yacht.update_users on my_yacht.user;
create trigger my_yacht.update_users
  instead of insert or update or delete on
    my_yacht.users for each row execute procedure my_yacht.update_users();

create or replace function
my_yacht.signup(email text, pass text) returns void
as $$
  insert into auth.users (email, pass, role) values
    (signup.email, signup.pass, 'user_role');
$$ language sql;


drop type if exists auth.jwt_claims cascade;
create type auth.jwt_claims AS (role text, email text, exp integer);

create or replace function
my_yacht.login(email text, pass text) returns auth.jwt_claims
  language plpgsql
  as $$
declare
  _role name;
  _verified boolean;
  _email text;
  result auth.jwt_claims;
begin
  -- check email and password
  select auth.user_role(email, pass) into _role;
  if _role is null then
    raise invalid_password using message = 'invalid user or password';
  end if;
  -- check verified flag whether users
  -- have validated their emails
  _email := email;
  select verified from auth.users as u where u.email=_email limit 1 into _verified;
  if not _verified then
    raise invalid_authorization_specification using message = 'user is not verified';
  end if;
  select _role as role, login.email as email,
         extract(epoch from now())::integer + 60*60 as exp
    into result;
  return result;
end;
$$;

ALTER DATABASE postgres SET postgrest.claims.email TO '';

create or replace function
auth.current_email() returns text
  language plpgsql
  as $$
begin
  return current_setting('postgrest.claims.email');
end;
$$;


create role user_role;
create role manager;
create role authenticator noinherit;
grant user_role to authenticator;
grant manager to authenticator;

grant usage on schema my_yacht, auth to user_role;
grant usage on schema my_yacht, auth to manager;

-- anon can create new logins
grant insert on table auth.users, auth.tokens to user_role;
grant insert on table auth.users, auth.tokens to manager;
grant select on table pg_authid, auth.users to user_role;
grant select on table pg_authid, auth.users to manager;
grant execute on function
  my_yacht.login(text,text),
  my_yacht.request_password_reset(text),
  my_yacht.reset_password(text,uuid,text),
  my_yacht.signup(text, text)
  to manager;
grant execute on function
  my_yacht.login(text,text),
  my_yacht.request_password_reset(text),
  my_yacht.reset_password(text,uuid,text),
  my_yacht.signup(text, text)
  to user_role;
