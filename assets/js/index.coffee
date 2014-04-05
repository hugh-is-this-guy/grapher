
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
      .charge -750
      .gravity 0.25
      .on 'tick', @tick.bind @
      .linkDistance (d) ->
        (Math.sqrt ((1 / d.weight) * 10000)) + 5

    @nodes = @force.nodes()
    @links = @force.links()
  
    @svg.append 'rect'
      .attr 'width', @width
      .attr 'height', @height

    # Used for random placement of nodes when first added to graph
    @generateX = ->
      Math.random() * 800

    @generateY = ->
      Math.random() * 500

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
    # Adds new node to the dataset and redraws graph, or highlights it if 
    # already there
    if not ((n for n in @nodes when +n.id is +new_node.id)[0])?
      new_node.x = @generateX()
      new_node.y = @generateY()
      @nodes.push new_node
      do @draw

    else
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
    # Used by d3 for force layout animation
    @link.attr 'x1', (d) -> d.source.x
    @link.attr 'y1', (d) -> d.source.y
    @link.attr 'x2', (d) -> d.target.x
    @link.attr 'y2', (d) -> d.target.y
    
    @node.attr 'cx', (d) -> d.x
    @node.attr 'cy', (d) -> d.y

  draw: ->
    # Called everytime graph needs to be redrawn. Sets new dataset and defines
    # functions used by d3 to work out which datapoints have been added and 
    # removed
    self = @

    do @force.stop

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
          "#{d.id} - #{d.name}"

    @link = @link.data @links, (d) ->
      self.links.indexOf d

    @link.enter().insert 'line', '.node'
      .attr 'class', 'link'
      .style 'stroke-width', (d) -> 
        Math.sqrt d.weight
      .append 'title'
        .text (d) -> 
          "#{d.source.name} -- #{d.target.name} (#{d.weight})"

    @link.exit().remove()

    @force.nodes @nodes
          .links @links
          .start()

    d3.selectAll ".fixed"
      .classed "fixed", false



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


  





