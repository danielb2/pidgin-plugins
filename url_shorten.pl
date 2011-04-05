use Purple;
use Data::Dumper;
use LWP::Simple qw($ua get);
use XML::Simple;
use Regexp::Common qw /URI/;
%PLUGIN_INFO = (
    perl_api_version => 2,
    name => "URL shorten",
    version => "0.9b3",
    summary => "Shortens urls.",
    description => "Shortens urls. BETA: report bugs please.  support\@pidgin.im",
    author => "daniel\@netwalk.org",
    url => "http://pidgin.im",
    load => "plugin_load",
    prefs_info => "prefs_info_cb",
    unload => "plugin_unload"
);
sub prefs_info_cb {
    # Get all accounts to show in the drop-down menu
    @accounts = Purple::Accounts::get_all();

    $frame = Purple::PluginPref::Frame->new();

    $acpref = Purple::PluginPref->new_with_name_and_label(
        "/plugins/core/url_shorten/max_url_length", "Max length for url: ");
    $acpref->set_bounds(10,100);

    $frame->add($acpref);

    return $frame;
}
sub plugin_init {
    return %PLUGIN_INFO;
}
sub receiving_im_msg_cb {
    my ($account, $who, $msg, $conv, $flags) = @_;
    my $accountname = $account->get_username();
    Purple::Debug::info("url_shorten", Dumper $account->get_protocol_id() );
    Purple::Debug::info("url_shorten", Dumper $msg);
    return unless $msg =~ m|https?://|;
    $msg = "<msg>$msg</msg>";
    my @urls = find_urls( $msg, $account->get_protocol_id() );
    Purple::Debug::info("url_shorten", Dumper \@_);
    my @shorts;
    for my $url ( @urls ) {
        if (my $short = shorten($url)) { push @shorts, $short; }
    }
    $_[2] .= "\n" . join("\n",@shorts);
}
sub find_urls {
    my ( $msg, $protocol ) = @_;
    my $xml = XMLin($msg, ForceArray => 1);
    Purple::Debug::info("url_shorten", Dumper $xml);
    my @urls = ();
    if ( $protocol eq 'prpl-aim' ) {
        push @urls, find_urls_in_aim($xml);
    } elsif ( $protocol eq 'prpl-jabber' ) {
        push @urls, find_urls_in_jabber($xml);
    } else { # $protocol =~ /(msn|yahoo|icq)/
        push @urls, find_urls_in_text($msg);
    }
    return @urls;
}
sub find_urls_in_text {
    my ( $msg ) = @_;
    my (@urls) = ( $msg =~  /($RE{URI}{HTTP})/g );
    return @urls;
}
sub find_urls_in_aim {
    my ( $xml ) = @_;
    my @urls = ();
    # if there are urls, there will be here
    my $urls = $xml->{A}; # [0]{href};

    for my $content_href (@$urls) {
        push @urls, $content_href->{HREF};
    }
    return @urls;
}
sub find_urls_in_jabber {
    my ( $xml ) = @_;
    my @urls = ();
    # if there are urls, there will be here
    my $urls = $xml->{html}[0]{body}[0]{a}; # [0]{href};

    for my $content_href (@$urls) {
        push @urls, $content_href->{href};
    }
    return @urls;
}

sub plugin_load {
    my $plugin = shift;
    Purple::Debug::info("url_shorten", "URL shorten $PLUGIN_INFO{version} Loaded.\n");
    # A pointer to the handle to which the signal belongs
    my $convs_handle = Purple::Conversations::get_handle();

    # Preferences
    Purple::Prefs::add_none("/plugins/core/url_shorten");
    Purple::Prefs::add_int("/plugins/core/url_shorten/max_url_length", 50);

    # Connect the perl sub 'receiving_im_msg_cb' to the event
    # 'receiving-im-msg'
    Purple::Signal::connect($convs_handle, "receiving-im-msg",
        $plugin,
        \&receiving_im_msg_cb, "yyy");
}
sub plugin_unload {
    my $plugin = shift;
    Purple::Debug::info("url_shorten", "URL shorten $PLUGIN_INFO{version} Unloaded.\n");
}
sub shorten {
    $max_length = Purple::Prefs::get_int("/plugins/core/url_shorten/max_url_length");

    return 0 if length($_[0]) < $max_length;
    #my $long_url = uri_escape($_[0]);
    my $long_url = $_[0];
    #my $short = $ua->post("http://qurl.com/automate.php", { url => $long_url })->content;
    #my $short = $ua->post("http://tcbp.net/", { url => $long_url })->content;
    $response = $ua->post("http://tcbp.net/", { url => $long_url });
    my $short = '';
    if ( $response->is_success ) {
        $short = $response->content;
    } else { # just a backup option
        $short = $ua->post("http://qurl.com/automate.php", { url => $long_url })->content;
    }

    return "" if $short =~ /^ERROR/;
    return substr($_[0],0,17) . "... -> $short";
}
