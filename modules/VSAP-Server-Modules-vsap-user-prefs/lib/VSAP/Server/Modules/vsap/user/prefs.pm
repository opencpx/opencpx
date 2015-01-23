package VSAP::Server::Modules::vsap::user::prefs;

use 5.008001;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Spec::Functions qw(canonpath catfile);

use VSAP::Server::Modules::vsap::logger;
use VSAP::Server::Modules::vsap::sys::timezone;

our $VERSION = '0.01';

our %_ERR = ( UPREF_SAVE_FAILED         => 100,
              UPREF_BAD_TZ              => 101,
              UPREF_BAD_DT              => 104,
              UPREF_BAD_LOGOUT          => 105,
              UPREF_BAD_PREFS           => 106,
              UPREF_BAD_HFD             => 107,
              UPREF_BAD_PPP             => 108,
              UPREF_BAD_SP              => 109,
              UPREF_BAD_UPP             => 110,
              UPREF_BAD_SORT_PREF       => 111,
              UPREF_BAD_SORT_ORDER      => 112,
            );


our $PREFS   = '/user_preferences.xml';

our %U_PREFS = (
                 ## an Olson timezone string
                 time_zone   => [ VSAP::Server::Modules::vsap::sys::timezone::get_timezone(), qr(^\w+(\/\w+)*?$), $_ERR{UPREF_BAD_TZ} ],

                 ## any strftime(3) string
                 date_format => [ '%m-%d-%Y', undef, undef ],
                 time_format => [ '%l:%M',    undef, undef ],

                 ## time | date
                 dt_order    => [ 'time', qr(^(?:tim|dat)e$), $_ERR{UPREF_BAD_DT} ],

                 ## decimal integer in hours
                 logout      => [ 1, qr(^\d+$), $_ERR{UPREF_BAD_LOGOUT} ],

                 ## user list: users per page
                 users_per_page  => [ 25, qr(^\d+$), $_ERR{UPREF_BAD_UPP} ],

                 ## user list "sort by" criteria: primary sort preference and order
                 users_sortby  => [ 'domain', qr(^(login_id|domain|usertype|status|limit|used)$), $_ERR{UPREF_BAD_SORT_PREF} ],
                 users_order   => [ 'ascending', qr(^(?:a|de)scending$), $_ERR{UPREF_BAD_SORT_ORDER} ],

                 ## user list "sort by" criteria: secondary sort preference and order
                 users_sortby2 => [ 'login_id', qr(^(login_id|domain|usertype|status|limit|used)$), $_ERR{UPREF_BAD_SORT_PREF} ],
                 users_order2  => [ 'ascending', qr(^(?:a|de)scending$), $_ERR{UPREF_BAD_SORT_ORDER} ],

                 ## domain list: domains per page
                 domains_per_page  => [ 25, qr(^\d+$), $_ERR{UPREF_BAD_UPP} ],

                 ## domain list "sort by" criteria: primary sort preference and order
                 domains_sortby  => [ 'admin', qr(^(name|admin|status|usage)$), $_ERR{UPREF_BAD_SORT_PREF} ],
                 domains_order   => [ 'ascending', qr(^(?:a|de)scending$), $_ERR{UPREF_BAD_SORT_ORDER} ],

                 ## domain list "sort by" criteria: secondary sort preference and order
                 domains_sortby2 => [ 'name', qr(^(name|admin|status|usage)$), $_ERR{UPREF_BAD_SORT_PREF} ],
                 domains_order2  => [ 'ascending', qr(^(?:a|de)scending$), $_ERR{UPREF_BAD_SORT_ORDER} ],

                 ## file manager: pathname for file manager 'start path' (blank == user homedir)
                 fm_startpath     => [ '', undef, $_ERR{UPREF_BAD_SP} ],

                 ## file manager: show/hide hidden files by default
                 fm_hidden_file_default => [ 'hide', qr(^(?:hide|show)$), $_ERR{UPREF_BAD_HFD} ],

                 ## server administration: packages per page
                 sa_packages_per_page => [ '10', qr(^(?:10|25|50|100)$), $_ERR{UPREF_BAD_PPP} ],

               );

use constant UP_VAL => 0;
use constant UP_REG => 1;
use constant UP_ERR => 2;

##############################################################################

