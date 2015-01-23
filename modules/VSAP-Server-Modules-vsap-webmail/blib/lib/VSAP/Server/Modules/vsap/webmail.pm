package VSAP::Server::Modules::vsap::webmail;

use 5.008001;
use strict;
use warnings;

## philosophically we are at odds with Mail::Cclient. Mail::Cclient
## has the concept of an open mailbox to which all methods apply. We
## have only the concept of a connection and you must specify folders,
## etc. This yields some performance hit but is easier to think about.
## People can always use Mail::Cclient! (via the {wm} element)

## do attachments
BEGIN {
        use POSIX('uname');
        use constant IS_LINUX => (POSIX::uname())[0] =~ /Linux/ ? 1 : 0;
        use constant VPS => (-d '/skel' || IS_LINUX) ? 1 : 0; 
}

#use Mail::Cclient ();
use Carp qw(carp);
use File::Find;
use File::Temp ();
use File::Spec::Functions qw(canonpath catfile);

our $VERSION = '0.21';

our %MAILBOXES = ();
our %STATUS    = ();
our @SEARCHED;
our $DEBUG     = 0;
our $LOG_MSG   = '';
our $DEBUG_MSG = '';

our $HOST = '{localhost/notls}';  ## NOTE: if you change this, change folder_status() also
our $MDIR = VPS ? 'Mail' : '';
our $PATH = IS_LINUX ? "" : "$MDIR/";
if ( isInstalledDovecot() ) {
    $MDIR = '';
    $PATH = '';
}
our @PARM = ();

#check to see if dovecot installer was ran or not
sub isInstalledDovecot {
    my $rCode = 0;
    my $cmd;
    #check to see if maildir is set up in the file
    if ( IS_LINUX ) {
        $cmd = '/sbin/chkconfig --list | grep -i dovecot | grep -i on > /dev/null 2>&1';
    } elsif ( VPS ) {
        $cmd = 'grep -i ^dovecot_enable=\"YES\" /etc/rc.conf > /dev/null 2>&1';
    }
    if ( ! system($cmd) ) {
        $rCode = 1;
    }
    return $rCode;
}

sub directory_create {
    my $self = shift;
    my $directory = shift;

    my $fullpath = canonpath(catfile($self->{_homedir}, $MDIR, $directory));
    system('mkdir', '-p', '--', $fullpath)
          and do {
              my $exit = ($? >> 8);
              $self->log("cannot mkdir '$fullpath' (exitcode $exit)");
              return 0;
          };
    return 1;
}

sub new {
    my $self     = { };
    my $class    = shift;
    bless $self, $class;

    my $username = shift;
    my $password = shift;
    my $userid;

    # for VPS it's the same as username, for SIG its whoever is the account owner. 
    if (VPS) { 
        $userid = $username;
    } else { 
        require VSAP::Server::Util;
        my $sysuid = syscall(&VSAP::Server::Util::SYS_getuid);
        $userid = (getpwuid($sysuid))[0];
    }

    ($self->{_uid}, $self->{_gid}) = (getpwnam($username))[2,3];

    $self->{_homedir} = VPS ? (getpwnam($username))[7] 
                : "/usr/home/$userid/users/$username/mail";

    $self->{_inboxpath} = VPS ?  "/var/mail/$username"
                : "/usr/home/$userid/users/$username/mail/INBOX";

    if (VPS) {
        my $mdirpath = canonpath(catfile($self->{_homedir}, $MDIR));
      REWT: {
            local $> = $) = 0;  ## regain privileges for a moment
            chown $self->{_uid}, $self->{_gid}, $mdirpath;
        }
    }

    Mail::Cclient::set_callback(
                                login => sub {
                                    return ($username, $password)
                                },
                                list  => sub {
                                    $_[2] =~ s!^.*\}!!;
                                    $_[2] =~ s!^$PATH!!;
                                    return unless $_[2];
                                    $MAILBOXES{$_[2]} = 1;
                                },
                                lsub  => sub {
                                    $_[2] =~ s!^.*\}!!;
                                    $_[2] =~ s!^$PATH!!;
                                    return unless $_[2];
                                    $MAILBOXES{$_[2]} = 1;
                                },
                                log   => sub {
                                    $LOG_MSG = shift;
                                    if( $DEBUG ) {
                                        system('logger', '-p', 'daemon.notice', "WM_LOG: $LOG_MSG");
                                    }
                                },
                                status => sub {
                                    $STATUS{$_[2]} = $_[3];
                                },
                                searched    => sub { push(@SEARCHED, $_[1]);  },
                               );

    if( $DEBUG ) {
        Mail::Cclient::set_callback(
                                    dlog  => sub {
                                        $DEBUG_MSG = shift;
                                        system('logger', '-p', 'daemon.notice', "WM_DLOG: $DEBUG_MSG");
                                    },
                                   );
    }

    ## USERNAME, HOMEDIR, LOCALHOST, SYSINBOX, OPENTIMEOUT,
    ## READTIMEOUT, WRITETIMEOUT, CLOSETIMEOUT, RSHTIMEOUT,
    ## SSHTIMEOUT, SSLFAILURE, MAXLOGINTRIALS, LOOKAHEAD, IMAPPORT,
    ## PREFETCH, CLOSEONERROR, POP3PORT, UIDLOOKAHEAD, MBXPROTECTION,
    ## DIRPROTECTION, LOCKPROTECTION, FROMWIDGET, NEWSACTIVE,
    ## NEWSSPOOL, NEWSRC, DISABLEFCNTLLOCK, LOCKEACCESERROR,
    ## LISTMAXLEVEL, ANONYMOUSHOME
    Mail::Cclient::parameters( undef,
                       RSHTIMEOUT     => 0,
                       SSHTIMEOUT     => 0,
                       OPENTIMEOUT    => 10,
                       READTIMEOUT    => 30,
                       WRITETIMEOUT   => 30,
                       CLOSEONERROR   => 1,
                       CLOSETIMEOUT   => 1,
                       MAXLOGINTRIALS => 1,
                     );

    ## NOTE: Reset @PARM so old objects' parameters don't affect
    ## NOTE: *this* object. Previous instantiations of webmail objects
    ## NOTE: were leaving their stuff in the @PARM global (e.g.,
    ## NOTE: 'readonly') which makes for problems if you don't want a
    ## NOTE: readonly mailbox.
    @PARM = ();
    push @PARM, 'debug' if $DEBUG;

    ## save away our parameters for later (e.g., folder_status)
    ## @_ contains any additional options such as 'readonly', etc.
    push @PARM, @_;

    ## NOTE: 'halfopen' is a safety feature dbrian found for bogus
    ## NOTE: INBOXes. You can't select a halfopen (no actual mailbox
    ## NOTE: is selected), but since we always check the active
    ## NOTE: mailbox before we try any operation on it, this will work
    ## NOTE: (Mail::Cclient::mailbox() returns '<no_mailbox>' on a
    ## NOTE: halfopen connection)
    
    $self->folder_open();
    return $self;
}

