###
  Style.color adapted from 4chan Style Script
###

ThemeTools =
  init: (key) ->
    Conf['editMode'] = "theme"

    if key
      editTheme = JSON.parse(JSON.stringify(Themes[key]))
      editTheme["Theme"] = if Conf['userThemes'][key]
        key
      else
        key += " [custom]"
    else
      editTheme = JSON.parse(JSON.stringify(Themes['Yotsuba B']))
      editTheme["Theme"]  = "Untitled"
      editTheme["Author"] = "Author"
      editTheme["Author Tripcode"] = "Unknown"

    # Objects are not guaranteed to have any type of arrangement, so we use a presorted
    # array to generate the layout of of the theme editor.
    # (Themes aren't even guaranteed to have any of these values, actually)
    layout = [
      "Background Image"
      "Background Attachment"
      "Background Position"
      "Background Repeat"
      "Background Color"
      "Thread Wrapper Background"
      "Thread Wrapper Border"
      "Dialog Background"
      "Dialog Border"
      "Reply Background"
      "Reply Border"
      "Highlighted Reply Background"
      "Highlighted Reply Border"
      "Backlinked Reply Outline"
      "Input Background"
      "Input Border"
      "Hovered Input Background"
      "Hovered Input Border"
      "Focused Input Background"
      "Focused Input Border"
      "Checkbox Background"
      "Checkbox Border"
      "Checkbox Checked Background"
      "Buttons Background"
      "Buttons Border"
      "Navigation Background"
      "Navigation Border"
      "Links"
      "Hovered Links"
      "Quotelinks"
      "Backlinks"
      "Navigation Links"
      "Hovered Navigation Links"
      "Names"
      "Tripcodes"
      "Emails"
      "Subjects"
      "Text"
      "Inputs"
      "Post Numbers"
      "Greentext"
      "Sage"
      "Board Title"
      "Timestamps"
      "Warnings"
      "Shadow Color"
    ]

    ThemeTools.dialog = $.el "div",
      id: "themeConf"
      className: "reply dialog"
      innerHTML: "
<div id=themebar>
</div>
<hr>
<div id=themecontent>
</div>
<div id=save>
  <a href='javascript:;'>Save</a>
</div>
<div id=upload>
  <a href='javascript:;'>Select Image</a>
</div>
<div id=close>
  <a href='javascript:;'>Close</a>
</div>
"

    header = $.el "div",
      innerHTML: "
