Style =
  init: ->
    @setup()
    $.asap (-> d.body), @asapInit
    $.ready @readyInit

  asapInit: ->
    MascotTools.init()

    if g.VIEW is 'index'
      $.asap (-> $ '.mPagelist'), ->

        prev = $ ".pagelist > .prev"
        prevA = $.el 'a',
          textContent: '<'

        next = $ ".pagelist > .next"
        nextA = $.el 'a',
          textContent: '>'

        if (prevAction = prev.firstElementChild).nodeName is 'FORM'
          prevA.href = 'javascript:;'
          $.on prevA, 'click', ->
            prevAction.firstElementChild.click()

        if (nextAction = next.firstElementChild).nodeName is 'FORM'
          nextA.href = 'javascript:;'
          $.on nextA, 'click', ->
            nextAction.firstElementChild.click()

        $.add prev, prevA
        $.add next, nextA

  readyInit: ->
    return unless $.id 'navtopright'

    # Give ExLinks and 4sight a little time to append their dialog links
    setTimeout ->
      Style.padding.nav = Header.bar
      Style.padding.pages = $(".pagelist", d.body)
      Style.padding()
      $.on window, "resize", Style.padding
      Style.iconPositions()
      if exLink = $ "#navtopright .exlinksOptionsLink", d.body
        $.on exLink, "click", ->
          setTimeout Rice.nodes, 100
    , 500

  agent:  "<% if (type === 'crx') { %>-webkit-<% } else if (type === 'userscript') { %>-moz-<% } else { %>-o-<% } %>"

  sizing: "<% if (type === 'userscript') { %>-moz-<% } else { %><% } %>box-sizing"

  setup: ->
    @addStyleReady()
    if d.head
      @remStyle()
      unless Style.headCount
        return @cleanup()
    @observe()

  observe: ->
    if MutationObserver
      Style.observer = new MutationObserver onMutationObserver = @wrapper
      Style.observer.observe d,
        childList: true
        subtree: true
    else
      $.on d, 'DOMNodeInserted', @wrapper

  wrapper: ->
    if d.head
      Style.remStyle()

      if not Style.headCount or d.readyState is 'complete'
        if Style.observer
          Style.observer.disconnect()
        else
          $.off d, 'DOMNodeInserted', Style.wrapper
        Style.cleanup()

  cleanup: ->
    delete Style.observe
    delete Style.wrapper
    delete Style.remStyle
    delete Style.headCount
    delete Style.cleanup

  addStyle: (theme) ->
    _conf = Conf
    unless theme
      theme = Themes[_conf['theme']]

    MascotTools.init _conf["mascot"]
    Style.layoutCSS.textContent = Style.layout()
    Style.themeCSS.textContent = Style.theme(theme)
    Style.iconPositions()
    Style.padding()

  headCount: 12

  addStyleReady: ->
    theme = Themes[Conf['theme']]
    $.extend Style,
      layoutCSS:    $.addStyle Style.layout(),      'layout'
      themeCSS:     $.addStyle Style.theme(theme),  'theme'
      icons:        $.addStyle "",                  'icons'
      paddingSheet: $.addStyle "",                  'padding'
      mascot:       $.addStyle "",                  'mascotSheet'

    # Non-customizable
    $.addStyle JSColor.css(), 'jsColor'

    delete Style.addStyleReady

  remStyle: ->
    nodes = d.head.children
    i = nodes.length
    while i--
      return unless Style.headCount
      node = nodes[i]
      if (node.nodeName is 'STYLE' and !node.id) or ("#{node.rel}".contains('stylesheet') and node.href[..3] isnt 'data')
        Style.headCount--
        $.rm node
    return

  filter: (text, background) ->

    matrix = (fg, bg) -> "
 #{bg.r} #{-fg.r} 0 0 #{fg.r}
 #{bg.g} #{-fg.g} 0 0 #{fg.g}
 #{bg.b} #{-fg.b} 0 0 #{fg.b}