sub log {
    shift;
    if( @_ ) {
        $LOG_MSG = shift;
    }
    return $LOG_MSG;
}

## '%', '*', '#', '&' are listed in the RFC as valid but "hard to work
## with" characters for mailbox names. Atom-specials are also illegal:
##
## atom-specials   = "(" / ")" / "{" / SP / CTL / list-wildcards /
##                  quoted-specials / resp-specials
## list-wildcards  = "%" / "*"
## quoted-specials = DQUOTE / "\"
## resp-specials   = "]"
##
## here, then, is the complete list of illegal characters for IMAP
## (rfc 3501) mailbox names:
##
## "(" / ")" / "{" / SP / CTL / "%" / "*" / DQUOTE / "\" / "]"
sub folder_legal {
    my $self   = shift;
    my $folder = shift;

    return 1 if $folder eq 'INBOX';

    my $illegal = '(){%*]';  ## except backslash, DQUOTE, and SP
    if( $folder =~ m![\Q$illegal\E\\]! ) {  ## backslash tested here
        $self->log("Folder name contains illegal characters (RFC3501)");
        return;
    }

    if( $folder =~ /[[:cntrl:]]/ ) {
        $self->log("Folder name contains control characters (RFC3501)");
        return;
    }

    return 1;
}

sub folder_create {
    my $self = shift;
    my $folder = shift;
    return {} unless ref($self->{mc});
    return if $folder eq 'INBOX';
    return unless $self->folder_legal($folder);
    return $self->{mc}->create($HOST . $PATH . $folder);
}

sub folder_delete {
    my $self = shift;
    my $folder = shift;
    return if $folder eq 'INBOX';
    $self->folder_open('INBOX');  ## divert our stream to free $folder
    $self->{mc}->unsubscribe($HOST . $PATH . $folder);  ## unsubscribe as well
    return $self->{mc}->delete($HOST . $PATH . $folder);
}

sub folder_list {
    my $self = shift;
    return {} unless ref($self->{mc});
    %MAILBOXES = (INBOX => 1);
    $self->{mc}->list($HOST, $PATH . '*');   ## this goes as deep as we want ('%' does 1 dir)
    return \%MAILBOXES;
}

sub folder_list_subscribed {
    my $self = shift;
    return {} unless ref($self->{mc});
    %MAILBOXES = (INBOX => 1);
    $self->{mc}->lsub($HOST, '*');
    return \%MAILBOXES;
}

sub folder_open {
    my $self = shift;
    my $folder = shift || 'INBOX';
    my $rv;

    ## no, an eval wouldn't do anything here
    my $str = $HOST . ($folder eq 'INBOX' ? '' : $PATH) . $folder;
    my $open;
    if( ref($self->{mc}) ) {
        $open = $self->{mc}->open($str, @PARM);
    }

    ## NOTE: If open() failed, it's likely we've killed our imap
    ## NOTE: connection (doubly-so since we have CLOSEONERROR set).
    ## NOTE: Reconnect here (but still return undef for this mailbox).
    unless( $open ) {
        my $log = $LOG_MSG; ## save the error
        undef $self->{mc};  ## destroy the object
        $self->{mc} = Mail::Cclient->new( "${HOST}INBOX", (@PARM, 'halfopen') );
        $self->log($log);   ## put the error back
    }

    return $open;
}

