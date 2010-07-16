PRAGMA foreign_keys=ON;

CREATE TABLE pub (
       pub_id integer not null primary key,
       title text,
       authors text
);

CREATE TABLE cv (
       cv_id integer not null primary key,
       name text not null,
       definition text
       );

CREATE TABLE cvterm (
       cvterm_id integer not null primary key,
       cv_id int not null references cv (cv_id),
       name varchar(1024) not null,
       definition text,
       dbxref_id int not null references dbxref (dbxref_id),
       is_obsolete int not null default 0,
       is_relationshiptype int not null default 0
     );
CREATE INDEX cvterm_idx1 ON cvterm (cv_id);
CREATE INDEX cvterm_idx2 ON cvterm (name);
CREATE INDEX cvterm_idx3 ON cvterm (dbxref_id);

CREATE TABLE pubstatus (
       pubstatus_id integer NOT NULL PRIMARY KEY,
       pub_id integer NOT NULL REFERENCES pub (pub_id),
       status integer NOT NULL REFERENCES cvterm (cvterm_id)
);

CREATE TABLE person (
       person_id integer NOT NULL PRIMARY KEY,
       shortname text,
       longname text NOT NULL,
       networkaddress text NOT NULL UNIQUE,
       role text NOT NULL,
       password text
);

CREATE TABLE curs (
       curs_id integer NOT NULL PRIMARY KEY,
       community_curator integer NOT NULL REFERENCES person (person_id)
);

CREATE TABLE sessions (
       id   text PRIMARY KEY,
       session_data text,
       expires      integer
);
