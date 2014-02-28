jQuery ->
  #Sets up animations to transition between page sections
  do $('div#about').hide

  $('a#graph').click ->
    $('div#about').fadeOut 'fast', ->
      $('div#graph').fadeIn 'fast'
    


  $('a#about').click ->
    $('div#graph').fadeOut 'fast', ->
      $('div#about').fadeIn 'fast'


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

  addToGraph= (id, name) ->
    alert id + ": " + name

  Searcher()
