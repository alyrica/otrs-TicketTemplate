# --
# Kernel/Modules/AgentTicketTemplate.pm - free text for ticket
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: AgentTicketTemplate.pm,v 1.78 2010/06/18 18:15:49 en Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketTemplate;

use strict;
use warnings;

use Kernel::System::TicketTemplate;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.78 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # create object
    my $Self = bless {%Param}, $Type;

    # check if all needed objects were passed
    for my $NeededObject (
        qw(ParamObject DBObject LayoutObject LogObject ConfigObject TicketObject TimeObject)
        )
    {
        if ( !$Self->{$NeededObject} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $NeededObject!" );
        }
    }

    # create needed objects
    $Self->{TemplateObject} = Kernel::System::TicketTemplate->new( %Param );

    $Self->{Config} = $Self->{ConfigObject}->Get( "Ticket::Frontent::$Self->{Action}" );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get parameters from request
    my %GetParam;
    for my $ParamName (qw(TicketID Comment TemplateName TemplateID)) {
        $GetParam{$ParamName} = $Self->{ParamObject}->GetParam( Param => $ParamName ) || '';
    }

    # check for needed stuff
    if ( $Self->{Action} and ( $Self->{Action} eq 'ShowForm' || $Self->{Action} eq 'SaveTemplate' ) ) {
        for my $Needed (qw(TicketID)) {
            if ( !$GetParam{$Needed} ) {
                $Self->{LogObject}->Log(
                    Priority => 'error',
                    Message  => "Need $Needed!",
                );
                return $Self->{LayoutObject}->ErrorScreen(
                    Message => "No $Needed is given!",
                    Comment => 'Please contact the admin.',
                );
            }
        }

        # check permission
        my $Access = $Self->{TicketObject}->TicketPermission(
            Type     => $Self->{Config}->{Permission} || 'ro',
            TicketID => $GetParam{TicketID},
            UserID   => $Self->{UserID},
        );

        if ( !$Access ) {
            return $Self->{LayoutObject}->ErrorScreen(
                Message    => "You need $Self->{Config}->{Permission} permission!",
                WithHeader => 'yes',
            );
        }
    }

    if ( $Self->{Subaction} eq 'ShowForm' ) {

        # show form
        my $Output       = $Self->{LayoutObject}->Header(
            Type => 'Small',
        );
        $Output .= $Self->_MaskNewTemplate( %GetParam, %Param );
        $Output .= $Self->{LayoutObject}->Footer(
            Type => 'Small',
        );
        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'SaveTemplate' ) {

        # save template and show success message
        my $Output       = $Self->{LayoutObject}->Header(
            Type => 'Small',
        );
        $Output .= $Self->_SaveTemplate( %GetParam );
        $Output .= $Self->{LayoutObject}->Footer(
            Type => 'Small',
        );
        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'DeleteTemplate' ) {
        $Self->{TemplateObject}->TemplateDelete(
            TemplateID => $GetParam{TemplateID},
        );

        return $Self->{LayoutObject}->Redirect(
            OP => 'Action=$Env{"Action"}',
        );
    }
    elsif ( $Self->{Subaction} eq 'TemplateAsJson' ) {
        my %TemplateData = $Self->{TemplateObject}->TemplateGet(
            TemplateID => $GetParam{TemplateID},
        );

       return $Self->{LayoutObject}->Attachment(
           ContentType => 'application/json; charset=' . $Self->{LayoutObject}->{Charset},
           Content     => $TemplateData{Template} || '',
           Type        => 'inline',
           NoCache     => 0,
       );
    }
    else {

        # show list of templates
        my $Output = $Self->{LayoutObject}->Header();
        $Output   .= $Self->_TemplateList( %GetParam );
        $Output   .= $Self->{LayoutObject}->Footer();
        return $Output;
    }
}

