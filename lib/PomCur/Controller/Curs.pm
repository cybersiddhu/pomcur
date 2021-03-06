package PomCur::Controller::Curs;

use base 'Catalyst::Controller::HTML::FormFu';

=head1 NAME

PomCur::Controller::Curs - curs (curation session) controller

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Controller::Curs

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use Carp;
use Moose;

with 'PomCur::Role::MetadataAccess';

use PomCur::Track;
use PomCur::Curs::Utils;

use constant {
  # user needs to confirm name and email address
  NEEDS_SUBMITTER => 0,
  # no genes in database, user needs to upload some
  NEEDS_GENES => 1,
#  READY => 2,
  # a gene is selected, but no annotation is started
  GENE_ACTIVE => 3,
  # user has picked an annotation type
  DONE => 5
};

# actions to execute for each state, undef for special cases
my %state_dispatch = (
  NEEDS_SUBMITTER, 'submitter_update',
  NEEDS_GENES, 'gene_upload',
  GENE_ACTIVE, undef,
  DONE, 'home',
);

=head2 begin

 Action to set up stash contents for curs

=cut
sub top : Chained('/') PathPart('curs') CaptureArgs(1)
{
  my ($self, $c, $curs_key) = @_;

  my $st = $c->stash();

  $st->{curs_key} = $curs_key;

  my $path = $c->req->uri()->path();
  (my $controller_name = __PACKAGE__) =~ s/.*::(.*)/\L$1/;
  $st->{controller_name} = $controller_name;

  my $root_path = $c->uri_for("/$controller_name/$curs_key");
  $st->{curs_root_path} = $root_path;

  $st->{page_description_id} = 'curs-page-description';

  my $config = $c->config();

  $st->{annotation_types} = $config->{annotation_types};
  $st->{annotation_type_list} = $config->{annotation_type_list};

  my $schema = PomCur::Curs::get_schema($c);
  $st->{schema} = $schema;

  my ($state, $submitter_email, $gene_count, $current_gene_id) = _get_state($c);
  $st->{state} = $state;

  $st->{first_contact_email} = get_metadata($schema, 'first_contact_email');
  $st->{first_contact_name} = get_metadata($schema, 'first_contact_name');

  my $pub_id = get_metadata($schema, 'curation_pub_id');
  $st->{pub} = $schema->find_with_type('Pub', $pub_id);

  if ($state >= NEEDS_GENES) {
    $st->{submitter_email} = $submitter_email;
    $st->{submitter_name} = get_metadata($schema, 'submitter_name');
  }

  if ($state == GENE_ACTIVE) {
    $st->{current_gene_id} = $current_gene_id;
    my $current_gene = $schema->find_with_type('Gene', $current_gene_id);
    $st->{current_gene} = $current_gene;

    my $gene_display_name = $current_gene->display_name();
    $st->{gene_display_name} = $gene_display_name;

    $st->{title} =
      "Curating $gene_display_name from PMID:" . $st->{pub}->pubmedid();
  }

  $st->{gene_count} = _get_gene_resultset($schema)->count();

  if ($path !~ /gene_upload|edit_genes/) {
    my $dispatch_dest = $state_dispatch{$state};
    if (defined $dispatch_dest) {
      $c->detach($dispatch_dest);
    }
  }
}

# Return a constant describing the state of the application, eg. NEEDS_GENES
# or DONE.  See the %state hash above for details
sub _get_state
{
  my $c = shift;

  my $st = $c->stash();

  my $schema = $st->{schema};
  my $submitter_email = get_metadata($schema, 'submitter_email');

  my $state = undef;
  my $current_gene_id = undef;
  my $gene_count = undef;

  if (defined $submitter_email) {
    my $gene_rs = _get_gene_resultset($schema);
    $gene_count = $gene_rs->count();

    if ($gene_count > 0) {
      $current_gene_id = get_metadata($schema, 'current_gene_id');

      if (defined $current_gene_id) {
          $state = GENE_ACTIVE;
      } else {
        $state = DONE;
      }
    } else {
      $state = NEEDS_GENES;
    }
  } else {
    $state = NEEDS_SUBMITTER;
  }

  return ($state, $submitter_email, $gene_count, $current_gene_id);
}