sub folder_status {
    my $self = shift;
    my $folder = shift || 'INBOX';
    %STATUS = ();
    # my %folder_status 

    ## must always open the folder (even if already open) for status
    ## to see new stuff. No, ping() doesn't work as documented.
    $self->folder_open($folder)
       or return;
    $self->{mc}->check();
    $self->{mc}->status($self->{mc}->mailbox, $_ ) for qw(messages recent unseen);

    $STATUS{size} = 0;

    my($folder_path, $size, $dir); 
    if (isInstalledDovecot()) {
        ## this excludes the dovecot indexes for now, so that it can work 
        ## the same for INBOX as the rest of the folders.
        $folder_path = ($folder =~ /^INBOX$/i 
            ? "$self->{_homedir}/Maildir/"
            : "$self->{_homedir}/Maildir/.$folder/");
        $size = 0;
        $dir = $folder_path . "/cur";
        find( sub { -f and ( $size += -s _ ) }, $dir );
        my $size_command = "du -sk $folder_path/cur";
        $STATUS{size} = $size;
        $size = 0;
        $dir = $folder_path . "/new";
        find( sub { -f and ( $size += -s _ ) }, $dir );
        $STATUS{size} += $size;
    }
    else
    {
        $folder_path = ($folder =~ /^INBOX$/i
            ? $self->{_inboxpath}
            : "$self->{_homedir}/Mail/$folder");
        $size = 0;
        $dir = $folder_path;
        find( sub { -f and ( $size += -s _ ) }, $dir );
        $STATUS{size} = $size;
    }

    return \%STATUS;
}

sub folder_rename {
    my $self       = shift;
    my $folder     = shift;
    my $new_folder = shift;
    return if $folder     eq 'INBOX';
    return if $new_folder eq 'INBOX';
    return unless( $self->folder_legal($new_folder) );
    return $self->{mc}->rename($HOST . $PATH . $folder,
                               $HOST . $PATH . $new_folder);
}

sub folder_subscribe {
    my $self = shift;
    my $folder = shift;
    return {} unless ref($self->{mc});
    return if $folder eq 'INBOX';
    return unless $self->folder_legal($folder);
    return $self->{mc}->subscribe($HOST . $PATH . $folder);
}

sub folder_unsubscribe {
    my $self = shift;
    my $folder = shift;
    return {} unless ref($self->{mc});
    return if $folder eq 'INBOX';
    return unless $self->folder_legal($folder);
    return $self->{mc}->unsubscribe($HOST . $PATH . $folder);
}

sub messages_move_seq {
    my $self = shift;
    $self->messages_move(@_, 1);
}

sub messages_move {
    my $self = shift;

    my $msgs = shift;
    my $folder = shift;
    my $dest = shift;
    my $seq  = shift;

    ## an optimization
    my $active = undef;
    eval {
        $active = $self->{mc}->mailbox;
    };
    return if !$active;
    $active    =~ s!^.*\}!!;
    $active    =~ s!^$PATH!!;
    unless( $folder eq $active ) {
        $self->folder_open($folder)
          or return;
    }
    $self->{mc}->check();
    my $ret = $self->{mc}->move($msgs, ( $dest eq 'INBOX' ? '' : $PATH ) . $dest, ($seq ? () : 'uid'));
    return $ret unless $ret;
    $self->{mc}->expunge;
    return $ret;
}

sub messages_copy {
    my $self = shift;
    my $msgs = shift;
    my $folder = shift;
    my $dest = shift;
    my $seq  = shift;

    my $active = undef;
    eval {
        $active = $self->{mc}->mailbox;
    };
    return if !$active;
    $active    =~ s!^.*\}!!;
    $active    =~ s!^$PATH!!;
    unless( $folder eq $active ) {
        $self->folder_open($folder)
          or return;
    }
    $self->{mc}->check();

    return $self->{mc}->copy($msgs, ( $dest eq 'INBOX' ? '' : $PATH ) . $dest, ($seq ? () : 'uid'));
}

