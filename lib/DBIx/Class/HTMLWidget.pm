package DBIx::Class::HTMLWidget;
use strict;
use warnings;

our $VERSION = '0.04';
# pod after __END__

sub fill_widget {
    my ($dbic,$widget)=@_;

    my @elements = $widget->get_elements;

    # get embeded widgets

    my @widgets = @{ $widget->{_embedded} };

    foreach my $emb_widget (@widgets) {
        push @elements, $emb_widget->get_elements;
    }

    foreach my $element ( @elements ) {
        my $name=$element->name;
        next unless $name && $dbic->can($name) && $element->can('value');
        if($element->isa('HTML::Widget::Element::Checkbox')) {
            $element->checked($dbic->$name?1:0);
        } else {
            $element->value($dbic->$name);
            $element->value( $dbic->get_column($name) );
        }
    }
}


sub populate_from_widget {
    my ($dbic,$result)=@_;

#   find all checkboxes
    my %cb = map {$_->name => undef if $_->isa('HTML::Widget::Element::Checkbox')} 
    @{ $result->{_elements} };

    foreach my $col ( $dbic->result_source->columns ) {
    $dbic->set_column($col, scalar($result->param($col)))
        if defined $result->param($col) || exists $cb{$col};
    }
    $dbic->insert_or_update;
    return $dbic;
}


1;

__END__

=pod

=head1 NAME

DBIx::Class::HTMLWidget - Like FromForm but with DBIx::Class and HTML::Widget

=head1 SYNOPSIS

You'll need a working DBIx::Class setup and some knowledge of HTML::Widget
and Catalyst. If you have no idea what I'm talking about, check the (sparse)
docs of those modules.

   package My::Model::DBIC::Pet;
   use base 'DBIx::Class';
   __PACKAGE__->load_components(qw/HTMLWidget Core/);

   
   package My::Controller::Pet;    # Catalyst-style
   
   # define the widget in a sub (DRY)
   sub widget_pet {
     my ($self,$c)=@_;
     my $w=$c->widget('pet')->method('get');
     $w->element('Textfield','name')->label('Name');
     $w->element('Textfield','age')->label('Age');
     ...
     return $w;
   }
     
   # this renders an edit form with values filled in from the DB 
   sub edit : Local {
     my ($self,$c,$id)=@_;
  
     # get the object
     my $item=$c->model('DBIC::Pet')->find($id);
     $c->stash->{item}=$item;
  
     # get the widget
     my $w=$self->widget_pet($c);
     $w->action($c->uri_for('do_edit/'.$id));
    
     # fill widget with data from DB
     $item->fill_widget($w);
  }
  
  sub do_edit : Local {
    my ($self,$c,$id)=@_;
    
    # get the object from DB
    my $item=$c->model('DBIC::Pet')->find($id);
    $c->stash->{item}=$item;
    
    # get the widget
    my $w=$self->widget_pet($c);
    $w->action($c->uri_for('do_edit/'.$id));
    
    # process the form parameters
    my $result = $w->process($c->req);
    $c->stash->{'result'}=$result;
    
    # if there are no errors save the form values to the object
    unless ($result->has_errors) {
        $item->populate_from_widget($result);
        $c->res->redirect('/users/pet/'.$id);
    }

  }

  
=head1 DESCRIPTION

Something like Class::DBI::FromForm / Class::DBI::FromCGI but using
HTML::Widget for form creation and validation and DBIx::Class as a ORM.

=head2 Methods

=head3 fill_widget

   $dbic_object->fill_widget($widget);

Fill the values of a widgets elements with the values of the DBIC object.

=head3 populate_from_widget

   my $obj=$schema->resultset('pet)->new->populate_from_widget($result);
   my $item->populate_from_widget($result);

Create or update a DBIx::Class row from a HTML::Widget::Result object
   
=head1 AUTHOR

Thomas Klausner, <domm@cpan.org>, http://domm.zsi.at
Marcus Ramberg, <mramberg@cpan.org>
Simon Elliott, <cpan@browsing.co.uk> (added support for checkboxes)


=head1 LICENSE

This code is Copyright (c) 2003-2006 Thomas Klausner.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut



