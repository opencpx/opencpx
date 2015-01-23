package VSAP::Server::Modules::vsap::sys::crontab;

use 5.008004;
use strict;
use warnings;

our $VERSION = '0.01';

our %_ERR = ( ERR_SYS_CRON_PERM     => 100,
              ERR_SYS_CRON_READ     => 101,
              ERR_SYS_CRON_WRITE    => 102,
              ERR_SYS_CRON_SCHEDULE => 103,
              ERR_SYS_CRON_USER     => 104,
              ERR_SYS_CRON_COMMAND  => 105,
              ERR_SYS_CRON_ABLE     => 106,
              ERR_SYS_CRON_MAILTO   => 107,
            );

our $Crontab = '/etc/crontab';
our $Private_comment_re = qr(^\s*\#(?!\#)); # a # not followed by a hash or space

package VSAP::Server::Modules::vsap::sys::crontab::list;

use Config::Crontab 1.06;

sub handler {
    my $vsap    = shift;
    my $xmlobj  = shift;

    my $ct;
    if ($vsap->is_vps()) {
        # VPS check for server_admin
        unless( $vsap->{server_admin} ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            $ct = new Config::Crontab( -file => $Crontab, -system => 1 );
        }
    } 
    else {
        # SIG check for account owner.
        unless( $vsap->{userclass} eq 'owner' ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        $ct = new Config::Crontab;
        $ct->read;
    }

    unless( $ct ) {
        $vsap->error($_ERR{ERR_SYS_CRON_READ} => "Could not read system crontab: " . $ct->error);
        return;
    }

    ##
    ## for selecting individual blocks and events, comments, and
    ## variables in those blocks
    ##
    my %selected_blocks = ();
    my $have_selected_blocks   = 0;
    my $have_selected_events   = 0;
    my $have_selected_comments = 0;
    my $have_selected_env      = 0;

    for my $block_obj ( $xmlobj->children('block') ) {
        if( my $block_id = $block_obj->attribute('id') ) {
            $selected_blocks{ $block_id } = {};
            $have_selected_blocks         = 1;

            for my $event_obj ( $block_obj->children('event') ) {
                if( my $event_id = $event_obj->attribute('id') ) {
                    $selected_blocks{$block_id}->{event}->{$event_id} = 1;
                    $have_selected_events = 1;
                }
            }

            for my $comment_obj ( $block_obj->children('comment') ) {
                if( my $comment_id = $comment_obj->attribute('id') ) {
                    $selected_blocks{$block_id}->{comment}->{$comment_id} = 1;
                    $have_selected_comments = 1;
                }
            }

            for my $env_obj ( $block_obj->children('env') ) {
                if( my $env_id = $env_obj->attribute('id') ) {
                    $selected_blocks{$block_id}->{env}->{$env_id} = 1;
                    $have_selected_env = 1;
                }
            }
        }
    }
    ##

    my @blocks;
    my $block_id = 0;

    for my $block ( $ct->blocks ) {
        $block_id++;

        if ( $have_selected_blocks and ! exists $selected_blocks{ $block_id } ) {
            # We're looking for a specific set of blocks and this ain't one of them.
            next;
        }

        my @block_array = ();

        my $comment_id  = 0;
        my $env_id      = 0;
        my $event_id    = 0;

        my $seen_comment = 0;
        my $seen_mailto  = 0;
        my $event_count  = 0;

        for my $line ( $block->lines ) {
            if( UNIVERSAL::isa( $line, 'Config::Crontab::Comment' ) ) {
                $comment_id++;

                if ( $have_selected_comments and ! exists $selected_blocks{ $block_id }->{ comment }->{ $comment_id } ) {
                    # We're looking for a specific set of comments and this ain't one of them.
                    next;
                }

                next if $seen_comment; # We only want to display the first comment.

                my $comment = $line->data;
                next if $comment =~ $Private_comment_re; # Don't show private comments.
                $seen_comment++;
                $comment =~ s/^\s*\#+\s*//; # Strip leading spaces and hash marks.

                push @block_array, {
                    createElement  => 'comment',
                    setAttribute   => [ 'id', $comment_id ],
                    appendTextNode => $comment,
                };
            } elsif( UNIVERSAL::isa( $line, 'Config::Crontab::Env' ) ) {
                $env_id++;

                if ( $have_selected_env and ! exists $selected_blocks{ $block_id }->{ env }->{ $env_id } ) {
                    # We're looking for a specific set of env lines and this ain't one of them.
                    next;
                }

                next unless $line->name eq 'MAILTO'; # Web interface only cares about this one.
                next if $seen_mailto; # It's possible to have multiple env settings, but we aren't handling that.
                $seen_mailto++;

                my %line_hash = (
                    createElement => 'env',
                    setAttribute  => [ 'id', $env_id ],
                );

                for my $child qw( active name value ) {
                    push @{ $line_hash{ appendTextChild } }, [ $child, $line->$child ];
                }

                push @block_array, \%line_hash;
            } elsif( UNIVERSAL::isa( $line, 'Config::Crontab::Event' ) ) {
                $event_id++;

                if ( $have_selected_events and ! exists $selected_blocks{ $block_id }->{ events }->{ $event_id } ) {
                    # We're looking for a specific set of events and this ain't one of them.
                    next;
                }

                my $cron_user = $line->user;
                my $cron_uid  = getpwnam( $cron_user );
                # FIXME: should probably use cpx.conf user list here instead of uid
                next if $cron_uid < 500; # Web interface shouldn't support system users.

                $event_count++;

                my %line_hash = (
                    createElement => 'event',
                    setAttribute => [ 'id', $event_id ],
                );

                for my $child qw( active user command ) {
                    push @{ $line_hash{ appendTextChild } }, [ $child, $line->$child ];
                }

                if ( $line->special ) {
                    $line_hash{ schedule } = { appendTextChild => [ [ 'special', $line->special ] ] };
                } else {

                    for my $child qw( minute hour dom ) {
                        push @{ $line_hash{ schedule }->{ appendTextChild } }, [ $child, $line->$child ];
                    }

                    # Normalize month to numeric
                    my %month_lookup = qw(
                        jan 1 feb 2 mar 3 apr  4 may  5 jun 6
                        jul 7 aug 8 sep 9 oct 10 nov 11 dec 12
                    );

                    my $month_rx = join '|', keys %month_lookup;
                    ( my $month = $line->month ) =~ s/($month_rx)/$month_lookup{$1}/egi;
                    push @{ $line_hash{ schedule }->{ appendTextChild } }, [ 'month', $month ];

                    # Normalize dow to numeric
                    my %dow_lookup = qw( sun 0 mon 1 tue 2 wed 3 thu 4 fri 5 sat 6 7 0 );
                    my $dow_rx = join '|', keys %dow_lookup;
                    ( my $dow = $line->dow ) =~ s/($dow_rx)/$dow_lookup{$1}/egi;
                    push @{ $line_hash{ schedule }->{ appendTextChild } }, [ 'dow', $dow ];
                }

                push @block_array, \%line_hash;
            } else {
                next; # just ignore an unknown line?
            }
        }

        push @blocks, { $block_id => \@block_array } if $seen_mailto || $event_count;
    } ## end for my $block ( $ct->blocks )

    my $dom  = $vsap->{_result_dom};
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:crontab:list' );

    for my $b ( @blocks ) {
        my ( $block_id ) = keys %$b;
        my $block_array  = $b->{ $block_id };
        my $block_node = $dom->createElement('block');
        $block_node->setAttribute( id => $block_id );

        for my $line ( @$block_array ) {
            my $el = $line->{ createElement };
            my $line_node = $dom->createElement($el);
            $line_node->setAttribute( id => $line->{ setAttribute }[1] );

            if ( $el eq 'comment' ) {
                $line_node->appendTextNode( $line->{ appendTextNode } );
            } elsif ( $el eq 'env' ) {
                $line_node->appendTextChild( @$_ ) for @{ $line->{ appendTextChild } };
            } elsif ( $el eq 'event' ) {
                $line_node->appendTextChild( @$_ ) for @{ $line->{ appendTextChild } };
                my $schedule_node = $dom->createElement( 'schedule' );
                $schedule_node->appendTextChild( @$_ ) for @{ $line->{ schedule }{ appendTextChild } };
                $line_node->appendChild( $schedule_node );
            }

            $block_node->appendChild( $line_node );
        }
        $root->appendChild( $block_node );
    } ## end for my $b ( @blocks )

    $dom->documentElement->appendChild($root);
    return;
}

package VSAP::Server::Modules::vsap::sys::crontab::add;

use Config::Crontab 1.06;

sub handler {
    my $vsap    = shift;
    my $xmlobj  = shift;

    my $ct;
    if ($vsap->is_vps()) {
        # VPS check for server_admin
        unless( $vsap->{server_admin} ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            $ct = new Config::Crontab( -file => $Crontab, -system => 1 );
        }
    }

    ## Signature block
    else {
        # SIG check for account owner.
        unless( $vsap->{userclass} eq 'owner' ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }

        ## check for existing crontab
        my $empty_crontab;
        CHECK_EXISTING: {
              my $pid = open my $pipe_ct, '-|';
              unless( defined $pid ) {
                  ## Gaa! No fork! Deal with it
                  last CHECK_EXISTING;
              }

              if( $pid ) {
                  my $data = <$pipe_ct>;
                  if( $data && $data =~ /\bno crontab for\b/io ) {
                      $empty_crontab = 1;
                  }
              }

              else {
                  open my $oldout, ">&STDOUT";    ## System Programmer Haiku:
                  close STDOUT;                   ##   You may notice how
                  open STDERR, ">&", $oldout;     ## carelessly I'm avoiding
                  exec('crontab', '-l');          ##   return values here.
              }
          }

        $ct = new Config::Crontab;
      CREATE_CRONTAB: {
            if( $empty_crontab ) {
                ## fetch favorite TZ
                require VSAP::Server::Modules::vsap::server::users::prefs;
                last CREATE_CRONTAB if $@;

                my $tz = VSAP::Server::Modules::vsap::server::users::prefs::getTmpPrefs($vsap, 'timeZoneInfo') || 'GMT';
                $ct->first(new Config::Crontab::Block(-data => "TZ=$tz"));
            }

            else {
                $ct->read;
            }
        }
    }

    unless( $ct ) {
        $vsap->error($_ERR{ERR_SYS_CRON_READ} => "Could not read system crontab: " . $ct->error);
        return;
    }

    my @blocks = $ct->blocks;  ## this can be optimized for memory someday, but crontabs are small

    for my $block_obj ( $xmlobj->children('block') ) {
        my $block = new Config::Crontab::Block;
        my $old_block;

        ## get existing block, if it exists (otherwise, add new block)
        if( my $block_id = $block_obj->attribute('id') ) {
            if( defined $blocks[$block_id-1] ) {
                $old_block = $block = $blocks[$block_id-1];
            }
        }

        ## add new comments
        if( $block_obj->children('comment') ) {
            ## delete existing (non-hidden) comments from object
            $block->remove( $block->select( -type     => 'comment',
                                            -data_nre => $Private_comment_re ) );

            for my $comment ( map { $_->value } reverse $block_obj->children('comment') ) {
                next unless $comment;

                ## split comments with embedded newlines
                for my $comment_line ( reverse split /(?:\n\r|\r\n?|\r?\n)/, $comment ) {
                    $block->first( new Config::Crontab::Comment(-data => "## $comment_line") );
                }
            }
        }

        ## select the event blocks
        my @events = $block->select( -type => 'event' );

        ## set new event data now
        if( my $event_obj = $block_obj->child('event') ) {
            my $event = new Config::Crontab::Event;

             my $cron_user = $event_obj->child( 'user' )->value;
             my $cron_uid  = getpwnam( $cron_user );

            if ( $cron_uid < 500 ) {
                $vsap->error($_ERR{ERR_SYS_CRON_USER} => "Cannot run cron job as system user ($cron_user)");
                return;
            }

            my $old_event;
            if( defined $old_block ) {
                if( my $event_id = $event_obj->attribute('id') ) {
                    if( defined $events[$event_id-1] ) {
                        $old_event = $event = $events[$event_id-1];
                    }
                }
            }

            $event->system(1);
            $event->special( my $special = ( $event_obj->child('schedule')->child('special') 
                                             ? $event_obj->child('schedule')->child('special')->value 
                                             : undef ) );  ## do not accept old value as default
            $event->minute(  my $minute  = ( $event_obj->child('schedule')->child('minute') 
                                             ? $event_obj->child('schedule')->child('minute')->value 
                                             : ( $old_event ? $old_event->minute : undef ) ) );
            $event->hour(    my $hour    = ( $event_obj->child('schedule')->child('hour') 
                                             ? $event_obj->child('schedule')->child('hour')->value 
                                             : ( $old_event ? $old_event->hour : undef ) ) );
            $event->dom(     my $dom     = ( $event_obj->child('schedule')->child('dom') 
                                             ? $event_obj->child('schedule')->child('dom')->value 
                                             : ( $old_event ? $old_event->dom : undef ) ) );
            $event->month(   my $month   = ( $event_obj->child('schedule')->child('month')
                                             ? $event_obj->child('schedule')->child('month')->value
                                             : ( $old_event ? $old_event->month : undef ) ) );
            $event->dow(     my $dow     = ( $event_obj->child('schedule')->child('dow')
                                             ? $event_obj->child('schedule')->child('dow')->value
                                             : ( $old_event ? $old_event->dow : undef ) ) );
            $event->command( my $command = ( $event_obj->child('command')
                                             ? $event_obj->child('command')->value
                                             : ( $old_event ? $old_event->command : undef ) ) );

            ## check the data
            unless( defined($minute) && defined($hour) && defined($dom) && defined($month) && defined($dow) or
                    defined($special) ) {
                $vsap->error($_ERR{ERR_SYS_CRON_SCHEDULE} => "Missing or illegal schedule");
                return;
            }

            ## FIXME: more bounds checking on schedule here maybe

                if ($vsap->is_vps()) {
                    $event->user(    my $user    = ( $event_obj->child('user')
                                                     ? $event_obj->child('user')->value
                                                     : ( $old_event ? $old_event->user : undef ) ) );

                    unless( $user ) {
                        $vsap->error($_ERR{ERR_SYS_CRON_USER} => "Missing user");
                        return;
                    }

                    unless( defined(getpwnam($user)) ) {
                        $vsap->error($_ERR{ERR_SYS_CRON_USER} => "User '$user' does not exist");
                        return;
                    }
                }

            unless( $command ) {
                $vsap->error($_ERR{ERR_SYS_CRON_COMMAND} => "Missing command");
                return;
            }

            ## create the event object and add to end of block
            if( defined $old_event ) {
                $block->replace( $old_event => $event );
            }
            else {
                $block->last( $event );
            }
        }

        ## replace the old block with new block
        if( defined $old_block ) {
            $ct->replace($old_block, $block);
        }

        ## add new block to the crontab file
        else {
            $ct->last($block);
        }
    }

    ## 'write' contains a Carp::croak that needs to be trapped
    eval {
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            $ct->write;
        }
    };

    if( $@ ) {
        $vsap->error($_ERR{ERR_SYS_CRON_WRITE} => "Could not write crontab: " . $@);
        return;
    }

    my $dom  = $vsap->{_result_dom};
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:crontab:add' );
    $root->appendTextChild( status => 'ok' );
    $dom->documentElement->appendChild($root);
    return;
}

package VSAP::Server::Modules::vsap::sys::crontab::delete;

use Config::Crontab 1.06;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;

    my $ct;
    if ($vsap->is_vps()) {
        # VPS check for server_admin
        unless( $vsap->{server_admin} ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            $ct = new Config::Crontab( -file => $Crontab, -system => 1 );
        }
    } 
    else {
        # SIG check for account owner.
        unless( $vsap->{userclass} eq 'owner' ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        $ct = new Config::Crontab;
        $ct->read;
    }

    unless( $ct ) {
        $vsap->error($_ERR{ERR_SYS_CRON_READ} => "Could not read system crontab: " . $ct->error);
        return;
    }

    my @blocks = $ct->blocks;
    my $is_changed = 0;

    for my $block_obj ( $xmlobj->children('block') ) {
        my $block_id = $block_obj->attribute('id');
        next unless $block_id;

        ## normalize block id
        $block_id--;
        next if $block_id > $#blocks;
        next unless defined $blocks[$block_id];

        ## delete this block and move on
        unless( $block_obj->children ) {
            undef $blocks[$block_id];
            $is_changed = 1;
            next;
        }

        ## has children, delete those
        my @delete_these = ();

        for my $element_type qw( event env comment ) {
            for my $element_obj ( $block_obj->children($element_type) ) {
                my $element_id = $element_obj->attribute('id');
                next unless $element_id;
                $element_id--;  ## normalize

                my $count = 0;
              ELEMENT: for my $obj ( $blocks[$block_id]->select( -type => $element_type ) ) {
                    if( $count == $element_id ) {
                        $obj->flag('delete');
                        $is_changed = 1;
                        last ELEMENT;
                    }
                    $count++;
                }
            }
        }
    }

    if( $is_changed ) {
        my @new_blocks = ();
        for my $block ( @blocks ) {
            next unless defined $block;                             ## skip undef'd blocks
            $block->remove( $block->select( -flag => 'delete' ) );  ## remove deleted elements
            push @new_blocks, $block if $block;                     ## if we still have a block, push it
        }
        $ct->blocks( \@new_blocks );

        ## 'write' contains a Carp::croak that needs to be trapped
        eval {
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                $ct->write;
            }
        };

        if( $@ ) {
            $vsap->error($_ERR{ERR_SYS_CRON_WRITE} => "Could not write crontab: " . $@);
            return;
        }
    }

    my $dom  = $vsap->{_result_dom};
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:crontab:delete' );
    $root->appendTextChild( status => 'ok' );
    $dom->documentElement->appendChild($root);
    return;
}

