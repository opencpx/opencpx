package VSAP::Server::Modules::vsap::mail;

use 5.008004;
use strict;
use warnings;

use Carp;
use Cwd ('getcwd');
use POSIX('uname');

use VSAP::Server::Modules::vsap::backup;
use VSAP::Server::Modules::vsap::globals;
use VSAP::Server::Modules::vsap::logger;

##############################################################################

our $VERSION = '0.12';

use constant LOCK_EX => 2;

our $POSTFIX        = $VSAP::Server::Modules::vsap::globals::POSTFIX_INSTALLED;
our $ALIASES        = $VSAP::Server::Modules::vsap::globals::MAIL_ALIASES;
our $GENERICSTABLE  = $VSAP::Server::Modules::vsap::globals::MAIL_GENERICS;
our $LOCALHOSTNAMES = $VSAP::Server::Modules::vsap::globals::MAIL_VIRTUAL_DOMAINS;
our $VIRTUSERTABLE  = $VSAP::Server::Modules::vsap::globals::MAIL_VIRTUAL_USERS;

our $PFSTR   = "%-39s %s";

our $DEBUG   = 0;


##############################################################################
# aliases
##############################################################################
#
# all_aliastable()
#
# load all alias table mappings, return as hash
#

sub all_aliastable
{
    my %aliastable = ();
    my ($lhs, $rhs);

    local $_;
    open AM, $ALIASES or return {};
    while( <AM> ) {
        next if /^\s*\#/;
        chomp;
        next unless (/^\s*(\S+):\s+(.+?)\s*$/);
        $lhs = $1;
        $rhs = $2;
        $rhs =~ s/\s+$//g;
        if ($rhs =~ /:include:(.*)/) {
            my $filename = $1;
            if (open(INCLUDE, "$filename")) {
                read(INCLUDE, $rhs, -s "$filename");
                close(INCLUDE);
                $rhs =~ s/\s+$//g;
                $rhs =~ s/\n/, /gm;
            }
        }
        while ($rhs =~ m#[,\\]$#) {
            $_ = <AM> || last;
            next if /^\s*\#/;
            chomp;
            # check for orphaned comma or backslash
            if (/^\s*(\S+):\s+(.+?)\s*$/) {
                $aliastable{$lhs} = $rhs;
                $lhs = $1;
                $rhs = $2;
                $aliastable{$lhs} =~ s/[,\\]$//;
            }
            else {
                s/^\s+//g;
                $rhs .= " $_";
            }
            $rhs =~ s/\s+$//g;
            last if ($rhs !~ m#[,\\]$#);
        }
        $aliastable{$lhs} = $rhs;
        $aliastable{$lhs} =~ s/[,\\]$//;
    }
    close AM;

    return \%aliastable;
}

##############################################################################
# generics
##############################################################################
#
# addr_genericstable()
#
# return address in genericstable for $user
#

sub addr_genericstable
{
    my $user = shift or return "";
    my $address = "";

    local $_;
    open GENT, $GENERICSTABLE or return "";
    while( <GENT> ) {
        next if /^\s*\#/;
        chomp;
        next unless /^\s*(\Q$user\E)\s+(.+?)\s*$/;
        $address = $2;
        last;
    }
    close GENT;

    return $address;
}

# ----------------------------------------------------------------------------
#
# all_genericstable()
#
# load all generic table mappings, return as hash
#

sub all_genericstable
{
    my %genericstable = ();

    local $_;
    open GENT, $GENERICSTABLE or return {};
    while( <GENT> ) {
        next if /^\#/;
        chomp;
        next unless /^\s*(\S+)\s+(.+?)\s*$/;
        $genericstable{$1} = $2;
    }
    close GENT;

    return \%genericstable;
}

##############################################################################
# virtmaps
##############################################################################
#
# addr_virtusertable()
#
# return list of LHS whose target is $addr
#

sub addr_virtusertable
{
    my $addr = shift or return [];
    my @virtusertable = ();


    local $_;
    open VM, $VIRTUSERTABLE
      or return [];
    while( <VM> ) {
        next if /^\s*\#/;
        chomp;
        next unless /^\s*(\S+)\s+\Q$addr\E$/;
        push @virtusertable, $1;
    }
    close VM;

    return \@virtusertable;
}

# ----------------------------------------------------------------------------
#
# all_virtusertable()
#
# load all virtusertable address mappings, return as hash
#

sub all_virtusertable
{
    my %virtusertable = ();

    local $_;
    open VM, $VIRTUSERTABLE
      or return {};
    while( <VM> ) {
        next if /^\#/;
        chomp;
        next unless /^\s*(\S+)\s+(.+?)\s*$/;
        $virtusertable{$1} = $2;
    }
    close VM;

    return \%virtusertable;
}

# ----------------------------------------------------------------------------
#
# dest_virtusertable()
#
# return target RHS whose source is $lhs
#

sub dest_virtusertable
{
    my $lhs = shift or return [];
    my $rhs = "";


    local $_;
    open VM, $VIRTUSERTABLE
      or return [];
    while( <VM> ) {
        next if /^\s*\#/;
        chomp;
        next unless /^\s*\Q$lhs\E\s+(\S+)$/;
        $rhs = $1;
        last;
    }
    close VM;

    return $rhs;
}

# ----------------------------------------------------------------------------
#
# domain_virtusertable()
#
# return hashref of (addresses => targets) for LHS in this domain
#

sub domain_virtusertable
{
    my $domain = shift or return {};
    my %virtusertable = ();

    local $_;
    open VM, $VIRTUSERTABLE
      or return {};
    while( <VM> ) {
        next if /^\#/;
        chomp;
        next unless /^([^\@]*\@\Q$domain\E)\s+(.+?)\s*$/;
         $virtusertable{$1} = $2;
    }
    close VM;

    return \%virtusertable;
}

# ----------------------------------------------------------------------------
#
# ref_virtusertable()
#
# return hashref of (addresses => targets) 
#     that use ~$addr as a reference to an alias entry
#

sub ref_virtusertable
{
    my $addr = shift or return {};
    my %virtusertable = ();

    local $_;
    open VM, $VIRTUSERTABLE
      or return {};
    while( <VM> ) {
        next if /^\s*\#/;
        chomp;
        next unless /^\s*(\S+)\s+(.+?~\Q$addr\E)\s*$/;
         $virtusertable{$1} = $2;
    }
    close VM;

    return \%virtusertable;
}

##############################################################################
#
# backup_system_file()
#
# backup a specified mail system mail, requires source file:
#
#  "aliases"       -> mail system alias file
#  "genericstable" -> mail system generics file
#  "domains"       -> mail system virtual domains file ("local-host-names")
#  "virtusertable" -> mail system virtual users file
#

sub backup_system_file
{
    my $file = shift;

    if ($file eq "aliases") {
        VSAP::Server::Modules::vsap::backup::backup_system_file($ALIASES);
    }
    elsif ($file eq "genericstable") {
        VSAP::Server::Modules::vsap::backup::backup_system_file($GENERICSTABLE);
    }
    elsif ($file eq "domains") {
        VSAP::Server::Modules::vsap::backup::backup_system_file($LOCALHOSTNAMES);
    }
    elsif ($file eq "virtusertable") {
        VSAP::Server::Modules::vsap::backup::backup_system_file($VIRTUSERTABLE);
    }
}

##############################################################################
#
# is_admin()
#
# return 1 if ($admin) is mail admin or domain admin for ($domain)
#

sub is_admin
{
    my $admin = shift;
    my $domain = shift;

    my $co = new VSAP::Server::Modules::vsap::config(username => $admin);
    my $domains = {};

    if ($co->mail_admin) {
        my $user_domain = $co->user_domain($admin);
        $domains = $co->domains(domain => $user_domain);
    }
    else {
        $domains = $co->domains(admin => $admin);
    }

    return grep {/^\Q$domain\E$/} keys(%{$domains});
}

##############################################################################

sub is_local
{
    my $addr = shift or return;

    $addr =~ s/[^a-zA-Z0-9\.\-_\@~]//g;  ## untaint

    my $mail;
    open MAIL, "echo /parse $addr | sendmail -bt|"
      or return;
    local $_;
    while( <MAIL> ) {
        next unless /^mailer local, user (.+)/;
        $mail = $1;
        last;
    }
    close MAIL;

    return $mail;
}

##############################################################################

sub domain_catchall
{
    my $domain   = shift;
    my $rhs = shift;
    my $alias;
    my $lhs = '@' . $domain;

    ## set a catchall for a domain

    ## Postfix defaults to a global reject.
    if( $POSTFIX ) {
        return( 1 ) if( $rhs =~ 'error:nouser' );
    }

    # if rhs is a list ...
    ## FIXME: The heuristic for determining whether to create an alias may
    ## FIXME: need to be revisited (e.g., for pipes, etc.). It should
    ## FIXME: be based on what's legal for virtusertable (very
    ## FIXME: restrictive) and put everything else into aliases
    ##
    ## NOTE: removed ($rhs =~ /\@/) for the benefit of ENH16706.  --rus.
    ##
    if ($rhs =~ /,/) {
      $alias = make_alias($lhs);
      add_alias_entry ($alias, $rhs);
      $rhs = $alias;
    }
    unless( -e $VIRTUSERTABLE ) {
        open VM, "> $VIRTUSERTABLE";
        close VM;
    }

    local $_;
    open VM, "+< $VIRTUSERTABLE"
      or return;
    flock VM, LOCK_EX
      or return;

    seek VM, 0, 2;
    my $last = tell VM;
    my @eof = ();
    seek VM, 0, 0;
    my $prev = tell VM;
    my $replace = 0;
  LINE: while( <VM> ) {
        ## find the existing catchall
        if( m!^\#*\s*\@$domain\s+!i ) {
            $last = $prev;
            $replace++;
            last LINE;
        }

        ## find a plain entry
        $last = tell VM
          if m!#*\s*[^\@]+\@$domain\s+!i;
        $prev = tell VM;
    }
    seek VM, $last, 0;      ## go to last found entry
    @eof = <VM>;            ## save the rest (if any)
    shift @eof if $replace; ## pop off the old catchall
    seek VM, $last, 0;      ## go back again
    printf VM "$PFSTR\n", $lhs, $rhs;
    print VM @eof;
    truncate VM, tell VM;
    close VM;

    # log notification of action to the message log
    my $action = ($replace) ? "replaced" : "added";
    VSAP::Server::Modules::vsap::logger::log_message("$action virtmap ($lhs => $rhs)");

    _makemaps();
    return 1;
}

##############################################################################
#
# list_domains()
#
# list for all domains for which user is an mail or domain admin
#

sub list_domains
{
    my $admin = shift;

    my $co = new VSAP::Server::Modules::vsap::config(username => $admin);
    my $domains = {};

    if ( $co->mail_admin ) {
        my $user_domain = $co->user_domain($admin);
        $domains = $co->domains(domain => $user_domain);
    }
    else {
        $domains = $co->domains(admin => $admin);
    }

    return keys(%{$domains});
}

##############################################################################

sub add_entry
{
    my $rtn = 1;
    my $lhs = shift;
    my $rhs = shift;
    my $domain;
    my $alias;
    ($domain = $lhs) =~ s/^.*\@([\w\.-]+)\s*/$1/;

    unless( -e $VIRTUSERTABLE ) {
        open VM, "> $VIRTUSERTABLE";
        close VM;
    }

    # keep track of path to :include: file if exist (BUG28665)
    my $old_include_path = "";

    ## delete alias (BUG05124)
    $old_include_path = delete_alias_entry(make_alias($lhs));

    # if rhs is a list ...
    ## FIXME: The heuristic for determining whether to create an alias may
    ## FIXME: need to be revisited (e.g., for pipes, etc.). It should
    ## FIXME: be based on what's legal for virtusertable (very
    ## FIXME: restrictive) and put everything else into aliases
    ##
    ## NOTE: removed ($rhs =~ /\@/) for the benefit of ENH16706.  --rus.
    ##
    if (($rhs =~ /,/) || ($rhs =~ /:/) || ($rhs =~ /\|/)) {
      $alias = make_alias($lhs);
      add_alias_entry($alias, $rhs, $old_include_path);
      $rhs = $alias;
    }

    local $_;
    open VM, "+< $VIRTUSERTABLE"
      or return;
    flock VM, LOCK_EX
      or return;

    seek VM, 0, 2;
    my $last = tell VM;
    my @eof = ();
    seek VM, 0, 0;
    my $prev = tell VM;
    my $catchall = 0;
    my $replace = 0;
  LINE: while( <VM> ) {
        # find matching entry
        if( m!^#*\s*\Q$lhs\E\s+!i ) {
            $last = $prev;
            $replace++;
            last LINE;
        }

        ## find the catchall
        $catchall = $prev
          if m!^\@$domain\s+!i;

        ## find a plain entry
        $last = tell VM
          if m!#*\s*[^\@]+\@$domain\s+!i;

        $prev = tell VM;
    }
    seek VM, ($catchall && ! $replace ? $catchall : $last), 0;
    @eof = <VM>;            ## save the rest (if any)
    shift @eof if $replace; ## pop off the old entry
    seek VM, ($catchall && ! $replace ? $catchall : $last), 0;

    printf VM "$PFSTR\n", $lhs, $rhs;
    print VM @eof;
    truncate VM, tell VM;
    close VM;

    # log notification of action to the message log
    my $action = ($replace) ? "replaced" : "added";
    VSAP::Server::Modules::vsap::logger::log_message("$action virtmap ($lhs => $rhs)");

    $rtn = _makemaps();

    return $rtn;
}

##############################################################################

sub update_entry
{
    my $lhs = shift;
    my $rhs = shift;
    my $domain;
    my $alias;
    ($domain = $lhs) =~ s/^.*\@([\w\.-]+)\s*/$1/;

    unless( -e $VIRTUSERTABLE ) {
        open VM, "> $VIRTUSERTABLE";
        close VM;
    }

    # keep track of path to :include: file if exist (BUG28665)
    my $old_include_path = "";

    ## delete alias (BUG05124)
    $old_include_path = delete_alias_entry(make_alias($lhs));

    ## is rhs a list?
    ## (see FIXME note in add_entry about alias heuristic)
    ###
    ## NOTE: removed ($rhs =~ /\@/) for the benefit of ENH16706.  --rus.
    ##
    if ($rhs =~ /,/) {
      $alias = make_alias($lhs);
      update_alias_entry($alias, $rhs, $old_include_path);
      $rhs = $alias;
    }

    local $_;
    open VM, "+< $VIRTUSERTABLE"
      or return;
    flock VM, LOCK_EX
      or return;

    seek VM, 0, 2;
    my $last = tell VM;
    my @eof = ();
    seek VM, 0, 0;
    my $prev = tell VM;
    my $replace = 0;
  LINE: while( <VM> ) {
        # find matching entry
        if( m!^#*\s*$lhs\s+!i ) {
            $last = $prev;
            $replace++;
            last LINE;
        }

        ## find a plain entry
        $last = tell VM
          if m!#*\s*[^\@]+\@$domain\s+!i;
        $prev = tell VM;
    }
    seek VM, $last, 0;      ## go to last found entry
    @eof = <VM>;            ## save the rest (if any)
    shift @eof if $replace; ## pop off the old entry
    seek VM, $last, 0;      ## go back again
    printf VM "$PFSTR\n", $lhs, $rhs;
    print VM @eof;
    truncate VM, tell VM;
    close VM;

    # log notification of action to the message log
    my $action = ($replace) ? "replaced" : "added";
    VSAP::Server::Modules::vsap::logger::log_message("$action virtmap ($lhs => $rhs)");

    _makemaps();

    return 1;
}

##############################################################################

sub change_domain
{
    my $user = shift;
    my $old_domain = shift;
    my $new_domain = shift;
    my $virtusertable;

    # get all possible virtusertable entries for this user
    my $lhs = addr_genericstable( $user );
    if ($lhs) {
        my $dest = dest_virtusertable($lhs);
        $virtusertable->{$lhs} = $dest if ($dest);
    }

    # add virtusertable entries that point to user
    foreach my $address (@{addr_virtusertable($user)}) {
        $virtusertable->{$address} = $user;
    }
    # add virtusertable entries that reference user
    my $reftable = ref_virtusertable($user);
    foreach my $address (keys(%{$reftable})) {
        $virtusertable->{$address} = $reftable->{$address};
    }

    my $aliases;
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $aliases = all_aliastable();
    }

    foreach $lhs (keys(%{$virtusertable})) {
        delete_entry($lhs);
        my $rhs;
        if ($virtusertable->{$lhs} =~ /~/) {
            $rhs = $aliases->{$virtusertable->{$lhs}};
        }
        else {
            $rhs = $virtusertable->{$lhs};
            ## not sure yet if next line is a good idea or not
            #$rhs =~ s/$old_domain/$new_domain/;
        }
        $lhs =~ s/$old_domain/$new_domain/;
        add_entry($lhs, $rhs);
    }
}

