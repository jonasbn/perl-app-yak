requires 'perl', '5.010';
requires 'JSON';                  # Not core
requires 'CryptX';                # Not core, provides Crypt::Digest::SHA256
requires 'Env';                   # Core since Perl 5
requires 'Data::Dumper';          # Core since Perl 5.005
requires 'File::Find';            # Core since Perl 5
requires 'List::MoreUtils';       # Not core
requires 'Term::ANSIColor';       # Core since 5.6.0
requires 'YAML::Tiny';            # Not core
requires 'Text::Gitignore';       # Not core
requires 'Getopt::Long';          # Core since Perl 5
requires 'File::Slurper';         # Not core
requires 'Data::Stack';           # Not core
requires 'Carp';
requires 'Readonly';
requires 'Cwd';
requires 'Class::Accessor';
requires 'FindBin';

on 'test' => sub {
    requires 'Test2::V0';                   # Not core
    requires 'Test::Script';                # Not core
    requires 'Test::Kwalitee', '1.21';      # From Dist::Zilla
    requires 'Pod::Coverage::TrustPod';     # From Dist::Zilla
    requires 'Test::Pod', '1.41';           # From Dist::Zilla
    requires 'Test::Pod::Coverage', '1.08'; # From Dist::Zilla
};