sub _TemplateList {
    my ( $Self, %Param ) = @_;

    my %TemplateList = $Self->{TemplateObject}->TemplateList();

    if ( !%TemplateList ) {
        $Self->{LayoutObject}->Block(
            Name => 'NoTemplates',
        );
    }

    for my $TemplateID ( keys %TemplateList ) {
        my %Template = $Self->{TemplateObject}->TemplateGet(
            TemplateID => $TemplateID,
        );

        $Self->{LayoutObject}->Block(
            Name => 'TemplateRow',
            Data => \%Template,
        );
    }

    return $Self->{LayoutObject}->Output(
        TemplateFile => 'AgentTicketTemplateList',
        Data         => {
            %Param,
        },
    );
}

sub _MaskNewTemplate {
    my ( $Self, %Param ) = @_;

    # get potential fields
    my $Fields = $Self->{ConfigObject}->Get( 'TicketTemplate::Field' );
    my %PotentialFields = map{
        my $Label = $Fields->{$_}->{Label};
        $Label ? ($Fields->{$_}->{Name} => $Label) : ();
    }keys %{$Fields};

    # create select box
    $Param{PotentialFields} = $Self->{LayoutObject}->BuildSelection(
        Data        => \%PotentialFields,
        Name        => 'TemplateFields',
        Size        => 20,
        SelectedIDs => [ $Self->{ParamObject}->GetArray( Param => 'TemplateFields' ) ],
        HTMLQuote   => 1,
        Validate    => 1,
        Multiple    => 1,
        Class       => $Param{TemplateFieldsInvalid} || '',
    );

    # get ticket data
    my %TicketData = $Self->{TicketObject}->TicketGet(
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    $Param{TicketNumber} = $TicketData{TicketNumber};
    $Param{TicketTitle}  = $TicketData{Title};

    # return template output
    return $Self->{LayoutObject}->Output(
        TemplateFile => 'AgentTicketTemplateForm',
        Data         => {
            %Param,
        },
    );
}

sub _SaveTemplate {
    my ( $Self, %Param ) = @_;

    # check for needed stuff
    for my $Needed (qw(TicketID)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Got no $Needed!",
            );
            return;
        }
    }

    # a name for the template must be given
    my $Error;
    my $Name = $Self->{ParamObject}->GetParam( Param => 'TemplateName' );
    if ( !$Name ) {
        $Param{TemplateNameInvalid} = 'ServerError';
        $Error = 1;
    }

    if ( $Name && $Self->{TemplateObject}->TemplateExists( TemplateName => $Name ) ) {
        $Param{TemplateNameInvalid} = 'ServerError';
        $Error = 1;
    }

    # get all fields that are selected for the template
    my @Fields = $Self->{ParamObject}->GetArray( Param => 'TemplateFields' );

    # show error message when no field was selected
    if ( !@Fields ) {
        $Param{TemplateFieldsInvalid} = 'ServerError';
        $Error = 1;
    }

    # show error message if an error occured
    if ( $Error ) {
        return $Self->_MaskNewTemplate( %Param );
    }

    # get all potential data
    my %TemplateData = $Self->{TemplateObject}->TemplateDataGet(
        TicketID => $Param{TicketID},
    );

    my $TicketType = $TemplateData{ArticleType}->{Value};

    # save selected fields in a new hash
    my %Template;
    for my $Field ( @Fields ) {
        $Template{$Field} = $TemplateData{$Field};
    }

    # get dump of the template
    my $TemplateDump = $Self->{LayoutObject}->JSONEncode( Data => \%Template );

    # save template
    my $TemplateID = $Self->{TemplateObject}->TemplateAdd(
        TemplateName => $Name,
        Template     => $TemplateDump,
        TicketType   => $TicketType,
        Comment      => $Param{Comment},
        UserID       => $Self->{UserID},
    );

    return q~<script type="text/javascript">//<![CDATA[
        window.opener.Core.UI.Popup.FirePopupEvent('Reload');
        window.close();
        //]]></script>~;
}

1;