sub _build_dom {
    my $root_node = shift;
    my $chillun   = shift;
    my %keys      = map { $_ => 1 } ( $chillun ? grep { exists $U_PREFS{$_} } @$chillun : keys %U_PREFS );
    my $pref_file = shift;

    my $dom;
    if( -f $pref_file && -s _ ) {
        eval {
            my $parser = new XML::LibXML;
            $dom       = $parser->parse_file( $pref_file )
              or die;
        };

        ## FIXME: return or just continue?
        if( $@ ) {
            warn "Could not build DOM for $pref_file: $@\n";
            return;
        }
    }

  FIND_KEYS: for my $key ( sort keys %keys ) {
        my $value = '';

        ## lookup the node in the dom
        if( $dom and my ($node) = $dom->findnodes("/user_preferences/$key") ) {
            $value = $node->string_value;
        }

        ## FIXME: need to lookup the owner's values

        ## use the owner's values
#       elsif( read_owner( @owner_lookup ) ) {
#           $value = $owner->string_value
#       }

        ## get hard-coded defaults
        $value ||= $U_PREFS{$key}->[UP_VAL];

        $root_node->appendTextChild($key => $value);
    }
}

sub _write_dom {
    my $vsap  = shift;
    my $thing = shift;

    my $status_code = 0;

    return(0) unless ref($thing);

    ## load DOM from disk
    my $dom;
    my $filename = $vsap->{cpxbase} . $PREFS;
    if (-e "$filename") {
        eval {
            my $parser = new XML::LibXML;
            ($dom) = $parser->parse_file($vsap->{cpxbase} . $PREFS)->findnodes('/user_preferences');
        };
        if( $@ ) {
            ## FIXME: something went wrong... what happened?
            $dom = $vsap->{_result_dom}->createElement('user_preferences');
        }
    }
    else {
        $dom = $vsap->{_result_dom}->createElement('user_preferences');
    }

    ## make our DOM nice and fresh
    for my $key ( sort keys %U_PREFS ) {
        my $have_val = ( UNIVERSAL::isa($thing, 'UNIVERSAL') 
                         ? $thing->child($key) 
                         : exists $thing->{$key} );
        my $value    = ( UNIVERSAL::isa($thing, 'UNIVERSAL') 
                         ? ( $thing->child($key) ? $thing->child($key)->value : '')
                         : $thing->{$key} );
        my $pattern  = $U_PREFS{$key}->[UP_REG];
        my $error    = $U_PREFS{$key}->[UP_ERR];

        ## check the value of this key, if necessary (have $value and $pattern)
        if( $value && $pattern ) {
            unless( $value =~ $pattern ) {
                $vsap->error( $error => "Error in value for $key" );
                return($error);
            }
        }

        ## special case: value of start path must exist on system
        if ($value && ($key eq "fm_startpath")) {
            my $path;
            if ($vsap->{server_admin}) {
                $path = $value;
            }
            else {
                $path = catfile(abs_path((getpwuid($vsap->{uid}))[7]), $value);
            }
            $path = canonpath($path);
            unless (-e $path) {
                $vsap->error( $error => "start path must exist" );
                return($error);
            }
        }

        ## this node exists; update it (or leave it alone)...
        if( my ($node) = $dom->findnodes("./$key") ) {
            ## and we have a replacement value for it...
            if( $have_val ) {
                my $new = $vsap->{_result_dom}->createElement($key);
                $new->appendTextNode( $value );
                $dom->replaceChild( $new, $node );
            }
        }

        ## ... node does not exist; create one
        else {
            $dom->appendTextChild( $key => ( $have_val ? $value : $U_PREFS{$key}->[UP_VAL] ) );
        }
    }

    ## flush DOM to file (Why doesn't toFile() work? Because we don't have a valid XML file)
    ## FIXME: should have locks on this file
    my $new_prefs_path = $vsap->{cpxbase} . $PREFS . "_hot_pepper_sauce";
    open OPTIONS, ">" . $new_prefs_path
      or do {
          $vsap->error( $_ERR{UPREF_BAD_PREFS} => "Could not open prefs file: $!" );
          VSAP::Server::Modules::vsap::logger::log_error("Could not open prefs file: $!");
          return($_ERR{UPREF_SAVE_FAILED});
      };
    print OPTIONS $dom->toString(1) 
      or do {
          $vsap->error( $_ERR{UPREF_BAD_PREFS} => "Could not write to prefs file: $!" );
          VSAP::Server::Modules::vsap::logger::log_error("Could not write to prefs file: $!");
          return($_ERR{UPREF_SAVE_FAILED});
      };
    close OPTIONS;

    if (-z $new_prefs_path) {
        unlink($new_prefs_path);
        $vsap->error( $_ERR{UPREF_BAD_PREFS} => "Could not save prefs file: over quota" );
        VSAP::Server::Modules::vsap::logger::log_error("Could not save prefs file: over quota");
        return($_ERR{UPREF_SAVE_FAILED});
    }
    else {
        my $prefs_path = $vsap->{cpxbase} . $PREFS;
        rename($new_prefs_path, $prefs_path);
    }

    ## fixup cache
    if( my ($del) = $vsap->{_result_dom}->findnodes('/vsap/vsap/user_preferences') ) {
        $del->parentNode->removeChild($del);
        $vsap->{_user_prefs_loaded} = undef;
    }

    return(0);  ## success == 0
}