##############################################################################

sub delete_domain
{
    my $domain = shift;

    open VM, "+< $VIRTUSERTABLE"
      or return;
    flock VM, LOCK_EX
      or return;
    seek VM, 0, 0;

    local $_;
    my @vm     = ();
    my %domain = ();
    while( <VM> ) {
        if( /^([^\@]*\@\Q$domain\E)\s+(.+?)\s*$/ ) {
            $domain{$1} = $2;
        }
        else {
            push @vm, $_;
        }
    }

    seek VM, 0, 0;
    print VM @vm;
    truncate VM, tell VM;
    close VM;

    # log notification of action to the message log
    VSAP::Server::Modules::vsap::logger::log_message("removed all virtmaps for domain '$domain'");

    ## lookup items in aliases now
    for my $lhs ( keys %domain ) {
        if( $domain{$lhs} eq make_alias($lhs) ) {
            delete_alias_entry($domain{$lhs});
        }
    }

    _makemaps();

    return 1;
}

##############################################################################

sub delete_entry
{
    my $lhs = shift;

    local $_;
    open VM, "+< $VIRTUSERTABLE"
      or return;
    flock VM, LOCK_EX
      or return;

    seek VM, 0, 2;
    my $last = tell VM;
    my @eof = ();
    seek VM, 0, 0;
    my $prev = tell VM;
    my $replace = 0;
  LINE: while( <VM> ) {
        # find matching entry
        if( m!^#*\s*\Q$lhs\E\s+!i ) {
            $last = $prev;
            last LINE;
        }
        $prev = tell VM;
    }
    seek VM, $last, 0;      ## go to last found entry
    @eof = <VM>;            ## save the rest (if any)
    my $old = shift @eof;   ## pop off the old entry
    my $alias = make_alias($lhs);
    if ($old && $old =~ m!^#*\s*\Q$lhs\E\s+$alias!i ) {
      delete_alias_entry($alias);
    }
    seek VM, $last, 0;      ## go back again
    print VM @eof;
    truncate VM, tell VM;
    close VM;

    # log notification of action to the message log
    VSAP::Server::Modules::vsap::logger::log_message("deleted virtmap for '$lhs'");

    _makemaps();

    return 1;
}

