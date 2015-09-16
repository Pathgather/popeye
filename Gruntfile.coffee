'use strict'

module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt)

  grunt.initConfig
    # clean - Delete all build artifacts
    clean: ['.tmp', 'release']

    # karma:unit - Run tests, watch /src & /test for changes
    # karma:release - Run tests once
    karma:
      unit:
        configFile: 'karma.conf.coffee'
        singleRun: false
      release:
        configFile: 'karma.conf.coffee'
        singleRun: true

    # coffee:release - convert popeye.coffee for release
    coffee:
      release:
        files:
          '.tmp/popeye.js': 'src/popeye.coffee'

    # ngAnnotate:release - add angular annotations
    ngAnnotate:
      release:
        files:
          'release/popeye.js': '.tmp/popeye.js'

    # sass:release - convert popeye.scss for release
    sass:
      release:
        files:
          'release/popeye.css': 'src/popeye.scss'

  grunt.registerTask 'watch', ['karma:unit']
  grunt.registerTask 'release', ['clean', 'karma:release', 'coffee:release', 'ngAnnotate:release', 'sass:release']
  grunt.registerTask 'default', ['release']