package VSAP::Server::Modules::vsap::sys::crontab;

use Config::Crontab 1.06;

sub able {
    my $vsap   = shift;
    my $xmlobj = shift;
    my $able   = shift;

    unless ( $able =~ /^(?:en|dis)able$/ ) {
        $vsap->error($_ERR{ERR_SYS_CRON_ABLE} => "Unrecognized ability status received");
        return;
    }

    my $able_set = ( $able eq 'disable' ? 0 : 1 );

    my $ct;
    if ($vsap->is_vps()) {
        # VPS check for server_admin
        unless( $vsap->{server_admin} ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            $ct = new Config::Crontab( -file => $Crontab, -system => 1 );
        }
    } 
    else {
        # SIG check for account owner.
        unless( $vsap->{userclass} eq 'owner' ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        $ct = new Config::Crontab;
        $ct->read;
    }

    unless( $ct ) {
        $vsap->error($_ERR{ERR_SYS_CRON_READ} => "Could not read system crontab: " . $ct->error);
        return;
    }

    my @blocks = $ct->blocks;
    my $is_changed = 0;

    for my $block_obj ( $xmlobj->children('block') ) {
        my $block_id = $block_obj->attribute('id');
        next unless $block_id;

        ## normalize block id
        $block_id--;
        next if $block_id > $#blocks;
        next unless defined $blocks[$block_id];

        ## activate this block and move on
        unless( $block_obj->children ) {
            $blocks[$block_id]->active($able_set);
            $is_changed = 1;
            next;
        }

        ## has children, activate those
        my @activate_these = ();

        for my $element_type qw( event env comment ) {
            for my $element_obj ( $block_obj->children($element_type) ) {
                my $element_id = $element_obj->attribute('id');
                next unless $element_id;
                $element_id--;  ## normalize

                my $count = 0;
                for my $obj ( $blocks[$block_id]->select( -type => ($element_type ) ) ) {
                    if( $count == $element_id ) {
                        push @activate_these, $obj;
                    }
                    $count++;
                }
            }
        }

        next unless @activate_these;
        $_->active($able_set) for @activate_these;
        $is_changed = 1;
    }

    if( $is_changed ) {
        $ct->blocks( [ grep { defined $_ } @blocks ] );

        ## 'write' contains a Carp::croak that needs to be trapped
        eval {
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                $ct->write;
            }
        };

        if( $@ ) {
            $vsap->error($_ERR{ERR_SYS_CRON_WRITE} => "Could not write crontab: " . $@);
            return;
        }
    }

    my $dom  = $vsap->{_result_dom};
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:crontab:enable' );
    $root->appendTextChild( status => 'ok' );
    $dom->documentElement->appendChild($root);
    return;
}

