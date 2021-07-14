u = up.util
e = up.element

###**
The `up.Params` class offers a consistent API to read and manipulate request parameters
independent of their type.

Request parameters are used in [form submissions](/up.Params.fromForm) and
[URLs](/up.Params.fromURL). Methods like `up.submit()` or `up.replace()` accept
request parameters as a `{ params }` option.

\#\#\# Supported parameter types

The following types of parameter representation are supported:

1. An object like `{ email: 'foo@bar.com' }`
2. A query string like `'email=foo%40bar.com'`
3. An array of `{ name, value }` objects like `[{ name: 'email', value: 'foo@bar.com' }]`
4. A [FormData](https://developer.mozilla.org/en-US/docs/Web/API/FormData) object.
   On IE 11 and Edge, `FormData` payloads require a [polyfill for `FormData#entries()`](https://github.com/jimmywarting/FormData).

@class up.Params
###
class up.Params extends up.Class

  ###**
  Constructs a new `up.Params` instance.

  @constructor up.Params
  @param {Object|Array|string|up.Params} [params]
    An existing list of params with which to initialize the new `up.Params` object.

    The given params value may be of any [supported type](/up.Params).
  @return {up.Params}
  @experimental
  ###
  constructor: (raw) ->
    super()
    @clear()
    @addAll(raw)

  ###**
  Removes all params from this object.

  @function up.Params#clear
  @experimental
  ###
  clear: ->
    @entries = []

  "#{u.copy.key}": ->
    new up.Params(@)

  ###**
  Returns an object representation of this `up.Params` instance.

  The returned value is a simple JavaScript object with properties
  that correspond to the key/values in the given `params`.

  \#\#\# Example

      var params = new up.Params('foo=bar&baz=bam')
      var object = params.toObject()

      // object is now: {
      //   foo: 'bar',
      //   baz: 'bam'
      // ]

  @function up.Params#toObject
  @return {Object}
  @experimental
  ###
  toObject: ->
    obj = {}
    for entry in @entries
      { name, value } = entry
      unless u.isBasicObjectProperty(name)
        if @isArrayKey(name)
          obj[name] ||= []
          obj[name].push(value)
        else
          obj[name] = value
    obj

  ###**
  Returns an array representation of this `up.Params` instance.

  The returned value is a JavaScript array with elements that are objects with
  `{ key }` and `{ value }` properties.

  \#\#\# Example

      var params = new up.Params('foo=bar&baz=bam')
      var array = params.toArray()

      // array is now: [
      //   { name: 'foo', value: 'bar' },
      //   { name: 'baz', value: 'bam' }
      // ]

  @function up.Params#toArray
  @return {Array}
  @experimental
  ###
  toArray: ->
    @entries

  ###**
  Returns a [`FormData`](https://developer.mozilla.org/en-US/docs/Web/API/FormData) representation
  of this `up.Params` instance.

  \#\#\# Example

      var params = new up.Params('foo=bar&baz=bam')
      var formData = params.toFormData()

      formData.get('foo') // 'bar'
      formData.get('baz') // 'bam'

  @function up.Params#toFormData
  @return {FormData}
  @experimental
  ###
  toFormData: ->
    formData = new FormData()
    for entry in @entries
      formData.append(entry.name, entry.value)
    unless formData.entries
      # If this browser cannot inspect FormData with the #entries()
      # iterator, assign the original array for inspection by specs.
      formData.originalArray = @entries
    formData

  ###**
  Returns an [query string](https://en.wikipedia.org/wiki/Query_string) for this `up.Params` instance.

  The keys and values in the returned query string will be [percent-encoded](https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding).
  Non-primitive values (like [`File`](https://developer.mozilla.org/en-US/docs/Web/API/File) will be omitted from
  the retuned query string.

  \#\#\# Example

      var params = new up.Params({ foo: 'bar', baz: 'bam' })
      var query = params.toQuery()

      // query is now: 'foo=bar&baz=bam'

  @function up.Params#toQuery
  @param {Object|FormData|string|Array|undefined} params
    the params to convert
  @return {string}
    a query string built from the given params
  @experimental
  ###
  toQuery: ->
    parts = u.map(@entries, @arrayEntryToQuery)
    parts = u.compact(parts)
    parts.join('&')

  arrayEntryToQuery: (entry) =>
    value = entry.value

    # We cannot transpot a binary value in a query string.
    if @isBinaryValue(value)
      return undefined

    query = encodeURIComponent(entry.name)
    # There is a subtle difference when encoding blank values:
    # 1. An undefined or null value is encoded to `key` with no equals sign
    # 2. An empty string value is encoded to `key=` with an equals sign but no value
    if u.isGiven(value)
      query += "="
      query += encodeURIComponent(value)
    query

  ###**
  Returns whether the given value cannot be encoded into a query string.

  We will have `File` values in our params when we serialize a form with a file input.
  These entries will be filtered out when converting to a query string.

  @function up.Params#isBinaryValue
  @internal
  ###
  isBinaryValue: (value) ->
    value instanceof Blob

  hasBinaryValues: ->
    values = u.map(@entries, 'value')
    return u.some(values, @isBinaryValue)

  ###**
  Builds an URL string from the given base URL and
  this `up.Params` instance as a [query string](https://en.wikipedia.org/wiki/Query_string).

  The base URL may or may not already contain a query string. The
  additional query string will be joined with an `&` or `?` character accordingly.

  @function up.Params#toURL
  @param {string} base
    The base URL that will be prepended to this `up.Params` object as a query string.
  @return {string}
    The built URL.
  @experimental
  ###
  toURL: (base) ->
    parts = [base, @toQuery()]
    parts = u.filter(parts, u.isPresent)
    separator = if u.contains(base, '?') then '&' else '?'
    parts.join(separator)

  ###**
  Adds a new entry with the given `name` and `value`.

  An `up.Params` instance can hold multiple entries with the same name.
  To overwrite all existing entries with the given `name`, use `up.Params#set()` instead.

  \#\#\# Example

      var params = new up.Params()
      params.add('foo', 'fooValue')

      var foo = params.get('foo')
      // foo is now 'fooValue'

  @function up.Params#add
  @param {string} name
    The name of the new entry.
  @param {any} value
    The value of the new entry.
  @experimental
  ###
  add: (name, value) ->
    @entries.push({name, value})

  ###**
  Adds all entries from the given list of params.

  The given params value may be of any [supported type](/up.Params).

  @function up.Params#addAll
  @param {Object|Array|string|up.Params|undefined} params
  @experimental
  ###
  addAll: (raw) ->
    if u.isMissing(raw)
      # nothing to do
    else if raw instanceof @constructor
      @entries.push(raw.entries...)
    else if u.isArray(raw)
      # internal use for copying
      @entries.push(raw...)
    else if u.isString(raw)
      @addAllFromQuery(raw)
    else if u.isFormData(raw)
      @addAllFromFormData(raw)
    else if u.isObject(raw)
      @addAllFromObject(raw)
    else
      up.fail("Unsupport params type: %o", raw)

  addAllFromObject: (object) ->
    for key, value of object
      valueElements = if u.isArray(value) then value else [value]
      for valueElement in valueElements
        @add(key, valueElement)

  addAllFromQuery: (query) ->
    for part in query.split('&')
      if part
        [name, value] = part.split('=')
        name = decodeURIComponent(name)
        # There are three forms we need to handle:
        # (1) foo=bar should become { name: 'foo', bar: 'bar' }
        # (2) foo=    should become { name: 'foo', bar: '' }
        # (3) foo     should become { name: 'foo', bar: null }
        if u.isGiven(value)
          value = decodeURIComponent(value)
        else
          value = null
        @add(name, value)

  addAllFromFormData: (formData) ->
    u.eachIterator formData.entries(), (value) =>
      @add(value...)

  ###**
  Sets the `value` for the entry with given `name`.

  An `up.Params` instance can hold multiple entries with the same name.
  All existing entries with the given `name` are [deleted](/up.Params.prototype.delete) before the
  new entry is set. To add a new entry even if the `name` is taken, use `up.Params#add()`.

  @function up.Params#set
  @param {string} name
    The name of the entry to set.
  @param {any} value
    The new value of the entry.
  @experimental
  ###
  set: (name, value) ->
    @delete(name)
    @add(name, value)

  ###**
  Deletes all entries with the given `name`.

  @function up.Params#delete
  @param {string} name
  @experimental
  ###
  delete: (name) ->
    @entries = u.reject(@entries, @matchEntryFn(name))

  matchEntryFn: (name) ->
    (entry) -> entry.name == name

  ###**
  Returns the first param value with the given `name` from the given `params`.

  Returns `undefined` if no param value with that name is set.

  If the `name` denotes an array field (e.g. `foo[]`), *all* param values with the given `name`
  are returned as an array. If no param value with that array name is set, an empty
  array is returned.

  To always return a single value use `up.Params#getFirst()` instead.
  To always return an array of values use `up.Params#getAll()` instead.

  \#\#\# Example

      var params = new up.Params({ foo: 'fooValue', bar: 'barValue' })
      var params = new up.Params([
        { name: 'foo', value: 'fooValue' }
        { name: 'bar[]', value: 'barValue1' }
        { name: 'bar[]', value: 'barValue2' })
      ]})

      var foo = params.get('foo')
      // foo is now 'fooValue'

      var bar = params.get('bar')
      // bar is now ['barValue1', 'barValue2']

  @function up.Params#get
  @param {string} name
  @experimental
  ###
  get: (name) ->
    if @isArrayKey(name)
      @getAll(name)
    else
      @getFirst(name)

  ###**
  Returns the first param value with the given `name`.

  Returns `undefined` if no param value with that name is set.

  @function up.Params#getFirst
  @param {string} name
  @return {any}
    The value of the param with the given name.
  @internal
  ###
  getFirst: (name) ->
    entry = u.find(@entries, @matchEntryFn(name))
    entry?.value

  ###**
  Returns an array of all param values with the given `name`.

  Returns an empty array if no param value with that name is set.

  @function up.Params#getAll
  @param {string} name
  @return {Array}
    An array of all values with the given name.
  @internal
  ###
  getAll: (name) ->
    if @isArrayKey(name)
      @getAll(name)
    else
      entries = u.map(@entries, @matchEntryFn(name))
      u.map(entries, 'value')

  isArrayKey: (key) ->
    u.endsWith(key, '[]')

  "#{u.isBlank.key}": ->
    @entries.length == 0

  ###**
  Constructs a new `up.Params` instance from the given `<form>`.

  The returned params may be passed as `{ params }` option to
  `up.request()` or `up.replace()`.

  The constructed `up.Params` will include exactly those form values that would be
  included in a regular form submission. In particular:

  - All `<input>` types are suppported
  - Field values are usually strings, but an `<input type="file">` will produce
    [`File`](https://developer.mozilla.org/en-US/docs/Web/API/File) values.
  - An `<input type="radio">` or `<input type="checkbox">` will only be added if they are `[checked]`.
  - An `<select>` will only be added if at least one value is `[checked]`.
  - If passed a `<select multiple>` or `<input type="file" multiple>`, all selected values are added.
    If passed a `<select multiple>`, all selected values are added.
  - Fields that are `[disabled]` are ignored
  - Fields without a `[name]` attribute are ignored.

  \#\#\# Example

  Given this HTML form:

      <form>
        <input type="text" name="email" value="foo@bar.com">
        <input type="password" name="pass" value="secret">
      </form>

  This would serialize the form into an array representation:

      var params = up.Params.fromForm('input[name=email]')
      var email = params.get('email') // email is now 'foo@bar.com'
      var pass = params.get('pass') // pass is now 'secret'

  @function up.Params.fromForm
  @param {Element|jQuery|string} form
    A `<form>` element or a selector that matches a `<form>` element.
  @return {up.Params}
    A new `up.Params` instance with values from the given form.
  @experimental
  ###
  @fromForm: (form) ->
    # If passed a selector, up.fragment.get() will prefer a match on the current layer.
    form = up.fragment.get(form)
    @fromFields(up.form.fields(form))

  ###**
  Constructs a new `up.Params` instance from one or more
  [HTML form field](https://www.w3schools.com/html/html_form_elements.asp).

  The constructed `up.Params` will include exactly those form values that would be
  included for the given fields in a regular form submission. If a given field wouldn't
  submit a value (like an unchecked `<input type="checkbox">`, nothing will be added.

  See `up.Params.fromForm()` for more details and examples.

  @function up.Params.fromFields
  @param {Element|List<Element>|jQuery} fields
  @return {up.Params}
  @experimental
  ###
  @fromFields: (fields) ->
    params = new @()
    for field in u.wrapList(fields)
      params.addField(field)
    params

  ###**
  Adds params from the given [HTML form field](https://www.w3schools.com/html/html_form_elements.asp).

  The added params will include exactly those form values that would be
  included for the given field in a regular form submission. If the given field wouldn't
    submit a value (like an unchecked `<input type="checkbox">`, nothing will be added.

  See `up.Params.fromForm()` for more details and examples.

  @function up.Params#addField
  @param {Element|jQuery} field
  @experimental
  ###
  addField: (field) ->
    params = new @constructor()
    field = e.get(field) # unwrap jQuery

    # Input fields are excluded from form submissions if they have no [name]
    # or when they are [disabled].
    if (name = field.name) && (!field.disabled)
      tagName = field.tagName
      type = field.type
      if tagName == 'SELECT'
        for option in field.querySelectorAll('option')
          if option.selected
            @add(name, option.value)
      else if type == 'checkbox' || type == 'radio'
        if field.checked
          @add(name, field.value)
      else if type == 'file'
        # The value of an input[type=file] is the local path displayed in the form.
        # The actual File objects are in the #files property.
        for file in field.files
          @add(name, file)
      else
        @add(name, field.value)

  "#{u.isEqual.key}": (other) ->
    other && (@constructor == other.constructor) && u.isEqual(@entries, other.entries)

  ###**
  Constructs a new `up.Params` instance from the given URL's
  [query string](https://en.wikipedia.org/wiki/Query_string).

  Constructs an empty `up.Params` instance if the given URL has no query string.

  \#\#\# Example

      var params = up.Params.fromURL('http://foo.com?foo=fooValue&bar=barValue')
      var foo = params.get('foo')
      // foo is now: 'fooValue'

  @function up.Params.fromURL
  @param {string} url
    The URL from which to extract the query string.
  @return {string|undefined}
    The given URL's query string, or `undefined` if the URL has no query component.
  @experimental
  ###
  @fromURL: (url) ->
    params = new @()
    urlParts = u.parseURL(url)
    if query = urlParts.search
      query = query.replace(/^\?/, '')
      params.addAll(query)
    params

  ###**
  Returns the given URL without its [query string](https://en.wikipedia.org/wiki/Query_string).

  \#\#\# Example

      var url = up.Params.stripURL('http://foo.com?key=value')
      // url is now: 'http://foo.com'

  @function up.Params.stripURL
  @param {string} url
    A URL (with or without a query string).
  @return {string}
    The given URL without its query string.
  @experimental
  ###
  @stripURL: (url) ->
    return u.normalizeURL(url, search: false)

  ###**
  If passed an `up.Params` instance, it is returned unchanged.
  Otherwise constructs an `up.Params` instance from the given value.

  The given params value may be of any [supported type](/up.Params)
  The return value is always an `up.Params` instance.

  @function up.Params.wrap
  @param {Object|Array|string|up.Params|undefined} params
  @return {up.Params}
  @experimental
  ###