##############################################################################

sub _loop_equal
{
    return unless @{$_[0]} == @{$_[1]};
    for (my $i = 0; $i < @{$_[0]}; $i++ ) {
        return if $_[0]->[$i] ne $_[1]->[$i];
    }
    return 1;
}

# ----------------------------------------------------------------------------

sub _delete_user
{
    my $user          = shift;
    my $aliases       = shift;
    my $virtusertable = shift;

    for my $line ( @$virtusertable ) {
        next unless $line;
        next unless $line =~ /^\s*(\S+)(\s+)(.+?)\s*$/;
        my $lhs   = $1;
        my $space = $2;
        my $rhs   = $3;

        next unless $rhs eq $user;
        undef $line;
        print STDERR "Recursing on vut $lhs\n" if $DEBUG;
        ($aliases, $virtusertable) = _delete_user($lhs, $aliases, $virtusertable);
        next;
    }

    for my $line ( @$aliases ) {
        next unless $line;
        next unless $line =~ /^\s*(\S+?)(:\s*)(.+?)\s*$/;
        my $lhs   = $1;
        my $space = $2;
        my $rhs   = $3;

        next unless $rhs =~ /\b\Q$user\E\b/;

        ## clean up middle/end of line
        $rhs =~ s/,\s*\Q$user\E\b//g;

        ## clean up beginning of line
        $rhs =~ s/^\b\Q$user\E,\s*//g;

        ## only user on this alias; recursively delete the alias too
        if( $rhs eq $user ) {
            undef $line;
            print STDERR "Recursing on alias $lhs\n" if $DEBUG;
            ($aliases, $virtusertable) = _delete_user($lhs, $aliases, $virtusertable);
            next;
        }

        $line = "${lhs}${space}${rhs}";
        $line .= "\n" unless substr($line, -1) eq "\n";  ## restore newline if necessary
    }

    return ($aliases, $virtusertable);
}