package VSAP::Server::Modules::vsap::sys::crontab::enable;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    return VSAP::Server::Modules::vsap::sys::crontab::able($vsap, $xmlobj, 'enable');
}

package VSAP::Server::Modules::vsap::sys::crontab::disable;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;
    return VSAP::Server::Modules::vsap::sys::crontab::able($vsap, $xmlobj, 'disable');
}

package VSAP::Server::Modules::vsap::sys::crontab::env;

use Config::Crontab 1.06;
use Email::Valid;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;

    my $ct;
    if ($vsap->is_vps()) {
        # VPS check for server_admin
        unless( $vsap->{server_admin} ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            $ct = new Config::Crontab( -file => $Crontab, -system => 1 );
        }
    } 
    else {
        # SIG check for account owner.
        unless( $vsap->{userclass} eq 'owner' ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        $ct = new Config::Crontab;
        $ct->read;
    }

    unless( $ct ) {
        $vsap->error($_ERR{ERR_SYS_CRON_READ} => "Could not read system crontab: " . $ct->error);
        return;
    }

    my $dom  = $vsap->{_result_dom};
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:crontab:env' );

    my $is_changed;
    for my $env_obj ( $xmlobj->children('env') ) {
        next unless $env_obj->child('name');
        my $name = $env_obj->child('name')->value;

        my $env_node = $dom->createElement('env');
        $env_node->appendTextChild( name => $name );

        ## just a query
        my $env = ($ct->select( -type => 'env',
                                -name => $name ))[0];

        if( $env_obj->child('value') ) {

            # perform various checks on user supplied data
            if( $name =~ /MAILTO/i ) {
                my $mailto = ( $env_obj->child('value') && $env_obj->child('value')->value ) ?
                               $env_obj->child('value')->value : '';
                if ( $mailto =~ /\@/ ) {
                    unless( Email::Valid->address( $mailto ) ) {
                        my $details = Email::Valid->details();
                        $vsap->error($_ERR{ERR_SYS_CRON_MAILTO} => $details);
                        return;
                    }
                }
                elsif ( !defined($mailto) || ($mailto eq "") || 
                        ($mailto eq "''") || ($mailto eq "\"\"") ) {
                    # discard all task messages
                }
                else {
                    # validate local username
                    my $user = $mailto;
                    unless( defined(getpwnam($user)) ) {
                        $vsap->error($_ERR{ERR_SYS_CRON_MAILTO} => "User '$user' does not exist");
                        return; 
                    }

                }
            }

            unless( $env ) {
                $env = new Config::Crontab::Env( -name => $name );
                $ct->first(new Config::Crontab::Block(-lines => [$env]));
            }
            $env->value( $env_obj->child('value')->value );
            $ct->remove( $env ) unless( $env_obj->child('value')->value );
            $is_changed = 1;
        }


        $env_node->appendTextChild( value => ( $env ? $env->value : '' ) );
        $root->appendChild($env_node);
    }

    ## 'write' contains a Carp::croak that needs to be trapped
    if( $is_changed ) {
        eval {
          REWT: {
                local $> = $) = 0;  ## regain privileges for a moment
                $ct->write;
            }
        };

        if( $@ ) {
            $vsap->error($_ERR{ERR_SYS_CRON_WRITE} => "Could not write crontab: " . $@);
            return;
        }
        $root->appendTextChild('set_status', 'success');
    }

    $dom->documentElement->appendChild($root);
    return;
}

