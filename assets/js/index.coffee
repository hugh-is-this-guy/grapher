jQuery ->
  #Sets up animations to transition between page sections
  do $('div#about').hide

  $('a#graph').click ->
    $('div#about').fadeOut 'fast', ->
      $('div#graph').fadeIn 'fast'
    


  $('a#about').click ->
    $('div#graph').fadeOut 'fast', ->
      $('div#about').fadeIn 'fast'

  @name = 'Jquery'

  Graph =
    width:  800
    height: 500

    tick: ->
      @link.attr 'x1', (d) -> d.source.x
      @link.attr 'y1', (d) -> d.source.y
      @link.attr 'x2', (d) -> d.source.x
      @link.attr 'y2', (d) -> d.source.y
      
      @node.attr 'cx', (d) -> d.x # Error
      @node.attr 'cy', (d) -> d.y


    _draw: ->
      @link = @link.data @links

      @link.enter().insert 'line', '.node'
        .attr 'class', 'link'

      @node = @node.data @nodes

      @node.enter().insert('circle')
        .attr 'class', 'node'
        .attr 'r', 15
        .call @force.drag
        .on 'click', (d) ->
          if not d3.event.defaultPrevented # Ignore drag
            alert d.id + ': ' + d.name

      @node.exit().remove()

      @force.start()


    _generateX: ->
      Math.random() * 800

    _generateY: ->
      Math.random() * 500

    addNode: (new_node) ->
      if not ((n for n in @nodes when n.name is new_node.name)[0])?
        new_node.x = @_generateX()
        new_node.y = @_generateY()
        @nodes.push new_node
        @_draw()

    clearGraph: ->
      @force.nodes []
      @force.links []
      @nodes = @force.nodes()
      @links = @force.links()
      @_draw()

    init: ->
      @svg = d3.select '#svg'
        .append 'svg'
        .attr 'width', @width
        .attr 'height', @height

      @node = @svg.selectAll '.node'
      console.log 'init@node: ' + @node

      @link = @svg.selectAll '.link'

      @force = d3.layout.force()
        .size [@width, @height]
        .linkDistance 30
        .charge -150
        .on 'tick', @tick.bind @

      @nodes = @force.nodes()
      @links = @force.links()
    
      @svg.append 'rect'
        .attr 'width', @width
        .attr 'height', @height

      do @tick

  do Graph.init

  # Search functionality
  #AJAX search for nodes on keydown by name and populate search results element.
  do Searcher = ->
    @last_term = ''

    search = (search_term) ->
      if @last_term != search_term
        clearResults()
        #loading
        if search_term != ''
          $.get "/nodes/name/#{search_term}", (data) ->
            clearResults()
            addResults(data)
        @last_term = search_term

    clearResults = (data) ->
      $('#results ul').empty()


    addResults = (data) ->
      addResult = (id, name) ->
        $('#results ul').append(
          $(document.createElement 'li')
          .append($(document.createElement 'a')
            .attr 'href', '#!'
            .html name
            .click () ->
              Graph.addNode new Node(id, name)
            .prepend($(document.createElement 'span')
              .attr('class', 'glyphicon glyphicon-user')
            )
          )
        )
      
      if data.meta.number_of_people == 0
        $('#results ul').append(
          $(document.createElement 'li')
            .html 'No results'
        )
      else
        addResult person.id, person.name for person in data.people

    $('#name-search').keyup ->
      search encodeURIComponent this.value

    $('#clear').click ->
      clearGraph()
  






  class Node
    constructor: (@id, @name) ->




