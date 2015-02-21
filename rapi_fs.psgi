use strict;
use warnings;

use Rapi::Fs;

my $app = Rapi::Fs->apply_default_middlewares(Rapi::Fs->psgi_app);
$app;