package VSAP::Server::Modules::vsap::sys::crontab::env::remove;

use Config::Crontab 1.06;

sub handler {
    my $vsap   = shift;
    my $xmlobj = shift;

    my $ct;
    if( $vsap->is_vps() ) {
        unless( $vsap->{server_admin} ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            $ct = new Config::Crontab( -file => $Crontab, -system => 1 );
        }
    }
    else {
        unless( $vsap->{userclass} eq 'owner' ) {
            $vsap->error($_ERR{ERR_SYS_CRON_PERM} => "You do not have permission to view the system crontab");
            return;
        }
        $ct = new Config::Crontab;
        $ct->read;
    }

    unless( $ct ) {
        $vsap->error($_ERR{ERR_SYS_CRON_READ} => "Could not read system crontab: " . $ct->error);
        return;
    }

    my $dom  = $vsap->{_result_dom};
    my $root = $dom->createElement('vsap');
    $root->setAttribute( type => 'sys:crontab:env:remove' );

    my $is_changed;
    for my $env_obj ( $xmlobj->children('name') ) {
        my $name = $env_obj->value
          or next;

        $ct->remove( ($ct->select( -type => 'env',
                                   -name => $name ))[0] );
        $is_changed = 1;

        $root->appendTextChild( name => $name );
    }

    if( $is_changed ) {
        eval {
            if( $vsap->is_vps() ) {
              REWT: {
                    local $> = $) = 0;  ## regain privileges for a moment
                    $ct->write;
                }
            }
            else {
                $ct->write;
            }
        };

        if( $@ ) {
            $vsap->error( $_ERR{ERR_SYS_CRON_WRITE} => "Could not wrte crontab: " . $@);
            return;
        }
        $root->appendTextChild('set_status', 'success');
    }

    $dom->documentElement->appendChild($root);
    return;
}

