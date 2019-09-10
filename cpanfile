requires 'JSON';                  # Not core
requires 'Crypt::Digest::SHA256'; # Not core, provides Crypt::Digest::SHA256
requires 'Env';                   # Core since Perl 5
requires 'Data::Dumper';          # Core since Perl 5.005
requires 'File::Find';            # Core since Perl 5
requires 'List::MoreUtils';       # Not core
requires 'Term::ANSIColor';       # Core since 5.6.0
requires 'YAML::Tiny';            #
requires 'Parse::Gitignore';      # Not core

on 'test' => sub {
    requires 'Test2::V0';
    requires 'Test::Script';
};
