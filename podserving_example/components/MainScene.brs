sub init()
  m.video = m.top.findNode("myVideo")
  m.video.notificationinterval = 1

  m.testPodservingStream = {
    title: "Sample live stream for DAI Pod Serving"
    assetKey: "google-sample"
    networkCode: "51636543"
    manifestUrl: "https://encodersim.sandbox.google.com/masterPlaylist/9c654d63-5373-4673-8c8d-6d92b66b9d46/master.m3u8?gen-seg-redirect=true&network=51636543&event=google-sample&pids=devrel4628000,devrel896000,devrel3528000,devrel1428000,devrel2628000,devrel1928000&seg-host=dai.google.com&stream_id=[[STREAMID]]"
    apiKey: ""
  }

  runIMASDKTask()
end sub

sub runIMASDKTask()
  m.IMASDKTask = createObject("roSGNode", "IMASDKTask")

  m.IMASDKTask.streamParameters = m.testPodservingStream
  m.IMASDKTask.videoNode = m.video

  m.IMASDKTask.observeField("IMASDKInitialized", "handleIMASDKInitialized")
  m.IMASDKTask.observeField("errors", "handleIMASDKErrors")
  m.IMASDKTask.observeField("urlData", "loadAdStitchedStream")

  ' Start the task thread.
  m.IMASDKTask.control = "RUN"
end sub

sub loadAdStitchedStream(message as object)
  print "Ad pod stream information ";message
  adPodStreamInfo = message.getData()
  streamId = adPodStreamInfo.streamId
  manifest = m.testPodservingStream.manifestUrl.Replace("[[STREAMID]]", streamId)
  playStream(manifest, adPodStreamInfo.format)
end sub

sub playStream(url as string, format as string)
  vidContent = createObject("RoSGNode", "ContentNode")
  vidContent.url = url
  vidContent.title = m.testPodservingStream.title
  vidContent.streamformat = format
  m.video.content = vidContent
  m.video.setFocus(true)
  m.video.visible = true
  m.video.control = "play"
  m.video.EnableCookies()
end sub

sub handleIMASDKInitialized()
  ' Follow your manifest manipulator (VTP) documentation to register a user
  ' streaming session if needed.
end sub

sub handleIMASDKErrors(message as object)
  print "------ IMA SDK failed  ------"
  if message <> invalid and message.getData() <> invalid
    print "IMA SDK Error ";message.getData()
  end if
end sub
