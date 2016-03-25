/**
 * `coffee`
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

  grunt.config.set('coffee', {
    dev: {
      options: {
        bare: false,
        sourceMap: true,
        sourceRoot: './bundles/',
        duplicates: false,
        debug: false
      },
      files: [{
        expand: true,
        cwd: '.tmp/public/js/bundles/',
        src: ['**/*.coffee'],
        dest: '.tmp/public/js/',
        ext: '.js'
      }]
    }
  });

  grunt.loadNpmTasks('grunt-contrib-coffee');
};
