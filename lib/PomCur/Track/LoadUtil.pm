package PomCur::Track::LoadUtil;

=head1 NAME

PomCur::Track::LoadUtil -

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Track::LoadUtil

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use Carp;
use Moose;

has 'schema' => (
  is => 'ro',
  isa => 'PomCur::TrackDB'
);

=head2 get_organism

 Usage   : my $organism = $load_util->get_organism($genus, $species);
 Function: Find or create, and then return the organism matching the arguments
 Args    : the genus and species of the new organism
 Returns : The new organism

=cut
sub get_organism
{
  my $self = shift;

  my $genus = shift;
  my $species = shift;
  my $taxonid = shift;

  croak "no taxon id supplied" unless $taxonid;

  my $schema = $self->schema();

  return $schema->resultset('Organism')->find_or_create(
      {
        genus => $genus,
        species => $species,
        organismprops => [ { value => $taxonid,
                             type => { name => 'taxonId' },
                             rank => 0 } ]
      });
}

=head2 get_cv

 Usage   : my $cv = $load_util->get_cv($cv_name);
 Function: Find or create, and then return the cv object matching the arguments
 Args    : $cv_name - the cv name
 Returns : The new organism

=cut
sub get_cv
{
  my $self = shift;
  my $cv_name = shift;

  my $schema = $self->schema();

  croak unless defined $cv_name;

  return $schema->resultset('Cv')->find_or_create(
      {
        name => $cv_name
      });
}

=head2 get_db

 Usage   : my $db = $load_util->get_db($db_name);
 Function: Find or create, and then return the db object matching the arguments
 Returns : The new db object

=cut
sub get_db
{
  my $self = shift;
  my $db_name = shift;

  my $schema = $self->schema();

  return $schema->resultset('Db')->find_or_create(
      {
        name => $db_name
      });
}

=head2 get_dbxref

 Usage   : my $dbxref = $load_util->get_dbxref($db, $dbxref_acc);
 Function: Find or create, and then return the object matching the arguments
 Args    : $db - the Db object
           $dbxref_acc - the accession
 Returns : The new dbxref object

=cut
sub get_dbxref
{
  my $self = shift;
  my $db = shift;
  my $dbxref_acc = shift;

  my $schema = $self->schema();

  return $schema->resultset('Dbxref')->find_or_create(
      {
        accession => $dbxref_acc,
        db => $db
      });
}

=head2 get_cvterm

 Usage   : my $cvterm = $load_util->get_cvterm(cv_name => $cv_name,
                                               term_name => $term_name,
                                               ontologyid => $ontologyid,
                                               definition => $definition);
 Function: Find or create, and then return the object matching the arguments
 Args    : cv_name - the Cv name
           term_name - the cvterm name
           ontologyid - the id in the ontology, eg. "GO:0001234"
           definition - the term definition
 Returns : The new cvterm object

=cut
sub get_cvterm
{
  my $self = shift;

  my %args = @_;

  my $cv_name = $args{cv_name};
  my $cv = $args{cv};
  if (!defined $cv) {
    $cv = $self->get_cv($cv_name);
  }
  my $term_name = $args{term_name};
  my $ontologyid = $args{ontologyid};
  my $definition = $args{definition};
  my $is_relationshiptype = $args{is_relationshiptype} // 0;

  my $db_name;
  my $accession;

  if (defined $ontologyid && $ontologyid =~ /(.*):(.*)/) {
    $db_name = $1;
    $accession = $2
  } else {
    $db_name = 'PomCur Track';
    $accession = $term_name;
  }

  my $db = $self->get_db($db_name);
  my $dbxref = $self->get_dbxref($db, $accession);

  my $schema = $self->schema();

  my %create_args = (
    name => $term_name,
    cv => $cv,
    definition => $definition,
    dbxref => $dbxref,
    is_relationshiptype => $is_relationshiptype,
  );

  return $self->schema()->resultset('Cvterm')->find_or_create(
      {
        %create_args
      });
}

=head2 get_pub

 Usage   : my $pub = $load_util->get_pub($pubmedid);
 Function: Find or create, and then return the object matching the arguments
 Args    : $pubmedid - the PubMed ID
 Returns : The new pub object

=cut
sub get_pub
{
  my $self = shift;
  my $pubmedid = shift;

  my $schema = $self->schema();

  my $pub_type_cv = $self->get_cv('PomBase publication type');
  my $pub_type = $self->get_cvterm(cv => $pub_type_cv,
                                   term_name => 'unknown');

  return $schema->resultset('Pub')->find_or_create(
      {
        pubmedid => $pubmedid,
        type => $pub_type,
      });
}

=head2 get_lab

 Usage   : my $lab = $load_util->get_lab($lab_head_obj);
 Function: Find or create, and then return the object matching the arguments
 Args    : $lab_head_obj - the Person object for the lab head
 Returns : The new lab object

=cut
sub get_lab
{
  my $self = shift;
  my $lab_head = shift;

  my $schema = $self->schema();

  my $lab_head_name = $lab_head->name();

  (my $lab_head_surname = $lab_head_name) =~ s/.* //;

  return $schema->resultset('Lab')->find_or_create(
      {
        lab_head => $lab_head,
        name => "$lab_head_surname Lab"
      });
}

=head2 get_person

 Usage   : my $person = $load_util->get_person($name, $networkaddress,
                                               $role_cvterm);
 Function: Find or create, and then return the object matching the arguments
 Args    : $name - the Person full name
           $networkaddress - the email address
           $role_cvterm - a cvterm from the "PomBase user types" cv
 Returns : The new person object

=cut
sub get_person
{
  my $self = shift;
  my $name = shift;
  my $networkaddress = shift;
  my $role_cvterm = shift;

  my $schema = $self->schema();

  if (!defined $networkaddress || length $networkaddress == 0) {
    die "email not set for $name\n";
  }
  if (!defined $name || length $name == 0) {
    die "name not set for $networkaddress\n";
  }

  return $schema->resultset('Person')->find_or_create(
      {
        name => $name,
        networkaddress => $networkaddress,
        password => $networkaddress,
        role => $role_cvterm,
      });
}

1;