sub _set_new_gene
{
  my $schema = shift;

  my $gene_rs = _get_gene_resultset($schema);
  my $first_gene = $gene_rs->first();

  if (defined $first_gene) {
    set_metadata($schema, 'current_gene_id', $first_gene->gene_id());
  } else {
    unset_metadata($schema, 'current_gene_id');
  }
}

sub _redirect_and_detach
{
  my ($c, @path_components) = @_;

  if (@path_components) {
    unshift @path_components, '';
  }

  my $target = $c->stash->{curs_root_path} . join ('/', @path_components);

  $c->res->redirect($target);
  $c->detach();
}

sub home : Chained('top') PathPart('') Args(0)
{
  my ($self, $c) = @_;

  # don't set stash title - use default
  $c->stash->{template} = 'curs/home.mhtml';

  $c->stash->{current_component} = 'home';
}

sub submitter_update : Private
{
  my ($self, $c) = @_;

  my $st = $c->stash();

  $st->{title} = 'Submitter update';
  $st->{template} = 'curs/submitter_update.mhtml';

  $st->{current_component} = 'submitter_update';

  my $first_contact_name = $st->{first_contact_name};
  my $first_contact_email = $st->{first_contact_email};

  my $submitter_update_text_name = 'submitter_name';
  my $submitter_update_text_email = 'submitter_email';

  my $form = $self->form();

  my @all_elements = (
      {
        name => 'submitter_name', label => 'Name', type => 'Text', size => 40,
        value => $first_contact_name,
        constraints => [ { type => 'Length',  min => 1 }, 'Required' ],
      },
      {
        name => 'submitter_email', label => 'Email', type => 'Text', size => 40,
        value => $first_contact_email,
        constraints => [ { type => 'Length',  min => 1 }, 'Required', 'Email' ],
      },
      {
        name => 'submit', type => 'Submit', value => 'submit',
        attributes => { class => 'button', },
      },
    );

  $form->elements([@all_elements]);

  $form->process();

  $st->{form} = $form;

  if ($form->submitted_and_valid()) {
    my $submitter_name = $form->param_value('submitter_name');
    my $submitter_email = $form->param_value('submitter_email');

    my $schema = PomCur::Curs::get_schema($c);


    my $add_submitter = sub {
      $schema->create_with_type('Metadata', { key => 'submitter_email',
                                              value => $submitter_email });

      $schema->create_with_type('Metadata', { key => 'submitter_name',
                                              value => $submitter_name });
    };

    $schema->txn_do($add_submitter);

    _redirect_and_detach($c);
  }
}

my $gene_list_textarea_name = 'gene_identifiers';

# return a list of only those genes which aren't already in the database
sub _filter_existing_genes
{
  my $schema = shift;
  my @genes = @_;

  my @gene_primary_identifiers = map { $_->{primary_identifier} } @genes;

  my $gene_rs = _get_gene_resultset($schema);
  my $rs = $gene_rs->search({
    primary_identifier => {
      -in => [@gene_primary_identifiers],
    }
  });

  my %found_genes = ();
  while (defined (my $gene = $rs->next())) {
    $found_genes{$gene->primary_identifier()} = 1;
  }

  return grep { !exists $found_genes{ $_->{primary_identifier} } } @genes;
}

# create a gene in the Curs database from a lookup() result
sub _create_gene
{
  my $schema = shift;
  my $result = shift;

  my $ret_gene = undef;

  my $_create_curs_genes = sub
      {
        my @genes = @{$result->{found}};

        @genes = _filter_existing_genes($schema, @genes);

        for my $gene (@genes) {
          my $org_full_name = $gene->{organism_full_name};
          my $org_taxonid = $gene->{organism_taxonid};
          my $curs_org =
            PomCur::CursDB::Organism::get_organism($schema, $org_full_name,
                                                   $org_taxonid);

          $ret_gene = $schema->create_with_type('Gene', {
            primary_name => $gene->{primary_name},
            primary_identifier => $gene->{primary_identifier},
            product => $gene->{product},
            organism => $curs_org
          });
        }
      };

  $schema->txn_do($_create_curs_genes);

  return $ret_gene;
}