# ----------------------------------------------------------------------------

sub delete_user
{
    my $rtn = 0;
    my $user = shift;

    ##
    ## read in aliases
    ##
    open ALIASES, "+< $ALIASES"
      or do {
          warn "Unable to open $ALIASES: $!\n";
          return 1;
      };
    flock ALIASES, LOCK_EX
      or do {
          carp "Unable to get lock on aliases: $!\n";
          close ALIASES;
          return;
      };

    seek ALIASES, 0, 0;

    local $_;
    my @aliases = ();
    my $continue;
    while( <ALIASES> ) {
        ## skip comments, empty lines
        if( /^\s*\#/ || /^\s*$/ ) {
            unless( $continue ) {
                push @aliases, $_;
            }
            next;
        }

        if( $continue ) {
            if (/^\s*(\S+):\s+(.+?)\s*$/) {
                # trap for orphaned comma or backslash
                push @aliases, $_;
            }
            else {
                $aliases[$#aliases] .= $_;
            }
        }

        else {
            push @aliases, $_;
        }
        s/\s+$//g;
        $continue = ( /[,\\]$/ ? 1 : 0 );
    }

    ##
    ## read in virtusertable
    ##
    open VM, "+< $VIRTUSERTABLE"
      or do {
          warn "Unable to open $VIRTUSERTABLE: $!\n";
          close ALIASES;
          return 1;
      };
    flock VM, LOCK_EX
      or do {
          carp "Unable to get lock on virtusertable: $!\n";
          close ALIASES;
          close VM;
          return;
      };
    seek VM, 0, 0;
    my @virtusertable = <VM>;

    ## fixup aliases, virtusertables. SEND IN COPIES! If you send in
    ## refs to the original arrays, they will be modified in-place and
    ## our array equality check will fail.
    my ($aliases, $virtusertable) = _delete_user( $user, [my @c_a = @aliases ], [my @c_v = @virtusertable] );
    @$aliases       = grep { defined } @$aliases;
    @$virtusertable = grep { defined } @$virtusertable;

    ## compare old and new
  ARE_EQUAL: {
        last ARE_EQUAL unless _loop_equal(\@aliases,       $aliases);
        last ARE_EQUAL unless _loop_equal(\@virtusertable, $virtusertable);

        ## nothing has changed. Don't write out files
        close ALIASES;
        close VM;
        return 1;
    }

    ##
    ## write back out to aliases
    ##
    seek ALIASES, 0, 0;
    print ALIASES @$aliases;
    truncate ALIASES, tell ALIASES;
    close ALIASES;

    # log notification of action to the message log
    VSAP::Server::Modules::vsap::logger::log_message("scrubbed all occurrences of user '$user' from aliases file");

    _newaliases();

    ##
    ## write back out to virtusertable
    ##
    seek VM, 0, 0;
    print VM @$virtusertable;
    truncate VM, tell VM;
    close VM;

    # log notification of action to the message log
    VSAP::Server::Modules::vsap::logger::log_message("scrubbed all occurrences of user '$user' from virtmaps file");

    $rtn = _makemaps();

    return $rtn;
}

##############################################################################

sub delete_user_domain
{
    my $lhs = shift;
    my $domain = shift;
    my $primary_email = $lhs . '@' . $domain;

    open VM, "+< $VIRTUSERTABLE"
      or do {
          carp "unable to open vm [$!]";
          return;
      };

    flock VM, LOCK_EX
      or do {
        carp "Unable to get lock on virtusertable: $!\n";
        close VM;
        return;
      };

    seek VM, 0, 0;

    local $_;
    my @vm = ();
    my %users = ();
    while( <VM> ) {
       if(/^($primary_email)\s+(.+?)\s*$/) {
         $users{$1} = $2;
       }
       elsif (!( /^(@|postmaster@|root@|www@|apache@)/) && (/^(\S+)\s+($primary_email|$lhs)\s*$/)) {
           $users{$1} = $2;
       }
       elsif ((/^(@|postmaster@|root@|www@|apache@)/) && (/^(\S+\s+)($primary_email|$lhs)\s*$/)) {
           my $line = $1 . 'dev-null' . "\n";
           push @vm, $line;
       }
       else {
           push @vm, $_;
       }
    }

    seek VM, 0, 0;
    print VM @vm;
    truncate VM, tell VM;
    close VM;

    # log notification of action to the message log
    VSAP::Server::Modules::vsap::logger::log_message("scrubbed all occurrences of email '$primary_email' from virtmaps file");
    VSAP::Server::Modules::vsap::logger::log_message("scrubbing all occurrences of email '$primary_email' from aliases file");

    ## lookup items in aliases now
    for my $lhs_key ( keys %users ) {
      if( $users{$lhs_key} eq make_alias($lhs_key)) {
        delete_alias_entry($users{$lhs_key});
      }
    }

    ## check for user@domain as a member of lists in aliases file (ENH23664)
    my $aliases;
  REWT: {
        local $> = $) = 0;  ## regain privileges for a moment
        $aliases = all_aliastable();
    }
    foreach my $alias (keys(%{$aliases})) {
        next unless ($aliases->{$alias} =~ /$primary_email/);
        $aliases->{$alias} =~ s/^$primary_email(,\s+)?//;
        $aliases->{$alias} =~ s/(,\s+)?$primary_email//;
        if ($aliases->{$alias} =~ /[^,\s]/) {
            # not empty
            update_alias_entry($alias, $aliases->{$alias});
        }
        else {
            # empty
            delete_alias_entry();
        }
    }

    _makemaps();

    return 1;
}

