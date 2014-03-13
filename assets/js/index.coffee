
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
        (Math.sqrt ((1 / d.weight) * 10000)) + 5

    @nodes = @force.nodes()
    @links = @force.links()
  
    @svg.append 'rect'
      .attr 'width', @width
      .attr 'height', @height

  selectNode: (node, i) ->
    d3.select '#node-' + node.id
      .classed 'selection-' + i, true


  highlightNode: (node) ->
    id = '#node-' + node.id
    circle = d3.select id
    @svg.append "circle"
      .attr({
        r: 10
        cx: circle.attr "cx"
        cy: circle.attr "cy"
      })
      .style "fill", circle.style "fill"
      .transition()
      .attr "r", 30
      .style "opacity", 0
      .duration 400
      .remove()



  addNode: (new_node) ->
    console.log "@nodes"
    console.log @nodes
    if not ((n for n in @nodes when +n.id is +new_node.id)[0])?
      console.log "add"
      new_node.x = generateX()
      new_node.y = generateY()
      @nodes.push new_node
      do @draw

    else
      console.log "highlight!"
      @highlightNode new_node

  drawGraph: (nodes, links) ->
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
    
    @node.attr 'cx', (d) -> d.x
    @node.attr 'cy', (d) -> d.y

  draw: ->
    self = @

    do @force.stop

    @link = @link.data @links, (d) ->
      self.links.indexOf d

    @link.enter().insert 'line', '.node'
      .attr 'class', 'link'
      .style 'stroke-width', (d) -> 
        Math.sqrt d.weight

    @link.exit().remove()

    @node = @node.data @nodes, (d) ->
      d.id

    @node.exit().remove()

    @node.enter().append 'circle'
      .attr 'id', (d) ->
        'node-' + d.id
      .attr 'class', 'node'
      .attr 'r', 10
      .call @force.drag
      .on 'click', (d) ->
        click(d, self, @)
      .append 'title'
        .text (d) -> 
          "#{d.name} #{d.id}"


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
            node = new Node id, name
            @graph.addNode node

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
      selection_id = $(@).attr("id").split("-")[1]

      self.showRelations selection_id

  graph: (@graph) ->

  select: (node) ->
    @selected = if @selected is 2 then 1 else 2

    if node.id not in @selection
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


  showRelations: (selection) ->
    css_id = "#selection-" + selection
    id = $(css_id + " .id .value").text()
    name = $(css_id + " .name .value").text()
    root = new Node id, name
    self = @

    # Get neighbours for selected node
    $.get(
      "/nodes/relations/outwards/#{root.id}"
      (data) ->
        # Get callback
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


        #If the user has selected another node, add it to the dataset if not there already.
        other_selection = if +selection is 2 then 1 else 2
        other_css_id = "#selection-" + other_selection
        text = $(other_css_id + " .id .value").text()
        other_id = if text is "" then undefined else text

        if other_id?
          other_name = $(other_css_id + " .name .value").text()
          other_node = new Node other_id, other_name
          
          # If other selection was in nodes
          if not ((n for n in nodes when n.id is other_node.id)[0])?
            nodes.push other_node

        self.graph.drawGraph nodes, links
        
        # Give selected nodes same colour as in previous visualisation
        self.graph.selectNode root, selection
        if other_node?
          self.graph.selectNode other_node, other_selection
    
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


