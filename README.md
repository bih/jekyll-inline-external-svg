# jekyll-inline-svg

SVG optimizer and inliner for jekyll

This liquid tag will let you inline SVG images in your jekyll sites.

```
    {% svg /path/to/file.svg width=24 foo="bar" %}
```

Will include the svg file in your output HTML like this :

```
<svg width=24 foo="bar" version="1.1" id="square" xmlns="http://www.w3.org/2000/svg" x="0" y="0" viewBox="0 0 24 24" >
  <rect width="20" height="20" x="2" y="2" />
</svg>
```

**Note** : You will generally want to set the width/height of your SVG or a `style` attribute, but anything can be passed through.

Paths with a space should be quoted :

```
{% svg "/path/to/foo bar.svg" %}
```
Otherwise anything after the first space will be considered an attribute.

Relative paths and absolute paths will both be interpreted from Jekyll's configured [source directory](https://jekyllrb.com/docs/configuration/). So both :

```
    {% svg "/path/to/foo.svg" %}
    {% svg "path/to/foo.svg"  %}
```

Should resolve to `/your/site/source/path/to/foo.svg`.


## Safety

In [safe mode](https://jekyllrb.com/docs/plugins/) (ie. on github pages), the plugin will be disabled as it's not yet trusted. However it should be "safe" as defined by [Jekyll](https://jekyllrb.com/docs/plugins/) (ie. no arbitrary code execution).

However, it does not provide any ability to prevent reading from outside of source dir. For example, `/../../file.svg` is still a valid location.



Some processing is done to remove useless data :

- metadata
- comments
- unused groups
- Other filters from [svg_optimizer](https://github.com/fnando/svg_optimizer)
- default size

If any important data gets removed, or the output SVG looks different from input, it's a bug. Please file an issue to this repository describing your problem.

It does not perform any input validation on attributes. They will be appended as-is to the root node.