##############################################################################

sub make_alias
{
    my $lhs = shift;
    my $alias = "";
    if ($lhs =~ /^\@(.+)$/) {
      my $domain = $1;
      $alias = "$domain~catchall__";
    }
    elsif ($lhs =~ /^([^@]+)\@(.+)$/) {
      my $addr = $1;
      my $domain = $2;
      $alias = "$domain~$addr";
    }
    return $alias;
}

##############################################################################

sub add_alias_entry
{
    my $alias = shift;
    my $rhs = shift;
    my $include_path = shift;

    my $domain;
    ($domain = $alias) =~ s/^.*\@([\w\.-]+)\s*/$1/;

    unless( -e $ALIASES ) {
        open VM, "> $ALIASES";
        close VM;
    }

    local $_;
    open ALIAS, "+< $ALIASES"
      or return;
    flock ALIAS, LOCK_EX
      or return;

    seek ALIAS, 0, 2;
    my $last = tell ALIAS;
    my @eof = ();
    seek ALIAS, 0, 0;
    my $prev = tell ALIAS;
    my $replace = 0;
    my $continue = 0;
  LINE: while( <ALIAS> ) {
        # find matching entry
        if ($continue) {
            if (/^\s*(\S+):\s+(.+?)\s*$/) {
                # trap for orphaned comma or backslash
                last LINE;
            }
            else {
                $replace++;  # increment line replace count
                s/\s*$//;
                $continue = ( /[,\\]$/ ? 1 : 0 );
                last LINE unless ($continue);
            }
        }
        elsif( m!^#*\s*$alias:\s+!i ) {
            $last = $prev;
            $replace++;
            s/\s*$//;
            $continue = ( /[,\\]$/ ? 1 : 0 );
            last LINE unless ($continue);
        }
        $prev = tell ALIAS;
    }
    seek ALIAS, $last, 0;      ## go to last found entry
    @eof = <ALIAS>;            ## save the rest (if any)
    if( $replace ) {    ## pop off the old entry
        shift @eof for (1..$replace);
    }
    seek ALIAS, $last, 0;      ## go back again
    printf ALIAS "$PFSTR\n", "$alias:", $rhs;
    print ALIAS @eof;
    truncate ALIAS, tell ALIAS;
    close ALIAS;

    # log notification of action to the message log
    my $action = ($replace) ? "replaced" : "added";
    VSAP::Server::Modules::vsap::logger::log_message("$action alias ($alias: $rhs)");

    _newaliases();

    return 1;
}

