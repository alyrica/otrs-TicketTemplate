// --
// TicketTemplate.Form.js - provides functions for form handling
// Copyright (C) 2001-2010 OTRS AG, http://otrs.org/\n";
// --
// $Id: TicketTemplate.Form.js,v 1.9 2010/08/12 13:46:08 mg Exp $
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var TicketTemplate = TicketTemplate || {};

/**
 * @namespace
 * @exports TargetNS as TicketTemplate.Form
 * @description
 *      This namespace contains all form functions.
 */
TicketTemplate.Form = (function (TargetNS) {

    /**
     * @function
     * @description
     *      This function fills the form with the info from template 
     * @param JsonData - the tickettemplate as jsondata
     * @return nothing
     */
    TargetNS.FillForm = function (SelectValue) {
        var Infos = SelectValue.replace( /\d+\|\|/, '' );

        // parse json
        var JsonObject = jQuery.parseJSON( Infos );

        jQuery.each( JsonObject, function(i, val){
            var FieldName  = val["Field"];
            var FieldValue = val["Value"];

            $('#' + FieldName).val( FieldValue );
        }); 
    };

    return TargetNS;
}(TicketTemplate.Form || {}));
