PRAGMA foreign_keys=ON;

CREATE TABLE pub (
       pub_id integer NOT NULL PRIMARY KEY,
       pubmedid text UNIQUE,
       type_id integer NOT NULL REFERENCES cvterm (cvterm_id),
       community_curator integer REFERENCES person (person_id),
       title text,
       abstract text,
       authors text
);

CREATE TABLE cv (
       cv_id integer NOT NULL PRIMARY KEY,
       name text NOT NULL,
       definition text
);

CREATE TABLE db (
    db_id integer NOT NULL PRIMARY KEY,
    name text NOT NULL,
    description text,
    urlprefix text,
    url text
);

CREATE TABLE dbxref (
    dbxref_id integer NOT NULL PRIMARY KEY,
    db_id integer NOT NULL REFERENCES db (db_id),
    accession text NOT NULL,
    version text NOT NULL DEFAULT '',
    description text
);
CREATE INDEX dbxref_idx1 ON dbxref (db_id);
CREATE INDEX dbxref_idx2 ON dbxref (accession);
CREATE INDEX dbxref_idx3 ON dbxref (version);

CREATE TABLE cvterm (
       cvterm_id integer NOT NULL PRIMARY KEY,
       cv_id int NOT NULL references cv (cv_id),
       name text NOT NULL,
       dbxref_id integer NOT NULL REFERENCES dbxref (dbxref_id),
       definition text,
       is_obsolete integer DEFAULT 0 NOT NULL,
       is_relationshiptype integer DEFAULT 0 NOT NULL
);
CREATE INDEX cvterm_idx1 ON cvterm (cv_id);
CREATE INDEX cvterm_idx2 ON cvterm (name);

CREATE TABLE cvtermsynonym (
    cvtermsynonym_id integer NOT NULL PRIMARY KEY,
    cvterm_id integer NOT NULL references cvterm (cvterm_id),
    synonym text NOT NULL,
    type_id integer references cvterm (cvterm_id)
);
CREATE INDEX cvtermsynonym_idx1 ON cvtermsynonym (cvterm_id);

CREATE TABLE cvterm_relationship (
    cvterm_relationship_id integer NOT NULL PRIMARY KEY,
    type_id integer NOT NULL references cvterm (cvterm_id),
    subject_id integer NOT NULL references cvterm (cvterm_id),
    object_id integer NOT NULL references cvterm (cvterm_id)
);
CREATE INDEX cvterm_relationship_idx1 ON cvterm_relationship (type_id);
CREATE INDEX cvterm_relationship_idx2 ON cvterm_relationship (subject_id);
CREATE INDEX cvterm_relationship_idx3 ON cvterm_relationship (object_id);

CREATE TABLE cvtermprop (
    cvtermprop_id integer NOT NULL PRIMARY KEY,
    cvterm_id integer NOT NULL references cvterm (cvterm_id),
    type_id integer NOT NULL references cvterm (cvterm_id),
    value text DEFAULT '' NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);
CREATE INDEX cvtermprop_idx1 ON cvtermprop (cvterm_id);
CREATE INDEX cvtermprop_idx2 ON cvtermprop (type_id);

CREATE TABLE cvterm_dbxref (
    cvterm_dbxref_id integer NOT NULL PRIMARY KEY,
    cvterm_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    is_for_definition integer DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX cvterm_dbxref_c1 on cvterm_dbxref (cvterm_id, dbxref_id);
CREATE INDEX cvterm_dbxref_idx1 ON cvterm_dbxref (cvterm_id);
CREATE INDEX cvterm_dbxref_idx2 ON cvterm_dbxref (dbxref_id);

CREATE TABLE organism (
       	organism_id integer NOT NULL PRIMARY KEY,
        abbreviation varchar(255) null,
        genus varchar(255) NOT NULL,
        species varchar(255) NOT NULL,
        common_name varchar(255) null,
        comment text null
);

CREATE INDEX organism_idx1 ON organism (organism_id);

CREATE TABLE organismprop (
organismprop_id integer NOT NULL PRIMARY KEY,
organism_id integer NOT NULL REFERENCES organism (organism_id),
type_id integer NOT NULL REFERENCES cvterm (cvterm_id),
value text,
rank integer DEFAULT 0 NOT NULL
);

CREATE INDEX organismprop_idx1 ON organismprop (organism_id);
CREATE INDEX organismprop_idx2 ON organismprop (type_id);

CREATE TABLE pub_organism (
       pub_organism_id integer NOT NULL PRIMARY KEY,
       pub integer NOT NULL REFERENCES pub (pub_id),
       organism integer NOT NULL REFERENCES organism (organism_id)
);

CREATE TABLE pub_status (
       pub_status_id integer NOT NULL PRIMARY KEY,
       pub_id integer NOT NULL REFERENCES pub (pub_id) UNIQUE,
       status integer NOT NULL REFERENCES cvterm (cvterm_id),
       assigned_curator integer REFERENCES person (person_id) 
);

CREATE TABLE person (
       person_id integer NOT NULL PRIMARY KEY,
       name text NOT NULL,
       networkaddress text NOT NULL UNIQUE,
       role integer REFERENCES cvterm(cvterm_id) DEFERRABLE INITIALLY DEFERRED  NOT NULL,
       lab INTEGER REFERENCES lab (lab_id),
       session_data text,
       password text
);

CREATE TABLE curs (
       curs_id integer NOT NULL PRIMARY KEY,
       community_curator integer NOT NULL REFERENCES person (person_id),
       pub integer NOT NULL REFERENCES pub (pub_id),
       curs_key text NOT NULL
);

CREATE TABLE lab (
       lab_id integer NOT NULL PRIMARY KEY,
       lab_head integer NOT NULL REFERENCES person (person_id),
       name text NOT NULL
);

CREATE TABLE sessions (
       id           text PRIMARY KEY,
       session_data text,
       expires      INTEGER
);

CREATE TABLE gene (
       gene_id integer NOT NULL PRIMARY KEY,
       primary_identifier text NOT NULL UNIQUE,
       product text,
       primary_name text,
       organism integer NOT NULL REFERENCES organism (organism_id)
);
CREATE INDEX gene_primary_identifier_idx ON gene (primary_identifier);
CREATE INDEX gene_primary_name_idx ON gene (primary_name);

CREATE TABLE genesynonym (
       genesynonym_id integer NOT NULL PRIMARY key,
       gene integer NOT NULL references gene (gene_id),
       identifier text NOT NULL
--       synonym_type integer NOT NULL references cvterm(cvterm_id)
);
CREATE INDEX genesynonym_identifier ON genesynonym (identifier);