##############################################################################

sub update_alias_entry
{
    my $lhs = shift;
    my $rhs = shift;
    my $include_path = shift;

    my $alias;

    unless( -e $ALIASES ) {
        open VM, "> $ALIASES";
        close VM;
    }

    local $_;
    open ALIAS, "+< $ALIASES"
      or return;
    flock ALIAS, LOCK_EX
      or return;

    seek ALIAS, 0, 2;
    my $last = tell ALIAS;
    my @eof = ();
    seek ALIAS, 0, 0;
    my $prev = tell ALIAS;
    my $replace = 0;
    my $continue = 0;
  LINE: while( <ALIAS> ) {
        # find matching entry
        if ($continue) {
            if (/^\s*(\S+):\s+(.+?)\s*$/) {
                # trap for orphaned comma or backslash
                last LINE;
            }
            else {
                $replace++;  # increment line replace count
                s/\s*$//;
                $continue = ( /[,\\]$/ ? 1 : 0 );
                last LINE unless ($continue);
            }
        }
        elsif( m!^#*\s*$lhs:\s+!i ) {
            $last = $prev;
            $replace++;
            s/\s*$//;
            $continue = ( /[,\\]$/ ? 1 : 0 );
            last LINE unless ($continue);
        }
        $prev = tell ALIAS;
    }
    seek ALIAS, $last, 0;      ## go to last found entry
    @eof = <ALIAS>;            ## save the rest (if any)
    if( $replace ) {    ## pop off the old entry
        shift @eof for (1..$replace);
    }
    seek ALIAS, $last, 0;      ## go back again
    printf ALIAS "$PFSTR\n", "$lhs:", $rhs;
    print ALIAS @eof;
    truncate ALIAS, tell ALIAS;
    close ALIAS;

    # log notification of action to the message log
    my $action = ($replace) ? "replaced" : "added";
    VSAP::Server::Modules::vsap::logger::log_message("$action alias ($lhs: $rhs)");

    _newaliases();

    return 1;
}

##############################################################################

sub delete_alias_entry
{
    my $lhs = shift;

    # keep track of path to :include: file if exist (BUG28665)
    my $include_path = "";

    unless( -e $ALIASES ) {
        open VM, "> $ALIASES";
        close VM;
    }

    local $_;
    open ALIAS, "+< $ALIASES"
      or return;
    flock ALIAS, LOCK_EX
      or return;

    seek ALIAS, 0, 2;
    my $last = tell ALIAS;
    my @eof = ();
    seek ALIAS, 0, 0;
    my $prev = tell ALIAS;
    my $replace = 0;
    my $continue = 0;
  LINE: while( <ALIAS> ) {
        # find matching entry
        if ($continue) {
            if (/^\s*(\S+):\s+(.+?)\s*$/) {
                # trap for orphaned comma or backslash
                last LINE;
            }
            else {
                $replace++;  # increment line replace count
                s/\s*$//;
                $continue = ( /[,\\]$/ ? 1 : 0 );
                last LINE unless ($continue);
            }
        }
        elsif( m!^#*\s*$lhs:\s+!i ) {
            if (/:include:(.*)/) {
                ## remove external list (BUG25445)
                my $filename = $1;
                unlink($filename);
                $include_path = $filename;
                $include_path =~ s/[^\/]+$//g;
                $include_path =~ s/\/+$//g;
                $include_path = '/' unless ($include_path);
            }
            $last = $prev;
            $replace++;
            s/\s*$//;
            $continue = ( /[,\\]$/ ? 1 : 0 );
            last LINE unless ($continue);
        }
        $prev = tell ALIAS;
    }
    seek ALIAS, $last, 0;      ## go to last found entry
    @eof = <ALIAS>;            ## save the rest (if any)
    if( $replace ) {    ## pop off the old entry
        shift @eof for (1..$replace);
    }
    seek ALIAS, $last, 0;      ## go back again
    print ALIAS @eof;
    truncate ALIAS, tell ALIAS;
    close ALIAS;

    # log notification of action to the message log
    VSAP::Server::Modules::vsap::logger::log_message("deleted alias for '$lhs'");

    _newaliases();

    return($include_path);
}

