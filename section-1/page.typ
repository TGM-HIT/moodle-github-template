#import "@preview/moodular:0.1.0" as moodular: c4l

#let attachment(source) = [#metadata(source)<attachments>]
#let dependency(source) = [#metadata(source)<dependencies>]

#show: moodular.preview()
#show: c4l.blockquotes-as-c4l()
#show image: it => attachment(it.source) + it
#c4l.remove-spacer(true)

_This is a page_

#c4l.tip[You can use C4L components here!]
