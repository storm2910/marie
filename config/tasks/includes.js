/**
 * `includes`
 *
 * ---------------------------------------------------------------
 *
 * Compile CoffeeScript files located in `assets/js` into Javascript
 * and generate new `.js` files in `.tmp/public/js`.
 *
 * For usage docs see:
 *   https://github.com/gruntjs/grunt-contrib-coffee
 *
 */
module.exports = function(grunt) {

  grunt.config.set('includes', {
    dev: {
      options: {
        includeRegexp: /^\/\/*import\s+['"]?([^'"]+)['"]?\s*$/,
        debug: false,
        duplicates: false,
        filenameSuffix: '.js'
      },
      files: [{
        expand: true,
        cwd: 'assets/js/',
        src: ['**/*.js'],
        dest: '.tmp/public/js/',
        ext: '.js'
      }]
    }
  });

  grunt.loadNpmTasks('grunt-includes');
};