1;
__END__

=head1 NAME

VSAP::Server::Modules::vsap::sys::crontab - VSAP module for managing crontabs

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::sys::crontab;


=head1 DESCRIPTION

The VSAP crontab module allows users to aggregate logically proximate
commands into "groups" and mark them with a comment if they wish.

=head2 sys:crontab:list

Listing the system crontab:

  <vsap type="sys:crontab:list"/>

returns:

  <vsap type="sys:crontab:list">
    <block id="1">...</block>
    ...
    <block id="3">
      <comment>rotate the logs</comment>
      <event id="1">
        <schedule>
          <minute>6</minute>
          <hour>0</hour>
          <dom>*</dom>
          <month>*</month>
          <dow>*</dow>
        </schedule>
        <user>barkus</user>
        <command>$HOME/bin/stats.sh >> $HOME/stats.out</command>
      </event>
    </block>

    <block id="4">
      <comment/>
      <event id="1">
        <schedule><special>@daily</special></schedule>
        <user>wilbur</user>
        <command>/usr/local/bin/savelogs --config=/usr/local/etc/foo.conf</command>
      </event>
    </block>
  </vsap>

Listing just a block (or multiple blocks):

  <vsap type="sys:crontab:list"><block id="4"/><block id="6"/></vsap>

Returns:

  <vsap type="sys:crontab:list">
    <block id="4">
      <comment>rotate the logs</comment>
      <event id="1">
        <schedule>
          <minute>6</minute>
          <hour>0</hour>
          <dom>*</dom>
          <month>*</month>
          <dow>*</dow>
        </schedule>
        <user>barkus</user>
        <command>$HOME/bin/stats.sh >> $HOME/stats.out</command>
      </event>

      <event id="2">
        <schedule>
          <minute>26</minute>
          <hour>1</hour>
          <dom>*</dom>
          <month>*</month>
          <dow>*</dow>
        </schedule>
        <user>barkus</user>
        <command>$HOME/bin/slaphappy.sh</command>
      </event>
    </block>

    <block id="6">
      ...
    </block>
  </vsap>

