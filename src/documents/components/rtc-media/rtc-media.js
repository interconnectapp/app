/* ---
browserify: true
--- */

/* global Polymer */
Polymer('rtc-media', {
	capture: 'camera max:320x240',
	stream: null,
	streamURI: null,
	ready: function(){
		var me = this
		var constraints = require('rtc-captureconfig')(me.capture).toConstraints()
		require('getusermedia')(constraints, function (err, stream) {
			if ( err ) {
				return console.log('MEDIA FAILED because of', err)
			}
			me.stream = stream
			me.streamURI = window.URL.createObjectURL(stream)
		})
	}
})
