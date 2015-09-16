module.exports = (config) ->
  config.set
    basePath: ''

    frameworks: ['jasmine-jquery', 'jasmine']

    files: [
      'node_modules/angular/angular.js'
      'node_modules/angular-mocks/angular-mocks.js'
      'src/*.coffee'
      'test/*.coffee'
    ]

    preprocessors:
      'src/*.coffee': ['coffee']
      'test/*.coffee': ['coffee']

    coffeePreprocessor:
      options:
        sourceMap: true

    reporters: ['dots']

    port: 9876

    colors: true

    logLevel: config.LOG_INFO

    autoWatch: true

    browsers: ['Chrome']

    singleRun: false
