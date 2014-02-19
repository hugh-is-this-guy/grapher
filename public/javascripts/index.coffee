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