sub messages_sort {
    my $self      = shift;
    my $folder    = (@_ % 2 ? shift : 'INBOX');

    ## an optimization
    my $active = undef;
    eval {
        $active = $self->{mc}->mailbox;
    };
    return if !$active;
    $active    =~ s!^.*\}!!;
    $active    =~ s!^$PATH!!;
    unless( $folder eq $active ) {
        $self->folder_open($folder)
          or return [];
    }
    $self->{mc}->check();

    my %sort_keys = @_;
    if( defined $sort_keys{from_name} ) {
      my $uids = $self->{mc}->sort( SORT => [ (@_ ? @_ : (date => 1) ) ],
                                    FLAG => [ qw(uid noprefetch) ] );
      my @msgs = map { $self->message($folder, $_, 1) } @$uids;
      my @s_msgs; 

      # Here we try and sort by the personal name (which is the from name) but if that is not available
      # we sort by the from email address so that everything will be sorted in line and messages 
      # with no from name won't sink to the bottom. This is how many other mail clients perform
      # sorting on the from address. 

      if ($sort_keys{from_name} == 0) { 
         @s_msgs = sort { 
            lc($a->{from}->[0]->{personal} || ($a->{from}->[0]->{mailbox} || '') .'@'.($a->{from}->[0]->{domain} || '')) 
                cmp
            lc($b->{from}->[0]->{personal} || ($b->{from}->[0]->{mailbox} || '') .'@'.($b->{from}->[0]->{domain} || ''))}  @msgs; 
      } else { 
         @s_msgs = sort { 
            lc($b->{from}->[0]->{personal} || ($b->{from}->[0]->{mailbox} || '') .'@'.($b->{from}->[0]->{domain} || '')) 
                cmp
            lc($a->{from}->[0]->{personal} || ($a->{from}->[0]->{mailbox} || '') .'@'.($a->{from}->[0]->{domain} || ''))} @msgs; 
      }

      my @s_uids = map { $_->{uid} } @s_msgs;
      return \@s_uids; 
    } else {

      return $self->{mc}->sort( SORT => [ (@_ ? @_ : (date => 1) ) ],
                                FLAG => [ qw(uid noprefetch) ] );
    }
}

sub messages_delete {
    my $self   = shift;
    my $folder = shift;
    my $msgs   = shift;

    ## an optimization
    my $active = undef;
    eval {
        $active = $self->{mc}->mailbox;
    };
    return if !$active;
    $active    =~ s!^.*\}!!;
    $active    =~ s!^$PATH!!;
    unless( $folder eq $active ) {
        $self->folder_open($folder)
          or return;
    }
    $self->{mc}->check();

    $self->messages_flag($folder, $msgs, '\Deleted');
    $self->{mc}->expunge;
    1;
}

sub messages_flag {
    my $self    = shift;
    my $folder  = shift;  ## FIXME: default to active mailbox
    my $seq     = shift;
    my $flag    = shift;

    ## an optimization
    my $active = undef;
    eval {
        $active = $self->{mc}->mailbox;
    };
    return if !$active;
    $active    =~ s!^.*\}!!;
    $active    =~ s!^$PATH!!;
    unless( $folder eq $active ) {
        $self->folder_open($folder)
          or return;
    }
    $self->{mc}->check();

    return $self->{mc}->setflag($seq, $flag, 'uid');
}

sub message_save {
    my $self    = shift;
    my $folder  = shift;
    my $message = shift;

    return $self->{mc}->append($HOST . ($folder eq 'INBOX' ? '' : $PATH) . $folder, $message);
}

