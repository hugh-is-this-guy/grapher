
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
      .linkDistance 30
      .charge -150
      .on 'tick', @tick.bind @

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


  clearGraph: ->
    @force.nodes []
    @force.links []
    @nodes = @force.nodes()
    @links = @force.links()
    do @draw

  tick: ->
    @link.attr 'x1', (d) -> d.source.x
    @link.attr 'y1', (d) -> d.source.y
    @link.attr 'x2', (d) -> d.source.x
    @link.attr 'y2', (d) -> d.source.y
    
    @node.attr 'cx', (d) -> d.x # Error
    @node.attr 'cy', (d) -> d.y

  draw: ->
    self = @

    @link = @link.data @links

    @link.enter().insert 'line', '.node'
      .attr 'class', 'link'

    @link.exit().remove()

    @node = @node.data @nodes

    @node.enter().append 'circle'
      .attr 'class', 'node unselected'
      .attr 'r', 15
      .call @force.drag
      .on 'click', (d) ->
        click(d, self, @)
      .append 'title'
        .text (d) -> 
          d.name

    @node.exit().remove()

    @force.start()

  #
  click = (d, self, circle) ->
    # Ignore drag
    if not d3.event.defaultPrevented
      if self.clicked_once
        #Double click
        self.clicked_once = false
        clearTimeout self.timer
        d3.select(circle).classed "fixed", d.fixed = false

      else
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
    else
      d3.select(circle).classed "fixed", d.fixed = true




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
    do $('.selection').hide
    $(".relations").click ->
      selection_id = "#selection-" + $(@).attr("id").split("-")[1]
      console.log $(selection_id + " .id .value").text()

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


  $('#reset').click =>
      do searcher.clearSearch
      do graph.clearGraph
      do selecter.clear


