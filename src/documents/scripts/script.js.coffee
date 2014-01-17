quickconnect = require("rtc-quickconnect")
media = require("rtc-media")
videoproc = require("rtc-videoproc")
captureConfig = require("rtc-captureconfig")
grayScaleFilter = require("rtc-videoproc/filters/grayscale")
$ = jQuery = require("jquery-browserify")

window.$ = window.jQuery = jQuery

MiniView = require('miniview').View
{Pointer} = require('pointers')
{QueryCollection} = require('query-engine')

class View extends MiniView
	point: (args...) ->
		pointer = new Pointer(args...)
		(@pointers ?= []).push(pointer)
		return pointer

	destroy: ->
		pointer.destroy()  for pointer in @pointers  if @pointers
		@pointers = null
		return super

# Define the Base Collection that uses QueryEngine.
# QueryEngine adds NoSQL querying abilities to our collections
class Collection extends QueryCollection
	collection: Collection

# Define the Base Model that uses Backbone.js
class Model extends window.Backbone.Model


class Person extends Model
	# Everyone
	stream: false
	media: false
	video: false
	canvas: false

	# Peers
	snap: false
	streamingTo: false
	streamingFrom: false

	# Attributes
	default:
		# Everyone
		id: null
		name: false

class People extends Collection
	model: Person
	collection: People

# Person View
class PersonView extends View
	el: $('.person:last').remove().first().prop('outerHTML')

	elements:
		'.name': '$name'
		'.video': '$video'
		'.image': '$image'
		'.stream': '$stream'

	render: =>
		# Prepare
		{item, $el, $name} = @

		# Apply
		$el.addClass('person-'+item.id)

		# Apply
		@point(
			item: item
			itemAttributes: ['name']
			element: $name
		).bind()

		# Chain
		@


