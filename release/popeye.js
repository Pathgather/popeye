(function() {
  var angular, popeye,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  popeye = function(angular) {
    "use strict";
    var mod;
    mod = angular.module("pathgather.popeye", []);
    mod.run(["$templateCache", function($templateCache) {
      return $templateCache.put("modal_container.html", '<div class="pg-modal-container pg-animate" pg-scroll-spy> <div class="pg-modal"></div></div>');
    }]);
    return mod.factory("Popeye", ["$q", "$animate", "$rootScope", "$document", "$http", "$templateCache", "$compile", "$controller", "$injector", function($q, $animate, $rootScope, $document, $http, $templateCache, $compile, $controller, $injector) {
      var Modal, currentModal, pendingPromise;
      currentModal = null;
      pendingPromise = null;
      Modal = (function() {
        function Modal(template1, options1) {
          this.template = template1;
          this.options = options1 != null ? options1 : {};
          this.handleError = bind(this.handleError, this);
          this.close = bind(this.close, this);
          this.open = bind(this.open, this);
          this.resolve = bind(this.resolve, this);
          if (this.template == null) {
            throw new Error("template must be provided");
          }
          this.resolvedDeferred = $q.defer();
          this.resolved = this.resolvedDeferred.promise;
          this.openedDeferred = $q.defer();
          this.opened = this.openedDeferred.promise;
          this.closedDeferred = $q.defer();
          this.closed = this.closedDeferred.promise;
        }

        Modal.prototype.resolve = function() {
          if (this.resolving) {
            return this.resolved;
          }
          this.resolving = true;
          $q.when({}).then((function(_this) {
            return function() {
              var locals, resolve;
              locals = angular.extend({}, _this.options.locals);
              resolve = angular.extend({}, _this.options.resolve);
              angular.forEach(resolve, function(value, key) {
                return locals[key] = angular.isString(value) ? $injector.get(value) : $injector.invoke(value, null, locals);
              });
              locals["modal"] = _this;
              return $q.all(locals);
            };
          })(this)).then((function(_this) {
            return function(resolved) {
              _this.scope = _this.options.scope != null ? _this.options.scope : $rootScope.$new();
              _this.scope.$close = function() {
                return _this.close.apply(_this, arguments);
              };
              if (_this.options.controller) {
                _this.controller = $controller(_this.options.controller, angular.extend({
                  $scope: _this.scope
                }, resolved));
              }
              return _this.resolvedDeferred.resolve(_this);
            };
          })(this), (function(_this) {
            return function(error) {
              return _this.handleError(error);
            };
          })(this));
          return this.resolved;
        };

        Modal.prototype.open = function() {
          var promise;
          if (this.opening) {
            return this.opened;
          }
          this.opening = true;
          promise = pendingPromise != null ? pendingPromise = pendingPromise.then((function(_this) {
            return function(prevModal) {
              return prevModal.close().then(function() {
                return _this;
              });
            };
          })(this)) : currentModal != null ? pendingPromise = currentModal.close().then((function(_this) {
            return function() {
              return _this;
            };
          })(this)) : (pendingPromise = this.opened, $q.when());
          promise.then((function(_this) {
            return function() {
              return _this.resolve().then(function() {
                var containerElement;
                if (_this.scope == null) {
                  throw new Error("@scope is undefined");
                }
                containerElement = angular.element($templateCache.get("modal_container.html"));
                if (_this.options.windowClass) {
                  containerElement.addClass(_this.options.windowClass);
                }
                return $http.get(_this.template, {
                  cache: $templateCache
                }).then(function(tmpl) {
                  var body, bodyLastChild;
                  angular.element(containerElement[0].querySelector(".pg-modal")).html(tmpl.data);
                  containerElement.on("click", function(evt) {
                    if (evt.target === evt.currentTarget) {
                      return _this.close({
                        reason: "backdrop click"
                      });
                    }
                  });
                  _this.container = $compile(containerElement)(_this.scope);
                  _this.element = angular.element(_this.container[0].querySelector(".pg-modal"));
                  body = $document.find("body");
                  if (body[0].lastChild) {
                    bodyLastChild = angular.element(body[0].lastChild);
                  }
                  body.addClass("modal-open");
                  return $animate.enter(_this.container, body, bodyLastChild).then(function() {
                    currentModal = _this;
                    return _this.openedDeferred.resolve(_this);
                  });
                });
              });
            };
          })(this), (function(_this) {
            return function(error) {
              return _this.handleError(error);
            };
          })(this));
          return this.opened;
        };

        Modal.prototype.close = function(value) {
          if (this.closing) {
            return this.closed;
          }
          this.closing = true;
          this.opened.then((function(_this) {
            return function() {
              if (_this.container == null) {
                throw new Error("@container is undefined");
              }
              return $animate.leave(_this.container).then(function() {
                currentModal = null;
                if (!_this.options.scope) {
                  _this.scope.$destroy();
                }
                angular.element(document.body).removeClass("modal-open");
                return _this.closedDeferred.resolve(value);
              }, function(error) {
                return _this.handleError(error);
              });
            };
          })(this));
          return this.closed;
        };

        Modal.prototype.handleError = function(error) {
          this.resolvedDeferred.reject(error);
          this.openedDeferred.reject(error);
          return this.closedDeferred.reject(error);
        };

        return Modal;

      })();
      return {
        openModal: function(template, options) {
          var modal;
          if (options == null) {
            options = {};
          }
          modal = new Modal(template, options);
          modal.open();
          return modal;
        },
        loadInOwnState: function(template, options) {
          if (options == null) {
            options = {};
          }
          return this.openModal(template, options);
        },
        getCurrentModal: function() {
          return currentModal;
        },
        closeCurrentModal: function(reason) {
          if (currentModal != null) {
            currentModal.close({
              reason: reason
            }).then(function() {
              return currentModal = null;
            });
          }
          return currentModal;
        }
      };
    }]);
  };

  if (typeof require !== "undefined" && require !== null) {
    angular = require("angular");
    popeye(angular);
  } else {
    popeye(window.angular);
  }

  if (typeof module !== "undefined" && module !== null) {
    module.exports = "pathgather.popeye";
  }

}).call(this);