sub _find_and_create_genes
{
  my ($schema, $config, $search_terms_ref) = @_;

  my @search_terms = @$search_terms_ref;
  my $lookup = PomCur::Track::get_lookup($config, 'gene');

  my $result = $lookup->lookup([@search_terms]);

  if (@{$result->{missing}}) {
    return $result;
  } else {
    _create_gene($schema, $result);

    return undef;
  }
}

# $confirm_genes will be true if we have just uploaded some genes
sub _edit_genes_helper
{
  my ($self, $c, $confirm_genes) = @_;

  my $st = $c->stash();

  $st->{title} = 'Gene list for PMID:' . $st->{pub}->pubmedid();
  $st->{template} = 'curs/gene_list_edit.mhtml';

  $st->{current_component} = 'list_edit';

  $st->{confirm_genes} = $confirm_genes;

  my $config = $c->config();
  my $schema = $st->{schema};

  my $form = $self->form();

  my @all_elements = (
      {
        name => 'gene-select', label => 'gene-select',
        type => 'Checkbox', default_empty_value => 1
      },
      {
        name => 'submit', type => 'Submit', value => 'Delete selected',
        name => 'continue', type => 'Submit', value => 'Continue',
      },
    );


  $form->elements([@all_elements]);

  $form->process();

  $st->{form} = $form;

  if ($form->submitted_and_valid()) {
    if (defined $c->req->param('continue')) {
      _redirect_and_detach($c);
    }

    if ($c->req()->param('submit')) {
      my @gene_ids = @{$form->param_array('gene-select')};

      if (@gene_ids == 0) {
        $st->{error} =
          { title => "No genes selected for deletion" };
      } else {
        my $delete_sub = sub {
          for my $gene_id (@gene_ids) {
            my $gene = $schema->find_with_type('Gene', $gene_id);
            $gene->delete();
            if (defined $st->{current_gene_id} &&
                $st->{current_gene_id} eq $gene_id) {
              _set_new_gene($schema);
            }
          }
        };
        $schema->txn_do($delete_sub);

        if ($schema->resultset('Gene')->count() == 0) {
          $c->flash()->{message} = 'All genes removed from the list';
          _redirect_and_detach($c, 'gene_upload');
        } else {
          my $plu = scalar(@gene_ids) > 1 ? 's' : '';
          $st->{message} = 'Removed ' . scalar(@gene_ids) . " gene$plu from list";
        }
      }
    }
  }
}

sub edit_genes : Chained('top') Args(0) Form
{
  my $self = shift;

  $self->_edit_genes_helper(@_, 0);
}

sub confirm_genes : Chained('top') Args(0) Form
{
  my $self = shift;

  $self->_edit_genes_helper(@_, 1);
}

sub gene_upload : Chained('top') Args(0) Form
{
  my ($self, $c) = @_;

  my $st = $c->stash();

  $st->{title} = 'Gene upload';
  $st->{template} = 'curs/gene_upload.mhtml';
  $st->{current_component} = 'gene_upload';

  my $form = $self->form();
  my @submit_buttons = ("submit");

  my $schema = $st->{schema};

  if ($st->{gene_count} > 0) {
    push @submit_buttons, "cancel";
  }

  my @all_elements = (
      { name => $gene_list_textarea_name, type => 'Textarea', cols => 80, rows => 10,
        constraints => [ { type => 'Length',  min => 1 }, 'Required' ],
      },
      map {
          {
            name => $_, type => 'Submit', value => $_,
              attributes => { class => 'button', },
            }
        } @submit_buttons,
    );

  $form->elements([@all_elements]);

  $form->process();

  $st->{form} = $form;

  if ($form->submitted()) {
    if (defined $c->req->param('cancel')) {
      _redirect_and_detach($c, 'edit_genes');
    }
  }

  if ($form->submitted_and_valid()) {
    my $search_terms_text = $form->param_value($gene_list_textarea_name);
    my @search_terms = grep { length $_ > 0 } split /[\s,]+/, $search_terms_text;

    my $result = _find_and_create_genes($schema, $c->config(), \@search_terms);

    if ($result) {
      my @missing = @{$result->{missing}};
      $st->{error} =
          { title => "No genes found for these identifiers: @missing" };
      $st->{gene_upload_unknown} = [@missing];
    } else {
      my $state = $st->{state};
      if ($state ne GENE_ACTIVE) {
        _set_new_gene($schema);
        $c->stash()->{state} = GENE_ACTIVE;
      }

      _redirect_and_detach($c, 'confirm_genes');
    }
  }
}

