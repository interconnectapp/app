// The DocPad Configuration File
// It is simply a CoffeeScript Object which is parsed by CSON
'use strict'
module.exports = {
	// =================================
	// Template Data
	// These are variables that will be accessible via our templates
	// To access one of these within our templates, refer to the FAQ: https://github.com/bevry/docpad/wiki/FAQ

	templateData: {
		ROOT:      'https://interconnectapp.github.io/app',
		BOWER:     'https://interconnectapp.github.io/app/bower_components',
		COMPONENT: 'https://interconnectapp.github.io/app/components',
		SOUND:     'https://interconnectapp.github.io/app/sounds',

		// Specify some site properties
		site: {
			// The production url of our website
			url: 'https://interconnectapp.github.io/app',

			// The default title of our website
			title: 'Interconnect',

			// The website description (for SEO)
			description: 'High-bandwidth virtual office for open teams. Public rooms are free. Private rooms cost. FOSS.',

			// The website keywords (for SEO) separated by commas
			keywords: 'interconnect, webrtc, irc, chat, community, communities, connect, connected, recording, recorded',

			// The website's styles
			styles: [
				// '#{ROOT}/vendor/normalize.css'
				// '#{ROOT}/vendor/h5bp.css'
				// '#{ROOT}/styles/style.css'
			],

			// The website's scripts
			scripts: [
				'#{BOWER}/platform/platform.js'
				// '#{BOWER}/polymer/polymer.js'
				// '#{BOWER}/script-bundled.js'
			]
		},


		// -----------------------------
		// Helper Functions

		// Get the prepared site/document title
		// Often we would like to specify particular formatting to our page's title
		// we can apply that formatting here
		getPreparedTitle: function () {
			// if we have a document title, then we should use that and suffix the site's title onto it
			if ( this.document.title ) {
				return this.document.title + " | " + this.site.title
			}
			// if our document does not have it's own title, then we should just use the site's title
			else {
				return this.site.title
			}
		},

		// Get the prepared site/document description
		getPreparedDescription: function () {
			// if we have a document description, then we should use that, otherwise use the site's description
			return this.document.description || this.site.description
		},

		// Get the prepared site/document keywords
		getPreparedKeywords: function () {
			// Merge the document keywords with the site keywords
			return this.site.keywords.concat(this.document.keywords || []).join(', ')
		}
	},


	// =================================
	// DocPad Environments

	environments: {
		development: {
			templateData: {
				ROOT:      '/',
				BOWER:     '/bower_components',
				COMPONENT: '/components',
				SOUND:     '/sounds',
				site:  {
					url: '/'
				}
			}
		}
	},

	// =================================
	// DocPad Events

	// Here we can define handlers for events that DocPad fires
	// You can find a full listing of events on the DocPad Wiki
	events: {

		renderDocument: function (opts) {
			opts.content = opts.content.replace(/#{([A-Z_]+)}/g, function (match, part) {
				return opts.templateData[part]
			})
			return true
		},

		// Server Extend
		// Used to add our own custom routes to the server before the docpad routes are added
		serverExtend: function (opts) {
			// Extract the server from the options
			var serverHttp = opts.serverHttp
			var serverExpress = opts.serverExpress
			var docpad = this.docpad

			// As we are now running in an event,
			// ensure we are using the latest copy of the docpad configuraiton
			// and fetch our urls from it
			var latestConfig = docpad.getConfig()
			var oldUrls = latestConfig.templateData.site.oldUrls || []
			var newUrl = latestConfig.templateData.site.url

			// Signaller
			var switchboard = require('rtc-switchboard')(serverHttp)
			serverExpress.get('/rtc.io/primus.js', switchboard.library())

			// Done
			return true
		}
	}
}