## returns the message in a hash
sub message {
    my $self        = shift;
    my $folder      = shift;
    my $uid         = shift;
    my $header_only = shift;

    ## an optimization
    my $active = undef;
    eval {
        $active = $self->{mc}->mailbox;
    };
    return if !$active;
    $active    =~ s!^.*\}!!;
    $active    =~ s!^$PATH!!;
    $self->folder_open($folder)
      unless $folder eq $active;
    $self->{mc}->check();
    $self->{mc}->search('SEARCH' => "ALL", "FLAG" => "peek");

    ##
    ## header only
    ##
    ## NOTE: fetch_structure will abort unless folder_open has been
    ## NOTE: called on this folder. fetch_structure will dump core if
    ## NOTE: $uid does not exist
    my($env,$body) = $self->{mc}->fetch_structure($uid, 'uid');
    my $elt  = $self->{mc}->elt( $self->{mc}->msgno($uid) );
    local $_;

    my %message = ();
    $message{uid}         = $uid;
    $message{date}        = $env->date;
    $message{flags}       = $elt->flags;

    $message{from}        = [];
    push @{$message{from}}, { personal => ( $_->personal ? $_->personal : '' ),
                              mailbox  => ( $_->mailbox  ? $_->mailbox  : '' ),
                              host     => ( $_->host     ? $_->host     : '' ), } 
      for @{$env->from};

    $message{to}          = [];
    push @{$message{to}}, { personal => ( $_->personal ? $_->personal : '' ),
                            mailbox  => ( $_->mailbox  ? $_->mailbox  : '' ),
                            host     => ( $_->host     ? $_->host     : '' ), }
      for @{$env->to};

    $message{cc}          = [];
    push @{$message{cc}}, { personal => ( $_->personal ? $_->personal : '' ),
                            mailbox  => ( $_->mailbox  ? $_->mailbox  : '' ),
                            host     => ( $_->host     ? $_->host     : '' ), }
      for @{$env->cc};

    $message{bcc}          = [];
    push @{$message{bcc}}, { personal => ( $_->personal ? $_->personal : '' ),
                             mailbox  => ( $_->mailbox  ? $_->mailbox  : '' ),
                             host     => ( $_->host     ? $_->host     : '' ), }
      for @{$env->bcc};

    $message{reply_to}          = [];
    push @{$message{reply_to}}, { personal => ( $_->personal ? $_->personal : '' ),
                             mailbox  => ( $_->mailbox  ? $_->mailbox  : '' ),
                             host     => ( $_->host     ? $_->host     : '' ), }
      for @{$env->reply_to};


    $message{rfc822_size} = $elt->rfc822_size;
    $message{subject} = $env->subject;

    ## return some indication of an attachment
    my $parsed;

    if( $header_only && $body->type eq "TEXT") {
        $message{numattachments} = 0;
    }

    ## full message request OR we have a multipart message we need to
    ## parse to find the number of attachments
    else {
        $message{attachments}    = [ _get_attachments($body, '') ];
        $message{numattachments} = scalar( grep { $_->{disposition} ne 'inline' } @{$message{attachments}} );
        $message{numinline} = scalar( grep { $_->{disposition} eq 'inline' } @{$message{attachments}} );
    }

  CLEAR_FLAGS: {
        my %flags = map { $_ => 1 } @{$message{flags}};
        $self->{mc}->clearflag( $uid, '\Seen', 'uid' ) unless $flags{'\Seen'};
    }

    ## return for header only
    if( $header_only ) {
        return \%message;
    }

    ##
    ## header + body
    ##
    $message{charset} = '';
    if( my $charset = _get_charset($body) ) {
        $message{charset} = $charset;
    }

    if( $body->type eq 'MULTIPART' ) {
        my ($partArray, $charset) = _get_text_body($self->{mc}, $self->{mc}->msgno($uid), $body);
        my @text_parts = @{$partArray};
        $message{body}->{'text/plain'}->{text}    = join("\n", @text_parts);
        $message{body}->{'text/plain'}->{charset} = $charset; ## FIXME

        ($partArray, $charset) = _get_html_body($self->{mc}, $self->{mc}->msgno($uid), $body);
        my @html_parts = @{$partArray};
        $message{body}->{'text/html'}->{text}    = join("\n", @html_parts);
        $message{body}->{'text/html'}->{charset} = $charset; ## FIXME
        $message{body}->{'text/html'}->{location} = _get_html_location($self->{mc}, $self->{mc}->msgno($uid), $body);
        $message{body}->{'text/html'}->{location} ||= $body->location;
    }

    ## not multipart
    else {
        my $type = lc($body->type) . '/' . lc($body->subtype);
        my $text = $self->{mc}->fetch_body( $self->{mc}->msgno($uid), "1" );
        $message{'content-transfer-encoding'} = lc($body->encoding);
        if( $body->encoding eq 'BASE64' ) {
            $text = Mail::Cclient::rfc822_base64($text);
            $message{'content-transfer-encoding'} = '8bit';
        }
        elsif( $body->encoding eq 'QUOTED-PRINTABLE' ) {
            $text = Mail::Cclient::rfc822_qprint($text);
            $message{'content-transfer-encoding'} = '8bit';
        }
        $message{body}->{$type} = { text    => $text,
                                    charset => _get_charset($body) };
    }

    return \%message;
}

sub message_raw {
    my $self = shift;
    my $uid  = shift;
    return $self->{mc}->fetch_message($uid, 'uid');
}

sub save_message_attachment_to_file {
    my $self        = shift;
    my $folder      = shift;
    my $uid         = shift;            ## message uid
    my $r_attach_id = shift;            ## attach_id
    my $path        = shift || '/tmp';  ## where to store the attachment

    unless( defined $r_attach_id ) {
        return;
    }

    ## an optimization
    my $active = undef;
    eval {
        $active = $self->{mc}->mailbox;
    };
    return if !$active;
    $active    =~ s!^.*\}!!;
    $active    =~ s!^$PATH!!;
    $self->folder_open($folder)
      unless $folder eq $active;
    $self->{mc}->check();

    my ($body, $part);

    (undef, $body) = $self->{mc}->fetch_structure($uid, 'uid');
    if( $r_attach_id ) {
        my %stp = _get_attachment_map($body, '');
        $part = $stp{$r_attach_id};
    }
    else {
        $part = $body;
    }
    return unless $part;

    ## if path is a directory, write file here (otherwise, just write to $path directly)
    my $filename = "";
    my $savepath = $path;
    if (-d $path) {
        $filename = _get_filename($part) || _get_inline_name($part) || lc($part->type) . '-' . lc($part->subtype);
        $filename =~ s/[^\w\.]//g;  ## remove evil spirits
        unless ($filename) {
            my $tmp_filename = new File::Temp(SUFFIX => '.tmp');
            $tmp_filename =~ s!/!!g;  ## slashes go bye-bye
            $filename = $tmp_filename;
        }
        use bytes;
        $savepath = $path . "/" . $filename;
        no bytes;
    }
    else {
        $savepath =~ m#.*/([^/]*)$#;
        $filename = $1;
    }

    ## do a fork here, write with child and exit
    defined(my $pid = open(READER, "-|"))
      or do {
          warn "Could not fork: $!\n";
          return;
      };
    local $SIG{PIPE} = 'IGNORE';
    if( $pid ) {
        while( <READER> ) { }
        close READER;
    }
    else {
        my $text;
        if( $r_attach_id ) {
          $text = $self->{mc}->fetch_body( $self->{mc}->msgno($uid), $r_attach_id );
        }
        else {
          $text = $self->{mc}->fetch_text( $self->{mc}->msgno($uid));
        }

        utf8::decode($savepath) if (utf8::is_utf8($savepath));
        if( open FILE, ">", $savepath ) {
            if( $part->encoding eq 'BASE64' ) {
                print FILE Mail::Cclient::rfc822_base64($text);
            }
            elsif( $part->encoding eq 'QUOTED-PRINTABLE' ) {
                print FILE Mail::Cclient::rfc822_qprint($text);
            }
            else {
                print FILE $text;
            }
            close FILE;
        }
        else {
            carp "Error writing file '$savepath': $!\n";
        }

        ## NOTE: we call SYS_exit here to kill our child
        ## NOTE: immediately, w/o any object cleanup (via
        ## NOTE: DESTROY) because that would close our cclient
        ## NOTE: object, and we need that in the parent.
        ## FIXME: 1 == SYS_exit; we should get this via
        ## FIXME: sys/syscall.ph but we forgot to run h2ph for
        ## FIXME: Perl 5.8.4. When we upgrade to 5.8.6,
        ## FIXME: uncomment the next 2 lines.
#        require 'sys/syscall.ph';
#        syscall( &SYS_exit, 0 );
        syscall(1, 0);  ## FIXME: remove this when we have syscall.ph built
    }

    my $mime_type = $part->type ? lc($part->type) . '/' . lc($part->subtype) : 'application/octet';

    return($filename, $mime_type);
}

