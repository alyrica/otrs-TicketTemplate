# --
# Kernel/Language/de_TicketTemplate.pm - translation file
# Copyright (C) 2001-2011 OTRS AG, http://otrs.org/
# --
# $Id$
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_TicketTemplate;

use strict;

sub Data {
    my $Self = shift;

    # Template: AgentTicketTemplateForm
    $Self->{Translation}->{'Create Template from Ticket'} = 'Erzeuge ein Template aus dem Ticket';
    $Self->{Translation}->{'Template name is required.'} = 'Der Template-Name ist erforderlich.';
    $Self->{Translation}->{'Template name is required and has to be unique.'} = 'Der Template-Name muss angegeben werden und eindeutig sein.';
    $Self->{Translation}->{'Please select at least one field for the template.'} = 'Bitte wählen Sie mindestens 1 Feld für das Template';

    # Template: AgentTicketTemplateList
    $Self->{Translation}->{'Ticket Template Management'} = 'Verwaltung der Ticket-Templates';

    # Template: TicketFromTemplate
    $Self->{Translation}->{'Template'} = 'Template';

    # SysConfig
    $Self->{Translation}->{'Activate TicketTemplate output filter.'} = 'Aktiviere den Ausgabefilter von TicketTemplate.';
    $Self->{Translation}->{'Activates the AgentTicketTemplate module for the frontend.'} = 'Aktiviere das Frontend-Modul AgentTicketTemplate.';
    $Self->{Translation}->{'Allow the ArticleType field to be used in a ticket template.'} = 'Der Artikel-Typ kann für Templates verwendet werden.';
    $Self->{Translation}->{'Allow the Body field to be used in a ticket template.'} = 'Der Text kann für Templates verwendet werden.';
    $Self->{Translation}->{'Allow the CC field to be used in a ticket template.'} = 'CC kann für Templates verwendet werden.';
    $Self->{Translation}->{'Allow the Owner field to be used in a ticket template.'} = 'Der Besitzer kann für Templates verwendet werden.';
    $Self->{Translation}->{'Allow the Queue field to be used in a ticket template.'} = 'Die Queue kann für Templates verwendet werden.';
    $Self->{Translation}->{'Allow the State field to be used in a ticket template.'} = 'Der Status kann für Templates verwendet werden.';
    $Self->{Translation}->{'Allow the Subject field to be used in a ticket template.'} = 'Der Betreff kann für Templates verwendet werden.';
}

1;
