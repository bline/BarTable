Package.describe({
  summary: "BarTable is a FAST jQuery plugin that transforms your HTML tables into expandable responsive tables."
});

var client = 'client';
var server = 'server';
var both = [client, server];
Package.on_use(function (api) {
  path = Npm.require("path");
  _ = Npm.require("underscore");
  api.use(['jquery', 'underscore', 'coffeescript'], client);
  jsFiles = [
    'bartable.coffee',
    'bartable.filter.coffee',
    'bartable.sort.coffee',
    'bartable.paginate.coffee'
  ];
  api.add_files([
    path.join('css', 'bartable.core.css'),
  ], client);
  api.add_files(
    _(jsFiles).map(function (file) { return path.join('coffee', file) })
  , client);
});
