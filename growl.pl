use Purple;
use Data::Dumper;
%PLUGIN_INFO = (
    perl_api_version => 2,
    name => "Growl",
    version => "0.1",
    summary => "Use growl notification for messages.",
    description => "Use growl notification for messages.",
    author => "daniel\@netwalk.org",
    url => "http://pidgin.im",
    load => "plugin_load",
    # prefs_info => "prefs_info_cb",
    unload => "plugin_unload"
);
sub prefs_info_cb {
    # Get all accounts to show in the drop-down menu
    @accounts = Purple::Accounts::get_all();

    $frame = Purple::PluginPref::Frame->new();

    # $acpref = Purple::PluginPref->new_with_name_and_label(
    #     "/plugins/core/url_shorten/max_url_length", "Max length for url: ");
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
    Purple::Debug::info("growl", '================================================');
    Purple::Debug::info("growl", Dumper $account->get_protocol_id() );
    $msg =~ s/<[^>]+>//g;
    $msg =~ s/"/''/g;
    next if $msg =~ /\?OTR/;
    Purple::Debug::info("growl", Dumper $msg);
    my $buddy = Purple::Find::buddy($account, $who);
    $display_name = $buddy->get_alias() ||  $buddy->get_name();
    $display_name =~ s/"/''/g;
    system("growlnotify -t \"$display_name ($who)\" -m \"$msg\"");
    $_[2];
}

sub plugin_load {
    my $plugin = shift;
    Purple::Debug::info("growl", "Growl $PLUGIN_INFO{version} Loaded.\n");
    # A pointer to the handle to which the signal belongs
    my $convs_handle = Purple::Conversations::get_handle();

    # Connect the perl sub 'receiving_im_msg_cb' to the event
    # 'receiving-im-msg'
    Purple::Signal::connect($convs_handle, "receiving-im-msg",
        $plugin,
        \&receiving_im_msg_cb, 0);
}
sub plugin_unload {
    my $plugin = shift;
    Purple::Debug::info("growl", "Growl $PLUGIN_INFO{version} Unloaded.\n");
}