Listing a comment and an event in a block:

  <vsap type="sys:crontab:list"><block id="4"><comment id="1"/><event id="2"/></block></vsap>

Returns:

  <vsap type="sys:crontab:list">
    <block id="4">
      <comment id="1">This is the comment for this block</comment>
      <event id="2">
        <schedule>
          <minute>26</minute>
          <hour>1</hour>
          <dom>*</dom>
          <month>*</month>
          <dow>*</dow>
        </schedule>
        <user>barkus</user>
        <command>$HOME/bin/slaphappy.sh</command>
      </event>
    </block>
  </vsap>

=head2 sys:crontab:add

Add a new block to the crontab file

  <vsap type="sys:crontab:add">
    <block>
      <comment>run my stats every ten</comment>
      <comment>minutes all day, every day</comment>
      <event>
        <schedule>
          <minute>*/10</minute>
          <hour>*</hour>
          <dom>*</dom>
          <month>*</month>
          <dow>*</dow>
        </schedule>
        <user>www</user>
        <command>$HOME/bin/mystats.sh</command>
      </event>
    </block>
  </vsap>

Results:

The specified data is used to create a new cron event.

=head2 sys:crontab:add (event)

Add an event to an existing block.

  <vsap type="sys:crontab:add">
    <block id="4">
      <event>
        ...
      </event>
    </block>

