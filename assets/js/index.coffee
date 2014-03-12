
class Graph
  
  constructor: (@width, @height, @selecter) ->

    @svg = d3.select '#svg'
      .append 'svg'
      .attr 'width', @width
      .attr 'height', @height

    @node = @svg.selectAll '.node'

    @link = @svg.selectAll '.link'

    @force = d3.layout.force()
      .size [@width, @height]
      .charge -150
      .on 'tick', @tick.bind @
      .linkDistance (d) ->
        Math.sqrt ((1 / d.weight) * 1000)

    @nodes = @force.nodes()
    @links = @force.links()
  
    @svg.append 'rect'
      .attr 'width', @width
      .attr 'height', @height


  addNode: (new_node) ->
    if not ((n for n in @nodes when n.name is new_node.name)[0])?
      new_node.x = generateX()
      new_node.y = generateY()
      @nodes.push new_node
      do @draw

  drawGraph: (nodes, links) ->
    do @clearGraph
    @nodes = nodes
    @links = links
    do @draw

  clearGraph: ->
    @force.nodes []
    @force.links []
    @nodes = @force.nodes()
    @links = @force.links()
    do @draw


  tick: ->
    @link.attr 'x1', (d) -> d.source.x
    @link.attr 'y1', (d) -> d.source.y
    @link.attr 'x2', (d) -> d.target.x
    @link.attr 'y2', (d) -> d.target.y
    
    @node.attr 'cx', (d) -> d.x # Error
    @node.attr 'cy', (d) -> d.y

  draw: ->
    self = @

    @link = @link.data @links

    @link.enter().append 'line'
      .attr 'class', 'link'
      .style 'stroke-width', (d) -> 
        Math.sqrt d.weight

    @link.exit().remove()

    @node = @node.data @nodes

    @node.enter().append 'circle'
      .attr 'class', 'node unselected'
      .attr 'r', 10
      .call @force.drag
      .on 'click', (d) ->
        click(d, self, @)
      .append 'title'
        .text (d) -> 
          d.name

    @node.exit().remove()

    @force.nodes @nodes
          .links @links
          .start()

  #
  click = (d, self, circle) ->
    # Drag
    if d3.event.defaultPrevented
      d3.select(circle).classed "fixed", d.fixed = true

    else
      if self.clicked_once
        # Double click
        self.clicked_once = false
        clearTimeout self.timer
        d3.select(circle).classed "fixed", d.fixed = false

      else
        # Single click
        # Waits for second click, and selects node if none.
        self.timer = setTimeout( ->
          selected = self.selecter.select d
          if selected > 0
            new_class = 'selection-' + selected
            #Remove class from previous selection...
            d3.select '.' + new_class
              .classed 'unselected', true
              .classed new_class, false
            #... and add to new selection
            d3.select circle
              .classed new_class, true

          self.clicked_once = false
        , 250)
        self.clicked_once = true


  generateX = ->
    Math.random() * 800

  generateY = ->
    Math.random() * 500





# Search functionality
#AJAX search for nodes on keydown by name and populate search results element.
class Searcher

  search: (search_term) ->
    if @last_term != search_term
      @clearResults()
      
      #loading
      if search_term != ''
          
        self = @
        $.get(
          "/nodes/name/#{search_term}"
          (data) ->
            do $('#loading').remove
            self.addResults(data)
        )

        if $('#loading').length is 0
          $('<img id="loading" src="/images/loading.gif">')
          .load -> 
            $(@).appendTo('#results')

      @last_term = search_term

  clearSearch: ->
    $('#name-search').val('')
    @last_term = ""
    do @clearResults

  clearResults: ->
    do $('#results ul').empty

  addResults: (data) ->
    self = @
    do @clearResults
    
    if data.meta.number_of_people is 0
      $('#results ul').append(
        $('<li>')
          .html 'No results'
      )
    else
      @addResult person.id, person.name for person in data.people
  
  addResult: (id, name) =>
    $('#results ul').append(
      $('<li>')
        .append($('<a>')
          .attr 'href', '#!'
          .html name
          .click () =>
            @graph.addNode new Node(id, name)
          .prepend($('<span>')
            .attr('class', 'glyphicon glyphicon-user')
          )
      )
    )

  constructor: (@graph) ->
    self = @
    $('#name-search').keyup (e) ->
      if e.keyCode == 13
        self.search($.trim($(@).val()))



class Selecter

  constructor: ->
    @selected = 2
    @selection = []
    self = @
    do $('.selection').hide
    $(".relations").click ->
      selection_id = "#selection-" + $(@).attr("id").split("-")[1]
      id = $(selection_id + " .id .value").text()
      name = $(selection_id + " .name .value").text()

      self.showRelations new Node id, name

  graph: (@graph) ->

  select: (node) ->
    @selected = if @selected is 2 then 1 else 2

    if node.id not in @selection
      console.log 'Select ' + node.id + ': ' + node.name + @selected

      @selection[@selected] = node.id

      selection = '#selection-' + @selected
      $(selection + ' .id .value').text(node.id)
      $(selection + ' .name .value').text(node.name)
      do $(selection).fadeIn

      #Return number of selection so node colours can be changed.
      @selected
    
    else
      0

  clear: ->
    for selection in [1..2]
      $("#selection-#{selection} .id .value").text ""
      $("#selection-#{selection} .name .value").text ""
      do $(".selection").fadeOut
      @selection = []
    @selected = 2

  showRelations: (root) ->
    self = @
    $.get(
      "/nodes/relations/outwards/#{root.id}"
      (data) ->
        nodes = [root]
        links = []

        for relation in data.relationships
          node = new Node relation.node.id, relation.node.name

          nodes.push node

          links.push {
            source: root
            target: node
            weight: relation.weight
          }

        console.log nodes
        console.log links
        do self.graph.clearGraph
        self.graph.drawGraph nodes, links
    )




class Node
  constructor: (@id, @name) ->

jQuery ->
  #Sets up animations to transition between page sections
  do $('#about').hide

  $('#show-graph').click ->
    $('#about').fadeOut 'fast', ->
      $('#graph').fadeIn 'fast'

  $('#show-about').click ->
    $('div#graph').fadeOut 'fast', ->
      $('div#about').fadeIn 'fast'


  selecter = new Selecter
  graph = new Graph 800, 500, selecter
  searcher = new Searcher graph
  selecter.graph graph


  $('#reset').click =>
      do searcher.clearSearch
      do graph.clearGraph
      do selecter.clear


