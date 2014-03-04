jQuery ->
  #Sets up animations to transition between page sections
  do $('div#about').hide

  $('a#graph').click ->
    $('div#about').fadeOut 'fast', ->
      $('div#graph').fadeIn 'fast'
    


  $('a#about').click ->
    $('div#graph').fadeOut 'fast', ->
      $('div#about').fadeIn 'fast'


  # Search functionality
  #AJAX search for nodes on keydown by name and populate search results element.
  Searcher = ->
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
              addToGraph id, name
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


  Searcher()


# D3
width   = 800
height  = 500

svg = d3.select '#svg'
  .append 'svg'
  .attr 'width', width
  .attr 'height', height

node = svg.selectAll '.node'
link = svg.selectAll '.link'

tick = () ->
  link.attr 'x1', (d) -> d.source.x
  link.attr 'y1', (d) -> d.source.y
  link.attr 'x2', (d) -> d.source.x
  link.attr 'y2', (d) -> d.source.y

  node.attr 'cx', (d) -> d.x # Error
  node.attr 'cy', (d) -> d.y

force = d3.layout.force()
  .size [width, height]
  .linkDistance 30
  .charge -150
  .on 'tick', tick

nodes = force.nodes()
links = force.links()

draw = () ->
  link = link.data links

  link.enter().insert 'line', '.node'
    .attr 'class', 'link'

  node = node.data nodes

  node.enter().insert('circle')
    .attr 'class', 'node'
    .attr 'r', 15
    .call force.drag
    .on 'click', (d) ->
      if not d3.event.defaultPrevented # Ignore drag
        alert d.id + ': ' + d.name

  node.exit().remove()

  force.start()

svg.append 'rect'
  .attr 'width', width
  .attr 'height', height

draw()

getX = ->
  Math.random() * 800

getY = ->
  Math.random() * 500

addToGraph = (id, name) ->
  nodes.push {id: id, name: name, x: getX(), y: getY()}
  draw()

clearGraph = () ->
  force.nodes([])
  force.links([])
  nodes = force.nodes()
  links = force.links()
  draw()