The event will be added to the block identified in the id attribute.
If the specified block does not exist, a new block will be created
with an automatically assigned id. Previously added comments and
events will not be changed.

=head2 sys:crontab:add (editing existing entries)

Edit a crontab block or event by specifying an existing block and
event id.

  <vsap type="sys:crontab:add">
    <block id="2">
      <event id="4">
        <schedule><special>weekly</special></schedule>
        <user>wilbur</user>
        <command>$HOME/bin/mystats.sh</command>
      </event>
    </block>
  </vsap>

Changing a comment:

  <vsap type="sys:crontab:add">
    <block id="1">
      <comment>This is the new comment. It replaces all previous
      comment nodes (except private comments).</comment>
    </block>
  </vsap>

Private comments and other event data are left untouched. You may
embed newlines in the comment for a multi-line comment. This makes
handling data from HTML textareas easier from the XSLT side (i.e., you
don't have to split the comment and send multiple E<lt>commentE<gt>
nodes).

=head2 crontab:delete

Delete one or more crontab entries.

  <vsap type="sys:crontab:delete">
    <block id="2"><event id="3"/></block>
    <block id="5"><event id="1"/></block>
    <block id="6"/>
  </vsap>

Results:

The identified blocks or entries within blocks are removed.

=head2 crontab:enable