sub _get_text_body {
    my $cc        = shift;
    my $msgno     = shift;
    my $parsed    = shift;
    my $section   = shift || '';
    my @text_body = ();

    my $charset = "";
    my $disposition = ( $parsed->disposition 
                        ? ( $parsed->disposition->[0]
                            ? ( $parsed->disposition->[0] =~ /^(inline|attachment)$/io 
                                ? lc($1)
                                : '' )
                            : '' )
                        : '' );

    if( $parsed->type eq 'MULTIPART' ) {
        my $subsection = 0;
        for my $part ( @{ $parsed->nested } ) {
            $subsection++;
            my $section_str = ( $section ? "$section.$subsection" : $subsection );
            my ($partArray, $currCharset) = _get_text_body($cc, $msgno, $part, $section_str);
            $charset = $currCharset if $currCharset;
            push @text_body, @{$partArray};
        }
    }

    ## all inline text parts, or all text parts w/o a filename will be displayed
    elsif( $parsed->type eq 'TEXT' && ($disposition eq 'inline' || ! _has_filename($parsed)) ) {
        if( $parsed->subtype eq 'PLAIN' ) {
            my $text = $cc->fetch_body($msgno, $section);
            if( $parsed->encoding eq 'BASE64' ) {
                $text = Mail::Cclient::rfc822_base64($text);
            }
            elsif( $parsed->encoding eq 'QUOTED-PRINTABLE' ) {
                $text = Mail::Cclient::rfc822_qprint($text);
            }
            push @text_body, $text;
            $charset = _get_charset($parsed);
        }
    }

    elsif( $parsed->type eq 'MESSAGE' ) {
        if( $parsed->nested ) {
            for my $part ( @{ $parsed->nested } ) {
                next unless UNIVERSAL::isa($part, 'Mail::Cclient::Body');
                my ($partArray, $currCharset) = _get_text_body($cc, $msgno, $part, $section);
                $charset = $currCharset if $currCharset;
                push @text_body, @{$partArray};
            }
        }
    }

    return (\@text_body, $charset);
}

sub _get_html_body {
    my $cc        = shift;
    my $msgno     = shift;
    my $parsed    = shift;
    my $section   = shift || '';
    my @html_body = ();

    my $charset = "";
    my $disposition = ( $parsed->disposition 
                        ? ( $parsed->disposition->[0]
                            ? ( $parsed->disposition->[0] =~ /^(inline|attachment)$/io 
                                ? lc($1)
                                : '' )
                            : '' )
                        : '' );

    if( $parsed->type eq 'MULTIPART' ) {
        my $subsection = 0;
        for my $part ( @{ $parsed->nested } ) {
            $subsection++;
            my $section_str = ( $section ? "$section.$subsection" : $subsection );
            my ($partArray, $currCharset) = _get_html_body($cc, $msgno, $part, $section_str);
            $charset = $currCharset if $currCharset;
            push @html_body, @{$partArray};
        }
    }

    ## all inline html parts, or all html parts w/o a filename will be displayed
    elsif( $parsed->type eq 'TEXT' && ($disposition eq 'inline' || ! _has_filename($parsed)) ) {
        if( $parsed->subtype eq 'HTML' ) {
            my $html = $cc->fetch_body($msgno, $section);
            if( $parsed->encoding eq 'BASE64' ) {
                $html = Mail::Cclient::rfc822_base64($html);
            }
            elsif( $parsed->encoding eq 'QUOTED-PRINTABLE' ) {
                $html = Mail::Cclient::rfc822_qprint($html);
            }
            push @html_body, $html;
            $charset = _get_charset($parsed);
        }
    }

    elsif( $parsed->type eq 'MESSAGE' ) {
        if( $parsed->nested ) {
            for my $part ( @{ $parsed->nested } ) {
                next unless UNIVERSAL::isa($part, 'Mail::Cclient::Body');
                my ($partArray, $currCharset) = _get_html_body($cc, $msgno, $part, $section);
                $charset = $currCharset if $currCharset;
                push @html_body, @{$partArray};
            }
        }
    }

    return (\@html_body, $charset);
}