class Searcher

  # Sends request to REST service for nodes matching user input.
  search: (search_term) ->
    if @last_term != search_term
      do @clearResults
      
      #loading
      if search_term

        if @ajax?
          do @ajax.abort
          
        self = @
        @ajax = $.get(
          "/nodes/search/name/#{search_term}"
          (data) ->

            # Callback function removes loading gif and adds results and nulls ajax
            # member variable
            self.ajax = null
            do $('#loading').remove
            self.addResults(data)
        )

        # Adds loading gif if not already present
        if $('#loading').length is 0
          $('<img id="loading" src="/images/loading.gif">')
          .load -> 
            if $('#loading').length is 0
              $(@).appendTo('#results')

      # If search term empty, aborts outstanding ajax requests and clears results
      else
        if @ajax?
          do @ajax.abort 
        do @clearResults

      @last_term = search_term

  clearSearch: ->
    $('#name-search').val('')
    @last_term = ""
    do @clearResults

  clearResults: ->
    do $('#results ul').empty
    do $('#loading').remove

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
    do $('.selection, #paths').hide

    $(".relations").click ->
      selection = +($(@).attr("id").split("-")[1])
      self.showRelations selection

    $(".showcluster").click ->
      selection = +($(@).attr("id").split("-")[1])
      self.showCluster selection

    $("#show-paths").click ->
      do self.showPaths

    do $(".range").hide

    $(".minlinks").change ->
      selection  = +($(@).attr("id").split("-")[1])
      minlinks   = +($(@).val())
      $("#selection-#{selection} .links .value").text(minlinks);

    $(".minlinks").mouseup ->
      selection  = +($(@).attr("id").split("-")[1])
      self.showRelations selection

    $("#numofpaths").change ->
      minPaths = +($(@).val())
      $("#paths .range .value").text(minPaths);

    $("#numofpaths").mouseup ->
      do self.showPaths



  graph: (@graph) ->

  select: (node) ->
    @selected = if @selected is 2 then 1 else 2

    if +node.id not in @selection
      @selection[@selected] = +node.id

      css_selection_id = '#selection-' + @selected
      $("#{css_selection_id} .id .value").text(node.id)
      $("#{css_selection_id} .name .value").text(node.name)
      $("#{css_selection_id} .links .value").text(0)
      $("#{css_selection_id} .links .minlinks").val(0)
      do $(css_selection_id).fadeIn

      if @selected is 2
        do $("#paths").fadeIn

      #Return number of selection so node colours can be changed.
      @selected
    
    else
      0

  clear: ->
    for selection in [1..2]
      $("#selection-#{selection} .id .value").text ""
      $("#selection-#{selection} .name .value").text ""
      do $(".selection").fadeOut
      do $("#paths").fadeOut
      $(".minlinks").val(0)
      $(".links .value").text(0)
      do $(".range").hide

      @selection = []
    @selected = 2


  showRelations: (selection) ->
    css_id = "#selection-" + selection
    id   = +($("#{css_id} .id .value").text())
    name = $("#{css_id} .name .value").text()
    min  = $("#{css_id} .links .minlinks").val()
    root = new Node id, name
    self = @

    other_selection = if +selection is 2 then 1 else 2
    other_css_id = "#selection-" + other_selection
    do $("#{css_id} .links .range").fadeIn
    do $("#{other_css_id} .links .range").hide
    do $("#paths .range").hide
    $("#paths .range #numofpaths").val 15
    $("#paths .range .value").text "15"


    # Get neighbours for selected node
    $.get(
      "/nodes/relations/#{root.id}/#{min}"
      (data) ->
        # Callback function
        nodes = [root]
        links = []

        for relation in data.relationships
          node = new Node +(relation.node.id), relation.node.name

          nodes.push node

          links.push new Link root, node, relation.weight


        #If the user has selected another node, add it to the dataset if not there already.
        
        text = $(other_css_id + " .id .value").text()
        other_id = if text is "" then undefined else +text

        # If there is another selection
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

  
  showPaths: ->
    from  = +($("#selection-1 .id .value").text())
    to    = +($("#selection-2 .id .value").text())
    max   = +($("#paths .range .value").text())
    self  = @

    do $(".links .range").hide
    do $("#paths .range").fadeIn


    # Callback function
    displayPaths = (from, to) ->
      (data) ->
        # Callback function
        nodes = []
        links = []

        # Build lists of nodes and links
        if data.paths.length > 0

          for path in data.paths
            for node in path.nodes
              nodes.push node if not Node.isNodeInList node, nodes

            for l in path.relationships
              from = (n for n in nodes when n.id is l.source)[0]
              to   = (n for n in nodes when n.id is l.target)[0]

              link = new Link from, to, l.weight
              links.push link if not Link.isLinkInList link, links


          # Draw graph
          self.graph.drawGraph nodes, links

        else
          alert "No paths of length less than three :("

    $.get "/paths/#{from}/#{to}/#{max}", displayPaths(from, to)

  
  showCluster: (selection) ->
    css_id = "#selection-" + selection
    id   = +($("#{css_id} .id .value").text())
    name = $("#{css_id} .name .value").text()
    root = new Node id, name

    other_selection = if +selection is 2 then 1 else 2
    other_id = +($("#{css_id} .id .value").text())
    self = @

    $.get(
      "/cluster/#{root.id}/"
      (data) ->
        console.log data
        if data.relationships.length > 0
          nodes = []
          links = []
          for rel in data.relationships
            from = (n for n in nodes when n.id is rel.from.id)[0]
            if not from?
              from = new Node rel.from.id, rel.from.name

            to = (n for n in nodes when n.id is rel.to.id)[0]
            if not to?
              to   = new Node rel.to.id, rel.to.name

            if not Node.isNodeInList from, nodes
              nodes.push from 
              console.log  "from: id: #{from.id} name: #{from.id}"

            if not Node.isNodeInList to, nodes
              nodes.push to
              console.log  "to: id: #{to.id} name: #{to.id}"


            link = new Link from, to, +rel.weight
            links.push link if not Link.isLinkInList link, links


          # If there is another selection
          if other_id?
            other_css_id = "#selection-" + other_selection
            other_name = $(other_css_id + " .name .value").text()
            other_node = new Node other_id, other_name
            
            # If other selection was in nodes
            if not ((n for n in nodes when n.id is other_node.id)[0])?
              nodes.push other_node

          # Draw graph
          self.graph.drawGraph nodes, links
          self.graph.selectNode id, selection
          if other_id?
            self.graph.selectNode other_id, other_selection
    
        else
          alert "Community could not be found for selected node. :("
    )





class Node
  constructor: (@id, @name) ->

  @isNodeInList : (node, nodes) ->
    ((n for n in nodes when n.id is node.id)[0])?


class Link
  constructor: (source, target, @weight) ->
    # Source is always the lower of the two ids, to aid in the comparisson of
    # two links.
    @source = if source.id < target.id then source else target
    @target = if source.id > target.id then source else target

  @isLinkInList : (link, links) ->
    ((l for l in links when l.source.id is link.source.id and l.target.id is link.target.id)[0])?



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
  graph = new Graph 800, 600, selecter
  searcher = new Searcher graph
  selecter.graph graph


  $('#reset').click =>
      do searcher.clearSearch
      do graph.clearGraph
      do selecter.clear