sub _get_annotation_helper
{
  my $c = shift;
  my $annotation_type_name = shift;

  my $config = $c->config();
  my $st = $c->stash();

  my %annotation_types = %{$config->{annotation_types}};

  my $module_config = $annotation_types{$annotation_type_name};
  my $module_class_name = $module_config->{class};

  my %args = (config => $config);

  while (my($key, $value) = each %{$module_config->{constructor_args}}) {
    $args{$key} = $value;
  }

  eval "use $module_class_name";
  if ($@) {
    die "can't find module ('$module_class_name') specified in configuration "
      . "for module: $annotation_type_name\n";
  }

  my $lookup = $module_class_name->new(%args);
}

sub annotation_delete : Chained('top') PathPart('annotation/delete') Args(1)
{
  my ($self, $c, $annotation_id) = @_;

  my $config = $c->config();
  my $st = $c->stash();
  my $schema = $st->{schema};

  my $delete_sub = sub {
    $schema->resultset('Annotation')->find($annotation_id)->delete();
    $schema->resultset('GeneAnnotation')
      ->search({ annotation => $annotation_id })->delete();
  };

  $schema->txn_do($delete_sub);

  _redirect_and_detach($c);
}

sub _get_iso_date
{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
  return sprintf "%4d-%02d-%02d", 1900+$year, $mon+1, $mday
}

sub annotation_edit : Chained('top') PathPart('annotation/edit') Args(2) Form
{
  my ($self, $c, $gene_id, $annotation_type_name) = @_;

  my $config = $c->config();
  my $st = $c->stash();
  my $schema = $st->{schema};

  my $gene = $schema->find_with_type('Gene', $gene_id);
  my $gene_display_name = $gene->display_name();

  my $annotation_config = $config->{annotation_types}->{$annotation_type_name};

  my $module_display_name = $annotation_config->{display_name};

  # don't set stash title - use default
  $st->{current_component} = $annotation_type_name;
  $st->{current_component_display_name} = $annotation_config->{display_name};
  $st->{current_component_short_display_name} =
    $annotation_config->{short_display_name};
  $st->{current_component_very_short_display_name} =
    $annotation_config->{very_short_display_name};
  $st->{current_component_suggest_term_help} =
    $annotation_config->{suggest_term_help_text};
  my $broad_term_suggestions = $annotation_config->{broad_term_suggestions};
  $broad_term_suggestions =~ s/\s+$//g;
  $st->{broad_term_suggestions} = $broad_term_suggestions;
  my $specific_term_examples = $annotation_config->{specific_term_examples};
  $specific_term_examples =~ s/\s+$//g;
  $st->{specific_term_examples} = $specific_term_examples;
  my $annotation_help_text = $annotation_config->{help_text};
  $st->{annotation_help_text} = $annotation_help_text;
  my $annotation_more_help_text = $annotation_config->{more_help_text};
  $st->{annotation_more_help_text} = $annotation_more_help_text;
  $st->{template} = "curs/modules/$annotation_type_name.mhtml";

  my $annotation_helper = _get_annotation_helper($c, $annotation_type_name);

  $st->{annotation_helper} = $annotation_helper;

  my $form = $self->form();

  my @all_elements = (
      {
        name => 'ferret-term-id', label => 'ferret-term-id',
        type => 'Hidden',
      },
      {
        name => 'ferret-suggest-name', label => 'ferret-suggest-name',
        type => 'Text',
      },
      {
        name =>'ferret-suggest-definition', label => 'ferret-suggest-definition',
        type => 'Text',
      },
      {
        name => 'ferret-submit', type => 'Submit',
      }
    );

  $form->elements([@all_elements]);
  $form->process();
  $st->{form} = $form;

  if ($form->submitted_and_valid()) {
    my $term_ontid = $form->param_value('ferret-term-id');
    my $submit_value = $form->param_value('ferret-submit');

    my $guard = $schema->txn_scope_guard;

    my %annotation_data = (term_ontid => $term_ontid);


    if ($submit_value eq 'Submit suggestion') {
      my $suggested_name = $form->param_value('ferret-suggest-name');
      my $suggested_definition =
        $form->param_value('ferret-suggest-definition');

      $suggested_name =~ s/^\s+//;
      $suggested_name =~ s/\s+$//;
      $suggested_definition =~ s/^\s+//;
      $suggested_definition =~ s/\s+$//;

      $annotation_data{term_suggestion} = {
        name => $suggested_name,
        definition => $suggested_definition
      };

      $c->flash()->{message} = 'Note that your term suggestion has been '
        . 'stored, but the gene will be temporarily '
        . 'annotated with the parent of your suggested new term';
    }

    my $gene = $schema->find_with_type('Gene', $gene_id);
    my $annotation =
      $schema->create_with_type('Annotation',
                                {
                                  type => $annotation_type_name,
                                  status => 'new',
                                  pub => $st->{pub},
                                  creation_date => _get_iso_date(),
                                  data => { %annotation_data }
                                });

    $annotation->set_genes($gene);

    $guard->commit();

    my $annotation_id = $annotation->annotation_id();

    _redirect_and_detach($c, 'annotation', 'evidence', $annotation_id);
  }
}