sub _get_html_location {
    my $cc        = shift;
    my $msgno     = shift;
    my $parsed    = shift;
    my $section   = shift || '';
    my @location  = ();

    if( $parsed->type eq 'MULTIPART' ) {
        my $subsection = 0;
        for my $part ( @{ $parsed->nested } ) {
            $subsection++;
            my $section_str = ( $section ? "$section.$subsection" : $subsection );
            return _get_html_location($cc, $msgno, $part, $section_str);
        }
    }

    elsif( $parsed->type eq 'TEXT' && $parsed->subtype eq 'HTML' && ! _get_filename($parsed) ) {
        return $parsed->location;
    }

    elsif( $parsed->type eq 'MESSAGE' ) {
        if( $parsed->nested ) {
            for my $part ( @{ $parsed->nested } ) {
                next unless UNIVERSAL::isa($part, 'Mail::Cclient::Body');
                return _get_html_location($cc, $msgno, $part, $section);
            }
        }
    }

    return '';
}

sub _get_attachment_map {
    my $part    = shift;
    my $section = shift || '';
    my @stp = ();

    if( $part->nested ) {
        if( $part->type eq 'MULTIPART' ) {
            my $subsection = 0;
            for my $obj ( @{$part->nested} ) {
                $subsection++;
                my $section_str = ( $section ? "$section.$subsection" : $subsection );
                push @stp, _get_attachment_map($obj, $section_str);
            }
        }
        elsif( $part->type eq 'MESSAGE' ) {
            for my $obj ( @{$part->nested} ) {
                next unless UNIVERSAL::isa($obj, 'Mail::Cclient::Body');
                push @stp, _get_attachment_map($obj, $section);
            }
        }
        return @stp;
    }
    push @stp, $section, $part;
    return(@stp);
}

sub _get_attachments {
    my @attach  = ();
    my $part    = shift;
    my $section = shift || '';

    if( $part->nested ) {
        if( $part->type eq 'MULTIPART' ) {
            my $subsection = 0;
            for my $obj ( @{$part->nested} ) {
                $subsection++;
                my $section_str = ( $section ? "$section.$subsection" : $subsection );
                push @attach, _get_attachments($obj, $section_str);
            }
        }
        elsif( $part->type eq 'MESSAGE' ) {
            for my $obj ( @{$part->nested} ) {
                next unless UNIVERSAL::isa($obj, 'Mail::Cclient::Body');
                push @attach, _get_attachments($obj, $section);
            }
        }
        return @attach;
    }

    my ($filename, $filename_encoding) = _get_filename($part);
    $filename ||= _get_inline_name($part);
    my $disposition = _get_disposition($part);

    ## this is the inverse of the inline text test in _get_text_body()
    if( $part->type eq 'TEXT' ) {
        if( $disposition ne 'attachment' || ! _has_filename($part) ) {
            return @attach;
        }
    }

    $section = 0 if( $section eq '');
    push @attach, { attach_id   => $section,
                    name        => $filename,
                    name_encoding => $filename_encoding,
                    disposition => $disposition,
                    cid         => $part->id || '',
                    location    => $part->location || '',
                    discrete    => lc($part->type),
                    composite   => lc($part->subtype),
                    encoding    => lc($part->encoding),
                    size        => $part->bytes,
                  };

    return @attach;
}

