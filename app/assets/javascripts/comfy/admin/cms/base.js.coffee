window.CMS ||= {}

window.CMS.code_mirror_instances = [ ]

unless Turbolinks?.controller? # Turbolinks 5 verification
  $ -> window.CMS.init()

$(document).on 'page:load turbolinks:load', -> window.CMS.init()
document.addEventListener 'turbolinks:before-cache', -> window.CMS.dispose()

window.CMS.dispose = ->
  CMS.files.dispose()
  CMS.fileUpload.dispose()

window.CMS.init = ->
  window.CMS.current_path = window.location.pathname
  CMS.slugify()
  CMS.wysiwyg()
  CMS.codemirror()
  CMS.sortableList()
  CMS.timepicker()
  CMS.pageFragments()
  CMS.categories()
  CMS.files.init()
  CMS.fileLinks()
  CMS.fileUpload.init()
  CMS.diff()


window.CMS.wysiwyg = ->
  csrf_token = $('meta[name=csrf-token]').attr('content')
  csrf_param = $('meta[name=csrf-param]').attr('content')

  if (csrf_param != undefined && csrf_token != undefined)
    params = csrf_param + "=" + encodeURIComponent(csrf_token)

  file_upload_path  = $("meta[name='cms-file-upload-path']").attr("content")
  pages_path        = $("meta[name='cms-pages-path']").attr("content")

  $('textarea.rich-text-editor, textarea[data-cms-rich-text]').redactor
    minHeight:        160
    autoresize:       true
    imageUpload:      "#{file_upload_path}?source=redactor&type=image&#{params}"
    imageManagerJson: "#{file_upload_path}?source=redactor&type=image"
    fileUpload:       "#{file_upload_path}?source=redactor&type=file&#{params}"
    fileManagerJson:  "#{file_upload_path}?source=redactor&type=file"
    definedLinks:     "#{pages_path}?source=redactor"
    buttonSource:     true
    formatting:       ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']
    plugins:          ['imagemanager', 'filemanager', 'table', 'video', 'definedlinks']
    lang:             $("meta[name='cms-locale']").attr("content")
    convertDivs:      false


window.CMS.codemirror = ->
  $('textarea[data-cms-cm-mode]').each (i, element) ->
    cm = CodeMirror.fromTextArea element,
      mode:           $(element).data('cms-cm-mode')
      tabSize:        2
      lineWrapping:   true
      autoCloseTags:  true
      lineNumbers:    true
      viewportMargin: Infinity

    CMS.code_mirror_instances.push(cm)

  $('a[data-toggle="tab"]').on 'shown.bs.tab', ->
    for cm in CMS.code_mirror_instances
      cm.refresh()


window.CMS.sortableList = ->
  dataIdAttr = 'data-id'
  sortableStore =
    get: (sortable) ->
      Array::map.call sortable.el.children, (el) -> el.getAttribute(dataIdAttr)
    set: (sortable) ->
      $.ajax
        url:      "#{CMS.current_path}/reorder"
        type:     'POST'
        dataType: 'json'
        data:
          order:    sortable.toArray()
          _method:  'PUT'

  for root in document.querySelectorAll('.sortable')
    Sortable.create root,
      handle:     '.dragger'
      draggable:  'li'
      dataIdAttr: dataIdAttr
      store:      sortableStore
      onStart:    (evt) -> evt.from.classList.add('sortable-active')
      onEnd:      (evt) -> evt.from.classList.remove('sortable-active')


window.CMS.timepicker = ->
  $('input[type=text][data-cms-datetime]').flatpickr
    format:     'yyyy-mm-dd hh:ii'
    enableTime: true
    locale:     $("meta[name='cms-locale']").attr("content")

  $('input[type=text][data-cms-date]').flatpickr
    format: 'yyyy-mm-dd',
    locale: $("meta[name='cms-locale']").attr("content")


window.CMS.categories = ->
  $('button.toggle-cat-edit', '.categories-widget').click (event) ->
    event.preventDefault()
    $('.read', '.categories-widget').toggle()
    $('.editable', '.categories-widget').toggle()
    $('.edit', '.categories-widget').toggle()
    $('.done', '.categories-widget').toggle()


window.CMS.diff = ->
  $(".revision").prettyTextDiff
    cleanup:            true
    originalContainer:  '.original'
    changedContainer:   '.current'
    diffContainer:      '.diff .content'