sub annotation_evidence : Chained('top') PathPart('annotation/evidence') Args(1) Form
{
  my ($self, $c, $annotation_id) = @_;

  my $config = $c->config();
  my $st = $c->stash();
  my $schema = $st->{schema};

  my $annotation = $schema->find_with_type('Annotation', $annotation_id);
  my $annotation_type_name = $annotation->type();

  my $gene = $annotation->genes()->first();
  my $gene_display_name = $gene->display_name();

  my $annotation_config = $config->{annotation_types}->{$annotation_type_name};

  my $annotation_data = $annotation->data();
  my $term_ontid = $annotation_data->{term_ontid};

  my $module_display_name = $annotation_config->{display_name};
  $st->{title} = "Annotating $gene_display_name";
  $st->{current_component} = $annotation_type_name;
  $st->{current_component_display_name} = $annotation_config->{display_name};
  $st->{template} = "curs/modules/${annotation_type_name}_evidence.mhtml";

  $st->{term_ontid} = $term_ontid;

  my $annotation_helper = _get_annotation_helper($c, $annotation_type_name);

  $st->{annotation_helper} = $annotation_helper;

  my $ont_config = $config->{annotation_types}->{$annotation_type_name};

  my %evidence_types = %{$config->{evidence_types}};

  my @codes = map {
    [ $_, $evidence_types{$_}->{name} . " ($_)" ]
  } @{$ont_config->{evidence_codes}};

  unshift @codes, [ '', 'Choose an evidence type ...' ];

  my $form = $self->form();

  my @all_elements = (
      {
        name => 'evidence-select',
        type => 'Select', options => [ @codes ],
      },
      {
        name => 'evidence-proceed', type => 'Submit', value => 'Proceed',
      },
    );

  $form->elements([@all_elements]);

  $form->process();

  $st->{form} = $form;

  if ($form->submitted_and_valid()) {
    my $data = $annotation->data();
    my $evidence_select = $form->param_value('evidence-select');

    if ($evidence_select eq '') {
      $c->flash()->{error} = 'Please choose an evidence type to continue';
      _redirect_and_detach($c, 'annotation', 'evidence', $annotation_id);
    }

    $data->{evidence_code} = $evidence_select;

    $annotation->data($data);
    $annotation->update();

    my $with_gene = $evidence_types{$evidence_select}->{with_gene};

    if ($with_gene) {
      _redirect_and_detach($c, 'annotation', 'with_gene', $annotation_id);
    } else {
      _redirect_and_detach($c);
    }
  }
}