sub _has_filename {
    my $body = shift;
    return unless UNIVERSAL::isa($body, 'Mail::Cclient::Body');

    my @disp = @{ $body->disposition };
    return unless $disp[0];

    my $type = '';
    if( $disp[0] =~ /^(inline|attachment)$/io ) {
        $type = lc(shift @disp);
    }

    my %disp = @disp;

    # concatenate FILENAME*[0-N]* to FILENAME* (BUG28668)
    my $index = 0;
    my $key = 'FILENAME*' . $index . '*';
    while ($disp{$key}) {
        $disp{'FILENAME*'} .= $disp{$key};
        $index++;
        $key = 'FILENAME*' . $index . '*';
    }

    my ($nameEncoding,$nameText);
    # If the filename passed is encoded using RFC2231, decode it here and
    # convert to UTF-8.
    $nameEncoding = $nameText = '';
    if ($disp{'FILENAME*'} || $disp{'filename*'}){ 
        my $fileName = $disp{'FILENAME*'} || $disp{'filename*'};
        $nameEncoding = $fileName;
        $nameEncoding =~ s/\'.*$//;
        $nameText = $fileName;
        $nameText =~ s/^[^\']*\'[^\']*\'//;
        $nameText =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        unless($nameEncoding =~ /utf\-?8'/i) {
            use Encode qw(find_encoding from_to);
            if(find_encoding($nameEncoding)) {
                from_to($nameText,$nameEncoding,'UTF-8');
            }
            else {
                $nameText = "cpx_webmail_attachment";
            }
        }
    }

    my $returnName = $disp{FILENAME} || $disp{filename} || $nameText || '';
    return wantarray ? ($returnName, $nameEncoding) : $returnName;
}

sub _get_filename {
    my $body = shift;
    if ( wantarray ) {
        my ($name, $encoding) = _has_filename($body);
        return ( defined $name 
                 ? $name || lc($body->type) . '-' . lc($body->subtype)
                 : undef , $encoding);
    }
    else {
        my $name = _has_filename($body);
        return ( defined $name 
                 ? $name || lc($body->type) . '-' . lc($body->subtype)
                 : undef );
    }
}

sub _get_disposition {
    my $part = shift;
    return ( $part->disposition 
             ? ( $part->disposition->[0]
                 ? ( $part->disposition->[0] =~ /^(inline|attachment)$/io 
                     ? lc($1)
                     : '' )
                 : '' )
             : '' );
}

sub _get_inline_name {
    my $body = shift;
    my %parms = @{ $body->parameter };
    return $parms{NAME} || $parms{name} || '';
}

sub _get_charset {
    my $body = shift;
    my %parms = @{ $body->parameter };
    return $parms{CHARSET} || $parms{charset} || '';
}

sub DESTROY {
    my $self = shift or return;
    if( defined $self->{mc} ) {
        $self->{mc}->gc("elt", "env", "texts");
        $self->{mc}->close;
    }
    delete $self->{mc};
}

## This is how we learned to close() our cclient connections.
## imapd sessions were not going away after Mail::Cclient object went
## out of scope. We also do garbage collection just to be safe.
## The following snippets helped find the errant processes and files:
#             print STDERR "ERROR: $LOG_MSG\n";
#             my $perl1 = q!perl -lane 'next unless $F[1] eq "imapd" and $F[3] =~ /^\d+$/; print $F[5]'!;
#             my $perl2 = q!perl -lne 'print `find /tmp -inum $_ -print0 2>/dev/null`'!;
#             print STDERR "FSTAT: " . `fstat | $perl1 | $perl2`;
#             my $ps = `cat /tmp/.d04.1ebc92a`;
#             print STDERR "DETAILS: " . $ps;
#             print STDERR "PS: " . `ps -ajx`;

1;

__END__

=head1 NAME

VSAP::Server::Modules::vsap::webmail - Wrapper for Mail::Cclient

=head1 SYNOPSIS

  use VSAP::Server::Modules::vsap::webmail;
  blah blah blah

=head1 DESCRIPTION

=head2 new( $username, $password [ PARAM, ... ] )

Opens INBOX and returns a webmail object.

Other parameters will be passed to Mail::Cclient (e.g., 'readonly').
Two are passed by default: 'shortcache' and 'debug'. NOTE:
'shortcache' was removed for Signature (core dumping imapd) but may
be replaced if imapd is upgraded.

Package variables $HOST and $PATH are set to '{localhost}' and
'~/Mail/' respectively.

=head2 log

returns the last error (as a string) produced by Mail::Cclient; status
messages also here during normal operation.

=head2 folder_open($folder)

opens Mail::Cclient stream on $folder; returns Mail::Cclient::open

=head2 folder_list()

returns hashref of folder names

=head2 folder_status($folder)

returns hashref of status of currently open folder

=head2 folder_create($folder)

creates a new folder in $PATH; returns Mail::Cclient::create

=head2 folder_rename($folder, $new_folder)

renames $folder to $new_folder; returns Mail::Cclient::rename

=head2 folder_delete($folder)

deletes $folder from $PATH; returns Mail::Cclient::delete

=head2 messages_move($seq, $src, $dest)

moves $seq messages from $src to $dest. $seq is a string list of UIDs
(e.g., "1,43,112").

=head2 messages_move_seq($seq, $src, $dest)

Just like messages_move, except $seq is treated as a sequence of
message numbers instead of uids.

=head2 messages_sort([$folder [, field1 => order1 [, ...]]])

Sorts $folder (default INBOX) on specified criteria (e.g., from => 1,
etc.) (default: date => 1). Returns a list reference.

Example:

  ## sort Trash using default '(date => 1)'
  $msgs = $wm->messages_sort('Trash');

  ## sort INBOX (default) using '(from => 1)'
  $msgs = $wm->messages_sort(from => 1);
  
  ## sort INBOX (default) using '(from_name => 1)'
  $msgs = $wm->messages_sort(from_name => 1);

=head2 message([$folder,] $msgno, $header_only)

Returns a hash reference containing the message contents. If
'$header_only' is a true value, only the message header will be
parsed.

=head2 messages_delete([$folder,] SEQUENCE)

Deletes messages by sequence number

E.g., messages_delete($m, "1,3")

=head2 messages_msgno($m, SORT => [ subject => 0, ... ])

Returns a hash reference of sequence => msgno using the SORT criteria
provided.

=head1 SEE ALSO

vsap::webmail::folders(3), vsap::webmail::messages(3)

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by MYNAMESERVER, LLC
 
No part of this module may be duplicated in any form without written
consent of the copyright holder.

=cut
