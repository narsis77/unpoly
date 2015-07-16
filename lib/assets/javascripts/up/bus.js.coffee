###*
Framework events
================

Up.js uses an internal event bus that you can use to hook into lifecycle events like "an HTML fragment into the DOM".
  
This internal event bus might eventually be rolled into regular events that we trigger on `document`.

\#\#\# `fragment:ready` event

This event is triggered after Up.js has inserted an HTML fragment into the DOM through mechanisms like [`[up-target]`](/up.flow#up-target) or [`up.replace`](/up.flow#up.replace):

    up.bus.on('fragment:ready', function($fragment) {
      console.log("Looks like we have a new %o!", $fragment);
    });

The event is triggered *before* Up has compiled the fragment with your [custom behavior](/up.magic).
Upon receiving the event, Up.js will start compilation.


\#\#\# `fragment:destroy` event

This event is triggered when Up.js is destroying an HTML fragment, e.g. because it's being replaced
with a new version or because someone explicitly called [`up.destroy`](/up.flow#up.destroy):

    up.bus.on('fragment:destroy', function($fragment) {
      console.log("Looks like we lost %o!", $fragment);
    });

After triggering this event, Up.js will remove the fragment from the DOM.
In case the fragment destruction is animated, Up.js will complete the
animation before removing the fragment from the DOM.


\#\#\# Incomplete documentation!
  
We need to work on this page:

- Decide whether to refactor this into document events
- Decide whether `fragment:enter` and `fragment:leave` would be better names

  
@class up.bus
###
up.bus = (->
  
  u = up.util

  callbacksByEvent = {}
  defaultCallbacksByEvent = {}

  callbacksFor = (event) ->
    callbacksByEvent[event] ||= []

  ###*
  Makes a snapshot of the currently registered bus listeners,
  to later be restored through [`up.bus.reset`](/up.bus#up.bus.reset)
  
  @private
  @method up.bus.snapshot
  ###
  snapshot = ->
    defaultCallbacksByEvent = {}
    for event, callbacks of callbacksByEvent
      defaultCallbacksByEvent[event] = u.copy(callbacks)
  
  ###*
  Resets the list of registered event listeners to the
  moment when the framework was booted.
  
  @private
  @method up.bus.reset
  ###
  reset = ->
    callbacksByEvent = u.copy(defaultCallbacksByEvent)

  ###*
  Registers an event handler to be called when the given
  event is triggered.
  
  @method up.bus.on
  @param {String} eventName
    The event name to match.
  @param {Function} handler
    The event handler to be called with the event arguments.  
  ###
  # We cannot call this function "on" because Coffeescript
  # https://makandracards.com/makandra/29733-english-words-that-you-cannot-use-in-coffeescript
  listen = (eventName, handler) ->
    callbacksFor(eventName).push(handler)

  ###*
  Triggers an event over the framework bus.

  All arguments will be passed as arguments to event listeners:

      up.bus.on('foo:bar', function(x, y) {
        console.log("Value of x is " + x);
        console.log("Value of y is " + y);
      });

      up.bus.emit('foo:bar', 'arg1', 'arg2')

      // This prints to the console:
      //
      //   Value of x is arg1
      //   Value of y is arg2

  @method up.bus.emit
  @param {String} eventName
    The name of the event.
  @param args...
    The arguments that describe the event. 
  ###
  emit = (eventName, args...) ->
    u.debug("Emitting event %o with args %o", eventName, args)
    callbacks = callbacksFor(eventName)
    u.each(callbacks, (callback) ->
      callback(args...)
    )

  listen 'framework:ready', snapshot
  listen 'framework:reset', reset

  on: listen
  emit: emit
)()