sub annotation_with_gene : Chained('top') PathPart('annotation/with_gene') Args(1) Form
{
  my ($self, $c, $annotation_id) = @_;

  my $config = $c->config();
  my $st = $c->stash();
  my $schema = $st->{schema};

  my $annotation = $schema->find_with_type('Annotation', $annotation_id);
  my $annotation_type_name = $annotation->type();

  my $gene = $annotation->genes()->first();
  my $gene_display_name = $gene->display_name();

  my $annotation_config = $config->{annotation_types}->{$annotation_type_name};

  my $annotation_data = $annotation->data();
  my $evidence_code = $annotation_data->{evidence_code};
  my $term_ontid = $annotation_data->{term_ontid};

  my $module_display_name = $annotation_config->{display_name};

  $st->{title} = "Annotating $gene_display_name";
  $st->{current_component} = $annotation_type_name;
  $st->{current_component_display_name} = $annotation_config->{display_name};
  $st->{template} = "curs/modules/${annotation_type_name}_with_gene.mhtml";

  my $annotation_helper = _get_annotation_helper($c, $annotation_type_name);

  $st->{annotation_helper} = $annotation_helper;
  $st->{term_ontid} = $term_ontid;
  $st->{evidence_code} = $evidence_code;

  my @genes = ();

  my $gene_rs = $schema->resultset('Gene');

  while (defined (my $gene = $gene_rs->next())) {
    push @genes, [$gene->primary_identifier(), $gene->display_name()];
  }

  unshift @genes, [ '', 'Choose a gene ...' ];

  my $form = $self->form();

  my @all_elements = (
      {
        name => 'with-gene-select',
        type => 'Select', options => [ @genes ],
      },
      {
        name => 'with-gene-proceed', type => 'Submit', value => 'Proceed',
      },
    );

  $form->elements([@all_elements]);

  $form->process();

  $st->{form} = $form;

  if ($form->submitted_and_valid()) {
    my $data = $annotation->data();
    my $with_gene_select = $form->param_value('with-gene-select');

    if ($with_gene_select eq '') {
      $c->flash()->{error} = 'Please choose a gene to continue';
      _redirect_and_detach($c, 'annotation', 'with_gene', $annotation_id);
    }

    $data->{with_gene} = $with_gene_select;

    $annotation->data($data);
    $annotation->update();

    _redirect_and_detach($c);
  }
}

sub set_current_gene : Chained('top') Args(1)
{
  my ($self, $c, $gene_id) = @_;

  my $schema = $c->stash()->{schema};

  set_metadata($schema, 'current_gene_id', $gene_id);

  _redirect_and_detach($c);
}

sub _get_gene_resultset
{
  my $schema = shift;
  return $schema->resultset('Gene')->search({},
                                            {
                                              order_by => {
                                                -asc => 'gene_id'
                                              }
                                            });
}

sub export_annotation : Chained('top') PathPart('export/annotation') Args(0)
{
  my ($self, $c) = @_;

  my $schema = $c->stash()->{schema};
  my $config = $c->config();

  my ($completed_count, $annotations_ref) =
    PomCur::Curs::Utils::get_annotation_table($config, $schema);
  my @annotations = @$annotations_ref;

  my %common_values = %{$config->{export}->{gene_association_fields}};

  my @column_names = qw(db gene_identifier gene_name_or_identifier
                        qualifier term_ontid pubmedid
                        evidence_code with_or_from_identifier
                        annotation_type_abbreviation
                        gene_product gene_synonyms_string db_object_type taxonid
                        creation_date_short db);

  my $db = $config->{export}->{gene_association_fields}->{db};

  my $results = '';

  for my $annotation (@annotations) {
    next unless $annotation->{completed};

    $results .= join "\t", map {
      my $val = $common_values{$_};
      if (!defined $val) {
        $val = $annotation->{$_};
      }
      if ($_ eq 'taxonid') {
        $val = "taxon:$val";
      }
      if ($_ eq 'pubmedid') {
        $val = "PMID:$val";
      }
      if ($_ eq 'with_or_from_identifier') {
        if (defined $val && length $val > 0) {
          $val = "$db:$val";
        } else {
          $val = '';
        }
      }

      $val;
    } @column_names;
    $results .= "\n";
  }

  $c->res->content_type('text/plain');
  $c->res->body($results);
}

1;
