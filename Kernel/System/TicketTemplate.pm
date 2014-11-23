# --
# Kernel/System/TicketTemplate.pm - All Template related functions should be here eventually
# Copyright (C) 2012-2014 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketTemplate;

use strict;
use warnings;

use Kernel::System::Ticket;

our $VERSION = 0.03;

=head1 NAME

Kernel::System::TicketTemplate - ticket template lib

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::TicketTemplate;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $TemplateObject = Kernel::System::TicketTemplate->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        MainObject   => $MainObject,
        EncodeObject => $EncodeObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(DBObject ConfigObject MainObject LogObject EncodeObject TimeObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }
    
    # create needed objects
    $Self->{TicketObject} = Kernel::System::Ticket->new( %{$Self} );

    return $Self;
}

=item TemplateExists()

checks if a template with a given name already exists. returns the template id
if a template exists, 'undef' otherwise.

    my $TemplateExists = $TemplateObject->TemplateExists(
        TemplateName => 'A template name',
    );

=cut

sub TemplateExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TemplateName)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    return if !$Self->{DBObject}->Prepare(
        SQL   => 'SELECT id FROM ps_tickettemplate WHERE name = ?',
        Bind  => [ \$Param{TemplateName} ],
        Limit => 1,
    );

    my $TemplateID;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $TemplateID = $Row[0];
    }

    return $TemplateID;
}

=item TemplateAdd()

to add a template

    my $ID = $TemplateObject->TemplateAdd(
        Template     => $TemplateStructure,
        TemplateName => 'Name of the template',
        TicketType   => 'phone',                             # phone|email
        Comment      => 'comment describing the template',   # optional
        UserID       => 123,
    );

=cut

sub TemplateAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Template TemplateName TicketType UserID)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # insert new invoice
    return if !$Self->{DBObject}->Do(
        SQL => 'INSERT INTO ps_tickettemplate '
            . '(name, template, ticket_type, comments, create_time, create_by) '
            . 'VALUES (?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TemplateName},
            \$Param{Template},
            \$Param{TicketType},
            \$Param{Comment},
            \$Param{UserID},
        ],
    );

    # get new invoice id
    return if !$Self->{DBObject}->Prepare(
        SQL  => 'SELECT id FROM ps_tickettemplate WHERE name = ?',
        Bind => [ \$Param{TemplateName}, ],
    );

    my $TemplateID;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $TemplateID = $Row[0];
    }

    # log notice
    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message  => "Template '$TemplateID' created successfully ($Param{UserID})!",
    );

    return $TemplateID;
}

=item TemplateGet()

returns a hash with template data

    my %TemplateData = $TemplateObject->TemplateGet( TemplateID => 2 );

This returns something like:

    %TemplateData = (
        'TemplateID'    => 2,
        'TemplateName'  => 'Test template 1',
        'Template'      => $DumpOfTemplateStructure,
        'TicketType'    => 'email',
        'CreateTime'    => '2010-04-07 15:41:15',
        'Comment'       => 'Test.',
        'CreateBy'      => 123,
    );

=cut

sub TemplateGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TemplateID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need TemplateID!',
        );
        return;
    }

    # sql
    return if !$Self->{DBObject}->Prepare(
        SQL => 'SELECT id, name, comments, template, ticket_type, create_time, create_by '
            . 'FROM ps_tickettemplate WHERE id = ?',
        Bind  => [ \$Param{TemplateID} ],
        Limit => 1,
    );

    my %Template;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        %Template = (
            TemplateID   => $Data[0],
            TemplateName => $Data[1],
            Comment      => $Data[2],
            Template     => $Data[3],
            TicketType   => $Data[4],
            CreateTime   => $Data[5],
            CreateBy     => $Data[6],
        );
    }

    return %Template;
}

=item TemplateDelete()

deletes a template. Returns 1 if it was successful, undef otherwise.

    my $Success = $TemplateObject->TemplateDelete(
        TemplateID => 123,
    );