Enable one or more crontab entries or blocks.

  <vsap type="sys:crontab:enable">
    <block id="3">
      <event id="2"/>
      <event id="4"/>
    </block>
    <block id="5"/>
  </vsap>

=head2 crontab:disable

Disable a crontab event or block. Analogous to B<enable>.

=head2 crontab:env

Sets the first found instance of a named environment variable. If the
variable does not exist, it adds it to the end of the first block in
the crontab file.

  <vsap type="sys:crontab:env">
    <env>
      <name>MAILTO</name>
      <value>joe@schmoe.org</value>
    </env>
  </vsap>

This is a shortcut for:

  <vsap type="sys:crontab:add">
    <block id="1">
      <env>
        <name>MAILTO</name>
        <value>joe@schmoe.org</value>
      </env>
    </block>
  </vsap>

which isn't implemented yet. Querying an environment variable:

  <vsap type="sys:crontab:env">
    <env>
      <name>MAILTO</name>
    </env>
  </vsap>

returns:

  <vsap type="sys:crontab:env">
    <env>
      <name>MAILTO</name>
      <value>joe@schmoe.org</value>
    </env>
  </vsap>

=head2 crontab:move

Move an event from one block to another block.

NOT IMPLEMENTED

=head2 crontab:order

Reorder blocks or entries within blocks

NOT IMPLEMENTED

=head1 SEE ALSO

Config::Crontab(3)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
