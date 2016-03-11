puppet-henchman CHANGELOG
=========================

0.1.1 (2016-03-11)
------------------

### Bugfix

Removed the integration rake task parameter `destroy`. This has been replaced with an environment variable `DESTROY` to make it easier to set (I'm looking at you zsh). The logic has also been fixed so instances actually get destroyed if `yes` or `always` is passed.

0.1.0 (2016-03-07)
------------------

* Initial Release