sub get_value {
    my $vsap = shift;
    my $key  = shift;
    my $reload = shift;

    my $user_prefs_loaded = 0;
    if( my ($node) = $vsap->{_result_dom}->findnodes('/vsap/vsap/user_preferences') ) {
        $user_prefs_loaded = 1;
    }

    if ( ! $user_prefs_loaded || $reload ) {
        VSAP::Server::Modules::vsap::user::prefs::load::handler($vsap);
        $vsap->{_user_prefs_loaded} = 1;
    }

    return $vsap->{_result_dom}->findvalue("/vsap/vsap/user_preferences/$key");
}

sub set_values ($$@) {
    my $vsap  = shift;
    my $dom   = shift;
    my %prefs = @_;

    unless( $vsap->{_user_prefs_loaded} ) {
        VSAP::Server::Modules::vsap::user::prefs::load::handler($vsap);
        $vsap->{_user_prefs_loaded} = 1;
    }
    _write_dom($vsap, \%prefs);
}

##############################################################################

package VSAP::Server::Modules::vsap::user::prefs::load;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;  ## not used

    my $root = $vsap->{_result_dom}->createElement('vsap');
    $root->setAttribute(type => 'user:prefs:load');

    my $up_node = $vsap->{_result_dom}->createElement('user_preferences');
    $up_node->appendTextChild( user => $vsap->{username} );
    $root->appendChild($up_node);

    VSAP::Server::Modules::vsap::user::prefs::_build_dom($up_node, undef, $vsap->{cpxbase} . $PREFS );

    $vsap->{_result_dom}->documentElement->appendChild($root);
    $vsap->{_user_prefs_loaded} = 1;

    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::prefs::fetch;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;

    my $root = $vsap->{_result_dom}->createElement('vsap');
    $root->setAttribute(type => 'user:prefs:fetch');

    my $prefs_node = $vsap->{_result_dom}->createElement('user_preferences');

    VSAP::Server::Modules::vsap::user::prefs::_build_dom( $prefs_node, 
                                                          [$xmlobj->children_names], 
                                                          $vsap->{cpxbase} . $PREFS );

    $root->appendChild($prefs_node);
    $vsap->{_result_dom}->documentElement->appendChild($root);
    return;
}

##############################################################################

package VSAP::Server::Modules::vsap::user::prefs::save;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;

    $vsap->{_user_prefs_loaded} = 0;

    my $status = "ok";
    my $failure_code = 0;
    $failure_code = VSAP::Server::Modules::vsap::user::prefs::_write_dom($vsap, $xmlobj);
    $status = "fail" if ($failure_code);

    my $root = $vsap->{_result_dom}->createElement('vsap');
    $root->setAttribute(type => 'user:prefs:save');
    $root->appendTextChild(status => $status);
    $root->appendTextChild(failure_code => $failure_code) if ($failure_code);
    $vsap->{_result_dom}->documentElement->appendChild($root);
    return;
}

##############################################################################

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::user::prefs - Perl extension for CPX preferences

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::user::prefs;

=head1 DESCRIPTION

The VSAP prefs module contains the packages needed to get and set user
preferences for the CPX Control Panel.

=head2 user:prefs:fetch

=head2 user:prefs:load

=head2 user:prefs:save

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
