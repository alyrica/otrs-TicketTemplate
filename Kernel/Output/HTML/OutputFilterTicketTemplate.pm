# --
# Kernel/Output/HTML/OutputFilterTicketTemplate.pm
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: OutputFilterTicketTemplate.pm,v 1.26 2010/05/19 07:01:36 mg Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterTicketTemplate;

use strict;
use warnings;

use Kernel::System::TicketTemplate;
use Kernel::System::DB;
use Kernel::System::Time;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.26 $) [1];

=head1 NAME

Kernel::Output::HTML::OutputFilterTicketTemplate

=head1 SYNOPSIS

a output filter module specially for ticket templates 

=head1 PUBLIC INTERFACE

=over 4

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (qw(MainObject ConfigObject LogObject LayoutObject EncodeObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    $Self->{Action} = $Param{Action};

    # create needed objects
    $Self->{DBObject}       = Kernel::System::DB->new( %{$Self} );
    $Self->{TimeObject}     = Kernel::System::Time->new( %{$Self} );
    $Self->{TemplateObject} = Kernel::System::TicketTemplate->new( %{$Self} );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    if ( $Self->{Action} ne 'AgentTicketPhone' && $Self->{Action} ne 'AgentTicketEmail' ) {
        return 1;
    }

    # perhaps no output is generated
    if ( !$Param{Data} ) {
        die 'TicketTemplate: At the moment, your code generates no output!';
    }

    # do nothing if output is a attachment
    if (
        ${ $Param{Data} } =~ /^Content-Disposition: attachment;/mi
        || ${ $Param{Data} } =~ /^Content-Disposition: inline;/mi
        )
    {
        return 1;
    }

    # do nothing if it is a redirect
    if (
        ${ $Param{Data} } =~ /^Status: 302 Moved/mi
        && ${ $Param{Data} } =~ /^location:/mi
        && length( ${ $Param{Data} } ) < 800
        )
    {
        return 1;
    }

    if ( ${ $Param{Data} } !~ m{<html[^>]*>}msx ) {
        print STDERR "NOT AN HTML DOCUMENT\n";
        return 1;
    }

    # create select box
    my %Templates = $Self->{TemplateObject}->TemplateList(
    );

    my %TemplateData;
    for my $TemplateID ( keys %Templates ) {
        my %Template = $Self->{TemplateObject}->TemplateGet( TemplateID => $TemplateID );
        $TemplateData{$TemplateID} = $Template{TemplateName};
    }

    my $TemplateSelect = $Self->{LayoutObject}->BuildSelection(
        Data      => \%TemplateData,
        Name      => 'Template',
        HTMLQuote => 1,
    );

    # Put output in the TicketTemplate Container
    my $Output = $Self->{LayoutObject}->Output(
        TemplateFile => 'TicketFromTemplate',
        Data         => {
            TemplateSelect => $TemplateSelect,
        },
    );

    # include the fred output in the original output
    ${ $Param{Data} } =~ s{(<fieldset\s+class="TableLike">)}{$1\n$Output\n}mx;

    my $JSPath      = $Self->{ConfigObject}->Get('Frontend::WebPath');
    my $UseRichText = $Self->{ConfigObject}->Get('Frontend::RichText') ? ' = 1' : '';
    my $JSDirective = qq~
        <script type="text/javascript">var RichTextActivated$UseRichText;</script>
        <script type="text/javascript" src="${JSPath}js/TicketTemplate.Form.js"></script>
    ~;

    ${ $Param{Data} } =~ s{</body>}{$JSDirective</body>}xms;

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.26 $ $Date: 2010/05/19 07:01:36 $

=cut
