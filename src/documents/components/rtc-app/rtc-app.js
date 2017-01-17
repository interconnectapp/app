/* ---
browserify: true
--- */

/* global Polymer */
Polymer('rtc-app', {
	room: 'interconnect',
	host: 'https://switchboard.rtc.io/',
	peers: null,
	myStream: null,
	myName: null,
	myStreamURI: null,
	mySnapshotURI: null,
	myVideo: null,
	sounds: null,
	blipSound: null,
	callSound: null,
	ready: function(){
		console.log('-> READY');
		this.peers = {};
		this.loadSounds();
		this.loadConnection();
		return this;
	},
	loadConnection: function(){
		console.log('-> LOAD CONNECTION');
		var me = this;
		var signallerOpts = {
			room: me.room,
			iceServers: null
		};

		var iceFree = window.location.href.indexOf('ice=turn') === -1;

		if ( iceFree ) {
			signallerOpts.iceServers = require('freeice')();
			console.log('Using the free ICE servers:', signallerOpts.iceServers);
			me.setupConnection(signallerOpts);
		}
		else {
			require('dominject')({
				type: 'script',
				url: '//api.turnservers.com/api.js?key=OJdfWBPLubSrwOXduDWzFkfjBVSNQhLS',
				next: function(err, element) {
					if ( err ) {
						console.log('Failed to retrieve ICE servers', err);
						return;
					}
					window.turnserversDotComAPI.iceServers(function(data){
						signallerOpts.iceServers = data;
						console.log('Using the TURN ICE servers:', signallerOpts.iceServers);
						me.setupConnection(signallerOpts);
					})
				}
			});
		}

		return this;
	},
	loadSounds: function(){
		console.log('-> LOAD SOUNDS');
		var oggSupported = (new Audio()).canPlayType("audio/ogg; codecs=vorbis");
		if ( oggSupported ) {
			this.sounds = true;
			Audio.prototype.load = function(){
				this.preload = 'auto';  // true is not valid
				// this.play();
				// this.pause();
			};
			Audio.prototype.start = function(){
				this.pause();
				this.currentTime = 0;
				this.play();
			};
			this.blipSound = new Audio('#{SOUND}/notifications/Blip.ogg');
			this.callSound = new Audio('#{SOUND}/ringtones/Ubuntu.ogg');
			this.blipSound.load();
			this.callSound.load();
			this.callSound.loop = true;
		}
		return this;
	},
	startStream: function(peerID) {
		console.log('-> START STREAM', peerID);
		var me = this;
		var peer = me.getPeer(peerID);
		if ( !peer.streaming ) {
			var stream = me.myStream;
			console.log('start stream', peerID, stream);

			try {
				peer.connection.addStream(stream);
			}
			catch (err) {
				console.log('FAILED to add stream', stream, 'from peer', peerID, 'because of', err);
			}

			//peer.removeAttribute('muted');
			//peer.setAttribute('streaming', '');
			peer.streaming = true;
			peer.muted = false;

			peer.sendMessage({
				action: 'started-stream'
			});
		}
	},
	stopStream: function(peerID) {
		console.log('-> STOP STREAM', peerID);
		var me = this;
		var peer = me.getPeer(peerID);
		if ( peer.streaming ) {
			var stream = me.myStream;
			console.log('stop stream', peerID, stream);

			try {
				peer.connection.removeStream(stream);
			}
			catch (err) {
				console.log('FAILED to remove stream', stream, 'from peer', peerID, 'because of', err);
			}

			//peer.removeAttribute('streaming');
			//peer.setAttribute('muted', '');
			peer.streaming = false;
			peer.muted = true;

			peer.sendMessage({
				action: 'stopped-stream'
			});
		}
	},
	getPeer: function(peerID) {
		console.log('-> GET PEER', peerID);
		var me = this;
		var peer = me.peers[peerID] || null;
		if ( peer === null ) {
			// Create peer
			peer = document.createElement('rtc-person');
			peer.sendMessage = function(data) {
				console.log('send message', data, 'to', peerID, 'FAILED as data channel has not opened yet');
			};
			me.peers[peerID] = peer;
			me.$.people.appendChild(peer);
		}
		return peer;
	},
	destroyPeer: function(peerID) {
		console.log('-> DESTROY PEER', peerID);
		var me = this;
		var peer = me.peers[peerID] || null;
		if ( peer) {
			peer.parentNode.removeChild(peer);
			delete me.peers[peerID];
		}
		return null;
	},
	getName: function(){
		console.log('-> GET NAME');
		var me = this;
		while ( !me.myName ) {
			me.myName = prompt('What is your name?');
		}
		me.sendMessage({
			action: 'meta',
			meta: {
				name: me.myName
			}
		});
	},
	sendMessage: function(data){
		console.log('-> SEND MESSAGE', data);
		var me = this;
		var message = JSON.stringify(data);
		Object.keys(me.peers).forEach(function(peerID){
			var peer = me.peers[peerID];
			peer.sendMessage(message);
		});
	},
	setupConnection: function(signallerOpts){
		console.log('-> SETUP CONNECTION');
		var me = this;
		console.log('Setting up the connection with these options:', signallerOpts);
		me.signaller = require('rtc-quickconnect')(me.host, signallerOpts);
		me.signaller
			.reactive()
			.createDataChannel('messages')
			.on('channel:opened:messages', function(peerID, peerChannel){
				console.log('CHANNEL:OPENED:MESSAGES', peerID);

				var peer = me.getPeer(peerID);
				peer.channel = require('rtc-dcstream')(peerChannel);

				peer.sendMessage = function(data){
					if ( data.action !== 'snap' )  console.log('send message', data, 'to', peerID);

					var message = JSON.stringify(data);
					try {
						peer.channel.write(message);
					}
					catch (err) {
						console.log('send message', data, 'to', peerID, 'FAILED for reason', err);
					}
				};

				peer.sendMessage({
					action: 'meta',
					meta: {
						name: me.myName
					}
				});

				peer.channel.on('data', function(message) {
					var data = null;

					try {
						data = JSON.parse(message.toString() || '{}') || {};
					}
					catch (err) {
						console.log('FAILED to parse the data', data);
						return;
					}

					if ( data.action !== 'snap' )  console.log('received message', data, 'from', peerID);

					// console.log('remote stream', peerID, peer.connection.getLocalStreams(), peer.connection.getRemoteStreams());

					switch (data.action) {
						// Peer has sent us their latest meta data
						case 'meta':
							peer.name = (data.meta || {}).name;
							break;

						// Peer has sent their stream to us
						case 'started-stream':
							if ( me.sounds ) {
								me.blipSound.pause();
								me.callSound.pause();
							}
							me.startStream(peerID);
							break;

						// Peer has cancelled their stream
						case 'stopped-stream':
							me.stopStream(peerID);
							break;

						// Peer has sent us their latest snapshot
						case 'snap':
							peer.snapshotURI = data.snapshotURI;
							break;
					}
				});
			})
			.on('call:started', function(peerID, peerConnection, data){
				console.log('CALL:STARTED', peerID);
				var peer = me.getPeer(peerID);
				peer.className += 'peer';
				peer.streaming = false;
				peer.muted = false;
				peer.connection = peerConnection;
				peer.name = peer.id = peerID;

				peer.addEventListener('click', function(){
					if ( peer.status !== 'busy' && peer.status !== 'waiting' ) {
						if ( peer.status === 'streaming' ) {
							if ( me.sounds ) {
								me.blipSound.start();
								me.callSound.pause();
							}
							me.stopStream(peerID);
						} else {
							if ( me.sounds ) {
								me.blipSound.start();
								me.callSound.start();
							}
							me.startStream(peerID);
						}
					}
				});
			})
			.on('call:ended', function(peerID){
				console.log('CALL:ENDED', peerID);
				me.destroyPeer(peerID);
			})
			.on('stream:added', function(peerID, stream, data) {
				console.log('STREAM:ADDED', peerID);
				if ( me.sounds ) {
					me.blipSound.pause();
					me.callSound.pause();
				}
				peer.stream = stream;
				peer.streamURI = window.URL.createObjectURL(peer.stream);
				peer.stream.onended = function(){
					me.stopStream(peerID);
				};
				me.startStream(peerID);
			})
			.on('stream:removed', function(peerID) {
				console.log('STREAM:REMOVED', peerID);
				me.stopStream(peerID);
			});
	},
	mySnapshotURIChanged: function(oldValue, newValue){
		console.log('-> MY SNAPSHOT UI CHANGED');
		var me = this;
		// console.log('snapshot uri changed: ', newValue);
		if ( newValue ) {
			Object.keys(me.peers).forEach(function(peerID){
				var peer = me.peers[peerID];
				peer.sendMessage({
					action: 'snap',
					snapshotURI: newValue
				});
			});
		}
	}
});
