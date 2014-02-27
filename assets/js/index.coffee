#Sets up animations to transition between page sections
do $('div#about').hide

$('a#graph').click( ->
  $('div#about').fadeOut('fast', ->
    $('div#graph').fadeIn('fast')
  )
)

$('a#about').click( ->
  $('div#graph').fadeOut('fast', ->
    $('div#about').fadeIn('fast')
  )
)

#AJAX search for nodes by name and populate search results element.