##############################################################################

sub get_alias_rhs
{
    my $lhs = shift;

    local $_;
    open ALIAS, "< $ALIASES"
      or return;
    seek ALIAS, 0, 0;
    my $return;
    my $continue = 0;
    LINE: while( <ALIAS> ) {
        # find matching entry
        if ($continue) {
            if (/^\s*(\S+):\s+(.+?)\s*$/) {
                # trap for orphaned comma or backslash
                last LINE;
            }
            else {
                $return .= $_;
                s/\s*$//;
                $continue = ( /[,\\]$/ ? 1 : 0 );
                last LINE unless ($continue);
            }
        }
        elsif( m!^#*\s*$lhs:\s+(.+)\s*$!i ) {
            $return = $1;
            last LINE;
        }
    }
    close ALIAS;
    return $return;
}

##############################################################################

sub check_devnull
{
    unless( -e $ALIASES ) {
        open VM, "> $ALIASES";
        close VM;
    }

    local $_;
    open ALIAS, "+< $ALIASES"
      or return;
    flock ALIAS, LOCK_EX
      or return;
    seek ALIAS, 0, 0;
    my $found_null;
    my $found_bucket;
    my @file = ();
    LINE: while( <ALIAS> ) {
          if( ! $found_null && m!^\#*\s*dev\-null:\s! ) {
              $found_null = 1;
              s!^\#*\s*!!;
          }

          if( ! $found_bucket && m!^\#*\s*bit\-bucket:\s! ) {
              $found_bucket = 1;
              s!^\#*\s*!!;
          }

          push @file, $_;
    }

    unless ($found_null) {
        unless( $found_bucket ) {
            push @file, sprintf "$PFSTR\n", "bit-bucket:", "/dev/null";
        }
        push @file, sprintf "$PFSTR\n", "dev-null:", "bit-bucket";
        # log notification of action to the message log
        VSAP::Server::Modules::vsap::logger::log_message("added 'dev-null' entry to aliases file");
    }

    seek ALIAS, 0, 0;
    print ALIAS @file;
    truncate ALIAS, tell ALIAS;
    close ALIAS;

    _newaliases();

    return 1;
}

##############################################################################

## NOTE: this function modifies local-host-names but does NOT restart
## NOTE: sendmail. For changes to this file to take effect, sendmail
## NOTE: must be restarted.

