'use strict'

module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt)

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    # usebanner: add a banner to all release files
    usebanner:
      options:
        position: 'top'
        banner: """
          /**
          * <%= pkg.name %>
          * <%= pkg.description %>\n
          * @author <%= pkg.author.name %> <<%= pkg.author.email %>>
          * @copyright <%= pkg.author.name %> <%= grunt.template.today('yyyy') %>
          * @license <%= pkg.license %>
          * @link <%= pkg.homepage %>
          * @version <%= pkg.version %>
          */\n
        """
      files:
        src: 'release/*'

    # clean - Delete all build artifacts
    clean: ['.tmp', 'release', 'demo/build']

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
          '.tmp/js/popeye.js': 'src/popeye.coffee'

    # ngAnnotate:release - add angular annotations
    ngAnnotate:
      release:
        files:
          'release/popeye.js': '.tmp/js/popeye.js'

    # uglify:release - minify popeye.js for release
    uglify:
      release:
        files:
          'release/popeye.min.js': 'release/popeye.js'

    # sass:release - convert popeye.scss for release
    # sass:demo - convert demo scss files
    sass:
      release:
        files:
          '.tmp/css/popeye.css': 'src/popeye.scss'
      demo:
        expand: true
        cwd: 'demo/src/'
        src: '*.scss'
        dest: '.tmp/demo/css/'
        ext: '.css'

    # postcss:release - autoprefix CSS for release
    # postcss:min - minify CSS for release
    # postcss:demo - autoprefix CSS for demo
    postcss:
      release:
        options:
          processors: [
            require('autoprefixer')({ browsers: ['last 2 versions', 'ie >= 9'] }),
          ]
        expand: true
        cwd: '.tmp/css/'
        src: '*.css'
        dest: 'release/'
      min:
        options:
          processors: [
            require('cssnano')
          ]
        expand: true
        cwd: 'release/'
        src: '*.css'
        dest: 'release/'
        ext: '.min.css'
      demo:
        options:
          processors: [
            require('autoprefixer')({ browsers: ['last 2 versions', 'ie >= 9'] }),
          ]
        expand: true
        cwd: '.tmp/demo/css/'
        src: '*.css'
        dest: 'demo/build/'

    # browserify:demo - bundle all demo dependencies & convert demo coffeescript
    browserify:
      demo:
        files:
          'demo/build/bundle.js': 'demo/src/*.coffee'
        options:
          transform: ['coffeeify']

    # watch - rebuild demo files if any sources change
    watch:
      browserify:
        files: ['demo/src/*.coffee']
        tasks: ['browserify:demo']
      sass:
        files: ['demo/src/*.scss']
        tasks: ['sass:demo', 'postcss:demo']

  grunt.registerTask 'test', ['karma:unit']
  grunt.registerTask 'js:release', ['coffee:release', 'ngAnnotate:release', 'uglify:release']
  grunt.registerTask 'css:release', ['sass:release', 'postcss:release', 'postcss:min']
  grunt.registerTask 'release', ['clean', 'karma:release', 'js:release', 'css:release', 'usebanner', 'demo']
  grunt.registerTask 'demo', ['browserify:demo', 'sass:demo', 'postcss:demo']
  grunt.registerTask 'demo:watch', ['demo', 'watch']
  grunt.registerTask 'default', ['release']
