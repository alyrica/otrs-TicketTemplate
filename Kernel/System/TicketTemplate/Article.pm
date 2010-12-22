# --
# Kernel/System/TicketTemplate/Article.pm -
#       This is a plugin to make article fields available for templates
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: Article.pm,v 1.83 2010/09/01 07:50:22 bes Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketTemplate::Article;

use strict;
use warnings;

use Kernel::System::Ticket;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.83 $) [1];

=head1 NAME

Kernel::System::TicketTemplate::Article - article fields for ticket template lib

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
    use Kernel::System::TicketTemplate::Article;

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
    my $TemplateObject = Kernel::System::TicketTemplate::Article->new(
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

=item DataGet()

    my %Data = $ArticleObject->DataGet(
        TicketID => 123,
    );

=cut

sub DataGet {
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

    my %Article = $Self->{TicketObject}->ArticleFirstArticle(
        TicketID => $Param{TicketID},
    );

    my %Result;

    FIELD:
    for my $Field ( keys %Article ) {
        next FIELD if $Field eq 'ArticleID';

        my $NewName = ( $Field !~ m{ \A Article }xms ) ? 'Article' . $Field : $Field;
        $Result{$NewName} = $Article{$Field};
    }

    return %Result;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.83 $ $Date: 2010/09/01 07:50:22 $

=cut