# App
class App extends View
	el: $('.app:last').remove().first().prop('outerHTML')

	config: null
	signaller: null
	local: null
	peers: null

	elements:
		'.peers': '$peers'

	constructor: (opts) ->
		super

		@config = opts

		@local = new Person(
			id: 'self'
			name: prompt('What is your name?')
		)

		@localView = new PersonView(
			item: @local
		)
		@localView.render().$el.addClass('me').prependTo(@$el)

		@peersCollection = new People([], {
			name: 'Peers Collection'
		})

		@

	# Create high bandwidth local stream
	createLocalStream: ->
		@local.media = media(@config.mediaOptions)

		@local.media.once('capture', (stream) =>
			console.log 'CAPTURED STREAM', stream
			@local.stream = stream
		)

		$(@local.media.render @localView.$video.get(0))
			.attr('muted', '')
			#.attr('controls', '')
			.addClass('mine')
			.removeClass('hidden')

		@

	createLocalSnaps: ->
		@local.canvas = videoproc(document.body, @config.snapOptions)
		#@local.canvas.width = 320/2
		#@local.canvas.height = 240/2
		@local.canvas.style.display = "none"
		@local.media.render(@local.canvas)

		# add the processing options
		@local.canvas.pipeline.add(grayScaleFilter)

		# once the canvas has been updated with the filters applied
		# capture the image data from the canvas and send via the data channel
		@local.canvas.addEventListener "postprocess", (event) =>
			snap = @getSnap()
			@peersCollection.each (peer) =>
				if peer.streamingTo is false
					@sendSnap(peer.id, snap)

		@

	getSnap: ->
		@local.canvas.toDataURL(@config.snapOptions.mime, @config.snapOptions.quality)

	sendSnap: (peerId, snap) ->
		snap ?= @getSnap()
		@sendMessage(peerId, {action:'snap', snap})

	sendStream: (peerId) ->
		peer = @getPeer(peerId)
		if peer.streamingTo is false
			peer.connection.addStream(@local.stream)
			peer.streamingTo = true
			@sendMessage(peerId, {action:'sent-stream'})
		@

	cancelStream: (peerId) ->
		peer = @getPeer(peerId)
		if peer.streamingTo is true
			peer.connection.removeStream(@local.stream)  if @local.stream?
			peer.streamingTo = false
			@sendMessage(peerId, {action:'cancelled-stream', snap:@getSnap()})
		@

	createConnection: ->
		@signaller = quickconnect(@config.signalHost, @config.connectionOptions)

		@signaller
			.createDataChannel("messages")

			.on("messages:open", (peerChannel, peerId) =>
				peer = @getPeer(peerId)
				peer.channel = peerChannel

				@sendMessage(peerId, {action:'get-peer-data'})

				peer.channel.onmessage = (event) =>
					data = JSON.parse(event.data or '{}') or {}
					console.log('received message', data, 'from', peerId, 'event', event)  if data.action isnt 'snap'

					switch data.action
						when 'send-stream'
							console.log 'SEND STREAM', peerId
							if @local.stream
								@sendStream(peerId)

						when 'cancel-stream'
							console.log 'CANCEL STREAM', peerId
							@cancelStream(peerId)

						when 'get-peer-data'
							@sendMessage(peerId, {
								action: 'set-peer-data'
								attributes:
									name: @local.get('name')
							})

						when 'set-peer-data'
							peer.set(data.attributes)

						# NOTE:
						# This is here as the addstream event only works once
						# Rather than every time
						when 'sent-stream'
							console.log 'SENT STREAM', peerId
							@showPeerStream(peerId)
							@sendStream(peerId)

						when 'cancelled-stream'
							console.log 'CANCELLED STREAM', peerId
							@cancelStream(peerId)
							#@sendMessage(peerId, {action:'cancel-stream'})

							{$image, $video} = @getPeerView(peerId)

							@destroyPeerStream(peerId)
							$video
								.addClass('hidden')

							$image
								.attr("src", data.snap)
								.removeClass('hidden')

						when 'snap'
							{$image, $video} = @getPeerView(peerId)

							$image
								.attr("src", data.snap)
								.removeClass('hidden')
			)

			.on("peer:connect", (peerConnection, peerId, data, monitor) =>
				peer = @getPeer(peerId)
				peer.connection = peerConnection

				#setInterval(
				#	-> console.log 'REMOTE STREAMS:', peerId, peerConnection.getRemoteStreams()
				#	5000
				#)

				# NOTE:
				# The addstream event doesn't fire for streams that have been added previously
				# As such, add stream only fires the first time a stream is shared
				# For subsequent shares, we rely on sent-stream
				peerConnection.onaddstream = (event) =>
					console.log 'ADD STREAM', peerId
					peer.stream = event.stream
					@showPeerStream(peerId)

					#event.stream.onended = -> destroyPeerStream(peerId)
				#peerConnection.onremovestream = (event) -> destroyPeerStream(peerId)
		  	)

			.on("peer:leave", (peerId) =>
				@destroyPeer(peerId)
			)

		@

	getPeer: (peerId) ->
		peer = @peersCollection.get(peerId)
		return peer  if peer

		peer = new Person(
			id: peerId
		)
		@peersCollection.add(peer)

		return peer

	getPeerView: (peerId) ->
		return @$el.find('.person-'+peerId).data('view')

	destroyPeer: (peerId) ->
		@destroyPeerStream(peerId)
		@peersCollection.remove(peerId)
		@

	destroyPeerStream: (peerId) ->
		peer = @getPeer(peerId)

		if peer?.media
			peer.media = false

		@

	showPeerStream: (peerId) ->
		peer = @getPeer(peerId)

		console.log 'SHOW STREAM BEFORE', peerId, peer.connection?.getRemoteStreams()

		if peer and peer.stream
			console.log 'SHOW STREAM', peerId
			peer.media = media(peer.stream)  if peer.media is false

			$(peer.media.render @getPeerView(peerId).$video.get(0))
				.data('peerId', peerId)
				#.attr('controls', '')
				.removeClass('hidden')


		@

	sendMessage: (peerId, data) ->
		peer = @getPeer(peerId)
		console.log('send message', data, 'to', peerId)  if data.action isnt 'snap'

		if peer and peer.channel
			message = JSON.stringify(data)
			peer.channel.send(message)

		@


	render: ->
		@$el.on("click", ".peers .stream", (event) =>
			peer = $(event.target).parents('.person:first').data('view').item
			if peer.video
				action = 'cancel-stream'
			else
				action = 'send-stream'
			@sendMessage(peer.id, {action})
		)

		@point(
			item: @peersCollection
			viewClass: PersonView
			element: @$peers
		).bind()

		@

	setup: ->
		@createLocalStream()
		@createLocalSnaps()
		@createConnection()
		@render()
		@

app = new App(
	signalHost: location.href.replace(/(^.*\/).*$/, "$1")  # 'http://rtc.io/switchboard/'
	connectionOptions:
		room: "demo-snaps"
		debug: false
	snapOptions:
		fps: 0.2
		mime: 'image/jpeg'
		quality: 0.5
	mediaOptions:
		muted: false
		constraints: captureConfig("camera max:320x240").toConstraints()
)
app.setup()
app.$el.appendTo(document.body)

