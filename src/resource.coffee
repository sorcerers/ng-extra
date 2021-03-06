
angular.module('ng-extra.resource', ['ngResource'])

# Resource.wrapStaticMethod and Resource.wrapInstanceMethod
.config([
  '$provide'
  ($provide) ->
    $provide.decorator('$resource', [
      '$delegate'
      ($delegate) ->
        (url, paramDefaults, actions) ->
          Resource = $delegate url, paramDefaults, actions

          Resource.wrapStaticMethod = (fnName, wrapper, deleteInstanceMethod = true) ->
            return unless angular.isFunction wrapper
            originalFn = Resource[fnName]
            delete Resource::["$#{fnName}"] if deleteInstanceMethod
            Resource[fnName] = wrapper -> originalFn.apply Resource, arguments

          Resource.wrapInstanceMethod = (fnName, wrapper) ->
            return unless angular.isFunction wrapper
            originalFn = Resource::["$#{fnName}"]
            Resource::["$#{fnName}"] = wrapper originalFn

          Resource
  ])
])


# Resource = $resource(
#   '/path/to/resource',
#   {id: '@defaultId'},
#   {
#     action1: {
#       normalize: true
#       retainprops: ['id', 'name']
#     }
#   }
# )
#
# resource = new Resource
# resource.$update(params, data)
#
.config([
  '$provide'
  ($provide) ->

    $provide.decorator('$resource', [
      '$delegate'
      ($resource) ->
        (url, paramDefaults, actions) ->
          Resource = $resource url, paramDefaults, actions
          angular.forEach actions, (options, method) ->
            return unless options.normalize
            return unless options.method.toUpperCase() in ['POST', 'PUT', 'PATCH']
            retainprops = options.retainprops ? ['id']

            Resource::["$#{method}"] = (params, data, success, error) ->
              if angular.isFunction params
                error = data
                success = params
                params = null
                data = null
              else if angular.isFunction data
                error = success
                success = data
                data = null

              if params? and not data?
                data = params
                params = null

              data = angular.copy(data) or {}
              angular.forEach retainprops, (property) =>
                data[property] = this[property]

              successHandler = (item, headers) =>
                promise = @$promise
                angular.copy angular.clean(item), this
                @$resolved = true
                @$promise = promise
                success? this, headers
              errorHandler = (resp) =>
                @$resolved = true
                error? resp

              @$resolved = false
              Resource[method](params, data, successHandler, errorHandler).$promise.then => this

          Resource
    ])

])
