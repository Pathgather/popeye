'use strict'

module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt)

  grunt.initConfig
    # clean - Delete all build artifacts
    clean: ['.tmp', 'build']

    # sass:demo - convert demo scss files
    sass:
      demo:
        expand: true
        cwd: 'src/'
        src: '*.scss'
        dest: '.tmp/css/'
        ext: '.css'

    # postcss:demo - autoprefix CSS for demo
    postcss:
      demo:
        options:
          processors: [
            require('autoprefixer')({ browsers: ['last 2 versions', 'ie >= 9'] }),
          ]
        expand: true
        cwd: '.tmp/css/'
        src: '*.css'
        dest: 'build/'

    # browserify:demo - bundle all demo dependencies & convert demo coffeescript
    browserify:
      demo:
        files:
          'build/bundle.js': 'src/*.coffee'
        options:
          transform: ['coffeeify']

    # copy:demo - copy popeye.css to demo assets
    copy:
      demo:
        files:
          'build/popeye.css': 'node_modules/angular-popeye/release/popeye.css'

    # watch - rebuild demo files if any sources change
    watch:
      browserify:
        files: ['src/*.coffee']
        tasks: ['browserify:demo']
      sass:
        files: ['src/*.scss']
        tasks: ['sass:demo', 'postcss:demo']

  grunt.registerTask 'demo', ['clean', 'browserify:demo', 'sass:demo', 'postcss:demo', 'copy:demo']
  grunt.registerTask 'demo:watch', ['demo', 'watch']
  grunt.registerTask 'default', ['demo']