=cut

sub TemplateDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TemplateID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need TemplateID!',
        );
        return;
    }

    return $Self->{DBObject}->Do(
        SQL  => 'DELETE FROM ps_tickettemplate WHERE id = ?',
        Bind => [ \$Param{TemplateID} ],
    );
}


=item TemplateList()

returns a hash of all templates

    my %Templates = $TemplateObject->TemplateList(
        TicketType => 'email', # optional email|phone
    );

the result looks like

    %Templates = (
        '1' => 'Template 1',
        '2' => 'Test Template',
    );

=cut

sub TemplateList {
    my ( $Self, %Param ) = @_;

    my %ColumnMap = (
        TicketType => 'ticket_type',
    );

    my @Where;
    my @Bind;

    PARAMNAME:
    for my $ParamName (qw(TicketType)) {
        if ( $Param{$ParamName} && ! ref $Param{$ParamName} ) {
            my $ColumnName = $ColumnMap{$ParamName};
            next if !$Param{$ParamName};

	    push @Where, "$ColumnName = ?";
            push @Bind, \$Param{$ParamName};
        }
    }

    my $WhereString = join ' AND ', @Where;
    $WhereString  ||= '1 = 1';

    # sql
    return if !$Self->{DBObject}->Prepare(
        SQL  => "SELECT id, name FROM ps_tickettemplate WHERE $WhereString",
        Bind => \@Bind,
    );

    my %Templates;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        $Templates{ $Data[0] } = $Data[1];
    }

    return %Templates;
}

=item TemplateDataGet()

This method collects all information that could be needed for templates.
Therefor it loads plugins - if available - and makes the fields available

The potential template fields have to be configured appropriatly.

How plugins can be developed is described in the documentation (PDF).

    my %TemplateData = $TemplateObject->TemplateDataGet(
        TicketID => 123,
    );

=cut

sub TemplateDataGet {
    my ( $Self, %Param ) = @_;

    # check for needed stuff
    for my $Needed (qw(TicketID)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "No $Needed given!",
            );
            return;
        }
    }

    # get all configured fields
    my $Fields  = $Self->{ConfigObject}->Get( 'TicketTemplate::Field' );

    my %Plugins;
    my @TicketFields;
    my %FieldNames;
    
    for my $Field ( keys %{$Fields} ) {
        my $Module    = $Fields->{$Field}->{Module};
        my $Name      = $Fields->{$Field}->{Name};
        my $Fieldname = $Fields->{$Field}->{HTML} || $Fields->{$Field}->{Name};

        push @{ $Plugins{$Module} }, $Name if $Module;
        push @TicketFields, $Name          if !$Module;

        $FieldNames{$Name} = $Fieldname;
    };

    my %Result;

    # load all modules
    MODULE:
    for my $Module ( keys %Plugins ) {
        next MODULE if !$Module;

        # require the module
        next MODULE if !$Self->{MainObject}->Require( $Module );

        my $Object = $Module->new( %{$Self} );
        next MODULE if !$Object;

        my $Sub = $Object->can( 'DataGet' );
        next Module if !$Sub;

        my %Data = $Object->$Sub(
            TicketID => $Param{TicketID},
        );

        for my $Field ( @{ $Plugins{$Module} } ) {
            $Result{$Field} = {
                Field => $FieldNames{$Field},
                Value => $Data{$Field},
            };
        }
    }

    my %TicketData = $Self->{TicketObject}->TicketGet(
        TicketID => $Param{TicketID},
        UserID   => 1,
    );

    for my $Field ( @TicketFields ) {
        $Result{$Field} = {
            Field => $FieldNames{$Field},
            Value => $TicketData{$Field},
        };

        if ( $Field eq 'QueueID' ) {
            $Result{$Field}->{Value} = $TicketData{$Field} . '||' . $TicketData{Queue};
        }
    }

    return %Result;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

