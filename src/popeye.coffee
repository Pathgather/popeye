popeye = (angular) ->
  "use strict"

  mod = angular.module "pathgather.popeye", []

  mod.run ($templateCache) ->
    # TODO: do we need this? YES! until there's a configuration option for Popeye to specify the container template url
    $templateCache.put("modal_container.html", '<div class="pg-modal-container pg-animate" pg-scroll-spy>
      <div class="pg-modal"></div></div>')

  mod.factory "Popeye", ($q, $animate, $rootScope, $document, $http, $templateCache, $compile, $controller, $injector) ->

      # Modal instances co-operatively manage this state so that everything works nicely
      # (in other words... here are some global variables we use)
      currentModal = null
      pendingPromise = null

      class Modal
        constructor: (@template, @options = {}) ->
          throw new Error("template must be provided") unless @template?

          # Setup up our resolved, opened, and closed promises
          @resolvedDeferred = $q.defer()
          @resolved = @resolvedDeferred.promise
          @openedDeferred = $q.defer()
          @opened = @openedDeferred.promise
          @closedDeferred = $q.defer()
          @closed = @closedDeferred.promise

        # Setup the modal scope, resolve controller locals, etc.
        # Returns the @resolved promise that resolves when complete
        resolve: =>
          return @resolved if @resolving
          @resolving = true
          $q.when({}).then =>
            locals = angular.extend({}, @options.locals)
            resolve = angular.extend({}, @options.resolve)
            angular.forEach resolve, (value, key) ->
              locals[key] = if angular.isString(value) then $injector.get(value) else $injector.invoke(value, null, locals)
            locals["modal"] = @
            $q.all(locals)
          .then (resolved) =>
            @scope = if @options.scope? then @options.scope else $rootScope.$new()
            @scope.$close = => @close(arguments...) # Backwards compatability with the Foundation modal # TODO: remove?
            if @options.controller
              @controller = $controller(@options.controller, angular.extend({$scope: @scope}, resolved))
            @resolvedDeferred.resolve(@)
          , (error) =>
            @handleError(error)
          return @resolved

        # Load the container & modal templates, and add everything to the DOM via $animate
        open: =>
          return @opened if @opening
          @opening = true

          # Don't simply start opening this modal - check to see if there's already an active one (or one in the process
          # of opening), tell it to close, and wait for that before opening ourself
          promise = if pendingPromise?
            # Wait for the pending modal to open...then close it...then return ourself!
            pendingPromise = pendingPromise.then (prevModal) =>
              prevModal.close().then => @
          else if currentModal?
            pendingPromise = currentModal.close().then => @
          else
            pendingPromise = @opened
            $q.when()

          # Once we've ensured that all other modals are cleaned up, start opening ourself
          promise.then =>
            @resolve().then =>
              throw new Error("@scope is undefined") unless @scope?
              containerElement = angular.element($templateCache.get("modal_container.html")) # TODO: use $http
              containerElement.addClass(@options.windowClass) if @options.windowClass
              $http.get(@template, {cache: $templateCache}).then (tmpl) =>
                angular.element(containerElement[0].querySelector(".pg-modal")).html(tmpl.data)
                containerElement.on "click", (evt) => @close(reason: "backdrop click") if evt.target == evt.currentTarget

                @container = $compile(containerElement)(@scope)
                @element = angular.element(@container[0].querySelector(".pg-modal"))

                # Add the container to the body
                body = $document.find("body")
                bodyLastChild = angular.element(body[0].lastChild) if body[0].lastChild
                body.addClass("modal-open")

                $animate.enter(@container, body, bodyLastChild).then =>
                  currentModal = @
                  @openedDeferred.resolve(@)
          , (error) =>
            @handleError(error)
          return @opened

        close: (value) =>
          # Remove the container from the body
          return @closed if @closing
          @closing = true
          @opened.then =>
            throw new Error("@container is undefined") unless @container?
            $animate.leave(@container).then =>
              currentModal = null
              # only destroy the scope if we created it
              @scope.$destroy() unless @options.scope
              angular.element(document.body).removeClass("modal-open")
              @closedDeferred.resolve(value)
            , (error) =>
              @handleError(error)
          return @closed

        handleError: (error) =>
          @resolvedDeferred.reject(error)
          @openedDeferred.reject(error)
          @closedDeferred.reject(error)

      # The Popeye API
      return {
        # TODO: remove the template required param, just have optional args
        openModal: (template, options = {}) ->
          modal = new Modal(template, options)
          modal.open()
          return modal

        loadInOwnState: (template, options = {}) ->
          @openModal(template, options)

        # TODO: remove this, it's a bad API, only useful for transitioning
        getCurrentModal: -> currentModal

        closeCurrentModal: (reason) ->
          currentModal?.close(reason: reason).then -> currentModal = null
          return currentModal
      }


# Use Browserify to require angular, if possible. Otherwise, expect angular on the window
if require?
  angular = require "angular"
  popeye(angular)
else
  popeye(window.angular)

# Define CommonJS-style module.exports
if module?
  module.exports = "pathgather.popeye"