"

    fgHex = Style.colorToHex(text)
    bgHex = Style.colorToHex(background)
    string = matrix {
      r: parseInt(fgHex.substr(0, 2), 16) / 255
      g: parseInt(fgHex.substr(2, 2), 16) / 255
      b: parseInt(fgHex.substr(4, 2), 16) / 255
    }, {
      r: parseInt(bgHex.substr(0, 2), 16) / 255
      g: parseInt(bgHex.substr(2, 2), 16) / 255
      b: parseInt(bgHex.substr(4, 2), 16) / 255
    }

    return """filter: url("data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg'><filter id='filters' color-interpolation-filters='sRGB'><feColorMatrix values='#{string} 0 0 0 1 0' /></filter></svg>#filters");"""

  layout: ->
    _conf   = Conf
    agent   = Style.agent
    xOffset = if _conf["Sidebar Location"] is "left" then '-' else ''
    
    Style.pfOffset = if _conf['4chan SS Navigation'] and
      ((_conf['Bottom Header'] and _conf['Fixed Header']) or
      (g.VIEW is 'index' and _conf['Pagination'] is 'sticky bottom'))
        1.5
    else
        0

    # Position of submenus in relation to the post menu.
    position = {
      right:
        {
          hide:
            if parseInt(_conf['Right Thread Padding'], 10) < 100
              "right"
            else
              "left"
          minimal: "right"
        }[_conf["Sidebar"]] or "left"
      left:
        if parseInt(_conf['Right Thread Padding'], 10) < 100
          "right"
        else
          "left"
    }[_conf["Sidebar Location"]]

    # Offsets various UI of the sidebar depending on the sidebar's width.
    # Only really used for the board banner or right sidebar.
    Style['sidebarOffset'] = if _conf['Sidebar'] is "large"
      {
        W: 51
        H: 17
      }
    else
      {
        W: 0
        H: 0
      }

    Style.logoOffset =
      if _conf["4chan Banner"] is "at sidebar top"
        83 + Style.sidebarOffset.H
      else
        0

    width = 248 + Style.sidebarOffset.W

    Style.sidebarLocation = if _conf["Sidebar Location"] is "left"
      ["left",  "right"]
    else
      ["right", "left" ]

    if _conf['editMode'] is "theme"
      editSpace = {}
      editSpace[Style.sidebarLocation[1]] = 300
      editSpace[Style.sidebarLocation[0]] = 0
    else
      editSpace =
        left:   0
        right:  0

    Style.sidebar = {
      minimal:  20
      hide:     2
    }[_conf['Sidebar']] or (252 + Style.sidebarOffset.W)

    Style.replyMargin = _conf["Post Spacing"]

    css = """<%= grunt.file.read('src/General/css/layout.css') %>"""

  theme: (theme) ->
    _conf = Conf
    agent = Style.agent

    bgColor = new Style.color(Style.colorToHex(backgroundC = theme["Background Color"]) or 'aaaaaa')

    Style.lightTheme = bgColor.isLight()

    icons = "data:image/png;base64,#{Icons[_conf["Icons"]]}"

    css = """<%= grunt.file.read('src/General/css/theme.css') %>"""

    <%= grunt.file.read('src/General/css/themeoptions.css') %>
    
    css

  iconPositions: ->
    css = """<%= grunt.file.read('src/General/css/icons.base.css') %>"""
    i = 0
    align = Style.sidebarLocation[0]

    _conf = Conf
    notCatalog = g.VIEW isnt 'catalog'
    notEither  = notCatalog and g.BOARD isnt 'f'

    aligner = (first, checks) ->
      # Create a position to hold values
      position = [first]

      # Check which elements we actually have. Some are easy, because the script creates them so we'd know they're here
      # Some are hard, like 4sight, which we have no way of knowing if available without looking for it.
      for enabled in checks
        position.push(
          if enabled
            first += 19
          else
            first
        )

      position

    if _conf["Icon Orientation"] is "horizontal"

      position = aligner(
        2
        [
          true
          _conf['Slideout Navigation'] isnt 'hide'
          _conf['Announcements'] is 'slideout' and (psa = $ '#globalMessage', d.body) and !psa.hidden
          _conf['Thread Watcher'] and _conf['Slideout Watcher']
          $ '#navtopright .exlinksOptionsLink', d.body
          notCatalog and $ 'body > a[style="cursor: pointer; float: right;"]', d.body
          notEither and _conf['Image Expansion']
          true
          notEither
          g.VIEW is 'thread'
          notEither and _conf['Fappe Tyme']
          navlinks = ((g.VIEW isnt 'thread' and _conf['Index Navigation']) or (g.VIEW is 'thread' and _conf['Reply Navigation'])) and notCatalog
          navlinks
        ]
      )

      iconOffset =
        position[position.length - 1] - (if _conf['4chan SS Navigation']
          0
        else
          Style.sidebar + parseInt(_conf["Right Thread Padding"], 10))
      if iconOffset < 0 then iconOffset = 0

      css += """<%= grunt.file.read('src/General/css/icons.horz.css') %>"""

    else

      position = aligner(
        2 + (if _conf["4chan Banner"] is "at sidebar top" then (Style.logoOffset + 19) else 0)
        [
          notEither and _conf['Image Expansion']
          true
          true
          _conf['Slideout Navigation'] isnt 'hide'
          _conf['Announcements'] is 'slideout' and (psa = $ '#globalMessage', d.body) and !psa.hidden
          _conf['Thread Watcher'] and _conf['Slideout Watcher']
          notCatalog and $ 'body > a[style="cursor: pointer; float: right;"]', d.body
          $ '#navtopright .exlinksOptionsLink', d.body
          notEither
          g.VIEW is 'thread'
          notEither and _conf['Fappe Tyme']
          navlinks = ((g.VIEW isnt 'thread' and _conf['Index Navigation']) or (g.VIEW is 'thread' and _conf['Reply Navigation'])) and notCatalog
          navlinks
        ]
      )

      iconOffset = (
        20 + (
          if g.VIEW is 'thread' and _conf['Updater Position'] is 'top'
            100
          else
            0
        )
      ) - (
        if _conf['4chan SS Navigation']
          0
        else
          Style.sidebar + parseInt _conf[align.capitalize() + " Thread Padding"], 10
      )

      css += """<%= grunt.file.read('src/General/css/icons.vert.css') %>"""

    Style.icons.textContent = css

  padding: ->
    return unless (sheet = Style.paddingSheet) and Style.padding.nav
    _conf = Conf
    Style.padding.nav.property = if _conf['Bottom Header'] then 'bottom' else 'top'
    if Style.padding.pages
      Style.padding.pages.property = _conf["Pagination"].split(" ")
      Style.padding.pages.property = Style.padding.pages.property[Style.padding.pages.property.length - 1]
    css = "body::before {\n"
    if _conf['4chan SS Navigation'] and Style.padding.pages and ["sticky top", "top", "sticky bottom"].contains _conf["Pagination"]
      css += "  #{Style.padding.pages.property}: #{Style.padding.pages.offsetHeight}px !important;\n"

    if _conf['Fixed Header']
      css += "  #{Style.padding.nav.property}: #{Style.padding.nav.offsetHeight}px !important;\n"

    css += """
}
body {
  padding-bottom: 0;\n
"""

    if Style.padding.pages? and ["sticky top", "top", "sticky bottom"].contains _conf["Pagination"]
      css += "  padding-#{Style.padding.pages.property}: #{Style.padding.pages.offsetHeight + 1}px;\n"

    unless _conf['Header auto-hide'] or _conf['Hide Header']
      css += "  padding-#{Style.padding.nav.property}: #{Style.padding.nav.offsetHeight + 1}px;\n"

    css += "}"

    sheet.textContent = css

  color: (hex) ->
    @hex = "#" + hex

    @calc_rgb = (hex) ->
      hex = parseInt hex, 16
      [ # 0xRRGGBB to [R, G, B]
        (hex >> 16) & 0xFF
        (hex >> 8) & 0xFF
        hex & 0xFF
      ]

    @private_rgb = @calc_rgb(hex)

    @rgb = @private_rgb.join ","

    @isLight = ->
      rgb = @private_rgb
      return (rgb[0] + rgb[1] + rgb[2]) >= 400

    @shiftRGB = (shift, smart) ->
      minmax = (base) ->
        Math.min Math.max(base, 0), 255
      rgb = @private_rgb.slice 0
      shift = if smart
        (
          if @isLight rgb
            -1
          else
            1
        ) * Math.abs shift
      else
        shift

      return [
        minmax rgb[0] + shift
        minmax rgb[1] + shift
        minmax rgb[2] + shift
      ].join ","

    @hover = @shiftRGB 16, true

  colorToHex: (color) ->
    if color.substr(0, 1) is '#'
      return color.slice 1, color.length

    if digits = color.match /(.*?)rgba?\((\d+), ?(\d+), ?(\d+)(.*?)\)/
      # [R, G, B] to 0xRRGGBB
      hex = (
        (parseInt(digits[2], 10) << 16) |
        (parseInt(digits[3], 10) << 8)  |
        (parseInt(digits[4], 10))
      ).toString 16

      while hex.length < 6
        hex = "0#{hex}"

      hex

    else
      false