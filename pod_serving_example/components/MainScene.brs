sub init()
  m.video = m.top.findNode("myVideo")
  m.video.notificationinterval = 1

  ' NOTE: These stream parameters are for example purposes only, and are
  ' not functional. Replace them with your own stream parameters.
  ' Live Stream
  m.streamParameters = {
    streamType: "Live",
    title: "Sample live stream for DAI Pod Serving",
    networkCode: "21775744923",
    apiKey: "",
    assetKey: assetKey: "google-sample",
    VTPManifest: "https://.../manifest.m3u8?gam-stream-id=[[STREAMID]]",
    subtitleConfig: [] ' Specifies the caption settings for content playback
                       ' following Roku's content metadata format at https://developer.roku.com/docs/developer-program/getting-started/architecture/content-metadata.md
  }

'  ' VOD Stream
'  m.streamParameters = {
'    streamType: "VOD",
'    title: "Sample VOD stream for DAI Pod Serving",
'    networkCode: "21775744923",
'    VTPManifest: "https://.../manifest.m3u8?gam-stream-id=[[STREAMID]]",
'    subtitleConfig: [] ' Specifies the caption settings for content playback
'                       ' following Roku's content metadata format at https://developer.roku.com/docs/developer-program/getting-started/architecture/content-metadata.md
'  }

  runIMASDKTask()
end sub

sub runIMASDKTask()
  m.IMASDKTask = createObject("roSGNode", "IMASDKTask")

  m.IMASDKTask.streamParameters = m.streamParameters
  m.IMASDKTask.videoNode = m.video

  m.IMASDKTask.observeField("IMASDKInitialized", "handleIMASDKInitialized")
  m.IMASDKTask.observeField("errors", "handleIMASDKErrors")
  m.IMASDKTask.observeField("streamInfo", "loadStream")

  ' Start the task thread.
  m.IMASDKTask.control = "RUN"
end sub

sub loadStream(message as object)
  print "Ad pod stream information ";message
  streamInfo = message.getData()

  vidContent = createObject("RoSGNode", "ContentNode")
  vidContent.title = m.IMASDKTask.streamParameters.title
  vidContent.url = streamInfo.manifest
  vidContent.subtitleConfig = streamInfo.subtitle
  vidContent.streamformat = streamInfo.format
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
