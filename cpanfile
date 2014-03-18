#! perl

requires 'Moo';
requires 'Hash::Util';
requires 'List::Util' => 1.38;
requires 'Package::Variant';
requires 'Class::Load';
recommends 'JSON::Tiny';
recommends 'YAML::Tiny';
recommends 'DBD::SQLite';
requires 'perl',               '5.008';


on develop => sub {
    requires 'Module::Install';
    requires 'Module::Install::CPANfile';
};
