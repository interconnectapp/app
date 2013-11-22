/* Your scripts go here */
// var detect = require('rtc-core/detect');
// navigator.getUserMedia = detect.call(navigator, 'getUserMedia');

// window.URL = window.URL || detect('URL');

// var constraints = {
//   video: {
//     mandatory: {
//       minFrameRate: 1,
//       maxFrameRate: 1
//     }, optional: []
//   },
//   audio: true
// };

// navigator.getUserMedia(constraints, renderMedia, function (err) {
//   console.log('could not capture media ', err);
// });

// function renderMedia (stream) {
//   var video = document.createElement('video');
//   video.setAttribute('autoplay', true);
//   video.setAttribute('muted', true);

//   if (typeof video.mozSrcObject != 'undefined') {
//     video.mozSrcObject = stream;
//   } else {
//     video.src = URL.createObjectURL(stream);
//   }

//   document.body.appendChild(video);
// }

var media = require('rtc-media');
var canvas = require('rtc-canvas');
var vid;

var sidebar = document.getElementsByTagName('sidebar')[0];

var constraints = {
 audio: true,
 video: {
  mandatory: {
    maxWidth: 640,
    maxHeight: 360
  },
  optional: []
 }
};

media({constraints: constraints}).render(vid = canvas(sidebar, { fps: 0.5 }));

vid.pipeline.add(function (imageData) {
  var channels = imageData.data;
  var channelCount = channels.length;

  // iterate through the data
  for (var ii = 0; ii < channelCount; ii += 4) {
    // update the values to the rgb average
    channels[ii] =       // update R
      channels[ii + 1] = // update G
      channels[ii + 2] = // update B
      (channels[ii] + channels[ii + 1] + channels[ii + 2] ) / 3;
  }

  // return true to flag that we want to write our pixel data
  // back to the canvas
  return true;
});

var canvas = document.getElementsByTagName('canvas')[0];
canvas.style.zoom = 0.25;