<input class='field subject' name='Theme' placeholder='Theme' value='#{key}'> by
<input class='field name' name='Author' placeholder='Author' value='#{editTheme['Author']}'>
<input class='field postertrip' name='Author Tripcode' placeholder='Author Tripcode' value='#{editTheme['Author Tripcode']}'>"

    # Setup inputs that are not generated from the layout variable.
    for input in $$("input", header)
      $.on input, 'blur', ->
        editTheme[@name] = @value
    $.add $("#themebar", ThemeTools.dialog), header
    themeContent = $("#themecontent", ThemeTools.dialog)

    nodes = []
    
    for item in layout
      unless editTheme[item]
        editTheme[item] = ''

      div = $.el "div",
        className: "themevar"
        innerHTML: "<div class=optionname><b>#{item}</b></div><div class=option><input name='#{item}' placeholder='#{if item == "Background Image" then "Shift+Click to upload image" else item}'>"

      input = $('input', div)

      input.value = editTheme[item]

      switch item
        when "Background Image"
          input.className = 'field'
          fileInput = $.el 'input',
            type: 'file'
            accept:   "image/*"
            title:    "BG Image"
            hidden:   "hidden"

          $.on input, 'click', (evt) ->
            if evt.shiftKey
              @nextSibling.click()

          $.on fileInput, 'change', (evt) ->
            ThemeTools.uploadImage evt, @

          $.after input, fileInput

        when "Background Attachment" ,"Background Position", "Background Repeat"
          input.className = 'field'

        else
          input.className = "colorfield"

          colorInput = $.el 'input',
            className: 'color'
            value: "##{Style.colorToHex(input.value) or 'aaaaaa'}"

          JSColor.bind colorInput

          $.after input, colorInput

      $.on input, 'blur', ->
        depth = 0
        toggle1 = false
        toggle2 = false
        len = @value.length

        if len < 1000
          i = 0
          while i < len
            switch @value[i++]
              when '(' then ++depth
              when ')' then --depth
              when '"' then toggle1 = !toggle1
              when "'" then toggle2 = !toggle2

        if (depth isnt 0) or toggle1 or toggle2
          return alert "Syntax error on #{@name}."

        if @className == "colorfield"
          @nextSibling.value = "##{Style.colorToHex(@value) or 'aaaaaa'}"
          @nextSibling.color.importColor()

        editTheme[@name] = @value
        Style.addStyle(editTheme)

      nodes.push div

    Style.addStyle(editTheme)

    unless editTheme["Custom CSS"]
      editTheme["Custom CSS"] = ""

    div = $.el "div",
      className: "themevar"
      innerHTML: "<div class=optionname><b>Custom CSS</b></div><div class=option><textarea name='Custom CSS' placeholder='Custom CSS'>#{editTheme['Custom CSS']}</textarea>"

    $.on $('textarea', div), 'blur', ->
      editTheme["Custom CSS"] = @value
      Style.themeCSS.textContent  = Style.theme editTheme

    nodes.push div

    $.on $('#save > a', ThemeTools.dialog), 'click', ->
      ThemeTools.save editTheme

    $.on  $('#close > a', ThemeTools.dialog), 'click', ThemeTools.close

    $.add themeContent, nodes

    $.add d.body, ThemeTools.dialog
    Style.themeCSS.textContent  = Style.theme editTheme

  uploadImage: (evt, el) ->
    file = evt.target.files[0]
    reader = new FileReader()

    reader.onload = (evt) ->
      val = 'url("' + evt.target.result + '")'

      el.previousSibling.value = val
      editTheme["Background Image"] = val
      Style.themeCSS.textContent  = Style.theme editTheme

    reader.readAsDataURL file

  importtheme: (origin, evt) ->
    file = evt.target.files[0]
    reader = new FileReader()

    reader.onload = (e) ->

      try
        imported = JSON.parse e.target.result
      catch err
        alert err
        return

      unless (origin != 'appchan' and imported.mainColor) or (origin == 'appchan' and imported["Author Tripcode"])
        alert "Theme file is invalid."
        return
      name = imported.name or imported["Theme"]
      delete imported.name

      if Themes[name] and not Themes[name]["Deleted"]
        if confirm "A theme with this name already exists. Would you like to over-write?"
          delete Themes[name]
        else
          return

      if origin == "oneechan" or origin == "SS"
        bgColor     = new Style.color(imported.bgColor);
        mainColor   = new Style.color(imported.mainColor);
        brderColor  = new Style.color(imported.brderColor);
        inputColor  = new Style.color(imported.inputColor);
        inputbColor = new Style.color(imported.inputbColor);
        blinkColor  = new Style.color(imported.blinkColor);
        jlinkColor  = new Style.color(imported.jlinkColor);
        linkColor   = new Style.color(imported.linkColor);
        linkHColor  = new Style.color(imported.linkHColor);
        nameColor   = new Style.color(imported.nameColor);
        quoteColor  = new Style.color(imported.quoteColor);
        sageColor   = new Style.color(imported.sageColor);
        textColor   = new Style.color(imported.textColor);
        titleColor  = new Style.color(imported.titleColor);
        tripColor   = new Style.color(imported.tripColor);
        timeColor   = new Style.color(imported.timeColor || imported.textColor);

        if imported.bgRPA
          bgRPA = imported.bgRPA.split(' ')
        else
          bgRPA = ['no-repeat', 'bottom', 'left', 'fixed']

        if origin == "oneechan"
          Themes[name] =
            'Author'                      : "Anonymous"
            'Author Tripcode'             : "!POMF.9waa"
            'Background Image'            : "url('#{imported.bgImg or ''}')"
            'Background Attachment'       : "#{bgRPA[3] or ''}"
            'Background Position'         : "#{bgRPA[1] or ''} #{bgRPA[2] or ''}"
            'Background Repeat'           : "#{bgRPA[0] or ''}"
            'Background Color'            : "rgb(#{bgColor.rgb})"
            'Dialog Background'           : "rgba(#{mainColor.rgb},.98)"
            'Dialog Border'               : "rgb(#{brderColor.rgb})"
            'Thread Wrapper Background'   : "rgba(0,0,0,0)"
            'Thread Wrapper Border'       : "rgba(0,0,0,0)"
            'Reply Background'            : "rgba(#{mainColor.rgb},#{imported.replyOp})"
            'Reply Border'                : "rgb(#{brderColor.rgb})"
            'Highlighted Reply Background': "rgba(#{mainColor.shiftRGB(4, true)}, #{imported.replyOp})"
            'Highlighted Reply Border'    : "rgb(#{linkColor.rgb})"
            'Backlinked Reply Outline'    : "rgb(#{linkColor.rgb})"
            'Checkbox Background'         : "rgba(#{inputColor.rgb}, #{imported.replyOp})"
            'Checkbox Border'             : "rgb(#{inputbColor.rgb})"
            'Checkbox Checked Background' : "rgb(#{inputColor.rgb})"
            'Input Background'            : "rgba(#{inputColor.rgb}, #{imported.replyOp})"
            'Input Border'                : "rgb(#{inputbColor.rgb})"
            'Hovered Input Background'    : "rgba(#{inputColor.hover}, #{imported.replyOp})"
            'Hovered Input Border'        : "rgb(#{inputbColor.rgb})"
            'Focused Input Background'    : "rgba(#{inputColor.hover}, #{imported.replyOp})"
            'Focused Input Border'        : "rgb(#{inputbColor.rgb})"
            'Buttons Background'          : "rgba(#{inputColor.rgb}, #{imported.replyOp})"
            'Buttons Border'              : "rgb(#{inputbColor.rgb})"
            'Navigation Background'       : "rgba(#{bgColor.rgb}, 0.8)"
            'Navigation Border'           : "rgb(#{mainColor.rgb})"
            'Quotelinks'                  : "rgb(#{linkColor.rgb})"
            'Links'                       : "rgb(#{linkColor.rgb})"
            'Hovered Links'               : "rgb(#{linkHColor.rgb})"
            'Navigation Links'            : "rgb(#{textColor.rgb})"
            'Hovered Navigation Links'    : "rgb(#{linkHColor.rgb})"
            'Subjects'                    : "rgb(#{titleColor.rgb})"
            'Names'                       : "rgb(#{nameColor.rgb})"
            'Sage'                        : "rgb(#{sageColor.rgb})"
            'Tripcodes'                   : "rgb(#{tripColor.rgb})"
            'Emails'                      : "rgb(#{linkColor.rgb})"
            'Post Numbers'                : "rgb(#{linkColor.rgb})"
            'Text'                        : "rgb(#{textColor.rgb})"
            'Backlinks'                   : "rgb(#{linkColor.rgb})"
            'Greentext'                   : "rgb(#{quoteColor.rgb})"
            'Board Title'                 : "rgb(#{textColor.rgb})"
            'Timestamps'                  : "rgb(#{timeColor.rgb})"
            'Inputs'                      : "rgb(#{textColor.rgb})"
            'Warnings'                    : "rgb(#{sageColor.rgb})"
            'Shadow Color'                : "rgba(0,0,0,0.1)"
            'Custom CSS'                  : """<%= grunt.file.read('src/General/css/theme.oneechan.css') %> #{imported.customCSS or ''}"""

        else if origin == "SS"
          Themes[name] =
            'Author'                      : "Anonymous"
            'Author Tripcode'             : "!.pC/AHOKAg"
            'Background Image'            : "url('#{imported.bgImg or ''}')"
            'Background Attachment'       : "#{bgRPA[3] or ''}"
            'Background Position'         : "#{bgRPA[1] or ''} #{bgRPA[2] or ''}"
            'Background Repeat'           : "#{bgRPA[0] or ''}"
            'Background Color'            : "rgb(#{bgColor.rgb})"
            'Dialog Background'           : "rgba(#{mainColor.rgb}, .98)"
            'Dialog Border'               : "rgb(#{brderColor.rgb})"
            'Thread Wrapper Background'   : "rgba(#{mainColor.rgb}, .5)"
            'Thread Wrapper Border'       : "rgba(#{brderColor.rgb}, .9)"
            'Reply Background'            : "rgba(#{mainColor.rgb}, .9)"
            'Reply Border'                : "rgb(#{brderColor.rgb})"
            'Highlighted Reply Background': "rgba(#{mainColor.shiftRGB(4, true)}, .9)"
            'Highlighted Reply Border'    : "rgb(#{linkColor.rgb})"
            'Backlinked Reply Outline'    : "rgb(#{linkColor.rgb})"
            'Checkbox Background'         : "rgba(#{inputColor.rgb}, .9)"
            'Checkbox Border'             : "rgb(#{inputbColor.rgb})"
            'Checkbox Checked Background' : "rgb(#{inputColor.rgb})"
            'Input Background'            : "rgba(#{inputColor.rgb}, .9)"
            'Input Border'                : "rgb(#{inputbColor.rgb})"
            'Hovered Input Background'    : "rgba(#{inputColor.hover}, .9)"
            'Hovered Input Border'        : "rgb(#{inputbColor.rgb})"
            'Focused Input Background'    : "rgba(#{inputColor.hover}, .9)"
            'Focused Input Border'        : "rgb(#{inputbColor.rgb})"
            'Buttons Background'          : "rgba(#{inputColor.rgb}, .9)"
            'Buttons Border'              : "rgb(#{inputbColor.rgb})"
            'Navigation Background'       : "rgba(#{bgColor.rgb}', 0.8)"
            'Navigation Border'           : "rgb(#{mainColor.rgb})"
            'Quotelinks'                  : "rgb(#{linkColor.rgb})"
            'Links'                       : "rgb(#{linkColor.rgb})"
            'Hovered Links'               : "rgb(#{linkHColor.rgb})"
            'Navigation Links'            : "rgb(#{textColor.rgb})"
            'Hovered Navigation Links'    : "rgb(#{linkHColor.rgb})"
            'Subjects'                    : "rgb(#{titleColor.rgb})"
            'Names'                       : "rgb(#{nameColor.rgb})"
            'Sage'                        : "rgb(#{sageColor.rgb})"
            'Tripcodes'                   : "rgb(#{tripColor.rgb})"
            'Emails'                      : "rgb(#{linkColor.rgb})"
            'Post Numbers'                : "rgb(#{linkColor.rgb})"
            'Text'                        : "rgb(#{textColor.rgb})"
            'Backlinks'                   : "rgb(#{linkColor.rgb})"
            'Greentext'                   : "rgb(#{quoteColor.rgb})"
            'Board Title'                 : "rgb(#{textColor.rgb})"
            'Timestamps'                  : "rgb(#{timeColor.rgb})"
            'Inputs'                      : "rgb(#{textColor.rgb})"
            'Warnings'                    : "rgb(#{sageColor.rgb})"
            'Shadow Color'                : "rgba(0,0,0,0.1)"
            'Custom CSS'                  : """<%= grunt.file.read('src/General/css/theme.4chanss.css') %> #{imported.customCSS or ''}"""

      else if origin == 'appchan'
        Themes[name] = imported

      userThemes = $.get "userThemes", {}, ({userThemes})->
        userThemes[name] = Themes[name]
        $.set 'userThemes', userThemes
        alert "Theme \"#{name}\" imported!"
        $.rm $("#themes", d.body)
        Settings.open 'themes'

    reader.readAsText(file)

  save: (theme) ->
    name = theme["Theme"]

    if Themes[name] and not Themes[name]["Deleted"]
      if confirm "A theme with this name already exists. Would you like to over-write?"
        delete Themes[name]
      else
        return

    Themes[name] = JSON.parse(JSON.stringify(theme))
    delete Themes[name]["Theme"]
    $.get "userThemes", {}, ({userThemes}) ->
      userThemes[name] = Themes[name]
      $.set 'userThemes', userThemes
      $.set "theme", Conf['theme'] = name
      alert "Theme \"#{name}\" saved."

  close: ->
    Conf['editMode'] = false
    $.rm $.id 'themeConf'
    Style.addStyle()
    Settings.open 'themes'