sub localhostname
{
    my %args = @_;

    ## domain => 'foo.com'
    ## action => 'enable|disable|delete|add'

    return unless $args{domain};
    return unless $args{action} && $args{action} =~ /^(?:add|delete|enable|disable)$/;

    open LHN, "+< $LOCALHOSTNAMES"
      or return;
    flock LHN, LOCK_EX
      or return;
    seek LHN, 0, 0;
    my @lhn = <LHN>;

    my $added;
    for my $i ( 0 .. $#lhn ) {
        next unless $lhn[$i] =~ /^\#*\Q$args{domain}\E$/;
        if( $args{action} eq 'enable' ) {
            $lhn[$i] =~ s/^\#//go;
            last;
        }

        elsif( $args{action} eq 'disable' ) {
            last if $lhn[$i] =~ /^\#/o;
            $lhn[$i] = '#' . $lhn[$i];
            last;
        }

        elsif( $args{action} eq 'delete' ) {
            splice @lhn, $i, 1;
            last;
        }

        elsif( $args{action} eq 'add' ) {
            $added = 1;
            last;
        }
    }

    if( $args{action} eq 'add' ) {
        unless( $added ) {
            if (($#lhn == -1) || ($lhn[$#lhn] =~ m|\n$|)) {
                push @lhn, $args{domain} . '   ' . $args{domain} . "\n";
            }
            else {
                push @lhn, "\n" . $args{domain} . '   ' . $args{domain} . "\n";
            }
        }
    }

    seek LHN, 0, 0;
    print LHN @lhn;

    truncate LHN, tell LHN;
    close LHN;

    # log notification of action to the message log
    my $action = $args{action} . (($args{action} =~ /e$/) ? "d" : "ed");
    my $prep = ($action eq "added") ? "to" : ($action eq "deleted") ? "from" : "in";
    VSAP::Server::Modules::vsap::logger::log_message("$action hostname '$args{domain}' $prep domains file");
    system('/usr/sbin/postmap /etc/postfix/domains');
    return 1;
}

##############################################################################

sub genericstable
{
    my $rtn = 1;
    my %args = @_;

    ## action => 'delete'

    ## must have user
    return unless $args{user};

    ## have action, must be 'delete'
    if( $args{action} ) {
        return unless $args{action} eq 'delete';
    }

    ## no action, must have valid user and dest
    ## note: we can delete non-existent users because their passwd
    ## entry might have already been removed. We don't care.
    else {
        return unless getpwnam($args{user});
        return unless $args{dest};
    }

    unless( -e "$GENERICSTABLE" ) {
        open GENT, "> $GENERICSTABLE";
        close GENT;
        chmod 0640, "$GENERICSTABLE";
    }

    open GENT, "+< $GENERICSTABLE"
      or return;
    flock GENT, LOCK_EX
      or return;
    seek GENT, 0, 0;
    my @gent = <GENT>;

    my $done;
    for my $i ( 0 .. $#gent ) {
        next unless $gent[$i] =~ /^\Q$args{user}\E\s+/;

        if( $args{action} && $args{action} eq 'delete' ) {
            splice @gent, $i, 1;
            $done = 1;
            last;
        }

        $gent[$i] = sprintf("%s\t\t%s\n", $args{user}, $args{dest});
        $done = 1;
        last;
    }

    ## not a delete: assuming an 'add'
    unless( $args{action} ) {
        unless( $done ) {
            push @gent, sprintf("%s\t\t%s\n", $args{user}, $args{dest});
            $done = 1;
        }
    }

    ## write out changes
    if( $done ) {
        seek GENT, 0, 0;
        print GENT @gent;
        truncate GENT, tell GENT;
    }
    close GENT;

    # log notification of action to the message log
    if( $args{action} ) {
        VSAP::Server::Modules::vsap::logger::log_message("removed genericstable entry for user '$args{user}'");
    }
    else {
        VSAP::Server::Modules::vsap::logger::log_message("added genericstable entry for user ($args{user} => $args{dest})");
    }

    if( $done ) {
        $rtn = _genericstable();
    }

    return $rtn;
}

##############################################################################

sub _newaliases
{
    # now works the same for sendmail and postfix MTA
    VSAP::Server::Modules::vsap::logger::log_message("running newaliases() system command");
    system('newaliases >/dev/null 2>&1');
}

##############################################################################

sub _makemaps
{
    my $rtn;
    if ($POSTFIX) {
        VSAP::Server::Modules::vsap::logger::log_message("rebuilding virtusertable portmap");
        $rtn = system('/usr/sbin/postmap /etc/postfix/virtusertable');
        VSAP::Server::Modules::vsap::logger::log_message("rebuilding domains portmap");
        $rtn = system('/usr/sbin/postmap /etc/postfix/domains');
    }
    else {
        VSAP::Server::Modules::vsap::logger::log_message("rebuilding virtusertable hash db");
        $rtn = system("/usr/sbin/makemap hash ${VIRTUSERTABLE}.db < ${VIRTUSERTABLE}");
    }
    if ( $rtn ne 0 ) {
        return 0;
    }
    else {
        return 1;
    }
}

##############################################################################

sub _genericstable
{
    my $rtn;
    if ($POSTFIX) {
        VSAP::Server::Modules::vsap::logger::log_message("rebuilding genericstable portmap");
        $rtn = system('/usr/sbin/postmap /etc/postfix/genericstable');
    }
    else {
        VSAP::Server::Modules::vsap::logger::log_message("rebuilding genericstable hash db");
        $rtn = system("/usr/sbin/makemap hash ${GENERICSTABLE}.db < ${GENERICSTABLE}");
    }
    if ( $rtn ne 0 ) {
        return 0;
    }
    else {
        return 1;
    }
}

##############################################################################

sub rebuild
{
    _newaliases();
    _makemaps();
    _genericstable();
}

##############################################################################

sub restart
{
    VSAP::Server::Modules::vsap::logger::log_message("rebuilding mail maps");
    rebuild();
    VSAP::Server::Modules::vsap::logger::log_message("restarting mail service");
    if ($POSTFIX) {
        ## restart postfix
        system('/usr/sbin/postfix reload');
    }
    else {
        ## restart sendmail
        my $cwd = getcwd();
        chdir('/etc/mail');
        system('make restart 2>&1 >/dev/null');
        chdir($cwd);
    }
}

##############################################################################

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::mail - CPX VSAP module for managing mail

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::mail;
  blah blah blah

=head1 DESCRIPTION

=head2 is_local( $addr )

Returns the local username if the mail will be delivered locally.

=head2 genericstable( [action => delete,]
                      user   => $user,
                      [ dest => $addr )

Modifies sendmail's genericstable (F</etc/mail/genericstable>). The
genericstable sendmail feature (see sendmail documentation for more
details) rewrites outbound headers based on rules found in the
F<genericstable> file.

For true virtually hosted mail accounts, outbound mail envelope and
'From:' headers should be rewritten using the user's virtually hosted
domain, not the server hostname. 

If a locally subhosted user (their primary domain is not the server
hostname), AND they do not receive mail (via F<virtmaps>) at
username@hostname (where 'hostname' is the server hostname), and which
implies that the catchall for '@hostname' rejects mail, THEN the
locally subhosted user's name MUST appear in the genericstable:

    username            username@subhosteddomain.tld

Otherwise, their username will not be rewritten and sendmail's
submission daemon (as of 8.13.1) will write the envelope sender as
'username@hostname' and send it to sendmail's MTA (on the same
system). The MTA will try to lookup 'username@hostname' in the
virtusertable and find that that address is not valid and it will
reject the mail (and wind up in F<dead.letter> or go in to savemail:
panic) and the mail will be lost but no indication will be given to
the end user that something went wrong.

The B<genericstable> function, then, is responsible for adding,
editing, and removing entries from this file and regenerating the map
file (a Berkeley hash).

Permissions on the map file must be group smmsp readable, since
sendmail's mail submission daemon runs with those permissions.

Examples:

Add a new entry:

    genericstable( user => 'joe', dest => 'joe@joesdomain.com' );

Edit an entry:

    genericstable( user => 'joe', dest => 'joe@bobsdomain.com' );

Delete an entry:

    genericstable( user => 'joe', action => 'delete' );


=head1 SEE ALSO

vsap(1)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC

No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
