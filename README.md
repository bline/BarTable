BarTable
========

BarTable is a fork of
[FooTable](http://fooplugins.com/plugins/footable-jquery). BarTable was created
out of a need for speed on larger sets of data (~10000) as well as the ability
to work with updates/additions/removals from the data. At this point, not much
of the original code from BarTable remains, only the plugin framework and basic
layout (which was well written!). 

Features that were removed:

* column groups (probably not going to)
* filter plugin, (todo)
* customizing the dropdown html for phone/tablet rendering is no longer
  possible. (todo)

Technical changes:

* internal dom element stores all rows, only displayed rows are added to the
  document.
* for display, a new tbody element is created with the range we are displaying
  and appended to the dom. this cuts down on rerendering and makes things very
  smooth
* sorting is done on internal dom element
* paging only needs to set the range we are displaying and create the paging
  toolbar
* all additions/removals/updates are done on internal dom element and pushed to
  document dom via redraw replacing tbody
* very optimized for speed, none of the functions that deal with the rows are
  using jquery. this resulted in loss of ie8 support but gained more than 100%
  speed increase
* updated to work with bootstrap3, no longer needs internal font set, as a
  result, this plugin requires [bootstrap3](http://getbootstrap.com/)
* table stipping is done with bootstrap3 now, we no longer add class to every
  other tr in the table (this was way too slow).
* use of [underscore.js](http://underscorejs.org/), so is now required

TODO
----

* filter plugin
* ability to customize breakpoint dropdown html
* remove nth column selectors so more browsers are supported
* create examples
* create demos
* create documentions
* better tests for required libraries
* better loading indicator
* more optimizations ;)

Features
--------

* Hide certain columns at different sizes
* Configuration via data attributes
* Built to work with Bootstrap3
* Easy to theme
* Sorting
* Pagination
* Easy to extend with add-ons
* Extremely fast
* Ability to load and sort large data sets (~10,000)


What Is BarTable?
-----------------

BarTable is a jQuery plugin that transforms your HTML tables into expandable
responsive tables. This is how it works:

1. It hides certain columns of data at different resolutions (we call these
   breakpoints).
2. Rows become expandable to reveal any hidden data.

So simple! Any hidden data can always be seen just by clicking the row.

Demos
-----

TODO

Documentation
-------------

TODO

Data Attribute Configuration
----------------------------

One of the main goals of BarTable was to make it completely configurable via data attributes. We wanted you to be able to look at the HTML markup and see exactly how the BarTable was going to function. Take a look at this markup for example:

```html
<table class="bartable" data-page-size="5">
  <thead>
    <tr>
      <th data-toggle="true">
        First Name
      </th>
      <th data-sort-ignore="true">
        Last Name
      </th>
      <th data-hide="phone,tablet">
        Job Title
      </th>
      <th data-hide="phone,tablet" data-name="Date Of Birth">
        DOB
      </th>
      <th data-hide="phone">
        Status
      </th>
    </tr>
  </thead>
```


Breakpoints
-----------

BarTable works with the concepts of "breakpoints", which are different table
widths we care about. The default breakpoints are:

```javascript
breakpoints: {
  phone: 480,
  tablet: 1024
}
```

So looking at the markup in the *Data Attribute Configuration* section, you can
now tell that the *Job Title*, *DOB* and *Status* columns will be hidden when
the table width is below 480 (phone).

There are also two built-in breakpoints called "default" and "all".

The "default" breakpoint is the fallback breakpoint for when the current table
width is larger than any defined breakpoint. Looking at the above JS snippet
the "default" breakpoint would be applied once the table width is larger than
1024 (tablet).

The "all" breakpoint is pretty straight forward in it's use. You can always
hide a column on any table width by applying the *data-hide="all"* attribute to
the header.

Usage
-----

Create a simple table (don't forget to set the data attributes for each column
in your thead!):

```html
<table class="bartable">
  <thead>
    <tr>
      <th>Name</th>
      <th data-hide="phone,tablet">Phone</th>
      <th data-hide="phone,tablet">Email</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Bob Builder</td>
      <td>555-12345</td>
      <td>bob@home.com</td>
    </tr>
    <tr>
      <td>Bridget Jones</td>
      <td>544-776655</td>
      <td>bjones@mysite.com</td>
    </tr>
    <tr>
      <td>Tom Cruise</td>
      <td>555-99911</td>
      <td>cruise1@crazy.com</td>
    </tr>
  </tbody>
</table>
```

1. **Include BarTable Core CSS**

   ```html
<link href="path_to_your_css/bartable.core.css" rel="stylesheet" type="text/css" />
```

2. **[optional] Include BarTable Theme CSS**

   > BarTable now requires [Twitter Bootstrap 3](http://twitter.github.io/bootstrap)


3. **Include jQuery**

    ```html
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js" type="text/javascript"></script>
```

4. **Include BarTable jQuery Plugin**

    ```html
<script src="path_to_your_js/bartable.js" type="text/javascript"></script>
```

5. **Initialize BarTable!**

   ```html
<script type="text/javascript">
    $(function () {

        $('.bartable').bartable();

    });
</script>
```

Extensible
----------

Another goal of BarTable was to make it easily extensible. If you look at the code you will see that there is a plugin framework within the plugin, so extra mods can be attached just by including another javascript file.

We also didn't want to bloat BarTable, so you can only use what you need and leave out everything else.

Working add-ons:

* sorting
* pagination (thanks @awc737)

Thanks
------

Thanks to [FooTable team](http://fooplugins.com/plugins/footable-jquery) for
creating the starting point for BarTable. Their code was a pleasure to gut :)

This is a list of the thanks from original FooTable README

* Catalin for his [original table CSS](http://www.red-team-design.com/practical-css3-tables-with-rounded-corners)
* [@awc737](https://github.com/awc737) for creating the pagination add-on
* [@OliverRC](https://github.com/OliverRC) for creating the striping add-on
* [Chris Coyier](http://css-tricks.com/responsive-data-tables/) (also check out Chris' [responsive table roundup post](http://css-tricks.com/responsive-data-table-roundup/))
* [Zurb](http://www.zurb.com/playground/responsive-tables)
* [Dave Bushell](http://dbushell.com/2012/01/05/responsive-tables-2/)
* [Filament Group](http://filamentgroup.com/examples/rwd-table-patterns/)
* [Stewart Curry](http://www.irishstu.com/stublog/2011/12/13/tables-responsive-design-part-2-nchilds/)
